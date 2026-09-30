# Som e tamanho do texto — 30/09/2026

Três PNGs RGBA 1254×1254 gerados pelo `image_gen` integrado ao chat: cone de
marfim/latão com ondas para som ligado, variante com X rosa para silenciado,
e letras Aa com base jade para tamanho do texto. Fontes selecionadas em
`assets/art/icons/sound-on-v2.png`, `sound-off-v2.png` e `text-size.png`.
Prompts completos, incluindo tentativas e edições, em `preferences-icons-prompts.json`.
Origem, hashes, dimensões, cantos transparentes e bounds opacos (>100/255)
em `preferences-icons-measurements.json`. Fontes finais copiadas byte a byte,
sem edição local de pixels. Catálogo atual: 82 PNGs, 30 texturas de animação,
cinco retratos e 23 ícones.

A primeira dupla de som incluía caixa, cone e ondas; o ícone ligado ficou denso
em 1024×640. Quatro checagens de pixels brilhantes falharam, embora alternância,
persistência e preferências funcionassem. Foi gerada outra dupla, com cone
maior e claro. O critério de dez pixels acima de 0,65 foi mantido. Erro inicial
e resumos em `preferences-icons-initial-failure.json`; nenhum caso removido.
As primeiras fontes descartadas permanecem na origem do gerador, sem fazer
parte do catálogo/export. Variantes finais mantêm a escala geral do cone;
a edição não é uma cópia pixel a pixel de todas as superfícies.

Margens laterais são menores que as solicitadas, mas silhuetas opacas não
tocam as bordas e cantos são transparentes. As duas variantes foram
inspecionadas no HUD de 28px. Ligado/desligado se distinguem por ondas/X,
além do rótulo nativo; Aa acompanha Texto +/− e o atalho F4.

`HotelArt.PREFERENCE_ICONS` compartilha os três imports de 256px com mipmaps.
`HotelHUD.set_audio_enabled` atualiza texto e imagem a partir de HotelAudio
no boot e após cada alternância. O helper de ícones de 28px é compartilhado
com os controles de painéis e partida; reserva largura no HFlowContainer.
Preferências continuam em `audio.cfg` e `interface.cfg`, separadas do save v7.
Sem novo estado da simulação, preços, sementes ou regras.

`tests/ui_preferences_icons.gd`: quatro janelas solicitadas (1024×640,
1280×800, 1600×900 e 3840×2160), dois textos, mouse/Enter: 64 ativações de
som/texto, mais 16 atalhos F4. Verifica as variantes, rótulos, tema de 16/20,
arquivos de preferências, foco, snapshot inteiro preservado, bounds e
ausência de sobreposição. Inicia um stream real na fixture antes de silenciar
e confirma que o player parou; volume da fixture fica em −80 dB, sem afirmar
qualidade audível ou certificação de equipamento de áudio.

Quatro cenas principais novas leem todas as combinações de som/texto dos
arquivos reais; trocar o hotel preserva as preferências. 64 áreas de ícone
contêm pixels pintados, com escala da captura aplicada ao recorte. O limiar
depende da paleta atual. Dados em `preferences-icons-ui.json`. Esses ícones
não adicionaram linha nos oito layouts medidos: playfield lógico 634 padrão
e 624 ampliado, igual ao estado sem as duas imagens de preferências.

Capturas inspecionadas: `hotel-preferences-on-small.png`,
`hotel-preferences-off-small.png` e `hotel-preferences-on-4k.png`
(canvas ativo 3456×2160 da janela solicitada 4K, sem margens externas).
Janela solicitada 4K não certifica monitor físico. Imports limitados não são
uma nova medição da memória total do jogo; perfil M8 anterior conserva seu escopo.

Cinco scripts válidos pelo gda. Onze suítes gráficas passaram:
ui_preferences_icons, ui_management_icons, ui_session_icons, ui_management,
ui_progression, ui_help, ui_smoke, ui_resume, ui_new_game, ui_recovery e ui_exit.
Runner agora configura 34 suítes Visual/Stress/Soak; a última bateria completa
de 31 suítes do M9 é anterior aos ícones posteriores e não foi repetida aqui.
