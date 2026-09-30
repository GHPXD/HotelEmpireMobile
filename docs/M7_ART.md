# M7 — arte raster, animação e áudio

Hotel jardim acolhedor: carvalho, painéis jade, latão e reboco creme; tecidos azuis,
terracota e violeta distinguem serviços. Interiores frontais com pista para circulação.
Arte original gerada pelo image_gen integrado; prompts e referências em `docs/art/`.

## Entrega
- Cinco interiores: recepção, quarto, bistrô, café e sala de lazer.
- Elevador dividido em poço repetido por andar e cabine móvel.
- Corredor modular, cidade ao fundo e passeio/jardim no primeiro plano.
- Cinco personagens: hóspedes equilibrado, negócios e lazer, recepcionista e limpeza.
  Cada um tem PNG transparente com quatro poses de caminhada.
- Duas faixas adicionais de trabalho: limpeza com esfregão e atendimento com
  prancheta, quatro poses cada. Originais RGBA preservados, gerados no chat pelo
  image_gen integrado; prompts em `art/staff-actions-prompts.json` e recortes em
  `assets/art/characters/action-regions.json`.
- Duas faixas de repouso para a equipe, com quatro poses por função e gestos
  discretos sem ferramentas, usadas em `idle` e `lift_queue`. Âncoras nos sapatos,
  escala comum e ciclo de 64 ticks. Prompts e medições em `art/staff-idle*.json`.
- Hóspedes têm espera própria, ciclos de beber, ler sentado e comer nos serviços,
  além de ciclos sutis de repouso sobre as camas dos três níveis. As três folhas
  de dormir usam grade 2×2, quatro poses e ciclo de 48 ticks; originais estáticos
  preservados como referências. Detalhes em `art/bedroom-sleeping-loop.md`.
- Seis ícones raster próprios para o catálogo, com silhuetas de objetos legíveis
  em 36px, mipmaps e estados nativos de Button. Detalhes em `art/build-icons.md`.
- Dois ícones raster para contratação e gestão da equipe, em 36/48px,
  com função da seleção atual e entrada nativa. Detalhes em `art/staff-icons.md`.
- Três ícones raster para adicionar andar, melhorar sala e demolir seleção,
  com fonte intacta, import de 256px e Button.icon de 32px. Detalhes em `art/action-icons.md`.
- Três ícones raster para Finanças, Operação e Avaliações no HUD, em 28px,
  com mínimo nativo, input/foco preservados. Detalhes em `art/management-icons.md`.
- Três ícones raster para Novo hotel, Salvar e Carregar, com import de 256px,
  confirmação nativa e continuidade pelo disco. Detalhes em `art/session-icons.md`.
- Três ícones raster para Equipe, Objetivos e Ajuda, compartilhando o catálogo
  dos painéis e preservando contador/F1/foco. Detalhes em `art/utility-icons.md`.
- Duas variantes raster para som ligado/silenciado e um ícone para texto,
  sincronizados com estado e preferências. Detalhes em `art/preferences-icons.md`.
- Cinco retratos transparentes de perfil/função para inspeção de hóspedes e equipe,
  separados das faixas de animação. Cartão de 96px na lateral, com texto nativo
  e rolagem automática ao selecionar. Detalhes em `art/character-portraits.md`.
- Três faixas com bagagem para chegada e saída: quatro poses por perfil,
  contexto de trânsito e âncoras espelhadas nos sapatos. Detalhes em `art/guest-travel.md`.
- Quartos aguardando limpeza têm pinturas próprias N1/N2/N3, com cama desfeita
  e toalhas usadas. O estado persistido seleciona a pintura; concluir a limpeza
  restaura a versão limpa. Detalhes em `art/bedroom-housekeeping.md`.
- Filas registradas usam posições pela ordem das reservas e um contador por grupo;
  elevadores separam os grupos por andar. Detalhes em `art/queue-presentation.md`.
- Três efeitos WAV sintetizados por `tools/generate_audio.py`: construção, melhoria
  e objetivo. Botão Som com preferência em `user://audio.cfg`.

## Contrato de apresentação
Grade: célula 62 px, andar 108 px, zoom 0,35–1,8. Interiores ajustados ao retângulo da
sala. PNGs fonte preservados; mipmaps e filtro linear melhoram redução. Textos, foco,
seleção, preview e avisos são nativos para manter informação dinâmica legível.

As faixas geradas não obedeceram perfeitamente à divisão em células iguais.
Recortes medidos pela extensão do alpha >100, com margem de 3 px, sem alterar PNGs.
Coordenadas em `characters/regions.json` e HotelArt.REGIONS. Escala comum por
personagem (altura máxima 46 px) e âncora central inferior mantêm os pés no chão.
Nunca presumir que uma faixa nova usa os mesmos recortes.

Caminhada: quatro frames a 10 quadros/s na velocidade normal, derivados do tick,
com fase por ID. Espelhamento segue destino horizontal. Parado usa pose 1; pausa
congela animação. Cabine acompanha posição autoritativa. Não há RNG, nós por ator
ou estado visual no save. Não há mudanças de economia ou gameplay.
Os estados `cleaning` e `working` selecionam as faixas próprias dos funcionários,
com troca de pose a cada quatro ticks (2,5 fps). Funcionários em repouso ou fila do
elevador trocam pose a cada 16 ticks; caminhada mantém a faixa original.
O atendimento representa trabalho administrativo durante a atribuição,
mesmo sem um hóspede presente. A geração tem pequenas variações entre poses;
não equivale a uma animação produzida com rig esquelético.

