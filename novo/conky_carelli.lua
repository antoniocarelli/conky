-- Configurações gerais
fontName="Technical CE"
fontSize=17
fontSlant=CAIRO_FONT_SLANT_NORMAL
fontFace=CAIRO_FONT_WEIGHT_BOLD
corLabel = "#44d31f"
corValor = "#f09309"
tableFontColor = "#FFFFFF"
corTitulo = "#FFFFFF" -- Linha do cabeçalho
corPar = "#53c9d6"    -- Linhas pares
corImpar = "#61EAF9"  -- Linhas ímpares

-- Customizações dos adaptadores de rede
wlanAdapter = "wlp3s0"
ethAdapter = "enp2s0"

-- Configurações de Rede --
gapRede = 21  -- Espaço para pular para próxima linha (texto e tabela)
corLabelRede = corLabel
corValorRede = corValor

-- Parâmetros da tabela Rede
linecapRede = CAIRO_LINE_CAP_BUTT
larguraTabelaRede = 650
transparenciaRede = 0.15

corTituloRede = corTitulo -- Linha do cabeçalho
corParRede = corPar    -- Linhas pares
corImparRede = corImpar  -- Linhas ímpares
tableFontColorRede = tableFontColor


-------------------

-- Converte o ângulo de graus para radianos
-- E corrige o ângulo inicial do arco (-90º)
-- function angulo( graus )
--     radianos = (graus - 90) * (math.pi/180)
--     return radianos
-- end



require 'cairo'

function desenhaLinha(corHex, startX, startY, endX, endY, espessura)
  r, g, b = hex2rgb(corHex)
  alpha=1
  cairo_set_source_rgba (cr,r,g,b,alpha)

  -- Configura a linha
  cairo_set_line_width (cr, espessura)
  cairo_set_line_cap  (cr, linecapRede)

  cairo_move_to (cr, startX, startY)
  cairo_line_to (cr, endX, endY)

  cairo_stroke (cr)
end

function desenhaArco(corHex, raio, centroX, centroY, posX, posY, espessura, anguloInicial, anguloFinal)
  r, g, b = hex2rgb(corHex)
  alpha=1
  cairo_set_source_rgba (cr,r,g,b,alpha)

  -- Configura o arco
  cairo_set_line_width (cr, espessura)
  cairo_set_line_cap  (cr, linecapRede)

  startAngle = angulo(anguloInicial)
  endAngle = angulo(anguloFinal)
  cairo_move_to (cr, posX, posY)
  cairo_arc (cr, centroX, centroY, raio, startAngle, endAngle)

  cairo_stroke (cr)
end

function hex2rgb(hex)
    hex = hex:gsub("#","")
    return (tonumber("0x"..hex:sub(1,2))/255), (tonumber("0x"..hex:sub(3,4))/255), tonumber(("0x"..hex:sub(5,6))/255)
end

function texto(txt, x, y, corHex, fs)
    size = fontSize
    if fs ~= nil and fs ~= 0 then
      size = fs
    end

    -- Inicializa o Cairo com as configurações de fontes
    cairo_select_font_face (cr, font, fontNameSlant, fontFace);
    cairo_set_font_size (cr, size)

    text=txt
    xpos,ypos=x,y
    red,green,blue = hex2rgb(corHex)
    alpha=1
    cairo_set_source_rgba (cr,red,green,blue,alpha)

    cairo_move_to (cr,xpos,ypos)
    cairo_show_text (cr,text)
    cairo_stroke (cr)
end

function titulo(label, x, y, corHex, altura, largura)
  -- configurações iniciais
  espessura = 6 --Usar apenas números pares
  raio = 50

  -- Escreve título
  xpos = x + 50
  ypos = y
  texto(label, xpos, ypos, corHex, 32)

  -- Desenha a linha horizontal
  startX = x
  startY = y-8
  endX = startX + 40
  endY = startY
  desenhaLinha(corHex, startX, startY, endX, endY, espessura)

  startX = endX + 90
  endX = x + largura - raio - (espessura/2)
  desenhaLinha(corHex, startX, startY, endX, endY, espessura)

  --desenha a curva
  centroX = endX
  centroY = endY + raio
  aInicial = 0
  aFinal = 90
  desenhaArco(corHex, raio, centroX, centroY, startX, startY, espessura, aInicial, aFinal)

  -- desenha a linha vertical
  startX = endX + raio
  startY = endY + raio
  endX = startX
  endY = endY + altura
  desenhaLinha(corHex, startX, startY, endX, endY, espessura)
end

-- function indicador_arco(x, y, valor, label, red, green, blue)
--     --SETTINGS
--     --rings size
--     ring_center_x=x
--     ring_center_y=y
--
--     ring_radius=50
--     ring_width=10
--
--     --colors
--     --set background colors
--     ring_in_red, ring_in_green, ring_in_blue=rgb(0,0,0)
--     ring_in_alpha=1
--
--     --set indicator colors
--     ring_bg_red=red
--     ring_bg_green=green
--     ring_bg_blue=blue
--     ring_bg_alpha=1
--
--     --indicator value settings
--     value=valor
--     max_value=100
--
--     --draw background
--     cairo_set_line_width (cr,ring_width)
--     cairo_set_source_rgba (cr,ring_bg_red,ring_bg_green,ring_bg_blue,ring_bg_alpha)
--     cairo_arc (cr,ring_center_x,ring_center_y,ring_radius,0,2*math.pi)
--     cairo_stroke (cr)
--
--     cairo_set_line_width (cr,ring_width+2)
--     start_angle = angulo(0)
--     end_angle=angulo( value*(360/max_value) )
--
--     --print (end_angle)
--     cairo_set_source_rgba (cr,ring_in_red,ring_in_green,ring_in_blue,ring_in_alpha)
--     cairo_arc (cr,ring_center_x,ring_center_y,ring_radius,start_angle,end_angle)
--     cairo_stroke (cr)
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
-- end

