# Changelog

## M9 — regressão integrada pós-arte, 30/09/2026
- 31 suítes passaram após integrar os 70 PNGs, incluindo 30 dias e save/load.
- Runner com prazo por processo e relatório consolidado em sucesso/falha.
- Preview de repouso usa limites reais do playfield e escala da captura;
  quatro poses comparadas em seis camas, sem cortar a linha superior com texto ampliado.
- Logs originais e proveniência preservados em docs/benchmarks/m9.

## M7 — extensão de personagens e estados, 30/09/2026
- Catálogo atual com 70 PNGs: pinturas próprias por nível, espera, trabalho,
  repouso da equipe e ciclos de serviço dos hóspedes.
- Quartos aguardando limpeza têm pinturas N1/N2/N3 e retorno à versão limpa.
- Filas seguem visualmente as reservas, com grupos por andar no elevador.
- Cinco retratos dedicados ao inspetor e rolagem automática ao selecionar pessoas.
- Imports de ícones/retratos limitados a 256/512px, com fontes originais intactas:
  redução medida de 94,61 MiB no monitor de vídeo e inspeção da UI em janela 4K.
- Dois ícones dedicados à contratação e ao funcionário selecionado no painel
  de atribuições, com custo/salário em texto nativo e limpeza da imagem em lista vazia.
- Seis ícones dedicados aos botões de construção, com objetos legíveis em 36px,
  filtragem com mipmaps e preço/nome em texto nativo.
- Três ícones raster dedicados aos comandos de andar, melhoria e demolição,
  importados a 256px e desenhados em 32px, com mouse/Enter e custos verificados.
- Hóspedes chegam e saem com malas próprias por perfil, com quatro poses de
  viagem, contexto no elevador e espelhamento ancorado nos sapatos.
- Original raster gerado no chat; prompts, hashes e capturas em docs/art.

## M9 — continuidade longa
- Seis cenários de 30 dias com orçamento inicial, procura natural e 30 checkpoints de save/load.
- Runner -Soak e relatório econômico reprodutível para hotéis de dois/oito quartos.
- Referência solvente; satisfação e decisões de gestão ainda em avaliação, sem mudar regras.

## M8 concluído / início de QA M9
- Perfil integrado contínuo: 118–120 hóspedes nas regras atuais, serviços e HUD em 1x/3x.
- P95 local abaixo de 6 ms no cenário de demanda controlada; limitações registradas.
- Não amplia o limite do jogo nem afirma operação sustentada de 1000 hóspedes.
- QA do diálogo Novo hotel: cancelar, confirmar, restaurar fundos e preservar/recarregar save.

## M8 — admissão e saídas
- Filtra recepções uma vez por step e evita buscar quarto para visitantes sem reserva.
- Equivalência de snapshots com referência anterior em três seeds e save/load.
- P95 de sobrecarga com alvo 1000: 83,35 para 9,28 ms neste hardware.
- Perfil da cena real com HUD registra queda da população após rejeições;
  operação preenchida sustentada continua pendente.

## M8a — visibilidade e perfil inicial
- Descarte conservador de desenhos fora da câmera, preservando simulação e arte.
- Perfil de render para 100/250/500/1000 hóspedes e sobrecarga de chegadas.
- Comparação pixel a pixel em nove câmeras; resultados/limites documentados.
- M8 continua pendente de picos de simulação e perfil integrado com HUD.

## M7 — arte raster e animação
- 15 PNGs originais: cinco interiores, elevador modular, corredor, cidade, passeio
  e cinco spritesheets transparentes de hóspedes/equipe.
- Caminhada de quatro poses, espelhamento, âncora dos pés, mipmaps e miniaturas.
- Três efeitos sonoros originais, botão Som e preferência independente do save.
- Teste visual dedicado, alpha/recortes/ciclo/zoom e proveniência dos assets.
- Poses específicas de serviço e trilha musical permanecem fora desta entrega.

## M6 — interface operacional
- Painel Operação (F2): métricas atuais, filtros por tipo/andar/situação e inspeção
  de salas com centralização da câmera, incluindo navegação por teclado.
