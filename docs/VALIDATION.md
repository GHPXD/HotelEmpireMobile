# Evidências de validação

## M0 — 2026-09-16
- Godot 4.7.2 real; importação registrou classes globais.
- `gda script run res://tests/foundation_test.gd --strict`: exit 0, zero falhas,
  zero diagnósticos, nenhuma fuga de objetos detectada.
- `gda scene preflight res://core/game/main.tscn`: `started=true`, `status=ready`,
  diagnósticos vazios.
- Primeira validação antes da importação não resolveu class_name; resolvido pelo
  scan do editor (passo obrigatório em checkout limpo).
- Sandbox impediu probe de escrita do gda e configurações do editor; testes
  subsequentes executados com permissão de processo e user-data-root local.
- Boot gráfico e gameplay ainda pendentes: M0 contém apenas a cena de fundação.

## M1a — construção
- 15 checks de construção passaram: overlap, limites, suporte, recepção no térreo,
  poços em todos os andares, expansão, custos e bloqueio de demolição ocupada.
- Todos os 11 scripts então existentes compilaram; fundação passou novamente.
- Cena integrada: preflight ready, zero diagnósticos.
- QA gráfico real em OpenGL/AMD: `tests/ui_smoke.gd` acionou botões e grid por
  eventos de mouse, construiu quatro tipos em dois andares, rejeitou overlap e
  cancelou construção. Zero falhas; captura inspecionada em `.runtime/construction-ui.png`.
- Corrigido o harness de QA: `push_input(..., true)` para coordenadas locais sob
  stretch. O primeiro teste usava coordenadas locais como coordenadas de janela.
- Captura 1280×800 legível, sem recorte de comandos. Outras resoluções, zoom/pan
  e teclado completo ainda precisam de cobertura adicional no M1d.

## M1b–c — simulação operacional
- `simulation_test.gd` strict: zero falhas/diagnósticos. Hóspede fez check-in,
  dormiu, consumiu 3 refeições, saiu; receita $224, um quarto limpo e 7 entregas
  de elevador (hóspede + funcionário). Salários/manutenção efetivamente cobrados.
- Sem recepcionista: hóspede abandona após esgotar paciência.
- 13 passageiros isolados: capacidade nunca excedeu 4, todos chegaram ao destino,
  entrega exatamente uma vez, fila drenada e espera medida.
- Validação agregada de 21 scripts e boot integrado sem diagnósticos.
- UI smoke ampliado: contratar ambos funcionários, abrir hotel, gerar receita,
  pausar. Zero falhas. Largura estável do botão de chegadas evita deslocar a pausa.
- Conteúdo de simulação segue provisório; métricas acima demonstram funcionamento,
  não balanceamento final. Multi-seeds/stress e save/load aguardam próximo marco.

## M1d — persistência e aceite do slice
- `tools/test.ps1 -Visual` passou integralmente: foundation, construction (16 checks),
  simulation, save, ui_smoke e ui_resume. Logs em `.runtime/`; runner rejeita erros
  de script, erros de engine e vazamento de objetos, além de exit code não zero.
- Save test: gravação/backup, ida e volta completa, viagem de elevador em curso,
  continuidade idêntica por 2.400 ticks; rejeição de versão desconhecida, catálogo
  inexistente, tipo inválido, overlap, passageiro inexistente, arquivo truncado/ausente.
- Corrigidos dois defeitos descobertos pelo teste: lambda em signal retinha sessão;
  substituída por método ligado. Relógio acumulava floats; agora deriva de tick inteiro.
- Fluxo gráfico: construir quatro tipos em dois andares, contratar, abrir chegadas,
  gerar receita, pausar, salvar, zerar sessão, carregar estado idêntico, zoom, pan e F3.
- Processo gráfico independente carregou o save e avançou 71 ticks sem erros.
- Capturas inspecionadas em 1280×800 e 1024×640. O comando solicitou 1024×720,
  mas o viewport capturado manteve proporção 16:10; não declarar 1024×720 validado.
  Sidebar tem rolagem e controles utilizados permaneceram acessíveis.
- Não validados ainda: navegação integral por teclado/controller, touch, leitores de
  tela, DPI variados, exports, stress 500–1000 agentes e balanceamento multi-seed.
  Essas limitações não são apresentadas como features prontas.

