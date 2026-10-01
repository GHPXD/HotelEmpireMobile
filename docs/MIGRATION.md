# Migração PC → Mobile

Documento temporário. Deve ser removido quando a migração estiver concluída.

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

## 2. Substituir

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

devem ser substituídos, não considerados cobertura mobile.

## 7. Export

Remover preset Windows quando a migração de build começar.

Adicionar:

- Android;
- iOS.

Configurar depois de definir orientação e pipeline de signing.

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
