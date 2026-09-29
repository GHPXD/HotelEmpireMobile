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
