# N4/N5 e posicionamento dos quartos

Contrato de balanceamento da Sprint 5. Valores em Resources; o save guarda IDs,
níveis e condições de estadias aceitas. Não existe compra premium de atributos.
O agente valida domínio e interação; o teste do usuário permanece na Sprint 15.

## Objetivo e unidade

N4/N5 aprofundam eficiência, capacidade e qualidade dos três espaços centrais.
N4 exige `steady_service`; N5 exige `trusted_hotel`. O acesso legado ao N3 não
libera esses níveis. Elevadores mantêm N1–N3; café/lounge mantêm os níveis atuais.
As três especializações de quarto exigem N3 e `first_stays`, sem novo bloqueio
de moeda. Uma reforma custa Cash e 5 minutos do relógio de construção, usa uma
das duas equipes gratuitas e pode entrar na fila existente. O quarto continua
operando com seu posicionamento anterior até a conclusão. Reconfigurar exige
outra reforma. Cancelar devolve o capital; um speedup consumido não retorna.

Cash é a moeda do hotel. Manutenção é cobrada por dia simulado de 120 segundos;
timers de obra usam milissegundos do relógio da aplicação. Uma estadia básica
tem limite de idade de 100 segundos simulados, multiplicado pelo perfil do
hóspede e pelo contrato do quarto no check-in. Esses relógios são distintos.

## Valores autorais e efeitos previstos

Os bônus de nível são absolutos sobre a definição N1, não cumulativos. A tarifa
75/100/125% é aplicada depois do posicionamento, arredondando para inteiro.

| Espaço / nível | Custo da melhoria | Preço a 100% | Manutenção/dia | Capacidade | Atendimento | Bônus de qualidade |
|---|---:|---:|---:|---:|---:|---:|
| Quarto N3 | 600 | 210 | 17 | 1 | 14s de descanso | +4 |
| Quarto N4 | 1.000 | 230 | 14 | 1 | 14s de descanso | +6 |
| Quarto N5 | 1.600 | 260 | 18 | 1 | 14s de descanso | +8 |
| Recepção N3 | 700 | — | 21 | 1 | 2s | 0 |
| Recepção N4 | 1.300 | — | 26 | 1 | 1,6s | +2 no check-in |
| Recepção N5 | 2.000 | — | 30 | 1 | 1,2s | +4 no check-in |
| Bistrô N3 | 1.000 | 40 | 30 | 5 | 5,6s | +4 |
| Bistrô N4 | 1.600 | 42 | 38 | 6 | 5,2s | +4 |
| Bistrô N5 | 2.400 | 44 | 46 | 7 | 4,8s | +6 |

| Posicionamento | Custo | Preço adicional | Manutenção adicional/dia | Limite de estadia | Efeito de satisfação |
|---|---:|---:|---:|---:|---|
| Executivo | 650 | +30 | +6 | ×0,90 | +4 negócios; −2 equilibrado; −4 lazer; −8 adicional se condição <90 |
| Conforto | 550 | +10 | +4 | ×1,15 | +4 por descanso; prefere público de lazer |
| Econômico | 400 | −25 | −6 | ×0,85 | −1 por descanso; prefere público equilibrado |

Previsões: executivo monetiza hóspedes de negócios, mas exige manutenção;
conforto favorece descanso e permanência, com menor giro; econômico melhora
acessibilidade e giro, exigindo mais limpezas por tempo ocupado. Nenhum deve
dominar tarifa, custo, qualidade e giro ao mesmo tempo. O bônus de nível segue
válido em todos. A recepção melhora a experiência de admissão; o bistrô melhora
vazão real e cobra maior manutenção.

A seleção primeiro exclui quartos sujos, ocupados, reservados para trabalho,
inacessíveis ou fora do orçamento. Depois escolhe a maior preferência autoral
do perfil. Empates preservam a ordem de construção. Hotel sem especializações
mantém a seleção anterior e não consome RNG adicional. Não altera o mix de
chegadas. A idade-limite contratada persiste mesmo que o quarto seja reformado
durante a visita. O descanso usa a qualidade vigente do quarto.

## Contextos, horizonte e limites de avaliação

Verificação determinística: todos os níveis, três tarifas, três perfis,
fronteiras de condição 89/90, orçamento exato, prazo da obra −1/0/+1ms,
fila/cancelamento e restauração de contratos. A receita deve ser debitada do
hóspede e creditada uma única vez ao hotel. Cash + capital líquido + despesas
− receita mantém o patrimônio inicial da fixture. Renovar e concluir uma obra
não fabrica receita nem avança o fixed tick.

Estudo de contexto: cinco sementes, hotel operacional com três quartos N3,
recepção/bistrô e equipe, aberto por 600 segundos simulados, comparando os três
posicionamentos com baseline neutra. Capital inicial de 100.000 é uma fixture
de laboratório para eliminar falência como variável; não prova a progressão
F2P nem viabilidade de IAP. Medir reservas, saídas, receita, despesas, limpezas,
reputação e resultados por perfil. Resultados e limites observados serão
registrados com a evidência, sem inventar metas de retenção humana.

Guardrails: sem reembolso duplicado, sem acesso antecipado por save legado,
sem alteração retroativa da duração, sem consumo de speedup para obra em fila,
sem inflação de estoque ou capital. Save de versão futura bloqueia downgrade
antes de procurar backup. Migrações v1–v9 preservam a entrada e introduzem
posicionamento neutro e fator contratado 1,0; construção v1 migra para v2.

Telemetria futura deve responder se um ramo domina por perfil e tarifa. Medir
escolhas, hóspedes admitidos/recusados, receitas por estadia e tempo até reforma
sem dados pessoais. Uma dominância persistente exige ajuste do Resource e
repetição dos contextos acima; conversão paga não é critério de qualidade.
