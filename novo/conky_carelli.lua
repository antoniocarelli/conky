-- o que e onde exibir
-- Posicao Rede
exibeRede = true
redeX = 50 --1150
redeY = 50 --400

-- Posicao Indicador
exibeIndicadores = true
indicadoresX = 750
indicadoresY = 50


-- Configuracoes gerais
fontName="Technical CE"
fontSize=17
corLabel = "#44d31f"
corValor = "#f09309"
corSeparador = "#00a4d1"
tableFontColor = "#FFFFFF"
corTitulo = "#FFFFFF" -- Linha do cabecalho
corPar = "#53c9d6"    -- Linhas pares
corImpar = "#61EAF9"  -- Linhas impares
corVerde =  "#44d31f"
corVermelha = "#df3b11"
corLilas = "#f35aca"
corLaranja = "#f09309"
corAzul = "#53c9d6"

-- Customizacoes dos adaptadores de rede
wlanAdapter = "wlp3s0"
ethAdapter = "enp2s0"

-- Configuracees de Rede --
gapRede = 21  -- Espaco para pular para proxima linha (texto e tabela)
corLabelRede = corLabel
corValorRede = corValor
corSeparadorRede = corSeparador

-- Parametros da tabela Rede
linecapRede = CAIRO_LINE_CAP_BUTT
larguraTabelaRede = 650
transparenciaRede = 0.15
corTituloRede = corTitulo -- Linha do cabecalho
corParRede = corPar    -- Linhas pares
corImparRede = corImpar  -- Linhas impares
tableFontColorRede = tableFontColor

-- Parametros Indicadores
gapIndicador = 120
raioIndicador = 50
espessuraIndicador = 8
-------------------

require 'cairo'

-- Converte o angulo de graus para radianos
-- E corrige o angulo inicial do arco (-90)
function angulo( graus )
  local radianos = (graus - 90) * (math.pi/180)
  return radianos
end

function desenhaLinha(corHex, startX, startY, endX, endY, espessura)
  local r, g, b = hex2rgb(corHex)
  local alpha=1
  cairo_set_source_rgba (cr,r,g,b,alpha)

  -- Configura a linha
  cairo_set_line_width (cr, espessura)
  cairo_set_line_cap  (cr, linecapRede)

  cairo_move_to (cr, startX, startY)
  cairo_line_to (cr, endX, endY)

  cairo_stroke (cr)
end

function desenhaArco(corHex, raio, centroX, centroY, posX, posY, espessura, anguloInicial, anguloFinal)
  local r, g, b = hex2rgb(corHex)
  local alpha=1
  cairo_set_source_rgba (cr,r,g,b,alpha)

  -- Configura o arco
  cairo_set_line_width (cr, espessura)
  cairo_set_line_cap  (cr, linecapRede)

  local startAngle = angulo(anguloInicial)
  local endAngle = angulo(anguloFinal)
  --cairo_move_to (cr, posX, posY)
  cairo_arc (cr, centroX, centroY, raio, startAngle, endAngle)

  cairo_stroke (cr)
end

function hex2rgb(hex)
    local hex = hex:gsub("#","")
    return (tonumber("0x"..hex:sub(1,2))/255), (tonumber("0x"..hex:sub(3,4))/255), tonumber(("0x"..hex:sub(5,6))/255)
end

function texto(txt, x, y, corHex, fs)
    fs = fs or fontSize

    -- Inicializa o Cairo com as configuracoes de fontes
    local red,green,blue = hex2rgb(corHex)
    local alpha=1
    cairo_set_source_rgba(cr, red, green, blue, alpha)
    cairo_select_font_face(cr, fontName, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)
    cairo_set_font_size(cr, fs)

    cairo_move_to(cr, x, y)
    cairo_show_text(cr, txt)
    cairo_stroke(cr)
end

