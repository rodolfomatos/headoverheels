# Head over Heels — 2026 Visual Reimagining & Sprite Generation System

## Contexto

Estás a trabalhar no repositório:

`https://github.com/rodolfomatos/headoverheels`

É uma implementação em Flutter/Flame de **Head over Heels**, o clássico jogo isométrico de 1987 para ZX Spectrum.

O projecto já possui:

* implementação funcional do jogo;
* mapas/salas;
* sistema de entidades;
* `CharacterState`;
* `AnimationState`;
* `FacingDirection`;
* `DualCharacterState`;
* tilesets/TSX;
* TMX;
* documentação de inventário;
* `docs/ASSET_INVENTORY.md`;
* `docs/SPRITE_GENERATION_SYSTEM.md`;
* estrutura de `assets/sprites/`;
* sistema AES/tickets.

Foi já feita uma auditoria do repositório e o objectivo desta tarefa é **evoluir o sistema de sprites**, não recomeçar o projecto.

---

# OBJECTIVO PRINCIPAL

Transformar o sistema gráfico actual numa **reimaginação visual de Head over Heels para 2026**.

Não queremos simplesmente:

> "sprites de ZX Spectrum com mais resolução".

Queremos:

> **uma interpretação moderna de Head over Heels que preserve a identidade visual, a linguagem isométrica, as proporções, os elementos reconhecíveis e o espírito do original, mas aproveite plenamente as capacidades gráficas contemporâneas.**

O ZX Spectrum deve ser tratado como **referência estética e histórica**, não como limitação técnica.

---

# PRINCÍPIO FUNDAMENTAL

## NÃO estamos a emular o hardware de 1987.

Não devemos limitar:

* número de cores;
* número de tonalidades;
* iluminação;
* sombras;
* transparências;
* efeitos;
* gradientes;
* materiais;
* partículas;
* resolução interna;
* detalhe;
* animação.

A estética deve continuar a ser claramente **pixel art / retro-isométrica**, mas com qualidade de produção contemporânea.

A pergunta correcta é:

> "Como seria Head over Heels se os seus criadores tivessem desenhado o jogo em 2026 mantendo a sua identidade?"

e não:

> "Como podemos imitar as limitações do ZX Spectrum?"

---

# 1. AUDITAR O ESTADO ACTUAL ANTES DE ALTERAR

Antes de modificar qualquer coisa:

1. Ler `README.md`.
2. Ler `docs/ASSET_INVENTORY.md`.
3. Ler `docs/SPRITE_GENERATION_SYSTEM.md`.
4. Inspeccionar `assets/`.
5. Inspeccionar todos os `.tsx`.
6. Inspeccionar todos os `.tmx`.
7. Inspeccionar:

   * `lib/entities/`
   * `lib/features/gameplay/entities/`
   * componentes de rendering;
   * `CharacterState`;
   * `AnimationState`;
   * `FacingDirection`;
   * `DualCharacterState`;
   * sistema de mapas;
   * sistema de colisões;
   * sistema de rendering.
8. Inspeccionar `pubspec.yaml`.
9. Inspeccionar `aes/` e documentação de tickets.
10. Não assumir que a documentação está correcta apenas porque existe.

Produzir primeiro uma breve síntese:

```text
CURRENT STATE
-------------
Gameplay:
Rendering:
Characters:
Entities:
Tiles:
Maps:
Existing assets:
Missing assets:
Sprite infrastructure:
Known inconsistencies:
```

---

# 2. NÃO DESTRUIR O TRABALHO EXISTENTE

Não apagar nem reescrever arbitrariamente:

* lógica de jogo;
* mapas;
* entidades;
* física;
* colisões;
* estados;
* carregamento de níveis;
* AES;
* documentação existente.

A tarefa é **incremental**.

Se alguma alteração estrutural for necessária, justificar primeiro no relatório.

---

# 3. NOVA FILOSOFIA VISUAL

Criar um sistema visual baseado nestes princípios:

### 3.1 Identidade Spectrum

Devem permanecer reconhecíveis:

* estética retro;
* pixel art;
* composição isométrica/dimétrica;
* silhuetas fortes;
* personagens visualmente simples;
* cores fortes;
* leitura imediata;
* sensação de jogo dos anos 80/90.

### 3.2 Mas sem limitações artificiais

Não impor:

