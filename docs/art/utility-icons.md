# Equipe, Objetivos e Ajuda — 30/09/2026

Três PNGs RGBA 1254×1254 produzidos pelo `image_gen` integrado ao chat:
dupla de recepcionista/camareira em azul/rosa, troféu de latão/jade e manual
aberto marfim/jade com interrogação. Fontes locais em `assets/art/icons/team.png`,
`objectives.png` e `help.png`. Arquivos selecionados copiados byte a byte, sem
edição local de pixels; origem, hashes e bounds em `utility-icons-measurements.json`.
Catálogo atual: 79 PNGs, 30 texturas de animação, cinco retratos e 20 ícones.

Equipe teve uma geração inicial e uma edição pelo próprio gerador para reduzir
torso e compactar a dupla. Foi selecionado o segundo resultado. O gerador não
cumpriu toda a margem pedida: as figuras ocupam mais largura que o solicitado,
assim como o manual; silhuetas opacas ficam dentro do canvas e os cantos são
transparentes. A composição foi inspecionada em fonte e no HUD de 28px, sem
corte dos cabelos/ombros/livro. Prompts iniciais e edição em
`utility-icons-prompts.json`. Não substitui os retratos individuais existentes.

As três texturas entram no catálogo compartilhado `HotelArt.MANAGEMENT_ICONS`,
que agora cobre seis painéis. Usa o mesmo helper nativo do HUD: import de 256px,
mipmaps, filtro linear, `icon_max_width=28` e `expand_icon=false`. Equipe mantém
o nome; Objetivos mantém o contador dinâmico; Ajuda mantém F1. Callbacks,
conteúdo dos painéis, salários, desbloqueios e schema v7 permanecem existentes.

`tests/ui_management_icons.gd` ampliado para seis painéis × quatro janelas
solicitadas (1024×640, 1280×800, 1600×900 e 3840×2160) × dois tamanhos de texto
× mouse/Enter: 96 ativações. Verifica painel correto, ausência de outro painel
aberto, snapshot pausado preservado, Esc/foco, imagem/alpha/import, largura
mínima, bounds e ausência de sobreposição. 48 áreas de ícone têm pixels pintados
além do fundo, com recortes escalados pela captura; limiar de brilho depende da
paleta atual. Dados em `utility-icons-ui.json`.

O fluxo agora ocupa uma segunda linha no texto padrão: playfield lógico 634,
comparado a 680 sem os seis ícones de painel, custo de uma linha de 46px.
Texto ampliado conserva 624 nos oito layouts medidos. Não altera a escala do
texto para compensar largura. Capturas inspecionadas em
`hotel-utility-toolbar-small.png` e `hotel-utility-toolbar-4k.png` (canvas ativo
3456×2160 da janela solicitada 4K, sem margens externas). Não certifica monitor
físico, controlador ou suporte integral de acessibilidade.

Quatro scripts válidos pelo gda. Dez suítes gráficas passaram:
ui_management_icons, ui_session_icons, ui_management, ui_progression, ui_help,
ui_smoke, ui_resume, ui_new_game, ui_recovery e ui_exit. Inclui contratação e
atribuição de equipe, contador/desbloqueio de objetivos, rolagem/F1/pausa da
ajuda e continuidade dos controles de partida. A bateria completa de 31 suítes
registrada no M9 é anterior aos ícones de painel/partida; não foi repetida aqui.

Três imports adicionais de 256px; a medição M8 anterior não representa a memória
do catálogo atual completo. Não há nova capacidade de hóspedes ou mudança de
regras; animação e economia usam o mesmo estado existente.

Pacote da revisão limpa `befcc66`: boot e smoke de 6120 ticks passaram, com
39 reservas, 42 refeições, 31 limpezas e caixa 2021. Seis painéis abertos pelos
ícones, snapshot preservado e Esc/foco em cada configuração do ZIP extraído:
`../release/utility-icons-matrix.json`. Os três comandos de partida e os ícones
de construção/contratação/ação também passaram. ZIP, documentos e hashes dos
79 PNGs auditados; kit de compatibilidade atualizado. Compatibilidade externa
e playtest humano continuam pendentes.
