# Indicadores de espera e seleção dos personagens

O indicador “…” usava deslocamento fixo que cobria parte do cabelo nas faixas
de espera. Agora sua borda inferior fica quatro pixels de mundo acima do recorte
desenhado, acompanhando altura, gesto e zoom. Tamanho e tipografia continuam
nativos; os 45 PNGs originais permanecem preservados.

`HotelView.actor_sprite_rect` calcula o mesmo retângulo usado no desenho, com
região, escala e âncora do catálogo de arte. O indicador é centralizado no ponto
do personagem e usa a medida real do texto. O descarte conservador da câmera
continua anterior aos cálculos de desenho.

Cliques aceitam o retângulo do sprite com margem de dois pixels de mundo, permitindo
seleção pela cabeça ou pelo corpo. Entre candidatos sobrepostos, vence o ponto
visual mais próximo do clique. Em empate, vence o último personagem desenhado;
os personagens em circulação têm prioridade sobre dorminhocos empatados.
Posições completamente iguais continuam representadas pelo personagem em primeiro
plano; não se inventa espaçamento ou ordem de atendimento na simulação.

Nenhuma mudança em filas, destinos, economia, RNG, tempos ou saves. Construção
mantém prioridade quando há um blueprint ativo; clique fora dos personagens
continua selecionando a sala. O espelhamento da caminhada preserva os limites
do recorte e a lógica existente.

Validação em Godot 4.7.2: `ui_actor_presentation` passou nos 11 contextos (três
perfis × três esperas, mais duas funções na fila do elevador), quatro fases e
três zooms. Cliques reais pela parte superior do sprite, fora do antigo raio de
14px, selecionaram cada personagem. Dois hóspedes separados por cinco pixels
de mundo continuam selecionáveis; empate segue a ordem de desenho. Snapshots
inalterados durante desenho, pausa e clique. Capturas em
`.runtime/m7-queue-presentation-0.png` a `-3.png`, inspecionadas.

`ui_culling` passou em 11 câmeras, incluindo dois casos com somente o indicador
visível na borda inferior, comparando pixels com e sem descarte. `ui_art`,
`ui_content` e `ui_checkin_diagnostics` passaram. Quatro scripts válidos pelo gda.
`ui_smoke`, `ui_resume` e `ui_management` também passaram, cobrindo construção,
retomada e gestão depois da ampliação da área de clique dos personagens.
O diagnóstico do executável confere separação e seleção em três zooms, além dos
12 sprites de uso dos hóspedes e quatro contextos de repouso da equipe.
