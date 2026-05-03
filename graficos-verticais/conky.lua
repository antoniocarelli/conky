-- Conky Lua Module for Vertical Graphics Panel
-- ================================================

require 'cairo'

-- Configuration
fontName = "Roboto Medium"
fontSize = 14
largura = 740
altura = 1000

-- Network adapters
wlanAdapter = "wlp35s0"
ethAdapter = "enp34s0"

-- Colors (matching modelo.png)
corProcessador = "#1F5C8A"    -- Blue for CPU
corMemoria = "#8B3A6B"        -- Purple for RAM
corGPU = "#C43E4D"            -- Red for GPU
corDisco = "#E69138"          -- Orange for Disk
corRede = "#17A3B8"           -- Teal for Network

-- Border settings
raioBorda = 20
espessuraBorda = 6
margensBorda = 10

-- Graph settings
raioGrafico = 15
espessuraGrafico = 3

-- Title settings
gapTitulo = 10
alturaTitulo = 40

-- Gap between sections
gapSecao = 20

-- == Helper Functions ==

-- Convert hex to RGB
function hex2rgb(hex)
    local hex = hex:gsub("#", "")
    return {
        tonumber("0x" .. hex:sub(1, 2)) / 255,
        tonumber("0x" .. hex:sub(3, 4)) / 255,
        tonumber("0x" .. hex:sub(5, 6)) / 255
    }
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
    
    -- Draw graph data
    if dados and #dados > 0 then
        local step = largura / (#dados - 1)
        
        for i, valor in ipairs(dados) do
            local barraAltura = valor * altura / 100
            local barraX = x + (i - 1) * step
            local barraY = y + altura - barraAltura
            
            -- Create gradient for bar
            local grad = cairo_get_context(cr):create_linear_gradient(barraX, y, barraX, y + altura)
            
            -- Top color (lighter)
            cairo_pattern_add_color_stop_rgba(grad, 0, r, g, b, alpha * 0.3)
            -- Bottom color (darker)
            cairo_pattern_add_color_stop_rgba(grad, 1, r, g, b, alpha * 0.8)
            
            cairo_set_source(cr, grad)
            cairo_rectangle(cr, barraX, barraY, step, barraAltura)
            cairo_fill(cr)
        end
    end
end

-- Draw a simple line graph
function desenhaGraficoLinha(corHex, x, y, largura, altura, dados)
    local r, g, b = hex2rgb(corHex)
    local alpha = 0.8
    
    -- Draw graph background
    cairo_set_source_rgba(cr, r, g, b, alpha * 0.1)
    cairo_rectangle(cr, x, y, largura, altura)
    cairo_fill(cr)
    
    if dados and #dados > 0 then
        local step = largura / (#dados - 1)
        
        -- Draw connecting line
        cairo_set_source_rgba(cr, r, g, b, alpha)
        cairo_move_to(cr, x, y + altura)
        
        for i, valor in ipairs(dados) do
            local graficoX = x + (i - 1) * step
            local graficoY = y + altura - (valor * altura / 100)
            cairo_line_to(cr, graficoX, graficoY)
        end
        
        cairo_stroke(cr)
        
        -- Draw filled area under the line
        cairo_set_source_rgba(cr, r, g, b, alpha * 0.3)
        cairo_move_to(cr, x, y + altura)
        for i, valor in ipairs(dados) do
            local graficoX = x + (i - 1) * step
            local graficoY = y + altura - (valor * altura / 100)
            cairo_line_to(cr, graficoX, graficoY)
        end
        cairo_line_to(cr, x, y + altura)
        cairo_fill(cr)
    end
end

-- Draw text
function texto(txt, x, y, corHex, fs, align)
    fs = fs or fontSize
    align = align or "left"
    
    local red, green, blue = hex2rgb(corHex)
    local alpha = 0.8
    
    cairo_set_source_rgba(cr, red, green, blue, alpha)
    cairo_select_font_face(cr, fontName, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)
    cairo_set_font_size(cr, fs)
    
    -- Align text
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
    cairo_stroke(cr)
end

-- Draw title with border
function titulo(label, x, y, corHex, largura)
    -- Draw title text
    texto(label, x + 20, y - 10, corHex, 24, "left")
    
    -- Draw title border
    desenhaBorda(corHex, x, y - 10, largura, 10)
end

-- == Main Drawing Functions ==

function conky_main()
    -- Check if conky_window is available
    if not conky_window or not conky_window.draw_area then
        return
    end
    
    -- Set up conky drawing area
    local width = conky_window.width
    local height = conky_window.height
    
    -- Create Cairo context
    cr = cairo_create(conky_window.draw_area)
    
    -- Set background color (dark theme)
    cairo_set_source_rgba(cr, 0.1, 0.1, 0.12, 1.0)
    cairo_paint(cr)
    
    -- == Section 1: Processador (CPU) ==
    local x = margensBorda
    local y = margensBorda
    local larguraSecao = largura / 5
    local alturaSecao = height / 5
    
    -- CPU Title
    titulo("Processador", x, y, corProcessador, larguraSecao)
    
    -- CPU Usage Graph
    local cpuX = x + larguraSecao / 2
    local cpuY = y + alturaTitulo + gapSecao
    local cpuLargura = larguraSecao - 40
    local cpuAltura = alturaSecao - 20
    
    -- Get CPU usage data
    local cpuData = {}
    for i = 1, 30 do
        cpuData[i] = tonumber(conky_parse("${cpu " .. i .. "}%")) or 0
    end
    
    desenhaGraficoLinha(corProcessador, cpuX, cpuY, cpuLargura, cpuAltura, cpuData)
    
    -- CPU Text Info
    local cpuUsage = conky_parse("${cpu}%")
    local cpuTemp = conky_parse("${temp}")
    if cpuTemp == "" then cpuTemp = "N/A" end
    texto(cpuUsage, cpuX + cpuLargura / 2, cpuY + cpuAltura + gapSecao, corProcessador, 14, "center")
    texto(cpuTemp, cpuX + cpuLargura / 2, cpuY + cpuAltura + gapSecao + 20, corProcessador, 12, "center")
    
    -- == Section 2: Memória (RAM) ==
    y = y + alturaSecao
    titulo("Memória", x, y, corMemoria, larguraSecao)
    
    -- RAM Usage Bar
    local ramX = x + larguraSecao / 2
    local ramY = y + alturaTitulo + gapSecao
    local ramLargura = larguraSecao - 40
    local ramAltura = alturaSecao - 20
    
    -- Get RAM usage
    local memTotal = tonumber(conky_parse("${mem}")) or 0
    local memUsed = tonumber(conky_parse("${mem_total}")) or 0
    local memFree = tonumber(conky_parse("${mem_free}")) or 0
    local memUsedPercent = ((memUsed - memFree) / memTotal) * 100
    
    -- Draw RAM bar
    local ramBarraAltura = (memUsedPercent / 100) * ramAltura
    local ramBarraX = ramX
    local ramBarraY = ramY + ramAltura - ramBarraAltura
    
    -- Create gradient for RAM bar
    local gradRam = cairo_get_context(cr):create_linear_gradient(ramBarraX, ramBarraY, ramBarraX, ramBarraY + ramBarraAltura)
    cairo_pattern_add_color_stop_rgba(gradRam, 0, 0.5, 0.2, 0.5, 0.6)
    cairo_pattern_add_color_stop_rgba(gradRam, 1, 0.5, 0.2, 0.5, 0.9)
    
    cairo_set_source(cr, gradRam)
    cairo_rectangle(cr, ramBarraX, ramBarraY, ramLargura, ramBarraAltura)
    cairo_fill(cr)
    
    -- RAM Text Info
    texto(memUsed .. " / " .. memTotal, ramX + ramLargura / 2, ramY + ramAltura + gapSecao, corMemoria, 14, "center")
    texto("Swap: " .. conky_parse("${swapperc}%"), ramX + ramLargura / 2, ramY + ramAltura + gapSecao + 20, corMemoria, 12, "center")
    
    -- == Section 3: GPU ==
    y = y + alturaSecao
    titulo("GPU", x, y, corGPU, larguraSecao)
    
    -- GPU Usage Graph
    local gpuX = x + larguraSecao / 2
    local gpuY = y + alturaTitulo + gapSecao
    local gpuLargura = larguraSecao - 40
    local gpuAltura = alturaSecao - 20
    
    -- Get GPU usage data
    local gpuData = {}
    for i = 1, 30 do
        gpuData[i] = tonumber(conky_parse("${gpu " .. i .. "}%")) or 0
    end
    
    desenhaGraficoLinha(corGPU, gpuX, gpuY, gpuLargura, gpuAltura, gpuData)
    
    -- GPU Text Info
    local gpuUsage = conky_parse("${gpu}%")
    local gpuMem = conky_parse("${gpu_mem_total}")
    local gpuMemUsed = conky_parse("${gpu_mem_used}")
    local gpuTemp = conky_parse("${gpu_temp}")
    
    texto(gpuUsage, gpuX + gpuLargura / 2, gpuY + gpuAltura + gapSecao, corGPU, 14, "center")
    texto(gpuMem .. " / " .. gpuMemUsed, gpuX + gpuLargura / 2, gpuY + gpuAltura + gapSecao + 20, corGPU, 12, "center")
    texto(gpuTemp .. "°C", gpuX + gpuLargura / 2, gpuY + gpuAltura + gapSecao + 40, corGPU, 12, "center")
    
    -- == Section 4: Disco (Disk) ==
    y = y + alturaSecao
    titulo("Unidade 500GB", x, y, corDisco, larguraSecao)
    
    -- Disk Activity Graph
    local discoX = x + larguraSecao / 2
    local discoY = y + alturaTitulo + gapSecao
    local discoLargura = larguraSecao - 40
    local discoAltura = alturaSecao - 20
    
    -- Get disk read/write data
    local discoData = {}
    for i = 1, 30 do
        local read = tonumber(conky_parse("${disk_read " .. i .. "}")) or 0
        local write = tonumber(conky_parse("${disk_write " .. i .. "}")) or 0
        discoData[i] = (read + write) / 2  -- Average of read/write
    end
    
    desenhaGraficoLinha(corDisco, discoX, discoY, discoLargura, discoAltura, discoData)
    
    -- Disk Text Info
    local readSpeed = conky_parse("${disk_read_mbps}")
    local writeSpeed = conky_parse("${disk_write_mbps}")
    texto("R: " .. readSpeed .. " MB/s", discoX + discoLargura / 2, discoY + discoAltura + gapSecao, corDisco, 14, "center")
    texto("G: " .. writeSpeed .. " MB/s", discoX + discoLargura / 2, discoY + discoAltura + gapSecao + 20, corDisco, 14, "center")
    
    -- == Section 5: Rede (Network) ==
    y = y + alturaSecao
    titulo("Conexão Wi-Fi", x, y, corRede, larguraSecao)
    
    -- Network Activity Graph
    local redeX = x + larguraSecao / 2
    local redeY = y + alturaTitulo + gapSecao
    local redeLargura = larguraSecao - 40
    local redeAltura = alturaSecao - 20
    
    -- Get network data
    local redeData = {}
    for i = 1, 30 do
        local up = tonumber(conky_parse("${upspeed " .. wlanAdapter .. "}")) or 0
        local down = tonumber(conky_parse("${downspeed " .. wlanAdapter .. "}")) or 0
        redeData[i] = (up + down) / 2
    end
    
    desenhaGraficoLinha(corRede, redeX, redeY, redeLargura, redeAltura, redeData)
    
    -- Network Text Info
    local upSpeed = conky_parse("${upspeed " .. wlanAdapter .. "}")
    local downSpeed = conky_parse("${downspeed " .. wlanAdapter .. "}")
    texto("R: " .. upSpeed, redeX + redeLargura / 2, redeY + redeAltura + gapSecao, corRede, 14, "center")
    texto("E: " .. downSpeed, redeX + redeLargura / 2, redeY + redeAltura + gapSecao + 20, corRede, 14, "center")
    
    -- == Footer ==
    texto("Conky Vertical Panel", largura / 2, height - 20, "#FFFFFF", 12, "center")
    
    -- Clean up
    cairo_destroy(cr)
end
