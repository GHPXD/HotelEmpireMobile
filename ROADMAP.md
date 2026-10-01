# Roadmap — Hotel Empire Mobile

Este roadmap organiza a transformação do protótipo herdado em produto mobile.

## Sprint 0 — Reset Mobile

Objetivo: remover o legado documental de desktop e estabelecer contratos mobile.

- [x] auditoria do repositório;
- [x] nova documentação mobile;
- [ ] remover pipeline/referências técnicas exclusivamente desktop quando a migração de código iniciar;
- [ ] classificar testes em domínio, desktop-obsoleto e mobile-novo;
- [ ] estabelecer baseline antes da primeira refatoração.

Saída: repo documentalmente mobile-first.

## Sprint 1 — Fundação Mobile

- AppRoot;
- GameController;
- SaveService;
- ScreenRouter;
- MobileInputController;
- lifecycle;
- autosave;
- exports Android/iOS;
- safe areas;
- protótipo landscape x portrait.

Saída: build real em dispositivo com save/resume.

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
