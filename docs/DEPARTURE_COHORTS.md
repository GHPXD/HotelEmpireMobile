# Satisfação final por grupo de saída

Pergunta: o efeito da tarifa sobre quem realmente se hospedou fica encoberto
pela mistura com desistências e pela suavização temporal da reputação?

Observador restrito a testes, em `tests/departure_observer.gd`. Antes de cada
tick, retém referências aos hóspedes atuais. Depois do tick, identifica os
removidos e lê a satisfação final dessas referências. Isso inclui alterações
do último tick, como penalidade por fome, e evita usar uma amostra atrasada.
Conta cada remoção uma vez; funcionários são excluídos. `checked_in` separa
quem pagou por uma estadia de quem saiu sem se hospedar, mesmo após o quarto
ser liberado. Retém apenas referências de um tick e agregados, sem histórico
individual crescente, escrita no jogo, RNG ou alterações de save.

Experimento: os mesmos 18 casos de `LODGING_VALUE.md`, oito quartos, três seeds,
serviços fixos em 100%, hospedagem em 75/100/125%, com/sem expansão e 30 dias.
Cinco checkpoints por cenário conferem continuidade. Contagens e somas de
satisfação dos grupos devem reconciliar com os totais autoritativos do jogo;
todas as métricas anteriores devem ser exatamente reproduzidas para demonstrar
que a observação não interfere nos resultados.

Comparar médias de saída de quem se hospedou entre tarifas no mesmo contexto.
Apresentar também o grupo sem estadia e as quantidades, sem atribuir todo o
efeito agregado exclusivamente ao preço. A reputação do jogo é uma média móvel
das saídas; a média histórica deste observador tem denominador diferente.
Nos resumos entre seeds, usar média ponderada pelo número de pessoas e mostrar
o intervalo das médias de cada seed. Não interpretar três seeds como intervalo
de confiança populacional. Este diagnóstico não recupera saídas anteriores ao
início da observação e não adiciona uma tela histórica ao jogo.

Reprodução: Godot headless, `--script res://tests/tariff_scenarios.gd --
--departure-cohorts`, APPDATA isolado. Saída `.runtime/departure-cohorts.json`.
`tools/summarize_departures.py` recebe resultado, referência
`docs/benchmarks/tariffs/lodging-value.json` e caminho de saída.

Teste unitário do observador: duas remoções reais com fome no último tick,
reconciliação das somas, ausência de mutação da sessão e dos relatórios,
exclusão de equipe, vazio e proteção contra contagem duplicada. Incluído no
modo opcional `tools/test.ps1 -Tariffs`, sem alterar a bateria rápida.

## Resultado — 25/09/2026

18 cenários completos, zero falhas, 90 checkpoints. Todas as métricas anteriores
permaneceram exatamente iguais à referência `lodging-value.json`. Contagens e
somas dos grupos reconciliaram com o jogo em todos os casos. Evidências e hash
do observador em `benchmarks/tariffs/departure-cohorts*.json`.

Médias ponderadas entre três seeds; quantidades são saídas simuladas somadas:

| Oferta | Tarifa | Saíram após estadia | Satisfação após estadia | Saíram sem estadia | Satisfação sem estadia |
|---|---:|---:|---:|---:|---:|
| Inicial | 75% | 669 | 78,95 | 762 | 34,24 |
| Inicial | 100% | 671 | 71,70 | 719 | 34,28 |
| Inicial | 125% | 673 | 64,52 | 675 | 34,37 |
| Expandida | 75% | 680 | 79,66 | 761 | 34,20 |
| Expandida | 100% | 681 | 72,55 | 718 | 34,31 |
| Expandida | 125% | 680 | 65,51 | 675 | 34,32 |

As faixas entre médias por seed não se sobrepõem entre tarifas na população
hospedada, em nenhum dos dois contextos medidos. Premium reduz essa média em
cerca de 7 pontos contra padrão; econômica aumenta em cerca de 7. A média de
quem não se hospedou permanece próxima de 34. Mais saídas sem estadia com
desconto são compatíveis com o feedback já existente: satisfação maior melhora
reputação, que aumenta procura e pode pressionar filas. Este experimento não
isola causalmente cada elo dessa cadeia.

Decisão: conservar o primeiro ajuste de valor. Sua contrapartida na experiência
da estadia foi observada mesmo quando a reputação final agregada sugeria outra
coisa. Não aumentar a penalidade para forçar reputação final monotônica, nem
alterar o mecanismo de reputação com base apenas nesses três seeds. A avaliação
de gestão deve acompanhar satisfação após estadia, volume de desistências e
lucro, além da reputação. Calibração com upgrades, políticas adaptativas e
playtest humano permanece aberta. O executável não mudou neste estudo.
