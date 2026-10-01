# Inventário global de speedups

Este componente da Sprint 5 prepara os consumíveis necessários às obras. Gems,
Empire Points, compras e rewarded ainda pertencem aos Sprints 6–7. Os itens deste
componente vêm de recompensas gratuitas; o catálogo não entrega compras fictícias.

## Política de produto

Dois slots de obras continuam gratuitos. Esperar conclui a mesma sala ou melhoria,
com os mesmos atributos e sem gastar itens. Speedups alteram somente o prazo de uma
obra ativa. Não alteram receita, qualidade, XP, salários, tarefas físicas ou Hotel Cash.

Resources definem três itens: 5 minutos, 15 minutos e 1 hora. `speedup_rules.tres`
concede um item de 5 minutos ao perfil novo ou migrado e um de 15 minutos ao concluir
os nove fatos físicos do tutorial. Cada origem tem uma concessão persistida única.
O item de 1 hora está definido, com estoque zero até existir uma origem implementada.

Um item afeta uma única obra. A redução é o menor valor entre seu tempo e o prazo
restante. O excedente é descartado, informado antes da confirmação. Uma redução
parcial mantém a obra indisponível; conclusão libera o slot e inicia a próxima
obra elegível no instante da aceleração. Obras na fila não consomem itens.
Cancelar uma obra acelerada estorna o capital da obra, sem devolver o item usado.

## Donos e persistência

`PlayerInventory`, em `core/economy/`, pertence ao GameController e fica em
`app_state.player_inventory`. É separado do HotelEconomy e das definições Resource.
O inventário pode ser preservado quando o hotel mudar; a navegação entre hotéis
continua no Sprint 11. Nenhum SDK escreve diretamente nesse estado.

Snapshot v1 contém quatro campos exatos: `version`, `grants`, `spent` e
`next_spend_id`. Concessões registram as quantidades recebidas, preservando-as após
mudanças futuras de balanceamento. Estoque deriva das concessões menos os gastos.
IDs de consumo são monotônicos, compartilhados pelos três itens e não reutilizados.

Restore valida origens/itens conhecidos, inteiros, limites, estoque não negativo e
sequência consistente. Falha preserva o inventário vivo. Números lidos de JSON são
normalizados para inteiros; snapshots são cópias. SaveService valida o módulo e
exige o tutorial concluído para sua concessão. Versão futura bloqueia downgrade,
inclusive quando há backup de uma versão anterior.

Perfis anteriores sem o módulo recebem a concessão de boas-vindas uma vez. O
checkpoint inclui inventário, hotel, relógio, obras e guia no mesmo envelope. Essa
validação local não autentica recibos de loja ou hora de servidor.

## Transação de consumo

GameController primeiro liquida deadlines vencidos e valida estoque/ID/alvo.
ConstructionSpeedupPlan cria um estado candidato com a mesma operação, sem tocar
no hotel vivo. SaveService persiste esse envelope antes de aplicar a redução e o
consumo ao estado vivo. Falha de escrita preserva item, dinheiro e obra, permitindo
repetir a mesma operação depois de recuperar o storage.

A aplicação preserva a identidade da sessão e dos atores/tarefas existentes.
Comandos reentrantes e ticks ficam bloqueados durante o commit síncrono. A última
intenção de pause/resume recebida nesse período é aplicada após o commit. Observadores
de checkpoint recebem o evento depois que estado vivo e persistido estão coerentes.
Um callback repetido, inclusive após reinício, não consome outro item.

## Interface e feedback

A ficha de obra mostra duração e estoque de cada item. Itens vazios ou obras na
fila têm controles desativados. A confirmação informa redução real, prazo restante,
descarte do excedente e quantidade disponível. Back cancela sem consumo; conclusão
natural enquanto a confirmação está aberta remove a ação e preserva o item.
O botão final mantém quantidade e duração do item visíveis mesmo após scroll.

Cada ação usa a ampulheta raster original em `assets/art/icons/speedup.png`, importada
com limite de 256 px e apresentada a 32 unidades. PT-BR/EN/ES têm as mesmas 351 chaves
de produto. O rótulo espanhol de unidades foi encurtado após medir truncamento no
landscape com fonte ampliada; duração e quantidade continuam explícitas.

`speedup_used` entra na fila limitada de analytics após sucesso. Propriedades são
`kind` (ID público do item) e `duration_seconds` (redução efetiva). Recibos e campos
pessoais são rejeitados. Provider indisponível não interfere no consumo.

## Validação

`speedup_test` cobre 97 verificações de inventário, transação, save, falha de escrita,
IDs repetidos, lifecycle, redução parcial/restart, fila e identidade das tarefas.
`onboarding_test` e o fluxo físico por toque verificam a concessão única do tutorial.
`speedup_touch_test` usa InputEventScreenTouch pela GUI real, em seis perfis e três
formatos com PT/ES/EN, texto ampliado e recortes: cancelamento, alvo concluído durante
confirmação, erro/retry, consumo completo, parcial e reinício um milissegundo antes
do deadline. Também verifica alpha real, import e leitura dos controles.

O harness aguarda contagens originais de referências WAV do mixer com limite de
dois segundos; timeout, erros, leaks e saída não zero reprovam os executores. O teste
de trabalho físico libera seu frame de execução antes do shutdown, preservando os
2.862 casos anteriores. Resultados, fontes e capturas estão em
`SPRINT5_SPEEDUP_VALIDATION.json`; o registro é parcial e não conclui a Sprint 5.

Gate parcial: 19 suítes mobile, 7.771 verificações efetivas, 11 suítes de domínio
preservadas, 21 scripts sem diagnostics e três suítes nativas com 1.189 verificações
e 51 capturas. A revisão final do rótulo de confirmação recebeu rechecks específicos
de touch/presentation/static/native, substituindo suas contagens anteriores no registro.
