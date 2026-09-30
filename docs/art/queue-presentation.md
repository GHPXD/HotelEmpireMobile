# Indicadores de espera e seleção dos personagens

## Posições por reserva

`HotelQueueProjection` projeta filas registradas em coordenadas de mundo, sem
alterar a posição física do ator ou a ordem de atendimento. Filas de salas seguem
`room.queue.members`; lugares reservados para quem está caminhando permanecem
na sequência. Elevadores mantêm a ordem relativa por andar dentro da fila global.
As posições avançam da porta para o interior do hotel, inclusive nos dois extremos.

Espaçamento máximo de 24px, comprimido quando o grupo excede a largura disponível.
Portanto, filas grandes ainda podem sobrepor silhuetas, mas seus pontos são distintos.
Um único contador por grupo fica acima dos personagens; o total das salas inclui
reservas em trânsito. Entrada interpola durante os primeiros 0,4s de espera, usando
o tempo autoritativo existente. Pausa congela essa transição. Nenhum relógio visual,
RNG, mudança de fila ou campo adicional de save.

A tabela é calculada uma vez por desenho ou clique. A consulta pública de uma
posição percorre somente a fila correspondente. Desenho e seleção usam as mesmas
coordenadas; personagens sem reserva mantêm a apresentação individual descrita
abaixo. O perfil antigo de caminhada não mede o custo desta projeção.

`ui_actor_presentation` inclui duas filas de 12 reservas, IDs em ordem inversa,
uma reserva ainda caminhando, dez passageiros distribuídos em dois andares e
duas funções da equipe. Verifica ordem, contadores, entrada, elevadores dos dois
extremos, seleção real de 33 pessoas nos três zooms, separação do contador,
equivalência de pixels com/sem descarte, snapshots e restauração das posições.

Captura inspecionada: `hotel-fifo-queues.png`. Incluída no pacote Windows da
revisão 090b8af, árvore limpa, seis combinações locais de janela/texto aprovadas.
O diagnóstico verifica seleção de 18 pessoas registradas em três zooms e leitura
sem mutação. Matriz `../release/housekeeping-fifo-matrix.json`. Sem novo perfil
de performance de filas; resultados antigos continuam restritos à caminhada.

## Indicador individual e seleção

O indicador “…” usava deslocamento fixo que cobria parte do cabelo nas faixas
de espera. Agora sua borda inferior fica quatro pixels de mundo acima do recorte
desenhado, acompanhando altura, gesto e zoom. Tamanho e tipografia continuam
nativos; os PNGs originais permanecem preservados.

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

Pacote verificado em 30/09/2026, revisão 1043b78 com árvore limpa. Smoke de 6120
ticks e seis combinações de janela/texto aprovados. Cada caso verificou seleção
e separação de indicador em três zooms. Matriz em
`../release/queue-presentation-matrix.json`; ZIP, documentos e hashes dos 45 PNGs
auditados. Kit externo atualizado. Compatibilidade em outra máquina pendente.

Perfil sintético de caminhada com 100/250/500/1000 hóspedes e duas distribuições
executado sem HUD ou simulação. Resultados e limites em
`../benchmarks/m8/QUEUE_PRESENTATION.md`. Não mede carga de filas nem latência do clique.
