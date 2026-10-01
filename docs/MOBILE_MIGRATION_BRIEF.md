/goal

Você é o engenheiro principal, arquiteto de software, game designer técnico e responsável pela execução da migração completa do repositório:

https://github.com/GHPXD/HotelEmpireMobile

Seu objetivo é transformar o projeto existente, atualmente derivado da versão PC de Hotel Empire, em um produto mobile-first completo, comercialmente viável, tecnicamente sólido e preparado para lançamento em Android e iOS.

Você deve trabalhar diretamente sobre o repositório existente, preservando o que já foi validado na simulação e reconstruindo aquilo que foi projetado especificamente para desktop.

======================================================================
1. FONTE DE VERDADE
======================================================================

Antes de modificar código, leia integralmente e trate como documentação oficial do projeto:

- README.md
- ARCHITECTURE.md
- GAME_DESIGN.md
- ROADMAP.md
- TEST_PLAN.md
- ASSET_GUIDE.md
- CHANGELOG.md
- docs/PRODUCT_MOBILE.md
- docs/ECONOMY_MONETIZATION.md
- docs/UX_MOBILE.md
- docs/ANALYTICS_LIVEOPS.md
- docs/TEST_RELEASE_MOBILE.md
- docs/MIGRATION.md

Esses documentos representam o produto mobile atual.

Documentação, decisões ou estruturas antigas específicas da versão desktop/Windows não devem prevalecer sobre esses documentos.

Sempre que código e documentação divergirem durante a migração, primeiro determine se o código ainda representa legado PC. Se representar, adapte o código à especificação mobile em vez de enfraquecer a nova especificação para preservar comportamento desktop.

======================================================================
2. MISSÃO DO PRODUTO
======================================================================

Hotel Empire Mobile não deve ser um simples port do jogo de PC.

Ele deve ser um jogo mobile reconstruído sobre o motor de simulação existente.

A fantasia central de progressão é:

Eu faço tudo sozinho
→ contrato meu primeiro funcionário
→ formo uma equipe
→ automatizo setores
→ contrato supervisores
→ contrato gerentes
→ administro departamentos
→ conquisto cinco estrelas
→ franquio/vendo o hotel
→ abro um novo hotel
→ construo uma rede de hotéis
→ construo um império hoteleiro.

O jogador começa próximo da operação e termina acima dela.

O mobile deve simplificar a INTERAÇÃO sem simplificar excessivamente a SIMULAÇÃO.

======================================================================
3. PRINCÍPIOS INEGOCIÁVEIS
======================================================================

1. Mobile-first.
2. Touch-first.
3. Simulação profunda e interface simples.
4. Progressão clara.
5. Rewarded Ads voluntários.
6. Monetização não deve substituir gameplay.
7. Sem pay-to-win.
8. Offline-friendly.
9. Performance mobile é requisito de produto.
10. Arquitetura modular.
11. Sistemas de plataforma nunca contaminam o domínio.
12. Sempre preservar testabilidade.
13. Não criar dívida técnica apenas para terminar uma sprint.
14. Não transformar o jogo em um idle tycoon genérico.
15. Cada novo sistema deve interagir com outros sistemas quando isso fizer sentido.
16. O jogo deve produzir histórias emergentes a partir da simulação.
17. O jogador deve conseguir entender POR QUE um problema ocorreu.
18. O jogador sempre deve ter algo relevante para fazer.
19. Timers não devem transformar o jogo em espera.
20. Monetização deve ser mensurável e configurável.

======================================================================
4. REGRA ABSOLUTA DE ARTE E ÍCONES
======================================================================

Esta regra é obrigatória em TODO o projeto.

NUNCA usar como arte final:

- emoji;
- caracteres Unicode usados como ícones;
- ícones de sistema genéricos;
- Material Icons;
- Font Awesome;
- Bootstrap Icons;
- Lucide;
- Heroicons;
- Feather;
- icon packs;
- assets gratuitos genéricos;
- clip-art;
- placeholders visuais;
- SVGs genéricos baixados;
- formas que claramente pareçam um ícone padrão de biblioteca;
- imagens stock;
- arte procedural genérica sem direção visual;
- assets que deem aparência de template ou “AI slop”.

Exemplos proibidos:

❌ botão com "💎"
❌ botão com "💰"
❌ botão com "⭐"
❌ botão com "🏨"
❌ botão usando ícone padrão de settings
❌ coração Unicode como energia
❌ Material Symbols
❌ SVG baixado de biblioteca
❌ substituir arte ausente por caracteres

Se um botão, moeda, recurso, ação ou sistema precisar de um ícone novo:

CRIE UM ASSET ORIGINAL ESPECÍFICO PARA ELE.

Cada ícone deve ser tratado como um asset real de produção.

Crie os ícones UM POR UM.

Não criar uma sprite sheet genérica com dezenas de ícones improvisados.

Não usar o mesmo desenho levemente modificado para representar sistemas diferentes.

Os novos assets devem respeitar a identidade visual da arte existente do Hotel Empire.

Antes de criar um asset novo:

1. examine os assets existentes em assets/art/;
2. entenda proporções, contornos, iluminação, textura, cores e linguagem visual;
3. identifique como os ícones atuais foram produzidos;
4. crie uma peça original coerente com essa direção;
5. gere o arquivo final individual;
6. configure corretamente seu import;
7. conecte-o ao sistema;
8. teste em tamanho real de UI.

Preferência de runtime:

- PNG transparente original;
- resolução apropriada;
- import mobile configurado;
- sem resolução excessiva.

Se um asset precisar ser criado programaticamente porque não há ferramenta gráfica disponível no ambiente, ainda assim ele deve ser um desenho ORIGINAL criado especificamente para Hotel Empire, exportado para raster final e revisado visualmente.

Não substituir a ausência de ferramenta gráfica por um ícone genérico.

O visual deve parecer produzido para este jogo, não retirado de uma biblioteca.

======================================================================
5. O QUE DEVE SER PRESERVADO DA BASE ATUAL
======================================================================

Preservar e evoluir, salvo evidência técnica concreta em contrário:

- HotelSession;
- HotelModel;
- RoomState;
- RoomDefinition;
- GuestSystem;
- EmployeeSystem;
- TransportSystem;
- ServiceQueue;
- HotelEconomy;
- sistema de needs;
- hóspedes;
- filas;
- transporte;
- satisfação;
- reputação;
- reviews;
- lógica de serviços;
- construção;
- upgrades;
- eventos;
- fixed simulation tick;
- save versionado;
- migrations;
- backup/recovery;
- testes de domínio;
- ferramentas úteis de balanceamento.

Não reescrever um sistema funcional apenas porque uma implementação diferente parece mais elegante.

Refatore quando houver benefício concreto de:

- mobile;
- manutenção;
- performance;
- testabilidade;
- desacoplamento;
- escalabilidade.

======================================================================
6. O QUE DEVE SER SUBSTITUÍDO
======================================================================

A camada desktop deve desaparecer gradualmente.

Substituir dependências de:

- mouse esquerdo;
- mouse direito;
- botão do meio;
- mouse wheel;
- hover obrigatório;
- teclado;
- F1/F2/F3/F4;
- Ctrl+F;
- Ctrl+S;
- Espaço;
- desktop Window;
- diálogos de desktop;
- toolbar de desktop;
- sidebar fixa de desktop;
- workflow manual Salvar/Carregar como UX principal;
- encerramento estilo desktop;
- testes focados exclusivamente em teclado/janelas Windows;
- pipeline de distribuição Windows deste repositório mobile.

Não manter comportamentos desktop apenas por compatibilidade histórica.

Este repositório tem como plataformas de produto:

ANDROID
e
iOS.

======================================================================
7. ARQUITETURA ALVO
======================================================================

Evoluir para aproximadamente:

AppRoot
│
├── GameController
│   └── HotelSession
│
├── SaveService
├── OfflineProgressService
├── PlayerEconomy
├── MissionService
├── PlayerProgressionService
├── ContentService
├── MobileInputController
├── ScreenRouter
├── AudioService
├── AnalyticsService
├── RemoteConfigService
│
└── MonetizationService
    ├── AdsService
    ├── PurchaseService
    └── EntitlementService

Regra de dependência:

Platform
↓
Application
↓
Domain

Presentation
↓
Application
↓
Domain

PROIBIDO:

Domain → SDK de Ads
Domain → StoreKit/Google Billing
Domain → Analytics Provider
Domain → UI
Domain → Android/iOS APIs

HotelSession não deve saber o que é AdMob, App Store, Google Play, RevenueCat ou qualquer provider comercial.

======================================================================
8. ECONOMIAS
======================================================================

Separar claramente:

HOTEL ECONOMY

Responsável por:

- cash;
- receita;
- despesas;
- salários;
- manutenção;
- investimento;
- lucro operacional.

PLAYER ECONOMY

Responsável por:

- Gems;
- Empire Points;
- Speedups;
- boosters;
- cosméticos;
- entitlements;
- itens permanentes.

Nunca armazenar Gems como apenas mais um campo de HotelEconomy.

Hotel Cash pode ser contextual ao hotel.

Gems e progressão permanente pertencem à conta/progresso global.

======================================================================
9. MONETIZAÇÃO
======================================================================

Modelo inicial:

Rewarded-first.

Rewarded Ads podem oferecer:

- redução de timer;
- aumento de recompensa offline;
- multiplicador moderado de missão;
- speed boost temporário;
- equipe emergencial;
- marketing temporário;
- VIP/evento;
- reroll limitado;
- recuperação situacional balanceada.

Regra:

O anúncio é SEMPRE escolha explícita.

Nunca abrir rewarded automaticamente.

Nunca bloquear progressão base até o jogador assistir anúncio.

Nunca tornar assistir anúncio permanentemente mais eficiente do que dominar o jogo.

IAP inicial:

- Small Gems Pack;
- Medium Gems Pack;
- Large Gems Pack;
- Starter Pack;
- Remove Ads;
- Cosmetic Packs.

Hotel Pass não deve ser prioridade inicial.