function desenhaTabela(xx, yy, pos)
  -- Ajusta a cor da linha
  if pos == -1 then         -- Linha do cabeçalho
    cor = corTituloRede
  elseif pos % 2 == 0 then  -- Linhas pares
    cor = corParRede
  else                      -- Linhas ímpares
    cor = corImparRede
  end

  -- Configura a tabela
  cairo_set_line_width (cr, gapRede)
  cairo_set_line_cap  (cr, linecapRede)
  vermelho,verde,azul=hex2rgb(cor)
  cairo_set_source_rgba (cr,vermelho,verde,azul,transparenciaRede)

  -- Desenha a tabela
  endy = yy-5
  endx = xx-5
  cairo_move_to (cr,endx,endy)
  endx = xx + larguraTabelaRede
  cairo_line_to (cr,endx,endy)

  cairo_stroke (cr)
end

function openPorts(x, y)
  txt = "Open Ports:"
  texto(txt, x, y, corLabelRede )

  xx = x + 100
  numPorts = tostring(conky_parse("${tcp_portmon 1 65535 count}"))
  texto(numPorts, xx, y, corValorRede )

  y = y+gapRede+gapRede

  --Títulos da tabela
  txt = "Port"
  texto(txt, x, y, tableFontColorRede )
  txt = "IP"
  ipX = x+70
  texto(txt, ipX, y, tableFontColorRede )
  txt = "Host"
  hostX = ipX+140
  texto(txt, hostX, y, tableFontColorRede )
  txt = "rhost"

  -- Desenha bordas do titulo
  desenhaTabela(x, y, -1)

  for i=0,numPorts-1 do
      rport = tostring(conky_parse("${tcp_portmon 1 65535 rport " .. i .. "}"))
      rip = tostring(conky_parse("${tcp_portmon 1 65535 rip " .. i .. "}"))
      rhost = conky_parse("${tcp_portmon 1 65535 rhost " .. i .. "}")

      y = y+gapRede
      texto(rport, x, y, tableFontColorRede )
      texto(rip, ipX, y, tableFontColorRede )
      texto(rhost, hostX, y, tableFontColorRede )
      desenhaTabela(x, y, i)
  end

  return y
end

function redeInfo(x, y, adaptador)
  texto(adaptador, x, y, corLabelRede )
  essid = tostring(conky_parse("${wireless_essid " .. adaptador .. "}"))

  if essid ~= nil and essid ~= "" then
    essid = "(" .. essid .. ")"
  end

  xx = x + 60
  yy = y
  texto(essid, xx, yy, corValorRede )

  addrs = tostring(conky_parse("${addr " .. adaptador .. "}"))
  xx = x
  yy = yy + gapRede
  texto(addrs, xx, yy, corValorRede )

  xx = x
  yy = yy + gapRede
  texto("Upload:", xx, yy, corLabelRede )

  upspeed = tostring(conky_parse("${upspeed " .. adaptador .. "}"))
  xx = x + 60
  texto(upspeed, xx, yy, corValorRede )

  xx = x
  yy = yy + gapRede
  texto("Download:", xx, yy, corLabelRede )

  downspeed = tostring(conky_parse("${downspeed " .. adaptador .. "}"))
  xx = x + 80
  texto(downspeed, xx, yy, corValorRede )

  return yy
end

function pip (x, y)
  xx = x
  yy = y
  texto("Public IP:", xx, yy, corLabelRede )

  ip = tostring(conky_parse("${execi 3600 curl ipinfo.io/ip}"))
  xx = x + 75
  texto(ip, xx, yy, corValorRede )

  return yy
end

function rede(startX, startY)
  altura = 9*gapRede
  largura = larguraTabelaRede
  titulo("Rede", startX, startY, "#00a4d1", altura, largura)

  -- Wlan
  x = startX
  y = startY + 40
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

function conky_main()
    if conky_window == nil then
        return
    end

    -- Inicializa cairo
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    cr = cairo_create(cs)

    -- Posição Rede
--    x = 1150
--  	y = 400
    x = 720
  	y = 250
    rede(x, y)


--     -- Indicador CPU
--     gap = 120
--     x = startX + 50
--     y=80
--     valor = conky_parse("${cpu cpu0}")
--     indicador_arco(x, y, valor, "CPU", rgb(255, 117, 49))
--
--     -- Indicador RAM
--     x = x + gap
--     valor = conky_parse("${memperc}")
--     indicador_arco(x, y, valor, "RAM", rgb(255, 255, 112))
--
--     -- Indicador SWAP
--     x = x + gap
--     valor = conky_parse("${swapperc}")
--     indicador_arco(x, y, valor, "SWAP", rgb(220, 127, 220))
--
--     -- Indicador Disco (Home)
--     x = x + gap
--     valor  = 100-tonumber(conky_parse("${fs_free_perc /home}"))
--     indicador_arco(x, y, valor, "Home", rgb(0, 164, 209))
--
--     -- Indicador Disco (Root)
--     x = x + gap
--     valor  = 100-tonumber(conky_parse("${fs_free_perc /}"))
-- --    indicador_arco(x, y, valor, "Root", rgb(141, 255, 141))
--     indicador_arco(x, y, valor, "Root", hex2rgb("#44d31f"))
--
--     x = startX
--     y = y + 85
--     titulo("Indicadores", x, y, hex2rgb("#00a4d1"))



    -- Finaliza cairo
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr=nil
end
