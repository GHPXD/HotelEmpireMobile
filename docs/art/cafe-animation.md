# Ciclos de beber no Café Brisa

Três faixas profissionais em PNG RGBA de 1774 × 887, geradas diretamente pelo
`image_gen` do chat a partir das poses `*-cafe.png`. Cada faixa contém quatro
poses completas: xícara baixa, levantar, beber e baixar. Preservam figurino,
paleta, bolsa e direção dos três perfis. Os arquivos originais permanecem intactos.

Assets: `assets/art/characters/balanced-drinking.png`, `business-drinking.png`
e `leisure-drinking.png`. Prompts integrais em `cafe-animation-prompts.json`;
dimensões, tamanho e SHA-256 em `manifest.json`.

A normalização ocorre por regiões e âncoras no Godot, sem reamostrar ou editar
pixels dos PNGs. Regiões medidas no alfa com margem de quatro pixels; cada faixa
usa uma altura e escala compartilhadas, com altura visual de 46 pixels em zoom 1.
O centro dos pés de cada pose fica no mesmo ponto do hotel, independentemente da
largura do braço e da xícara. Medições em `cafe-animation-measurements.json`.
Mipmaps e correção de borda alfa são habilitados na importação.

Cada pose dura oito ticks de 0,1 segundo; ciclo de 3,2 segundos em velocidade 1x.
O ID do hóspede desloca a fase, evitando gestos sincronizados. A animação segue
os ticks da simulação, congela na pausa e não usa RNG nem altera estados.
Somente `using` no café seleciona essas faixas. Outros serviços, caminhada,
espera e ações dos funcionários preservam seus sprites anteriores.

Validação: `ui_art`, `ui_culling` e `ui_content`, zero falhas. O teste de arte
verifica transparência, recortes, quatro poses, avanço, loop, âncoras internas e
baseline comum. Captura o hotel em zoom 0,35/0,90/1,80 e cada fase do café em 1,80,
comparando snapshots antes/depois de desenhar uma sessão pausada. As capturas
foram inspecionadas. O teste de câmera manteve equivalência pixel a pixel em nove
posições/escalas. Catálogo atual: 34 PNGs e 16 texturas de personagens.

As faixas estão no ZIP Windows exportado da revisão `c63bb6e`, com árvore limpa.
Smoke e seis combinações locais de janela/texto aprovados; auditoria dos 34 PNGs
concluída. Evidência em `docs/release/cafe-animation-matrix.json`.
