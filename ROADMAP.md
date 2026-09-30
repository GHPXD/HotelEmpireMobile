# Roadmap

O pedido operacional atual organiza o trabalho abaixo; a visão permanente em
`docs/PRODUCT_VISION.md` permanece como destino do produto, sem exigir conteúdo antecipado.

- [x] M0 Foundation: projeto, dados, economia, fila, testes, boot validado.
- [x] M1 Vertical Slice: construção, câmera, hóspedes, serviços, transporte, funcionários,
  satisfação, save/load, HUD, debug e ciclo integrado validado.
  - [x] M1a construção/andares/seleção/demolição.
  - [x] M1b hóspedes/check-in/decisão/serviços/economia.
  - [x] M1c elevadores/filas/funcionários/limpeza/reputação.
  - [x] M1d save/load/UI/diagnóstico/QA integrado.
- [x] M2 Simulation Core: robustez, stress, métricas e múltiplas seeds.
- [x] M3 Hotel Management: upgrades, atribuições e finanças.
- [x] M4 Progression: desbloqueios e objetivos.
- [x] M5 Content Expansion: novos serviços, perfis e eventos.
  - [x] Histórico das últimas 20 avaliações com fatos das visitas e persistência v6.
  - [x] Tempos reais de recepção e filas por visita; migração v7 conserva histórico antigo com tempos desconhecidos.
- [x] M6 UI/UX Polish: filtros, analytics e melhorias de leitura/foco no desktop.
  - [x] Causa atual da fila de check-in e ação sugerida no inspetor e em Operação.
  - [x] Métricas por elevador em Operação: cabine, fila, espera atual e histórico de embarques.
  - [x] Satisfação dos presentes separada por check-in, com contagens, médias e resumo rolável por teclado.
  - [x] Inspetor identifica objetivo, sala e andar do personagem, sem destinos ou esperas antigos em etapas posteriores.
- [x] M7 Art & Animation: 51 PNGs originais, caminhada, espera de hóspedes, ações de funcionários e efeitos sonoros.
  - [x] Pinturas dedicadas para quartos, recepções e restaurante nos níveis 2 e 3.
  - [x] Cabine de elevador N2 com pintura dedicada.
  - [x] Cabine N3 distinta, com mármore e medalhão de latão.
  - [x] Quatro poses de espera próprias para cada um dos três perfis de hóspede.
  - [x] Pose com xícara para cada perfil durante o uso do Café Brisa, com transparência e escala validadas.
  - [x] Ciclo de beber com quatro poses por perfil, escala compartilhada e pés alinhados; acompanha velocidade e pausa.
  - [x] Leitura sentada na Sala Horizonte: quatro poses por perfil e assentos separados para os usuários admitidos; café também distribui usuários visualmente.
  - [x] Refeição sentada no Bistrô Aurora: quatro poses por perfil, mesas próprias e usuários separados nos níveis 1/2/3, sem sobreposição no limite de cinco lugares.
  - [x] Pose de dormir por perfil sobre a cama pintada; nove combinações de perfil/nível selecionáveis e peseira N3 em primeiro plano.
  - [x] Ciclo sutil de repouso com quatro quadros por perfil nas camas N1–N3, com escala comum, pausa e cadência de 12 ticks por quadro.
  - [x] Quatro poses próprias de repouso para camareira e recepcionista, também usadas na fila do elevador, com pés alinhados e pausa pelo relógio da simulação.
  - [x] Indicador de espera acima dos sprites e seleção pelo rosto/corpo; clique escolhe o personagem próximo quando as silhuetas se sobrepõem.
  - [x] Pinturas de quartos aguardando limpeza nos três níveis, com retorno automático à versão limpa.
  - [x] Posições visuais pela ordem das reservas, filas de elevador por andar e um contador por grupo.
