# Ícones da barra de gestão — 30/09/2026

Três PNGs RGBA 1254×1254 gerados pelo `image_gen` integrado ao chat, copiados
sem alterar pixels para `assets/art/icons/finances.png`, `operations.png` e
`reviews.png`. Livro-caixa com moedas, planta com lupa e livro de avaliações
com balão/coração; mesma paleta jade, marfim, latão, carvalho e rosa.
Prompts integrais em `management-icons-prompts.json`; origem, dimensões,
hashes e bounds opacos (>100/255) em `management-icons-measurements.json`.
Cantos transparentes e silhuetas sem corte; a lupa ocupa mais dos 80% pedidos,
conservando margem. Catálogo atual: 73 PNGs, 30 texturas de animação, cinco
retratos e 14 ícones. Nenhuma edição ou dependência do diretório do gerador.

`HotelArt.MANAGEMENT_ICONS` compartilha as três texturas importadas a 256px,
com mipmaps. Os botões nativos mantêm texto, atalho e ativação; limite de 28px
por `icon_max_width`, filtro linear e `expand_icon=false`. Isso deixa a imagem
participar do tamanho mínimo no HFlowContainer. A primeira versão com expansão
passava os testes de propriedade, mas os ícones não apareciam nas capturas,
porque o fluxo dava somente a largura do texto. A inspeção detectou o problema;
tamanho mínimo e verificação de pixels foram corrigidos e repetidos.
Referência de API: [Button, Godot](https://docs.godotengine.org/en/latest/classes/class_button.html#class-button-theme-constant-icon-max-width).

`tests/ui_management_icons.gd`: três painéis × quatro janelas solicitadas
(1024×640, 1280×800, 1600×900, 3840×2160) × dois textos × mouse/Enter:
48 ativações. Confere painel correto, Esc/foco, snapshot pausado preservado,
fontes/alpha, largura reservada, limites e ausência de sobreposição dos botões.
24 áreas de ícone contêm pixels pintados além do fundo; a escala da captura
é aplicada ao recorte. Essa checagem usa a paleta atual; revisar se o tema mudar.

Compara altura do playfield com e sem as imagens: nos oito layouts medidos,
as alturas lógicas foram iguais (680 no texto padrão, 624 no ampliado),
registradas em `management-icons-ui.json`. Os botões ficam mais largos, mas
não acrescentaram linha vertical nesses casos; não garante qualquer escala futura.
Capturas inspecionadas: `hotel-management-toolbar-small.png` (1024×640) e
`hotel-management-toolbar-4k.png` (canvas 3456×2160 da janela solicitada 4K,
sem as margens externas). Não é certificação de monitor/hardware físico 4K.

Só apresentação e navegação: sem novo estado, preços ou mudança no save v7.
Ícones estáticos; hover/foco usam o tema nativo. A biblioteca soma três imports
de 256px; a medição M8 anterior não representa o total novo de memória do jogo.
