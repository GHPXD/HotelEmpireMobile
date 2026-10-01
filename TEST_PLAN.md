# Plano de Testes — Hotel Empire Mobile

## Princípio

A migração não deve trocar profundidade por regressões. Testes de domínio permanecem como rede de segurança enquanto UI, input e serviços de plataforma são reconstruídos.

Classificação detalhada: [TEST_MIGRATION_MATRIX](docs/TEST_MIGRATION_MATRIX.md).
Executor portátil: `python tools/run_tests.py --group all --godot <executável>`.
Relatórios completos e dados isolados ficam em `.runtime/tests/`.
Validações intermediárias são automatizadas e conduzidas pelo agente; avaliação do
usuário somente no Sprint 15. Registrar limitações reais de hardware/toolchains.

## 1. Domínio

Preservar e ampliar cobertura de:

- construção;
- economia;
- hóspedes;
- filas;
- funcionários;
- transporte;
- upgrades;
- progressão;
- reviews;
- eventos;
- save/restore;
- determinismo;
- stress.

Testes de domínio não devem depender de dispositivo.

## 2. Save e lifecycle

Cobrir:

- primeiro boot;
- autosave;
- app background;
- app foreground;
- encerramento abrupto;
- processo morto pelo OS;
- save corrompido;
- backup;
- migration;
- timers em andamento;
- economia premium;
- entitlements;
- offline time.

## 3. Touch

Cobrir em dispositivo:

- tap em sala;
- tap em hóspede;
- tap em terreno;
- drag;
- pinch;
- long press se usado;
- cancelar;
- Android back;
- múltiplos toques;
- gesture durante modal;
- conflito entre scroll e pan.

## 4. Layout

Matriz mínima:

- telefones pequenos;
- telefones longos;
- tablets;
- notch;
- camera cutout;
- gesture bar;
- safe area;
- landscape e portrait enquanto a decisão de orientação estiver aberta.

Não considerar resolução de desktop como evidência de qualidade mobile.

## 5. Performance

Medir:

- cold boot;
- warm resume;
- RAM;
- VRAM/GPU memory quando disponível;
- tamanho do pacote;
- frame time;
- bateria;
- temperatura;
- tempo de carregamento;
- 30/60 FPS conforme tier;
- população alta;
- hotel grande;
- múltiplos overlays.

Criar tiers de aparelho low/mid/high.

## 6. Offline progress

Validar:

- minutos;
- horas;
- limite máximo;
- clock skew;
- relógio alterado;
- DST/timezone;
- construção concluída offline;
- custos;
- receita;
- ausência de simulação tick-a-tick de horas.

## 7. Rewarded Ads

Casos:

- ad disponível;
- indisponível;
- usuário fecha;
- falha de rede;
- callback duplicado;
- reward concedida uma única vez;
- app vai a background;
- provider demora;
- compra Remove Ads;
- rewarded continua opcional conforme design.

Nunca conceder recompensa apenas porque o anúncio foi solicitado.

## 8. IAP

Cobrir:

- compra aprovada;
- cancelada;
- pendente;
- falha;
- callback repetido;
- restore;
- reinstalação;
- item consumível;
- non-consumable;
- entitlement;
- perda de rede;
- reinício durante compra.

## 9. Economia

Testar invariantes:

- Gems nunca negativas;
- Cash nunca sofre mutação por SDK;
- entitlement idempotente;
- reward idempotente;
- timers não podem ser concluídos duas vezes;
- prestige não apaga progressão permanente.

## 10. Analytics

Eventos não podem:

- duplicar transações;
- conter PII desnecessária;
- bloquear gameplay;
- lançar erro se analytics estiver offline.

## 11. Localização

Cobrir:

- strings ausentes;
- textos longos;
- pluralização;
- moedas;
- formatos numéricos;
- fallback de idioma.

## 12. Regressão visual

Usar screenshots mobile por estado importante, não screenshots de desktop.

Estados:

- hotel vazio;
- seleção;
- construção;
- upgrade;
- missão;
- loja;
- offline summary;
- rewarded offer;
- purchase;
- evento;
- cinco estrelas.

## 13. Release gate

Nenhum release sai se houver:

- perda de save;
- duplicação de compra/reward;
- crash reproduzível de lifecycle;
- overflow de safe area em device suportado;
- regressão grave de performance;
- monetização obrigatória para progressão base.
