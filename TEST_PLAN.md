# Plano de testes

Automatizados: economia (saldo, investimento, resultado), filas (limite, FIFO,
duplicação), construção (limites, sobreposição, custo, suporte, demolição),
transporte (capacidade, embarque, destinos), ciclo do hóspede, limpeza e save/load.
Testes de save devem cobrir arquivos ausentes, truncados, versão desconhecida e
referências inválidas, preservando a sessão atual em caso de falha.

Integração: construir → contratar → check-in → quarto → fome → refeição → elevador
→ saída → receita → limpeza → nova reserva. Salvar no meio, carregar e continuar.

QA visual: 1440×900 e 1024×720, pan/zoom, preview válido/inválido, cancelamento,
inspeção, foco por teclado, pausa/velocidade, alertas de filas. Plataformas móveis e
Web não são declaradas testadas antes de exports reais.

Evidências de cada marco serão registradas em `docs/VALIDATION.md`.

Runner Windows: `powershell -File tools/test.ps1 -Visual`. Remove-se `-Visual` para
somente os testes headless. Os testes gráficos usam `Viewport.push_input` com
coordenadas locais, não invocação direta dos callbacks dos botões de gameplay.
O diálogo de nova sessão tem cobertura em ui_new_game: toolbar, Esc para cancelar,
Enter para confirmar, snapshot preservado no cancelamento, arquivo preservado na
confirmação e recuperação pela toolbar. A fixture inicial usa a API interna de troca. Save/load também tem teste em outro processo.

`-Stress` adiciona continuidade em 20 checkpoints/5 seeds e verificações de conservação
de agentes, reconciliação do caixa, capacidade, geometria, referências, ocupação e
snapshots periódicos. Transporte isolado deve entregar exatamente uma vez cada agente
e drenar as filas para 100/250/500/1000 passageiros. Resultados de tempo são informativos,
sem limiar dependente da máquina; FPS renderizado continua no plano de M8.

M3: `management_test.gd` cobre custos/limites de upgrades, atributos efetivos,
manutenção, contrato de preço, atribuições durante limpeza/viagem, reserva de postos,
demolição, migração de save M2 real e continuidade. Compara check-in e transporte
antes/depois. `ui_management.gd` compra upgrade por mouse, abre Equipe, seleciona
funcionário/andar pelo teclado e aplica; confere custos fixos em Finanças.
PopupMenus recebem `Input.parse_input_event` com window_id; demais controles usam
`Viewport.push_input`. Capturas são inspecionadas; isso não cobre todo o teclado/controller.

M4: `progression_test.gd` testa limites exatos, combinação de requisitos, persistência
da conquista após queda de reputação, compra bloqueada sem efeitos, reset de partida,
continuidade após load, dados inválidos e migração de fixtures reais v1/v2. Vinte e cinco
hóspedes sequenciais em hotel pequeno com caixa inicial normal verificam viabilidade.
Stress exige os dois desbloqueios N3 em até cinco dias no template padrão/5 seeds.
`ui_progression.gd` testa bloqueio visível, painel vivo, Esc, compra liberada, save/load
pela toolbar e fechamento/reset do painel ao trocar sessão. Captura topo e fim da rolagem.

M5: `content_test.gd` verifica construção bloqueada, exceção legada restrita a N3,
escolhas diferentes de perfis na mesma situação, refeição versus lanche com fome alta,
saldo, alívio, caixa, filas/capacidade e uso em três seeds de operação controlada.
Valida fronteiras de eventos, efeito real nas chegadas, hotel fechado e continuidade
atravessando fim e início de eventos. Fixture M4/v3 migra sem mutação; perfis e
contadores inválidos são rejeitados. `ui_content.gd` testa construção pelo viewport,
inspeção de hóspede, calendário pausado e save/load com evento ativo pela toolbar.

M6: `analytics_test.gd` verifica hotel vazio, ocupação/limpeza, média dos hóspedes
presentes, filas separadas, custos reconciliados, filtros combinados, elevador por
andar, ordenação estável e ausência de mutação. Preferência de texto tem roundtrip
separado e fallback para valor inválido.
`ui_operations.gd` digita busca com/sem resultados, opera filtros pelo teclado,
inspeciona com Enter, confirma centralização, atualiza lista quando a situação muda,
fecha com Esc e verifica retorno de foco. F4 amplia texto, persiste preferência sem
alterar snapshot e a mantém ao trocar partida, resetando filtros. Equipe e Finanças
também abrem/fecham pelo teclado. Capturas normais/ampliadas e janela menor são inspecionadas.


M7: `ui_art.gd` monta todos os ambientes e cinco personagens, verifica alpha real,
recortes dentro das texturas, avanço/loop da caminhada, render em zoom 0,35/0,9/1,8
sem mutação da sessão e botão Som com persistência. WAVs devem carregar com duração
válida. Capturas são inspecionadas no jogo. Bateria completa: 17 suítes com Stress/Visual.

