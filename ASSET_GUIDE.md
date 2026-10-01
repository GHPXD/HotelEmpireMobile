# Guia de Assets — Mobile

## Objetivo

A direção visual pode reutilizar a identidade existente, mas o pipeline passa a ser orientado a memória, pacote e carregamento mobile.

## Problema atual

A base herdada contém dezenas de texturas grandes e muitas ainda sem limite de resolução no import. Isso não deve ser levado para Android/iOS sem budget explícito.

## Categorias

### UI icons

- tamanho de import pequeno;
- mipmaps apenas quando necessários;
- preferir atlas quando houver ganho;
- contraste legível em telas pequenas.

### Portraits

- resolução limitada;
- carregar sob demanda quando possível;
- não manter retratos não usados residentes sem necessidade.

### Rooms/environment

- definir size limit por tipo;
- validar leitura no zoom mínimo/máximo;
- evitar resolução invisível na tela;
- compressão adequada ao target mobile.

### Characters/animation sheets

- revisar folhas grandes;
- considerar atlas/spritesheet;
- evitar duplicação de frames;
- carregar grupos por hotel/tema;
- medir RAM depois do import, não apenas tamanho PNG.

## Import

Para cada categoria documentar:

- resolução fonte;
- size limit;
- mipmaps;
- compressão;
- memória estimada;
- plataforma.

Targets móveis devem priorizar formatos de textura adequados a Android/iOS.

## Budgets

Antes do release definir:

- budget de memória de textura;
- budget de RAM total;
- budget de pacote;
- budget por hotel/mapa;
- budget de UI;
- budget de personagens.

## Carregamento

O catálogo atual faz preload de muitos assets. A migração deve permitir carregar por contexto.

Exemplo:

```
Common
HotelTheme
RoomSet
GuestSet
UISet
```

## Documentação de arte

Não manter screenshots de QA, matrizes de desktop ou imagens de validação dentro de `docs/`.

Assets de runtime ficam em `assets/`.

Arquivos de referência de produção só permanecem no repo se forem necessários para reproduzir ou manter o asset.

## Safe area e UI

Assets de UI não devem depender de coordenadas absolutas.

Validar:

- notch;
- cantos arredondados;
- gesture bar;
- tablets;
- diferentes densidades.

## Naming

Usar nomes sem ambiguidade e por domínio:

```
room_bedroom_n1
room_bedroom_n2
guest_business_waiting
staff_cleaner_working
icon_build
icon_upgrade
```

## Regra

Qualidade visual só é aprovada quando também respeita memória, loading e legibilidade mobile.
