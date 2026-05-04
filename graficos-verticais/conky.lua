-- Conky Lua Module for Vertical Graphics Panel
-- ================================================

require 'cairo'

-- Conky 1.20+: X11 Cairo entry points live in a separate Lua module. Without this,
-- cairo_xlib_surface_create is nil, conky.text is empty, and nothing draws.
local cairo_xlib_ok, cairo_xlib_err = pcall(function()
    require('cairo_xlib')
end)
if not cairo_xlib_ok and io and io.stderr then
    io.stderr:write('[graficos-verticais] require("cairo_xlib") failed: ' .. tostring(cairo_xlib_err) .. '\n')
end

-- Yellow on-screen lines + red border; stderr hints if Cairo surface cannot be created.
local DEBUG_DRAW = false

-- Configuration
fontName = "Roboto Medium"
fontSize = 14
largura = 370
altura = 1000

-- Full-window fill colour (what you actually see). conky.conf `own_window_colour` is only used by
-- Conky’s X11 background pass before Lua and is painted over entirely every frame here.
painelCorFundo = "#1e2024"

-- Network adapters
wlanAdapter = "wlp0s20f3"
ethAdapter = "enp59s0"

-- Block device for ${diskio_read} / ${diskio_write} (e.g. sda, nvme0n1)
diskioDevice = "nvme0n1"

-- GPU stats via `nvidia-smi` (works on Wayland). Conky `${nvidia ...}` uses NV-CONTROL and fails there.
useNvidiaSmi = true
-- Seconds between `nvidia-smi` runs (Conky `execi` cache); higher = less CPU, slower UI updates.
nvidiaSmiInterval = 5

local GRAPH_LEN = 30

-- Rolling samples for time-series graphs (updated each conky cycle)
cpu_hist = cpu_hist or {}
gpu_hist = gpu_hist or {}
gpu_vram_hist = gpu_vram_hist or {}
net_up_hist = net_up_hist or {}
net_down_hist = net_down_hist or {}
disk_read_hist = disk_read_hist or {}
disk_write_hist = disk_write_hist or {}

-- First numeric value in a string (handles "12%", "3.4 MiB", "1,2", etc.)
local function parse_number(s)
    if s == nil then
        return 0
    end
    s = tostring(s):gsub(",", ".")
    local m = s:match("[-+]?%d*%.?%d+")
    return tonumber(m) or 0
end