Refinamento de café: `ui_art` verifica os três ciclos com quatro poses, avanço a
cada oito ticks, loop em 32 ticks, âncoras dentro dos recortes e pés com baseline
compartilhada. Captura quatro fases com a sessão pausada e confirma ausência de
mutação da simulação. `ui_art`, `ui_culling` (nove câmeras) e `ui_content` passaram
com zero falhas após a integração. Total de arte: 34 PNGs, 16 texturas de personagens.

M8a: `ui_culling.gd` compara pixel a pixel nove câmeras com/sem descarte de desenho
e confirma snapshot inalterado. Bateria atual: 18 suítes com Stress/Visual;
benchmark de desempenho separado em debug/performance_profile.gd.

Admissão M8: admission_equivalence_test integra -Stress e compara algoritmos em
três seeds, reconstrução de recepção e continuidade após save/load. Total atual:
19 suítes com -Stress -Visual (oito básicas, três de stress e oito gráficas).

M9 iniciado: ui_new_game integra -Visual. Runner completo agora inclui 20 suítes
(oito básicas, três de stress e nove gráficas). Perfil operacional M8 separado:
debug/operating_profile.gd aquece por 300 segundos e mede fases 1x/3x com serviços
reais, registra população e valida invariantes; não equivale a soak longo.

M9 longo: -Soak adiciona long_run_test (seis cenários de 30 dias, invariantes e
30 checkpoints de continuidade). Conjunto opcional completo: 21 suítes. Metas
e resultados em docs/benchmarks/m9/README.md; não confundir com FPS ou balanceamento final.

Perfis de gestão M9 separados da bateria: `debug/management_profile.gd` compara
quatro políticas em três seeds. Com argumento `-- --checkin`, compara referência
e quatro intervenções isoladas, usando `debug/checkin_metrics.gd` para atribuir
hóspede-segundos ao bloqueio da cabeça da fila. Ambos duram 30 dias por caso,
usam orçamento real e verificam invariantes/solvência/compras. Resultados e limites
em docs/benchmarks/m9/MANAGEMENT.md e CHECKIN.md.

Saída M10: `ui_exit` integra -Visual e exercita o pedido de fechamento da janela,
Escape/foco, pausa modal sem mudar velocidade, salvar e sair, descarte preservando
bytes do save, falha de gravação mantendo o hotel aberto e construção só de andares.
Intercepta apenas o método final de quit para inspecionar os resultados no teste.
Total naquele marco: 18 suítes com -Visual; 22 com -Visual -Stress -Soak.
O smoke do executável também abre e cancela a saída preservando a sessão.

Ajuda M10: `ui_help` testa botão/F1, foco, End/Escape, pausa sem mutar snapshot,
rolagem com texto ampliado e fechamento ao substituir a partida. Bateria atual:
19 suítes com -Visual; 23 com -Visual -Stress -Soak. Em 21/09/2026, as 19 passaram.
O smoke do pacote abre/fecha a ajuda por controles reais e verifica preservação da
sessão em todas as combinações da matriz de janela/texto.

Recuperação M10: `ui_recovery` cobre backup válido com principal ausente/corrompido,
rejeição de backup inválido, prioridade do principal válido, cancelamento, pausa
e preservação dos dois arquivos. Total naquele marco: 20 suítes com -Visual; 24 com
-Visual -Stress -Soak. O smoke exportado testa cancelamento e recuperação com
arquivos `release-smoke-corrupt*` isolados, sem tocar no save normal.

Diagnóstico de filas (22/09/2026): `checkin_diagnostics_test` cobre bloqueio real
por sujeira, intervenção de limpeza, ocupação e quarto disponível;
`ui_checkin_diagnostics` cobre atualização do inspetor/painel e leitura sem mutação.
Total atual: 22 suítes com -Visual (aprovadas), 26 com -Visual -Stress -Soak
(conjunto ampliado aprovado em 24/09/2026). O smoke exportado
verifica diagnóstico compartilhado, snapshot inalterado e texturas de upgrade.

Arte persistida no pacote: o smoke compra melhorias de recepção/quarto, restaurante
e elevador para N2/N3 com o caixa ganho na simulação. Confere a pintura de cada
nível antes de salvar e depois de Carregar pela barra; a comparação do snapshot e
a continuidade de 120 ticks também incluem esses upgrades. A compra usa as regras
de custo e desbloqueio reais, sem conceder dinheiro ou objetivos de teste.

Tarifas e espera (24/09/2026): 25 suítes de -Visual -Stress aprovadas. Teste
management adicional confirmou desconto liberando hospedagem real e ausência de
cobrança retroativa; ui_management repetido após correção do Espaço preserva
pausa ao operar o seletor. Executável 9237939 passou nas seis combinações de
janela/texto, com persistência da tarifa e controle visível após Carregar.
Evidência: docs/release/tariffs-waiting-matrix.json. Soak não repetido neste lote.

