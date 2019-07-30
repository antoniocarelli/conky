require 'cairo'

-- Configurações --
space = 21  -- Espaço para pular para próxima linha (texto e tabela)

-- Configurações da fonte que será utilizada
font="Technical CE"
font_size=17
font_slant=CAIRO_FONT_SLANT_NORMAL
font_face=CAIRO_FONT_WEIGHT_BOLD
corLabel = "#44d31f"
corValor = "#f09309"

-- Parâmetros da tabela
line_cap = CAIRO_LINE_CAP_BUTT
larguraTabela = 650
transparencia = 0.15
corTitulo = "#FFFFFF" -- Linha do cabeçalho
corPar = "#53c9d6"    -- Linhas pares
corImpar = "#61EAF9"  -- Linhas ímpares
tableFontColor = "#FFFFFF"

-- Customizações dos sensores
wlanAdapter = "wlp3s0"
ethAdapter = "enp2s0"
-------------------

-- Converte o ângulo de graus para radianos
-- E corrige o ângulo inicial do arco (-90º)
function angulo( graus )
    radianos = (graus - 90) * (math.pi/180)
    return radianos
end

function rgb( r, g, b )
    red = r/255
    green = g/255
    blue = b/255

    return red, green, blue
end

function hex2rgb(hex)
    hex = hex:gsub("#","")
    return (tonumber("0x"..hex:sub(1,2))/255), (tonumber("0x"..hex:sub(3,4))/255), tonumber(("0x"..hex:sub(5,6))/255)
end

function texto(txt, x, y, r, g, b)
    -- Inicializa o Cairo com as configurações de fontes
    cairo_select_font_face (cr, font, font_slant, font_face);
    cairo_set_font_size (cr, font_size)

    text=txt
    xpos,ypos=x,y
    red,green,blue = r,g,b
    alpha=1
    cairo_set_source_rgba (cr,red,green,blue,alpha)

    cairo_move_to (cr,xpos,ypos)
    cairo_show_text (cr,text)
    cairo_stroke (cr)
end

function indicador_arco(x, y, valor, label, red, green, blue)
    --SETTINGS
    --rings size
    ring_center_x=x
    ring_center_y=y

    ring_radius=50
    ring_width=10

    --colors
    --set background colors
    ring_in_red, ring_in_green, ring_in_blue=rgb(0,0,0)
    ring_in_alpha=1

    --set indicator colors
    ring_bg_red=red
    ring_bg_green=green
    ring_bg_blue=blue
    ring_bg_alpha=1

    --indicator value settings
    value=valor
    max_value=100

    --draw background
    cairo_set_line_width (cr,ring_width)
    cairo_set_source_rgba (cr,ring_bg_red,ring_bg_green,ring_bg_blue,ring_bg_alpha)
    cairo_arc (cr,ring_center_x,ring_center_y,ring_radius,0,2*math.pi)
    cairo_stroke (cr)

    cairo_set_line_width (cr,ring_width+2)
    start_angle = angulo(0)
    end_angle=angulo( value*(360/max_value) )

    --print (end_angle)
    cairo_set_source_rgba (cr,ring_in_red,ring_in_green,ring_in_blue,ring_in_alpha)
    cairo_arc (cr,ring_center_x,ring_center_y,ring_radius,start_angle,end_angle)
    cairo_stroke (cr)

    -- Label
    -- Centraliza o texto no arco
    local extents = cairo_text_extents_t:create()
    tolua.takeownership(extents)
    cairo_text_extents(cr, label, extents)
    x = ring_center_x - (extents.width / 2 + extents.x_bearing)
    y = ring_center_y - (extents.height / 2 + extents.y_bearing) - 9

    texto(label, x, y, red, green, blue )

    txt = valor .. "%"
    cairo_text_extents(cr, txt, extents)
    x = ring_center_x - (extents.width / 2 + extents.x_bearing)
    y = ring_center_y - (extents.height / 2 + extents.y_bearing) + 9

    texto(txt, x, y, red, green, blue )
