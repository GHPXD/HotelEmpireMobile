# Ciclos sutis de repouso nas camas

Três folhas quadradas de 1254 × 1254 RGBA geradas pelo `image_gen` integrado ao
chat, com quatro poses em grade 2×2. Olhos fechados, pijamas mostarda/jade/lavanda,
travesseiro e edredom marfim. Perspectiva frontal vista do pé da cama, com corpo
encurtado. As poses variam discretamente mãos e centro do edredom ao respirar;
há pequenas variações pintadas entre quadros, sem rig ou interpolação de movimento.

Novos arquivos `balanced-sleeping-loop.png`, `business-sleeping-loop.png` e
`leisure-sleeping-loop.png` em `assets/art/characters`. Copiados sem edição de
pixels. Originais estáticos preservados como referências. Prompts completos e
tentativas de layout descartadas em `bedroom-sleeping-loop-prompts.json`, dimensões
e hashes em `manifest.json`. Somente as três folhas quadradas selecionadas entram
no projeto; tentativas com pouco espaço entre edredons não foram usadas.

Recortes medidos por leitura dos quatro maiores componentes conectados do alfa
>100, ordenados da esquerda para a direita em cada linha, com margem de dois
pixels. Isso separa a silhueta principal de marcas isoladas no fundo transparente.
Os quatro retângulos não se sobrepõem e permanecem contidos no PNG. Medições em
`bedroom-sleeping-loop-measurements.json`; normalização de escala e âncora acontece
no Godot, preservando os pixels fonte. Imports usam mipmaps e correção de borda alfa.

Os mesmos IDs `*-sleeping` do catálogo agora apontam para os novos arquivos;
continua exclusivo de hóspedes em `using` no quarto. Escala única por perfil,
largura máxima de 52px e âncora inferior central, com a mesma posição sobre as
camas. Um quadro a cada 12 ticks: ciclo de 48 ticks (4,8s em velocidade normal),
fase por ID. Pausa congela; velocidade acompanha a simulação. Caminhada usa a
faixa original ao terminar o uso. Peseira N3 e circulação permanecem à frente.
Não muda save, ocupação, preço, necessidades, timer, RNG ou posição autoritativa.

Catálogo: 48 PNGs, 27 texturas de personagens. Três novos arquivos substituem as
referências estáticas somente no mapeamento ativo, sem aumentar a quantidade de
texturas pré-carregadas pelo catálogo. O diagnóstico do export confere 12 sprites
de uso dos hóspedes, todos com quatro quadros, e os quatro contextos da equipe.

Validação: quatro scripts válidos pelo gda. `ui_art` aprovado nas nove combinações
de perfil × cama N1/N2/N3; todos os quadros contidos no quarto e acima do piso nos
zooms 0,35/0,90/1,80. Quatro quadros distintos por perfil, limites de textura,
largura/âncora, avanço a cada 12 ticks, loop em 48 e retorno à caminhada conferidos.
Cliques selecionam os nove hóspedes na cama. Quatro capturas de fase inspecionadas,
incluindo peseira N3 em primeiro plano. Seis camas completas no enquadramento
mostraram mudanças de pixels durante o ciclo. Pausa, desenho e seleção conservaram
os snapshots. `ui_culling` passou nas 11 câmeras; `ui_actor_presentation` e
`ui_content` passaram. Sem erros de script ou recursos retidos ao sair.

Pacote verificado em 30/09/2026, revisão a0fcec0 com árvore limpa. Smoke de 6120
ticks e seis combinações de janela/texto aprovados. Cada caso verificou quatro
quadros dos 12 sprites de uso, quatro contextos de repouso da equipe e seleção
em três zooms. Matriz em `../release/bedroom-sleeping-loop-matrix.json`. ZIP,
documentos e hashes dos 48 PNGs auditados; kit externo atualizado com o mesmo
pacote. Compatibilidade em outro computador permanece pendente.