Experimento de tarifas: `tools/test.ps1 -Tariffs` adiciona 18 cenários de 30 dias
à bateria base, sem alterar os switches anteriores. Execução direta do cenário
aprovada em 24/09/2026, com 90 checkpoints e conservação de estado/dinheiro.
Dados e interpretação em `docs/TARIFF_BALANCE.md`. A aprovação comprova integridade
da simulação; não significa que as opções de preço estejam bem balanceadas.

Matriz de preços mistos: `tariff_scenarios.gd -- --tariff-mixed`, 54 casos e
270 checkpoints aprovados. Expansão no sexto dia comprada com caixa e objetivos
da partida. As nove combinações sobrepostas reproduzem exatamente a linha de
base. Evidência em `docs/benchmarks/tariffs/mixed.json`; interpretação em
`docs/TARIFF_MIXED.md`. Não incluída por padrão na bateria rápida.

Percepção de valor: `lodging_value_test` acrescenta 11 casos de check-in,
limites de satisfação e continuidade. Bateria com -Visual -Stress: 26 suítes
aprovadas; limites adicionais conferidos em execução isolada. `--lodging-value`
executa 18 cenários opcionais de 30 dias: 90 checkpoints aprovados e seis casos
padrão exatamente iguais à referência. Dados em `docs/benchmarks/tariffs/`.

Pacote 8fbfdb5: seis casos de janela/texto aprovados, incluindo prévia de valor
no inspetor e tarifa de hospedagem persistida. Matriz arquivada em
docs/release/lodging-value-matrix.json.

Satisfação por grupo (25/09/2026): analytics e ui_operations aprovados para
contagens/médias reconciliadas, equipe excluída, ausência de observações,
visitantes saindo, atualização ao vivo, ausência de mutação e rolagem com foco
visível. A mudança é uma projeção dos presentes, sem novo schema de save.
Pacote f22e841 aprovado nos seis casos locais: docs/release/satisfaction-groups-matrix.json.

Coortes de saída (25/09/2026): departure_observer_test aprovado; 18 cenários
com --departure-cohorts, zero falhas e 90 checkpoints. Contagens e somas
reconciliadas, sem duplicação e com satisfação do último tick. Os 18 relatórios
anteriores foram reproduzidos exatamente; observador não interfere na simulação.
Evidência em docs/DEPARTURE_COHORTS.md. Executável permanece f22e841.

Avaliações e poses de café (29/09/2026): 28 suítes da seleção -Visual -Stress
aprovadas. Após uma falha do helper de teclado de ui_reviews ao operar uma
ConfirmationDialog nativa, o helper foi corrigido e a suíte mais as sete visuais
restantes foram executadas novamente. Persistência v6, limite de 20 registros,
migração, continuidade, pausa, foco, rolagem, texto ampliado e saída com o
histórico aberto estão cobertos. ui_art confirma 13 texturas de personagens,
incluindo três poses estáticas de café, com capturas em três escalas.
Soak e experimentos longos de tarifas não foram repetidos neste lote.
O pacote Windows anterior ainda não inclui estas alterações; reexport e matriz
do novo pacote permanecem pendentes.

Atualização de pacote (29/09/2026): revisão 45d2eb6 exportada de árvore limpa,
smoke com 6120 ticks e seis combinações de janela/texto aprovados. Histórico
preenchido por saídas reais, restaurado via barra e exibido com fatos conferidos;
leitura pausa velocidade 1x, Escape devolve foco e janela cabe no viewport.
Auditoria de inventário e hashes aprovou 31 PNGs. Evidência em
docs/release/reviews-cafe-matrix.json. Kit externo atualizado; validação em outro
computador continua pendente.

Inspetor de personagens (29/09/2026): ui_content e ui_management aprovados.
Seleção pela cena, destino durante deslocamento, espera por etapa, embarque,
saída e decisão sem alvo antigo, projeção sem mutação e save/load conferidos.
Captura inspecionada em .runtime/m5-content.png; detalhes em
docs/ACTOR_INSPECTION.md. Não exige mudança de schema. Não incluído ainda no ZIP.

Tarifas com upgrades (29/09/2026): `tariff_scenarios.gd -- --lodging-upgrades`
aprovado em 27 cenários de 30 dias, com 135 checkpoints. Compras reais N2/N3
espelhadas no save em continuidade, desbloqueios naturais, conservação de caixa,
níveis finais e contagens/somas de coortes conferidos. O resumidor validou os
custos, datas, contexto e reprodução exata de nove referências N1. Resultados
em docs/LODGING_UPGRADES.md. Não altera parâmetros de balanceamento nem o runtime.

