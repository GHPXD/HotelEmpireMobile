# Avaliações dos visitantes

O botão **Avaliações** abre as últimas 20 saídas, da mais recente à mais antiga.
Cada registro contém perfil, identificador do visitante, instante da saída,
satisfação final, realização de check-in e contadores de refeições, serviços e
descansos. Descansos são usos do quarto, não diárias nem noites dormidas.

O relato usa somente esses fatos. Satisfação a partir de 80 produz uma opinião
satisfeita; de 50 até abaixo de 80, razoável; abaixo de 50, insatisfeita. A nota
individual aparece junto ao texto. Essa classificação não altera a satisfação
nem a reputação, que continua sendo atualizada pelo sistema de hóspedes.
Não há afirmações sobre causas, como espera de elevador ou preço excessivo,
porque o registro ainda não rastreia essas causas individuais.

O registro ocorre no tick da saída, depois das alterações de satisfação desse
tick, antes de remover o ator. Não consome aleatoriedade. Quando chega o 21º
registro, o mais antigo é descartado. A janela pausa a simulação; Esc fecha e
devolve o foco ao botão. Novo hotel fecha a janela e começa sem histórico.
Fechar o jogo com a janela aberta a oculta antes da confirmação de saída.

## Persistência

Schema de save v6. A migração v5 → v6 começa com histórico vazio, sem inventar
visitas antigas; a cadeia de migrações anteriores continua disponível. O nome
do arquivo de save não muda. O carregamento valida quantidade, tipos, limites,
cronologia, perfis existentes, IDs únicos de visitantes já removidos e coerência
entre serviços e refeições. Um histórico inválido rejeita o snapshot.

## Verificação

`reviews_test.gd` cobre descarte dos registros antigos, fatos copiados, texto
sem mutação, JSON, continuidade determinística, migração sem alterar a origem e
rejeição de campos inválidos, duplicações e excesso de registros.
`ui_reviews.gd` cobre abertura pela barra, vazio e visitas reais, foco, pausa,
Escape, novo hotel e cancelamento da saída enquanto o histórico está aberto.
Essas suítes fazem parte de `tools/test.ps1 -Visual -Stress`.

O pacote Windows da revisão 45d2eb6 também passou nas seis combinações locais
de janela/texto: restauração pela barra, fatos do último registro, janela dentro
do viewport, pausa em 1x e fechamento com foco restaurado. Evidência em
`docs/release/reviews-cafe-matrix.json`.