## M2 — simulação, stress e correção de continuidade
- Runner completo `tools/test.ps1 -Stress -Visual`: oito suítes passaram sem erro/leak.
  Métricas de filas foram acrescentadas depois e `stress_test.gd --strict` passou novamente.
- Nova suíte de saves encontrou 7 divergências em 20 checkpoints antes da correção.
  Primeiro desvio reproduzido: seed 1, tick 1012, elevador em 1.07 versus 1.0.
  Causa: resíduo positivo no door_timer após JSON alterava a transição de estado.
  Comparações de limites usam TIME_EPSILON=1e-8, menor que 1/1.000.000 do tick.
- Após correção: 20 checkpoints passaram, cobrindo working/idle/walking/checkin/riding/
  using/lift_queue/cleaning. Cada um continuou 600 ticks comparando todos os campos.
  Estados/contagens iguais; somente floats admitem erro absoluto <=1e-8. O teste de
  disco inicialmente comparava texto JSON e detectou diferença de arredondamento em
  atributos de atores; agora compara campos com o mesmo critério explícito.
- Cinco seeds de 5 dias: zero falhas de invariantes e ciclo produtivo em todas.
- 100/250/500/1000 agentes no transporte: entrega de todos exatamente uma vez, destinos
  corretos, capacidade respeitada e filas drenadas. Máximo observado com 1000: 3,599 ms
  por passo do transporte, sem renderização. Não extrapolar para jogo inteiro.
- CLI real: cenário padrão 30 dias, 36.000 ticks, 374 reservas, 488 saídas e 930 viagens;
  tower burst 1000: 20 andares, 1000 saídas, apenas 24 reservas. Zero falhas nos dois.
- Tempos e resultados completos preservados em `docs/benchmarks/`. Sem ajustes arbitrários
  de custos/preços: esta etapa mede e corrige comportamento, não declara economia final.

## M3 — upgrades, equipe e finanças
- `tools/test.ps1 -Stress -Visual`: dez suítes aprovadas, sem erros/leaks do engine.
- Upgrades dos quatro tipos até N3: custo exato, manutenção efetiva, limite e saldo
  insuficiente; Resources base permanecem imutáveis. Save/load preserva níveis.
- Serviço iniciado mantém preço contratado mesmo após upgrade e save/load;
  novos hóspedes sem saldo para o preço atualizado escolhem novamente.
- Equipe: mudança de recepção, exclusividade/reserva de posto, mudança de andar
  durante limpeza e viagem, retorno ao automático e limpeza de referência ao demolir.
- Fixture real M2 (`tests/fixtures/m2-save-v1.json`) migra sem alterar a entrada,
  continua 600 ticks e salva em v2. Níveis inválidos são rejeitados.
- Check-in ficou mais rápido; transporte de 20 passageiros passou de 279 para 125
  ticks com elevador N3 no cenário isolado. Não equivale a retorno econômico validado.
- Teste gráfico compra upgrade pelo mouse, seleciona camareiro/andar pelo teclado,
  aplica preferência e abre Finanças para conferir custos fixos. PopupMenus recebem
  eventos via Input com window_id; controles normais recebem eventos do viewport.
- Teste gráfico adicional com resolução solicitada 1024×720 aprovado; capturas reais
  1024×640 inspecionadas, incluindo rolagem do inspetor e painel Equipe. Capturas locais:
  `.runtime/m3-staff.png` e `.runtime/m3-upgrade.png`.
- Economia segue como hipótese de protótipo; contrato e próximo experimento em
  `docs/M3_BALANCE.md`. Navegação integral por teclado/controller permanece pendente.

## M4 — objetivos e desbloqueios
- Runner completo `tools/test.ps1 -Stress -Visual`: doze suítes passaram, sem erros
  ou leaks reportados pelo engine. Novas classes exigiram import antes do primeiro teste.
- Três objetivos com fronteiras exatas, múltiplos requisitos, bloqueio transacional
  de compra, permanência após queda de reputação e reset em nova sessão verificados.
- Snapshots v3 preservam progresso parcial/concluído; rejeitam IDs desconhecidos,
  duplicados, sequência inválida, flags malformadas e N3 instalado sem autorização.
