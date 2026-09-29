# Objetivo e destino no inspetor

Selecionar um personagem identifica a atividade atual, a sala e seu andar.
Durante caminhada, fila de elevador ou viagem, o objetivo é derivado de
`destination_state`; o estado visível continua descrevendo o deslocamento.

Check-in identifica a recepção; descanso identifica o quarto; serviços mostram
o estabelecimento de destino. Limpeza e atendimento usam a atribuição do
funcionário, pois esses agentes não usam `target_room` para suas tarefas.
Saída e escolha de atividade não mostram uma sala antiga como destino.
Referências ausentes são apresentadas como “Sem sala definida”.

O quarto reservado passa a mostrar nome, ID e andar. “Tempo no hotel” é o
tempo desde a chegada, inclusive antes do check-in. Não equivale a noites ou
diárias cobradas. A duração de espera é exibida somente na recepção, na fila
de serviço ou na fila de elevador, com rótulo próprio. O contador da recepção
inclui atendimento e busca de quarto; não é denominado apenas fila.

A projeção é somente leitura e não altera saves, navegação, decisões ou RNG.
`ui_content` valida seleção real do personagem, destino de café, espera,
embarque sem espera antiga, saída, decisão, ausência de mutação e save/load.
`ui_management` cobre os fluxos de gestão existentes. Ambas passaram em
29/09/2026; a captura do inspetor foi inspecionada visualmente.

O ZIP Windows 45d2eb6 permanece como artefato anterior validado; este incremento
ainda não foi reexportado.
