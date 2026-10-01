# Testes e Release Mobile

## 1. Plataformas

Targets:

- Android;
- iOS.

Web e desktop não são plataformas de release deste repositório.

## 2. Android

Validar:

- AAB;
- package id;
- signing;
- billing;
- ads;
- back button;
- lifecycle;
- processo morto;
- low memory;
- múltiplos aspect ratios;
- Play Store requirements vigentes no momento do release.

## 3. iOS

Validar:

- bundle id;
- signing;
- StoreKit/IAP;
- restore;
- safe areas;
- lifecycle;
- memory warnings;
- diferentes famílias de iPhone/iPad;
- App Store requirements vigentes no momento do release.

## 4. Device matrix

Definir aparelhos reais ou equivalentes representando:

### Low

- pouca RAM;
- GPU limitada;
- storage lento.

### Mid

Target principal.

### High

Valida qualidade máxima e scaling.

Não otimizar apenas pelo aparelho de desenvolvimento.

## 5. Performance gates

Antes de release medir:

- boot;
- resume;
- frame time;
- RAM;
- texture memory;
- loading;
- bateria;
- aquecimento;
- tamanho do pacote.

## 6. Lifecycle

Cenários obrigatórios:

- Home durante construção;
- Home durante rewarded;
- Home durante compra;
- retorno após horas;
- chamada/notificação;
- kill pelo sistema;
- restart;
- update do app.

## 7. Rede

O core deve funcionar sem internet quando não depende de provider externo.

Validar:

- offline boot;
- perda durante rewarded;
- perda durante compra;
- reconnect;
- analytics queue/failure;
- Remote Config indisponível.

## 8. Purchases

Release blocker se houver:

- duplicação;
- perda de entitlement;
- restore quebrado;
- item entregue sem compra confirmada;
- compra confirmada sem entrega recuperável.

## 9. Ads

Release blocker se:

- reward duplica;
- jogo trava sem ad;
- modal bloqueia progresso;
- provider failure quebra sessão.

## 10. Save

Release blocker se:

- save perde progresso;
- migration falha em versão suportada;
- timer duplica;
- premium currency corrompe;
- prestige apaga entitlement.

## 11. Store readiness

Checklist:

- nome;
- descrição;
- screenshots;
- vídeo opcional;
- ícone;
- classificação;
- privacy disclosures;
- links legais;
- suporte;
- produtos IAP configurados;
- ads/consent revisados.

## 12. Soft launch

Antes de escalar aquisição:

- estabilidade;
- crash-free;
- tutorial completion;
- D1;
- D7;
- economia;
- rewarded;
- primeiros IAP;
- feedback qualitativo.

## 13. Release decision

Não liberar globalmente apenas porque o build instala.

A decisão considera:

- estabilidade;
- retenção;
- clareza;
- economia;
- monetização saudável;
- performance;
- suporte operacional.