- Fixtures reais M2/v1 e M3/v2 migram; v2 continua 600 ticks e salva em v3. Migração
  não modifica o dicionário de entrada e mantém acesso legado às melhorias N3 do M3.
- Hotel de dois quartos, caixa inicial $12.000, seed 99: 25 visitas sequenciais
  concluíram os três objetivos; caixa final $8.972. Continuidade de 600 ticks após
  save/load sem divergência. Não representa comportamento ou ritmo de jogadores reais.
- Cinco seeds do template padrão liberaram N3 entre ticks 1661–1795; quatro também
  conquistaram o título nos cinco dias. Evidência: `benchmarks/m4-progression.json`.
- UI: N2 comprado por mouse, motivo do bloqueio N3, painel que atualiza aberto,
  fechamento por Esc, compra após desbloquear, salvar/carregar pela toolbar e reset
  ao trocar partida. Capturas topo/fim da rolagem inspecionadas.
- Resolução padrão e teste adicional solicitado em 1024×720 passaram; captura menor
  efetiva 1024×640. Arquivos locais `.runtime/m4-locked.png`, `m4-objectives.png` e
  `m4-objectives-bottom.png`. Nenhuma declaração de QA integral de acessibilidade.

## M5 — conteúdo, perfis e calendário
- Quatorze suítes aprovadas: nove headless (incluindo stress/continuidade) e cinco
  gráficas. Após a última validação de contadores, headless passou; a comparação
  textual do save no ui_smoke falhou intermitentemente. Foi substituída pelo mesmo
  comparador de campos/tolerância 1e-8 já usado no M2; as cinco suítes gráficas passaram
  novamente. Sem erros/leaks nos resultados finais.
- Novas salas: bloqueio sem cobrança, acesso legado sem liberar conteúdo futuro,
  construção após objetivos, capacidade/fila, pagamento único, alívio da necessidade
  correta, continuidade por 1.500 ticks. Uso de lazer não incrementa refeições.
- Mesmas necessidades/posição produzem escolhas distintas nos três perfis; fome alta
  favorece refeição completa; falta de saldo exclui serviços pagos.
- Três seeds com demanda controlada usaram café e lazer, respeitando invariantes.
  O café teve uso baixo ou nulo com chegadas contínuas; ajuste temporário de rapidez
  foi revertido por não alterar esse resultado. Limitação de balanceamento explicitada
  em `M5_CONTENT.md`; não equivale a retorno econômico ou escolha humana validada.
- Fronteiras do calendário nos ticks 3599/3600/4799/4800/7200/8400/10800 verificadas.
  Hotel fechado não recebe chegadas; comparação de 30s mediu 5/7/4 chegadas em
  condição normal/feira/dias tranquilos. Save ativo continua por 5.000 ticks,
  atravessando fim e próximo evento sem divergência.
- Fixture real M4/v3 migra sem mutação de entrada, mantém dinheiro e atribui perfil
  equilibrado aos atores existentes. Perfis desconhecidos e contadores inválidos são
  rejeitados. Migrações antigas v1/v2 e 20 checkpoints/5 seeds continuam aprovados.
- UI: construção de café/lazer pelo viewport, bloqueios e requisitos, seleção de
  hóspede com perfil visível, evento de 150% e calendário congelado em pausa, save/load
  pela toolbar com salas/perfil/evento preservados. Novos controles permanecem na
  rolagem existente; o teste antigo agora rola até o botão antes de clicar.
- Teste adicional `ui_content` com resolução solicitada 1024×720 passou. Captura
  efetiva 1024×640 inspecionada em `.runtime/m5-content.png`, com café/lazer, perfil
  e faixa de evento legíveis. A versão padrão também foi inspecionada. Navegação
  integral por teclado/controller e acessibilidade assistiva continuam pendentes.

## M6 — filtros, indicadores e leitura
- Bateria completa `tools/test.ps1 -Stress -Visual`: dezesseis suítes passaram sem
  erros/leaks. São oito suítes headless básicas, duas de stress/continuidade e seis
  gráficas. Analytics também passou pelo gda `--strict`.
