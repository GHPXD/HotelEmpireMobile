# Retratos de inspeção

Cinco retratos raster originais gerados diretamente no chat pelo image_gen:
hóspedes equilibrado, de negócios e de lazer; recepcionista e camareira.
Referências de identidade são as faixas de caminhada existentes. Os bustos mantêm
cores, roupa, cabelo e acessórios e usam enquadramento comum para leitura a 96px.
São imagens fixas de perfil ou função; não representam a felicidade atual nem
um rosto individual diferente para cada visitante.

PNGs RGBA 1254×1254 em `assets/art/portraits/`, copiados sem alterar pixels.
Alpha real e cantos transparentes conferidos. Há pequenas variações de pintura
entre referências e retratos. Prompts em `character-portraits-prompts.json`;
dimensões, extensão do alpha e hashes em `character-portraits-measurements.json`
e no manifesto geral. Imports com mipmaps; nenhuma dependência do diretório
de geração fora do projeto.

`HotelArt.PORTRAITS` é separado das 27 texturas de animação. A escolha lê somente
perfil ou função. O HUD usa TextureRect de 96×96 com proporção preservada, em
um cartão dentro da rolagem lateral. O texto identifica perfil/função e os dados
da pessoa continuam no inspetor nativo. Os elementos decorativos não recebem
foco nem bloqueiam entrada. Clicar no personagem revela seu cartão; selecionar
sala, trocar/carregar partida ou remover a pessoa limpa a imagem anterior.

`ui_content` cobre as cinco identidades em três janelas (1024×640, 1280×800,
1600×900) e texto normal/ampliado: cliques reais, rolagem, limites, identidade,
estado/satisfação independentes, snapshot, save/load e limpeza de seleção.
O diagnóstico do executável verifica as cinco imagens, alpha e seleção pela
interface em cada combinação de janela/texto. Nenhuma mudança em gameplay,
economia, dados de atores, RNG ou schema v7.
