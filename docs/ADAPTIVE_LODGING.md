# Tarifas adaptativas a partir das avaliações

## Contrato do experimento

Testar uma decisão diária que use apenas o histórico disponível ao jogador.
Alvo: nas três seeds, satisfação média de quem se hospedou após o quinto dia
de pelo menos 75 e caixa final igual ou superior à tarifa econômica fixa.
Não exigir que a política maximize caixa. Medir a receita sacrificada em relação
a padrão e premium, além da frequência de alterações exigida do jogador.

12 partidas de 30 dias: seeds 1, 17 e 123, com quatro políticas por seed.
Três mantêm hospedagem em 75%, 100% ou 125% desde o início; a quarta começa em
100% e toma decisões a partir do sexto dia. Todas compram N2 para os oito quartos
nesse dia, com dinheiro ganho e desbloqueios naturais. Serviços ficam em 100%,
sem expansão. Orçamento e configuração são os mesmos do estudo de upgrades.

## Regra diária

Antes do primeiro tick de cada dia, do sexto ao trigésimo, ler as últimas 20
saídas do histórico e considerar apenas aquelas com check-in. Com menos de
cinco observações, manter a tarifa. Com média abaixo de 75, baixar um degrau
de 25 pontos; acima de 80, subir um degrau. Entre 75 e 80, inclusive, manter.
Limites: 75% e 125%. Não muda preço de contrato já iniciado.

O registro da decisão inclui scores, IDs e instantes observados. Não recebe
resultados futuros nem métricas históricas globais do observador de teste.
A seleção das avaliações é somente leitura. Nos checkpoints, a política
recalcula sua decisão a partir do save restaurado antes de aplicar o comando.

O histórico limitado contém também desistências; portanto, pode fornecer menos
de 20 observações de hóspedes atendidos. Saídas observadas podem corresponder
a tarifas anteriores e o efeito de uma mudança chega com atraso. A regra não
identifica causas da insatisfação nem garante controlar a média nesse intervalo.

## Resultado — 29/09/2026

12 cenários, zero falhas e 60 checkpoints. Os nove controles fixos reproduziram
exatamente o estudo N2 anterior. As três partidas adaptativas eram idênticas
aos respectivos controles de 100% até o quinto dia, inclusive na compra de N2.
75 decisões diárias foram validadas contra suas observações e o relógio.

| Política | Caixa final médio | Ganho de caixa após dia 5 | Satisfação atendidos após dia 5 |
|---|---:|---:|---:|
| 75% fixa | 27.952,3 | 21.257,0 | 80,81 |
| 100% fixa | 37.882,0 | 29.891,7 | 73,63 |
| 125% fixa | 47.577,0 | 38.266,0 | 66,34 |
| Adaptativa | 33.695,7 | 25.705,3 | 77,20 |

Caixa é média de três seeds. Satisfação é média ponderada pelas saídas com
check-in na janela. Ganho após dia 5 desconta a diferença de caixa já existente
antes de iniciar a política; inclui a compra N2 e demais fluxos posteriores.

O alvo foi cumprido em 3/3 seeds. Depois do quinto dia, a adaptativa ganhou
$4.664, $5.462 e $3.219 a mais que econômica. Contra padrão, sacrificou
$4.747, $2.747 e $5.065 e ganhou 3,27, 2,85 e 4,61 pontos de satisfação.
Foram 13, 14 e 11 alterações ao longo de 25 decisões por partida: demanda de
gestão frequente, ainda não avaliada com jogadores. Em 75 dias somados das três
partidas, a política escolheu 75% por 43 dias, 100% por 28 e 125% por quatro.

## Decisão e limites

Conservar os valores atuais: a política encontrou uma posição intermediária
de caixa e satisfação, sem eliminar as diferenças das tarifas fixas. Levar
essa hipótese a playtest para avaliar se ler avaliações e alterar preços é
compreensível e interessante. O experimento não adiciona automação ao jogo.

A evidência cobre uma regra, três seeds e o hotel com N2 comprado no sexto dia.
Não estabelece uma estratégia ótima nem resolve expansão, N3, outras datas,
limiares ou escolhas individuais por quarto. Avaliações repetidas entre dias
não são amostras independentes. A janela após dia 5 inclui saídas de visitantes
admitidos antes da mudança.

Reprodução: Godot headless com APPDATA isolado e
`--script res://tests/tariff_scenarios.gd -- --adaptive-lodging`.
Validar `.runtime/adaptive-lodging.json` com `tools/summarize_adaptive_lodging.py`,
usando `benchmarks/tariffs/lodging-upgrades.json` como referência N2. Dados,
resumo e hashes de proveniência em `benchmarks/tariffs/adaptive-lodging*.json`.
O validador também rejeitou cinco mutações de relatório: caso ausente,
observação futura, decisão incorreta, controle divergente e caixa inconsistente.
