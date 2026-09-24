# Tarifas por categoria e oferta de serviços

Extensão do diagnóstico em `TARIFF_BALANCE.md`. Pergunta: a vantagem de premium
vem da hospedagem, dos serviços ou da falta de opções de serviço?

Matriz: oito quartos, três seeds (1, 17, 123), tarifas de hospedagem e serviço
independentes em 75/100/125%, com e sem expansão. São 54 cenários de 30 dias,
partindo de $12.000. Geometria inicial, funcionários e construção seguem o
experimento anterior. Sem upgrades. No cenário expandido, café e lounge são
comprados no primeiro tick depois de cinco dias. Os desbloqueios naturais e a
capacidade de pagar são verificados; nenhum objetivo ou dinheiro é concedido.

Cada cenário valida invariantes e cinco saves com 120 ticks de continuidade.
A compra é espelhada na sessão restaurada durante o checkpoint correspondente,
para comparar as mesmas ações de gestão. Receitas por tipo de sala e total de
usos de serviço complementam reservas/refeições/reputação/ocupação/lucro.

Comparações são pareadas por seed, expansão e tarifa da outra categoria. O
efeito isolado de aumentar de 100% para 125% é descrito separadamente para
hospedagem e serviços. Médias são descritivas; três seeds não representam uma
estimativa de confiança sobre toda a população de partidas. Como as trajetórias
podem consumir RNG de maneiras diferentes, diferenças pequenas não comprovam
uma causa única. Nenhuma regra do jogo é ajustada para produzir o resultado.

Reprodução: executar Godot headless com `--script res://tests/tariff_scenarios.gd`
e argumentos de usuário `-- --tariff-mixed`, com APPDATA isolado. Saída em
`.runtime/tariff-mixed.json`. `tools/summarize_mixed_tariffs.py` aceita o caminho
de entrada e saída e rejeita matrizes incompletas, duplicadas ou com falhas.

## Hipótese para o próximo protótipo

O código atual verifica apenas orçamento na hospedagem; nos serviços, subtrai
preço × sensibilidade do perfil da utilidade calculada. Testar a percepção de
valor como consequência da tarifa, mantendo o preço padrão neutro. Um bônus
por desconto ou penalidade por sobretaxa pode afetar satisfação na contratação,
proporcional à sensibilidade já definida no perfil. Cobranças monetárias e
contratos continuam independentes desse efeito.

Critérios antes de aceitar esse protótipo: zero efeito a 100%; efeito aplicado
uma vez por hospedagem/contrato, nunca por tick de espera; nenhuma alteração
retroativa quando a tarifa muda; saves continuam equivalentes; preço premium
produz uma diferença perceptível de satisfação, sem tornar 75% uma solução
universal. A interface deve mostrar a consequência antes da escolha. Essa é
uma proposta de experimento, ainda não uma regra implementada ou calibrada.

## Resultado — 24/09/2026

54 cenários e 270 checkpoints aprovados, sem erros no log. Os nove cenários
que coincidem com a linha de base anterior reproduziram exatamente todas as
métricas brutas anteriores. Proveniência e hash do script em
`benchmarks/tariffs/mixed-provenance.json`; dados completos em `mixed.json` e
comparações/intervalos em `mixed-summary.json`, no mesmo diretório.

| Aumento isolado de 100% para 125% | Pares | Lucro maior | Experiência medida idêntica |
|---|---:|---:|---:|
| Hospedagem | 18 | 18 | 18 |
| Serviços | 18 | 18 | 12 |

Experiência idêntica significa reservas, refeições, usos de serviço, reputação
e ocupação iguais dentro de tolerância de 1e-9. Não significa identidade de
todos os estados individuais. Cada linha reúne nove pares sem expansão e nove
com expansão. Para hospedagem, não houve diferença em nenhuma dessas métricas
em ambos os contextos. Serviços tiveram três pares com diferenças em cada
contexto. O critério de alerta de vantagem sem contrapartida foi confirmado
para hospedagem dentro do escopo medido.

Exemplos de médias das três seeds, mantendo a outra categoria a 100%:

| Oferta | Hospedagem | Serviços | Lucro em 30 dias | Reservas | Usos de serviço | Reputação |
|---|---:|---:|---:|---:|---:|---:|
| Inicial | 100% | 100% | 32.583,3 | 227,0 | 218,3 | 50,48 |
| Inicial | 125% | 100% | 40.528,3 | 227,0 | 218,3 | 50,48 |
| Inicial | 100% | 125% | 33.983,3 | 226,3 | 217,3 | 51,50 |
| Expandida | 100% | 100% | 34.324,0 | 231,7 | 294,0 | 49,59 |
| Expandida | 125% | 100% | 42.432,3 | 231,7 | 294,0 | 49,59 |
| Expandida | 100% | 125% | 35.995,0 | 231,0 | 287,0 | 49,51 |

Decisão: priorizar o protótipo de percepção de valor da hospedagem. Aumentar
apenas a oferta de serviços não resolve sua vantagem sem contrapartida.
Manter estes resultados como controle antes de mexer na satisfação ou nos
orçamentos. Não declarar equilíbrio geral: ainda faltam upgrades, concorrência
entre salas com preços diferentes, gestão adaptativa e avaliação humana.