- Busca de construção sem distinção de acentos, categorias e feedback sem resultados.
- Texto ampliado (F4) com preferência separada do save; foco visível/retorno dos modais,
  barra que reorganiza controles e Finanças com rolagem.
- Estados de hóspedes/equipe em português; utilidades técnicas aparecem apenas no debug.
- Testes de projeções sem mutação, preferências, busca, filtros e fluxos de teclado.

## M5 — serviços, hóspedes e eventos
- Café Brisa e Sala Horizonte liberados pelos objetivos existentes, com construção
  protegida no modelo e serviços integrados a fila, pagamento e necessidades.
- Três GuestArchetype: equilibrado, negócios e lazer; escolhas por alívio efetivo,
  orçamento e preferências. Inspeção mostra perfil e contagem de serviços.
- Feira da cidade e Dias tranquilos: calendário determinístico, previsão no HUD,
  alterações temporárias de procura, pausa e fechamento de chegadas respeitados.
- Snapshot v4 migra perfis/contadores de v1–v3; refeições separadas de lazer.
- Suítes de conteúdo e interface, cenários com três seeds e limites documentados.

## M4 — progressão
- Três objetivos orientados a dados, com requisitos visíveis, N3 por desempenho e título final.
- Construção básica/N2 livres; desbloqueios permanentes, sem prêmio monetário repetível.
- Painel Objetivos com progresso atual, aviso de conclusão e motivo de bloqueio no inspetor.
- Snapshot v3 com migrações v1/v2 e preservação do acesso prévio a N3.
- Relatório headless registra conquistas e ticks; doze suítes aprovadas, incluindo migração
  real M3, fluxo gráfico e progressão com caixa inicial de $12.000.

## M3 — gestão do hotel
- Upgrades N2/N3 em quatro instalações, com comparação, custos e manutenção efetivos.
- Equipe com recepções/andares preferidos e modo automático, preservando tarefas em curso.
- Preço contratado protegido durante upgrades; finanças mostram custos fixos diários.
- Snapshot v2 com migração de v1 e validação das novas invariantes.
- Suítes de gestão e interface; dez suítes aprovadas, incluindo stress e retomada.

## 0.1.0 em desenvolvimento — 2026-09-16
- Auditoria inicial: sem projeto Godot, cenas, código de jogo ou Git.
- Preservada a visão do produto e as configurações/skills locais.
- Fundação: Godot 4.7.2 Compatibility, Resources de quatro salas, economia e FIFO.
- Plano incremental, arquitetura e critérios de validação documentados.
- M1a: construção validada, andares, poços, demolição, seleção, HUD e câmera.
- QA com entrada real no viewport e testes automatizados de construção.
- M1b–c: tick fixo, hóspedes/utility simples, atendimento, receita, despesas,
  filas, elevadores FIFO com capacidade, contratação, limpeza e reputação.
- Inspeção de agentes, diagnóstico de filas e controles de operação/tempo.
- M1d: snapshots v1, backup, validação transacional, restauração de viagens e RNG,
  novo hotel, finanças, debug F3, save Ctrl+S e pausa por Espaço.
- Corrigidos ciclo de referências, deriva do relógio, satisfação de visitantes
  recusados e seleção de elevador fora dos limites do hotel.
- Bateria completa e retomada em outro processo aprovadas.

## M2 — robustez e medição
- Comando `--simulate` com templates, seed, duração, orçamento e chegadas configuráveis;
  JSON de economia, satisfação, ocupação, filas, transporte, memória e tempo de tick.
- Cinco seeds, 20 checkpoints de save e stress isolado de 100/250/500/1000 passageiros.
- Corrigida divergência após load em limites temporais: resíduo decimal na porta do
  elevador atrasava o transporte em um tick; demais temporizadores usam a mesma tolerância.
- JSON de save utiliza precisão completa. Comparações de estado mantêm estados/contagens
  exatos e tolerância absoluta 1e-8 para resíduos de floats.
- Relatórios reproduzíveis de 30 dias e burst de 1000 hóspedes registrados em docs/benchmarks.
