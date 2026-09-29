# Revisão local de distribuição — 29/09/2026

Resultado: pacote do protótipo preparado e verificado para testes externos.
Isso não conclui M10 nem autoriza publicação comercial.

Artefato revisado: `builds/HotelEmpire-windows-x86_64.zip`, revisão de código
`45d2eb60d45747a42cfc2cf96f9f2690ecac13ed`. O manifesto registra árvore limpa
no build. Evidência reproduzível: `python tools/audit_release.py`; saída em
`local-distribution-audit.json`. O comando falha se qualquer verificação divergir.

| Item | Evidência / resultado |
|---|---|
| Inventário do ZIP | Exatamente executável, guia, licença Godot, avisos de terceiros e manifesto; sem entradas adicionais ou duplicadas |
| Identidade do executável | SHA-256 e tamanho conferem com o manifesto |
| Guia e avisos | Bytes empacotados iguais aos arquivos fonte; guia explica instalação, controles, save, recuperação e limites |
| Arte | Todos os 31 PNGs em `assets/art` têm entrada única no manifesto e hash/tamanho conferidos |
| Funcionamento exportado | `reviews-cafe-matrix.json`: seis combinações locais; boot, operação, upgrades, save/load v6, avaliações, recuperação, ajuda e métricas |
| Teste sem repositório | `external-kit-local-matrix.json`: validação anterior do runner em Windows PowerShell 5.1; kit atualizado com o novo ZIP, cujo jogo passou na matriz local atual |
| Dados do jogador | Testes usam APPDATA isolado; o guia informa ausência de autosave e localização do save manual |
| Distribuição pública | Não publicada, não assinada; sem instalador, atualização automática ou requisito mínimo certificado |

A verificação dos avisos confirma presença e correspondência dos arquivos
documentados, não uma conclusão jurídica sobre distribuição comercial. Os avisos
do Godot não atribuem licença ao código ou à arte do Hotel Empire.

## Critério ainda aberto

Executar o kit em outro computador e revisar tanto `HotelEmpire-test-results.zip`
quanto o roteiro manual em `EXTERNAL-TEST.txt`. Registrar GPU, sistema, DPI,
problemas observados e passos para reproduzir. Resultados desta máquina não
substituem esse teste. Não declarar hardware mínimo a partir de um único host.

Os limites de produto continuam: 120 hóspedes na operação contínua medida,
desktop com mouse/teclado, animações de hóspedes sem poses próprias para
dormir/sentar, sem música ambiente. A visão de produto e a evolução futura
permanecem abertas; integridade do ZIP não é prova de conclusão do jogo.
