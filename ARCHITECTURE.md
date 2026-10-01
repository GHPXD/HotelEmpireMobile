# Arquitetura — Hotel Empire Mobile

## Objetivo

Preservar o domínio de simulação validado e substituir o acoplamento de desktop por uma aplicação mobile modular, testável e preparada para Android/iOS.

## Regra principal

A simulação não conhece SDKs de anúncios, lojas, analytics ou APIs de plataforma.

```
UI / Input
    ↓
GameController
    ↓
HotelSession
    ↓
Simulation Domain
```

Serviços de plataforma ficam ao lado do domínio:

A árvore inclui serviços previstos para as próximas sprints. Ads/IAP, entitlements
e offline ainda não estão implementados nesta entrega de fundação/UX.

```
AppRoot
├── GameController
│   └── HotelSession
├── SaveService
├── MobileInputController
├── ScreenRouter
├── AudioService
├── AnalyticsService
├── RemoteConfigService
└── MonetizationService
    ├── AdsService
    ├── PurchaseService
    └── EntitlementService
```

## Camadas

### Domain

Responsável pelas regras autoritativas:

- hotel;
- salas;
- hóspedes;
- funcionários;
- filas;
- transporte;
- economia operacional;
- reputação;
- reviews;
- eventos;
- progressão de hotel.

Classes existentes como `HotelSession`, `HotelModel`, `GuestSystem`, `EmployeeSystem`, `TransportSystem`, `ServiceQueue` e `HotelEconomy` devem ser preservadas e evoluídas.

### Application

Orquestra comandos, lifecycle e estado de sessão.

Componentes planejados:

- `GameController`;
- `SaveService`;
- `OfflineProgressService`;
- `MissionService`;
- `PlayerProgressionService`;
- `ContentService`.

### Presentation

Responsável por:

- HUD;
- screens;
- bottom navigation;
- bottom sheets;
- feedback;
- câmera;
- seleção;
- gestures;
- safe areas;
- tablets.

A apresentação herdada baseada em `Window`, teclado e mouse foi removida no Sprint 2.

Implementação da fundação: `core/application/app_root.tscn` é a cena principal.
`AppRoot` conecta `GameController`, `SaveService`, `ScreenRouter`, gestos,
`MobileSafeArea`, `MobileShell`, áudio e providers de analytics/config.
`MobileHotelPanels` constrói as telas de gestão e emite comandos sem alterar a
sessão. `MobileLabels` traduz projeções causais de check-in, elevador, hóspedes e
reviews; `HotelAnalytics` permanece uma projeção somente de leitura. `AppRoot`
encaminha construção, upgrade, tarifa, contratação, assignment e demolição ao
controller, que faz checkpoint após o comando. Confirmações são sheets Control.

`MobileDisplayScale` converte resolução física/densidade em unidades lógicas no
Android/iOS antes de criar a interface. `MobileSafeArea` converte os insets físicos
nessa mesma escala. Targets têm altura mínima de 48 unidades; contexto fica abaixo
do hotel em portrait e ao lado em landscape/tablet. Câmera preserva o slot da prévia
e mantém o alvo contextual visível quando o painel muda a área do hotel.

`HapticService` adapta a vibração opcional do dispositivo. Preferências de idioma,
texto, som e vibração são persistidas separadamente sem apagar outras preferências.
`HotelAudio` libera playback e stream ao suspender o app ou remover a cena.

### Platform

Integrações que não podem contaminar o domínio:

- Android/iOS lifecycle;
- billing;
- rewarded ads;
- restore purchases;
- analytics;
- crash reporting;
- cloud save futuro;
- notificações futuras.

## Input

`HotelView` encaminha eventos ao controlador de gestos mobile.

```
InputEvent
→ MobileInputController
→ Gesture/Command
→ HotelView ou GameController
```

Gestos base:

- tap: selecionar/confirmar;
- drag: pan;
- pinch: zoom;
- long press: ação contextual opcional;
- Android back: fechar overlay/voltar.

## Economia

Existem duas economias distintas.

### HotelEconomy

- cash;
- revenue;
- expenses;
- salaries;
- maintenance;
- operational profit.

### PlayerEconomy

- Gems;
- Empire Points;
- speedups;
- boosters;
- cosméticos;
- entitlements.

Nunca usar Gems diretamente dentro de `HotelEconomy`.

## Monetização

```
Gameplay
→ MonetizationService
   ├── Mock provider no editor
   ├── Ads provider
   └── Store provider
```

`HotelSession` não chama SDK de publicidade nem de compra.

## Save

Evoluir `SaveStore` e `SessionSnapshot` para um `SaveService` com:

- autosave;
- atomic write;
- backup;
- recovery;
- schema version;
- migration;
- lifecycle checkpoint;
- player economy;
- entitlements;
- timers de construção;
- timestamps;
- estado de offline progress.

Compras consumíveis e entitlements exigem validação idempotente.

Implementado no Sprint 1: `AtomicJSONStore` é compartilhado por `SaveStore` e
`SaveService`. O envelope mobile v1 contém `saved_at_utc`, snapshot do hotel v7 e
`app_state` primitivo para módulos da aplicação. Boot tenta primary/backup e migra
save legado sem apagar o original. Ambos corrompidos bloqueiam escrita; versão
futura válida bloqueia downgrade. Save após recovery preserva backup válido.
`GameController` executa autosave mesmo com speed zero e para em background.
O nome interno `Hotel Empire` permanece estável para preservar o diretório de saves.

Ainda pendente: módulos premium, entitlements, timers e settlement offline. Não
considerar `app_state` vazio como implementação desses sistemas.

## Offline progress

Não simular horas de ausência tick a tick.

Usar cálculo agregado e determinístico baseado em snapshot de:

- capacidade;
- ocupação;
- receita;
- custos;
- eficiência;
- tempo ausente;
- limite de offline time.

Timers de construção e upgrades usam tempo absoluto persistido.

## Rendering

Preservar o modelo de renderização enxuto sempre que possível.

Evitar transformar cada hóspede em uma árvore pesada de Nodes se o desenho customizado atual for mais eficiente.

Separar frequências:

- simulação: fixed tick;
- atualização de métricas/UI: frequência menor;
- render: adaptativo.

## Assets

O catálogo atual faz preload de muitas texturas. A arquitetura mobile deve migrar para carregamento por grupo/tema quando necessário.

Metas:

- budgets de RAM/VRAM;
- size limits por categoria;
- compressão mobile;
- atlas/spritesheets quando houver ganho real;
- unload entre hotéis/mapas.

## Localização

Nenhuma string nova de produto deve ser hardcoded em GDScript.

Usar chaves de tradução e arquivos de locale desde a reconstrução da UI.

## Testabilidade

Preservar testes de domínio independentes de UI.

Criar adaptadores mock para:

- Ads;
- IAP;
- analytics;
- remote config;
- clock/time;
- lifecycle.

## Regra de dependência

```
Platform → Application → Domain
Presentation → Application → Domain

Domain ✕ Platform
Domain ✕ SDK
Domain ✕ UI
```
