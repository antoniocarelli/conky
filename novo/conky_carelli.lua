-- Indicadores
exibeIndicadores = true
tituloIndicadores = "Indicadores"
gapTituloIndicadores = 185
gapIndicadores = 120
indicadoresX = redeX
indicadoresY = 60
raioIndicador = 50
espessuraIndicador = 8


-- Rede
exibeRede = true
exibeListaPortasRede = false
tituloRede = "Rede"
gapRede = 90
redeX = 50 --1200 --650
redeY = 245

-- Processos
exibeProcessos = true
tituloProcessos = "Processos"
gapProcessos = 170
processosX = redeX
processosY = 480

-- Informações
exibeInfo = true
tituloInfo = "Info"
gapInfo = 75
infoX = redeX
infoY = 790

-- Cores
Branco = "FFFFFF"

Laranja3 = "D75825"
Amarelo3 = "D78B25"
Azul3 = "1F5C8A"
Verde3 = "19935F"

Laranja1 = "FFA37E"
Amarelo1 = "FFC87E"
Azul1 = "5B89AD"
Verde1 = "5AB68F"

Laranja2 = "E77A4F"
Amarelo2 = "E7A64F"
Azul2 = "396D95"
Verde2 = "369F72"

Laranja4 = "AB3D12"
Amarelo4 = "AB6A12"
Azul4 = "12466E"
Verde4 = "0C7548"

Laranja5 = "842600"
Amarelo5 = "844C00"
Azul5 = "053255"
Verde5 = "005B34"

cor1 = "44d31f"
cor2 = "df3b11"
cor3 = "f35aca"
cor4 = "f09309"
cor5 = "53c9d6"
cor6 = "EBD891"
cor7 = "8E8831"
cor8 = "62A5A5"
cor9 = "8A522D"
cor10 = "1B314B"
cor11 = "00a4d1"
corBorda = Laranja3
corLabel = Amarelo3
corValor = Branco
tableFontColor = Branco
corTitulo = Verde5  --Branco -- Linha do cabecalho
corPar = Verde3     --"53c9d6"    -- Linhas pares
corImpar = Verde4   --"61EAF9"  -- Linhas impares
corBordaRede = corBorda
corBordaIndicadores = corBorda
corBordaProcessos = corBorda
corBordaInfo = corBorda
corCPU  = Azul2
corRAM  = Azul2
corSWAP = Azul2
corHOME = Azul2
corROOT = Azul2


-- Configuracoes gerais
fontName="Technical"
fontSize=17
largura = 650

-- Customizacoes dos adaptadores de rede
wlanAdapter = "wlp3s0"
ethAdapter = "enp2s0"

-- Configurações das bordas
raioBorda = 20
espessuraBorda = 6 --Usar apenas numeros pares
margensBorda = 10

-- Tabela
alturaLinhaTabela = 21  -- Espaco para pular para proxima linha (texto e tabela)

-- Parametros da tabela Rede
transparenciaRede = 0.2
corTituloRede = corTitulo -- Linha do cabecalho
corParRede = corPar    -- Linhas pares
corImparRede = corImpar  -- Linhas impares
tableFontColorRede = tableFontColor
-------------------


require 'cairo'

-- Converte o angulo de graus para radianos
-- E corrige o angulo inicial do arco (-90)
function angulo( graus )
  local radianos = (graus - 90) * (math.pi/180)
  return radianos
end

function hex2rgb(hex)
    local hex = hex:gsub("#","")
    return (tonumber("0x"..hex:sub(1,2))/255), (tonumber("0x"..hex:sub(3,4))/255), tonumber(("0x"..hex:sub(5,6))/255)
end

function desenhaLinha(corHex, startX, startY, endX, endY, espessura)
  local r, g, b = hex2rgb(corHex)
  local alpha=1
  cairo_set_source_rgba (cr,r,g,b,alpha)

  -- Configura a linha
  cairo_set_line_width (cr, espessura)
  cairo_set_line_cap  (cr, CAIRO_LINE_CAP_BUTT)

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
  cairo_set_line_cap  (cr, CAIRO_LINE_CAP_BUTT)

  local startAngle = angulo(anguloInicial)
  local endAngle = angulo(anguloFinal)
  --cairo_move_to (cr, posX, posY)
  cairo_arc (cr, centroX, centroY, raio, startAngle, endAngle)

  cairo_stroke (cr)
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

