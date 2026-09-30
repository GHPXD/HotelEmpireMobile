# Assets

M7 usa 76 PNGs originais produzidos pelo **image_gen integrado ao chat**, com
novas faixas de serviço documentadas em `docs/art/`. Sem CLI/API alternativa,
SVG ou imagens copiadas de jogos de referência.
Não são assets feitos manualmente por um ilustrador. Prompts completos e referências
em `docs/art/*.txt` e `docs/art/*.json`; dimensões/hashes em
`docs/art/manifest.json`. Não atribuir licença de terceiros inexistente.

| Pasta | Conteúdo |
|---|---|
| `assets/art/rooms/` | Recepção, quarto e bistrô nos níveis 1/2/3; três variantes de quarto aguardando limpeza; café e lounge |
| `assets/art/environment/` | Poço, cabine nos níveis 1/2/3, corredor, cidade e passeio |
| `assets/art/characters/` | Cinco faixas de caminhada, três de viagem com bagagem, três de espera de hóspedes, duas de repouso da equipe, duas de trabalho, 12 folhas de serviço, três poses de dormir e três poses de café preservadas como referências |
| `assets/art/portraits/` | Cinco bustos RGBA dedicados ao inspetor: três perfis de hóspedes e duas funções da equipe |
| `assets/art/icons/` | Seis ícones RGBA de construção, dois da equipe, três de comandos (andar, melhoria e demolição) e três de gestão (finanças, operação e avaliações) |
| `assets/audio/` | Três WAVs originais sintetizados localmente |

O projeto consome cópias locais versionadas; não depende de `.codex/generated_images`.
PNGs fonte preservados. Recorte, escala e espelhamento acontecem no Godot;
transparência preservada. Texturas compartilhadas, mipmaps e filtragem linear.
Imports de UI limitam ícones a 256px e retratos a 512px; as fontes de 1254px
continuam intactas. Perfil e capturas em `docs/benchmarks/m8/UI_TEXTURES.md`.
`assets/art/art_catalog.gd` centraliza o mapeamento visual por ID.

Café, leitura no lounge e refeição no restaurante têm quatro poses próprias para
cada perfil, cadência por serviço e âncoras medidas nos pés/móveis. Assentos usam
usuários admitidos, com o mesmo ponto para desenho e clique. Fluxos e validação em
`docs/art/cafe-animation.md`, `lounge-reading.md` e `restaurant-dining.md`.
Quartos usam quatro poses sutis de repouso sobre as camas, sem alterar os PNGs dos
ambientes; peseira N3 e circulação ficam à frente. Detalhes em
`docs/art/bedroom-sleeping-loop.md`. As poses estáticas anteriores são referências
preservadas; os mesmos IDs do catálogo agora carregam as folhas animadas.
Quartos aguardando limpeza têm pinturas próprias por nível, selecionadas pelo
estado persistido e restauradas após o serviço da equipe. Detalhes em
`docs/art/bedroom-housekeeping.md`.
Funcionários em repouso ou fila do elevador usam ciclos discretos de quatro poses,
sem ferramentas de trabalho. Âncoras medidas nos sapatos e escala comum preservam
o apoio no piso. Detalhes em `docs/art/staff-idle.md`.
Indicadores de espera respeitam os limites dos sprites, e cliques aceitam cabeça
e corpo. Critérios de sobreposição e validação em `docs/art/queue-presentation.md`.
O inspetor mostra retratos próprios de perfil/função em 96px, com seleção e rolagem
automáticas. Proveniência e limites em `docs/art/character-portraits.md`.

Chegada e saída têm faixas próprias com malas por perfil; quatro poses e apoio
dos pés preservado nos dois sentidos. Detalhes em `docs/art/guest-travel.md`.

O catálogo de construção usa seis ícones próprios em 36px com mipmaps e mantém
nome/preço em texto nativo. Proveniência e limites em `docs/art/build-icons.md`.
Contratação e gestão da equipe têm ícones próprios para as duas funções;
detalhes em `docs/art/staff-icons.md`.
Andar, melhoria e demolição usam três fontes raster próprias nos botões nativos
de 32px, com import limitado a 256px; detalhes em `docs/art/action-icons.md`.
Finanças, Operação e Avaliações têm ícones raster de 28px na barra do HUD;
fontes intactas e imports de 256px. Detalhes em `docs/art/management-icons.md`.
Novo hotel, Salvar e Carregar têm fontes raster próprias, em botões de 28px;
confirmação e continuidade preservadas. Detalhes em `docs/art/session-icons.md`.

Sons gerados pelo código original `tools/generate_audio.py`, sem samples externos:
PCM mono 16 bits/22050 Hz, envelope de ataque/decay e volume moderado na reprodução.

Ver `docs/M7_ART.md` para direção, dimensões, animação, limites e validação.
Manter IDs estáveis, verificar recortes e conferir novas artes no zoom de jogo.
Registrar origem/condições de uso; não extrair material de Theme Hotel.
