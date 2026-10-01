# Economia e Monetização

## 1. Filosofia

O jogo deve continuar completo sem pagamento.

O jogador paga principalmente por:

- velocidade;
- conveniência;
- expressão;
- conteúdo opcional.

Não criar frustração artificial para vender a solução.

## 2. Moedas

### Hotel Cash

Economia operacional de cada hotel.

Usos:

- construção;
- salário;
- manutenção;
- upgrade;
- operação.

Fontes:

- hospedagem;
- serviços;
- eventos;
- contratos;
- missões específicas.

### Gems

Moeda premium da conta.

Fontes:

- IAP;
- achievements;
- eventos;
- progressão limitada.

Usos:

- aceleração;
- conveniência;
- itens premium;
- cosméticos;
- ofertas.

Gems não devem ser necessárias para concluir o conteúdo base.

### Empire Points

Metaprogressão.

Obtidos principalmente ao:

- completar/franquear hotéis;
- atingir marcos de rede.

Usados em:

- bônus permanentes;
- unlocks de metagame;
- qualidade de vida da rede.

### Speedups

Consumíveis de tempo.

Exemplos:

- 5 min;
- 15 min;
- 1 h.

Fontes:

- missão;
- evento;
- progressão;
- loja;
- passe futuro.

## 3. Rewarded Ads

Rewarded é o formato principal de publicidade.

Possíveis ofertas:

- reduzir timer;
- aumentar retorno offline;
- multiplicar recompensa de missão;
- boost temporário;
- equipe emergencial;
- marketing;
- VIP/evento;
- reroll limitado.

### Regras

- sempre voluntário;
- reward clara antes do anúncio;
- reward concedida somente após callback válido;
- nenhum spam modal;
- não ser obrigatoriamente melhor que jogar;
- limitar frequência quando necessário.

## 4. Interstitial

Não faz parte do core de monetização inicial.

Se usado futuramente:

- apenas em transições naturais;
- frequência baixa;
- nunca durante decisão crítica ou operação ativa;
- removível por compra Remove Ads.

## 5. IAP inicial

### Gems

- Small;
- Medium;
- Large.

### Starter Pack

Oferta de boa conversão inicial.

Pode conter:

- Gems;
- Cash;
- speedups;
- cosmético.

Não incluir poder permanente desproporcional.

### Remove Ads

Remove formatos interruptivos caso existam.

Rewarded pode continuar opcional, pois o jogador escolhe assistir em troca de recompensa.

### Cosmetic Pack

Tema/visual sem vantagem crítica.

## 6. Hotel Pass

Não lançar no MVP.

Condições mínimas antes de implementar:

- boa retenção;
- eventos recorrentes;
- pipeline de conteúdo;
- calendário operacional;
- recompensas suficientes para uma trilha.

## 7. Construção e Gems

Fluxo recomendado:

```
timer
├── esperar
├── rewarded → reduzir tempo
├── speedup → reduzir tempo
└── Gems → concluir/avançar
```

Gems não devem ser a única maneira razoável de avançar.

## 8. Offline earnings

Valor base deve ser satisfatório.

Rewarded pode oferecer:

- +50%;
- x2 em contexto balanceado;
- bônus limitado.

Evitar criar valor base artificialmente baixo para forçar anúncio.

## 9. Sources e sinks

Cada moeda precisa de mapa explícito.

### Cash sources

- hospedagem;
- alimentação;
- room service;
- serviços;
- reservas;
- contratos.

### Cash sinks

- construção;
- upgrade;
- salário;
- manutenção;
- incidentes;
- expansão.

### Gems sources

- IAP;
- progressão limitada;
- eventos;
- achievement.

### Gems sinks

- timer;
- conveniência;
- cosméticos;
- ofertas.

### Empire sources

- prestige;
- marcos.

### Empire sinks

- bônus permanentes;
- unlocks de rede.

## 10. Proteção econômica

Requisitos técnicos:

- transações idempotentes;
- callbacks duplicados seguros;
- save versionado;
- entitlements separados;
- receipt/store state quando necessário;
- nenhuma recompensa concedida duas vezes.

## 11. Balanceamento

Monitorar:

- Cash earned/spent por sessão;
- tempo até primeiro bloqueio;
- tempo até primeiro funcionário;
- tempo até ★2/★3/★4/★5;
- Gems source/sink;
- rewarded acceptance;
- purchase conversion;
- ARPDAU quando houver escala;
- progressão de pagadores e não pagadores.

## 12. Remote Config

Valores candidatos:

- recompensas;
- cooldowns;
- timers;
- limites;
- multiplicadores;
- preços de soft currency;
- oferta de rewarded.

Não usar Remote Config para corrigir arquitetura ou lógica crítica.

## 13. Guardrails

Nunca:

- cobrar para recuperar save;
- vender solução para bug;
- bloquear conteúdo principal por rewarded;
- reduzir deliberadamente performance para vender speedup;
- esconder preço;
- criar confirmação ambígua;
- perder entitlement após reinstalação/restauração suportada.