Só implementar Hotel Pass quando houver:

- boa retenção;
- conteúdo recorrente;
- calendário;
- eventos;
- quantidade suficiente de rewards;
- justificativa operacional.

======================================================================
10. CONSTRUÇÃO E TIMERS
======================================================================

Construções deixam de ser instantâneas.

Referência:

ONBOARDING
10 s
20 s
30 s
60 s

EARLY
1–5 min

MID
5–30 min

LATE
1–4 h apenas em investimentos relevantes.

Evite transformar cada construção em várias horas.

O jogador sempre deve ter outras atividades relevantes enquanto timers estão ativos.

Cada timer pode ser resolvido por:

- esperar;
- Rewarded para reduzir;
- Speedup;
- Gems para concluir ou avançar.

Construção e upgrades devem continuar com app fechado.

Persistir timestamps de forma robusta.

======================================================================
11. OFFLINE PROGRESS
======================================================================

Nunca simular várias horas de ausência usando milhões de simulation ticks.

Offline progress deve usar cálculo agregado.

Exemplo de inputs:

- capacidade;
- ocupação;
- revenue rate;
- custos;
- staff efficiency;
- reputação;
- hotel state;
- duração offline;
- cap de offline time.

Ao retornar, mostrar resumo compreensível:

- receita;
- despesas;
- lucro;
- construções concluídas;
- upgrades concluídos;
- eventos relevantes.

Rewarded pode aumentar resultado, mas recompensa base precisa ser justa.

======================================================================
12. GAMEPLAY INICIAL — JOGADOR COMO FUNCIONÁRIO
======================================================================

Este é um dos principais diferenciais da versão mobile.

No início:

- pequeno hotel;
- pouco dinheiro;
- nenhuma equipe;
- poucas instalações.

O próprio jogador:

- atende recepção;
- realiza check-in;
- limpa quartos;
- entrega room service;
- resolve reparos simples;
- atende algumas emergências/VIPs.

Essas ações devem ser curtas e agradáveis.

Evitar minigames excessivamente longos ou repetitivos.

Objetivo:

dar peso emocional e mecânico à contratação.

Progressão:

fazer sozinho
→ contratar
→ delegar
→ automatizar
→ supervisionar.

Mesmo no late game, permitir intervenção manual opcional em gargalos.

======================================================================
13. FUNCIONÁRIOS
======================================================================

Papéis possíveis ao longo do produto:

- recepcionista;
- camareiro;
- manutenção;
- garçom;
- cozinheiro;
- segurança;
- concierge;
- técnico;
- supervisor;
- gerente.

Não implementar todos de uma vez.

Começar pelos papéis necessários ao loop atual.

Funcionário pode possuir:

- nível;
- XP;
- salário;
- eficiência;
- qualidade;
- até dois traits relevantes.

Traits possíveis:

- carismático;
- perfeccionista;
- ágil;
- experiente;
- preguiçoso;
- desorganizado;
- noturno;
- workaholic.

Não transformar staff em RPG com dezenas de atributos.

Cada atributo deve alterar uma decisão real.

======================================================================
14. SALAS E UPGRADES
======================================================================

Expandir gradualmente N1–N3 para até N1–N5.

Upgrades podem:

- aumentar capacidade;
- melhorar velocidade;
- melhorar conforto;
- reduzir custo;
- alterar público;
- desbloquear funcionalidade.

Criar especializações quando fizer sentido.

Exemplo:

EXECUTIVO

- tarifa maior;
- preferência business;
- expectativa maior.

CONFORTO

- satisfação;
- estadia maior.

ECONÔMICO

- manutenção menor;
- ocupação maior;
- tarifa menor.

Evitar upgrades que sejam apenas "+10%, +20%, +30%" sem alterar decisões.

======================================================================
15. ESTRELAS E PROGRESSÃO DO HOTEL
======================================================================

Cada hotel:

★
★★
★★★
★★★★
★★★★★

Critérios possíveis:

- reputação;
- ocupação;
- satisfação;
- receita;
- lucro;
- serviços;
- eficiência;
- objetivos especiais.

Estrelas devem:

- desbloquear conteúdo;
- marcar progressão;
- alterar percepção visual/status;
- preparar próximo ciclo.

★★★★★ permite concluir/franquear/prestigiar o hotel quando os requisitos forem atendidos.

======================================================================
16. IMPÉRIO E PRESTIGE
======================================================================

Ao concluir um hotel:

o jogador pode franquear/vender.

Recebe Empire Points.

Mantém:

- Gems;
- cosméticos;
- entitlements;
- progressão permanente;
- bônus globais.

Inicia novo hotel com contexto diferente.

Hotéis futuros podem incluir:

- Hotel Familiar;
- Downtown Hotel;
- Hotel Executivo;
- Beach Resort;
- Mountain Resort;
- Luxury Tower;
- Grand Hotel.

Não tratar os hotéis como skins.

Cada hotel deve mudar:

- demanda;
- público;
- instalações;
- eventos;
- estratégia;
- desafios;
- layout quando adequado.

