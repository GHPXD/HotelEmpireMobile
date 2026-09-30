# Ícones da equipe

Dois PNGs RGBA 1254×1254 gerados diretamente no chat pelo image_gen integrado:
`assets/art/icons/receptionist.png` (prancheta e chave) e `cleaner.png` (balde e
esfregão). As cópias locais preservam os originais byte a byte. Prompts finais em
`staff-icons-prompts.json`; origem, alpha, hashes e dimensões em
`staff-icons-measurements.json` e no manifesto geral.

`HotelArt.STAFF_ICONS` mapeia funções, separado dos retratos e sprites animados.
Os botões de contratação mostram ícone de 36px e nome/preço em duas linhas,
com salário na tooltip. Mínimo de 58px de altura, filtro linear com mipmaps e
rolagem nativa. `HotelHUD.hire_buttons` mantém uma referência por função.

O painel de equipe exibe o mesmo ícone em 48px junto dos dados do funcionário
selecionado. A imagem identifica a função; o nome/ID continua na seleção nativa.
Decoração ignora mouse e foco. Lista vazia ou seleção indisponível limpa a imagem;
seleção indisponível desabilita a aplicação. Ícone centralizado verticalmente sem
esticar quando o texto ocupa mais linhas. Nenhum novo estado no save ou na simulação.

`tests/ui_management.gd` verifica duas funções × três resoluções × texto normal
ou ampliado: contratação por clique e Enter (24 contratações), função/custo,
bounds e rótulos, seleção e ícone da gestão, atribuições por teclado, restauração
de funcionários/atribuições, falta de dinheiro sem mutação e remoção do ícone
com lista vazia. A primeira fixture de atribuição não tinha elevador e usava
clique simulado sem ativar a janela; foi corrigida para hotel acessível e a rota
de teclado nativa já usada pela suíte.

O smoke exportado verifica as duas funções por clique nos botões, custo correto,
alpha, layout e ícone de gestão/limpeza quando a lista fica vazia, em cada caso
da matriz Windows. Não há alteração de preço, salário, regras ou lógica de trabalho.
