# Repouso e espera dos funcionários

Dois PNGs originais gerados pelo `image_gen` integrado ao chat, preservando rosto,
proporções e uniformes das faixas de trabalho já usadas no jogo. Camareira em rosa
com avental creme; recepcionista de colete azul e camisa creme. Quatro poses de
pés parados: mãos reunidas, pequeno olhar, ajuste do avental/punho e retorno.
Não há esfregão, prancheta ou outros acessórios durante o repouso.

`cleaner-idle.png`: 2100 × 749. `receptionist-idle.png`: 1774 × 887.
Ambos RGBA, alfa entre 0 e 255, copiados sem edição de pixels. Prompts completos
em `staff-idle-prompts.json`, recortes e âncoras em `staff-idle-measurements.json`,
dimensões e hashes em `manifest.json`. Imports usam mipmaps e correção de borda alfa.

Somente funções `cleaner` e `receptionist` em estados `idle` e `lift_queue`
selecionam essas faixas. Caminhada e trabalho preservam suas sequências. Não muda
atribuição, transporte, economia, posição autoritativa ou schema de save.
Cadência: 16 ticks por pose, 64 ticks por ciclo (6,4s em velocidade normal), fase
por ID; pausa congela e velocidade acompanha o relógio existente.

Recortes medidos no alfa >100 com margem de quatro pixels. Centro horizontal dos
sapatos medido na faixa inferior de 20 pixels; altura da âncora coincide com o
último pixel opaco dos sapatos. Escala única por faixa, com altura máxima de 46px
em zoom 1, preserva proporção e alinhamento dos pés entre gestos. Não se presumem
células de recorte iguais nem se normalizam pixels dos PNGs.

Catálogo atual: 45 PNGs e 27 texturas de personagens. O diagnóstico do export
confere os dois novos sprites em quatro contextos (duas funções × dois estados),
além dos 12 sprites de uso dos hóspedes.

Validação: quatro scripts aprovados pelo `gda` sem diagnósticos após importação.
`ui_art` conferiu os dois estados por função, transparência, quatro recortes,
cadência/loop, escala compartilhada, âncoras e retorno às faixas de caminhada e
trabalho. Quatro capturas de fase inspecionadas no jogo; clique seleciona os quatro
funcionários no ponto desenhado e snapshots permanecem iguais. A vitrine posiciona
somente a camareira em limpeza no andar superior, mantendo o repouso separado.
`ui_culling` passou nas nove câmeras com trabalho, repouso e fila da equipe;
`ui_content` passou. Sem erros de script ou recursos retidos ao sair.