local function trim(s)
    if s == nil then
        return ""
    end
    return (tostring(s):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function hist_push(buf, v, maxlen)
    maxlen = maxlen or GRAPH_LEN
    table.insert(buf, v)
    while #buf > maxlen do
        table.remove(buf, 1)
    end
end

-- Last N points, left-padded with zeros if history is still short
local function hist_series(buf, n)
    n = n or GRAPH_LEN
    local t = {}
    local h = #buf
    for i = 1, n do
        local idx = h - n + i
        t[i] = (idx >= 1) and buf[idx] or 0
    end
    return t
end

-- Scale non-percent series to 0..100 for drawing (by local max)
local function normalize_0_100(data)
    local maxv = 1e-9
    for i = 1, #data do
        if data[i] > maxv then
            maxv = data[i]
        end
    end
    local out = {}
    for i = 1, #data do
        out[i] = math.min(100, (data[i] / maxv) * 100)
    end
    return out
end

-- Section accent colors (graphs / highlights) — see modelo.png
corProcessador = "#2E7CB5"    -- CPU line / fill accent
corMemoria = "#A855B8"        -- RAM bar (purple)
corGPU = "#E04B5C"            -- GPU load graph
corGPUMem = "#C86B98"         -- VRAM % graph (separate from system RAM section colour)
corDisco = "#F0A040"          -- Disk section accent / title underline
corDiscoRead = "#F0A040"      -- read (L) graph
corDiscoWrite = "#E8A868"     -- write (G) graph
corRede = "#2EC4D9"           -- Wi-Fi section accent / title underline
corRedeUp = "#2EC4D9"         -- upload graph (same family as section)
corRedeDown = "#5AB4E8"       -- download graph

-- Typography (modelo: white titles, light grey stats)
corTitulo = "#FFFFFF"
corTextoStats = "#C8CED6"
corTextoStatsDim = "#9AA3AE"

-- Graph plot area background (neutral, slightly lighter than panel)
corFundoGrafico = { 0.16, 0.17, 0.20, 1.0 }

-- Border settings
raioBorda = 20
espessuraBorda = 6
margensBorda = 10

-- Graph settings
raioGrafico = 15
espessuraGrafico = 3

-- Vertical layout per section: one header row (title left, stats right) + underline, then graph.
tituloFontSize = 18
statsRowFontSize = 13
-- Y offset from section top to accent underline (must fit inside alturaCabecalhoSec).
tituloUnderlineY = 24
alturaCabecalhoSec = 28
gapTituloGrafico = 6

-- Vertical gap: distance from the window top edge to the first section title, and the
-- same distance between each of the five sections (horizontal inset stays margensBorda).
gapSecao = 24

-- == Helper Functions ==

-- Convert hex to RGB (three floats 0..1 for Cairo). Callers use: local r, g, b = hex2rgb("#RRGGBB").
function hex2rgb(hex)
    hex = tostring(hex or "#000000"):gsub("#", "")
    return tonumber("0x" .. hex:sub(1, 2)) / 255,
        tonumber("0x" .. hex:sub(3, 4)) / 255,
        tonumber("0x" .. hex:sub(5, 6)) / 255
end

-- Draw a rounded rectangle border
function desenhaBorda(corHex, x, y, largura, altura)
    local r, g, b = hex2rgb(corHex)
    local alpha = 0.3
    
    cairo_set_source_rgba(cr, r, g, b, alpha)
    cairo_set_line_width(cr, espessuraBorda)
    cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
    cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND)
    
    -- Top-left arc
    cairo_arc(cr, x + raioBorda, y + raioBorda, raioBorda, math.pi, 1.5 * math.pi)
    cairo_stroke(cr)
    
    -- Top-right arc
    cairo_arc(cr, x + largura - raioBorda, y + raioBorda, raioBorda, 0, 0.5 * math.pi)
    cairo_stroke(cr)
    
    -- Bottom-right arc
    cairo_arc(cr, x + largura - raioBorda, y + altura - raioBorda, raioBorda, 0.5 * math.pi, math.pi)
    cairo_stroke(cr)
    
    -- Bottom-left arc
    cairo_arc(cr, x + raioBorda, y + altura - raioBorda, raioBorda, math.pi, 1.5 * math.pi)
    cairo_stroke(cr)
end

-- Draw a line
function desenhaLinha(corHex, startX, startY, endX, endY)
    local r, g, b = hex2rgb(corHex)
    local alpha = 1.0
    
    cairo_set_source_rgba(cr, r, g, b, alpha)
    cairo_move_to(cr, startX, startY)
    cairo_line_to(cr, endX, endY)
    cairo_stroke(cr)
end

