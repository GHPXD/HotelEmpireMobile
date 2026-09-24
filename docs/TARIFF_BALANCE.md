# Experimento de tarifas

Pergunta: tarifas globais fixas de 75%, 100% e 125% criam diferenças de caixa,
atendimento e reputação no hotel inicial? Ainda não há evidência humana de que
os jogadores entendem e aproveitam essa decisão.

Contrato de avaliação: em hotéis novos de dois e oito quartos, com $12.000,
uma recepção, um restaurante, um elevador e um funcionário de cada função,
comparar 30 dias nas seeds 1, 17 e 123. Não comprar upgrades nem expandir após
abrir. Aplicar o mesmo percentual aos quartos e ao restaurante. Usar 100% como
referência. Não exigir lucro igual das opções. Sinalizar para investigação se
uma política superar as demais em caixa e reputação em todos os contextos sem
reduzir atendimento, ou se a referência de oito quartos ficar insolvente.

Guardas: conservação de dinheiro, referências e capacidade válidas; cinco
round-trips JSON por cenário com 120 ticks de continuidade idêntica. Resultados
de insolvência não abortam a medição. Ocupação é a soma dos ticks com quarto
reservado/ocupado dividida por quartos × ticks; não mede presença física no
quarto. Caixa mínimo inclui o instante após construção. O lucro é operacional
acumulado, sem subtrair investimento inicial em construção/contratação.

Reprodução: executar `tests/tariff_scenarios.gd` no Godot em modo headless com
APPDATA isolado. Saída bruta em `.runtime/tariff-scenarios.json`. O experimento
fica fora da bateria rápida; custa 648.000 ticks mais 10.800 ticks de comparação
de saves. Não mede hotel expandindo, preços por sala mistos ou chegadas elásticas
em função de preço. Seeds iguais começam com o mesmo RNG, mas podem divergir
durante a simulação conforme a política muda o comportamento.

## Resultado inicial — 24/09/2026

Implementação de jogo medida: `9237939`, preservada em `ca3ef68` juntamente com
o experimento. Dados em `benchmarks/tariffs/baseline.json`; agregação reproduzível
em `benchmarks/tariffs/baseline-summary.json`, gerada por
`python tools/summarize_tariffs.py docs/benchmarks/tariffs/baseline.json docs/benchmarks/tariffs/baseline-summary.json`.
A simulação terminou com zero falhas, 18 cenários completos e 90 checkpoints
de save com continuidade. Não foram alteradas regras de economia neste estudo.

Médias das três seeds; lucro é acumulado em 30 dias:

| Quartos | Tarifa | Lucro | Reservas | Refeições | Reputação final | Ocupação |
|---|---|---:|---:|---:|---:|---:|
| 2 | 75% | 10.739 | 116,3 | 114,0 | 46,37 | 79,7% |
| 2 | 100% | 15.776,7 | 117,3 | 115,0 | 45,89 | 79,7% |
| 2 | 125% | 20.781,7 | 117,7 | 116,0 | 44,93 | 79,6% |
| 8 | 75% | 22.998 | 226,0 | 218,0 | 51,28 | 41,0% |
| 8 | 100% | 32.583,3 | 227,0 | 218,3 | 50,48 | 40,7% |
| 8 | 125% | 41.905 | 226,3 | 217,3 | 51,50 | 40,6% |

Premium supera o lucro padrão nos seis pares hotel/seed. Em quatro pares,
reservas, refeições, reputação e ocupação são idênticas: dois quartos/seeds 1
e 123; oito quartos/seeds 17 e 123. Os outros dois pares têm diferenças de
atendimento e reputação, portanto não há dominância universal comprovada em
todas as métricas. A referência de oito quartos permanece solvente nas três
seeds. Intervalos mínimo/máximo por métrica estão no JSON agregado.

Diagnóstico: contrapartida fraca para cobrar mais no hotel inicial. A leitura
do código explica uma hipótese causal: a hospedagem só verifica orçamento,
enquanto o peso do preço atua na escolha de serviços. Orçamentos iniciais de
320/420/360 permitem absorver muitos aumentos sem rejeição. Um restaurante
único também oferece pouca concorrência interna por preço. Isso é uma
interpretação dos mecanismos, não um experimento isolando cada causa.

Próximo ajuste a investigar: disposição a pagar em relação ao valor entregue,
separando hospedagem de serviços. Deve manter 100% como referência estável,
preservar contratos e saves e tornar legível por que um hóspede aceita ou
rejeita premium. Antes de calibrar coeficientes, comparar também preços mistos
por categoria e um hotel com café/lounge desbloqueados. Não reduzir orçamento
global apenas para forçar equivalência de lucro entre opções.

Comando integrado opcional: `./tools/test.ps1 -Tariffs`; executa a bateria base
e o experimento. As 26 suítes anteriores continuam disponíveis sem esse switch.
