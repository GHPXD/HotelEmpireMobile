# Hóspedes em repouso nos quartos

Três poses estáticas geradas diretamente pelo `image_gen` do chat. Cada recorte
mostra o rosto do perfil, pijama em sua paleta, mãos sobre o edredom e travesseiro.
As imagens usam a perspectiva frontal vista do pé da cama, com corpo encurtado
pela perspectiva. A turista retira o chapéu para dormir. Nenhum recorte contém
outra cama ou cenário; os ambientes pintados permanecem como base.

Arquivos em `assets/art/characters`: `balanced-sleeping.png`, `business-sleeping.png`
e `leisure-sleeping.png`, RGBA de 1774 × 887 com alfa entre 0 e 255. Copiados sem
editar pixels. Prompts em `bedroom-sleeping-prompts.json`, medições no alfa em
`bedroom-sleeping-measurements.json`, dimensões e SHA-256 em `manifest.json`.
Recortes com margem de quatro pixels, mipmaps e correção de borda alfa no Godot.

Somente hóspedes em `using` no quarto recebem essas poses. A largura de desenho
é 52px em zoom 1; escala preserva a proporção de cada PNG. Âncora inferior central,
posicionada em (0,5; 0,62) da pintura interna do quarto. O ponto de seleção
acompanha a imagem sobre a cama; `actor.x` e o trajeto continuam intactos.
Pausa e ticks não mudam a pose: este incremento não fornece ciclo de respiração.

No N3, a região normalizada (0,28; 0,572; 0,435; 0,09) da pintura é redesenhada
sobre o hóspede para preservar a peseira de madeira. Dorminhocos e peseiras são
desenhados antes dos personagens que circulam pelo piso. Isso evita cobrir o rosto
de um personagem em primeiro plano com a região restaurada. Sem consumo de RNG,
alteração de relógios, ocupantes, necessidades ou saves.

Validação: `ui_art` aprovado nas nove combinações dos três perfis com N1/N2/N3.
Clique seleciona cada hóspede na cama; alpha, recortes, largura, estabilidade da
pose e retorno à caminhada conferidos. Em zoom 0,35/0,90/1,80, recortes contidos no
quarto e posicionados acima do piso. Capturas inspecionadas com peseira N3 visível.
Snapshots antes/depois de desenho e seleção iguais. `ui_culling` incluiu os três
níveis de cama nas nove comparações pixel a pixel; `ui_content` passou. Cinco
scripts validados pelo `gda` sem diagnósticos.

Catálogo: 43 PNGs, 25 texturas de personagens. O diagnóstico do executável verifica
12 sprites de uso: nove faixas de quatro poses e três recortes estáticos de dormir.