end

function desenhaTabela(xx, yy, pos)
  -- Ajusta a cor da linha
  if pos == -1 then         -- Linha do cabeçalho
    cor = corTitulo
  elseif pos % 2 == 0 then  -- Linhas pares
    cor = corPar
  else                      -- Linhas ímpares
    cor = corImpar
  end

  -- Configura a tabela
  line_width = space
  cairo_set_line_width (cr,line_width)
  cairo_set_line_cap  (cr, line_cap)
  vermelho,verde,azul=hex2rgb(cor)
  cairo_set_source_rgba (cr,vermelho,verde,azul,transparencia)

  -- Desenha a tabela
  endy = yy-5
  endx = xx-5
  cairo_move_to (cr,endx,endy)
  endx = xx + larguraTabela
  cairo_line_to (cr,endx,endy)

  cairo_stroke (cr)
end

function openPorts(x, y)
  txt = "Open Ports:"
  texto(txt, x, y, hex2rgb(corLabel) )

  xx = x + 100
  numPorts = tostring(conky_parse("${tcp_portmon 1 65535 count}"))
  texto(numPorts, xx, y, hex2rgb(corValor) )

  y = y+space+space

  --Títulos da tabela
  txt = "Port"
  texto(txt, x, y, hex2rgb(tableFontColor) )
  txt = "IP"
  ipX = x+70
  texto(txt, ipX, y, hex2rgb(tableFontColor) )
  txt = "Host"
  hostX = ipX+140
  texto(txt, hostX, y, hex2rgb(tableFontColor) )
  txt = "rhost"

  -- Desenha bordas do titulo
  desenhaTabela(x, y, -1)

  for i=0,numPorts-1 do
      rport = tostring(conky_parse("${tcp_portmon 1 65535 rport " .. i .. "}"))
      rip = tostring(conky_parse("${tcp_portmon 1 65535 rip " .. i .. "}"))
      rhost = conky_parse("${tcp_portmon 1 65535 rhost " .. i .. "}")

      y = y+space
      texto(rport, x, y, hex2rgb(tableFontColor) )
      texto(rip, ipX, y, hex2rgb(tableFontColor) )
      texto(rhost, hostX, y, hex2rgb(tableFontColor) )
      desenhaTabela(x, y, i)
  end

  return y
end

function rede(x, y, adaptador)
  texto(adaptador, x, y, hex2rgb(corLabel) )
  essid = tostring(conky_parse("${wireless_essid " .. adaptador .. "}"))

  if essid ~= nil and essid ~= "" then
    essid = "(" .. essid .. ")"
  end

  xx = x + 60
  yy = y
  texto(essid, xx, yy, hex2rgb(corValor) )

  addrs = tostring(conky_parse("${addr " .. adaptador .. "}"))
  xx = x
  yy = yy + space
  texto(addrs, xx, yy, hex2rgb(corValor) )

  xx = x
  yy = yy + space
  texto("Upload:", xx, yy, hex2rgb(corLabel) )

  upspeed = tostring(conky_parse("${upspeed " .. adaptador .. "}"))
  xx = x + 60
  texto(upspeed, xx, yy, hex2rgb(corValor) )

  xx = x
  yy = yy + space
  texto("Download:", xx, yy, hex2rgb(corLabel) )

  downspeed = tostring(conky_parse("${downspeed " .. adaptador .. "}"))
  xx = x + 80
  texto(downspeed, xx, yy, hex2rgb(corValor) )

  return yy
end

function pip (x, y)
  xx = x
  yy = y
  texto("Public IP:", xx, yy, hex2rgb(corLabel) )

  ip = tostring(conky_parse("${execi 3600 curl ipinfo.io/ip}"))
  xx = x + 75
  texto(ip, xx, yy, hex2rgb(corValor) )

  return yy
end

