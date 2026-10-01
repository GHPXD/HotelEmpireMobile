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

A escolha será feita pelo agente após protótipos automatizados de landscape e
portrait, incluindo telefones estreitos e tablets. Medidas de layout e screenshots
são evidência de legibilidade/área disponível, não um playtest em aparelho real.
Arquitetura responsiva deve permitir adaptação posterior sem reescrever o domínio.
