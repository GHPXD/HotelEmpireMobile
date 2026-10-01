# Decisões da migração

## Autoridade e validação

O prompt preservado em `MOBILE_MIGRATION_BRIEF.md` e a documentação mobile são
o contrato. O usuário autorizou decisões técnicas/de produto coerentes com esse
contrato e pediu que o agente execute todas as validações intermediárias.
O usuário avalia o resultado na última sprint. Não solicitar teste manual para
encerrar sprints anteriores; registrar evidência automatizada e limitações reais.

## Monetização inicial

- Rewarded voluntário, com oferta/benefício explícitos e entrega somente após callback confirmado.
- Gameplay e progressão completos sem anúncios ou compras.
- Packs de Gems pequeno/médio/grande, Starter Pack e cosméticos. Preços apresentados pela loja, sem conversão monetária hardcoded.
- Sem Hotel Pass ou assinatura no lançamento.
- Sem anúncios interruptivos na primeira versão. Remove Ads terá contrato/restore testáveis, mas não será vendido enquanto não houver formato interruptivo a remover. Evita vender um benefício inexistente.
- Mock só em ambiente de desenvolvimento/teste. Produção sem provider configurado informa indisponibilidade e não simula compra concluída.
- Transações/entitlements pertencem ao progresso global; entrega persistida antes de acknowledgement/consumption. SDKs nunca alteram HotelEconomy.

Provider comercial, IDs reais, signing, consentimento e validação sandbox serão
fechados após fundação estável. Não inventar credenciais nem considerar mocks como
validação de compra em loja.

## Sequência

Sprint 0 remove apenas distribuição Windows e inventaria dívida desktop.
UI/input permanecem até haver substituição funcional no Sprint 2. Ferramentas
PowerShell úteis ao host e estudos de balanceamento são preservados.

O SaveService amplia o snapshot de domínio v7 com envelope versionado da
aplicação. O domínio preserva suas migrations; dados globais serão incorporados
ao envelope sem misturar Gems com HotelEconomy.

## Orientação

O produto mantém portrait e landscape por sensor, com adaptação de layout.
Portrait permite operação com uma mão; landscape e tablets oferecem contexto
lateral e mais largura para o hotel. A matriz local inclui 320x568, 568x320,
360x780, 844x390, 960x540 e 1280x800, cutouts, PT-BR/EN/ES e texto ampliado.
Não impor orientação única antes da avaliação final em aparelho no Sprint 15.

Em portrait estreito a navegação usa duas linhas. Em landscape sempre usa uma,
inclusive quando cutouts deixam menos de 540 unidades de largura. Em landscape
curto o feedback ocupa o topo do world, preservando espaço para hotel e contexto.
O scroll tem área mínima de 48 unidades; cabeçalho longo não pode consumir essa área.

A câmera inicial usa zoom mínimo de 0,8 e mostra o início do terreno no celular.
Pan alcança as demais colunas. A confirmação mantém coordenadas do slot original;
abrir contexto reposiciona a câmera apenas quando o alvo sai da área visível.
Arrastar conteúdo cancela ativação do botão e não move o hotel. Haptic leve de
construção/upgrade é opcional e persiste; som para em background.

A escala usa densidade do OS e preserva targets de 48 unidades lógicas, em vez de
reduzir a viewport de referência inteira para caber no celular. Foram verificadas
densidades 1x/2x/3x com canvas stretch e toques em coordenadas físicas.
API: [múltiplas resoluções no Godot](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html).
Android declara VIBRATE para a API de feedback:
[Input.vibrate_handheld](https://docs.godotengine.org/en/4.6/classes/class_input.html#class-input-method-vibrate-handheld).

Capturas e eventos locais comprovam layout e roteamento no renderer do host.
Efeito háptico físico, ergonomia, rotação/notch reportados pelo OS e performance
em Android/iOS continuam sendo gates próprios do Sprint 15.

## Operação inicial

Novo perfil mobile começa com 2.400 Cash, sem equipe e sem salas gratuitas;
recepção + quarto deixam 1.000 Cash para restaurante/expansão. O domínio de estudos
mantém 12.000 por compatibilidade das políticas de benchmark. Migração não reduz
Cash existente. Guia acompanha nove fatos, sem congelar simulação ou bloquear
compras; pode ser ocultado/retomado. Não cobra Gems/IAP para avançar o early game.

Uma tarefa manual física por vez: 1,5–3 segundos no alvo, mais caminhada/elevador.
Receita deriva de hóspede/orçamento real; reparo usa despesa de materiais somente
na conclusão. Wear máximo custa 20% de tempo adicional, sem fechar instalações;
incidentes e operação especializada ficam para Sprint 9. A tarefa e o cancelamento
têm prioridade acima do guia no sheet ativo, inclusive em landscape curto.

Política guiada de cinco seeds chegou à primeira hospedagem em 3,5–3,7 segundos
e à contratação em 96–135,5 segundos. Este resultado delimita a hipótese de pacing;
não demonstra compreensão espontânea ou retenção de jogadores reais.