- Métricas verificadas com hotel vazio e estado conhecido: ocupação 1/2 = 50%,
  satisfação média 70 de três hóspedes (sem equipe), filas 1+1, maior espera 12,5s,
  custo igual à cobrança diária. Filtros combinados, poço por andar e desempate por
  ID conferidos. Captura antes/depois comprova ausência de mutação na partida.
- Teclado: digitação “cafe” encontra Café Brisa, consulta sem resultados mostra
  explicação, F2 abre/foca filtro, PopupMenu filtra limpeza, Enter seleciona/centraliza,
  atualização remove sala que deixou de estar suja, Esc fecha e devolve foco. F4
  altera fonte/preferência; nova partida reseta filtros e mantém preferência.
- Equipe e Finanças abrem e fecham por teclado, com retorno de foco. Finanças tem
  extrato rolável. Dados de utilidade aparecem apenas no debug; estados em português.
- Capturas normais/ampliadas inspecionadas. A imagem revelou altura excessiva de
  Equipe causada por wrap_controls; corrigido para conteúdo rolável com altura
  controlada. Após a correção, ui_management e ui_operations foram reexecutados em
  janela menor; ui_operations também foi reexecutado na resolução padrão.
- Janela menor solicitada: 1024×720; captura do HUD efetiva: 1024×640. Verificações
  de dimensões comparam unidades lógicas equivalentes de Window e viewport. Arquivos:
  `.runtime/m6-operations.png`, `m6-large-panel.png`, `m6-large-hud.png`,
  `m6-large-staff.png`, `m6-large-finances.png`.
- Sem alteração de regras, RNG, economia, save v4 ou balanceamento. Sem declaração
  de QA de controller, touch, leitores de tela, DPI variados ou construção só por teclado.


## M7 — apresentação raster
- 15 PNGs (25.338.668 bytes de fontes) gerados pelo image_gen integrado; cinco
  interiores, cinco componentes/cenário e cinco spritesheets RGBA. Prompts,
  dimensões/hashes e referência visual versionados em docs/art.
- Bateria `tools/test.ps1 -Stress -Visual`: 17 suítes passaram, sem erros ou leaks.
  Oito básicas, duas de stress/save e sete gráficas. Nova ui_art cobre transparência,
  recortes, ciclo de caminhada, render sem mutar snapshot, zoom e preferência sonora.
- Após habilitar mipmaps do passeio, import final e ui_art/ui_operations reexecutados
  com janela solicitada 1024x720 (viewport capturado 1024x640), ambos passaram.
- Inspeção visual de zoom 0,35, 0,9 e 1,8: materiais/silhuetas, recorte, pés no chão,
  cabine e badges. Evidência padrão: docs/art/hotel-m7.png. Textos permanecem nativos.
- Seis scripts passaram em gda script validate com caminhos canônicos res://.
  A primeira tentativa por caminhos relativos retornou falso conflito de classes no
  Windows; repetir por res:// validou todos. Import e execução também confirmaram.
- Três WAVs PCM originais carregam; acionamento por construção/melhoria/objetivo e
  botão Som. Não houve avaliação auditiva humana; música/ambiente contínuo ausentes.
- Sem mudança na simulação, RNG, economia ou formato v4. Caminhada não equivale a
  animações específicas de atendimento, sono e limpeza, que seguem como expansão.
- M8 ainda pendente: estes testes não comprovam 1000 atores renderizados a 60 FPS.


## M8a — visibilidade (20/09/2026)
- Perfil inicial antes/depois para 100/250/500/1000 hóspedes: resultados brutos e
  método em docs/benchmarks/m8. Render isolado, não FPS integrado.
- 1000 distribuídos: média 12,02 → 8,42 ms, draw calls 1090 → 443. Todos visíveis
  não melhorou; limites registrados. Sobrecarga de chegadas atingiu P95 83,35 ms.
- ui_culling: nove comparações byte a byte de imagens com/sem otimização passaram;
  nenhuma mutação do snapshot. Preserva espelhamento, espera e aviso de limpeza.
- tools/test.ps1 -Visual: 16 suítes passaram (oito básicas e oito gráficas), sem
  erros/leaks. Suites de stress não repetidas: regras/simulação não foram alteradas.