======================================================================
17. MISSÕES
======================================================================

Criar estrutura para:

- main missions;
- side missions;
- daily missions;
- weekly challenges;
- event missions.

Season Missions somente no futuro.

Exemplos:

- hospedar hóspedes;
- limpar quartos;
- atingir faturamento;
- manter reputação;
- completar upgrades;
- sobreviver a evento;
- preparar reserva;
- resolver gargalo.

Missão deve incentivar gameplay saudável e ensinar sistemas.

======================================================================
18. EVENTOS
======================================================================

Eventos não podem ser apenas:

"+10% dinheiro por 5 minutos".

Devem gerar decisões.

Possíveis eventos:

- vigilância sanitária;
- incêndio;
- apagão;
- vazamento;
- elevador quebrado;
- inspeção;
- greve;
- casamento;
- congresso;
- excursão;
- celebridade;
- influenciador;
- equipe esportiva;
- temporada turística;
- baixa temporada.

Exemplo:

VIGILÂNCIA SANITÁRIA

Possíveis decisões:

- fechar cozinha temporariamente;
- continuar operando e assumir risco;
- contratar inspeção/emergência;
- resolver falhas antes da visita.

Consequências devem vir da simulação.

======================================================================
19. EVENTOS POR MAPA
======================================================================

Exemplos:

COSTA
- terremoto;
- incêndio;
- festival;
- celebridade.

TROPICAL
- furacão;
- tempestade;
- alta temporada;
- casamentos.

MONTANHA
- neve;
- temporada de esqui;
- avalanche.

METRÓPOLE
- congressos;
- shows;
- protestos/eventos urbanos;
- business flow.

JAPÃO
- terremotos;
- festivais;
- períodos turísticos.

Não usar estereótipos ofensivos ou caricaturas.

======================================================================
20. GRUPOS E RESERVAS
======================================================================

Suportar grupos progressivamente:

- casais;
- famílias;
- excursões;
- empresas;
- times;
- congressos;
- casamentos;
- VIPs.

Grupos podem chegar juntos e criar pressão real na infraestrutura.

RESERVAS ANTECIPADAS devem ser feature importante.

Exemplo:

TechCon
42 hóspedes
chegada amanhã
receita potencial alta.

O jogador decide:

ACEITAR
ou
RECUSAR.

Depois precisa preparar:

- quartos;
- recepção;
- restaurantes;
- elevadores;
- staff.

A reserva deve realmente usar esses sistemas quando chegar.

======================================================================
21. ROOM SERVICE
======================================================================

Room Service nunca deve ser apenas um botão que gera receita.

Fluxo:

pedido
→ cozinha/restaurante
→ preparação
→ garçom/funcionário
→ caminho
→ elevador
→ andar
→ quarto
→ entrega
→ satisfação
→ receita.

Isso deve criar trade-offs reais.

Mais room service:

+ receita
+ satisfação potencial
- capacidade da cozinha
- disponibilidade do staff
- tráfego de elevador.

======================================================================
22. REVIEWS PROCEDURAIS
======================================================================

Gerar avaliações usando eventos reais da visita.

Possíveis componentes:

- espera;
- limpeza;
- comida;
- conforto;
- preço;
- elevador;
- atendimento;
- incidente;
- serviço.

Reviews devem comunicar causalidade.

Evitar reviews aleatórios sem relação com o que aconteceu.

Exemplo:

"Esperei muito tempo pelo elevador."

Só deve ser gerado se houve espera relevante de elevador.

======================================================================
23. MANUTENÇÃO
======================================================================

Adicionar gradualmente desgaste em:

- elevadores;
- cozinha;
- geradores;
- ar-condicionado;
- equipamentos importantes.

Manutenção preventiva:

custa dinheiro agora,
reduz risco depois.

Negligência pode gerar:

- quebra;
- interrupção;
- evento;
- queda de satisfação;
- custo emergencial.

======================================================================
24. INCIDENTES E SEGREDOS
======================================================================

Não implementar inicialmente um sistema enorme estilo Beholder.

Começar como incidentes de hóspedes:

- crítico secreto;
- celebridade;
- ladrão;
- festa clandestina;
- animal escondido;
- hóspede problemático;
- VIP secreto;
- comportamento suspeito.

Possíveis ações:

- observar;
- investigar;
- ignorar;
- chamar segurança;
- intervir.

Se o sistema provar valor, evoluir posteriormente para mecânica de observação/privacidade mais profunda.

======================================================================
25. COSMÉTICOS
======================================================================

Categorias possíveis:

- fachada;
- piso;
- papel de parede;
- móveis;
- elevadores;
- uniformes;
- recepção;
- temas completos.

Fontes:

- gameplay;
- achievements;
- eventos;
- compra;
- futuro Hotel Pass.

Cosméticos pagos não devem ser requisito para operação competitiva.

======================================================================
26. UX MOBILE
======================================================================

Reconstruir interface.

Base sugerida:

TOP BAR
- cash;
- reputação/estrelas;
- hóspedes;
- Gems.

CENTRO
- hotel.

