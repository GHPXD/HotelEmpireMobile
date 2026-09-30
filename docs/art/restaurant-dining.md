# Refeições no Bistrô Aurora

Três faixas de quatro poses geradas diretamente pelo `image_gen` do chat, usando
os personagens de leitura como referências de identidade e o bistrô como referência
de móveis. Cada hóspede come sentado em cadeira de couro laranja, com mesa de
pedestal, prato e garfo. Sequência: pegar a comida, levantar o garfo, comer e baixar.
Corpo, roupa, cabelo, chapéu, bolsas, cadeira e mesa permanecem consistentes.

Arquivos em `assets/art/characters`: `balanced-dining.png` (2155 × 730),
`business-dining.png` (2161 × 728) e `leisure-dining.png` (2172 × 724). Todos RGBA
com alfa entre 0 e 255. PNGs copiados sem alterar pixels. Prompts completos em
`restaurant-dining-prompts.json`, regiões e âncoras medidas no alfa em
`restaurant-dining-measurements.json`, dimensões e hashes em `manifest.json`.

Recortes com margem de quatro pixels, altura e escala compartilhadas por faixa,
âncoras medidas no apoio inferior; normalização por geometria no Godot. Importação
com mipmaps e correção de borda alfa. Altura visual: 36px em zoom 1, igual à leitura
sentada e menor que os hóspedes em pé (46px). Cada pose dura seis ticks de 0,1s;
ciclo de 2,4s em 1x. O ID desloca a fase. Segue a velocidade e congela na pausa.

O catálogo mapeia serviço para ação, duração de quadro e altura. Apenas hóspedes
em `using` no restaurante selecionam as faixas de refeição. Filas, caminhada,
café e lounge usam suas próprias texturas. O renderer distribui os usuários do
restaurante pela largura da sala, assim como café e lounge, com o índice em
`room.users` e a capacidade atual. O mesmo ponto serve para desenho e clique.
Índices podem mudar ao sair um usuário; a posição de navegação não é alterada.

`ui_art` validou três salas cheias: N1 com três lugares, N2 com quatro e N3 com
cinco. Os 12 personagens foram selecionados pelo clique. Em zoom 0,35/0,90/1,80,
os limites das silhuetas de todas as poses ficam dentro da sala e separados por
mais de dois pixels na escala base, sem reduzir sprites nos níveis superiores.
Alpha, recortes, altura, baseline, avanço e loop aprovados. Capturas dos quatro
quadros e dos restaurantes N2/N3 inspecionadas. Snapshots de apresentação/pausa
inalterados. `ui_culling` incluiu restaurante N3 cheio nas nove comparações pixel
a pixel, e `ui_content` passou. Cinco scripts validados por `gda` sem diagnósticos.

Catálogo: 40 PNGs e 22 texturas de personagens. O diagnóstico interno do export
verifica nove sprites de serviço, com alpha, quatro quadros e regiões contidas.
Poses de dormir ainda não estão implementadas.

Pacote Windows exportado da revisão `a02edbe`, árvore limpa no build. Smoke de
6120 ticks e seis combinações locais de janela/texto aprovados; cada combinação
verificou os nove sprites de serviço. Auditoria do ZIP e dos 40 PNGs aprovada.
Evidência em `docs/release/restaurant-dining-matrix.json`; kit externo atualizado.