function titulo(label, xInicial, yInicial, corHex, altura, largura, gap)
  local ajusteTituloY = 8

  -- Escreve titulo
  local xpos = xInicial + 50
  local ypos = yInicial
  texto(label, xpos, ypos, corHex, 32)

  -- Desenha a linha horizontal superior
  local startX = xInicial
  local startY = yInicial - ajusteTituloY
  local endX = startX + 40
  local endY = startY
  desenhaLinha(corHex, startX, startY, endX, endY, espessuraBorda)

  startX = endX + gap
  endX = xInicial + largura --+ margensBorda
  desenhaLinha(corHex, startX, startY, endX, endY, espessuraBorda)

  --desenha a curva canto superior direito
  local centroX = endX
  local centroY = endY + raioBorda
  local aInicial = 0
  local aFinal = 90
  desenhaArco(corHex, raioBorda, centroX, centroY, startX, startY, espessuraBorda, aInicial, aFinal)

  -- desenha a linha vertical direita
  startX = endX + raioBorda
  startY = endY + raioBorda
  endY = endY + altura + ajusteTituloY + margensBorda
  desenhaLinha(corHex, startX, startY, startX, endY, espessuraBorda)

  --desenha a curva canto inferior direito
  local centroX = endX
  local centroY = endY
  local aInicial = 90
  local aFinal = 180
  desenhaArco(corHex, raioBorda, centroX, centroY, startX, startY, espessuraBorda, aInicial, aFinal)

  -- desenha a linha horizontal inferior
  startX = endX
  startY = endY + raioBorda
  endX = xInicial
  desenhaLinha(corHex, startX, startY, endX, startY, espessuraBorda)

  --desenha a curva canto inferior esquerdo
  local centroX = endX
  local centroY = endY
  local aInicial = 180
  local aFinal = 270
  desenhaArco(corHex, raioBorda, centroX, centroY, startX, startY, espessuraBorda, aInicial, aFinal)

  -- desenha a linha vertical esquerda
  startX = endX - raioBorda
  startY = endY
  endY = yInicial + raioBorda - ajusteTituloY
  desenhaLinha(corHex, startX, startY, startX, endY, espessuraBorda)

  --desenha a curva canto superior esquerdo
  local centroX = endX
  local centroY = endY
  local aInicial = 270
  local aFinal = 360
  desenhaArco(corHex, raioBorda, centroX, centroY, startX, startY, espessuraBorda, aInicial, aFinal)
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

     -- Label
     -- Centraliza o texto no arco
     local extents = cairo_text_extents_t:create()
     tolua.takeownership(extents)
     cairo_text_extents(cr, label, extents)
     x = centroX - (extents.width / 2 + extents.x_bearing)
     y = centroY - (extents.height / 2 + extents.y_bearing) - 9
     texto(label, x, y, cor)

     local txt = valor .. "%"
     cairo_text_extents(cr, txt, extents)
     x = centroX - (extents.width / 2 + extents.x_bearing)
     y = centroY - (extents.height / 2 + extents.y_bearing) + 9
     texto(txt, x, y, cor)
end

function desenhaTabela(xx, yy, pos, largura)
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
  cairo_set_line_width (cr, alturaLinhaTabela)
  cairo_set_line_cap  (cr, CAIRO_LINE_CAP_BUTT)
  local vermelho,verde,azul=hex2rgb(cor)
  cairo_set_source_rgba (cr,vermelho,verde,azul,transparenciaRede)

  -- Desenha a tabela
  local endy = yy-5
  local endx = xx-5
  cairo_move_to (cr,endx,endy)
  endx = xx + largura
  cairo_line_to (cr,endx,endy)

  cairo_stroke (cr)
end

