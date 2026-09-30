# Render após a revisão de apresentação — 30/09/2026

Revisão 1043b78, árvore limpa no início do perfil. Godot 4.7.2 Compatibility,
Windows, Ryzen 7 5700U / Radeon integrada. Método existente de
`debug/performance_profile.gd --render-only`: 20 andares, dez funcionários,
100/250/500/1000 hóspedes em caminhada; 30 frames de aquecimento e 120 amostras
por caso, VSync desligado e sem limite de FPS. Dados em
`queue-presentation-render.json`; comando, hashes e escopo em
`queue-presentation-render-provenance.json`.

| Hóspedes | p95 distribuídos (ms) | p95 todos no térreo (ms) |
|---|---:|---:|
| 100 | 6,976 | 8,611 |
| 250 | 9,441 | 12,587 |
| 500 | 12,062 | 21,723 |
| 1000 | 21,126 | 39,749 |

Os oito casos terminaram sem erros de script ou recursos retidos. O monitor de
vídeo do Godot reportou aproximadamente 340,2 MiB; isso não é memória total do
driver. A cena carrega o catálogo atual de 45 PNGs, com texturas compartilhadas.

O perfil é de caminhada sintética, sem HUD ou IA, e não mede filas, indicadores
por hóspede nem tempo de resposta do clique. Todos no térreo representa
sobreposição extrema. Os resultados não são uma comparação controlada com as
medições antigas, nem certificam 60 FPS para 1000 hóspedes em operação. O limite
atual de operação permanece 120; compatibilidade externa continua pendente.
