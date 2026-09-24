# Percepção de valor da hospedagem

Problema medido: cobrar 125% na hospedagem aumentou o lucro em 18/18 pares,
sem alterar reservas, refeições, usos, reputação ou ocupação. Ver
`TARIFF_MIXED.md` e seus dados anteriores a esta mudança.

Primeiro ajuste: aplicar satisfação no check-in, uma vez por estadia, segundo
`(100 - tarifa_percentual) × sensibilidade_do_perfil`. Sensibilidade inicial:
0,2 ponto por ponto percentual para negócios; 0,3 para equilibrado e lazer.
Portanto, econômica oferece +5 a +7,5 pontos; padrão é neutra; premium custa
5 a 7,5 pontos. Satisfação continua limitada a 0–100. Os coeficientes ficam
nos recursos de perfil e o cálculo é compartilhado entre simulação e prévia.

Escopo: hospedagem apenas. Serviços mantêm sua avaliação de preço na utilidade.
O upgrade já define o preço padrão daquele nível; o percentual é relativo a
esse preço. Não há penalidade adicional por ter um quarto melhor. Não é uma
simulação completa de disposição a pagar nem uma nova regra de rejeição.

Trocar tarifa não reescreve satisfação de estadias já pagas. O efeito integra
o campo `happiness` existente, então não há novo schema nem reaplicação ao
carregar. Saves antigos permanecem compatíveis. Pessoas que já fizeram
check-in antes da mudança não recebem o efeito retroativamente.

Contrato do experimento: com serviços fixos em 100%, comparar hospedagem em
75/100/125% nas seeds 1/17/123, oito quartos, com/sem expansão real após cinco
dias. São 18 cenários de 30 dias e 90 checkpoints. Padrão deve reproduzir os
seis casos equivalentes anteriores exatamente. Premium deve apresentar uma
contrapartida mensurável de satisfação/reputação; econômica deve preservar o
custo em receita. Referência padrão deve continuar solvente. Não exigir lucro
igual nem proclamar calibração final com três seeds.

Reprodução: `tariff_scenarios.gd -- --lodging-value`, em Godot headless com
APPDATA isolado. Resultado em `.runtime/lodging-value.json`. Testes específicos
em `lodging_value_test.gd` cobrem os nove check-ins, efeito único, cobrança,
alteração posterior de tarifa e continuidade de save/load. O inspetor mostra
as três consequências por perfil antes da escolha; serviços não exibem essa
explicação de hospedagem.

## Resultado do primeiro ajuste

18 cenários completos, zero falhas e 90 checkpoints. Os seis cenários a 100%
reproduziram exatamente os relatórios anteriores, incluindo receitas por tipo,
ocupação e caixa. Dados e resumo em `benchmarks/tariffs/lodging-value*.json`.
Reprodução da comparação: `tools/summarize_lodging_value.py` recebe resultado
novo, referência `mixed.json` e arquivo de saída; rejeita deriva a 100%.

| Oferta | Tarifa hospedagem | Lucro médio | Reputação final média |
|---|---:|---:|---:|
| Inicial | 75% | 24.619,7 | 57,43 |
| Inicial | 100% | 32.583,3 | 50,48 |
| Inicial | 125% | 40.645,0 | 49,54 |
| Expandida | 75% | 25.992,7 | 56,71 |
| Expandida | 100% | 34.324,0 | 49,59 |
| Expandida | 125% | 42.095,3 | 50,09 |

Econômica perde lucro e ganha reputação nos seis pares contra padrão. Premium
ganha lucro nos seis; sua reputação final fica abaixo em três e acima em três.
O efeito direto negativo no check-in é garantido, mas reputação agregada também
depende da procura, filas e composição das saídas. Portanto, o ajuste cria uma
contrapartida local legível e uma vantagem observada para desconto, porém não
prova que premium perde a dominância contra padrão em todo cenário.

Decisão: manter como primeiro incremento, com padrão neutro e efeito apresentado
na UI. Continuar a calibração usando satisfação dos hóspedes efetivamente
hospedados, separada das saídas por desistência, além da reputação agregada.
Não aumentar o coeficiente apenas para fazer seis seeds produzirem o mesmo
sinal. Ainda faltam playtest humano e políticas de preço adaptativas.
