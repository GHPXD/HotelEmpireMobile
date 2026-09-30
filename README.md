# Hotel Empire

Tycoon 2D original em Godot **4.7.2**, GDScript tipado, renderer Compatibility.
Estado: **M0–M9** implementados e validados no protótipo desktop: simulação, gestão,
interface, arte raster original, animações e efeitos sonoros. Export Windows
validado localmente; M10 aguarda compatibilidade em outra máquina e revisão manual.
O balanceamento de produção permanece aberto.

Abra `project.godot` no Godot e execute F6 na cena principal ou F5 no projeto.
Teste: `godot --headless --path . --script res://tests/foundation_test.gd`.
Importe antes de testar em checkout novo: `godot --headless --editor --path . --quit`.

Construção: selecione sala na lateral e clique no grid. Recepção somente no térreo.
Novo andar custa $750; poços ocupam todos os andares. Esc/clique direito cancela.
Scroll ajusta zoom; botão central arrasta a câmera. Clique numa sala para inspecionar
e use Demolir para removê-la, sem reembolso. Contrate recepcionista e camareiro(a),
depois abra o hotel. Hóspedes escolhem serviços, viajam e pagam; quartos usados
aguardam limpeza. Clique nos personagens para inspecionar necessidades e estado.
Pausa/1x/2x/3x controlam o tempo. Fechar chegadas permite esvaziar o hotel.
Espaço pausa/retoma; F3 mostra debug. Salvar (ou Ctrl+S) preserva a sessão em
`user://hotel-v1.json`; Carregar restaura inclusive filas e viagens em andamento.
Novo hotel pede confirmação e preserva o arquivo salvo. Finanças exibe extrato e
custos fixos diários de manutenção e salários.

Operação (F2) mostra ocupação, limpeza, filas, maior espera atual e custos do hotel.
Filtre salas por tipo, andar e situação; selecione uma e pressione Enter para
inspecionar e centralizar a câmera. Os indicadores resumem o hotel inteiro;
os filtros afetam apenas a lista, ordenada pela maior fila.

Ctrl+F leva à busca de construção, que aceita nomes com ou sem acentos; o seletor
de categoria reduz o catálogo. F4 alterna texto padrão/ampliado e salva a preferência
do dispositivo em `user://interface.cfg`, separada da partida. Tab navega controles;
Esc fecha os painéis e devolve foco ao botão de abertura. Finanças tem rolagem.

Selecione uma sala ou elevador para comparar e comprar upgrades até N3 no inspetor
(role a lateral para baixo). Equipe permite fixar recepcionistas em recepções e
camareiros em andares, ou voltar ao automático. Uma nova preferência não cancela
viagem ou limpeza em andamento. Saves usam schema v7 e migram arquivos v1–v6;
o nome `hotel-v1.json` foi mantido para encontrar partidas anteriores.

Objetivos mostra requisitos e recompensas. Três reservas liberam N3 de quartos e
recepções; dez reservas, cinco refeições e cinco limpezas liberam N3 de bistrôs e
elevadores. Depois, vinte visitas concluídas e reputação 65 concedem o título
Hotel de referência. Desbloqueios são permanentes, mas upgrades continuam pagos.
N2 e construção básica são livres. Partidas anteriores mantêm o acesso a N3.

Primeiras estadias também libera o Café Brisa; Operação completa libera a Sala
Horizonte. O café atende fome rapidamente, com menor alívio que o bistrô; a sala
atende entretenimento. Esses dois serviços possuem apenas N1 neste incremento.
Hóspedes equilibrados, de negócios e de lazer variam orçamento e preferências;
clique no personagem para ver seu perfil. A localização e a demanda afetam o uso.

O calendário alterna Feira da cidade (+50% na procura) e Dias tranquilos (-35%).
Um evento começa a cada três dias simulados e dura um dia, sem sobreposição.
A faixa abaixo dos controles mostra a próxima ocorrência ou o evento ativo;
passe o mouse para ler o efeito. Pausar congela o calendário; fechar chegadas
impede visitantes novos durante eventos, mas o tempo continua correndo.

Sugestão inicial: recepção e bistrô no térreo, elevador em coluna livre, outro andar
com vários quartos. Contrate os dois tipos de funcionário antes de abrir chegadas.
Poucos quartos criam fila na recepção; expansão excessiva pressiona transporte e limpeza.

