# Changelog — Hotel Empire Mobile

Este changelog começa na separação da versão mobile. O histórico de desenvolvimento e validação do protótipo desktop permanece no repositório original de PC.

## Em andamento — Sprint 5

- ProgressClock adiciona tempo monotônico para deadlines e ausência persistida,
  com proteção de rollback, watermark e resume idempotente. Checkpoint durante
  background preserva o intervalo a ser liquidado no retorno.
- Componente isolado passou em 35 verificações determinísticas pelo gda estrito.
  ConstructionService adiciona dois slots gratuitos, fila, reservas de terreno,
  capital pago uma vez, cancelamento com estorno e deadlines agregados. Upgrades e
  andares aguardam conclusão. Restore valida a fila sem alterar estado em caso de erro.
- Núcleo de construção passou em 162 verificações; as 11 suítes de domínio
  preservadas passaram. Ainda pendem integração, speedups, N4/N5, especializações
  e settlement offline do hotel;
  o fluxo de construção do produto continua no estado validado da Sprint 4.

## 0.6.0-mobile — Equipe e delegação

- Recepcionista e camareiro ganham XP somente por tarefas concluídas, níveis 1–5,
  eficiência/qualidade e salários derivados. Evolução individual preserva as
  definições compartilhadas; pausa mantém salário.
- Contratação oferece quatro perfis fixos com até dois traços relevantes e custos
  comparáveis por toque. Qualidade da recepção afeta satisfação; limpeza concede
  bônus consumido uma vez na próxima hospedagem. Sem RNG ou moeda premium.
- Assignments, prioridade por idade/proximidade, pausa após tarefa e supervisão
  de pendências/departamentos. O jogador continua cobrindo gargalos manualmente.
- Desligamento confirmado libera reservas, respeita viagem de elevador, sai pelo
  térreo e encerra salário após saída física, sem reembolso ou XP de cancelamento.
- Snapshot v9 migra v1–v8 sem inventar XP/traços. Checkpoints persistem conclusões,
  promoções e saídas. Dados contraditórios e futuros continuam bloqueados.
- Comparação multiseed mantém caixa não negativo e 91–100% das hospedagens,
  eliminando intervenções de recepção/limpeza após 600s sob a política medida.
- Gate final: 33 suítes, 4.499 verificações renderizadas, 113 capturas e 27 scripts
  validados. Casos originais de operação manual preservados em helper carregado em
  runtime; saída não zero, erros e vazamentos continuam reprovando os executores.
- APK Android debug 0.6.0/code 4 reconstruído sem warnings. Evidências/hashes em
  `docs/SPRINT4_VALIDATION.json`. Aparelhos, lojas e iOS permanecem gates do release.

## 0.5.0-mobile — Jogador e primeiro hotel

- PlayerWorkSystem adiciona um jogador físico, com caminhada/elevadores, uma tarefa
  por vez e trabalho sem salário. Check-in compartilha admissão/cobrança com staff;
  limpeza reserva alvo e conta nos objetivos existentes.
- Pedidos de room service usam hóspedes hospedados, fila/capacidade de alimentação,
  preparação, percurso e entrega. Preço acordado, orçamento, receita, refeição e
  alívio de fome são aplicados uma vez na entrega válida.
- Instalações se desgastam pelo uso. Reparo simples restaura condição/eficiência,
  com materiais cobrados como despesa operacional na conclusão.
- Cancelamento libera reservas sem recompensa; passageiros terminam a viagem.
  Save de domínio v8 preserva tarefas, timers, pedidos e condição; migra v1–v7.
- Perfil novo começa com 2.400 Cash e guia de nove fatos, sem alterar saves existentes.
  Guia pode ser ocultado/retomado. Checkpoints protegem tarefas e etapas, inclusive
  background/kill. Dados contraditórios/futuros não substituem saves válidos.
- HUD mostra Você, fase, tempo, condição, motivos e cancelamento prioritário.
  PT-BR/EN/ES; dois ícones raster originais e individuais importados a 128 px.
- Simulação guiada multiseed chega à primeira contratação sem dinheiro injetado;
  suíte touch percorre guia e quatro ações em portrait, landscape e tablet.
  Evidência final em `docs/SPRINT3_VALIDATION.json`.

## 0.4.0-mobile — Gestão por toque

- Gestão herdada portada para sheets Control: categorias de construção,
  operações/filtros, tarifas, upgrades, contratação, assignments, finanças,
  diagnósticos, reviews, objetivos e preferências.
- Construção e demolição por confirmação explícita, com cancelamento por back.
  Gestos de pan/pinch/scroll e drag iniciado sobre botão não gastam Cash.