BOTTOM NAVIGATION
- Hotel;
- Construir;
- Missões;
- Equipe;
- Loja.

Usar:

- bottom sheets;
- context panels;
- overlays leves.

Evitar:

- múltiplas Windows;
- desktop toolbar;
- desktop sidebar;
- popups empilhados.

======================================================================
27. GESTOS
======================================================================

Tap:
- selecionar;
- construir;
- confirmar.

Drag:
- mover câmera.

Pinch:
- zoom.

Long press:
- apenas se realmente melhorar UX.

Android back:

1. fecha overlay;
2. fecha screen;
3. volta;
4. saída só quando apropriado.

Resolver cuidadosamente conflito entre:

- pan da câmera;
- ScrollContainer;
- tap;
- pinch;
- drag em UI.

======================================================================
28. ORIENTAÇÃO
======================================================================

NÃO assumir portrait automaticamente.

Criar/prototipar landscape e portrait.

Comparar em dispositivo:

- leitura do hotel;
- quantidade de quartos visíveis;
- andares;
- personagens;
- elevadores;
- bottom sheet;
- uso com polegar;
- tablets.

Escolher com base em experiência real.

A arquitetura deve evitar tornar uma possível adaptação futura desnecessariamente difícil.

======================================================================
29. SAFE AREA E ACESSIBILIDADE
======================================================================

Suportar:

- notch;
- camera cutout;
- gesture bar;
- cantos arredondados;
- tablets.

Também:

- touch targets adequados;
- contraste;
- texto escalável;
- feedback não dependente apenas de cor;
- ícone + texto em ações críticas;
- movimento reduzido quando aplicável.

======================================================================
30. LOCALIZAÇÃO
======================================================================

Não adicionar novas strings de produto hardcoded.

Criar infraestrutura de localization.

Usar keys.

Exemplo:

ui.build
ui.upgrade
mission.first_guests
error.insufficient_cash
room.bedroom.name

Preparar pelo menos arquitetura para:

- PT-BR;
- EN;
- ES.

Não é obrigatório traduzir todo o jogo na primeira sprint de infraestrutura, mas não continuar criando dívida de strings hardcoded.

======================================================================
31. ANALYTICS
======================================================================

Implementar camada desacoplada.

Eventos planejados:

LIFECYCLE
- app_open
- session_start
- session_end
- background
- resume

TUTORIAL
- tutorial_start
- tutorial_step
- tutorial_complete
- tutorial_abandon

GAMEPLAY
- room_build_started
- room_build_completed
- room_upgrade_started
- room_upgrade_completed
- staff_hired
- staff_upgraded
- mission_completed
- star_earned
- hotel_completed
- prestige_completed

ECONOMIA
- soft_currency_earned
- soft_currency_spent
- premium_currency_earned
- premium_currency_spent
- speedup_used

ADS
- rewarded_offer_viewed
- rewarded_started
- rewarded_completed
- rewarded_failed
- rewarded_reward_granted

IAP
- store_viewed
- purchase_started
- purchase_success
- purchase_cancelled
- purchase_failed
- restore_started
- restore_completed

RESERVAS/EVENTOS
- reservation_offered
- reservation_accepted
- reservation_declined
- reservation_result
- event_started
- event_choice
- event_completed

Não coletar PII desnecessária.

Falha de analytics nunca pode impedir gameplay.

======================================================================
32. PERFORMANCE
======================================================================

A base herdada possui muitos PNGs grandes e várias texturas sem size limit.

Isso precisa ser corrigido.

Investigar:

- source resolution;
- imported resolution;
- RAM;
- GPU memory;
- mipmaps;
- compressão;
- draw cost;
- boot;
- loading.

Criar budgets para:

- low-tier Android;
- mid-tier Android;
- high-tier Android;
- iPhones compatíveis;
- tablets.

Não otimizar apenas para a máquina de desenvolvimento.

======================================================================
33. ESTRATÉGIA DE ASSETS
======================================================================

O catálogo atual faz preload de muitos assets.

Evoluir progressivamente para agrupamento/carregamento contextual quando necessário.

Possível divisão:

CommonAssets
HotelThemeAssets
RoomAssets
GuestAssets
StaffAssets
UIAssets

Não fazer lazy loading excessivamente complexo antes de medir.

Primeiro medir.

Depois otimizar.

======================================================================
34. SIMULAÇÃO E BATERIA
======================================================================

Preservar fixed tick.

Separar frequências quando possível:

simulation tick
≠
UI refresh
≠
render request.

Não chamar redraw desnecessariamente a cada frame se nada visual mudou.

Quando app estiver:

- background;
- pausado;
- em overlay que congela simulação;

reduzir processamento de forma adequada.

======================================================================
35. SAVE E LIFECYCLE
======================================================================

Evoluir save atual, não jogar fora.

Criar SaveService com:

- autosave;
- atomic save;
- backup;
- recovery;
- migration;
- lifecycle save;
- checkpoint;
- timer persistence;
- PlayerEconomy;
- entitlements;
- offline timestamp.

Testar:

