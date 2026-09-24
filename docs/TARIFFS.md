# Tarifas por sala

No inspetor de quartos e serviços, escolha Econômica (75%), Padrão (100%) ou
Premium (125%). A mudança é gratuita e vale apenas para a sala selecionada.
Recepção e elevador não têm tarifa. O preço efetivo aparece no inspetor e na
prévia do próximo upgrade.

O percentual incide sobre preço base mais bônus do nível; o resultado é
arredondado ao inteiro mais próximo, com mínimo de 1 para preços positivos.
Exemplo: Bistrô N1 de $28 custa $21, $28 ou $35.

Quartos cobram no check-in. Serviços combinam o valor ao admitir o hóspede e
cobram esse valor ao terminar. Alterar a tarifa não cobra novamente quem já
pagou pela hospedagem nem modifica contratos de serviço em andamento. Pessoas
na fila ainda precisam poder pagar o preço vigente quando forem admitidas.

Preços afetam a capacidade de pagamento e a escolha de serviços, que considera
o perfil do hóspede. Na hospedagem, econômica acrescenta 5–7,5 pontos de
satisfação no check-in, padrão é neutra e premium reduz 5–7,5, conforme o perfil.
O efeito é único e respeita o limite 0–100. A reputação resultante pode afetar
as chegadas pelo mecanismo já existente; não há elasticidade direta adicional
do preço sobre as chegadas. Detalhes em `LODGING_VALUE.md`.
Os três percentuais são opções iniciais de design; ainda não constituem uma
calibração econômica completa de todas as estratégias ao longo da campanha.

Save v5 persiste `price_percent` por sala. Saves v1–v4 migram para tarifa padrão,
sem alterar os dados de entrada. Percentuais desconhecidos, tipos inválidos e
tarifas de infraestrutura são rejeitados. O arquivo continua `hotel-v1.json`;
seu nome não indica a versão interna do schema.

Validação cobre preços reais, admissão de serviço com desconto, cobrança de
hospedagem, ausência de cobrança retroativa, contratos em curso, migração,
round-trip JSON e seleção pelo teclado. O diagnóstico do executável confere
persistência e visibilidade do controle nas resoluções testadas.
