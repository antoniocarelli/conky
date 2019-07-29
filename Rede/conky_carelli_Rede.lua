require 'cairo'

-- Configurações --
space = 21  -- Espaço para pular para próxima linha (texto e tabela)
margemX = 22

-- Tipo e o tamanho da fonte que será utilizada
font="Technical CE"
font_size=17
font_slant=CAIRO_FONT_SLANT_NORMAL
font_face=CAIRO_FONT_WEIGHT_BOLD
corLabel = "#44d31f"
corValor = "#f09309"

-- Parâmetros da tabela
line_cap = CAIRO_LINE_CAP_BUTT
larguraTabela = 550
transparencia = 0.15
corTitulo = "#FFFFFF" -- Linha do cabeçalho
corPar = "#53c9d6"    -- Linhas pares
corImpar = "#61EAF9"  -- Linhas ímpares
tableFontColor = "#FFFFFF"

-- Customizações dos sensores
wlanAdapter = "wlp3s0"
ethAdapter = "enp2s0"
-------------------

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

  x = 120
  numPorts = tostring(conky_parse("${tcp_portmon 1 65535 count}"))
  texto(numPorts, x, y, hex2rgb(corValor) )

  x = margemX + 3
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

function conky_main()
    if conky_window == nil then
        return
    end

    -- Inicializa cairo
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    cr = cairo_create(cs)

    -- Posição Rede
    gap_x = 25
  	gap_y = 0

    -- Wlan
    x = gap_x
    y = gap_y + 95
    rede(x, y, wlanAdapter)

    -- Eth
    x = gap_x + 300
    y = gap_y + 95
    y = rede(x, y, ethAdapter)

    -- Public IP:
    x = gap_x
    y = y + space + space
    y = pip(x, y)

    -- Lista de portas abertas
    x = gap_x
    y = y + space
    y = openPorts(x, y)



    -- Finaliza cairo
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr=nil
end
