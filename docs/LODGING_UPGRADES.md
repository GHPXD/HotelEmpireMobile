# Tarifas com melhorias de hospedagem

## Pergunta e contrato

As três tarifas devem conservar diferenças legíveis de valor, inclusive após
melhorar quartos. Neste experimento, sinalizar investigação se premium deixar
de apresentar contrapartida na satisfação de quem se hospedou nos três pares
de seeds de uma política de melhoria, ou se o hotel de referência ficar sem
caixa para a compra programada. Não exigir igualdade de lucro entre tarifas.

Comparar caixa após o investimento, reservas e satisfação de hóspedes atendidos;
reputação agregada também inclui desistências e não basta como único indicador.
Se o retorno dos upgrades variar entre seeds, descrever a variação em vez de
atribuir dominância geral a uma política. Este contrato mede o modelo; a
avaliação de clareza e preferência do jogador continua dependendo de playtest.

## Contexto

27 partidas de 30 dias, seeds 1, 17 e 123. Oito quartos, uma recepção, um bistrô,
um elevador, um recepcionista e um camareiro. Orçamento inicial de $12.000.
Serviços em 100%, hospedagem em 75%, 100% ou 125%, sem expansão de serviços.

Três políticas: manter N1; comprar N2 para os oito quartos antes do tick 6001;
ou fazer essa compra e adquirir N3 antes do tick 18001. Os instantes correspondem
ao começo do sexto e do décimo sexto dia. Usar exclusivamente `upgrade_room`,
com dinheiro ganho na partida e objetivos concluídos naturalmente.

N2 custa $350 por quarto; N3 custa mais $600. Preço-base, manutenção e bônus
de satisfação vêm dos Resources existentes. N3 substitui os valores de N2;
os bônus não são cumulativos. Durante usos já iniciados, o sistema mantém seus
contratos normais; não se reconstrói a partida para simular uma melhoria.

Antes das compras, cada par de políticas deve ter resultados idênticos.
Os nove casos sem melhorias devem reproduzir exatamente as referências
sem expansão de `benchmarks/tariffs/departure-cohorts.json`. Cinco checkpoints
JSON por partida verificam mais 120 ticks de continuidade, inclusive compras
programadas que ocorrem logo após restaurar o save.

O observador mede saídas com e sem check-in e registra também a janela após
o quinto dia. Essa janela inclui hóspedes que chegaram antes da compra e saíram
depois; não representa exclusivamente clientes admitidos após o upgrade.
Ocupação continua sendo proporção de ticks com quarto reservado/ocupado.
Lucro é operacional; caixa final também desconta construção, contratação e
melhorias. Nenhum parâmetro do jogo é ajustado pelo experimento.

## Reprodução

Executar Godot headless com dados de usuário isolados:

```
--path C:/Projects/HotelEmpire --script res://tests/tariff_scenarios.gd -- --lodging-upgrades
```

Saída em `.runtime/lodging-upgrades.json`. Validar e resumir com
`tools/summarize_lodging_upgrades.py`, passando resultado, referência
`docs/benchmarks/tariffs/departure-cohorts.json` e destino do resumo.
O modo é opcional e fica fora da bateria rápida.

## Resultado — 29/09/2026

27 cenários completos, zero falhas, 135 checkpoints e nove referências N1
reproduzidas exatamente. Todas as 216 compras N2 e 72 compras N3 planejadas
foram pagas com caixa real. As políticas permaneceram idênticas até o quinto dia.

| Política | Tarifa | Caixa final médio | Satisfação atendidos após dia 5 |
|---|---:|---:|---:|
| N1 | 75% | 26.989,7 | 78,30 |
| N1 | 100% | 34.953,3 | 70,96 |
| N1 | 125% | 43.015,0 | 63,72 |
| N2 no dia 6 | 75% | 27.952,3 | 80,81 |
| N2 no dia 6 | 100% | 37.882,0 | 73,63 |
| N2 no dia 6 | 125% | 47.577,0 | 66,34 |
| N3 no dia 16 | 75% | 25.633,0 | 82,46 |
| N3 no dia 16 | 100% | 36.381,0 | 75,24 |
| N3 no dia 16 | 125% | 47.119,7 | 67,90 |

Caixa é média das três seeds; satisfação é média ponderada pelas saídas com
check-in nessa janela. Não comparar essas médias como se todas as partidas
tivessem exatamente os mesmos hóspedes.

N2 supera o caixa N1 em todos os nove pares. N3 supera N1 em caixa a 100% e
125%, mas fica abaixo a 75% nos três pares: diferenças de -1.163, -1.286 e
-1.621. Comparado a N2, N3 reduz caixa em oito dos nove pares; a exceção é
premium na seed 1, com +122. O instante de compra importa para o retorno em
30 dias, e a satisfação maior não implica recuperação imediata do investimento.

Premium fica entre 6,93 e 8,01 pontos abaixo de padrão na satisfação de quem
se hospedou após o quinto dia, nos nove pares de políticas/seeds. Econômica
fica entre 6,43 e 7,71 pontos acima. A contrapartida local de preço permanece
observável com upgrades. Melhorias não eliminam essa escolha de valor.

Decisão: conservar os coeficientes atuais. Há retorno positivo medido para N2,
custo de oportunidade de N3 comprado mais tarde e diferença de satisfação entre
tarifas. Isso não estabelece uma estratégia ótima global: faltam políticas
adaptativas, outras datas de compra, hotéis expandidos e playtest humano.

Dados brutos, resumo e proveniência: `benchmarks/tariffs/lodging-upgrades*.json`.
O experimento só altera ferramentas de medição; o pacote Windows validado
45d2eb6 continua com os valores usados neste estudo.
