# Hotel Empire Mobile

Hotel Empire Mobile é um tycoon/simulation game em Godot 4 no qual o jogador começa operando um pequeno hotel pessoalmente e progride até administrar uma rede de hotéis.

Este repositório é exclusivo da versão mobile. A base de simulação foi herdada do protótipo de PC, mas UX, progressão, economia, monetização, assets, lifecycle, testes e distribuição passam a ser definidos para Android e iOS.

## Visão do produto

A fantasia de progressão é:

```
Eu faço tudo sozinho
→ contrato meu primeiro funcionário
→ formo uma equipe
→ automatizo setores
→ contrato supervisores e gerentes
→ conquisto cinco estrelas
→ franquio/vendo o hotel
→ abro um novo hotel
→ construo um império hoteleiro
```

O jogo deve ser fácil de operar no celular, mas manter uma simulação profunda por baixo. Hóspedes, filas, quartos, serviços, funcionários, elevadores, limpeza, preço, manutenção, eventos e reputação devem continuar interagindo de forma sistêmica.

## Princípios

1. Mobile-first: toda interação deve funcionar naturalmente por toque.
2. Profundidade sem fricção: simplificar a interface, não a simulação.
3. Progressão visível: sempre deve existir um próximo objetivo compreensível.
4. Monetização opcional: anúncios e compras aceleram ou personalizam; não substituem jogar bem.
5. Rewarded-first: publicidade deve ser voluntária.
6. Economia separada: Hotel Cash, Gems e Empire Points têm funções diferentes.
7. Offline-friendly: construção, upgrades e ganhos offline precisam sobreviver ao fechamento do app.
8. Data-driven: balanceamento, monetização e LiveOps devem ser mensuráveis.
9. Conteúdo escalável: novos hotéis e mapas devem reutilizar a mesma fundação sistêmica.
10. Performance como feature: memória, bateria, boot e tamanho de pacote são requisitos de produto.

## Core loop

```
operar hotel
→ receber hóspedes
→ resolver gargalos
→ gerar receita
→ construir e melhorar
→ contratar e automatizar
→ cumprir objetivos
→ aumentar estrelas
```

## Meta loop

```
hotel
→ ★★★★★
→ franquia/prestige
→ Empire Points
→ bônus permanentes
→ novo hotel / novo mapa
→ rede de hotéis
```

## Monetização prevista

A primeira versão comercial deve priorizar:

- Rewarded Ads;
- Gems;
- Starter Pack;
- Remove Ads;
- cosméticos;
- speedups.

Hotel Pass, temporadas complexas e sistemas avançados de LiveOps só entram após retenção e conteúdo recorrente justificarem sua existência.

## Estrutura

- `core/`: sessão, eventos, save e serviços de aplicação.
- `core/application/`: AppRoot, GameController e adaptadores de analytics/config.
- `ui/mobile/`: shell, painéis de gestão, traduções, escala, gestos e safe area.
- `simulation/`: regras e sistemas de simulação.
- `hotel/`: modelo, construção, salas e transporte.
- `entities/`: hóspedes e funcionários.
- `progression/`: objetivos e upgrades.
- `data/`: conteúdo configurável.
- `assets/`: arte e áudio de runtime.
- `tests/`: regressões de domínio, fluxo mobile por toque e renderização.
- `tools/`: balanceamento, assets, testes e automação.
- `docs/`: especificações ativas do produto mobile.

## Documentação

- [Arquitetura](ARCHITECTURE.md)
- [Game Design](GAME_DESIGN.md)
- [Roadmap](ROADMAP.md)
- [Plano de testes](TEST_PLAN.md)
- [Guia de assets](ASSET_GUIDE.md)
- [Produto Mobile](docs/PRODUCT_MOBILE.md)
- [Economia e Monetização](docs/ECONOMY_MONETIZATION.md)
- [UX Mobile](docs/UX_MOBILE.md)
- [Trabalho e onboarding](docs/PLAYER_WORK.md)
- [Analytics e LiveOps](docs/ANALYTICS_LIVEOPS.md)
- [Testes e Release Mobile](docs/TEST_RELEASE_MOBILE.md)
- [Migração](docs/MIGRATION.md)

## Status

O repositório está no início da migração mobile. A simulação existente é a fundação a ser preservada; interface, input, progressão de longo prazo, monetização, lifecycle e distribuição mobile serão reconstruídos em sprints.

Não considerar este estado atual como build mobile final.

Sprints 0–3 implementados e validados no host: domínio preservado, entry point
mobile, save/lifecycle e gestão completa por toque. Construção, tarifas, upgrades,
equipe, assignments, operações, finanças, reviews e settings usam painéis Control;
UI, atalhos e janelas desktop foram removidos. A matriz inclui seis dimensões,
PT-BR/EN/ES, texto ampliado, cutouts e densidades 1x/2x/3x.
Evidências: [Sprint 2](docs/SPRINT2_VALIDATION.json).
O APK de debug fica em `builds/android/HotelEmpireMobile.apk`.
Sprint 3 adiciona trabalho físico de check-in, limpeza, reparo e room service,
cancelamento seguro, desgaste, snapshot v8 e guia retomável de nove etapas.
Perfil mobile novo começa com 2.400 Cash; perfis existentes preservam patrimônio.
Evidências: [Sprint 3](docs/SPRINT3_VALIDATION.json), com 31 suítes aprovadas,
4.274 verificações renderizadas, 98 capturas e APK Android debug 0.5.0.
Próxima etapa: Sprint 4, XP/níveis/traits e supervisão da equipe.

Executar regressões: `python tools/run_tests.py --group all --godot <executável>`.
Renderização no host Windows: `tools/test_mobile_render.ps1 -GodotPath <executável>`.
Relatórios e screenshots ficam isolados em `.runtime/`; não são evidência de aparelho real.