- [x] M8 Optimization: perfis 100/250/500/1000 agentes e operação até o limite atual de 120.
  - [x] M8a perfil inicial, descarte de render fora da câmera e equivalência visual.
  - [x] M8b admissão/saídas otimizadas; perfil integrado contínuo com 118–120 hóspedes.
- [x] M9 QA: regressões, cenários e diagnóstico de balanceamento do protótipo desktop.
  - [x] Confirmação/cancelamento de novo hotel e preservação do save pela interface.
  - [x] Seis cenários de 30 dias com orçamento inicial e continuidade de save/load.
  - [x] Comparação de quatro decisões de gestão em três seeds, 30 dias e orçamento real.
  - [x] Diagnóstico do check-in: 15 cenários isolando limpeza, quartos, recepção e elevador.
  - [x] Revisão final de QA e bateria conjunta de 21 suítes, sem falhas.
- [ ] M10 Release Preparation: exports, compatibilidade e distribuição.
  - [x] Preset Windows, build reproduzível, ZIP, licenças e manifesto de hash/revisão.
  - [x] Boot e operação/save/load pela interface no executável, inclusive ZIP extraído em caminho com espaços.
  - [x] Matriz local de seis combinações de janela/texto, inventário do ZIP e hash do executável.
  - [x] Saída com salvar/descartar/cancelar, pausa modal e proteção contra falha de gravação.
  - [x] Ajuda F1 no jogo: primeiros passos, diagnóstico de filas, controles e saves, com pausa e rolagem.
  - [x] Recuperação de backup validado pela interface, com confirmação e preservação dos arquivos.
  - [ ] Revisão final de distribuição e compatibilidade externa documentada.
    - [x] Integridade local, guia, avisos e manifesto revisados em `docs/release/DISTRIBUTION_REVIEW.md`.
    - [ ] Resultados de outro computador e roteiro manual revisados.
  - [x] Kit independente de compatibilidade com coleta de relatórios e roteiro manual; validado localmente.

Uma caixa só é marcada após execução e validação. Publicação será decidida depois.

Evolução de gestão: tarifas por sala de 75%, 100% e 125%, com migração de saves
v1–v4 para v5 e contratos em curso preservados. Detalhes em `docs/TARIFFS.md`.
- [x] Comparação de tarifas: 18 cenários de 30 dias e 90 checkpoints de save.
- [x] Separação hospedagem/serviços e expansão: 54 cenários, 270 checkpoints;
  premium de hospedagem sem contrapartida em 18/18 pares (`docs/TARIFF_MIXED.md`).
- [ ] Refinar a contrapartida de premium: quatro dos seis pares medidos renderam
  mais lucro sem mudar atendimento/reputação. Evidência em `docs/TARIFF_BALANCE.md`.
  - [x] Primeiro efeito de valor no check-in, com prévia por perfil e padrão
    neutro: 18 cenários e 90 checkpoints em `docs/LODGING_VALUE.md`.
  - [x] Validar satisfação de saída por coorte: 18 cenários e observador neutro;
    contrapartida de premium confirmada entre hóspedes atendidos.
  - [ ] Calibrar com upgrades/políticas adaptativas e avaliar em playtest humano.
    - [x] Medir três políticas de melhoria em 27 cenários e 135 checkpoints; contrapartida de preço preservada e retorno dependente da tarifa/data de compra.
    - [ ] Comparar políticas adaptativas e revisar a experiência com jogadores.
      - [x] Política diária baseada nas avaliações: 12 cenários, 60 checkpoints, alvo de caixa/satisfação cumprido em três seeds.
      - [ ] Avaliar leitura do histórico e frequência de mudanças em playtest humano.
M10 permanece aberto para resultados de compatibilidade em outro computador.
M6 não conclui suporte integral a teclado/controller, leitores de tela ou touch.
M8 mede render isolado, transporte e sobrecarga até 1000; operação integrada
contínua respeita o limite atual de 120. Não comprova 1000 hóspedes atendidos
simultaneamente a 60 FPS. Ampliar esse limite requer conteúdo/capacidade e novo perfil.
