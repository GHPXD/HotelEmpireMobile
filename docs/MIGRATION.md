# Migração PC → Mobile

Documento temporário. Deve ser removido quando a migração estiver concluída.

## Execução ativa

Contrato completo preservado em [MOBILE_MIGRATION_BRIEF](MOBILE_MIGRATION_BRIEF.md).
Decisões: [MOBILE_DECISIONS](MOBILE_DECISIONS.md). Classificação dos testes:
[TEST_MIGRATION_MATRIX](TEST_MIGRATION_MATRIX.md).

Auditoria técnica do Sprint 0:

- Partida na `main`, revision `608b02c`, sem alterações locais anteriores.
- Godot 4.7.2 e gda 0.17.0 disponíveis. gda exige `GDA_GODOT` explícito neste host.
- Removidos `build_windows.ps1`, `test_windows_package.ps1`,
  `build_compatibility_kit.ps1`, `audit_release.py` e preset Windows Desktop.
  As referências encontradas eram restritas a esses próprios scripts/preset.
- Preservados domínio, fixtures/migrations v1–v7, ferramentas de tarifas e
  `test.ps1`. Novo executor portátil `run_tests.py` gera evidências por suíte.
- Baseline: 17 suítes aprovadas, zero failures/diagnostics. Inclui 20 checkpoints
  multiseed, stress até 1.000 agentes, seis cenários de 30 dias e 18 de tarifas.
  Resumo versionado: `docs/SPRINT0_BASELINE.json`; evidências locais:
  `.runtime/tests/20261001T043350Z-mobile-baseline/`.
- Inventário: 82 PNGs, 54 sem size limit; RGBA estimado sem mipmaps de
  351.046.412 bytes. Runtime usa arte raster original via `HotelArt`.
- Legado identificado naquele baseline, resolvido no Sprint 2: `main.gd` registrava
  atalhos e criava `Window`/ConfirmationDialog; `HotelHUD` usava toolbar/sidebar;
  `HotelView._gui_input` usava mouse, wheel e botão do meio; 19 testes `ui_*`
  dependiam do harness desktop e não contavam como cobertura mobile.

Sprint 0 técnico concluído: regressão pós-reset também passou nas 17 suítes,
sem failures/diagnostics (`.runtime/tests/20261001T043637Z-sprint0-regression/`).

Esse baseline antecede a fundação e a UX implementadas abaixo.

### Fundação implementada (Sprint 1)

- Entry point mobile: `AppRoot`, `GameController` e `MobileShell` responsivo.
- Save envelope v1 com domínio v7; migrations v1–v7 preservadas. Autosave 30s,
  checkpoint após comandos/background, backup/recovery automático e bloqueio de
  downgrade/sobrescrita de dados irrecuperáveis. Nenhum botão Salvar necessário.
- Touch/pan/pinch e roteamento de um sheet; world input ignora mouse emulado.
- Safe area testada com notch e gesture bar em pixels convertidos para UI.
- Traduções PT-BR/EN/ES e mudança de locale atualizam controles existentes.
- Analytics/config com defaults locais, filas/bounds e providers mock; sem SDK.
- APK de debug Android gerado com toolchain instalada. ETC2/ASTC habilitado por
  exigência verificada no exporter. Signing de produção/AAB ficam no release.
- Preset iOS sem Team ID inventado. Host Windows, sem Xcode/template iOS.
- Não há device/AVD/imagem Android neste ambiente. Screenshots de renderer local
  e notificações injetadas não contam como instalação/kill real pelo OS.
- Gate local aprovado: 21 suítes, 128 verificações renderizadas e 12 capturas;
  detalhes/hashes em `docs/SPRINT1_VALIDATION.json`. APK reconstruído sem warnings.

### Gestão por toque implementada (Sprint 2)

- Removidos main desktop, HUD, panels Window, hotkeys, wheel/middle mouse,
  release smoke desktop e os 19 testes ui_* após portar a cobertura útil.
- MobileHotelPanels expõe construção/categorias, operações/filtros, tarifas,
  upgrade, contratação/assignments, finanças, reviews, objetivos e preferências.
  MobileLabels traduz dados reais e diagnósticos causais do domínio.
- Construção e demolição exigem confirmação explícita. Pan/pinch/scroll/back
  não gastam Cash; scroll iniciado sobre botão cancela sua ativação.
- Contexto abaixo/lateral sem cobrir hotel; slots e alvos continuam visíveis.
  Área de scroll e targets mínimos de 48 unidades, cutouts e texto ampliado.
- Escala mobile pela densidade, com canvas stretch e toque em pixels físicos
  verificados em 1x/2x/3x. Áudio libera stream em background; haptic é opcional.
- Regressões úteis de arte, sprites, bagagem, hit tests e culling preservadas em
  três suítes renderizadas independentes do harness desktop.
- Evidências locais e hashes: `SPRINT2_VALIDATION.json`.

### Operação manual e onboarding implementados (Sprint 3)