- minimizar app;
- OS matar processo;
- bateria acabar;
- update;
- reinstall quando aplicável;
- corrupção;
- callback de compra durante lifecycle transition.

Botão "Salvar" não deve ser necessário no fluxo mobile normal.

======================================================================
36. TESTES
======================================================================

PRESERVAR testes úteis de domínio:

- foundation;
- construction;
- simulation;
- save;
- management;
- progression;
- reviews;
- stress;
- tariffs e estudos úteis.

Substituir testes desktop específicos de:

- F-keys;
- teclado;
- wheel;
- middle mouse;
- Window;
- resoluções desktop.

Criar testes para:

- touch;
- gesture;
- safe area;
- lifecycle;
- offline;
- Ads;
- IAP;
- restore;
- callbacks duplicados;
- save migration;
- economy invariants.

Nunca remover um teste de domínio apenas para fazer uma refatoração passar.

Corrija o código ou atualize o teste somente quando o comportamento esperado realmente mudou de acordo com a especificação mobile.

======================================================================
37. INVARIANTES DE MONETIZAÇÃO
======================================================================

Garantir:

- Gems nunca ficam negativas;
- reward não duplica;
- purchase callback duplicado é idempotente;
- purchase success não perde entrega;
- restore funciona para non-consumables;
- entitlement sobrevive de acordo com a plataforma;
- HotelEconomy não é manipulada diretamente por SDK;
- timers não podem ser concluídos duas vezes;
- prestige não apaga premium currency;
- prestige não apaga cosméticos;
- prestige não apaga entitlement.

======================================================================
38. ROADMAP DE IMPLEMENTAÇÃO
======================================================================

Execute as sprints NA ORDEM, salvo dependência técnica concreta.

----------------------------------------------------------------------
SPRINT 0 — RESET MOBILE TÉCNICO
----------------------------------------------------------------------

Objetivo:
limpar o legado técnico desktop restante e criar baseline seguro.

Tarefas:

- revisar estado atual após o reset documental;
- remover scripts/pipelines exclusivos de Windows que não tenham uso mobile;
- remover preset Windows quando seguro;
- classificar testes:
  - preservar domínio;
  - remover/substituir desktop;
  - criar mobile;
- garantir que nenhuma exclusão quebre runtime;
- inventariar assets usados;
- registrar baseline dos testes de domínio;
- atualizar docs/MIGRATION.md conforme progresso.

Não remover ferramenta de balanceamento útil apenas porque nasceu durante desenvolvimento PC.

Critério de saída:

- repo sem dependência operacional de pipeline Windows;
- domínio preservado;
- baseline de testes conhecido;
- documentação e código apontando para mobile.

----------------------------------------------------------------------
SPRINT 1 — FUNDAÇÃO MOBILE
----------------------------------------------------------------------

Criar:

- AppRoot;
- GameController;
- SaveService;
- ScreenRouter;
- MobileInputController;
- hooks de lifecycle;
- autosave;
- safe area;
- estrutura Android;
- estrutura iOS;
- mocks de serviços externos.

Prototipar:

- portrait;
- landscape.

Não integrar monetização real ainda se a fundação não estiver pronta.

Critério:

build executável em mobile ou configuração completa de export quando toolchain externa impedir build local.

----------------------------------------------------------------------
SPRINT 2 — UX TOUCH-FIRST
----------------------------------------------------------------------

Substituir fluxos desktop.

Implementar:

- tap;
- drag;
- pinch;
- selection;
- camera;
- top bar;
- bottom navigation;
- bottom sheets;
- mobile HUD;
- screen transitions;
- mobile settings;
- touch-first construction.

Remover dependência de:

- F1/F2/F3/F4;
- Ctrl;
- middle mouse;
- wheel;
- Window UI.

Critério:

todo core loop atual utilizável apenas por touch.

----------------------------------------------------------------------
SPRINT 3 — JOGADOR TRABALHA NO HOTEL
----------------------------------------------------------------------

Criar novo onboarding.

Jogador executa manualmente:

- recepção;
- check-in;
- limpeza;
- room service inicial;
- reparos simples.

Criar controles e feedback próprios.

Não criar minigames longos.

Critério:

primeiros minutos têm gameplay ativo e progressão perceptível.

----------------------------------------------------------------------
SPRINT 4 — EQUIPE E AUTOMAÇÃO
----------------------------------------------------------------------

Implementar inicialmente papéis essenciais.

Adicionar:

- contratação;
- salários;
- assignments;
- nível;
- XP;
- traits;
- delegação;
- jogador cobrindo gargalos;
- progressão rumo à automação.

Critério:

contratar funcionário muda significativamente o que o jogador precisa fazer manualmente.

----------------------------------------------------------------------
SPRINT 5 — CONSTRUÇÃO MOBILE
----------------------------------------------------------------------

Implementar:

- timers;
- fila;
- slots;
- upgrade timers;
- timestamps persistidos;
- conclusão offline;
- speedups;
- N4/N5 onde fizer sentido;
- especializações iniciais.

Critério:

todo ciclo de construção funciona online/offline e sobrevive a restart.

