# Ícones dos comandos de construção — 30/09/2026

Três PNGs RGBA de 1254×1254 gerados pelo `image_gen` integrado ao chat e
copiados byte a byte para `assets/art/icons/`: `add-floor.png` (fachada, laje
e seta), `upgrade.png` (estrela e seta) e `demolish.png` (malho e alvenaria).
Prompts integrais em `action-icons-prompts.json`; caminhos de origem, hashes,
bounds de alpha >100/255 e dimensões em `action-icons-measurements.json`.
Nenhuma edição dos pixels. Cantos transparentes, silhuetas opacas sem corte.
O malho ocupa mais de 80% da largura pedida, mas conserva margem e leitura.

O catálogo atual tem 70 PNGs, 30 texturas de animação, cinco retratos e 11
ícones. `HotelArt.ACTION_ICONS` centraliza os três comandos. As fontes são
compartilhadas e importadas a 256px, com mipmaps; `Button.icon` limita o desenho
a 32px com filtro linear. Não muda o estado da simulação nem o esquema v7.
Texto, preço, feedback, foco e ativação permanecem em controles nativos.
Demolição informa ausência de reembolso também no tooltip.

`tests/ui_action_icons.gd` exercita 36 ativações: três comandos, três janelas
(1024×640, 1280×800, 1600×900), texto padrão/ampliado e mouse/Enter. Confere
imagem, orçamento de importação, bounds na rolagem, mínimos, nível/seleção,
custo exato, ausência de reembolso e pausa. Caixa insuficiente e seleção vazia
preservam o snapshot. O teste aguarda o layout antes de rolar; a primeira
execução antecipava a rolagem e foi corrigida. A captura da melhoria também
rola novamente após o texto de desbloqueio aumentar o painel.

Capturas: `hotel-action-floor.png` (expansão e demolição) e
`hotel-action-upgrade.png` (melhoria disponível para N2), em 1024×640/texto ampliado.
São ícones estáticos; o destaque de foco/hover continua no tema do jogo.
