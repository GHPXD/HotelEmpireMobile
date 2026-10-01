# Equipe e automação — Sprint 4

A primeira equipe assume recepção e limpeza. Contratar transforma intervenções
repetidas em supervisão de filas, atribuições e caixa; o jogador continua disponível
para trabalhar em gargalos. Manutenção, cozinha/serviço de quarto e incidentes são
operações especializadas da Sprint 9. Supervisores e gerentes continuam na evolução
do produto; a projeção de departamentos desta sprint não simula esses cargos.

## Autoridade e ciclo

`HotelSession` autoriza contratação, atribuição, prioridade, pausa e desligamento.
Cada funcionário possui `EmployeeProgress`; `EmployeeDefinition` e `EmployeeRules`
são dados compartilhados imutáveis. `EmployeeSystem` recebe a conclusão de check-in
por sinal tipado de `GuestSystem` e conclui limpeza somente com a reserva válida.
`TransportSystem` aplica velocidade de caminhada derivada. UI envia comandos ao
`GameController`, que persiste alterações e conclusões. `StaffProjection` lê os
departamentos, salários e evolução sem alterar a simulação.

Fluxo: contratar → deslocar → atender/limpar → ganhar XP → melhorar eficiência e
qualidade → pagar salário atualizado → revisar equipe e filas. É possível pausar,
reatribuir ou desligar para controlar capacidade e custo. Não há contratação aleatória,
reroll, consumo de Gems ou IAP para liberar esses dois papéis.

## Progressão limitada

| Nível | XP cumulativo | Eficiência base | Qualidade adicional | Salário base |
| --- | ---: | ---: | ---: | ---: |
| 1 | 0 | 100% | +0 | 100% |
| 2 | 60 | 108% | +1 | 105% |
| 3 | 180 | 116% | +2 | 110% |
| 4 | 360 | 124% | +3 | 115% |
| 5 | 600 | 132% | +4 | 120% |

Check-in válido concede 6 XP; limpeza válida concede 10 XP. O contador de tarefas
continua após o teto de 600 XP. Espera, caminhada, falta de quarto, cancelamento e
trabalho do jogador não concedem XP a funcionários. Qualidade da tarefa usa o nível
anterior à sua recompensa, evitando aplicar retroativamente uma promoção.

Salário é cobrado por dia simulado do hotel, com arredondamento para cima em Cash.
Porcentagens são estabilizadas antes do arredondamento para evitar que 36 matemáticos
virem 37 por erro de ponto flutuante. A promoção modifica a próxima cobrança diária;
não retira dinheiro imediatamente. Pausar tarefas mantém salário.

## Contratação e traços

Cada papel oferece quatro perfis fixos: padrão, ágil, qualidade e combinação.
Uma pessoa tem até dois traços relevantes. Custos e resultados aparecem na comparação.

| Traço | Papel | Trabalho | Caminhada | Qualidade | Contratação | Salário |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Ágil | Ambos | ×1,12 | ×1,15 | — | +20% | +12% |
| Carismático | Recepção | — | — | +3 | +15% | +5% |
| Cuidadoso | Limpeza | ×0,90 | — | +3 | +15% | +8% |

A recepção concede qualidade à satisfação no check-in concluído. Limpeza registra
um bônus no quarto disponível, concedido uma vez na próxima hospedagem e então
consumido. Liberar um quarto após estadia apaga o bônus antigo. Limpeza manual mantém
qualidade base; permanece mais rápida, reforçando a utilidade de intervir.

Os adicionais de custo/salário se somam; fatores de eficiência se multiplicam.
Exemplo: camareiro ágil e cuidadoso custa 203 Cash, recebe 36 por dia no nível 1,
trabalha a 100,8% e entrega +3 de qualidade. No nível 2, recebe 38 por dia.
Os parâmetros ficam em `data/employee_rules.tres` e no script de seu Resource.

## Delegação e interrupção

- Recepção conserva fila FIFO, orçamento, quarto acessível, tarifa e reserva manual.
  Pausa conclui o atendimento já iniciado e libera o posto antes do próximo.
- Camareiros reservam quartos vazios e sujos. Pausa conclui viagem e limpeza atuais,
  mas impede a próxima tarefa. Andar fixo ou automático continua disponível.
- Prioridade de limpeza escolhe espera mais antiga ou quarto mais próximo. A primeira
  usa timestamp de liberação; histórico legado desconhecido vem primeiro. Distância
  usa percurso horizontal mais três unidades por andar, com desempate por idade/ID.
  Viagem já iniciada termina antes de aplicar nova prioridade/andar.
- Desligamento exige confirmação pela GUI. Libera imediatamente a limpeza, sem
  concluir a tarefa, conceder XP ou reembolsar contratação. Um passageiro termina
  sua viagem e retorna fisicamente à saída do térreo. Salário deixa de contar após
  remoção do funcionário; IDs nunca são reutilizados.
- Supervisão mostra delegados, pessoas em tarefa, pendências, pausados e salários
  por papel. Jogador não conta como funcionário. Operação e ações manuais continuam
  acessíveis para resolver as pendências observadas.

## Persistência

Domínio v9 adiciona evolução de funcionário, qualidade/idade de limpeza e contagem
de desligamentos. Evolução guarda XP, tarefas, traços, pausa, prioridade e saída;
nível e atributos efetivos são derivados. Migrações v1–v8 preservam Cash, habilidades,
velocidade, tarefas manuais e transporte. Funcionários antigos começam com XP zero
e sem traços inventados; salas antigas recebem qualidade zero e idade desconhecida.

Restore rejeita campos ausentes, traços duplicados/irrelevantes, excesso de traços,
XP inconsistente com tarefas, prioridades inválidas e atribuição retida por quem sai.
Versão futura não é substituída. Timers e saídas param em background; settlement
offline agregado é Sprint 5.

## Política medida e critério

Teste compara 1.200 segundos em cinco sementes com 2.400 Cash iniciais, recepção,
quarto e restaurante. A política manual cobre recepção e limpeza. A outra contrata
os dois papéis com receita obtida e reserva uma diária de manutenção/salários após
contratação. O teste não injeta dinheiro, paga os custos reais e usa hóspedes reais.

Critérios: caixa nunca negativo; pelo menos seis hospedagens; redução de pelo menos
60% nas intervenções de recepção/limpeza após 600 segundos; retenção de pelo menos
85% das hospedagens da política manual, que tem limpeza mais rápida.

| Semente | Intervenções manual/equipe | Intervenções após 600s manual/equipe | Hospedagens manual/equipe | Cash final com equipe |
| --- | ---: | ---: | ---: | ---: |
| 1 | 46 / 6 | 24 / 0 | 21 / 21 | 2.456 |
| 17 | 47 / 5 | 26 / 0 | 23 / 21 | 2.370 |
| 123 | 50 / 6 | 25 / 0 | 22 / 20 | 2.373 |
| 9001 | 49 / 5 | 24 / 0 | 22 / 21 | 2.456 |
| 54321 | 50 / 7 | 27 / 0 | 21 / 20 | 2.317 |

As cinco políticas preservaram caixa não negativo e 91–100% das hospedagens.
A reserva de diária é uma decisão de gestão; contratar sem capital de giro pode
criar déficit antes da próxima receita. Qualidade, filas, preço e capacidade continuam
dependendo do hotel. Estes resultados medem a política determinística, sem provar
retenção ou ergonomia humana. Evidência final fica em `SPRINT4_VALIDATION.json`.