No Windows deste ambiente: `powershell -File tools/test.ps1 -Visual` executa import,
11 suítes headless e 18 testes gráficos. Passe `-GodotPath` para outro engine.
Testes isolam dados em `.runtime/`; não sobrescrevem seu save normal.
O runner limita cada processo a 120s (`-SuiteTimeoutSeconds` ajusta o prazo) e
grava revisão, opções, duração, resumos e hashes dos logs em `.runtime/test-run-report.json`.
Acrescente `-Stress` para três suítes adicionais com múltiplas seeds, continuidade de save e transporte com
100/250/500/1000 agentes. Evidências: [benchmarks](docs/benchmarks/README.md).
Última bateria completa em 30/09/2026, anterior aos ícones de painéis e partida,
com `-Visual -Stress -Soak`: 31 suítes passaram; relatório e logs
preservados na [revisão de QA](docs/benchmarks/m9/QA_REVIEW.md).

Teste integrado: `godot --headless --path . --script res://tests/simulation_test.gd`.

Simulação sem interface:

```sh
godot --headless --path . -- --simulate --days=30 --seed=123 --template=standard --output=res://.runtime/report.json
```

Opções: `--days=1..60`, `--seed=inteiro`, `--starting-money=250000`,
`--template=standard|tower`, `--guests=0..1000`, `--output=caminho`.
Zero hóspedes significa chegadas contínuas; valor positivo cria um burst inicial
e fecha novas chegadas. O relatório distingue pico de população média. A pasta de
saída precisa existir. Templates de teste custam dinheiro e podem ser recusados.
O JSON inclui receitas, despesas, ocupação, satisfação, esperas, rotas, tempo de tick,
memória do processo, objetivos concluídos, tick de cada conquista, serviços usados,
perfis dos hóspedes ainda presentes, estado do evento e falhas.
Medidas headless não equivalem a FPS com renderização.

Arte atual: 79 PNGs originais, com caminhada, espera, trabalho e repouso da equipe,
e ciclos dedicados de dormir, beber, ler sentado e comer para os três perfis. Os usuários admitidos
nos serviços têm posições visuais separadas; animações acompanham velocidade e pausa.
Quartos aguardando limpeza têm pinturas próprias nos três níveis. Filas seguem
visualmente a ordem das reservas, com grupos por andar no elevador.
Cinco retratos próprios identificam os perfis e funções no inspetor; clicar no
personagem leva a rolagem até o cartão e seus dados.
O catálogo de construção usa seis ícones raster próprios; hóspedes chegam e saem
com malas de viagem dedicadas aos três perfis.
Contratação e gestão da equipe usam dois ícones de função dedicados.
Andar, melhoria e demolição têm três ícones próprios em botões nativos de 32px.
Finanças, Operação e Avaliações usam três ícones próprios de 28px no HUD.
Novo hotel, Salvar e Carregar também têm ícones dedicados de 28px, com
confirmação nativa e preservação dos saves verificados em oito layouts.
Equipe, Objetivos e Ajuda têm ícones dedicados no catálogo dos painéis.
Os seis painéis passaram em 96 ativações por mouse/Enter; no texto padrão,
a barra usa duas linhas, mantendo rótulos e atalhos legíveis.

Limitações atuais: seis instalações, três perfis, dois eventos e sem música ambiente.
Animações usam quatro poses pintadas, com pequenas variações entre quadros. A operação integrada foi medida até 120 hóspedes. Testes
multi-seed são regressões e estudos de gestão, não balanceamento final. Export
Windows validado nesta máquina; mobile/Web e compatibilidade externa permanecem abertos.

Consulte [ROADMAP.md](ROADMAP.md), [ARCHITECTURE.md](ARCHITECTURE.md) e
[visão permanente](docs/PRODUCT_VISION.md). Arte raster original, animações e sons: [guia de assets](ASSET_GUIDE.md).

M8: [perfis e otimizações](docs/benchmarks/m8/README.md), com operação integrada
validada até o limite atual de 120 hóspedes. QA M9 e estudos de tarifas registrados
em [TEST_PLAN.md](TEST_PLAN.md); playtests humanos de balanceamento permanecem pendentes.

Pacote Windows: `powershell -File tools/build_windows.ps1` exporta, testa o
executável e gera `builds/HotelEmpire-windows-x86_64.zip` com manifesto de revisão
e hash. `tools/test_windows_package.ps1` valida seis combinações de janela/texto.
Evidências e limites em [revisão de distribuição](docs/release/DISTRIBUTION_REVIEW.md).