----------------------------------------------------------------------
SPRINT 6 — ECONOMIA F2P
----------------------------------------------------------------------

Criar:

- PlayerEconomy;
- Gems;
- Empire Points;
- Speedups;
- sources;
- sinks;
- persistência;
- migrations;
- testes.

Balancear primeiro rascunho de:

- Cash;
- salários;
- manutenção;
- construções;
- upgrades;
- progressão.

Critério:

economia operacional e premium completamente separadas.

----------------------------------------------------------------------
SPRINT 7 — MONETIZAÇÃO V1
----------------------------------------------------------------------

Criar arquitetura de provider e mocks.

Implementar:

Rewarded Ads
- timer;
- offline bonus;
- missões;
- boosts limitados.

IAP
- Gems;
- Starter Pack;
- Remove Ads;
- Cosmetic Pack inicial;
- restore.

Analytics correspondente.

Nunca colocar chamada de SDK no domínio.

Critério:

gameplay continua integralmente jogável sem pagar.

----------------------------------------------------------------------
SPRINT 8 — RETENÇÃO E PROGRESSÃO
----------------------------------------------------------------------

Implementar:

- ★–★★★★★;
- main missions;
- side missions;
- daily missions;
- unlocks;
- rewards;
- achievements iniciais;
- milestones;
- progress UI.

Critério:

o jogador sempre entende o próximo objetivo.

----------------------------------------------------------------------
SPRINT 9 — HOTEL VIVO
----------------------------------------------------------------------

Implementar:

- reviews procedurais;
- manutenção;
- incidentes;
- room service completo;
- grupos de hóspedes;
- VIPs;
- feedback de gargalo;
- causalidade legível.

Critério:

o hotel produz acontecimentos e histórias a partir da simulação.

----------------------------------------------------------------------
SPRINT 10 — EVENTOS E PLANEJAMENTO
----------------------------------------------------------------------

Implementar:

- eventos aleatórios;
- eventos específicos de mapa;
- reservas antecipadas;
- aceitar/recusar;
- congressos;
- casamentos;
- excursões;
- contratos simples.

Critério:

planejamento futuro muda as decisões presentes.

----------------------------------------------------------------------
SPRINT 11 — IMPÉRIO HOTELEIRO
----------------------------------------------------------------------

Implementar:

- conclusão ★★★★★;
- prestige/franquia;
- Empire Points;
- bônus permanentes;
- segundo hotel;
- diferenças de mapa;
- progressão global.

Critério:

concluir um hotel abre um novo ciclo de jogo significativo.

----------------------------------------------------------------------
SPRINT 12 — PERSONALIZAÇÃO E LOJA
----------------------------------------------------------------------

Implementar:

- fachada;
- pisos;
- uniformes;
- recepções;
- temas;
- cosméticos;
- inventory;
- ownership;
- equip;
- store presentation;
- cosmetic bundles.

Todos os ícones e assets necessários devem seguir a REGRA ABSOLUTA DE ARTE.

Critério:

há monetização relevante não ligada a poder.

----------------------------------------------------------------------
SPRINT 13 — ANALYTICS E BALANCEAMENTO
----------------------------------------------------------------------

Completar:

- analytics schema;
- funil;
- economy telemetry;
- ad telemetry;
- IAP telemetry;
- retention telemetry;
- Remote Config;
- dashboards/specs;
- ferramentas internas de balanceamento.

Não hardcode dezenas de variáveis de economia se elas puderem ser Data Resources ou config.

Critério:

é possível entender abandono, gargalos e comportamento econômico.

----------------------------------------------------------------------
SPRINT 14 — PERFORMANCE MOBILE
----------------------------------------------------------------------

Fazer auditoria real.

Otimizar:

- texturas;
- size limits;
- compressão;
- preload;
- memory;
- frame time;
- redraw;
- boot;
- loading;
- bateria;
- population stress;
- tablets.

Não degradar qualidade visual sem medir necessidade.

Critério:

performance previsível em tiers definidos.

----------------------------------------------------------------------
SPRINT 15 — RELEASE CANDIDATE
----------------------------------------------------------------------

Preparar:

- Android;
- iOS;
- billing;
- ads production configuration;
- consent/privacy;
- crash reporting;
- restore;
- save migration;
- lifecycle;
- store metadata;
- screenshots;
- icon;
- release QA.

Validar requisitos das lojas na época efetiva do release.

Critério:

build publicável.

======================================================================
39. PÓS-LANÇAMENTO
======================================================================

Não implementar antes de justificar com dados:

- Hotel Pass;
- temporadas complexas;
- concorrentes profundos;
- espionagem estilo Beholder completa;
- privacidade/vigilância profunda;
- tech tree gigantesca;
- dezenas de elevadores especiais;
- sistemas sociais complexos.

Eles pertencem ao backlog pós-validação.

======================================================================
40. FORMA DE TRABALHO
======================================================================

Para cada sprint:

1. leia a documentação relevante;
2. audite o código envolvido;
3. identifique dependências;
4. defina o menor conjunto arquitetural correto;
5. implemente;
6. teste;
7. corrija regressões;
8. atualize documentação;
9. atualize CHANGELOG;
10. registre o que foi concluído no ROADMAP;
11. só então avance.

