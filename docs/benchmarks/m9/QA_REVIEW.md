# Revisão da M9 — protótipo desktop atual

Escopo: revisão do vertical slice e dos incrementos M0–M8 no Godot 4.7.2 deste
Windows. Não é certificação comercial, teste de todos os dispositivos ou prova de
1000 hóspedes atendidos. Export e compatibilidade do pacote pertencem à M10.

Em 21/09/2026, `tools/test.ps1 -Stress -Visual -Soak` concluiu com exit 0:
21 suítes, sem falhas, erros de script ou avisos de recursos vazados. Resumos
extraídos dos logs reais estão em `regression.json`. M9 concluída neste escopo;
o objetivo geral de evolução do jogo permanece em andamento.

| Requisito do protótipo | Evidência executável |
|---|---|
| Abrir, iniciar novo hotel, confirmar/cancelar e reiniciar estado | ui_smoke, ui_new_game |
| Construir, demolir, selecionar e expandir andares | construction_test, ui_smoke, ui_management |
| Receber hóspedes, quartos, alimentação, elevadores e limpeza | simulation_test, stress_test, long_run_test |
| Contratar/atribuir funcionários e melhorar instalações | management_test, ui_management |
| Ganhar/gastar, reconciliar caixa e operar com orçamento inicial | foundation_test, analytics_test, long_run_test, perfis management/checkin |
| Satisfação, filas e congestionamento visíveis | analytics_test, ui_operations, métricas dos perfis |
| Salvar, carregar, continuar e preservar o save ao criar novo hotel | save_test, save_multiseed_test, ui_resume, ui_new_game, long_run_test |
| Conteúdo, objetivos, perfis e eventos | progression_test, content_test, ui_progression, ui_content |
| Arte, áudio, animação e câmera | ui_art, ui_culling |
| Otimização preserva comportamento | admission_equivalence_test; perfis M8 separados |

Save_test cobre arquivo ausente/truncado, versão/conteúdo/tipo inválidos, referência
pendente e sobreposição; valida viagem de elevador, substituição com backup e
continuidade. O teste longo repete 30 checkpoints de save/load. Isso não prova
resistência a toda falha de disco/energia nem tratamento de todo erro pela UI.

Diagnóstico econômico: 12 partidas de comparação e 15 de intervenções isoladas,
três seeds por política, sem alterar regras ou injetar caixa. Há escolhas eficazes
de gestão, com limpeza limitando o hotel de referência. Espera alta não foi ocultada
nem o contrato relaxado para atingir reputação artificialmente.

Limites registrados em 21/09/2026: entrada principal desktop; cobertura parcial de
teclado, sem certificação de controller/touch/leitor de tela; naquela revisão ainda
faltavam poses para dormir/sentar, adicionadas posteriormente na M7. Sem música ambiente; operação contínua medida
até o limite atual de 120 hóspedes. Os testes não substituem avaliação humana de
diversão, acessibilidade ou balanceamento em muitos mapas. Esses limites permanecem
visíveis no roadmap e documentação de arte/desempenho.

## Regressão completa de 24/09/2026

`tools/test.ps1 -Visual -Stress -Soak` passou com exit 0 na revisão `e816873`:
26 suítes, incluindo os incrementos de confirmação de saída, ajuda, recuperação,
diagnóstico de check-in, pinturas de upgrade e métricas de elevador. Resultados
extraídos dos logs desta execução, com hash e horário, em
`regression-20260924.json`; seis cenários de 30 dias e 30 checkpoints de
continuidade em `long-run-20260924.json`. Nenhum erro de script ou aviso de
recursos vazados foi detectado pelo runner.

Stress de transporte entregou 100/250/500/1000 agentes nos cenários isolados;
isso continua sem provar operação sustentada de 1000 hóspedes. A revisão não
substitui a matriz do executável nem a compatibilidade externa pendente em M10.

## Regressão completa de 30/09/2026

`tools/test.ps1 -Visual -Stress -Soak` passou na revisão limpa `dcfcd2d`:
31 suítes (15 headless, incluindo stress e continuidade; 16 gráficas) mais import.
Nenhum erro de script, timeout ou aviso de recursos vazados detectado. O runner
agora limita os processos a 120s por padrão, encerra apenas o handle que criou e
preserva relatório também em falhas. Prazo configurável por `-SuiteTimeoutSeconds`.

`regression-20260930.json` registra revisão/árvore no início e fim, engine/hash,
opções, horários, duração, exit code, resumos reais e SHA-256 de cada log.
`regression-20260930-logs.zip` preserva os 32 logs originais; seus bytes foram
comparados aos hashes do relatório. `long-run-20260930.json` registra seis
cenários de 30 dias e 30 checkpoints de save/load, todos sem divergências.

A primeira bateria na revisão `cf37cdf` parou em `ui_art`: o pan fixo da preview
de repouso cortava a linha superior com o cabeçalho de texto ampliado. Registro
e log original em `art-preview-failure-20260930.json`. A fixture agora centraliza
seis quartos explícitos usando o tamanho real do playfield. Recortes convertem
coordenadas lógicas para pixels da captura. Mantém os quatro quadros, prova 24
amostras e diferenças de pixels em cada cama, sem reduzir os casos ou alterar
o estado da simulação. Captura corrigida inspecionada antes da bateria final.

Com o catálogo atual de 70 PNGs, a regressão cobre nove combinações de repouso por
perfil/nível, refeições, café, leitura, filas e bagagem, retratos e ícones,
além de construção/gestão, avaliações, saída, ajuda, recuperação e diagnóstico.
Transporte isolado conserva e entrega 100/250/500/1000 agentes; não prova operação
simultânea de 1000 hóspedes nem performance de render em hardware externo.

O ZIP permanece na revisão `7f651a3`, cuja matriz de seis configurações está em
`../../release/action-icons-matrix.json`. Desde ela mudaram somente documentação,
runner e teste de arte, excluídos do executável. Esta bateria usa o editor e não
substitui a validação do pacote ou os resultados pendentes de outro computador.
Animações continuam com quatro poses pintadas; balanceamento e acessibilidade
de produção requerem avaliação humana.