Tarifa adaptativa (29/09/2026): 12 partidas com --adaptive-lodging, zero falhas,
60 checkpoints e nove controles fixos idênticos ao estudo N2. 75 decisões
baseadas em avaliações já existentes validadas, inclusive a decisão recalculada
no save restaurado. Observação somente leitura, custos, coortes e contexto
conferidos. O resumidor rejeitou cinco corrupções deliberadas de relatório.
Resultados em docs/ADAPTIVE_LODGING.md; não adiciona automação ao jogo nem muda
parâmetros do runtime. Playtest humano permanece pendente.

Tempos de visita (29/09/2026): 28 suítes -Visual -Stress aprovadas. Medição de
recepção, múltiplas admissões de serviço e filas de elevador, exclusão da equipe,
conservação dos totais ao mudar trajeto e registro na saída conferidos. Save v7
preserva avaliações v6 com tempos desconhecidos, sem alterar a origem; visitantes
antigos não produzem falsos zeros. JSON e continuidade em várias seeds passaram,
assim como a janela de avaliações com tempos reais e texto ampliado.

Pacote v7 (29/09/2026 local, 30/09 UTC): revisão 28fc7c9, export limpo, smoke
de 6120 ticks e seis combinações de janela/texto aprovados. Tempos reais de
recepção/elevador conferidos antes do save e fatos da avaliação restaurada
verificados na janela. ZIP, documentos e 31 PNGs passaram na auditoria. Matriz
em docs/release/visit-times-matrix.json; kit externo atualizado. O pacote também
inclui o incremento anterior do inspetor de personagens.

Pacote com animações de café (29/09/2026 local, 30/09 UTC): revisão c63bb6e,
export limpo, smoke de 6120 ticks e seis combinações de janela/texto aprovados.
Auditoria de ZIP, documentos e 34 PNGs aprovada. Matriz em
docs/release/cafe-animation-matrix.json; kit externo atualizado com o mesmo ZIP.

Leitura sentada: `ui_art` aprovado para os três perfis, incluindo clique em cada
assento, alpha, baseline, altura de 36px, avanço/loop e quatro capturas de fase sem
mutação da sessão. `ui_culling` agora inclui usuários registrados no café e lounge;
nove comparações pixel a pixel e snapshot inalterado aprovados. `ui_content`
aprovado. Arte atual: 37 PNGs, 19 texturas de personagens. O fixture de câmera
desbloqueia os serviços antes de construir; o de arte aguarda layout antes do clique.

Pacote com leitores (29/09/2026 local, 30/09 UTC): revisão e7bfa21, árvore limpa,
smoke de 6120 ticks e seis combinações de janela/texto aprovadas. Cada caso
validou alpha, quatro quadros e recortes dos seis sprites de serviço. Auditoria
do ZIP e dos 37 PNGs aprovada; kit externo atualizado. Matriz preservada em
docs/release/lounge-reading-matrix.json. Compatibilidade em outra máquina pendente.

Refeições sentadas: `ui_art` aprovado com restaurantes cheios nos níveis N1/N2/N3,
12 hóspedes selecionados pelo clique e limites de todas as silhuetas contidos e
separados em três escalas. Alpha, altura de 36px, baseline, avanço a cada seis ticks,
loop em 24 ticks e quatro capturas de fase aprovados sem mutação da sessão.
`ui_culling` incluiu restaurante N3 cheio nas nove comparações pixel a pixel;
`ui_content` aprovado. Cinco scripts validados pelo gda sem diagnósticos. Arte:
40 PNGs, 22 texturas de personagens. O diagnóstico do export verifica nove sprites
de serviço.

Pacote com refeições (29/09/2026 local, 30/09 UTC): revisão a02edbe, árvore limpa,
smoke de 6120 ticks e seis combinações locais de janela/texto aprovados. Cada caso
verificou os nove sprites de serviço. ZIP, guia, avisos e hashes dos 40 PNGs
auditados; kit externo atualizado com o mesmo pacote. Matriz preservada em
docs/release/restaurant-dining-matrix.json. README e guia de assets atualizados
para o catálogo, schema v7, seleção de testes e export local atuais.

Repouso nas camas: `ui_art` aprovado nas nove combinações perfil × N1/N2/N3,
incluindo clique no hóspede, alpha, recorte, largura de 52px, estabilidade da pose,
retorno à caminhada e localização acima do piso em três escalas. Peseira N3
inspecionada na captura; snapshots de render e seleção iguais. `ui_culling`
incluiu camas dos três níveis nas nove comparações pixel a pixel; `ui_content`
aprovado. Cinco scripts validados pelo gda. Arte: 43 PNGs, 25 texturas de personagens;
repouso usa uma pose estática por perfil. Diagnóstico exportado verifica 12 sprites.

Pacote com repouso (29/09/2026 local, 30/09 UTC): revisão e074d08, árvore limpa,
smoke de 6120 ticks e seis combinações locais de janela/texto aprovados. Cada caso
verificou os 12 sprites de uso. ZIP, documentos e hashes dos 43 PNGs auditados;
kit externo atualizado com o mesmo pacote. Matriz preservada em
docs/release/bedroom-sleeping-matrix.json. Teste em outra máquina permanece pendente.

