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

- [x] tap, drag e pinch pela rota de eventos GUI/viewport;
- [x] seleção contextual de sala, hóspede e funcionário;
- [x] HUD e bottom navigation responsivos;
- [x] sheets de gestão: construção, operações, tarifas, upgrade, finanças, reviews e missões;
- [x] contratação e assignments por toque com checkpoint;
- [x] confirmação de construção/demolição e cancelamento por back sem gasto;
- [x] scroll/pan/modal sem comandos acidentais, inclusive drag iniciado sobre botão;
- [x] remoção de main, HUD, Window, hotkeys e harness/testes desktop;
- [x] layout celular/tablet, cutouts, texto ampliado, três idiomas e densidades 1x/2x/3x;
- [x] feedback háptico opcional, áudio suspenso em background e preferências persistidas;
- [x] verificações úteis de pixels, sprites, bagagens, hit targets e culling portadas;
- [x] 28 suítes aprovadas, 3.992 verificações renderizadas, 83 capturas e APK de debug reconstruído: `docs/SPRINT2_VALIDATION.json`.

Saída: core gameplay herdado completo por toque. Operação manual/onboarding
entram no Sprint 3. Ergonomia, vibração física, rotação/safe area do OS e QA
Android/iOS em aparelho continuam gates do Sprint 15.

## Sprint 3 — O jogador trabalha no hotel

- [x] guia não bloqueante, versionado e retomável por fatos do hotel;
- [x] perfil mobile novo com 2.400 Cash, sem reduzir patrimônio de saves existentes;
- [x] jogador físico: caminhada, elevadores e uma tarefa por vez, sem salário;
- [x] recepção manual FIFO usando a mesma admissão e cobrança dos funcionários;
- [x] limpeza manual com reserva exclusiva e contagem agregada dos objetivos;
- [x] room service: pedido real, capacidade/FIFO de preparação, preço acordado e entrega;
- [x] desgaste por uso, eficiência até 20% mais lenta e reparo com custo operacional;
- [x] cancelamento libera reservas sem cobrança/benefício e preserva passageiro embarcado;
- [x] snapshot v8 e migração v1–v7; checkpoints de início/transição/conclusão/background;
- [x] ações de 1,5–3 segundos no alvo, feedback, controles prioritários e tradução;
- [x] ícones raster individuais originais para reparo/room service, com import de 128 px;
- [x] gate final: 31 suítes, 4.274 verificações renderizadas, 98 capturas + revisão dos ícones e APK 0.5.0 reconstruído (`docs/SPRINT3_VALIDATION.json`).

Implementação: [PLAYER_WORK](docs/PLAYER_WORK.md). Cinco sementes sob política
guiada: primeira hospedagem em 3,5–3,7 segundos e contratação em 96–135,5 segundos.
Isso mede a política simulada; ergonomia humana permanece no Sprint 15.

Saída: early game ativo e pessoal, mantendo intervenção após contratar.

## Sprint 4 — Equipe e Automação

- [x] recepcionista e camareiro como os dois papéis essenciais ao loop inicial;
- [x] contratação com quatro perfis fixos, custos e efeitos comparáveis por toque;
- [x] salários derivados de nível/traços, pagos por dia e preservados durante pausa;
- [x] XP somente por tarefa válida e níveis 1–5 com eficiência/qualidade derivadas;
- [x] até dois traços relevantes, sem RNG, reroll ou contratação por moeda premium;
- [x] assignments por recepção/andar, prioridade de limpeza e pausa após tarefa atual;
- [x] desligamento confirmado, sem reembolso, saída física e IDs não reutilizados;
- [x] jogador continua cobrindo gargalos sem contar na equipe ou folha salarial;
- [x] projeção de departamentos, pendências e delegação como base da supervisão;
- [x] snapshot v9, migração v1–v8 e checkpoints de promoção/conclusão/desligamento;
- [x] cinco sementes: redução de 100% das intervenções centrais após 600s, preservando 91–100% das hospedagens sob política com capital de giro;
- [x] gate final: 33 suítes, 4.499 verificações renderizadas, 113 capturas, 27 scripts validados e APK Android debug 0.6.0 sem warnings (`docs/SPRINT4_VALIDATION.json`).

Implementação: [STAFF_AUTOMATION](docs/STAFF_AUTOMATION.md). Manutenção, cozinha e
room service especializados permanecem na Sprint 9; supervisores/gerentes continuam
no crescimento do produto. A projeção desta sprint não simula esses cargos.

Saída: transição clara de trabalhador para gestor.

## Sprint 5 — Construção Mobile

- [x] timers;
- [x] fila;
- [x] dois slots gratuitos;
- [x] construção offline com reserva/pagamento persistido e resumo de retorno;
- [x] upgrades temporizados mantendo operação no nível anterior;
- [ ] N1–N5 quando aplicável;
- [ ] especializações;
- [x] speedups gratuitos em inventário global, consumo confirmado e persistência atômica.

A integração de timers/fila/save/GUI tem evidência própria em
`docs/SPRINT5_INTEGRATION_VALIDATION.json`. Ainda não conclui a sprint.
Speedups têm evidência própria em `docs/SPRINT5_SPEEDUP_VALIDATION.json` e contrato
em `docs/PLAYER_INVENTORY.md`. O inventário mínimo foi antecipado do Sprint 6 por
dependência das obras; Gems, Empire Points e seus sources/sinks permanecem naquele
sprint, e providers de rewarded/IAP continuam no Sprint 7.
Settlement econômico offline e seu resumo precisam de política/balanceamento antes
do gate completo; snapshots de obra não concedem receita ou salários inventados.

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
