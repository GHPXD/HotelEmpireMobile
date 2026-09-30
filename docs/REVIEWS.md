# Avaliações dos visitantes

O botão **Avaliações** abre as últimas 20 saídas, da mais recente à mais antiga.
Cada registro contém perfil, identificador do visitante, instante da saída,
satisfação final, realização de check-in e contadores de refeições, serviços e
descansos, tempo na recepção e tempos nas filas de elevador e serviço. Descansos
são usos do quarto, não diárias nem noites dormidas.

O relato usa somente esses fatos. Satisfação a partir de 80 produz uma opinião
satisfeita; de 50 até abaixo de 80, razoável; abaixo de 50, insatisfeita. A nota
individual aparece junto ao texto. Essa classificação não altera a satisfação
nem a reputação, que continua sendo atualizada pelo sistema de hóspedes.
Os tempos permitem investigar o que ocorreu, mas não atribuem uma causa única
à nota nem afirmam que o preço foi excessivo.

Tempo na recepção inclui fila, busca de quarto disponível e atendimento, desde
a chegada à recepção. Filas de elevador somam o tempo em `lift_queue`, incluindo
o tick de embarque, sem caminhada ou viagem. Filas de serviço somam os ticks de
`service_queue` após verificar sala, orçamento e entrada na fila; uma admissão
imediata registra um tick (0,1s). Contadores são cumulativos por visita e não
reiniciam com `travel_to`. Não incluem funcionários. Esses tempos usam segundos
da simulação e permanecem congelados com a pausa.

O registro ocorre no tick da saída, depois das alterações de satisfação desse
tick, antes de remover o ator. Não consome aleatoriedade. Quando chega o 21º
registro, o mais antigo é descartado. A janela pausa a simulação; Esc fecha e
devolve o foco ao botão. Novo hotel fecha a janela e começa sem histórico.
Fechar o jogo com a janela aberta a oculta antes da confirmação de saída.

## Persistência

Schema de save v7. A migração v5 → v6 começa com histórico vazio, sem inventar
visitas antigas. A migração v6 → v7 conserva as avaliações e marca seus tempos
como desconhecidos (`null`). Visitantes que já estavam ativos no save antigo
mantêm os três contadores em -1; sua futura avaliação também fica sem esses
tempos, pois medições parciais não equivalem à visita inteira. Visitantes novos
começam em zero e acumulam suas medições. A cadeia anterior continua disponível. O nome
do arquivo de save não muda. O carregamento valida quantidade, tipos, limites,
cronologia, perfis existentes, IDs únicos de visitantes já removidos e coerência
entre serviços e refeições, além de tempos finitos/não negativos ou `null` nas
avaliações e do marcador -1 nos atores antigos. Um histórico inválido rejeita o snapshot.

## Verificação

`reviews_test.gd` cobre descarte dos registros antigos, fatos copiados, texto
sem mutação, JSON, continuidade determinística, migração sem alterar a origem e
rejeição de campos inválidos, duplicações e excesso de registros.
Também verifica recepção, duas admissões de serviço, múltiplas etapas de fila
de elevador, exclusão da equipe, totais na saída e migração v6 sem tempos inventados.
`ui_reviews.gd` cobre abertura pela barra, vazio e visitas reais, foco, pausa,
Escape, novo hotel e cancelamento da saída enquanto o histórico está aberto.
Essas suítes fazem parte de `tools/test.ps1 -Visual -Stress`.

O pacote Windows da revisão 45d2eb6 também passou nas seis combinações locais
de janela/texto: restauração pela barra, fatos do último registro, janela dentro
do viewport, pausa em 1x e fechamento com foco restaurado. Evidência em
`docs/release/reviews-cafe-matrix.json`.

Esse pacote anterior usa v6 e não inclui os tempos de visita. A validação do
schema v7 ocorre no projeto; sua reexportação permanece pendente.
