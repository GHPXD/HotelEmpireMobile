# Leitores na Sala Horizonte

Três faixas de quatro poses geradas diretamente pelo `image_gen` do chat. Cada
perfil lê um livro sentado em poltrona roxa, combinando com a Sala Horizonte.
Sequência: leitura, alcançar página, virar e retornar. Figurinos, chapéu, cabelo
e bolsas preservam a identidade dos sprites já integrados. O primeiro resultado
casual tinha o último sapato cortado; uma edição corrigiu escala e espaçamento
antes da integração. As imagens selecionadas foram copiadas sem editar pixels.

Arquivos em `assets/art/characters`: `balanced-reading.png` (1774 × 887),
`business-reading.png` (2128 × 739), `leisure-reading.png` (2172 × 724), todos RGBA
com alfa entre 0 e 255. Prompts em `lounge-reading-prompts.json`, medições de
região/âncora em `lounge-reading-measurements.json` e hashes em `manifest.json`.

Regiões medidas no alfa com margem de quatro pixels, altura compartilhada por
faixa e âncoras no apoio inferior. Normalização por geometria no Godot; mipmaps e
correção de borda alfa na importação. Altura visual sentada: 36 pixels em zoom 1,
comparada aos 46 dos hóspedes em pé. A animação avança a cada 12 ticks de 0,1s,
ciclo de 4,8s em 1x. ID desloca fase, pausa congela os gestos, sem consumir RNG.
Somente hóspedes em `using` no lounge selecionam essas faixas.

O renderer distribui usuários admitidos de café e lounge pela largura da sala,
usando o índice em `room.users` e a capacidade. Cada assento tem o mesmo ponto
para desenho e clique. Ao sair um usuário, os índices dos restantes podem mudar.
Isso é apresentação: `actor.x`, trajetória, filas, timers, dinheiro e save não
são alterados. Sem usuário registrado ou sala compatível, mantém a posição atual.

Validação: `ui_art` aprovado, incluindo seleção dos três leitores pelo clique,
alpha, recortes, loop, escala e baseline; snapshots antes/depois da apresentação
iguais. Capturas nas escalas 0,35/0,90/1,80 e quatro fases da leitura inspecionadas.
`ui_culling` inclui usuários admitidos nos dois serviços e manteve equivalência
pixel a pixel nas nove câmeras. `ui_content` aprovado. `gda script validate` com
caminhos `res://` validou os scripts sem diagnósticos; caminhos relativos Windows
haviam causado conflito artificial de classes globais no validador.

Catálogo neste incremento: 37 PNGs, 19 texturas de personagens. Refeições foram
adicionadas depois, conforme `restaurant-dining.md`; repouso em `bedroom-sleeping.md`.
O teste interno do executável nesta revisão verificou os seis
sprites de serviço, com alpha, quatro quadros e recortes dentro das texturas.

Pacote Windows: revisão `e7bfa21`, árvore limpa na exportação. Smoke de 6120 ticks
e matriz de seis janelas/textos passaram; cada caso verificou os seis sprites de
serviço. Auditoria de inventário e hashes dos 37 PNGs aprovada. Evidência em
`docs/release/lounge-reading-matrix.json`; kit externo inclui o mesmo ZIP.