- Removidos main/HUD/panels desktop, hotkeys, wheel/middle mouse e 19 testes de UI
  antigos após portar sua cobertura útil. Domínio e migrations preservados.
- Contexto abaixo/lateral sem cobrir o hotel; slot da prévia e seleção continuam
  visíveis. Layout de 320x568 a tablet, PT-BR/EN/ES, cutouts e texto ampliado.
- Escala pela densidade do OS, targets e scroll de 48 unidades, navegação de uma
  linha em landscape curto e feedback compacto para preservar a área de contexto.
- Idioma, som, texto e haptic persistidos sem apagar outras preferências.
  Áudio libera stream/playback em background; feedback háptico é opcional.
- Regressões de sprites, poses, âncoras, bagagem, hit targets e culling portadas;
  fluxo de gestão usa ScreenTouch/ScreenDrag pela GUI real do viewport.
- Evidências e hashes em `docs/SPRINT2_VALIDATION.json`; APK Android debug 0.4.0.
  Operação manual/onboarding é Sprint 3. SDKs, aparelhos, iOS e signing de produção
  continuam pendentes do escopo seguinte e do release gate.

## 0.3.0-mobile — Fundação Mobile

- AppRoot substitui o entry point desktop; GameController mantém a sessão e o fixed tick.
- SaveService adiciona envelope de aplicação v1 sobre domínio v7, autosave 30s,
  checkpoint de comandos/lifecycle e recovery automático. Migrations e arquivos
  legados são preservados; dados corrompidos/futuros não são sobrescritos.
- Writer atômico compartilhado protege o backup válido após corrupção do primary.
- Adicionados tap, pan, pinch, cancel e supressão de eventos de mouse emulados.
- ScreenRouter, shell responsivo, sheets Control e safe area substituem o fluxo principal de janelas.
- Localização PT-BR/EN/ES e atualização de controles na troca de idioma.
- Analytics/config desacoplados com providers indisponíveis e mocks, fila limitada e configuração com ranges.
- Criados presets Android/iOS e APK Android de debug sem warnings, com ETC2/ASTC.
- Validação local: 21 suítes aprovadas, 128 verificações renderizadas, 12 screenshots em quatro dimensões/três idiomas.
- Ainda pendentes: paridade de gestão touch (Sprint 2), sistemas de produto seguintes,
  instalação/kill pelo OS, iOS em macOS/Xcode, SDKs e signing de produção. Não é release candidate.

## 0.2.1-mobile — Sprint 0 técnico

- Removidos preset Windows e ferramentas de distribuição, pacote e compatibilidade desktop sem leitores no runtime.
- Preservados domínio, migrations/fixtures e ferramentas de balanceamento.
- Criado executor portátil via gda com isolamento de save, timeout e relatórios com hash.
- Inventariados 82 PNGs e imports com ferramenta reproduzível; 54 sem limite de importação.
- Baseline de 17 suítes aprovada, incluindo stress, save multiseed e estudos de 30 dias.
- Regressão após reset: as mesmas 17 suítes aprovadas sem diagnostics.
- Classificados testes desktop para substituição; verificações úteis de arte/culling serão portadas.
- Preservado prompt integral e documentada autonomia de validação e decisões de monetização inicial.

## 0.2.0-mobile — documentação e replanejamento

### Produto

- Reposicionamento do repositório como Hotel Empire Mobile.
- Definida fantasia de progressão de funcionário a dono de uma rede.
- Definidos core loop e meta loop.
- Definidos hotéis por estrelas, prestige/franquia e Empire Points.
- Reservas antecipadas, eventos, reviews procedurais, manutenção e room service entram no plano de produto.

### Monetização

- Modelo Rewarded-first.
- Ads voluntários.
- Hotel Cash, Gems e Empire Points separados.
- Planejados Starter Pack, Gems, Remove Ads e cosméticos.
- Hotel Pass adiado para pós-validação de retenção.

### Arquitetura

- Domínio de simulação será preservado.
- UI/input desktop serão substituídos por camada touch-first.
- MonetizationService, SaveService, AnalyticsService e adapters de plataforma serão independentes do domínio.
- Offline progress será agregado, não tick-a-tick por horas.

### UX

- Planejados bottom navigation, bottom sheets, tap, drag e pinch.
- Orientação landscape versus portrait será validada por protótipo em dispositivo.
- Safe area e tablets passam a ser requisitos.

### Performance

- Identificado backlog de otimização de texturas e preloads.
- Performance, memória, boot e bateria passam a ser gates de release.

### Documentação

- Removida a documentação de validação/release desktop desta árvore.
- Criado conjunto documental focado exclusivamente em Android/iOS.