- gda validou HotelView, performance_profile e ui_culling com caminhos res://.
- Um erro de tipagem do array vazio no harness render-only foi corrigido; processo
  do benchmark falho encerrado por PID identificado, execução repetida e concluída.
- M8 permanece incompleto: perfil por sistema e teste integrado com ocupação real
  necessários antes de concluir o marco. project.godot anterior permanece fora do commit.


## M8 — admissão/saídas (20/09/2026)
- Duas otimizações locais, sem alterar decisões, ordem de filas ou estado salvo.
- Bateria completa tools/test.ps1 -Stress -Visual: 19 suítes passaram sem erros/leaks.
- Equivalência: três seeds, 240 ticks de reposição por seed, checkpoints completos,
  recepção reconstruída após outras salas e 100 ticks de continuidade por save.
- Perfil controlado da sobrecarga: P95 1000 caiu 83,35 → 16,85 → 9,28 ms.
  Totais de saídas, população final e pedidos de transporte permaneceram iguais.
- Perfil integrado com HUD: quatro ondas e 12 segundos de simulação a 1x cada;
  todas terminaram com 24 hóspedes, quatro reservas e invariantes válidas.
  Não sustenta afirmação de 1000 hóspedes atendidos simultaneamente.
- gda validou os quatro scripts envolvidos. Resultados e limitações completos em
  docs/benchmarks/m8/ADMISSION.md. Marco continua aberto para operação preenchida.


## M8 operacional e transição M9 (verificado em 21/09/2026)
- operating_profile: procura normal e controlada, 300 segundos de preparação real,
  fases de 30 segundos em 1x/3x. Cenário controlado sustenta 118–120 hóspedes;
  P95 5,70/5,96 ms, serviços ativos e invariantes válidas. operating.json versionado.
- Regressão tools/test.ps1 -Visual iniciada na execução anterior foi retomada pelo
  mesmo handle: completou 17 suítes sem falhas. Não foi reiniciada por timeout.
- gda validou operating_profile e ui_new_game após liberação da revisão automática.
- Diálogo nativo testado via Esc/Enter com window_id correto; cliques da toolbar
  reais, cancelamento preserva snapshot/foco, confirmação preserva arquivo e Load
  recupera partida. Primeira injeção no viewport errado foi corrigida no harness.
- M8 concluído para a capacidade atual (120); não prova 1000 hóspedes atendidos.

## M9 — continuidade longa (21/09/2026)
- tools/test.ps1 -Soak: nove suítes passaram (oito básicas e long_run).
- Seis partidas de 30 dias, 30 checkpoints de save com 120 ticks de continuação
  comparada por checkpoint. Caixa, agentes, capacidade e referências sem violações.
- Oito quartos financiados por $12.000: mínimo $2.370, final $34.832–35.112;
  primeiro desbloqueio de serviços dentro de cinco dias nas três seeds.
- Montagem inicial inválida (quartos sobre poço) detectada pelo teste, corrigida e
  repetida. Os relatórios finais representam oito quartos realmente construídos.
- Reputação modesta nos layouts estáticos exige análise de decisões de gestão;
  M9 e balanceamento de produção continuam em andamento. Nenhuma regra alterada.

## Regressão integrada pós-arte (30/09/2026)

- Revisão limpa dcfcd2d, Godot 4.7.2: 31 suítes mais import passaram com
  `tools/test.ps1 -Visual -Stress -Soak`; sem erros, leaks ou timeout.
- 15 suítes headless e 16 gráficas; seis cenários de 30 dias/30 checkpoints,
  conservação/entrega de 100/250/500/1000 passageiros no transporte isolado.
- Primeira execução parou numa fixture de preview cortada pelo cabeçalho ampliado.
  Enquadramento adaptado ao playfield e recortes à escala dos pixels; preservados
  seis quartos, quatro fases e 24 amostras. Nova bateria completa passou.
- Relatório com revisão/hash do engine, duração/exit code e logs originais arquivados
  em docs/benchmarks/m9/regression-20260930*. Detalhes e limites em QA_REVIEW.md.
- Alterações apenas no runner e no teste; jogo e pacote 7f651a3 permanecem iguais.
  Compatibilidade externa e playtest humano continuam pendentes.