-- Draw a graph with temperature gradient
function desenhaGrafico(corHex, x, y, largura, altura, dados)
    local r, g, b = hex2rgb(corHex)
    local alpha = 0.6
    
    -- Draw graph background
    cairo_set_source_rgba(cr, r, g, b, alpha * 0.2)
    cairo_rectangle(cr, x, y, largura, altura)
    cairo_fill(cr)
    
    if dados and #dados > 1 then
        local step = largura / (#dados - 1)
        
        for i, valor in ipairs(dados) do
            local barraAltura = valor * altura / 100
            local barraX = x + (i - 1) * step
            local barraY = y + altura - barraAltura
            
            local grad = cairo_pattern_create_linear(barraX, y, barraX, y + altura)
            cairo_pattern_add_color_stop_rgba(grad, 0, r, g, b, alpha * 0.3)
            cairo_pattern_add_color_stop_rgba(grad, 1, r, g, b, alpha * 0.8)
            cairo_set_source(cr, grad)
            cairo_rectangle(cr, barraX, barraY, step, barraAltura)
            cairo_fill(cr)
            cairo_pattern_destroy(grad)
        end
    end
end

-- Draw a simple line graph (neutral plot background; saturated series color)
function desenhaGraficoLinha(corHex, x, y, largura, altura, dados)
    local r, g, b = hex2rgb(corHex)
    local bg = corFundoGrafico

    cairo_set_source_rgba(cr, bg[1], bg[2], bg[3], bg[4])
    cairo_rectangle(cr, x, y, largura, altura)
    cairo_fill(cr)

    if dados and #dados > 1 then
        local n = #dados
        local step = largura / (n - 1)

        cairo_set_source_rgba(cr, r, g, b, 0.38)
        cairo_move_to(cr, x, y + altura)
        for i, valor in ipairs(dados) do
            local graficoX = x + (i - 1) * step
            local graficoY = y + altura - (valor * altura / 100)
            cairo_line_to(cr, graficoX, graficoY)
        end
        cairo_line_to(cr, x + largura, y + altura)
        cairo_line_to(cr, x, y + altura)
        cairo_fill(cr)

        cairo_set_source_rgba(cr, r, g, b, 1)
        cairo_set_line_width(cr, 2.25)
        cairo_move_to(cr, x, y + altura)
        for i, valor in ipairs(dados) do
            local graficoX = x + (i - 1) * step
            local graficoY = y + altura - (valor * altura / 100)
            cairo_line_to(cr, graficoX, graficoY)
        end
        cairo_stroke(cr)
    end
end

-- Draw text (do not cairo_stroke after show_text — it ruins contrast / colour)
function texto(txt, x, y, corHex, fs, align, weightBold)
    fs = fs or fontSize
    align = align or "left"
    weightBold = (weightBold == nil) and true or weightBold

    local red, green, blue = hex2rgb(corHex)
    cairo_set_source_rgba(cr, red, green, blue, 1)
    cairo_select_font_face(
        cr,
        fontName,
        CAIRO_FONT_SLANT_NORMAL,
        weightBold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL
    )
    cairo_set_font_size(cr, fs)

    if align == "center" then
        local extents = cairo_text_extents_t:create()
        tolua.takeownership(extents)
        cairo_text_extents(cr, txt, extents)
        x = x - (extents.width / 2) - extents.x_bearing
    elseif align == "right" then
        local extents = cairo_text_extents_t:create()
        tolua.takeownership(extents)
        cairo_text_extents(cr, txt, extents)
        x = x - extents.width - extents.x_bearing
    end

    cairo_move_to(cr, x, y)
    cairo_show_text(cr, txt)
end

-- == Main Drawing Functions ==

local _debug_ticks = 0

local function trunc(s, maxLen)
    maxLen = maxLen or 72
    s = tostring(s or "")
    if #s <= maxLen then
        return s
    end
    return s:sub(1, maxLen - 3) .. "..."
end

-- One header row: title left, stats right, full-width accent underline.
function secao_cabecalho_linha(label, statsStr, bx, by, corAccent, larguraConteudo)
    local reserveTitlePx = 108
    local maxStatsChars = math.max(
        8,
        math.min(72, math.floor(math.max(0, larguraConteudo - reserveTitlePx) / 5.2))
    )
    local statsDisp = trunc(statsStr, maxStatsChars)
    local rowBaseline = by + 18
    texto(label, bx + 4, rowBaseline, corTitulo, tituloFontSize, "left", true)
    texto(statsDisp, bx + larguraConteudo - 4, rowBaseline, corTextoStats, statsRowFontSize, "right", false)
    local rr, gg, bb = hex2rgb(corAccent)
    cairo_save(cr)
    cairo_set_source_rgba(cr, rr, gg, bb, 0.85)
    cairo_set_line_width(cr, 2)
    cairo_move_to(cr, bx, by + tituloUnderlineY)
    cairo_line_to(cr, bx + larguraConteudo, by + tituloUnderlineY)
    cairo_stroke(cr)
    cairo_restore(cr)
end

-- On-screen debug (requires cr). Call before cairo_destroy(cr).
local function draw_debug_overlay(surfaceSource, width, height, lines)
    if not DEBUG_DRAW or cr == nil then
        return
    end
    cairo_save(cr)
    cairo_set_source_rgba(cr, 1, 0.15, 0.15, 0.95)
    cairo_set_line_width(cr, 3)
    cairo_rectangle(cr, 2, 2, width - 4, height - 4)
    cairo_stroke(cr)
    cairo_restore(cr)

    local yy = 22
    local dy = 16
    local col = "#EEFF00"
    for _, row in ipairs(lines) do
        texto(trunc(row, 90), 10, yy, col, 12, "left")
        yy = yy + dy
    end
end

function conky_main()
    _debug_ticks = _debug_ticks + 1

    if conky_window == nil then
        if DEBUG_DRAW and io and io.stderr then
            io.stderr:write("[graficos-verticais] conky_main: conky_window is nil (tick " .. _debug_ticks .. ")\n")
        end
        return
    end

    local surfaceSource = "?"
    local cs
    local ownSurface = false
    local conky_surface_returned_nil = false

    if type(conky_surface) == "function" then
        cs = conky_surface()
        if cs ~= nil then
            surfaceSource = "conky_surface()"
        else
            conky_surface_returned_nil = true
        end
    end

    if cs == nil and type(cairo_xlib_surface_create) == "function"
        and conky_window.display ~= nil
        and conky_window.drawable ~= nil
        and conky_window.visual ~= nil then
        cs = cairo_xlib_surface_create(
            conky_window.display,
            conky_window.drawable,
            conky_window.visual,
            conky_window.width,
            conky_window.height
        )
        ownSurface = true
        surfaceSource = "cairo_xlib_surface_create"
    end

    if cs == nil and conky_window.draw_area ~= nil then
        cs = conky_window.draw_area
        surfaceSource = "draw_area"
    end

    if cs == nil then
        if DEBUG_DRAW and io and io.stderr then
            io.stderr:write(
                "[graficos-verticais] conky_main: no cairo surface (tick "
                    .. _debug_ticks
                    .. ") conky_surface_fn="
                    .. tostring(type(conky_surface) == "function")
                    .. " conky_surface_returned_nil="
                    .. tostring(conky_surface_returned_nil)
                    .. " display="
                    .. tostring(conky_window.display ~= nil)
                    .. " drawable="
                    .. tostring(conky_window.drawable ~= nil)
                    .. " visual="
                    .. tostring(conky_window.visual ~= nil)
                    .. " draw_area="
                    .. tostring(conky_window.draw_area ~= nil)
                    .. " xlib_fn="
                    .. tostring(type(cairo_xlib_surface_create) == "function")
                    .. " cairo_xlib_require_ok="
                    .. tostring(cairo_xlib_ok)
                    .. "\n"
            )
        end
        return
    end

    cr = cairo_create(cs)

    local width = conky_window.width
    local height = conky_window.height

    -- Opaque base: SOURCE replaces buffer (avoids leftover alpha / compositor “veil” on ARGB).
    local pbr, pbg, pbb = hex2rgb(painelCorFundo)
    cairo_save(cr)
    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE)
    cairo_set_source_rgba(cr, pbr, pbg, pbb, 1.0)
    cairo_paint(cr)
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER)
    cairo_restore(cr)

    local x = margensBorda
    local contentW = width - 2 * margensBorda
    local grafPad = 10
    local grafW = math.max(120, contentW - 2 * grafPad)
    local grafX = margensBorda + (contentW - grafW) / 2

    local bottomReserve = 28
    local topInset = gapSecao
    local gapsEntreSecoes = 4 * gapSecao
    local alturaSecao = (height - topInset - margensBorda - bottomReserve - gapsEntreSecoes) / 5
    if alturaSecao < 40 then
        alturaSecao = 40
    end

    local grafBottomPad = 6
    local grafMinH = 26

    local function graphGeometry(baseY)
        local headerBottom = baseY + alturaCabecalhoSec
        local gY = headerBottom + gapTituloGrafico
        local gH = baseY + alturaSecao - gY - grafBottomPad
        if gH < grafMinH then
            gH = grafMinH
        end
        return gY, gH
    end

    -- GPU section: two stacked line graphs (load + VRAM %) within the same section height.
    local function graphGeometryDual(baseY)
        local headerBottom = baseY + alturaCabecalhoSec
        local graphsTop = headerBottom + gapTituloGrafico
        local totalH = baseY + alturaSecao - graphsTop - grafBottomPad
        if totalH < grafMinH * 2 + 4 then
            totalH = grafMinH * 2 + 4
        end
        local midGap = 4
        local pairH = totalH - midGap
        local gH1 = math.max(grafMinH, math.floor(pairH / 2))
        local gH2 = math.max(grafMinH, pairH - gH1)
        local gY1 = graphsTop
        local gY2 = graphsTop + gH1 + midGap
        return gY1, gH1, gY2, gH2
    end

    -- Baseline Y for short in-plot labels (GPU / network dual graphs).
    local function graphInsetLabelBaseline(gY, gH, labelFs, pad)
        pad = pad or 8
        return math.min(gY + gH - 4, gY + labelFs + pad + 2)
    end

    -- == Section 1: Processador (CPU) ==
    local y = topInset
    local cpuUsage = conky_parse("${cpu cpu0}")
    local cpuTemp = conky_parse("${acpitemp}")
    if cpuTemp == "" then
        cpuTemp = conky_parse("${hwmon 0 temp 1}")
    end
    if cpuTemp == "" then
        cpuTemp = "N/A"
    end
    secao_cabecalho_linha("Processador", cpuUsage .. "% · " .. cpuTemp .. "°C", x, y, corProcessador, contentW)
    local cpuGY, cpuGH = graphGeometry(y)

    hist_push(cpu_hist, parse_number(conky_parse("${cpu cpu0}")), GRAPH_LEN)
    desenhaGraficoLinha(corProcessador, grafX, cpuGY, grafW, cpuGH, hist_series(cpu_hist, GRAPH_LEN))

    -- == Section 2: Memória (RAM) ==
    y = y + alturaSecao + gapSecao
    local memUsedPercent = parse_number(conky_parse("${memperc}"))
    local memUsedStr = conky_parse("${mem}")
    local memTotalStr = conky_parse("${memmax}")
    local ramStatsStr = memUsedStr
        .. " / "
        .. memTotalStr
        .. " · Swap: "
        .. conky_parse("${swapperc}")
        .. "%"
    secao_cabecalho_linha("Memória", ramStatsStr, x, y, corMemoria, contentW)
    local ramGY, ramGH = graphGeometry(y)

    local ramLargura = grafW
    local ramAltura = ramGH
    local ramBarraAltura = (memUsedPercent / 100) * ramAltura
    local ramBarraX = grafX
    local ramBarraY = ramGY + ramAltura - ramBarraAltura
    local pr, pg, pb = hex2rgb(corMemoria)
    local gradRam = cairo_pattern_create_linear(ramBarraX, ramBarraY, ramBarraX, ramBarraY + ramBarraAltura)
    cairo_pattern_add_color_stop_rgba(gradRam, 0, pr, pg, pb, 0.55)
    cairo_pattern_add_color_stop_rgba(gradRam, 1, pr, pg, pb, 0.95)
    cairo_set_source_rgba(cr, 0.18, 0.19, 0.22, 1)
    cairo_rectangle(cr, grafX, ramGY, ramLargura, ramAltura)
    cairo_fill(cr)
    cairo_set_source(cr, gradRam)
    cairo_rectangle(cr, ramBarraX, ramBarraY, ramLargura, ramBarraAltura)
    cairo_fill(cr)
    cairo_pattern_destroy(gradRam)

    -- == Section 3: GPU (nvidia-smi; Wayland-safe) — dual graphs: load + VRAM % ==
    y = y + alturaSecao + gapSecao
    local gpuSample = 0
    local gpuVramPerc = 0
    local gpuLineStats = "GPU: set useNvidiaSmi=true and install nvidia-utils (nvidia-smi)"
    if useNvidiaSmi then
        local raw = trim(
            conky_parse(
                "${execi "
                    .. nvidiaSmiInterval
                    .. " nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits}"
            )
        )
        local firstLine = (raw:match("^[^\r\n]+") or raw)
        firstLine = trim(firstLine)
        local lower = firstLine:lower()
        if firstLine ~= "" and not lower:find("failed", 1, true) and not lower:find("error", 1, true) then
            local parts = {}
            for token in firstLine:gmatch("[^,]+") do
                parts[#parts + 1] = trim(token)
            end
            if #parts >= 4 then
                gpuSample = parse_number(parts[1])
                local tempN = parse_number(parts[2])
                local memU = parse_number(parts[3])
                local memT = parse_number(parts[4])
                gpuVramPerc = (memT > 0) and (100 * memU / memT) or 0
                gpuLineStats = string.format(
                    "%.0f%% · VRAM: %.0f/%.0f MiB (%.0f%%) · %.0f°C",
                    gpuSample,
                    memU,
                    memT,
                    gpuVramPerc,
                    tempN
                )
            else
                gpuLineStats = "GPU: unexpected nvidia-smi output"
            end
        else
            gpuLineStats = "GPU: nvidia-smi unavailable"
        end
    else
        gpuLineStats = "GPU: useNvidiaSmi=false in conky.lua"
    end
    secao_cabecalho_linha("GPU", gpuLineStats, x, y, corGPU, contentW)
    local gpuGY1, gpuGH1, gpuGY2, gpuGH2 = graphGeometryDual(y)
    hist_push(gpu_hist, gpuSample, GRAPH_LEN)
    hist_push(gpu_vram_hist, gpuVramPerc, GRAPH_LEN)

    desenhaGraficoLinha(corGPU, grafX, gpuGY1, grafW, gpuGH1, hist_series(gpu_hist, GRAPH_LEN))
    desenhaGraficoLinha(corGPUMem, grafX, gpuGY2, grafW, gpuGH2, hist_series(gpu_vram_hist, GRAPH_LEN))

    -- In-plot labels (same colours as series); drawn after graphs so they stay on top.
    local gpuLabelFs = 10
    local gpuPad = 8
    texto("GPU", grafX + gpuPad, graphInsetLabelBaseline(gpuGY1, gpuGH1, gpuLabelFs, gpuPad), corGPU, gpuLabelFs, "left", true)
    texto("VRAM", grafX + gpuPad, graphInsetLabelBaseline(gpuGY2, gpuGH2, gpuLabelFs, gpuPad), corGPUMem, gpuLabelFs, "left", true)

    -- == Section 4: Disco (Disk) — dual graphs: read (L) + write (G) ==
    y = y + alturaSecao + gapSecao
    local readSpeed = conky_parse("${diskio_read " .. diskioDevice .. "}")
    local writeSpeed = conky_parse("${diskio_write " .. diskioDevice .. "}")
    secao_cabecalho_linha("Disco", "L: " .. readSpeed .. " · G: " .. writeSpeed, x, y, corDisco, contentW)
    local diskGY1, diskGH1, diskGY2, diskGH2 = graphGeometryDual(y)
    local dr = parse_number(conky_parse("${diskio_read " .. diskioDevice .. "}"))
    local dw = parse_number(conky_parse("${diskio_write " .. diskioDevice .. "}"))
    hist_push(disk_read_hist, dr, GRAPH_LEN)
    hist_push(disk_write_hist, dw, GRAPH_LEN)

    desenhaGraficoLinha(corDiscoRead, grafX, diskGY1, grafW, diskGH1, normalize_0_100(hist_series(disk_read_hist, GRAPH_LEN)))
    desenhaGraficoLinha(corDiscoWrite, grafX, diskGY2, grafW, diskGH2, normalize_0_100(hist_series(disk_write_hist, GRAPH_LEN)))

    local diskLabelFs = 10
    local diskPad = 8
    texto("L", grafX + diskPad, graphInsetLabelBaseline(diskGY1, diskGH1, diskLabelFs, diskPad), corDiscoRead, diskLabelFs, "left", true)
    texto("G", grafX + diskPad, graphInsetLabelBaseline(diskGY2, diskGH2, diskLabelFs, diskPad), corDiscoWrite, diskLabelFs, "left", true)

    -- == Section 5: Rede (Network) — dual graphs: upload + download ==
    y = y + alturaSecao + gapSecao
    local upSpeed = conky_parse("${upspeed " .. wlanAdapter .. "}")
    local downSpeed = conky_parse("${downspeed " .. wlanAdapter .. "}")
    secao_cabecalho_linha("Wi-Fi", "Up: " .. upSpeed .. " · Down: " .. downSpeed, x, y, corRede, contentW)
    local netGY1, netGH1, netGY2, netGH2 = graphGeometryDual(y)
    local upf = parse_number(conky_parse("${upspeedf " .. wlanAdapter .. "}"))
    local downf = parse_number(conky_parse("${downspeedf " .. wlanAdapter .. "}"))
    hist_push(net_up_hist, upf, GRAPH_LEN)
    hist_push(net_down_hist, downf, GRAPH_LEN)

    desenhaGraficoLinha(corRedeUp, grafX, netGY1, grafW, netGH1, normalize_0_100(hist_series(net_up_hist, GRAPH_LEN)))
    desenhaGraficoLinha(corRedeDown, grafX, netGY2, grafW, netGH2, normalize_0_100(hist_series(net_down_hist, GRAPH_LEN)))

    local netLabelFs = 10
    local netPad = 8
    texto("Up", grafX + netPad, graphInsetLabelBaseline(netGY1, netGH1, netLabelFs, netPad), corRedeUp, netLabelFs, "left", true)
    texto("Down", grafX + netPad, graphInsetLabelBaseline(netGY2, netGH2, netLabelFs, netPad), corRedeDown, netLabelFs, "left", true)

    if DEBUG_DRAW then
        local dbgLines = {
            "DEBUG graficos-verticais tick=" .. _debug_ticks,
            "If you see yellow text, conky_main ran and Cairo drew on this surface.",
            "surface=" .. surfaceSource .. "  cairo_cs_nil=" .. tostring(cs == nil),
            "window WxH=" .. width .. "x" .. height .. "  ownSurface_destroy=" .. tostring(ownSurface),
            "cpu0 raw=[" .. trunc(conky_parse("${cpu cpu0}"), 36) .. "] parse=" .. parse_number(conky_parse("${cpu cpu0}")),
            "memperc raw=[" .. trunc(conky_parse("${memperc}"), 24) .. "] parse=" .. parse_number(conky_parse("${memperc}")),
            "cpu_hist_len=" .. #cpu_hist .. "  wlan=" .. wlanAdapter .. "  diskio=" .. diskioDevice,
            "cairo_xlib require ok=" .. tostring(cairo_xlib_ok),
            "Set DEBUG_DRAW=false in conky.lua when finished.",
        }
        draw_debug_overlay(surfaceSource, width, height, dbgLines)
    end

    cairo_surface_flush(cs)
    cairo_destroy(cr)
    if ownSurface then
        cairo_surface_destroy(cs)
    end
    cr = nil
end

-- One line on load so you can confirm this file is the one Conky picked (stderr).
if io and io.stderr then
    io.stderr:write("[graficos-verticais] conky.lua loaded\n")
end