- PlayerWorkSystem usa um ator real, caminhos/elevadores e reservas exclusivas;
  check-in, limpeza, preparação/entrega e reparo têm duração curta e efeito real.
- Cancelamentos liberam salas/capacidade e mantêm passageiro embarcado seguro.
  Hospedagem e entrega cobram uma vez; reparo cobra materiais na conclusão.
- Condição degrada por uso, reduzindo eficiência em até 20%; reparo recupera 100%.
- Snapshot v8 migra v1–v7 e valida referências/fases. Onboarding v1 em app_state
  avança por fatos, preserva outros módulos e pode ser ocultado/retomado.
- Perfil novo de 2.400 Cash completa operação solo → contratação sem fundos
  artificiais nas políticas medidas. Saves existentes preservam patrimônio.
- HUD traduzido com cancelamento prioritário, Você e ícones raster individuais.
- Gate completo aprovado: 31 suítes, 4.274 verificações renderizadas e 98 capturas,
  mais revisão dos ícones em UI de 32 px; APK Android debug 0.5.0 sem warnings.
  Evidências e hashes preservados em `SPRINT3_VALIDATION.json`.

Próxima etapa: Sprint 4, desenvolvimento/supervisão da equipe. As limitações reais
de device/iOS/lojas continuam no Sprint 15; não são resolvidas por captures ou mocks.

## Objetivo

Reaproveitar o domínio validado e substituir o que é específico de desktop.

## 1. Preservar

### Domínio

- HotelSession;
- HotelModel;
- RoomState/RoomDefinition;
- GuestSystem;
- EmployeeSystem;
- TransportSystem;
- ServiceQueue;
- HotelEconomy;
- progression core;
- event definitions;
- save versioning.

### Testes

Preservar regressões de:

- foundation;
- construction;
- simulation;
- save;
- management;
- progression;
- reviews;
- stress;
- tariffs quando ainda úteis ao balanceamento.

## 2. Substituído nos Sprints 1–2

### Input

Remover dependência de:

- mouse esquerdo/direito/meio;
- wheel;
- hotkeys;
- foco por teclado.

Adicionar:

- tap;
- drag;
- pinch;
- back;
- gestures contextuais.

### UI

Substituir:

- Window;
- toolbar desktop;
- sidebar desktop;
- atalhos F1/F2/F3/F4;
- Ctrl+F/Ctrl+S.

Por:

- top bar;
- bottom nav;
- bottom sheets;
- screens;
- overlays;
- safe area.

### Save UX

Remover dependência do botão manual Salvar.

Adicionar autosave/lifecycle.

## 3. Serviços novos

- SaveService;
- OfflineProgressService;
- PlayerEconomy;
- MonetizationService;
- AdsService;
- PurchaseService;
- EntitlementService;
- AnalyticsService;
- RemoteConfigService;
- ScreenRouter;
- MobileInputController.

## 4. Assets

Estado herdado:

- muitos PNGs grandes;
- catálogo com vários preloads;
- dezenas de texturas sem size limit.

Ações:

1. inventariar resolução e memória;
2. definir budget;
3. limitar imports;
4. testar compressão mobile;
5. agrupar assets por hotel;
6. medir boot/memória;
7. eliminar redundâncias somente depois de confirmar referência.

## 5. Documentação

Concluído nesta migração documental:

- remover evidências de Windows;
- remover screenshots de QA desktop;
- remover matrizes de compatibilidade desktop;
- remover milestones históricos PC da documentação ativa;
- substituir por documentação mobile.

## 6. Testes obsoletos

Testes de UI baseados em:

- keyboard;
- F-keys;
- mouse wheel;
- middle mouse;
- desktop Window;
- resoluções desktop específicas;

foram substituídos pelas suítes mobile da matriz. Captures técnicos de arte
preservam regressões de renderização, sem serem usados como prova de aparelho.

## 7. Export

Preset Windows removido; presets configurados:

- Android;
- iOS.

Android debug arm64 exportado; iOS preparado para toolchain macOS. Signing de
produção, build iOS e QA de OS/lojas permanecem gates do Sprint 15.

## 8. Strings

Migrar strings hardcoded para localization keys.

Não continuar acumulando texto de produto dentro de scripts.

## 9. Economia

Separar HotelEconomy de PlayerEconomy antes de integrar IAP.

## 10. Sequência

```
docs/reset
→ mobile foundation
→ touch UX
→ player-as-worker
→ staff automation
→ timers
→ F2P economy
→ monetization
→ retention
→ hotel systems
→ empire
→ analytics
→ optimization
→ release
```

## 11. Definição de concluído

A migração termina quando:

- nenhum fluxo essencial depende de mouse/teclado;
- build Android/iOS é first-class;
- save é lifecycle-safe;
- monetização está desacoplada;
- assets respeitam budgets;
- testes mobile substituem QA desktop;
- documentação não descreve plataforma desktop como target.
