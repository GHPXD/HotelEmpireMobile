# Ícones dedicados ao catálogo de construção

Seis PNGs RGBA 1254×1254, gerados diretamente no chat pelo image_gen integrado.
Os botões passam a usar objetos com silhuetas próprias, em vez de reduzir as
pinturas completas das salas. Os originais foram copiados sem editar pixels.

| ID | Motivo |
|---|---|
| reception | Sino de latão sobre base jade e carvalho |
| bedroom | Cama com cabeceira jade, almofadas creme e colcha azul |
| restaurant | Prato de refeição e talheres |
| cafe | Xícara e pires creme/jade |
| lounge | Poltrona violeta e livro aberto |
| elevator | Portas jade com moldura de carvalho/latão |

Fontes em `assets/art/icons/`; prompts finais em `build-icons-prompts.json`,
origem, dimensões, hashes e medidas de alpha em `build-icons-measurements.json`.
Não há corte opaco nas bordas; alguns originais têm alpha muito fraco nas margens
(até 6/255), preservado. O jogo usa arquivos locais versionados.

`HotelArt.BUILD_ICONS` mantém IDs iguais aos recursos de construção.
Os seis botões nativos usam `expand_icon`, largura máxima 36px e filtro linear
com mipmaps. Texturas compartilhadas e mipmaps na importação; PNGs fonte não
reduzidos. Os ícones identificam o tipo da instalação, sem representar nível ou
disponibilidade. Bloqueio, foco e hover continuam a cargo do Button/Theme.
Nome, preço, células e tooltip permanecem texto nativo.

`tests/ui_content.gd` verifica seis instalações × três tamanhos de janela ×
texto normal/ampliado: fonte distinta da pintura, alpha, limite de tamanho,
botão dentro da rolagem e viewport, mínimos do layout, clique e Enter escolhem
a construção correta, snapshot preservado. Café/lounge bloqueados ainda têm
ícone e não entram em construção. O smoke do executável confere os seis ícones,
alpha, layout e ativação por clique em cada configuração da matriz exportada.