Repouso da equipe: `ui_art` aprovado nos quatro contextos função × idle/lift_queue,
com alpha, recortes, cadência de 16 ticks, loop em 64, escala única, âncoras dos
sapatos e retorno à caminhada/trabalho. Quatro fases capturadas e inspecionadas;
cliques nos quatro funcionários e snapshots inalterados. A vitrine separa repouso
da camareira em limpeza. `ui_culling` passou nas nove câmeras incluindo os três
contextos da equipe; `ui_content` passou. Quatro scripts válidos pelo gda após
importação. Catálogo: 45 PNGs e 27 texturas de personagens.

Pacote com repouso da equipe (29/09/2026 local, 30/09 UTC): revisão eff5486, árvore
limpa, smoke de 6120 ticks e seis combinações locais de janela/texto aprovados.
Cada caso verificou quatro contextos de repouso da equipe e 12 sprites de uso dos
hóspedes. ZIP, documentos e hashes dos 45 PNGs auditados; kit externo atualizado.
Matriz em docs/release/staff-idle-matrix.json. Compatibilidade externa pendente.

Apresentação das filas (30/09/2026): nova `ui_actor_presentation` passou nos 11
contextos de espera, quatro fases e três zooms, incluindo clique pela parte superior
do sprite, dois personagens a cinco pixels de distância e empate por ordem de
desenho. Indicadores acima de todos os recortes, snapshots inalterados e capturas
inspecionadas. `ui_culling` passou nas 11 câmeras, duas com somente o indicador
na borda inferior; `ui_art`, `ui_content` e `ui_checkin_diagnostics` passaram.
Quatro scripts válidos pelo gda. Seleção `-Visual` agora contém 15 suítes gráficas.
`ui_smoke`, `ui_resume` e `ui_management` passaram após a mudança de seleção.

Pacote da apresentação de filas (30/09/2026): revisão 1043b78, árvore limpa,
smoke de 6120 ticks e seis combinações locais de janela/texto aprovados. Cada
caso verificou seleção e indicadores em três zooms, 12 sprites de uso e quatro
contextos de repouso da equipe. ZIP, documentos e 45 PNGs auditados; kit externo
atualizado. Matriz: docs/release/queue-presentation-matrix.json. Perfil sintético
de caminhada concluído em oito casos; escopo e dados em
docs/benchmarks/m8/QUEUE_PRESENTATION.md. Não mede latência de clique ou operação de filas.

Ciclo de repouso (30/09/2026): `ui_art` aprovado nas nove combinações perfil ×
cama N1/N2/N3, quatro quadros e três zooms. Recortes contidos, largura máxima de
52px, âncora inferior, cadência de 12 ticks, loop em 48 e retorno à caminhada.
Cliques selecionam os nove hóspedes; quatro capturas inspecionadas com peseira N3
preservada. Seis camas completas mudaram pixels entre fases; snapshots inalterados
durante pausa/desenho/seleção. `ui_culling` passou nas 11 câmeras;
`ui_actor_presentation` e `ui_content` passaram. Quatro scripts válidos pelo gda.
Catálogo: 48 PNGs e 27 texturas de personagens; poses estáticas preservadas como
referências e novos arquivos ativos com os mesmos IDs. PNGs não foram editados.

Pacote com ciclos de repouso (30/09/2026): revisão a0fcec0, árvore limpa, smoke de
6120 ticks e seis combinações locais de janela/texto aprovados. Cada caso verificou
os 12 sprites de uso com quatro quadros, quatro contextos da equipe e seleção em
três zooms. ZIP, documentos e hashes dos 48 PNGs auditados; kit externo atualizado.
Matriz: docs/release/bedroom-sleeping-loop-matrix.json. Compatibilidade externa pendente.

Limpeza e posições das filas (30/09/2026): três pinturas RGB 1254×1254 geradas no
chat, copiadas sem alteração de pixels e com mipmaps. `ui_art` passou com compras
reais de N2/N3, desenho nos três zooms, snapshot inalterado, save/load e conclusão
da limpeza pelo EmployeeSystem nos três níveis. Comparações antes/depois
inspecionadas em docs/art/hotel-housekeeping{,-cleaned}.png.

`ui_actor_presentation` passou com duas filas de 12 reservas (uma ainda caminhando),
IDs em ordem inversa e dez passageiros em dois andares, incluindo funcionários.
Ordem por reserva, extremos do hotel, entrada interpolada, contadores, seleção real
de 33 pessoas nos três zooms, culling equivalente e posições reproduzidas após
restaurar o snapshot. Captura inspecionada em docs/art/hotel-fifo-queues.png.
Filas grandes comprimem espaçamento e ainda podem sobrepor silhuetas.