function titulo(label, x, y, sentido, gap, r, g, b)
  -- Inicializa o Cairo com as configurações de fontes
  f = "Roboto Mono Medium"
  fs = 32

  cairo_select_font_face (cr, f, font_slant, font_face);
  cairo_set_font_size (cr, fs)

  alpha=1
  cairo_set_source_rgba (cr,r,g,b,alpha)

  -- Configura a linha
  line_width = 5
  cairo_set_line_width (cr,line_width)
  cairo_set_line_cap  (cr, line_cap)
  cairo_set_source_rgba (cr,r,g,b,alpha)

  xpos = x + 50
  ypos = y
  cairo_move_to (cr, xpos, ypos)
  cairo_show_text (cr, label)

  -- Desenha a linha horizontal
  endy = y-8
  endx = x
  cairo_move_to (cr,endx,endy)
  endx = endx + 40
  cairo_line_to (cr,endx,endy)
  endx = endx + gap
  cairo_move_to (cr,endx,endy)
  endx = larguraTabela + x - gap + 40
  cairo_line_to (cr,endx,endy)

  --desenha a curva
  if sentido == "down" then
    ring_radius=50
    ring_center_x=endx
    ring_center_y=endy+ring_radius
    start_angle = angulo(0)
    end_angle = angulo(90)
  else
    ring_radius=50
    ring_center_x=endx
    ring_center_y=endy-ring_radius
    endx = endx + ring_radius
    endy = endy - ring_radius
    cairo_move_to (cr,endx,endy)
    start_angle = angulo(90)
    end_angle = angulo(180)
  end

  cairo_arc (cr, ring_center_x, ring_center_y, ring_radius, start_angle, end_angle)

  -- desenha a linha vertical
  if sentido == "down" then
    endx = endx + ring_radius
    endy = endy + ring_radius
    cairo_move_to (cr,endx,endy)
    endy = endy + 7*space
  else
    cairo_move_to (cr,endx,endy)
    endy = 0
  end

  cairo_line_to (cr,endx,endy)
  cairo_stroke (cr)
end

function conky_main()
    if conky_window == nil then
        return
    end

    -- Inicializa cairo
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    cr = cairo_create(cs)

    -- Posição Rede
--    start_x = 1150
--  	start_y = 400
    start_x = 700
  	start_y = 250

    titulo("Rede", start_x, start_y, "down", 110, hex2rgb("#00a4d1"))

    -- Wlan
    x = start_x
    y = start_y + 40
    rede(x, y, wlanAdapter)

    -- Eth
    x = start_x + 300
    y = start_y + 40
    y = rede(x, y, ethAdapter)

    -- Public IP:
    x = start_x
    y = y + space + space
    y = pip(x, y)

    -- Lista de portas abertas
    x = start_x
    y = y + space
    openPorts(x, y)

    -- Indicador CPU
    gap = 120
    x = start_x + 50
    y=80
    valor = conky_parse("${cpu cpu0}")
    indicador_arco(x, y, valor, "CPU", rgb(255, 117, 49))

    -- Indicador RAM
    x = x + gap
    valor = conky_parse("${memperc}")
    indicador_arco(x, y, valor, "RAM", rgb(255, 255, 112))

    -- Indicador SWAP
    x = x + gap
    valor = conky_parse("${swapperc}")
    indicador_arco(x, y, valor, "SWAP", rgb(220, 127, 220))

    -- Indicador Disco (Home)
    x = x + gap
    valor  = 100-tonumber(conky_parse("${fs_free_perc /home}"))
    indicador_arco(x, y, valor, "Home", rgb(0, 164, 209))

    -- Indicador Disco (Root)
    x = x + gap
    valor  = 100-tonumber(conky_parse("${fs_free_perc /}"))
--    indicador_arco(x, y, valor, "Root", rgb(141, 255, 141))
    indicador_arco(x, y, valor, "Root", hex2rgb("#44d31f"))

    x = start_x
    y = y + 85
    titulo("Indicadores", x, y, "up", 245, hex2rgb("#00a4d1"))



    -- Finaliza cairo
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr=nil
end
