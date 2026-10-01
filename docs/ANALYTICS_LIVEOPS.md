# Analytics e LiveOps

## 1. Objetivo

Medir comportamento sem acoplar gameplay ao provider de analytics.

Analytics observa o jogo; não controla o domínio.

## 2. Eventos essenciais

### Lifecycle

- app_open;
- session_start;
- session_end;
- background;
- resume.

### Tutorial

- tutorial_start;
- tutorial_step;
- tutorial_complete;
- tutorial_abandon.

### Gameplay

- room_build_started;
- room_build_completed;
- room_upgrade_started;
- room_upgrade_completed;
- staff_hired;
- staff_upgraded;
- mission_started;
- mission_completed;
- star_earned;
- hotel_completed;
- prestige_started;
- prestige_completed.

### Economy

- soft_currency_earned;
- soft_currency_spent;
- premium_currency_earned;
- premium_currency_spent;
- speedup_used.

Campos devem usar reason/source bem definidos.

Implementado no componente de speedups da Sprint 5: `speedup_used` é emitido após
consumo durável, com `kind` (ID público) e `duration_seconds` (redução real).
Back, erro de storage e callback duplicado não geram outro consumo/evento. O contrato
local rejeita recibos e campos fora do schema e conserva a fila limitada quando
provider está indisponível; envio a um SDK real permanece nos gates de integração.

### Ads

- rewarded_offer_viewed;
- rewarded_started;
- rewarded_completed;
- rewarded_failed;
- rewarded_reward_granted.

### IAP

- store_viewed;
- product_viewed;
- purchase_started;
- purchase_success;
- purchase_cancelled;
- purchase_failed;
- restore_started;
- restore_completed.

Nunca enviar recibos sensíveis como propriedade analítica comum.

### Offline

- offline_return;
- offline_duration_bucket;
- offline_base_reward;
- offline_bonus_selected.

### Events

- event_started;
- event_choice;
- event_completed;
- reservation_offered;
- reservation_accepted;
- reservation_declined;
- reservation_result.

## 3. Funil inicial

Medir:

```
install/open
→ tutorial start
→ primeira tarefa
→ primeiro quarto
→ primeiro hóspede
→ primeiro funcionário
→ primeiro upgrade
→ primeira estrela
→ segundo dia
```

## 4. Retenção

Acompanhar:

- D1;
- D3;
- D7;
- D14;
- D30 quando houver volume.

Analisar por:

- versão;
- país/idioma;
- device tier;
- aquisição;
- progressão.

## 5. Economia

Dashboards:

- cash source/sink;
- gems source/sink;
- tempo por milestone;
- timer distribution;
- speedup usage;
- rewarded usage;
- bloqueios de progressão.

## 6. Monetização

Medir:

- ad offer rate;
- accept rate;
- completion rate;
- rewards/user;
- payer conversion;
- first purchase time;
- product mix;
- restore success.

Interpretar métricas junto de retenção. Receita isolada não é critério suficiente.

## 7. Remote Config

Pode controlar parâmetros já desenhados para configuração:

- timers;
- reward multipliers;
- cooldowns;
- limites;
- valores econômicos;
- frequência de ofertas.

Toda chave precisa de:

- default local;
- tipo;
- range;
- owner;
- versão.

## 8. Experimentos

Experimentos só depois de baseline estável.

Boas hipóteses:

- duração de timer;
- recompensa de missão;
- apresentação de oferta;
- onboarding;
- offline bonus.

Não experimentar simultaneamente muitas variáveis do mesmo loop.

## 9. LiveOps

Fase inicial:

- eventos simples;
- desafios;
- bônus temáticos.

Fase posterior:

- calendário;
- seasons;
- pass;
- conteúdo recorrente.

Não construir infraestrutura de LiveOps complexa antes de validar retenção.

## 10. Privacidade

Princípios:

- coletar apenas o necessário;
- não registrar PII desnecessária;
- documentar providers;
- respeitar consentimento aplicável;
- analytics nunca bloqueia o jogo;
- falha de rede nunca impede sessão.

## 11. Crash e performance

Telemetria deve permitir correlacionar:

- crash;
- ANR;
- memory warning;
- frame degradation;
- device tier;
- versão;
- hotel/população.