Seis scripts válidos pelo gda. Os 11 testes base e 15 gráficos passaram nesta
entrega. A primeira execução parou numa fixture nova sem desbloqueio para N3;
corrigida a fixture, as oito suítes gráficas restantes passaram em
.runtime/housekeeping-verification, com timeout por processo. Sem alteração de
economia, atendimento, transporte ou schema v7.

Pacote de limpeza/filas (30/09/2026): revisão 090b8af, árvore limpa; boot e smoke
de 6120 ticks aprovados. Seis casos em 1024×640, 1280×800 e 1600×900, com texto
normal/ampliado, verificaram os três níveis de quarto e seleção de filas em três
zooms. Matriz docs/release/housekeeping-fifo-matrix.json. ZIP e 51 PNGs auditados;
kit externo atualizado. Compatibilidade em outra máquina permanece pendente.

Retratos de inspeção (30/09/2026): cinco PNGs RGBA originais 1254×1254 gerados no
chat, sem editar pixels, com alpha real, cantos transparentes e mipmaps. Catálogo
atual: 56 PNGs; retratos separados das 27 texturas de animação. Cinco scripts
válidos pelo gda. `ui_content` passou nos 30 casos de perfil/função × janela/texto,
incluindo clique real, rolagem automática, limites do cartão, identidade fixa,
snapshot, save/load, troca de partida e pessoa removida sem retrato antigo.

`ui_art`, `ui_actor_presentation`, `ui_operations`, `ui_management`, `ui_new_game`,
`ui_smoke` e `ui_resume` passaram. A primeira fixture incluiu dois camareiros e
manteve uma câmera centralizada em sala de outro caso; corrigida para uma pessoa
por função e câmera comum. Retomada executada após ui_smoke produzir seu save.
Capturas inspecionadas em docs/art/hotel-character-portraits.png e
hotel-staff-portrait.png. Textos e necessidades permanecem nativos; retrato não
representa emoção atual. Economia, estados e schema v7 preservados.

Pacote de retratos (30/09/2026): revisão a3b2554, árvore limpa; boot e smoke de
6120 ticks sem falhas. Seis combinações de janela/texto verificaram os cinco
retratos, seleção real e rolagem. Matriz docs/release/character-portraits-matrix.json.
ZIP, documentos e 56 PNGs auditados; kit de compatibilidade atualizado.

## M7 — bagagem na chegada e saída (30/09/2026)

Três faixas RGBA preservadas do gerador do chat, quatro poses por perfil.
Catálogo atual: 59 PNGs, 30 texturas de animação e cinco retratos separados.
Quatro scripts validados pelo gda; oito suítes passaram: ui_actor_presentation,
ui_culling, ui_art, ui_content, ui_smoke, ui_resume, simulation_test e save_test.

ui_actor_presentation acrescenta 72 combinações (três perfis, dois sentidos,
quatro poses e três zooms), com clique no corpo e na mala, âncora de apoio
espelhada, limites da fonte e snapshot imutável. Compara pixels de culling
em 18 casos de pose 0. Exercita chegada à recepção, recusa sem recepção,
fim da estadia, escolha contextual em fila/cabine, caminhada interna e
restauração de destino sem alterar o esquema de save. Fixtures de relógio
e destino foram corrigidas após a primeira execução falhar; nova execução completa passou.

Capturas inspecionadas: docs/art/hotel-travel-balanced.png,
hotel-travel-business.png e hotel-travel-leisure.png. Proveniência e limites
em docs/art/guest-travel.md. Não há rig nem animação de porta/desempacotar.

Pacote de bagagem: revisão 89f2a6c, árvore limpa; boot e smoke de 6120 ticks,
39 reservas, 42 refeições, 31 limpezas, caixa 2021 e zero falhas. As três faixas
de viagem foram verificadas em cada uma das seis combinações de janela/texto:
docs/release/guest-travel-matrix.json. ZIP, documentos e 59 PNGs auditados;
kit de compatibilidade atualizado. Teste externo em outra máquina ainda aberto.

## M7 — ícones do catálogo (30/09/2026)

Seis fontes RGBA 1254×1254 preservadas do gerador integrado ao chat; alpha e
bordas medidos sem editar PNGs. Catálogo atual: 65 PNGs, 30 texturas de animação,
cinco retratos e seis ícones separados. Quatro scripts válidos pelo gda.

Seis suítes gráficas passaram: ui_content, ui_smoke, ui_resume, ui_management,
ui_progression e ui_new_game. ui_content cobre 36 casos de instalação/janela/texto,
clique e Enter, rolagem/bounds e mínimos do layout, fontes distintas das pinturas,
alpha, preço/nome nativos e snapshot preservado. Café/lounge bloqueados conservam
ícones e não entram em construção. Capturas normal/ampliada em 1024×640 inspecionadas:
docs/art/hotel-build-icons.png e hotel-build-icons-large.png.
Prompts, origem, hashes e limites em docs/art/build-icons.md e arquivos associados.