* 8 cores;
* 16 cores;
* colour clash;
* restrições de atributos do Spectrum;
* ausência de alpha;
* ausência de sombras suaves;
* ausência de efeitos.

---

# 4. PALETA 2026

Esta é uma alteração deliberada relativamente ao plano anterior.

## NÃO congelar uma paleta Spectrum+ de 16 cores.

O Spectrum original deve fornecer a **base cromática**, mas a paleta final deve ser muito mais rica.

Criar o conceito:

```text
Spectrum DNA
     ↓
2026 Master Palette
     ↓
Theme Palettes
     ↓
Material Palettes
     ↓
Effects Palette
```

---

## 4.1 Spectrum DNA

Identificar as cores fundamentais associadas ao Spectrum:

* black
* blue
* red
* magenta
* green
* cyan
* yellow
* white

e respectivas variantes de luminosidade.

Estas cores não são limites.

São **referências de identidade**.

---

# 4.2 2026 Master Palette

Criar uma paleta contemporânea suficientemente grande para permitir:

* sombras;
* luz;
* volume;
* materiais;
* profundidade;
* transparências;
* água;
* fogo;
* metal;
* pedra;
* madeira;
* vegetação;
* pele;
* efeitos;
* partículas.

Não estabelecer previamente um número arbitrário de cores.

A paleta deve ser determinada através dos primeiros masters visuais.

Por exemplo:

```text
Core Spectrum colours
+
shadow ramps
+
highlight ramps
+
material ramps
+
environment colours
+
effect colours
```

---

# 4.3 Regras de cor

Mesmo tendo muito mais cores, a arte deve continuar coerente.

Aplicar:

* cores deliberadas;
* ramps curtas;
* saturação controlada;
* contraste forte;
* highlights selectivos;
* sombras consistentes;
* evitar fotorealismo;
* evitar gradients excessivamente suaves;
* evitar aparência de arte vectorial;
* evitar estética "AI glossy".

A imagem deve parecer **pixel art desenhada**, não uma imagem realista reduzida para pixels.

---

# 5. PIXEL ART 2026

A resolução física pode ser muito superior à original.

O importante é preservar:

* pixels visíveis;
* clusters de pixels;
* edges deliberados;
* silhuetas claras;
* shading em clusters;
* ausência de ruído.

Não usar:

* anti-aliasing automático;
* blur;
* sharpening fotográfico;
* subpixel rendering;
* outlines inconsistentes.

O resultado deve continuar a parecer desenhado pixel a pixel, mesmo que seja utilizado numa resolução moderna.

---

# 6. ISOMETRIA

Preservar a linguagem dimensional do original.

O sistema de referência continua a usar:

```text
logical tile:
64 × 32
```

ou a dimensão que o runtime actual realmente usar.

Não alterar arbitrariamente a geometria dos mapas.

O artwork deve adaptar-se ao sistema geométrico existente.

A regra visual é:

```text
2:1 dimetric / isometric
```

com:

* luz consistente;
* verticalidade clara;
* planos bem definidos;
* sombras coerentes.

---

# 7. LIGHTING

Estabelecer uma iluminação global:

```text
Key light:
top-left

Secondary:
subtle ambient fill

Contact:
strong contact shadows

Characters:
soft ground shadow

Objects:
contact + cast shadow when appropriate
```

Mas isto não significa realismo.

A iluminação deve ser estilizada.

Exemplo:

```text
floor
████████████
  shadow
    ↓

object
   ███
 ██████
   ███
    ↓
contact shadow
```

---

# 8. CHARACTERS

## Head

Preservar:

* cabeça arredondada;
* asas;
* identidade visual;
* proporção;
* expressão;
* leitura imediata.

Mas permitir:

* maior detalhe;
* olhos expressivos;
* shading;
* volume;
* materiais;
* highlights.

## Heels

Preservar:

* corpo;
* pernas;
* postura;
* identidade;
* proporções reconhecíveis.

Mas permitir uma interpretação moderna.

---

# 9. NÃO GERAR TODAS AS ANIMAÇÕES INDEPENDENTEMENTE

O estado lógico não deve determinar automaticamente o número de sprites.

Por exemplo:

```text
jumpRise
jumpPeak
jumpFall
```

não implica necessariamente três animações completas.

Criar um sistema baseado em:

```text
Logical state
      ↓
Visual requirement
      ↓
Minimal set of poses
```