## Limites
Repouso nas camas tem quatro poses pintadas de respiração sutil, sem rig esquelético. Leitura e refeições
têm ciclos sentados e posições separadas por usuário. Quartos, recepções e restaurante têm pinturas próprias para níveis 2 e 3;
cabines N2 usam pintura de nogueira e N3 tem mármore e medalhão de latão; o poço
mantém a pintura base. Sem música ou ambiente
contínuo nesta entrega. Novos conteúdos precisam de arte própria. M8 mediu render
isolado até 1000 e operação contínua até 120; esta entrega não comprova 1000 hóspedes
atendidos simultaneamente a 60 FPS. Catálogo atual: 82 PNGs, 30 texturas de personagens
(27 folhas animadas e três poses estáticas de referência do café), cinco retratos
e 23 ícones de interface. Referências de dormir anteriores ficam fora do preload.

## Verificação
`ui_art.gd`: carregamento, alpha, limites dos recortes, ciclo, zoom mínimo/normal/máximo,
ausência de mutação da partida e persistência de Som. Capturas:
`.runtime/m7-art-0.35.png`, `m7-art-0.90.png`, `m7-art-1.80.png`.
Demais suítes cobrem construção, seleção, bloqueios, filas, save/load, foco,
texto ampliado e retomada com novo render.

Extensão de funcionários (21/09/2026): catálogo válido pelo gda; `ui_art` e
`ui_culling` passaram sem falhas, incluindo nove combinações de câmera com as
ações novas. Verificados alpha, limites, ciclo, retorno à faixa original e ausência
de mutação do snapshot. Captura inspecionada: `art/hotel-staff-actions.png`.

Extensão de ambientes (22/09/2026): `bedroom-level-2.png` e
`reception-level-2.png` gerados pelo image_gen integrado no chat. Prompts em
`art/room-upgrades-prompts.json`; dimensões e SHA-256 em `art/manifest.json`.
HotelView escolhe a textura a partir do nível persistido da sala. A compra e os
efeitos econômicos continuam na lógica existente. O catálogo de construção mantém
a imagem do nível 1. A vitrine `ui_art` compra melhorias reais para mostrar quartos
base e melhorados juntos, além da recepção melhorada, nos três níveis de zoom.
Validação: `tools/test.ps1 -Visual` passou nas 22 suítes do worktree em 22/09/2026.
Após ativar mipmaps nos dois imports, `ui_art` passou novamente; captura de zoom
0,90 inspecionada. Incluída no ZIP Windows da revisão `ce2ff22`; seis casos do
pacote extraído aprovados em `release/upgrade-diagnostics-matrix.json`.

Extensão do restaurante (22/09/2026): pinturas distintas para níveis 2 e 3,
com mesas e iluminação progressivamente refinadas. Prompts em
`art/restaurant-upgrades-prompts.json`, PNGs preservados e hashes no manifesto.
O catálogo mantém a pintura base; a sala usa seu nível persistido para escolher
a textura. Café e lounge não têm upgrades definidos atualmente. A vitrine compra
os dois níveis de restaurante no andar superior e mantém o nível 1 no térreo.
Importação com mipmaps e `ui_art` validados; três zooms, compras reais e snapshot
inalterado. Incluída no ZIP da revisão `80d51de`, com compra, save/load e seleção
da pintura verificados no executável nas seis combinações de janela/texto.

Extensão N3 de quarto/recepção (22/09/2026): cama com dossel e balcão de mármore
distinguem os níveis máximos. PNGs gerados pelo image_gen integrado, preservados
com mipmaps; prompts em `art/final-room-upgrades-prompts.json`. A vitrine compra
os upgrades reais e coloca quartos N1/N2/N3 lado a lado. Essas duas pinturas estão
no pacote Windows da revisão `c3f2b6a`.
`ui_art` passou sem falhas com compras e capturas nos três zooms; captura 0,90
inspecionada. O snapshot da simulação permanece inalterado durante a renderização.

Cabine N2 (22/09/2026): pintura de nogueira selecionada pelo nível da sala do
elevador em movimento, preservando retângulo e posição da cabine. `ui_art` passou
com compra real do upgrade; `ui_culling` passou nas nove câmeras. Captura 0,90
inspecionada. PNG e prompt em `art/cabin-upgrades-prompts.json`; sem mudanças de
transporte ou save. A geração N3 inicialmente encontrou o limite de uso; a nova
tentativa produziu a pintura própria descrita abaixo. A cabine N2 está no ZIP da revisão
`c3f2b6a`: compra, save/load e seleção da pintura passaram nas seis combinações
de janela/texto, com evidência em `release/final-rooms-cabin-matrix.json`.

Cabine N3 (23/09/2026): pintura própria de mármore claro, painéis verdes e medalhão
de latão gerada pelo image_gen integrado. Prompt preservado em
`art/cabin-upgrades-prompts.json`; dimensões/hash no manifesto. `ui_art` passou
com compra real de N2/N3, capturas nos três zooms e snapshot inalterado; captura
0,90 inspecionada. O teste do executável também compra N3 e confere nível/textura
depois de Carregar. Não muda geometria, regras de transporte ou schema de save.
Incluída no pacote da revisão `f8eb7b2`, aprovado nos seis casos de janela/texto;
relatório em `release/cabin3-matrix.json`.

Espera dos hóspedes (24/09/2026): três sequências dedicadas, com quatro poses
por perfil, geradas diretamente no chat. Integradas às filas de check-in,
serviços e elevador. PNGs RGBA preservados, mipmaps, prompts e hashes registrados.
Detalhes e validação em art/guest-waiting.md. ui_art: zero falhas. Ainda não
incluídas no ZIP Windows anterior.

Lote de espera incluído no ZIP Windows 9237939, validado nas seis combinações
de janela/texto em release/tariffs-waiting-matrix.json.
