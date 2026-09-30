# Quartos aguardando limpeza

Três pinturas raster originais geradas no chat pelo image_gen integrado, uma para
cada nível de quarto. Lençóis e colchas desfeitos, travesseiros fora do lugar,
toalhas usadas no tapete e uma xícara distinguem o estado após checkout.
Os materiais, câmera frontal, cores, móveis e faixa de circulação seguem as
pinturas limpas. Há pequenas variações de pintura; não é uma edição determinística
dos pixels da referência. A peseira e o dossel N3 permanecem visíveis.

Arquivos `assets/art/rooms/bedroom-dirty.png`, `bedroom-level-2-dirty.png` e
`bedroom-level-3-dirty.png`: RGB, 1254×1254, originais copiados sem alteração de
pixels. Imports com mipmaps e filtro linear. Prompts/referências em
`bedroom-housekeeping-prompts.json`; dimensões e hashes em
`bedroom-housekeeping-measurements.json` e `manifest.json`.

`HotelArt.room_state` lê o nível e `RoomState.dirty`, já persistidos no schema v7.
A sala conserva sua pintura de espera durante a limpeza e volta à pintura limpa
quando `EmployeeSystem` conclui o serviço. O catálogo de construção mostra a
instalação limpa. O aviso nativo LIMPAR continua disponível para leitura do estado.
Não altera duração, custo, satisfação, reservas, transporte ou schema de save.

Validação automatizada em `ui_art`: compras reais de N2/N3, seleção da pintura,
dimensões, ausência de mutação durante desenho, três zooms, save/load e conclusão
real da limpeza nos três níveis. Capturas de comparação limpa/suja em
`.runtime/m7-housekeeping-{0.35,0.9,1.8}.png` e após limpeza em
`.runtime/m7-housekeeping-cleaned.png`. O diagnóstico exportado verifica as três
pinturas e retorno à versão limpa.
