# Assets

M7 usa 45 PNGs originais produzidos pelo **image_gen integrado ao chat**, com
novas faixas de serviço documentadas em `docs/art/`. Sem CLI/API alternativa,
SVG ou imagens copiadas de jogos de referência.
Não são assets feitos manualmente por um ilustrador. Prompts completos e referências
em `docs/art/*.txt` e `docs/art/*.json`; dimensões/hashes em
`docs/art/manifest.json`. Não atribuir licença de terceiros inexistente.

| Pasta | Conteúdo |
|---|---|
| `assets/art/rooms/` | Recepção, quarto e bistrô nos níveis 1/2/3; café e lounge |
| `assets/art/environment/` | Poço, cabine nos níveis 1/2/3, corredor, cidade e passeio |
| `assets/art/characters/` | Cinco faixas de caminhada, três de espera de hóspedes, duas de repouso da equipe, duas de trabalho, nove de serviço, três poses de dormir e três poses de café preservadas como referências |
| `assets/audio/` | Três WAVs originais sintetizados localmente |

O projeto consome cópias locais versionadas; não depende de `.codex/generated_images`.
PNGs fonte preservados. Recorte, escala e espelhamento acontecem no Godot;
transparência preservada. Texturas compartilhadas, mipmaps e filtragem linear.
`assets/art/art_catalog.gd` centraliza o mapeamento visual por ID.

Café, leitura no lounge e refeição no restaurante têm quatro poses próprias para
cada perfil, cadência por serviço e âncoras medidas nos pés/móveis. Assentos usam
usuários admitidos, com o mesmo ponto para desenho e clique. Fluxos e validação em
`docs/art/cafe-animation.md`, `lounge-reading.md` e `restaurant-dining.md`.
Quartos usam recortes estáticos de dormir sobre as camas, sem alterar os PNGs dos
ambientes; peseira N3 e circulação ficam à frente. Detalhes em `bedroom-sleeping.md`.
Funcionários em repouso ou fila do elevador usam ciclos discretos de quatro poses,
sem ferramentas de trabalho. Âncoras medidas nos sapatos e escala comum preservam
o apoio no piso. Detalhes em `docs/art/staff-idle.md`.

Sons gerados pelo código original `tools/generate_audio.py`, sem samples externos:
PCM mono 16 bits/22050 Hz, envelope de ataque/decay e volume moderado na reprodução.

Ver `docs/M7_ART.md` para direção, dimensões, animação, limites e validação.
Manter IDs estáveis, verificar recortes e conferir novas artes no zoom de jogo.
Registrar origem/condições de uso; não extrair material de Theme Hotel.
