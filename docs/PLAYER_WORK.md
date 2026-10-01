# Operação manual e onboarding

Sprint 3: o jogador atende um hotel pequeno antes de delegar. A intervenção
continua disponível depois da contratação. Esta especificação evolui junto da
implementação e das evidências; ergonomia humana é avaliada no Sprint 15.

## Experiência e limites

Uma tarefa por vez: observar fila/pedido/desgaste, escolher uma prioridade,
deslocar-se, concluir uma ação curta e perceber o efeito. Funcionários liberam
atenção para construir e administrar. Nenhuma tarefa manual concede Cash por
um toque isolado: hospedagem e entrega usam hóspedes, preços e orçamento reais.

Perfil mobile novo começa com 2.400 Cash, sem equipe. Recepção (800) e quarto
(600) deixam 1.000 para alimentação/expansão. O domínio de benchmark mantém seu
orçamento de 12.000; isso não é o orçamento do novo perfil mobile.
Guia não congela simulação nem bloqueia escolhas; o progresso é persistido e
retomado. Não redefine ou reduz hotéis já existentes ao migrar saves.

## Estado e autoria

| Estado | Dono | Persistência e limites |
|---|---|---|
| Tarefa, progresso, reservas, pedidos e contadores manuais | PlayerWorkSystem na HotelSession | snapshot de domínio v8; uma tarefa, pedidos ativos limitados, IDs estáveis |
| Deslocamento do jogador | ActorState com role player + TransportSystem | mesmo caminho, elevadores e filas dos demais atores; sem salário |
| Limpeza e reparo reservados | RoomState | dono explícito; evita duas tarefas sobre o mesmo alvo |
| Condição da instalação | RoomState | 0–100; degradação por uso, recuperada por reparo |
| Estágio do guia | OnboardingService na aplicação | módulo versionado em app_state; preserva outros módulos |
| Painel, câmera, seleção | AppRoot/MobileHotelPanels | apresentação transitória, sem autoridade econômica |

## Ações

- Check-in: reservar somente o primeiro hóspede que chegou ao balcão. Caminhar
  até a recepção e concluir atendimento curto; admissão usa a mesma função dos
  recepcionistas, com quarto limpo/acessível, orçamento e cobrança única.
- Limpeza: quarto vazio e sujo, sem outro dono. Caminhar, limpar e liberar a
  reserva; a contagem agregada de limpezas alimenta os objetivos existentes.
- Room service inicial: pedido de hóspede hospedado e com fome, origem em serviço
  de alimentação disponível. Preparação ocupa capacidade, entrega percorre o
  hotel/elevador. Hóspede aguarda no quarto. Preço fica acordado no início;
  orçamento, receita, fome e satisfação mudam somente na entrega válida.
- Reparo simples: recuperar condição e eficiência, com custo de materiais em
  Cash. Desgaste reduz velocidade em até 20%, sem fechar uma instalação nem
  bloquear progressão. Falhas maiores e staff especializado entram no Sprint 9.

O jogador pode cancelar. Reservas são liberadas, sem efeito de serviço ou
receita. Um passageiro já embarcado termina seu trajeto com segurança; não é
teletransportado para fora do elevador. Novo trabalho aguarda esse deslocamento.
Background/pause suspende trabalho ativo. Checkpoint inicial, de transição e de
conclusão protege retomada; timers agregados offline de obras entram no Sprint 5.

## Guia

Construir recepção → quarto → abrir → atender → construir alimentação → entregar
pedido → limpar após estadia → reparar → contratar primeiro funcionário.
Hotel e Missões apresentam próximo objetivo e ação para localizar seu alvo.
Progresso usa fatos de jogo, sem marcar etapas pelo simples clique em Avançar.

## Relações e feedback

Atendimento → hospedagem → receita → expansão/equipe → menos tarefas manuais.
Mais hóspedes → filas/sujeira/pedidos/desgaste → decisão de prioridade/equipe.
Desgaste → atendimento mais lento → reparo → capacidade recuperada.
Uma tarefa por jogador limita throughput; automação paraleliza setores.

Painéis mostram condição, efeito do reparo, etapa do trabalho, alvo, preço,
progresso e motivo de indisponibilidade. Identificar o ator como Você. Som/haptic
continuam opcionais. Ícones novos são peças raster originais individuais.

## Contrato de validação

Parâmetros ficam centralizados em data/player_work.tres. Hipótese inicial:
ações no alvo em 1,5–4 segundos, excluindo caminhada/elevador; primeira hospedagem
em até 30 segundos sob política guiada; guia/equipe acessíveis em poucos minutos.
Esses números são hipóteses de pacing, não evidência de preferência do mercado.

Testar FIFO, orçamento, quarto sujo/ocupado/inacessível, corrida com funcionários,
cancelamento em cada fase, falta de capacidade, hóspede que abandona pedido,
tarifa alterada durante entrega, demolição, callback repetido, pause/background,
save/restore em cada fase, migrations v1–v7, dados malformados e solo → contratação.
Medir multiseed com políticas de intervenção explícitas, reconciliar economia e
comparar resultados com guardrails. UI deve executar o fluxo por eventos reais
de toque, com capturas em portrait/landscape/texto ampliado e densidade mobile.

O estudo técnico comprova regras e pacing da política simulada. Diversão,
compreensão espontânea e retenção continuam dependentes de avaliação humana e
telemetria futura. Eventos devem permitir medir oportunidade, início, resultado,
tempo, cancelamento e etapa do guia sem incluir dados pessoais.

## Resultado e política medida

O guia tem nove etapas. Check-in, limpeza, preparo, entrega e reparo duram,
respectivamente, 1,5/3/2/1/3 segundos no alvo. Preparação respeita a fila e ocupa
capacidade real; nenhuma moeda é recebida ao aceitar um pedido. Materiais de
reparo custam 5 Cash na conclusão. Desgaste por hospedagem/refeição/check-in é
8/3/2 pontos; duração = duração nominal × (1 + (100 − condição)/100 × 0,2).

Política simulada: construir recepção/quarto, abrir, fazer check-in quando o
primeiro da fila chega, construir restaurante após a primeira hospedagem, entregar
primeiro pedido elegível, limpar após saída, reparar o quarto e contratar ao ter
saldo. Enquanto aguarda, pode fazer um segundo check-in. Horizonte: 600 segundos;
meta: primeira hospedagem ≤30 s e delegação ≤300 s, com saldo não negativo e
identidade Cash inicial + receita − despesa − capital preservada.

| Seed | Primeira hospedagem (s) | Contratação (s) | Cash após contratar |
|---|---:|---:|---:|
| 1 | 3,6 | 105,7 | 67 |
| 17 | 3,7 | 111,8 | 207 |
| 123 | 3,7 | 96,0 | 39 |
| 9001 | 3,5 | 109,7 | 207 |
| 54321 | 3,5 | 135,5 | 199 |

Resultado para esta política e sementes; não é uma estimativa da população humana.
Gate adicional da aplicação completou guia em 115,3 s com 95 Cash, checkpoints e
retomada após kill simulado. Rebalancear se novas políticas legais criarem um
soft lock obrigatório ou se a evidência final mostrar carga manual repetitiva.
Rollback dos valores é o recurso `data/player_work.tres` e orçamento de perfil;
nunca redefinir patrimônio persistido ao alterar a política do primeiro boot.