function titulo(label, x, y, corHex, altura, largura)
  -- configuracoes iniciais
  local espessura = 6 --Usar apenas numeros pares
  local raio = 50

  -- Escreve titulo
  local xpos = x + 50
  local ypos = y
  texto(label, xpos, ypos, corHex, 32)

  -- Desenha a linha horizontal
  local startX = x
  local startY = y-8
  local endX = startX + 40
  local endY = startY
  desenhaLinha(corHex, startX, startY, endX, endY, espessura)

  startX = endX + 90
  endX = x + largura - raio - (espessura/2)
  desenhaLinha(corHex, startX, startY, endX, endY, espessura)

  --desenha a curva
  local centroX = endX
  local centroY = endY + raio
  local aInicial = 0
  local aFinal = 90
  desenhaArco(corHex, raio, centroX, centroY, startX, startY, espessura, aInicial, aFinal)

  -- desenha a linha vertical
  startX = endX + raio
  startY = endY + raio
  endX = startX
  endY = endY + altura
  desenhaLinha(corHex, startX, startY, endX, endY, espessura)
end

function indicadorArco(x, y, valor, label, cor)
     --indicator value settings
     local maxValue=360
     local inicial = maxValue * valor / 100
     local final = 360
     local centroX = x + raioIndicador
     local centroY = y + raioIndicador

    -- Desenha o arco
    desenhaArco(cor, raioIndicador, centroX, centroY, x, y, espessuraIndicador, inicial, final)

--
--     -- Label
--     -- Centraliza o texto no arco
--     local extents = cairo_text_extents_t:create()
--     tolua.takeownership(extents)
--     cairo_text_extents(cr, label, extents)
--     x = ring_center_x - (extents.width / 2 + extents.x_bearing)
--     y = ring_center_y - (extents.height / 2 + extents.y_bearing) - 9
--
--     texto(label, x, y, red, green, blue )
--
--     txt = valor .. "%"
--     cairo_text_extents(cr, txt, extents)
--     x = ring_center_x - (extents.width / 2 + extents.x_bearing)
--     y = ring_center_y - (extents.height / 2 + extents.y_bearing) + 9
--
--     texto(txt, x, y, red, green, blue )
end

function desenhaTabela(xx, yy, pos)
  local cor = corImparRede

  -- Ajusta a cor da linha
  if pos == -1 then         -- Linha do cabecalho
    cor = corTituloRede
  elseif pos % 2 == 0 then  -- Linhas pares
    cor = corParRede
  else                      -- Linhas impares
    cor = corImparRede
  end

  -- Configura a tabela
  cairo_set_line_width (cr, gapRede)
  cairo_set_line_cap  (cr, linecapRede)
  local vermelho,verde,azul=hex2rgb(cor)
  cairo_set_source_rgba (cr,vermelho,verde,azul,transparenciaRede)

  -- Desenha a tabela
  local endy = yy-5
  local endx = xx-5
  cairo_move_to (cr,endx,endy)
  endx = xx + larguraTabelaRede
  cairo_line_to (cr,endx,endy)

  cairo_stroke (cr)
end

function openPorts(x, y)
  local txt = "Open Ports:"
  texto(txt, x, y, corLabelRede, fontSize)

  local xx = x + 100
  local numPorts = tostring(conky_parse("${tcp_portmon 1 65535 count}"))
  texto(numPorts, xx, y, corValorRede, fontSize)

  local yy = y+gapRede+gapRede

  --Titulos da tabela
  txt = "Port"
  texto(txt, x, yy, tableFontColorRede, fontSize)
  txt = "IP"
  ipX = x+70
  texto(txt, ipX, yy, tableFontColorRede, fontSize)
  txt = "Host"
  hostX = ipX+140
  texto(txt, hostX, yy, tableFontColorRede, fontSize)
  txt = "rhost"

  -- Desenha bordas do titulo
  desenhaTabela(x, yy, -1)

  for i=0,numPorts-1 do
      local rport = tostring(conky_parse("${tcp_portmon 1 65535 rport " .. i .. "}"))
      local rip = tostring(conky_parse("${tcp_portmon 1 65535 rip " .. i .. "}"))
      local rhost = conky_parse("${tcp_portmon 1 65535 rhost " .. i .. "}")

      yy = yy+gapRede
      texto(rport, x, yy, tableFontColorRede, fontSize)
      texto(rip, ipX, yy, tableFontColorRede, fontSize)
      texto(rhost, hostX, yy, tableFontColorRede, fontSize)
      desenhaTabela(x, yy, i)
  end

  return yy