Reutilizar poses quando isso não prejudicar a qualidade.

---

# 10. HEAD + HEELS / DUO

Não gerar inicialmente um conjunto completo de sprites "Duo".

A arquitectura preferida é:

```text
                  DUO
                   │
          ┌────────┴────────┐
          ↓                 ↓
        HEELS              HEAD
          │                 │
       animation         animation
          │                 │
          └────────┬────────┘
                   ↓
               COMPOSITOR
```

Criar:

```text
Head sprite
Heels sprite
Head anchor
Heels anchor
relative offset
z-order
shadow
animation synchronization
```

O Duo deve ser uma composição visual.

Só criar artwork específico para Duo quando uma pose não puder ser obtida correctamente através de composição.

---

# 11. TILE SYSTEM

## MUITO IMPORTANTE

Não assumir que os 256 slots correspondem à categorização inicialmente imaginada.

O `castle.tsx` real contém informação que deve ser tratada como fonte de verdade.

Construir:

```text
TSX
+
TMX
+
object layers
      ↓
Canonical Asset Inventory
```

Criar uma tabela:

```text
tile_id
tileset
source
semantic_role
geometry
used_by
visual_category
animated
collision
notes
```

---

# 12. TILE ID ≠ ENTITY

Separar explicitamente:

```text
TILE ART
ENTITY ART
CHARACTER ART
UI ART
EFFECT ART
```

Não tratar:

```text
fish
crown
monster
switch
door
conveyor
```

automaticamente como simples tiles.

Verificar no TMX se são:

* tile;
* object;
* entity;
* animation;
* collision object.

---

# 13. DUPLICATE TILE IDS

O inventário actual encontrou IDs aparentemente duplicados.

Exemplos incluem IDs na zona:

```text
65
74
75
76
```

Não "corrigir" estes IDs por intuição.

Determinar primeiro:

1. onde são usados;
2. em que tileset;
3. em que TMX;
4. se são context-dependent;
5. se são artefactos da exportação;
6. se representam realmente assets diferentes.

Documentar o resultado em:

```text
docs/TILE_ID_AUDIT.md
```

---

# 14. TILE GENERATION

Não gerar 256 imagens completamente independentes.

Usar:

```text
Master tile
    ↓
Tile family
    ↓
Variants
    ↓
Complete tileset
```

Exemplo:

```text
Stone floor master
   ├── clean
   ├── worn
   ├── cracked
   ├── dark
   ├── illuminated
   └── edge
```

O mesmo princípio deve ser usado para:

* paredes;
* portas;
* escadas;
* plataformas;
* conveyors;
* água;
* lava;
* props;
* decoração.

---

# 15. ENTITY GENERATION

Criar assets independentes para entidades.

Exemplos:

* fish;
* rabbit;
* crown;
* bag;
* key;
* spring;
* switch;
* door;
* teleport;
* monster;
* guardian;
* hush puppy;
* conveyor;
* etc.

Cada entidade deve ter:

```text
idle
movement
interaction
special state
death / disabled
```

apenas quando o gameplay realmente exigir.

Não criar animações que não sejam usadas.

---

# 16. UI

Criar uma linguagem visual coerente para:

* HUD;
* power-ups;
* inventory;
* menus;
* status;
* icons;
* dialogs.

A UI pode ser mais moderna que o Spectrum original, mas deve continuar pertencendo ao mesmo universo visual.

---

# 17. ASSET NAMING

Adoptar um naming consistente.

Por exemplo:

```text
characters/head/
characters/heels/

entities/fish/
entities/rabbit/
entities/crown/

tiles/castle/
tiles/egyptus/
tiles/penitentiary/
tiles/safari/
tiles/bookworld/

ui/
effects/
```

Os nomes devem ser semânticos.

Evitar nomes dependentes de prompts ou ferramentas de IA.

---

# 18. SPRITE REGISTRY

Implementar ou documentar claramente:

```text
Asset ID
      ↓
Sprite Registry
      ↓
Atlas region
```

Exemplo conceptual:

```text
head.walk.ne
heels.idle.s
entity.fish.swim.01
tile.castle.floor.stone.03
```

O gameplay nunca deve depender directamente de:

```text
assets/sprites/head_walk_NE_03.png
```

---

# 19. RENDERING

Investigar o rendering actual.

Actualmente existem componentes baseados em geometria/rectangles.

