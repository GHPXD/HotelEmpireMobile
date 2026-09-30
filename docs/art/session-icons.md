# Ícones de partida — 30/09/2026

Três PNGs RGBA 1254×1254 gerados diretamente no chat pelo `image_gen` integrado:
hotel marfim/jade com medalhão de soma para Novo hotel, disquete jade/latão para
Salvar e pasta carvalho/jade com seta para Carregar. Fontes copiadas sem edição
de pixels para `assets/art/icons/new-hotel.png`, `save.png` e `load.png`.
Prompts completos em `session-icons-prompts.json`; origens, dimensões, hashes,
cantos transparentes e bounds opacos (>100/255) em `session-icons-measurements.json`.
As silhuetas ficam dentro do canvas; a pasta usa margem menor que os 10% pedidos
à direita, sem corte. Catálogo atual: 76 PNGs, 30 texturas de animação, cinco
retratos e 17 ícones. As fontes do gerador não são dependência de runtime.

`HotelArt.SESSION_ICONS` compartilha os imports de 256px com mipmaps. Botões
nativos de 28px com `expand_icon=false` reservam a imagem na largura mínima do
HFlowContainer, preservando rótulos, callbacks e foco. Novo hotel continua
abrindo a confirmação existente; não há mudança no schema v7 ou nos arquivos
de partida. O teste usa um save próprio em APPDATA isolado.

`tests/ui_session_icons.gd`: três comandos × quatro janelas solicitadas
(1024×640, 1280×800, 1600×900 e 3840×2160) × dois tamanhos de texto × mouse/Enter:
48 ativações, oito cancelamentos e oito confirmações. Confere escrita e leitura
do snapshot inteiro de um hotel operando, preservação dos bytes salvos, reset
de quartos/atores/fundos/objetivos/seleção, preferência de texto e retorno de foco.
Antes de carregar, substitui a sessão por uma vazia para provar restauração.

Confere alpha, orçamento de import, largura mínima, bounds e ausência de
sobreposição; 24 áreas de ícone contêm pixels pintados além do fundo. Recortes
usam a escala real da captura; o limiar de brilho depende da paleta atual.
O playfield manteve a altura lógica de 680 no texto padrão e 624 no ampliado,
com e sem as três imagens nos oito layouts. Dados em `session-icons-ui.json`.
Capturas inspecionadas: `hotel-session-toolbar-small.png` e
`hotel-session-toolbar-4k.png` (canvas ativo 3456×2160, sem margens externas).
Janela solicitada 4K não certifica monitor ou hardware físico 4K.

Ícones estáticos, com hover/foco do tema nativo. Três novos imports de 256px;
a medição M8 anterior não representa a memória do catálogo atual completo.

Pacote da revisão limpa `33eca92`: boot e smoke de 6120 ticks passaram, com
os três comandos e imports dentro do executável. Seis configurações extraídas
do ZIP passaram em `../release/session-icons-matrix.json`: gravação, carga após
sessão vazia, cancelamento e confirmação de Novo hotel, seguida de recuperação
pela carga, com snapshot e bytes salvos preservados. ZIP, documentos e hashes
dos 76 PNGs auditados; kit de compatibilidade atualizado. Outros computadores
e playtest humano permanecem pendentes.

As alturas e dados acima correspondem à revisão 33eca92. Na revisão befcc66,
novos ícones de Equipe/Objetivos/Ajuda fazem a barra padrão ocupar uma linha
adicional (playfield 634), enquanto ampliada mantém 624; os 48 comandos de
partida foram repetidos com sucesso. Detalhes atuais em `utility-icons.md`.
