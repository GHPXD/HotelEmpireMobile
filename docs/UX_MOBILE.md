# UX Mobile

## 1. Objetivo

Fazer o hotel parecer um jogo nativo de celular, não uma interface de PC reduzida.

## 2. Orientação

Landscape e portrait devem ser prototipados em dispositivo.

Critério de decisão:

- leitura do hotel;
- construção;
- alcance com polegar;
- espaço para bottom sheet;
- clareza de personagens;
- experiência em tablets;
- retenção em playtest.

A orientação final não deve ser escolhida apenas por convenção de mercado.

Implementado no Sprint 2: ambas as orientações por sensor. Contexto abaixo do
hotel em portrait estreito e lateral em landscape/tablets, sem sobrepor o world.
Navegação horizontal mantém uma linha mesmo no celular de 568x320; portrait
estreito usa duas. Feedback compacto libera altura em landscape curto. Targets
e scroll preservam 48 unidades lógicas com densidade 1x/2x/3x. O slot da prévia
não muda quando o sheet redimensiona o world; o alvo selecionado continua visível.
Evidências: `SPRINT2_VALIDATION.json`; ergonomia em aparelho é gate do Sprint 15.

## 3. Navegação

Estrutura base proposta:

```
Top bar
- Cash
- reputação/estrelas
- hóspedes
- Gems

World
- hotel

Bottom navigation
- Hotel
- Construir
- Missões
- Equipe
- Loja
```

## 4. Bottom sheets

Usar bottom sheet/context panel para:

- sala;
- hóspede;
- funcionário;
- construção;
- upgrade;
- evento;
- missão;
- compra.

Evitar múltiplas janelas sobrepostas.

## 5. Gestos

### Tap

- selecionar;
- confirmar;
- abrir detalhes.

### Drag

- mover câmera.

### Pinch

- zoom.

### Long press

Somente se oferecer valor real e não ocultar ação essencial.

### Android back

Prioridade:

1. fechar overlay;
2. fechar screen;
3. voltar;
4. pedir saída apenas quando realmente necessário.

## 6. Construção

Fluxo:

```
Construir
→ escolher categoria
→ escolher sala
→ preview no hotel
→ tap para posicionar
→ confirmar
```

Feedback imediato para:

- espaço insuficiente;
- andar bloqueado;
- custo insuficiente;
- dependência;
- slot cheio.

## 7. Jogador manual

Ações iniciais devem ser rápidas.

Exemplos:

- tap no balcão para check-in;
- tap/swipe curto para limpeza;
- tap em reparo;
- tap para entregar pedido.

Não criar microtarefas repetitivas longas.

## 8. Informação

Prioridade visual:

1. problema atual;
2. ação disponível;
3. consequência;
4. detalhe.

Evitar despejar métricas técnicas.

## 9. Gargalos

Sempre explicar causa.

Exemplo:

```
Fila alta na recepção
Causa: 1 recepcionista para 12 hóspedes
Sugestão: contratar ou melhorar recepção
```

## 10. Feedback

Usar:

- animação;
- som;
- texto curto;
- haptic leve quando apropriado.

Não depender exclusivamente de cor.

## 11. Safe area

Nenhum controle essencial pode ficar sob:

- notch;
- cutout;
- gesture bar;
- cantos arredondados.

## 12. Acessibilidade

Planejar desde o início:

- tamanho mínimo de touch target;
- contraste;
- texto escalável;
- ícone + texto em ações críticas;
- feedback sem cor exclusiva;
- redução de motion quando aplicável.

## 13. Loja

A loja deve separar:

- Gems;
- packs;
- cosmetics;
- entitlements.

Mostrar claramente:

- conteúdo;
- preço;
- benefício;
- tipo de item.

## 14. Rewarded

Oferta deve mostrar:

```
Assistir anúncio
→ benefício exato
```

Nunca abrir rewarded por engano ou sem ação explícita.

## 15. Offline return

Tela resumida:

```
Enquanto você esteve fora

Receita
Custos
Lucro

Construções concluídas
Ocorrências

[Coletar]
[Rewarded: bônus]
```

## 16. Tablets

Não apenas esticar celular.

Usar espaço adicional para:

- painel contextual lateral;
- hotel maior;
- múltiplas informações sem sobreposição.