Pacote de ícones: revisão 2f5bf1e, árvore limpa; boot e smoke de 6120 ticks,
39 reservas, 42 refeições, 31 limpezas e caixa 2021, sem falhas. Os seis ícones
foram verificados em cada combinação da matriz docs/release/build-icons-matrix.json.
ZIP, documentos e 65 PNGs auditados; kit de compatibilidade atualizado.

## M7 — ícones de contratação e gestão da equipe (30/09/2026)

Dois PNGs RGBA 1254×1254 originais do gerador integrado, preservados byte a byte;
catálogo atual: 67 PNGs, 30 texturas de animação, cinco retratos e oito ícones.
Cinco scripts válidos pelo gda. Seis suítes gráficas passaram: ui_management,
ui_content, ui_smoke, ui_resume, ui_new_game e ui_operations.

ui_management cobre 12 casos de função/janela/texto: 24 contratações por mouse
e Enter, papel/custo/salário, bounds, ícone da seleção, atribuição por teclado,
restauração de funcionários/atribuições, caixa insuficiente sem mutação e lista
vazia sem imagem antiga. A fixture de atribuição foi corrigida após falhas na
primeira execução: elevador para alcançar o andar e ativação por teclado da janela.
ui_content manteve 30 casos de retrato e 36 casos dos ícones de construção.

Capturas inspecionadas em 1024×640 com texto ampliado:
docs/art/hotel-staff-hiring.png, hotel-staff-management-receptionist.png e
hotel-staff-management-cleaner.png. Detalhes e proveniência em docs/art/staff-icons.md.

Pacote de equipe: revisão 5847132, árvore limpa; boot e smoke de 6120 ticks,
39 reservas, 42 refeições, 31 limpezas e caixa 2021, sem falhas. Duas funções
contratadas pelo ícone com custo correto e arte na gestão em cada configuração
da matriz docs/release/staff-icons-matrix.json. ZIP, documentos e 67 PNGs
auditados; kit de compatibilidade atualizado.

## M8 — orçamento de texturas da interface (30/09/2026)

`debug/ui_asset_profile.gd` válido pelo gda; baseline limpa 43baeb6 e execução
com somente 13 imports limitados a ícones 256px/retratos 512px. Mesmo código,
seed, cena pausada e host. Dados e proveniência em docs/benchmarks/m8/UI_TEXTURES.md.
Monitor de vídeo reduzido em 99.206.244 bytes (94,61 MiB) nos quatro pares de
janela/texto; cadeia RGBA8+mips das 13 texturas reduzida de 103,94 para 9,33 MiB.
Não há medição de FPS ou nova capacidade de hóspedes.

20 seleções de retrato nas janelas reais 1280×800/3840×2160 e ambos os textos,
sem alteração do snapshot ou corte do cartão. Canvas capturado em 4K: 3456×2160,
mantendo a proporção lógica 1440×900. Capturas portrait/hiring inspecionadas.
67 PNGs fonte com hashes preservados; nenhum ambiente ou sprite foi reduzido.
Seis suítes gráficas passaram: ui_management (12 casos/24 contratações),
ui_content (30 retratos/36 ícones), ui_smoke, ui_resume, ui_new_game e ui_operations.
Resultados de outro computador e playtest humano continuam pendentes.

Pacote com limites de importação: revisão 451bbdc, árvore limpa; boot e smoke
de 6120 ticks, 39 reservas, 42 refeições, 31 limpezas e caixa 2021, sem falhas.
Seis combinações do executável extraído passaram, incluindo dois ícones da
equipe, seis de construção e cinco retratos: docs/release/ui-texture-budget-matrix.json.
ZIP, documentos e 67 PNGs auditados; kit de compatibilidade atualizado.

## M7 — ícones dos comandos de construção (30/09/2026)

Três novos PNGs RGBA originais do gerador integrado ao chat, sem edição dos
pixels; hashes e cantos transparentes conferidos. Catálogo atual: 70 PNGs,
30 texturas de animação, cinco retratos e 11 ícones; novos imports a 256px.
Quatro scripts válidos pelo gda. Sete suítes gráficas passaram: ui_action_icons,
ui_content, ui_management, ui_smoke, ui_resume, ui_new_game e ui_progression.
36 ativações dos comandos em três janelas, dois textos e mouse/Enter, com custo,
nível, seleção, reembolso, pausa e bounds; falhas de caixa/seleção sem mutação.
Primeira fixture rolava antes do layout; espera corrigida. Um carregamento durante
edição parcial do diagnóstico falhou; validação e bateria repetidas após concluir
as edições. Capturas de expansão/demolição e melhoria em 1024×640/texto ampliado
inspecionadas em docs/art/hotel-action-*.png. Detalhes em docs/art/action-icons.md.

