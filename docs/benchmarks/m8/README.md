# M8a — visibilidade e primeiro perfil (20/09/2026)

Registro inicial M8a. Medições locais em Ryzen 7 5700U/Radeon integrada,
Godot 4.7.2 Compatibility, Windows. Resultados brutos preservados em baseline.json
e culled.json. Sem comparação com outro hardware nem promessa de 60 FPS integrado.

Continuação: [admissão, saídas e perfil integrado inicial](ADMISSION.md).
Perfil atual após a revisão de apresentação: [30/09/2026](QUEUE_PRESENTATION.md).

## Método
`debug/performance_profile.gd` abre HotelView real com todos os PNGs M7, torre de
20 andares e 10 funcionários. Acrescenta 100/250/500/1000 hóspedes posicionados
artificialmente, distribuídos por andar ou todos no térreo. O render usa 30 frames
de aquecimento e 120 amostras; VSync desligado, sem limite de FPS. Mede tempo de
parede entre frames, draw calls globais e memória reportada pelo engine.

É um teste isolado de render: não executa IA, nem o HUD durante essas amostras.
Todos visíveis é um caso de sobreposição extrema, não ocupação normal de um hotel.
Valores de vídeo são os monitores do Godot, não a memória total do driver/processo.

| Hóspedes distribuídos | Média antes/depois (ms) | P95 antes/depois (ms) | Draw calls antes/depois |
|---|---|---|---|
| 100 | 5,01 / 4,54 | 5,47 / 5,74 | 499 / 206 |
| 250 | 6,08 / 5,07 | 6,34 / 6,05 | 591 / 246 |
| 500 | 8,21 / 5,69 | 8,66 / 6,06 | 746 / 305 |
| 1000 | 12,02 / 8,42 | 12,58 / 8,98 | 1090 / 443 |

Com 1000 todos visíveis: média 11,86 → 12,10 ms; P95 12,12 → 13,14 ms.
A verificação de visibilidade tem custo e não ajuda personagens que estão todos
na tela. Não afirmar melhora universal: o ganho é no hotel com conteúdo fora da câmera.
Vídeo permaneceu em 121.947.375 bytes: descarte de desenho não descarrega texturas.

## Simulação e limitação descoberta
Baseline também mede 600 ticks de uma torre, descartando os primeiros 100 das
estatísticas. Antes de cada tick repõe hóspedes até o alvo, sem cobrar esse preparo
no tempo medido. Valida invariantes a cada 50 ticks, também fora do intervalo.

O nome inicial `sustained_refill_60_sim_seconds` no JSON NÃO significa população
hospedada sustentada. A recepção rejeita o excesso, e o final tem 53 hóspedes em
todos os tamanhos. Trata-se de sobrecarga de chegadas/reposição, com até 192.511
saídas; não comprova 1000 hóspedes utilizando serviços simultaneamente.
O script foi corrigido para chamar esse modo `arrival_overload_refill_60_sim_seconds`
e contar vagas uma única vez por tick, eliminando custo quadrático do próprio preparo.

P95 dos ticks no baseline: 6,73 / 19,27 / 40,63 / 83,35 ms para os quatro alvos.
Isso identifica picos acima do orçamento de um frame. Próximas ações: perfil por
sistema, otimização da admissão e validação de carga integrada com população e
estados efetivamente ocupados registrados. O M8 permanece aberto.

## Correção visual
HotelView ignora andares/células, salas, módulos de elevador, cabines, personagens
e badges fora do viewport. Margens preservam antialiasing, rótulos e avisos.
Sem descarte de agentes da simulação, mudanças de ordem visível ou escrita no save.
`ui_culling.gd` compara bytes das capturas com otimização ligada/desligada em nove
combinações de zoom/pan, incluindo espera, sujeira e personagens espelhados.

## Reproduzir
Importar o projeto antes. Executar Godot com dados locais isolados em `.runtime`:

```powershell
godot --path . --script res://debug/performance_profile.gd -- --label=profile
godot --path . --script res://debug/performance_profile.gd -- --label=render --render-only
godot --path . --script res://tests/ui_culling.gd
```

Não rodar benchmarks em paralelo com testes. Relatórios em `.runtime/m8-<label>.json`.
Para referência sem descarte, HotelView.cull_offscreen pode ser desligado pelo harness.

Conclusão do marco para a capacidade atual: [operação contínua com HUD](OPERATING.md).
