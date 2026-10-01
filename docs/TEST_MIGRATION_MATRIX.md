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

## Substituir com cobertura mobile

Todos os `tests/ui_*.gd` são testes da apresentação antiga e **não** contam como
validação mobile. Serão substituídos junto das respectivas telas no Sprint 2.

| Cobertura herdada | Suítes | Substituição |
|---|---|---|
| Input e janelas | ui_smoke, ui_management, ui_help, ui_exit | Touch, conflitos pan/scroll, back e roteamento Control |
| Save e sessão | ui_resume, ui_recovery, ui_new_game | Boot, autosave, background/resume e recovery automático |
| Gestão | ui_operations, ui_progression, ui_reviews, ui_content, ui_checkin_diagnostics | Bottom sheets por toque e feedback de causalidade |
| Ícones e preferências | ui_action_icons, ui_management_icons, ui_session_icons, ui_preferences_icons | Arte original, targets touch, persistência de settings |
| Renderização útil | ui_art, ui_culling, ui_actor_presentation | Preservar as verificações de pixels/âncoras/culling, portar o harness ao AppRoot |

Os arquivos antigos permanecem enquanto leitores ainda dependem do harness; nenhuma
regressão de domínio será removida para acomodar mudanças de UI.

## Criar

Suítes em `tests/mobile/`: persistência/lifecycle, gestos, safe area, UI por toque,
timers/offline, economia global, rewarded, IAP/restore/idempotência, progressão,
prestige, localização e budgets. O grupo `mobile` é descoberto pelo executor.

Validações intermediárias são responsabilidade do agente. A avaliação do usuário
fica para o Sprint 15. Simulação de lifecycle não equivale a kill real pelo OS;
assinatura, SDKs sandbox/produção e aparelhos devem ter evidência própria.