Pacote de comandos: revisão 7f651a3, árvore limpa; boot e smoke de 6120 ticks,
39 reservas, 42 refeições, 31 limpezas e caixa 2021, sem falhas. Os três comandos
e seus imports de 256px passaram em cada caso de docs/release/action-icons-matrix.json.
ZIP, documentos e 70 PNGs auditados; kit de compatibilidade atualizado.

## QA integrado após os assets (30/09/2026)

Revisão limpa dcfcd2d, `tools/test.ps1 -Visual -Stress -Soak`: 31 suítes mais
import passaram. Quinze headless e 16 gráficas; seis cenários de 30 dias,
30 checkpoints e entrega de 100/250/500/1000 agentes no transporte isolado.
Relatório e 32 logs originais em docs/benchmarks/m9/regression-20260930*.

A bateria inicial cf37cdf parou em ui_art: preview com pan fixo cortava quartos
com cabeçalho ampliado. Fixture enquadra seis camas explícitas pelo playfield e
converte bounds lógicos para pixels da captura; quatro fases/24 amostras reais,
snapshot preservado. Captura inspecionada e bateria completa repetida sem falhas.
Erro inicial e correção preservados em art-preview-failure-20260930.json.
O runner registra resultados também em falha e limita cada processo a 120s
por padrão, ajustável por `-SuiteTimeoutSeconds`, encerrando apenas o handle criado.
Isso não valida compatibilidade externa, FPS de 1000 hóspedes ou balanceamento humano.

## M7 — ícones da barra de gestão (30/09/2026)

Três fontes RGBA 1254×1254 originais do gerador integrado ao chat, sem edição;
catálogo atual de 73 PNGs e 14 ícones. Novos imports de 256px com mipmaps e
botões de 28px. Quatro scripts válidos pelo gda. Nove suítes gráficas passaram:
ui_management_icons, ui_management, ui_operations, ui_reviews, ui_smoke,
ui_resume, ui_new_game, ui_help e ui_art (seis camas/24 amostras de repouso).

ui_management_icons cobre 48 ativações de três painéis, quatro janelas, dois
textos e mouse/Enter; Esc retorna foco, snapshot pausado preservado. Confere
24 áreas com pixels pintados, largura mínima, bounds e ausência de sobreposição.
Altura lógica do playfield igual à barra sem imagens nos oito layouts medidos;
dados em docs/art/management-icons-ui.json. Primeira configuração com
expand_icon passava propriedades, mas ocultava imagens; capturas identificaram
o problema e a configuração/checagem de pixels foram corrigidas e repetidas.
Capturas em janela pequena e 4K inspecionadas; não certificam monitor físico.
Origem, prompts, limites e comportamento em docs/art/management-icons.md.

Pacote de gestão: revisão 4c7d81b, árvore limpa; boot e smoke de 6120 ticks,
39 reservas, 42 refeições, 31 limpezas e caixa 2021, sem falhas. Três painéis
abertos pelos ícones, Esc/foco e snapshot preservados em cada caso da matriz
docs/release/management-icons-matrix.json. ZIP, documentos e 73 PNGs auditados;
kit de compatibilidade atualizado. Validação externa e playtest humano pendentes.

## M7 — ícones de partida (30/09/2026)

Três fontes RGBA 1254×1254 originais geradas no chat, sem edição de pixels;
catálogo de 76 PNGs e 17 ícones. Imports de 256px com mipmaps, Button.icon de
28px incluído no mínimo do fluxo. Nove suítes gráficas passaram: ui_session_icons,
ui_smoke, ui_resume, ui_new_game, ui_recovery, ui_exit, ui_management_icons,
ui_help e ui_content (36 construções e seleções de retrato).

ui_session_icons verifica 48 ativações por mouse/Enter em quatro janelas e dois
textos, oito cancelamentos e oito confirmações; gravação validada no disco,
restauração integral após sessão vazia, reset/fundos/objetivos e bytes salvos
preservados. 24 áreas de ícone realmente pintadas, mínimo/bounds/sem sobreposição,
foco e preferência de texto. Playfield não ganhou linha nesses oito layouts.
Capturas pequena/4K inspecionadas; dados em docs/art/session-icons-ui.json,
prompts/origem/hashes em docs/art/session-icons*.json.

O runner configura agora 33 suítes com Visual/Stress/Soak; a última bateria
completa de 31 suítes continua sendo a revisão dcfcd2d, anterior aos seis ícones
de gestão e partida. Não há nova medição global de memória, compatibilidade
externa ou playtest humano neste incremento.

Quatro scripts válidos pelo gda. Pacote da revisão limpa 33eca92: boot e smoke
de 6120 ticks passaram, com 39 reservas, 42 refeições, 31 limpezas e caixa 2021.
Três comandos de partida verificados em cada uma das seis configurações do ZIP
extraído: docs/release/session-icons-matrix.json. Gravar/carregar, cancelar e
confirmar novo hotel e carregar novamente preservam snapshot/bytes salvos.
Inventário, documentos e hashes dos 76 PNGs conferidos; kit atualizado.