A migração deve ser incremental:

```text
Current renderer
      ↓
Sprite-capable renderer
      ↓
Asset registry
      ↓
Atlas
```

Não reescrever o rendering inteiro sem necessidade.

---

# 20. FIRST VERTICAL SLICE

Antes de produzir centenas de assets, criar apenas:

### Characters

```text
Head
  front
  side
  back

Heels
  front
  side
  back
```

### Duo

Uma composição funcional.

### Environment

```text
floor
wall
corner
edge
```

### Entities

```text
fish
crown
```

### Effects

Um efeito representativo.

### UI

Um pequeno conjunto de icons/HUD.

---

# 21. STYLE BOARD

Criar uma Style Board que permita avaliar:

```text
Head
Heels
Duo
Floor
Wall
Corner
Fish
Crown
Effect
UI
```

Todos juntos.

O objectivo desta fase não é testar quantidade.

É validar:

* proporção;
* escala;
* paleta;
* lighting;
* pixel density;
* outline;
* shading;
* silhouette;
* relação personagem/tile;
* coerência global.

---

# 22. CRITÉRIO DE APROVAÇÃO

Não avançar para produção massiva enquanto a Style Board não estiver visualmente coerente.

O processo deve ser:

```text
Generate
   ↓
Review
   ↓
Adjust
   ↓
Regenerate
   ↓
Approve
   ↓
Freeze visual language
```

Depois:

```text
Frozen Style System
        ↓
Mass generation
```

---

# 23. PIPELINE DE IA

A IA deve produzir **candidates**, não assets automaticamente aceites.

Pipeline:

```text
Reference
    ↓
Prompt
    ↓
AI generation
    ↓
Candidate
    ↓
Human review
    ↓
Pixel cleanup
    ↓
Normalization
    ↓
Validation
    ↓
Approved master
    ↓
Variants
    ↓
Atlas
```

---

# 24. PROMPTS

Actualizar:

```text
docs/SPRITE_GENERATION_SYSTEM.md
```

para que a definição de estilo seja reutilizável.

Criar:

```text
prompts/
├── style/
├── characters/
├── tiles/
├── entities/
├── ui/
└── effects/
```

O style prompt deve ser comum.

Os prompts específicos apenas acrescentam:

* personagem;
* pose;
* direcção;
* material;
* tema;
* animação;
* contexto.

---

# 25. REFERÊNCIAS

Usar as referências existentes:

* mapas;
* manual;
* TSX;
* TMX;
* sprites originais, quando existentes;
* screenshots;
* documentação.

Mas distinguir:

```text
REFERENCE
vs
COPY
```

A referência serve para preservar:

* identidade;
* composição;
* proporção;
* função;
* reconhecimento.

A arte final deve ser uma interpretação nova.

---

# 26. NÃO USAR O TERMO "ZX SPECTRUM PALETTE" COMO CONSTRAINT

No novo sistema, evitar instruções como:

> "Use only the 15 Spectrum colours."

ou:

> "Limit the image to 8 colours."

Em vez disso:

> "Use the ZX Spectrum colour language as chromatic inspiration while taking advantage of a modern expanded palette."

Esta diferença é fundamental.

---

# 27. 2026 VISUAL TARGET

O resultado pretendido deve situar-se conceptualmente entre:

```text
1987 Head over Heels
        +
modern pixel art
        +
modern indie game production
        +
high-quality dimetric environment art
```

Não deve parecer:

```text
NES
SNES
generic pixel art
mobile cartoon
AI concept art
vector art
photorealistic rendering
```

Deve parecer:

> **Head over Heels, se tivesse sido produzido em 2026.**

---

# 28. DOCUMENTAÇÃO

Actualizar:

```text
docs/SPRITE_GENERATION_SYSTEM.md
docs/ASSET_INVENTORY.md
```

Criar, se necessário:

```text
docs/TILE_ID_AUDIT.md
docs/VISUAL_DESIGN_SYSTEM.md
docs/ASSET_PIPELINE.md
```

Não duplicar informação desnecessariamente.

Cada documento deve ter uma responsabilidade clara.

---

# 29. TOOLING

Não implementar imediatamente todo o tooling previsto.

Primeiro descobrir as necessidades através do vertical slice.

Depois criar, conforme necessário:

