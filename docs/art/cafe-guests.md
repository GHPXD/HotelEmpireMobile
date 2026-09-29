# Hóspedes no Café Brisa

Três poses estáticas dedicadas, geradas diretamente pelo `image_gen` do chat em
29/09/2026. Cada PNG preserva o perfil visual do respectivo personagem: casual
com cardigan mostarda, executiva de blazer verde e turista de chapéu lilás.

Arquivos: `assets/art/characters/balanced-cafe.png`, `business-cafe.png` e
`leisure-cafe.png`. Todos são RGBA de 1024 × 1536, com transparência real.
Os prompts e o refinamento do primeiro recorte estão em `cafe-guests-prompts.json`;
dimensões e hashes estão no manifesto de arte. As imagens foram copiadas sem
alterar pixels. Regiões foram medidas pelo canal alfa, com margem de quatro pixels.

O renderer usa a pose somente quando um hóspede está em `using` no Café Brisa.
Filas, quartos, restaurante e lounge continuam usando seus estados anteriores.
A altura visual permanece em 46 pixels na escala padrão, alinhada pelos pés,
com mipmaps para redução. São poses únicas, não ciclos de animação.

`tests/ui_art.gd` verifica transparência, seleção contextual, estabilidade da pose
e que o desenho não altera a simulação; captura o hotel em três escalas.

Validação em 29/09/2026: suíte `ui_art` concluída com zero falhas e sem erros
do Godot na execução fora do sandbox; capturas de zoom 0,35, 0,90 e 1,80.
Total do catálogo: 31 PNGs, dos quais 13 texturas de personagens.