Não marque tarefa como concluída sem implementação funcional.

Não crie documentação dizendo que algo existe quando ainda é apenas plano.

Use checkboxes do ROADMAP de forma verdadeira.

======================================================================
41. COMMITS E ALTERAÇÕES
======================================================================

Faça commits coesos.

Exemplos:

feat(mobile): add touch camera controller
refactor(save): introduce lifecycle-safe SaveService
feat(economy): add player premium economy
feat(ads): add rewarded provider abstraction
perf(assets): enforce mobile texture budgets
test(mobile): add lifecycle regression coverage

Evite mega-commit com dezenas de sistemas não relacionados.

Antes de alterações destrutivas:

- confirme referências;
- procure usos;
- preserve migrations necessárias;
- preserve dados importantes.

======================================================================
42. NÃO FAZER
======================================================================

Não:

- recomeçar projeto do zero sem necessidade;
- remover simulação profunda;
- converter Hotel Empire em clone genérico de idle hotel;
- colocar anúncios obrigatórios;
- usar emojis como interface;
- usar ícones genéricos;
- usar SVG genérico;
- baixar icon pack;
- usar stock art;
- deixar placeholder visual na implementação final;
- misturar Gems com Hotel Cash;
- misturar provider SDK com HotelSession;
- simular 8h offline tick a tick;
- manter UX de desktop escondida atrás de botões mobile;
- criar dezenas de features sem testes;
- excluir testes só porque falharam após refatoração;
- usar timers absurdos apenas para vender Gems;
- adicionar assinatura/Pass antes de haver produto que justifique;
- implementar tudo em um único script;
- aumentar main.gd indefinidamente;
- hardcodar novos textos de produto sem localization;
- marcar sprint como completa pela metade.

======================================================================
43. QUALIDADE DE UI
======================================================================

Toda tela deve parecer deliberadamente desenhada para Hotel Empire.

Evitar:

- cards genéricos demais;
- excesso de gradientes;
- neon sem propósito;
- glassmorphism gratuito;
- botões iguais para tudo;
- bordas arredondadas em excesso;
- ícones de biblioteca;
- números sem hierarquia;
- layout que pareça dashboard SaaS;
- aparência de template Flutter/React;
- aparência de jogo mobile genérico.

A UI deve nascer da linguagem visual do hotel e da arte existente.

Cada componente deve responder:

- qual informação ele prioriza?
- qual ação ele permite?
- qual estado ele comunica?
- por que ele ocupa esse espaço?

======================================================================
44. DEFINITION OF DONE GERAL
======================================================================

Uma feature não está pronta apenas porque compila.

Ela está pronta quando:

- funciona;
- integra com o sistema;
- possui feedback adequado;
- não quebra save;
- possui testes proporcionais ao risco;
- funciona com touch;
- funciona com lifecycle;
- respeita arquitetura;
- respeita performance;
- respeita localização;
- respeita identidade visual;
- não introduz placeholder genérico;
- documentação foi atualizada.

======================================================================
45. PRIORIDADE DE DECISÃO
======================================================================

Se duas soluções forem possíveis, priorize nesta ordem:

1. integridade da simulação;
2. experiência do jogador;
3. clareza;
4. robustez de save/economia;
5. performance mobile;
6. testabilidade;
7. escalabilidade;
8. monetização saudável;
9. velocidade de implementação.

Não sacrifique os primeiros itens apenas para desenvolver mais rápido.

======================================================================
46. PRIMEIRA AÇÃO
======================================================================

Comece pelo estado atual da branch main.

Leia toda a documentação mobile.

Depois:

1. faça uma nova auditoria curta do estado real do repo contra o Sprint 0;
2. identifique exatamente o legado técnico desktop que ainda resta;
3. preserve testes e ferramentas de domínio úteis;
4. execute o Sprint 0 técnico;
5. rode/verifique as regressões possíveis;
6. atualize ROADMAP, MIGRATION e CHANGELOG;
7. avance para Sprint 1 somente quando Sprint 0 realmente estiver concluído.

A partir daí, siga o roadmap sequencialmente.

Não fique apenas produzindo planos.

IMPLEMENTE.

Quando encontrar uma decisão não especificada:

- primeiro procure na documentação;
- depois procure no código atual;
- preserve o espírito do produto;
- escolha a opção mais coerente e documente a decisão.

Evite interromper o trabalho com perguntas quando uma decisão técnica segura puder ser inferida destas regras.

Pare para solicitar decisão humana apenas quando houver:

- escolha de produto irreversível;
- custo financeiro externo;
- credencial necessária;
- conta de loja/provider necessária;
- ação externa que não possa ser simulada;
- conflito real entre requisitos.

O objetivo final é entregar uma versão de Hotel Empire concebida desde o início como um excelente jogo mobile, preservando a profundidade sistêmica do original e adicionando progressão, retenção e monetização de forma natural, sem sacrificar identidade, qualidade visual ou integridade técnica.