function openPorts(x, y)
  local txt = "Connections:"
  texto(txt, x, y, corLabel, fontSize)

  local xx = x + 100
  local numPorts = tonumber(conky_parse("${tcp_portmon 1 65535 count}"))
  texto(numPorts, xx, y, corValor, fontSize)

  local yy = y

  if exibeListaPortasRede then
      yy = yy + alturaLinhaTabela + alturaLinhaTabela

      --Titulos da tabela
      txt = "Port"
      texto(txt, x, yy, tableFontColorRede, fontSize)
      txt = "IP"
      local ipX = x+70
      texto(txt, ipX, yy, tableFontColorRede, fontSize)
      txt = "Host"
      local hostX = ipX+140
      texto(txt, hostX, yy, tableFontColorRede, fontSize)
      txt = "rhost"

      -- Desenha bordas do titulo
      desenhaTabela(x, yy, -1, largura)

      for i=0,numPorts-1 do
          local rport = tonumber(conky_parse("${tcp_portmon 1 65535 rport " .. i .. "}"))
          local rip = tostring(conky_parse("${tcp_portmon 1 65535 rip " .. i .. "}"))
          local rhost = conky_parse("${tcp_portmon 1 65535 rhost " .. i .. "}")

          yy = yy+alturaLinhaTabela
          texto(rport, x, yy, tableFontColorRede, fontSize)
          texto(rip, ipX, yy, tableFontColorRede, fontSize)
          texto(rhost, hostX, yy, tableFontColorRede, fontSize)
          desenhaTabela(x, yy, i, largura)
      end
  end
  return yy
end

function redeInfo(x, y, adaptador)
  texto(adaptador, x, y, corLabel, fontSize)
  local essid = tostring(conky_parse("${wireless_essid " .. adaptador .. "}"))

  if essid ~= nil and essid ~= "" then
    essid = "(" .. essid .. ")"
  end

  local xx = x + 60
  local yy = y
  texto(essid, xx, yy, corValor, fontSize)

  local addrs = tostring(conky_parse("${addr " .. adaptador .. "}"))
  xx = x
  yy = yy + alturaLinhaTabela
  texto(addrs, xx, yy, corValor, fontSize)

  xx = x
  yy = yy + alturaLinhaTabela
  texto("Upload:", xx, yy, corLabel, fontSize)

  local upspeed = tostring(conky_parse("${upspeed " .. adaptador .. "}"))
  xx = x + 60
  texto(upspeed, xx, yy, corValor, fontSize)

  xx = x
  yy = yy + alturaLinhaTabela
  texto("Download:", xx, yy, corLabel, fontSize)

  local downspeed = tostring(conky_parse("${downspeed " .. adaptador .. "}"))
  xx = x + 80
  texto(downspeed, xx, yy, corValor, fontSize)

  return yy
end

function pip (x, y)
  local xx = x
  local yy = y
  texto("Public IP:", xx, yy, corLabel, fontSize)

  local ip = tostring(conky_parse("${execi 3600 curl ipinfo.io/ip}"))
  xx = x + 75
  texto(ip, xx, yy, corValor, fontSize)

  return yy
end

function rede(startX, startY)
  -- Wlan
  local x = startX + margensBorda
  local y = startY + 40
  redeInfo(x, y, wlanAdapter)

  -- Eth
  x = startX + (0.5*largura)
  y = startY + 40
  y = redeInfo(x, y, ethAdapter)

  -- Public IP:
  x = startX + margensBorda
  y = y + alturaLinhaTabela + alturaLinhaTabela
  y = pip(x, y)

  -- Lista de portas abertas
  x = startX + margensBorda
  y = y + alturaLinhaTabela
  local altura = openPorts(x, y)

  altura = altura - startY
  titulo(tituloRede, startX, startY, corBordaRede, altura, largura, gapRede)
end

function indicadores(startX, startY)
    gapIndicadores = largura / 5

    --Titulo
    local altura = gapIndicadores - alturaLinhaTabela
    --local largura = 5*gapIndicadores
    titulo(tituloIndicadores, startX, startY, corBordaIndicadores, altura, largura, gapTituloIndicadores)

    -- Centraliza a posição dos indicadores.
    startX = startX + 15
    startY = startY + 15

    -- Indicador CPU
    local valor = tonumber( conky_parse("${cpu cpu0}") )
    indicadorArco(startX, startY, valor, "", corCPU)  -- Fix stupid position bug
    indicadorArco(startX, startY, valor, "CPU", corCPU)

    -- Indicador RAM
    startX = startX + gapIndicadores
    valor = tonumber( conky_parse("${memperc}") )
    indicadorArco(startX, startY, valor, "RAM", corRAM)

    -- Indicador SWAP
    startX = startX + gapIndicadores
    valor = tonumber( conky_parse("${swapperc}") )
    indicadorArco(startX, startY, valor, "SWAP", corSWAP)

    -- Indicador Disco (Home)
    startX = startX + gapIndicadores
    valor  = 100-tonumber( conky_parse("${fs_free_perc /home}") )
    indicadorArco(startX, startY, valor, "Home", corHOME)

    -- Indicador Disco (Root)
    startX = startX + gapIndicadores
    valor  = 100 - tonumber( conky_parse("${fs_free_perc /}") )
    indicadorArco(startX, startY, valor, "Root", corROOT)
