# Construção e progresso temporal — Sprint 5

Sprint em implementação. `ProgressClock` e `ConstructionService` estão implementados
e testados isoladamente, ainda sem integração ao GameController/save/interface.
Speedups, N4/N5, especializações e settlement offline do hotel continuam pendentes.
O fluxo do produto ainda usa a construção validada na Sprint 4; esta documentação
não conclui a sprint.

## Relógio implementado

O relógio pertence à aplicação. Construção deve usar milissegundos de progresso,
independentes de `HotelSession.time`, velocidade e pausa da simulação. Durante uma
execução, o tempo avança pelo contador monotônico. O relógio do sistema só mede
ausência no boot/resume e fornece o watermark dos checkpoints ativos.

O Godot documenta que o relógio do sistema pode ser alterado pelo usuário/OS,
enquanto `get_ticks_msec()` é monotônico. Essa distinção orienta o componente:
[documentação de Time](https://docs.godotengine.org/en/stable/classes/class_time.html).

Estado v1: `time_ms`, `wall_watermark_ms` e versão, todos com validação numérica.
Timestamp do envelope antigo pode iniciar o relógio sem inventar um histórico.
Rollback não diminui progresso nem watermark; corrigir a data para um valor já
observado não concede a ausência outra vez. Tempo de jogo ativo continua avançando
mesmo com o relógio civil atrasado. Ausência extrema é limitada a sete dias por
settlement; o watermark consome também o excesso descartado.

Suspensão congela o relógio até resume. Checkpoint durante background preserva o
anchor de ausência, para uma compra ou outro callback futuro não apagar esse intervalo.
Resume atualiza a base monotônica e aplica apenas a ausência, sem contar duas vezes
o período em que o processo permaneceu aberto. Resume duplicado concede zero.

A suíte `progress_clock_test` passou em 35 verificações pelo gda estrito, com saída
zero e sem diagnostics (`.runtime/tests/20261001T112800Z-sprint5-clock-final/`).
Usa providers injetáveis e deadlines concretos, sem
espera real: precisão em milissegundos, mudança de relógio durante obra, restart,
background, callbacks/checkpoints, rollback, ausência extrema e dados inválidos.
Essa proteção local não comprova hora confiável de servidor ou autenticidade de compra.

## Núcleo da fila implementado

`ConstructionService` pertence à aplicação e referencia o `HotelModel`. A simulação
continua sendo dona das salas concluídas. `finish_build` coloca uma sala já paga;
`build` permanece útil para autoria de estado e regressões de domínio. A integração
do produto vai encaminhar construção/upgrades/andares ao serviço de obras.

Dois slots gratuitos processam até 12 investimentos no total, incluindo ativos.
Os demais aguardam FIFO. Terreno é reservado ao aceitar; um elevador reserva seu
poço em todos os andares. Andares sucessores aguardam a conclusão do anterior.
Upgrades conservam os atributos anteriores durante a obra e não duplicam investimento.

Cash é debitado como capital uma vez. Cancelamento antes da conclusão estorna o
investimento inteiro, libera espaço/slot e não fabrica receita operacional. Não é
possível cancelar um andar que sustenta outros investimentos pendentes. Uma obra
invalidada devolve o capital uma vez e não conta como conclusão.

O processamento visita deadlines em ordem de tempo/ID. Ao liberar um slot, a próxima
obra começa naquele deadline, mesmo se o retorno ocorrer muito depois. A mesma fila
produz o mesmo hotel ao observar cada segundo, retornar após ausência ou restaurar
um save intermediário. Nenhum desses caminhos executa ticks de simulação adicionais.

Estado v1 guarda jobs, timestamps, slots, custo pago, alvo e contadores/ID. Restore
valida campos, referências, sobreposição, slots únicos, fila de andares e capital
reservado; falha não altera o estado vivo. Tempos ficam em `construction_rules.tres`.

`construction_timer_test` passou em 162 verificações pelo gda estrito. As 11 suítes
do grupo domain também passaram após a separação de colocação/cobrança e estorno.
Provas dos componentes ficam em `SPRINT5_COMPONENT_VALIDATION.json`; não substituem
o gate de integração por toque, lifecycle e export da sprint completa.

## Decisões para a integração pendente

- Dois slots simultâneos gratuitos e fila limitada, sem vender a capacidade base.
- Primeiras obras de 10/20/30/60 segundos; early de 1–5 minutos, mid de 5–30 minutos.
  Até quatro horas somente em investimento relevante. Dados ficam em Resources.
- Reserva de terreno e Cash uma vez ao aceitar; nenhuma sala oferece serviço antes
  de concluída. Upgrades mantêm seu nível anterior até conclusão válida.
- Fila, custos, reservas, timestamps e inventário de speedups persistem juntos.
  Jobs têm IDs não reutilizados e conclusão idempotente.
- Conclusão offline processa a fila agregadamente; não reproduz ticks de ausência.
  Receita/despesas offline do hotel têm política e cap próprios, separados das obras.
- Esperar sempre permite progredir. Speedups usam inventário global separado de
  Hotel Cash. Gems/rewarded dependem da economia e dos providers dos Sprints 6–7.
- N4/N5 e primeiras especializações entram somente onde alteram decisões reais,
  mantendo migrations e regressões de N1–N3.

O gate da Sprint 5 exige ciclo completo por toque, fila/slots, uso real de speedup,
restart/background/rollback, conclusão offline, persistência e regressões anteriores.