end

function redeInfo(x, y, adaptador)
  texto(adaptador, x, y, corLabelRede, fontSize)
  local essid = tostring(conky_parse("${wireless_essid " .. adaptador .. "}"))

  if essid ~= nil and essid ~= "" then
    essid = "(" .. essid .. ")"
  end

  local xx = x + 60
  local yy = y
  texto(essid, xx, yy, corValorRede, fontSize)

  local addrs = tostring(conky_parse("${addr " .. adaptador .. "}"))
  xx = x
  yy = yy + gapRede
  texto(addrs, xx, yy, corValorRede, fontSize)

  xx = x
  yy = yy + gapRede
  texto("Upload:", xx, yy, corLabelRede, fontSize)

  local upspeed = tostring(conky_parse("${upspeed " .. adaptador .. "}"))
  xx = x + 60
  texto(upspeed, xx, yy, corValorRede, fontSize)

  xx = x
  yy = yy + gapRede
  texto("Download:", xx, yy, corLabelRede, fontSize)

  local downspeed = tostring(conky_parse("${downspeed " .. adaptador .. "}"))
  xx = x + 80
  texto(downspeed, xx, yy, corValorRede, fontSize)

  return yy
end

function pip (x, y)
  local xx = x
  local yy = y
  texto("Public IP:", xx, yy, corLabelRede, fontSize)

  local ip = tostring(conky_parse("${execi 3600 curl ipinfo.io/ip}"))
  xx = x + 75
  texto(ip, xx, yy, corValorRede, fontSize)

  return yy
end

function rede(startX, startY)
  local altura = 9*gapRede
  local largura = larguraTabelaRede
  titulo("Rede", startX, startY, corSeparadorRede, altura, largura)

  -- Wlan
  local x = startX
  local y = startY + 40
  redeInfo(x, y, wlanAdapter)

  -- Eth
  x = startX + 300
  y = startY + 40
  y = redeInfo(x, y, ethAdapter)

  -- Public IP:
  x = startX
  y = y + gapRede + gapRede
  y = pip(x, y)

  -- Lista de portas abertas
  x = startX
  y = y + gapRede
  openPorts(x, y)
end

function indicadores(startX, startY)
    -- Indicador CPU
    local valor = tonumber( conky_parse("${cpu cpu0}") )
    indicadorArco(startX, startY, valor, "CPU", corAzul)


    -- Indicador RAM
    -- x = x + gapIndicador
    -- valor = conky_parse("${memperc}")
    -- indicador_arco(x, y, valor, "RAM", rgb(255, 255, 112))

    -- Indicador SWAP
    -- x = x + gapIndicador
    -- valor = conky_parse("${swapperc}")
    -- indicador_arco(x, y, valor, "SWAP", rgb(220, 127, 220))

    -- Indicador Disco (Home)
    -- x = x + gapIndicador
    -- valor  = 100-tonumber(conky_parse("${fs_free_perc /home}"))
    -- indicador_arco(x, y, valor, "Home", rgb(0, 164, 209))

    -- Indicador Disco (Root)
--     x = x + gapIndicador
--     valor  = 100-tonumber(conky_parse("${fs_free_perc /}"))
-- --    indicador_arco(x, y, valor, "Root", rgb(141, 255, 141))
--     indicador_arco(x, y, valor, "Root", hex2rgb("#44d31f"))
end

function conky_main()
    if conky_window == nil then
        return
    end


    -- Inicializa cairo
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    cr = cairo_create(cs) --CR definido no conky_main

    -- Rede
    if exibeRede then rede(redeX, redeY) end

    -- Indicadores
    if exibeIndicadores then indicadores(indicadoresX, indicadoresY) end

    -- Finaliza cairo
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr=nil
end
