## Plan: Criar Script Conky com Indicadores em Lua

** Criar um script Conky completo usando Lua para gráficos, com as cores e estilos da image graficos-verticais/modelo.png, com indicadores de CPU, RAM/SWAP, GPU, GRAM, disco e Wi-Fi.

**Steps**
1. **Discovery** - Pesquisar como é o arquivo base do conky
   - Ler o documento oficial em https://conky.cc/config_settings
   - Extrair as configurações para montar um painel:
     - vertical
     - que fique no canto superior esquerdo como janela, ou como se fosse o papel de parede da area de trabalho
     - Transparente em 30%
   - Ler o documento oficial de como integrar o conky com o LUA API: https://conky.cc/lua
   - Ler as variáveis disponíveis para acessar as informações a serem exibidas no painel: https://conky.cc/variables

2. **Design** - Implementar o script Conky completo, com atualização a cada 1 segundo

**Relevant files**
- `/home/antonio/codes/conky/graficos-verticais/modelo.png` — Imagem com as cores e tipos de gráficos para referência
- `/home/antonio/codes/conky/graficos-verticais` — Pasta onde os arquivos devem ser criados
- `/home/antonio/codes/conky/novo/conky_carelli.conf` — Arquivo conky de outro projeto, que usa LUA
- `/home/antonio/codes/conky/novo/conky_carelli.lua` — Arquivo com o código LUA, usado pelo conky para renderizar as imagens

**Verification**
1. Testar script no Conky
2. Verificar todos os gráficos funcionando
3. Validar cores e estilos

**Decisions**
- Usar Lua para gráficos (como solicitado)
- Criar gráfico único para RAM/SWAP
- Criar gráfico único para tráfego de rede up e download

**Further Considerations**
1. Verificar se há dependências de bibliotecas Lua específicas
