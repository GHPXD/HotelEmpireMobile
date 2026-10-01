# Classificação dos testes na migração mobile

## Preservar e executar

`tools/run_tests.py` executa Godot via gda com `--json --strict`, isola `user://`
por suíte e registra revision, resultado, duração e hash de cada evidência.

| Grupo | Suítes | Motivo |
|---|---|---|
| domain | foundation, construction, simulation, save, management, lodging_value, reviews, progression, content, analytics, checkin_diagnostics | Invariantes e contratos do domínio herdado |
| stress | save_multiseed, stress, admission_equivalence | Continuidade determinística, transporte até 1.000 agentes e equivalência de admissão |
| studies | long_run, departure_observer, tariff_scenarios | Solvência e balanceamento de estadias/tarifas |
| helpers | snapshot_comparison, departure_observer | Utilitários chamados pelas suítes, não entry points |

Comando completo: `python tools/run_tests.py --group all --godot <executável>`.
`tools/test.ps1` permanece como executor auxiliar do host; Windows não é target do produto.

## Substituição concluída no Sprint 2

Os 19 `tests/ui_*.gd` e o harness desktop foram removidos depois da transferência
da cobertura útil. Não há entry point, Window, hotkey ou leitor restante dessas
telas no runtime. Os 17 testes de domínio/stress/estudos permanecem.

| Cobertura herdada | Suítes | Substituição |
|---|---|---|
| Input e janelas | ui_smoke, ui_management, ui_help, ui_exit | input_navigation_test, touch_management_test, shell_layout_test: GUI real, scroll/pan/pinch, modal, back e construção explícita |
| Save e sessão | ui_resume, ui_recovery, ui_new_game | save_lifecycle_test, touch_management_test: boot, checkpoint, backup, recovery e retomada dos comandos |
| Gestão | ui_operations, ui_progression, ui_reviews, ui_content, ui_checkin_diagnostics | touch_management_test, presentation_test: salas, tarifas, assignments, filtros, finanças, reviews e traduções de projeções causais |
| Ícones e preferências | ui_action_icons, ui_management_icons, ui_session_icons, ui_preferences_icons | arte original em MobileHotelPanels; presentation_test, audio_lifecycle_test, touch_management_test e captures com texto ampliado |
| Renderização útil | ui_art, ui_culling, ui_actor_presentation | art_render, culling_render, actor_presentation_render: pixels, âncoras, bagagens, poses, hit targets e equivalência de culling portados para HotelView independente |

Há treze suítes executáveis `*_test.gd` no grupo mobile após a Sprint 4. `display_scale_test`
verifica resolução física/densidade, stretch, cutouts, targets e rotação lógica.
`platform_adapters_test` mantém cobertura dos contratos de analytics/config.
Os três `*_render.gd` precisam de renderer nativo e são executados com
`tools/test.ps1 -Visual` ou `tools/test_mobile_render.ps1 -Suite <nome>`.
Helpers em `tests/mobile/` não são entry points do executor headless.

Sprint 3 acrescenta `player_work_test` (tarefas, reservas, cobrança, cancelamentos,
elevadores, snapshots/continuação e pacing multiseed), `onboarding_test` (fatos,
módulos, perfil novo/existente e lifecycle) e `onboarding_touch_test` (guia e quatro
ações por GUI/viewport em três formatos/idiomas, com texto ampliado).
`legacy_admission_reference` é helper: a referência de equivalência foi movida de
classe interna para script próprio após reproduzir falha de shutdown do Godot.
Mantém o algoritmo de referência e incorpora o mesmo desgaste do quarto por uso;
comparações completas de snapshots, sementes e continuação permanecem.

Sprint 4 acrescenta `staff_automation_test` e `staff_touch_test`: evolução por tarefas
reais, perfis/traços, trade-offs, pausa/prioridade, salários, desligamento físico,
persistência e comparação multiseed manual/delegada. A referência de admissão conecta
o sinal de XP ao seu EmployeeSystem após substituir GuestSystem; seu algoritmo de
varredura continua independente. Nenhuma suíte herdada foi removida nesta sprint.

`player_work_cases` é helper carregado em runtime pelo entry point existente;
preserva exatamente os corpos dos casos da Sprint 3, com 2.862 checks e 11 fases.
O gate continua exigindo saída zero e ausência de erros/recursos retidos. O áudio
aguarda a liberação exata de referências com limite, sem referência temporária
retida pelo próprio polling assíncrono.

A Sprint 5 em implementação acrescenta `progress_clock_test`,
`construction_timer_test`, `construction_lifecycle_test` e `construction_touch_test`,
totalizando dezessete entry points `*_test.gd` descobertos pelo grupo mobile.
`construction_timer_cases`, `construction_lifecycle_cases` e `fake_progress_time`
são helpers. Prazos injetados percorrem a aplicação real sem esperas de horas.
As suítes anteriores de onboarding/gestão/shell agora verificam pagamento inicial,
indisponibilidade antes do prazo e conclusão antes de operar salas.
Speedups e os demais componentes pendentes ainda precisam de cobertura própria;
esses testes não concluem o gate da sprint.

## Próximas coberturas

Adicionar às suítes mobile existentes: timers/offline, economia global,
rewarded, IAP/restore/idempotência, progressão,
prestige, localização e budgets. O grupo `mobile` é descoberto pelo executor.

Validações intermediárias são responsabilidade do agente. A avaliação do usuário
fica para o Sprint 15. Simulação de lifecycle não equivale a kill real pelo OS;
assinatura, SDKs sandbox/produção e aparelhos devem ter evidência própria.