end

function processos(processosX, processosY)
    local procX = processosX
    local pidX =  procX + (0.5*largura)
    local cpuX =  pidX +  (0.5*largura/3)
    local memX =  cpuX +  (0.5*largura/3)

    local y = processosY + alturaLinhaTabela + margensBorda

--    --Titulos da tabela
    local txt = "Processos"
    texto(txt, procX, y, tableFontColor, fontSize)
    txt = "PID"
    texto(txt, pidX, y, tableFontColor, fontSize)
    txt = "CPU%"
    texto(txt, cpuX, y, tableFontColor, fontSize)
    txt = "MEM%"
    texto(txt, memX, y, tableFontColor, fontSize)


    -- Desenha bordas do titulo
    desenhaTabela(processosX, y, -1, largura)

    for i=1, 10 do
        local proc = tostring(conky_parse("${top name " .. i .. "}"))
        local pid  = tostring(conky_parse("${top pid " .. i .. "}"))
        local cpu  = conky_parse("${top cpu " .. i .. "}")
        local mem  = conky_parse("${top mem " .. i .. "}")

        y = y + alturaLinhaTabela
        texto(proc, procX, y, tableFontColor, fontSize)
        texto(pid,  pidX,  y, tableFontColor, fontSize)
        texto(cpu,  cpuX,  y, tableFontColor, fontSize)
        texto(mem,  memX,  y, tableFontColor, fontSize)
        desenhaTabela(processosX, y, i, largura)
    end

    --Titulo
    local altura = y - processosY
    titulo(tituloProcessos, processosX, processosY, corBordaProcessos, altura, largura, gapProcessos)
end

function info(startX, startY)
  --Titulo
  local altura = 8*alturaLinhaTabela
  titulo(tituloInfo, startX, startY, corBordaInfo, altura, largura, gapInfo)

  local uptime = tostring(conky_parse("${uptime}"))
  local osVer = tostring(conky_parse("${exec cat /etc/issue.net}"))
  local processador = tostring(conky_parse("${execi 1000 cat /proc/cpuinfo|grep 'model name'|sed -e 's/model name.*: //'| uniq | cut -c 1-32}"))
  local kernel = tostring(conky_parse("$kernel"))
  local host = tostring(conky_parse("${nodename}"))
  local updates = tonumber(conky_parse("${execi 360 aptitude search \"~U\" | wc -l | tail}"))
--  local updatelist = tostring(conky_parse("${exec apt list --upgradable}"))

  local x = startX + margensBorda
  local y = startY + alturaLinhaTabela + alturaLinhaTabela
  texto("Uptime:", x, y, corLabel, fontSize)
  x = x + 60
  texto(uptime, x, y, corValor, fontSize)

  x = startX + margensBorda
  y = y + alturaLinhaTabela
  texto("SO:", x, y, corLabel, fontSize)
  x = x + 30
  texto(osVer, x, y, corValor, fontSize)

  x = startX + margensBorda
  y = y + alturaLinhaTabela
  texto("Processador:", x, y, corLabel, fontSize)
  x = x + 105
  texto(processador, x, y, corValor, fontSize)

  x = startX + margensBorda
  y = y + alturaLinhaTabela
  texto("Kernel:", x, y, corLabel, fontSize)
  x = x + 55
  texto(kernel, x, y, corValor, fontSize)

  x = startX + margensBorda
  y = y + alturaLinhaTabela
  texto("Host:", x, y, corLabel, fontSize)
  x = x + 45
  texto(host, x, y, corValor, fontSize)

  x = startX + margensBorda
  y = y + alturaLinhaTabela
  texto("Updates:", x, y, corLabel, fontSize)
  x = x + 72
  texto(updates, x, y, corValor, fontSize)

  if updates>0 then
--    y = y + alturaLinhaTabela
--    x = x + 72
--    texto(updatelist, x, y, corValor, fontSize)

    x = startX + largura - 15
    y = y + 3*alturaLinhaTabela
    local tam = 60
    texto("*", x, y, cor3, tam)
  end
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

    -- Processos
    if exibeProcessos then processos(processosX, processosY) end

    -- Informações
    if exibeInfo then info(infoX, infoY) end

    -- Finaliza cairo
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr=nil
end