```text
scripts/
├── generate_prompts.py
├── validate_sprites.py
├── normalize_sprites.py
├── validate_palette.py
├── validate_animation.py
├── validate_tiles.py
└── pack_atlas.py
```

Mas não criar scripts artificiais apenas para cumprir uma lista.

Cada script deve existir porque resolve um problema real observado no pipeline.

---

# 30. PUBSPEC

Verificar a configuração actual de:

```text
pubspec.yaml
```

e garantir que a futura estrutura de assets pode ser carregada pelo Flutter.

Não adicionar referências a assets que ainda não existem.

---

# 31. TESTES

Depois das alterações:

```bash
flutter analyze
flutter test
```

Executar também o jogo quando possível.

Verificar:

* mapas;
* colisões;
* rendering;
* scaling;
* sprites;
* anchors;
* animações;
* composição Head + Heels.

Não aceitar regressões de gameplay.

---

# 32. AES / TICKETS

Respeitar o sistema AES existente.

Não criar uma nova metodologia paralela.

Se o ticket actual indicar `T016`, continuar a numeração existente.

Criar novos tickets apenas quando houver trabalho concreto.

Uma possível sequência conceptual é:

```text
T017 — Visual Design System
T018 — Character Masters
T019 — Environment Masters
T020 — Entity Masters
T021 — Sprite Registry
T022 — Sprite Renderer
T023 — Vertical Slice
T024 — Production Pipeline
```

Mas adaptar os números ao estado REAL do `aes/`.

Não inventar tickets já existentes.

---

# 33. O QUE NÃO FAZER

Não:

* gerar os 256 tiles imediatamente;
* gerar todas as animações imediatamente;
* congelar uma paleta arbitrária;
* tratar Spectrum como limite de cores;
* substituir gameplay por artwork;
* alterar mapas sem necessidade;
* assumir sem verificar o significado dos tile IDs;
* criar sprites independentes para todas as combinações possíveis;
* criar Duo completo se a composição resolver;
* criar três versões físicas `@1x/@2x/@4x`;
* introduzir anti-aliasing;
* aceitar imagens AI sem normalização;
* introduzir arte fotorealista;
* criar scripts sem necessidade;
* reescrever o renderer inteiro.

---

# 34. DELIVERABLES DESTA TAREFA

No final desta tarefa, quero:

### 1. Auditoria

Um relatório curto:

```text
docs/SPRITE_SYSTEM_AUDIT.md
```

com:

* estado actual;
* problemas encontrados;
* decisões tomadas;
* decisões ainda em aberto.

### 2. Tile audit

```text
docs/TILE_ID_AUDIT.md
```

se necessário, contendo o mapeamento real TSX/TMX.

### 3. Visual Design System

Actualizar/criar:

```text
docs/VISUAL_DESIGN_SYSTEM.md
```

incluindo:

* 2026 visual philosophy;
* Spectrum DNA;
* expanded palette;
* pixel-art rules;
* lighting;
* isometric rules;
* character rules;
* environment rules;
* entity rules;
* UI rules.

### 4. Sprite Generation System

Actualizar:

```text
docs/SPRITE_GENERATION_SYSTEM.md
```

para reflectir tudo isto.

### 5. Style Board specification

Definir concretamente os assets que devem ser produzidos para o primeiro vertical slice.

### 6. Repository changes

Implementar apenas as alterações de código necessárias para preparar a arquitectura.

Não começar ainda a produzir centenas de sprites.

---

# 35. DECISÃO FINAL DESTA FASE

A tarefa NÃO termina com:

> "256 sprites generated."

A tarefa termina quando existir uma base sólida para responder:

> **"Temos agora uma linguagem visual coerente que permite gerar o resto do jogo?"**

Se sim, congelar o sistema visual e avançar para produção.

Se não, iterar primeiro sobre os masters.

---

# RESULTADO ESPERADO

Quero que trabalhes como:

**Lead Game Artist + Technical Artist + Flutter/Flame Engineer + Asset Pipeline Architect.**

A prioridade é:

```text
IDENTITY
   ↓
CONSISTENCY
   ↓
READABILITY
   ↓
SCALABILITY
   ↓
PRODUCTION
```

e não simplesmente quantidade de sprites.

O objectivo é transformar o actual projecto Head over Heels numa **reimaginação visual contemporânea**, mantendo a alma do original mas sem carregar artificialmente para 2026 as limitações técnicas de 1987.

