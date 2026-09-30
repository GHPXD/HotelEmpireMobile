# Hóspedes com bagagem — chegada e saída

Três faixas RGBA originais geradas diretamente no chat pelo image_gen integrado,
com quatro poses por perfil. Identidades e roupas vêm das faixas de caminhada
existentes. Mala vinho para equilibrado, azul escuro para negócios e caramelo
para lazer; todos usam alça telescópica e rodas.

Arquivos em `assets/art/characters/{balanced,business,leisure}-travel.png`.
Prompts finais em `guest-travel-prompts.json`; hashes, dimensões, origem e recortes
em `guest-travel-measurements.json`. Os PNGs de 1774×887 são cópias byte a byte
dos originais em `.codex/generated_images/01a0a915-2716-7f90-a3cc-87023fafadff`.
A primeira tentativa do equilibrado foi rejeitada por sobreposição entre poses.

`HotelArt.travelling_with_luggage` deriva a apresentação do estado já persistido:
`arriving`/`exit`, ou trânsito para `exit`, ou trânsito para `checkin` antes da
admissão. Inclui caminhada, fila de elevador e cabine. Caminhada usa quatro poses
a 10 fps na velocidade normal; estados estacionários usam pose 1. O atendimento
na recepção mantém sua faixa de espera; viagens internas aos serviços mantêm
a caminhada comum. Nenhum novo campo de save, estado autoritativo ou RNG.

As divisões geradas não são células iguais. Recortes virtuais medidos pelo alpha
>100 e margem de 3px; originais preservados, mipmaps e escala comum de 46px de
altura máxima por faixa. Âncora de contato dos sapatos exclui as rodas da mala.
Ao andar à esquerda, a âncora horizontal reflete em `largura - âncora.x` antes
de desenhar a região invertida. Desenho e seleção usam o mesmo retângulo positivo.

São poses pintadas com pequenas variações de proporção e contato entre quadros,
sem rig esquelético. Entrada e saída compartilham a faixa de viagem, espelhada
conforme o destino enquanto caminha. Não há animação de abrir porta ou desempacotar.

Verificação em `tests/ui_actor_presentation.gd`: três perfis × dois sentidos ×
quatro poses × três zooms; clique no corpo e na bagagem, apoio dos pés, limites
dos recortes e snapshot inalterado. Comparação de pixels com/sem culling em
18 casos de pose 0. Fluxos reais de chegada, recusa e fim da estadia, contextos
de transporte e restauração do destino por snapshot também conferidos.
O smoke do executável verifica as três faixas, cinco estados, geometria nos dois
sentidos/quatro poses/três zooms, alpha e seleção.
