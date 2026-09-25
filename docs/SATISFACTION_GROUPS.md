# Satisfação de quem está no hotel

Operação (F2) mostra duas populações atuais: presentes com check-in e presentes
sem check-in. Cada linha traz quantidade e satisfação média, excluindo equipe.
Grupo vazio mostra `—`; não é interpretado como satisfação zero.

A classificação usa `checked_in`, não o quarto atual nem o estado de movimento.
Assim, um hóspede pago continua no seu grupo enquanto sai do hotel, mesmo após
liberar o quarto. Quem chega, espera ou desiste sem se hospedar permanece no
grupo sem check-in até ser removido da simulação. As contagens somam todos os
hóspedes presentes; a média ponderada reproduz a média geral.

São projeções somente de leitura: não modificam RNG, counters ou schema de save.
Não representam avaliações históricas, causas individuais de insatisfação ou
uma estimativa do efeito causal das tarifas. A reputação continua sendo um
indicador separado, atualizado nas saídas. O estudo de coortes históricas para
calibrar tarifas permanece pendente.

O resumo tem rolagem própria para texto ampliado; o painel preserva espaço para
filtros, lista de salas e ações. Com foco no resumo, setas, Page Up/Down e Home/End
rolam; Tab e Esc continuam funcionando. O texto só é substituído quando muda,
preservando a leitura de um hotel pausado e evitando atualizações redundantes.

Validação: analytics cobre vazio, exclusão da equipe, médias/contagens,
reconciliação dos grupos, saída com e sem check-in e ausência de mutação.
ui_operations verifica valores vazios/preenchidos, texto ampliado, rolagem por
teclado, filtros e fechamento. Captura: `.runtime/satisfaction-groups.png`.
