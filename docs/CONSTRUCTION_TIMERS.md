# Construção e progresso temporal — Sprint 5

Sprint em implementação. O primeiro componente é `ProgressClock`, ainda sem
integração ao GameController/save. Fila, slots, obras, upgrades, speedups e settlement
offline do hotel continuam pendentes; esta documentação não conclui a sprint.

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
