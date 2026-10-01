# Roadmap — Hotel Empire Mobile

Este roadmap organiza a transformação do protótipo herdado em produto mobile.

O contrato de execução completo está em [MOBILE_MIGRATION_BRIEF](docs/MOBILE_MIGRATION_BRIEF.md).
São 16 etapas, numeradas de 0 a 15. O objetivo continua sendo a migração integral.
Reorganizações por dependências devem ser registradas aqui, sem reduzir escopo.
O agente executa testes e validações intermediárias; o usuário testa no Sprint 15.
Mocks e testes headless não substituem evidência de SDKs, lojas e aparelhos reais.

### Gates de execução

- Sprint 0: baseline de domínio/stress/estudos, inventário e remoção do pipeline desktop.
- Sprints 1–2: aplicação mobile, persistência/lifecycle, gestos e core loop por touch.
- Sprints 3–6: operação manual, automação, timers/offline e economia global separada.
- Sprints 7–13: monetização opcional, retenção, hotel vivo, planejamento, império, cosméticos e telemetria.
- Sprints 14–15: medição/otimização, integrações reais e release verificável.

PlayerEconomy e clock podem ganhar contratos antes dos Sprints 5–6 quando necessários
para timers/save; isso não conclui antecipadamente suas integrações de produto.

## Sprint 0 — Reset Mobile

Objetivo: remover o pipeline desktop e estabelecer baseline técnica mobile.

- [x] auditoria do repositório;
- [x] nova documentação mobile;
- [x] remover scripts de distribuição/pacote/compatibilidade Windows e preset desktop;
- [x] classificar testes em domínio, desktop-obsoleto e mobile-novo (`docs/TEST_MIGRATION_MATRIX.md`);
- [x] inventariar assets com referências, imports e estimativa de memória (`tools/audit_mobile_assets.py`);
- [x] estabelecer baseline antes da primeira refatoração (17 suítes; `docs/SPRINT0_BASELINE.json`);
- [x] regressão pós-reset: mesmas 17 suítes aprovadas, sem diagnostics.

Saída: pipeline desktop removido, ferramentas de domínio preservadas e baseline verificada.

## Sprint 1 — Fundação Mobile

- [x] AppRoot como cena principal, separado da apresentação desktop;
- [x] GameController como dono da sessão e do fixed tick;
- [x] SaveService com envelope da aplicação v1 sobre domínio v7 e migrations preservadas;
- [x] ScreenRouter com uma screen e um sheet contextual;
- [x] MobileInputController: tap, pan, pinch, cancel e supressão de mouse emulado;
- [x] lifecycle com checkpoint e suspensão da simulação; focus-in não resume app pausado pelo OS;
- [x] autosave a cada 30 segundos, inclusive com simulação pausada;
- [x] presets Android/iOS; APK Android de debug exportado sem warnings;
- [x] safe area com conversão de pixels para unidades da UI;
- [x] protótipos landscape/portrait/tablet, quatro dimensões e três idiomas;
- [x] providers indisponíveis e mocks de analytics/remote config, sem SDK no domínio;
- [x] gate final: 21 suítes aprovadas (17 preservadas + 4 mobile), 128 verificações renderizadas e 12 capturas; `docs/SPRINT1_VALIDATION.json`.

Saída: APK executável e configuração iOS preparada quando toolchain externa impedir
build local; save/resume validado por testes. Instalação/kill real pelo Android OS e
iOS precisam de evidência própria. Não há AVD/imagem Android ou device conectado
neste host; iOS requer macOS/Xcode, template iOS e Team ID. Esses gates continuam
pendentes no Sprint 15, sem solicitar teste do usuário nas sprints intermediárias.

Contratos de recompensa/compra e seus mocks entram no Sprint 7, após PlayerEconomy
e timers: a fundação não inventa entrega de moedas nem simula compra na loja.
O shell inicial é um protótipo integrado; paridade total da UI herdada é Sprint 2.

