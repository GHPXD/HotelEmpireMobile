# M8 — orçamento das texturas de interface, 30/09/2026

Treze texturas UI (cinco retratos, seis ícones de construção e dois da equipe)
tinham fontes RGBA 1254×1254 importadas integralmente. A interface mostra ícones
a 36/48px e retratos a 96px lógicos. Agora os imports limitam ícones a 256px e
retratos a 512px, mantendo mipmaps e os PNGs fonte intactos.

Dois processos novos de Godot 4.7.2 Compatibility no mesmo Ryzen 7 5700U/Radeon,
com a mesma cena principal pausada, seed 841, pessoas, código UI e configurações.
Baseline com árvore limpa na revisão 43baeb6; somente 13 limites de importação
diferem na segunda execução. Código comparado ao Git da baseline, normalizando
somente CRLF/LF; hashes brutos de ambos, imports antes/depois e comandos em
`ui-textures-provenance.json`.
Relatórios em `ui-textures-full.json` e `ui-textures-budget.json`.

| Escopo | Antes (MiB) | Depois (MiB) | Redução (MiB) |
|---|---:|---:|---:|
| Cadeias RGBA8+mips das 13 texturas, calculadas | 103,94 | 9,33 | 94,61 |
| Monitor de vídeo Godot, janela 1280×800, texto padrão | 486,48 | 391,87 | 94,61 |
| Monitor de vídeo Godot, janela 3840×2160, texto padrão | 537,87 | 443,26 | 94,61 |

A redução calculada foi 91,02% do orçamento dessas texturas. O monitor reportou
a mesma diferença de 99.206.244 bytes em todos os quatro pares de janela/texto.
Ele inclui ambientes, personagens, buffers e fontes; não é toda a memória do
driver ou do sistema. Não foram medidos FPS ou aumento de capacidade do hotel.

Cinco identidades de retrato em duas janelas × texto normal/ampliado: 20 casos
com cartão dentro da rolagem e snapshot preservado. Janelas solicitadas e reais
foram 1280×800 e 3840×2160. Na janela 4K, a captura da área renderizada é
3456×2160 por manter a proporção do canvas lógico 1440×900; margens externas
da janela não fazem parte desse PNG. Capturas em `docs/art/hotel-ui-budget*.png`
inspecionadas: retratos e ícones permanecem legíveis. Não prometemos qualidade
em escalas maiores, nem certificamos hardware mínimo ou monitor físico 4K.

Os 67 PNGs fonte mantêm os hashes do manifesto. Não reduzimos personagens,
ambientes ou animações. Repetir este perfil ao mudar os tamanhos da interface,
DPI alvo ou conteúdo; aumentar limites somente quando a escala exigir.