## Sprint 2 — UX Touch-First

- tap;
- drag;
- pinch;
- seleção contextual;
- HUD mobile;
- bottom navigation;
- bottom sheets;
- remoção da dependência de janelas/atalhos desktop;
- layout celular/tablet;
- feedback háptico quando adequado.

Saída: core gameplay completo por toque.

## Sprint 3 — O jogador trabalha no hotel

- onboarding;
- recepção/check-in manual;
- limpeza manual;
- room service simples;
- reparo simples;
- primeiros objetivos;
- ações curtas, sem minigames longos.

Saída: early game ativo e pessoal.

## Sprint 4 — Equipe e Automação

- funcionários essenciais;
- contratação;
- salários;
- XP/nível;
- traits limitados;
- assignments;
- jogador pode cobrir gargalos;
- base de supervisão/automação futura.

Saída: transição clara de trabalhador para gestor.

## Sprint 5 — Construção Mobile

- timers;
- fila;
- slots;
- construção offline;
- upgrades temporizados;
- N1–N5 quando aplicável;
- especializações;
- speedups.

Saída: loop temporal mobile completo.

## Sprint 6 — Economia F2P

- Hotel Cash;
- Gems;
- Empire Points;
- PlayerEconomy;
- sources/sinks;
- proteção de save;
- custos e curvas de progressão.

Saída: economia preparada para monetização.

## Sprint 7 — Monetização v1

- MonetizationService;
- rewarded ads;
- Gems packs;
- Starter Pack;
- Remove Ads;
- restore purchases;
- mocks;
- telemetria de funil.

Saída: monetização funcional e opcional.

## Sprint 8 — Retenção e Progressão

- ★–★★★★★;
- missões principais;
- secundárias;
- diárias;
- unlocks;
- recompensas;
- objetivos de eficiência/satisfação/lucro.

Saída: sempre existe próximo objetivo.

## Sprint 9 — Hotel Vivo

- reviews procedurais;
- manutenção;
- incidentes;
- room service completo;
- grupos de hóspedes;
- VIPs;
- gargalos com feedback legível.

Saída: simulação produz histórias.

## Sprint 10 — Eventos e Planejamento

- eventos aleatórios;
- eventos por mapa;
- reservas antecipadas;
- aceitar/recusar;
- congressos;
- casamentos;
- excursões;
- contratos simples.

Saída: sessões exigem antecipação e reação.

## Sprint 11 — Império Hoteleiro

- cinco estrelas;
- franquia/prestige;
- Empire Points;
- bônus permanentes;
- segundo hotel;
- diferenças reais por mapa;
- rede.

Saída: meta-loop fechado.

## Sprint 12 — Personalização e Loja

- cosméticos;
- loja;
- fachadas;
- uniformes;
- temas;
- bundles cosméticos.

Saída: monetização de expressão.

## Sprint 13 — Analytics e Balanceamento

- schema de eventos;
- funis;
- coortes;
- economia;
- rewarded;
- IAP;
- remote config;
- experimentos controlados.

Saída: decisões orientadas por dados.

## Sprint 14 — Performance Mobile

- budgets de textura;
- redução das texturas sem size limit;
- carregamento por grupo;
- memory tiers;
- bateria;
- boot;
- low/mid/high devices;
- stress real em Android/iOS.

Saída: performance previsível.

## Sprint 15 — Release Candidate

- QA Android/iOS;
- billing real;
- consent/privacy;
- crash reporting;
- restore;
- background/kill;
- migração de save;
- store metadata;
- release checklist.

Saída: build publicável.

## Pós-lançamento

Somente após validar retenção e economia:

- Hotel Pass;
- temporadas;
- LiveOps avançado;
- concorrentes;
- vigilância/segredos profundos;
- tecnologia expandida;
- elevadores especiais;
- novos hotéis.
