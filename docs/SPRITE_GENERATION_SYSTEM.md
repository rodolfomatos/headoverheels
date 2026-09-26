# Sprite Generation System

## Head over Heels — Flutter Port

**Versão:** 2.0
**Estado:** Active — Reconciled with 2026 Visual Design System
**Projecto:** `rodolfomatos/headoverheels`
**Objectivo:** substituir a representação visual actual por uma nova linguagem visual coerente, inspirada no universo e na estética do jogo original, mas produzida como artwork original para a implementação Flutter.

> **Source of Truth:** `docs/REIMAGINING.md` and `docs/VISUAL_DESIGN_SYSTEM.md` define the 2026 visual philosophy. This document describes the production pipeline only.

---

# 1. Objectivo

Criar um sistema de produção de sprites capaz de gerar, normalizar, validar e integrar de forma sistemática toda a componente gráfica do jogo.

O objectivo **não é simplesmente gerar imagens com IA**.

O objectivo é construir um **pipeline de produção de assets** no qual a geração assistida por IA seja apenas uma das etapas:

```text
Referências
    ↓
Design visual
    ↓
Master assets
    ↓
Geração
    ↓
Normalização
    ↓
Validação
    ↓
Atlas
    ↓
Flutter / Flame
```

O sistema deve permitir:

* produzir personagens consistentes;
* produzir animações consistentes;
* produzir tiles coerentes entre si;
* produzir entidades e objectos;
* manter uma paleta e iluminação comuns;
* detectar automaticamente assets inválidos;
* regenerar assets sem destruir os restantes;
* associar cada sprite à entidade lógica correspondente;
* evitar dependência de artwork extraída do jogo original.

O repositório já estabelece como princípio que o port utiliza artwork criada especificamente para o projecto e não assets extraídos do original. Esta arquitectura deve preservar esse princípio.

---

# 2. Princípio fundamental

## Não gerar os 256 tiles individualmente como imagens independentes

A proposta inicial considera um tileset de 256 tiles.

Isso continua a ser o objectivo final, mas **não deve ser a unidade de criação artística**.

A produção deverá seguir:

```text
Visual Language
      ↓
Master Tiles
      ↓
Tile Families
      ↓
Variants
      ↓
Complete Tileset
```

Por exemplo:

```text
stone_floor_master
       ├── clean
       ├── cracked
       ├── worn
       ├── moss
       └── damaged

stone_wall_master
       ├── straight
       ├── corner
       ├── end
       ├── inner
       └── damaged
```

Isto reduz drasticamente a inconsistência visual.

---

> **IMPORTANT:** This document has been reconciled with the 2026 Visual Design System.
> The following outdated constraints have been REMOVED:
> - ❌ "Spectrum+ = 16–24 colours" (palette is now open-ended, governed by visual hierarchy)
> - ❌ "Limited palette" as a hard constraint
> - ❌ Binary alpha only (now supports opaque, binary, smooth per asset)
> - ❌ Premature fixed master dimensions (48×48, 48×56, 56×64) — these are LOGICAL RUNTIME dimensions only
> - ❌ "256 tiles = 256 artworks" (master → family → variant system)
> 
> See `docs/VISUAL_DESIGN_SYSTEM.md` for the authoritative visual specification.

# 3. Estado actual do projecto (Auditoria Real — 2026-09-20)

O projecto já dispõe de uma arquitectura adequada para suportar esta alteração.

Actualmente (estado **real** verificado):

* Flutter + Dart (3.11.4);
* Flame 1.17.0 + flame_tiled 1.0.0;
* Riverpod 2.5.1 + Freezed 2.4.4;
* 21 salas TMX em `assets/levels/rooms/` (5 temas/planetas + test rooms);
* 5 mundos/planetas: Castle, Egyptus, Penitentiary, Safari, Book World;
* 19 tipos de entidades de puzzle/gameplay implementados;
* `assets/levels/tilesets/castle.tsx` — **único TSX existente** (256 tiles, **IDs duplicados resolvidos**: 65→77, 74→78, 75→79, 76→80, duplicados exactos removidos);
* `assets/levels/tilesets/castle.png` — **EXISTS** (1024×512 generated);
* 5 tilesets em falta: egyptus, penitentiary, safari, bookworld, moonbase (TSX não existem, PNG masters gerados);
* 21 ficheiros TMX em `assets/levels/rooms/` (todos usam `castle.tsx`);
* `assets/sprites/` — **POPULATED** com character masters, entity masters, theme tilesets, props;
* `assets/sprites/` declarado no `pubspec.yaml` — **NEEDS UPDATE** para incluir subdirectórios;
* Pipeline AES funcional com tickets T001–T022 completados, T023 em progresso;
* `docs/SPRITE_GENERATION_SYSTEM.md` — **RECONCILED** com 2026 Visual Design System;
* `docs/ASSET_INVENTORY.md` existe;
* `docs/VISUAL_DESIGN_SYSTEM.md` é a fonte de verdade visual;
* `docs/TILE_ID_AUDIT.md` documenta IDs resolvidos;
* Pipeline de geração: `scripts/generate_*.py` para characters, entities, environment, themes;
* Pipeline de validação: `scripts/validation_pipeline.py` (5 checks: tiles, palette, dimensions, naming, alpha);
* **Implementação visual actual:** Character masters (Head/Heels/Duo) + Environment masters + Entity masters + Theme tilesets (6) + Props. Rendering usa placeholders em `CharacterComponent` até integração completa.

# 4. Arquitectura proposta

```text
sprite-system/
│
├── style/
│   ├── style-guide.md
│   ├── palette.json
│   ├── lighting.json
│   ├── geometry.json
│   ├── proportions.json
│   └── naming.md
│
├── references/
│   ├── maps/
│   ├── manual/
│   ├── gameplay/
│   └── extracted-analysis/
│
├── masters/
│   ├── characters/
│   │   ├── head/
│   │   ├── heels/
│   │   └── duo/
│   │
│   ├── tiles/
│   │   ├── castle/
│   │   ├── egyptus/
│   │   ├── penitentiary/
│   │   ├── safari/
│   │   └── bookworld/
│   │
│   ├── entities/
│   └── ui/
│
├── prompts/
│   ├── system/
│   ├── characters/
│   ├── tiles/
│   ├── entities/
│   └── ui/
│
├── generated/
│   ├── characters/
│   ├── tiles/
│   ├── entities/
│   └── ui/
│
├── normalized/
│
├── atlases/
│
└── scripts/
    ├── generate_prompts.py
    ├── normalize_sprites.py
    ├── validate_sprites.py
    ├── validate_palette.py
    ├── validate_animation.py
    ├── validate_tiles.py
    ├── build_spritesheets.py
    └── pack_atlas.py
```

A implementação concreta pode ser adaptada à estrutura existente do projecto; o princípio importante é separar:

**referência → geração → normalização → runtime.**

---

# 5. Design Language

Antes de gerar dezenas ou centenas de sprites deve ser criado um documento único:

```text
style/style-guide.md
```

Este documento será a **fonte de verdade visual**.

Deve definir:

## 5.1 Pixel art

* pixel art hard-edged;
* sem anti-aliasing tradicional;
* sem blur;
* sem gradients fotográficos;
* sem texturas fotorealistas;
* sem subpixel rendering;
* linhas deliberadas;
* sombras construídas com pixels;
* dithering apenas quando necessário.

### Princípio

Não:

```text
pixel art + smooth anti-aliasing
```

Mas:

```text
pixel art
    ↓
hard edges
    ↓
limited palette
    ↓
selective dithering
    ↓
controlled highlights
```

---

# 6. Paleta

> **RECONCILED:** The outdated "Spectrum+ 16–24 colours" constraint has been removed.
> The authoritative palette definition is in `style/palette.json` and `docs/VISUAL_DESIGN_SYSTEM.md`.

A referência cromática deve partir da Spectrum mas não ficar limitada às oito cores originais.

A paleta deve ser definida explicitamente em:

```text
style/palette.json
```

A estrutura da paleta (ver `VISUAL_DESIGN_SYSTEM.md` §2):

```
Spectrum DNA (8 identity anchors)
    ↓
Shadow Ramps (3 steps per base)
    ↓
Highlight Ramps (3 steps per base)
    ↓
Material Ramps (stone, metal, wood, fabric, organic, magic, tech)
    ↓
Environment Colours (per theme)
    ↓
Effect Colours (fire, water, magic, poison, electric, holy)
```

**Target:** ~120–180 colours total, organised as ramps, not a flat list.

Não estabelecer previamente um número arbitrário de cores.

A paleta deve ser determinada através dos primeiros masters visuais.

Os valores concretos estão em `style/palette.json` (base + themes + extended).

---

### 6.1 Alpha Policy

O sistema visual 2026 suporta três modos de alpha por asset:

| Mode | Description | Use Cases |
|------|-------------|-----------|
| `opaque` | Alpha = 0 or 255 only | Tiles, solid objects, characters (base) |
| `binary` | 0, 128, 255 (hard edges) | UI icons, hard-edged effects |
| `smooth` | Full 0–255 range | Shadows, particles, wings, water, magic effects |

Cada asset declara o seu modo no manifest (`assets/sprites/manifest.yaml`).

O validator **não rejeita** automaticamente semi-transparência — valida contra o modo declarado.

---

# 7. Iluminação

A iluminação deve ser globalmente consistente.

Regra:

```text
Light source
     ↘
 top-left
```

Todos os assets devem obedecer aproximadamente à mesma lógica.

Isto significa:

* highlights no topo/esquerda;
* sombras no fundo/direita;
* ambient occlusion subtil;
* contacto visual com o chão;
* sombras não devem alterar arbitrariamente de direcção entre sprites.

Definir:

```text
style/lighting.json
```

com regras comuns.

---

# 8. Escala

## Tiles

A unidade lógica continua:

```text
64 × 32 px
```

correspondente à projecção dimétrica 2:1 já utilizada pelo jogo.

## Personagens

Os sprites podem ser maiores que um tile, desde que:

* mantenham uma escala consistente;
* tenham um anchor point definido;
* respeitem a grelha espacial do jogo.

Proposta inicial:

```text
Head:      ~48×48
Heels:     ~56×56
Combined:  ~56×72
```

Os valores devem ser validados visualmente dentro de uma sala real antes de congelar a especificação.

---

# 9. Scaling

Não criar obrigatoriamente três versões físicas:

```text
@1x
@2x
@4x
```

A fonte deve ser um único master.

Exemplo:

```text
head_walk_n_master.png
```

O runtime deverá utilizar scaling com nearest-neighbor.

Só deverão existir versões múltiplas se um requisito específico do Flutter/runtime justificar a sua existência.

> **Note:** `geometry.json` defines `supported_scales: [1, 2, 4]` with `scaling_method: "nearest_neighbor"`. Masters are authored at 1× (base resolution). Runtime variants are generated by the atlas pipeline if needed.

---

# 10. Master Assets

A produção deve começar por um conjunto pequeno de assets.

## Fase 1 — Characters

> **IMPORTANT:** Master resolution is intentionally not fixed until the first approved visual master establishes the pixel density and character-to-tile ratio.
> 
> The values below (48×48, 48×56, 56×64) are **LOGICAL RUNTIME DIMENSIONS** from `geometry.json`, not master canvas sizes.
> Masters should be authored at whatever resolution achieves the desired visual fidelity, then normalized to runtime dimensions.

Criar:

1. Head frontal
2. Head lateral
3. Head traseiro
4. Heels frontal
5. Heels lateral
6. Heels traseiro
7. Head + Heels (composição)
8. Fire effect
9. Jump pose
10. Carry pose

Estes assets definem:

* proporção;
* outline;
* escala;
* paleta;
* olhos;
* sombras;
* highlights;
* anatomia;
* estilo de animação.

---

# 11. Fase 2 — Environment Masters

Criar aproximadamente 10–15 masters:

```text
floor
wall
wall_corner
wall_end
stairs
ladder
door
conveyor
spring
switch
teleport
water
lava
crate
decorative_prop
```

Cada um será posteriormente expandido para as variantes necessárias.

---

# 12. Fase 3 — Entities

Criar os masters para:

* fish;
* rabbits;
* crowns;
* doughnuts;
* bags;
* keys;
* hush puppies;
* monsters;
* guardians;
* switches;
* doors;
* springs;
* conveyors;
* teleports;
* outros tipos presentes no modelo lógico.

O projecto actualmente identifica 19 tipos de entidades de puzzle/gameplay.

A arte deverá ser organizada por **tipo lógico**, e não apenas por aparência.

---

# 13. Fase 4 — Themes

Depois da linguagem visual estar congelada:

```text
castle
egyptus
penitentiary
safari
bookworld
```

Cada tema deverá reutilizar a mesma gramática visual.

Exemplo:

```text
floor
 ├── castle_floor
 ├── egyptus_floor
 ├── penitentiary_floor
 ├── safari_floor
 └── bookworld_floor
```

A identidade temática muda através de:

* materiais;
* cores;
* decoração;
* props;
* padrões;

e não através de uma mudança completa do estilo de pixel art.

---

# 14. Characters

## Head

Características visuais:

* criatura verde;
* asas amarelas;
* silhueta arredondada;
* olhos expressivos;
* leitura imediata;
* corpo compacto.

Animações:

```text
idle
walk
jump
climb
fire
combined
```

Direcções:

```text
N
NE
E
SE
S
SW
W
NW
```

Nem todas as animações necessitam obrigatoriamente de 8 direcções se a animação não o justificar.

---

# 15. Heels

Características:

* corpo escuro;
* silhueta volumétrica;
* botas vermelhas;
* olhos muito visíveis;
* centro de massa baixo.

Animações:

```text
idle
walk
jump
climb
carry
combined
```

O comportamento visual deve enfatizar a diferença entre Head e Heels.

---

# 16. Head + Heels / Duo

A arquitectura correcta é **composição**, não duplicação:

```text
                   DUO
                    │
            ┌───────┴───────┐
            ↓               ↓
          HEELS            HEAD
            │               │
       animation        animation
            │               │
            └───────┬───────┘
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

> **Reconciled:** Previous version said "tratar como entidade visual própria" — corrected to composition-based approach per `VISUAL_DESIGN_SYSTEM.md` §10.

---

# 17. Tileset

O tileset final poderá continuar a possuir 256 tiles.

Contudo, a geração será organizada por famílias.

> **RECONCILED:** "256 tiles ≠ 256 artworks". The system is Master → Family → Variant → Tile Mapping.
> One master can generate multiple variants (clean, worn, cracked, moss, illuminated, edge, etc.).

Exemplo:

```text
00–15   Floors
16–31   Walls
32–47   Conveyors
48–55   Springs
56–63   Switches
64–71   Doors
72–79   Teleports
80–95   Props
96–111  Stairs / Ladders
112–127 Hazards
128–143 Hush Puppies
144–159 Fish
160–175 Rabbits
176–191 Items
192–207 Monsters
208–223 Guardians
224–239 Keys / Bags
240–255 Decals / overlays
```

**Nota:** esta classificação deverá ser confrontada com o TSX real antes de alterar os IDs existentes.

O objectivo é manter a compatibilidade com os mapas TMX.

---

# 18. Compatibilidade TMX

Este ponto é crítico.

Não alterar arbitrariamente:

```text
tile IDs
firstgid
tile coordinates
object references
collision metadata
```

A nova arte deverá inicialmente substituir apenas o conteúdo visual dos tiles.

Fluxo:

```text
TMX existente
       ↓
mesmos GIDs
       ↓
novo TSX
       ↓
nova imagem
       ↓
mesma lógica de jogo
```

Isto permite alterar completamente o aspecto sem reescrever as salas.

---

# 19. Sprite Metadata

Cada sprite deverá poder possuir metadata declarada no **Asset Manifest** (`assets/sprites/manifest.yaml`).

Não espalhar metadata em ficheiros individuais.

Exemplo de entrada no manifest:

```yaml
assets:
  - id: "character.head.idle.n"
    category: "character"
    character: "head"
    animation: "idle"
    direction: "n"
    frames: 4
    frame_duration: 200
    loop: true
    master: "head_idle_front_master"
    runtime_size: { width: 48, height: 48 }
    anchor: { x: 24, y: 43 }
    alpha: "opaque"
    palette: "base"
    scale: 1
    theme: "universal"
```

Isto permitirá automatizar a validação e o registry lookup.

> **Reconciled:** Previous version used per-file JSON sidecars. Now uses central manifest.

---

# 20. Naming Convention

> **Reconciled:** Physical filenames use snake_case. Semantic Asset IDs use dot-notation.
> The manifest maps between them. Gameplay code uses **Asset IDs only**.

**Physical filename format:**
```text
{category}_{asset}_{animation}_{direction}_{frame:02d}.png
```

**Asset ID format (used in code):**
```text
character.head.idle.n
entity.fish.swim.01
tile.castle.floor.01
ui.crown.castle
fx.explosion.03
```

Exemplos de ficheiros físicos:
```text
character_head_idle_s_01.png
character_head_walk_ne_03.png
character_heels_walk_e_05.png
character_duo_idle_s_01.png

entity_fish_idle_e_01.png
entity_rabbit_walk_s_02.png

tile_castle_floor_01.png
tile_castle_wall_corner_03.png

ui_crown.png
ui_doughnut.png
```

---

# 21. Prompt System

Criar:

```text
prompts/system/style-guide.md
```

com a definição global.

Depois:

```text
prompts/characters/head.md
prompts/characters/heels.md
prompts/characters/duo.md

prompts/tiles/castle.md
prompts/tiles/egyptus.md
prompts/tiles/penitentiary.md
prompts/tiles/safari.md
prompts/tiles/bookworld.md

prompts/entities/fish.md
prompts/entities/rabbit.md
...
```

Cada prompt deve herdar implicitamente:

```text
STYLE
+
CATEGORY
+
ASSET
+
ANIMATION
+
REFERENCE
+
CONSTRAINTS
```

---

# 22. Geração assistida por IA

A IA deve ser considerada uma ferramenta de **geração de candidatos**.

Não é a autoridade final.

Pipeline:

```text
Prompt
   ↓
Generation
   ↓
Candidate selection
   ↓
Human approval
   ↓
Normalization
   ↓
Validation
   ↓
Runtime
```

Nunca:

```text
Prompt
 ↓
PNG
 ↓
commit
```

---

# 23. Normalização

Criar:

```text
scripts/normalize_sprites.py
```

Responsabilidades:

* remover fundo;
* garantir alpha;
* corrigir dimensões;
* alinhar à grelha;
* normalizar escala;
* normalizar anchor;
* converter para paleta;
* remover cores inesperadas;
* corrigir pequenos artefactos;
* garantir nearest-neighbor;
* produzir PNG final.

---

# 24. Palette Validation

Criar:

```text
scripts/validate_palette.py
```

Exemplo de erro:

```text
ERROR:
character_head_walk_ne_03.png

Found:
#A37B42

Allowed palette:
16 colours

Action:
REJECT
```

O pipeline não deverá aceitar automaticamente sprites que introduzam centenas de cores devido à geração de imagem.

---

# 25. Dimension Validation

Criar:

```text
scripts/validate_sprites.py
```

Validar:

```text
✓ width
✓ height
✓ alpha
✓ file format
✓ naming
✓ anchor
✓ palette
```

---

# 26. Animation Validation

Criar:

```text
scripts/validate_animation.py
```

Detectar:

* bounding box inconsistente;
* personagem a saltar de posição;
* escala diferente entre frames;
* baseline inconsistente;
* anchor inconsistente;
* alterações abruptas de silhueta;
* frame duplicado;
* frame vazio.

Exemplo:

```text
Frame 01 baseline = 43
Frame 02 baseline = 43
Frame 03 baseline = 44
Frame 04 baseline = 67  ← ERROR
```

---

# 27. Tile Validation

Criar:

```text
scripts/validate_tiles.py
```

Validar:

```text
64×32
correct diamond geometry
palette
alpha
tile ID
tileset index
theme
```

Especialmente importante:

```text
floor
wall
corner
stairs
```

devem encaixar geometricamente sem seams.

---

# 28. Atlas

Criar:

```text
scripts/pack_atlas.py
```

Responsabilidades:

* recolher sprites validados;
* criar atlas;
* gerar metadata;
* preservar naming;
* produzir assets para Flame.

Limite inicial:

```text
2048×2048
```

Mas o atlas deverá poder ser dividido por categoria:

```text
characters.atlas
entities.atlas
castle.atlas
egyptus.atlas
...
```

Não obrigar todo o jogo a carregar um atlas gigante.

---

# 29. Estrutura final dos assets

A estrutura de runtime deverá aproximar-se de:

```text
assets/
├── sprites/
│   ├── characters/
│   │   ├── head.png
│   │   ├── heels.png
│   │   └── duo.png
│   │
│   ├── entities/
│   │   ├── fish.png
│   │   ├── rabbit.png
│   │   └── ...
│   │
│   ├── tiles/
│   │   ├── castle.png
│   │   ├── egyptus.png
│   │   ├── penitentiary.png
│   │   ├── safari.png
│   │   └── bookworld.png
│   │
│   └── ui/
│
└── levels/
    └── tilesets/
        ├── castle.tsx
        ├── egyptus.tsx
        ├── penitentiary.tsx
        ├── safari.tsx
        └── bookworld.tsx
```

---

# 30. Flutter / Flame

A alteração visual não deve alterar a lógica de gameplay.

A camada:

```text
CharacterState
CharacterComponent
EntityComponent
RoomComponent
InteractionSystem
```

deve continuar a trabalhar com IDs/estados lógicos.

A arte passa a ser uma implementação visual desses estados.

Por exemplo:

```dart
CharacterState.walking
```

não deve saber que existe:

```text
character_head_walk_ne_03.png
```

Essa tradução deverá ser responsabilidade do renderer/animation controller.

---

# 31. Sprite Registry

Criar um registry central.

Exemplo conceptual:

```dart
class SpriteRegistry {
  final Map<String, SpriteAnimation> animations;

  SpriteAnimation getCharacterAnimation(
    String character,
    String animation,
    String direction,
  );
}
```

Assim:

```text
game state
    ↓
animation state
    ↓
sprite registry
    ↓
sprite atlas
```

---

# 32. Não duplicar lógica por sprite

Evitar:

```dart
if (head) ...
if (heels) ...
if (castle) ...
```

espalhado pelo código.

Preferir:

```text
Asset ID
↓
Asset Manifest
↓
Sprite Registry
↓
Renderer
```

---

# 33. Asset Manifest

Criar:

```text
assets/sprites/manifest.yaml
```

Exemplo:

```yaml
version: "1.0"
assets:
  - id: "character.head.idle.n"
    file: "characters/head/frames/head_idle_n_01.png"
    category: "character"
    character: "head"
    animation: "idle"
    direction: "n"
    frames: 4
    frame_duration: 200
    loop: true
    master: "head_idle_front_master"
    runtime_size: { width: 48, height: 48 }
    anchor: { x: 24, y: 43 }
    alpha: "opaque"
    palette: "base"
    scale: 1
    theme: "universal"
  - id: "character.heels.walk.ne"
    file: "characters/heels/frames/heels_walk_ne_01.png"
    category: "character"
    character: "heels"
    animation: "walk"
    direction: "ne"
    frames: 8
    frame_duration: 100
    loop: true
    master: "heels_walk_front_master"
    runtime_size: { width: 48, height: 56 }
    anchor: { x: 24, y: 51 }
    alpha: "opaque"
    palette: "base"
    scale: 1
    theme: "universal"
  - id: "tile.castle.floor.clean"
    file: "tiles/castle/floor_clean_01.png"
    category: "tile"
    theme: "castle"
    family: "floor"
    variant: "clean"
    tile_id: 0
    runtime_size: { width: 64, height: 32 }
    alpha: "opaque"
    palette: "castle"
    scale: 1
```

O manifest torna o pipeline desacoplado do código.
O código de gameplay usa **Asset IDs**; o registry resolve para ficheiros físicos.

---

# 34. Primeiro Prototype

Antes de gerar todo o jogo:

## Sprint A

Produzir apenas:

```text
Head
Heels
Duo
Castle floor
Castle wall
Castle stairs
Castle door
Fish
Rabbit
Crown
Switch
```

Depois integrar numa única sala real.

Critério:

> Se estes assets não parecerem pertencer ao mesmo jogo, parar e corrigir o style guide.

Não avançar para centenas de sprites antes deste gate.

---

# 35. Visual QA

Criar uma sala de demonstração:

```text
sprite_gallery.tmx
```

ou uma cena Flutter dedicada.

Mostrar:

```text
Head
Heels
Duo
all directions
all animations
all entities
all master tiles
```

com:

* fundo neutro;
* grelha;
* labels;
* escala 1×;
* escala 2×;
* escala 4×.

Isto permitirá detectar inconsistências rapidamente.

---

# 36. Teste em gameplay real

Depois da galeria:

```text
sprite gallery
       ↓
castle_start
       ↓
castle rooms
       ↓
all worlds
```

Não validar apenas os sprites isoladamente.

Um sprite que parece excelente numa imagem pode parecer errado quando colocado:

* sobre um tile;
* ao lado de uma parede;
* junto de outro personagem;
* em movimento;
* durante um salto.

---

# 37. AES Integration

Como o projecto já utiliza AES, esta iniciativa deverá ser tratada como uma sequência de tickets.

Proposta:

```text
T016 — Sprite System Architecture
T017 — Visual Design System
T018 — Character Masters
T019 — Character Animation Pipeline
T020 — Environment Masters
T021 — Castle Tileset
T022 — Entity Masters
T023 — Remaining Themes
T024 — Sprite Validation Pipeline
T025 — Atlas Pipeline
T026 — Flutter Sprite Registry
T027 — Gameplay Integration
T028 — Visual QA
T029 — Final Asset Migration
```

Cada ticket deverá seguir:

```text
kanban
  ↓
ticket
  ↓
plan
  ↓
hostile analysis
  ↓
implementation
  ↓
verification
  ↓
learn
```

que é o processo já definido pelo projecto.

---

# 38. T016 — Sprite System Architecture

Criar:

```text
docs/SPRITE_GENERATION_SYSTEM.md
style/
prompts/
references/
masters/
generated/
normalized/
scripts/
```

Implementar naming convention e manifest.

### Acceptance criteria

* estrutura criada;
* documentação disponível;
* naming definido;
* manifest definido;
* nenhum código de gameplay alterado.

---

# 39. T017 — Visual Design System

Criar:

```text
style/style-guide.md
style/palette.json
style/lighting.json
style/geometry.json
```

Produzir primeiro concept sheet.

### Gate

Human visual approval.

Só avançar quando:

* Head;
* Heels;
* Duo;
* floor;
* wall

parecerem pertencer ao mesmo universo visual.

---

# 40. T018 — Character Masters

Produzir:

```text
Head
Heels
Duo
```

com:

* idle;
* walk;
* jump;
* climb;
* fire/carry;
* combined.

Primeiro apenas um subconjunto de direcções.

Depois expandir para oito direcções.

---

# 41. T019 — Character Animation Pipeline

Implementar:

```text
normalize_sprites.py
validate_animation.py
build_spritesheets.py
```

Garantir:

* baseline;
* anchor;
* escala;
* dimensões;
* loop;
* frame timing.

---

# 42. T020 — Environment Masters

Criar os masters:

```text
floor
wall
corner
stairs
ladder
door
switch
conveyor
spring
teleport
hazard
props
```

---

# 43. T021 — Castle

O Castle deverá ser o primeiro tema completo.

Motivo:

* permite testar todos os principais tipos de tiles;
* permite testar paredes;
* pisos;
* portas;
* mecanismos;
* entidades;
* navegação.

Gerar:

```text
castle.tsx
castle.png
```

mantendo os GIDs compatíveis com os mapas existentes.

---

# 44. T022 — Entities

Produzir os assets para os 19 tipos lógicos existentes.

Cada entidade deverá ter:

```text
idle
active
interaction
death
special
```

apenas quando essas animações fizerem sentido para a entidade.

Não criar animações artificialmente.

---

# 45. T023 — Remaining Themes

Depois do Castle:

```text
Egyptus
Penitentiary
Safari
Book World
```

Cada tema deverá reutilizar:

```text
style
lighting
geometry
palette rules
character scale
```

e alterar apenas a linguagem material/decorativa.

---

# 46. T024 — Validation Pipeline

> **Reconciled:** Validation is now metadata-driven via `manifest.yaml`. The validator reads the manifest and validates each asset against its declared spec (dimensions, alpha mode, palette, naming).

Implementar todos os validators.

Comando único:

```bash
python scripts/validation_pipeline.py
```

Validation checks:
1. **tiles** - tile geometry (64×32, diamond mask)
2. **palette** - colours allowed per asset's declared palette (base + theme)
3. **dimensions** - matches declared runtime_size in manifest
4. **naming** - physical filename matches convention; Asset ID format validated
5. **alpha** - validates against declared alpha mode (opaque/binary/smooth)

Resultado esperado:

```text
==================================================
VALIDATION PIPELINE SUMMARY
==================================================
  tiles          : ✅ PASS
  palette        : ✅ PASS
  dimensions     : ✅ PASS
  naming         : ✅ PASS
  alpha          : ✅ PASS
--------------------------------------------------
Total: 168 passed, 0 failed
```

---

# 47. T025 — Atlas Pipeline

Comando:

```bash
python scripts/pack_atlas.py
```

Deverá produzir:

```text
build/assets/
├── characters.atlas
├── entities.atlas
├── castle.atlas
├── egyptus.atlas
├── penitentiary.atlas
├── safari.atlas
└── bookworld.atlas
```

---

# 48. T026 — Flutter Sprite Registry

Criar:

```text
lib/core/assets/
    sprite_registry.dart
    sprite_manifest.dart
```

O código de gameplay não deverá conhecer filenames.

---

# 49. T027 — Gameplay Integration

Substituir progressivamente os assets existentes.

Ordem:

```text
characters
    ↓
castle
    ↓
entities
    ↓
remaining themes
    ↓
UI
```

Não fazer uma substituição global de uma só vez.

---

# 50. T028 — Visual QA

Criar uma cena dedicada:

```text
Sprite Gallery
```

com:

```text
Characters
Animations
Directions
Entities
Tiles
Themes
UI
```

Validar também:

```text
1×
2×
4×
```

---

# 51. T029 — Final Asset Migration

Quando todos os assets estiverem aprovados:

1. substituir assets antigos;
2. actualizar TSX;
3. actualizar manifest;
4. remover assets obsoletos;
5. actualizar documentação;
6. executar testes;
7. executar build;
8. executar análise;
9. testar em dispositivo.

---

# 52. Quality Gates

Nenhum asset entra no branch principal se falhar:

```text
[ ] correct dimensions (matches manifest runtime_size)
[ ] correct alpha (matches declared mode: opaque/binary/smooth)
[ ] correct palette (matches declared palette: base + theme)
[ ] correct naming (physical filename + Asset ID format)
[ ] correct anchor (±1px from manifest)
[ ] correct scale (±1px from manifest)
[ ] animation consistency (baseline, anchor, scale, loop)
[ ] tile geometry (64×32, diamond mask)
[ ] no unintended artifacts
[ ] human visual approval ✅
```

---

# 53. Código

Depois de alterações de código:

```bash
dart format .
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

O projecto já define `make check` como o quality gate principal.

Portanto:

```bash
make check
```

deve continuar a ser obrigatório.

---

# 54. Asset Quality Gate

Adicionar ao `Makefile`:

```make
sprites-check:
	python scripts/validation_pipeline.py

sprites-build:
	python scripts/build_spritesheets.py

sprites-pack:
	python scripts/pack_atlas.py

assets-check: sprites-check
```

Idealmente:

```bash
make check
make assets-check
```

---

# 55. CI

O CI deverá futuramente validar:

```text
Dart
    ↓
Flutter analyze
    ↓
Flutter tests
    ↓
Sprite validation
    ↓
Asset manifest validation
```

Assim, um sprite inválido não entra no projecto apenas porque o código compila.

---

# 56. Human-in-the-loop

A aprovação visual deve ser explícita.

Cada master poderá ter:

```text
master.png
master-approved.md
```

ou metadata equivalente.

Exemplo:

```yaml
asset: head_master
status: approved
version: 1
approved_by: human
```

A IA pode gerar.

A pipeline pode validar.

**A decisão final sobre a identidade visual continua a ser humana.**

---

# 57. Regras para geração por IA

Cada prompt deverá conter:

## Context

```text
Modern reimagining of a classic ZX Spectrum
isometric puzzle-platformer.
```

## Style

```text
hard-edged pixel art
limited palette
clean silhouettes
2:1 dimetric geometry
top-left lighting
```

## Constraints

```text
transparent background
no text
no UI
no photorealism
no gradients
no anti-aliasing
no background scenery
```

## Asset-specific information

```text
character
animation
direction
frame
dimensions
reference
```

---

# 58. Não copiar directamente

As referências do jogo original servem para compreender:

* função;
* composição;
* silhueta conceptual;
* comportamento;
* proporções;
* identidade do universo.

A nova arte deverá ser uma interpretação visual original.

O repositório já estabelece explicitamente esta separação relativamente aos assets do jogo original.

---

# 59. Critério de sucesso

O resultado final deverá parecer:

> **Head over Heels reconhecível sem parecer uma simples cópia dos sprites do ZX Spectrum.**

Deverá conservar:

* personalidade;
* humor;
* estranheza;
* arquitectura isométrica;
* leitura imediata;
* simplicidade;
* lógica visual.

Mas ganhar:

* maior resolução;
* maior expressividade;
* animações mais fluidas;
* melhor leitura em ecrãs modernos;
* identidade visual consistente.

---

# 60. Ordem recomendada de execução

A ordem exacta deve ser:

```text
01. Repository audit
        ↓
02. Sprite architecture
        ↓
03. Style guide
        ↓
04. Palette
        ↓
05. Lighting
        ↓
06. Head master
        ↓
07. Heels master
        ↓
08. Duo master
        ↓
09. Character animation
        ↓
10. Environment masters
        ↓
11. Castle tileset
        ↓
12. Entity masters
        ↓
13. Castle complete
        ↓
14. Validation pipeline
        ↓
15. Atlas pipeline
        ↓
16. Flutter registry
        ↓
17. Gameplay integration
        ↓
18. Egyptus
        ↓
19. Penitentiary
        ↓
20. Safari
        ↓
21. Book World
        ↓
22. UI
        ↓
23. Visual QA
        ↓
24. Final migration
```

---

# 61. Primeira milestone

A primeira milestone **não deve ser "todos os sprites gerados"**.

Deve ser:

## Visual Vertical Slice

Uma sala completa jogável contendo:

```text
✓ Head
✓ Heels
✓ Duo
✓ floor
✓ wall
✓ stairs
✓ door
✓ switch
✓ conveyor
✓ spring
✓ teleport
✓ fish
✓ rabbit
✓ crown
✓ item
✓ shadows
✓ animation
✓ atlas
✓ Flutter integration
```

Se esta sala funcionar visualmente, a tecnologia e a linguagem visual estão validadas.

A partir daí, a produção do resto do jogo torna-se essencialmente uma expansão controlada do sistema.

---

# 62. Resultado esperado

No final, o projecto deverá possuir dois sistemas claramente separados:

```text
GAMEPLAY SYSTEM
---------------
World
Rooms
Physics
Entities
State
Interactions
Input
Audio


ASSET SYSTEM
------------
Style
Palette
Masters
Prompts
Generation
Normalization
Validation
Atlases
Manifest
```

Ligados apenas por:

```text
Asset IDs
```

Esta separação permitirá mudar novamente o estilo visual no futuro sem reescrever a lógica do jogo.

---

# 63. Visão final

O objectivo não é simplesmente:

> "fazer sprites novos para o Head over Heels".

O objectivo é criar:

> **um sistema de produção de arte proceduralmente assistido, validável e reproduzível para uma reimaginação moderna do Head over Heels.**

A IA torna-se o mecanismo de exploração visual.

Os *master assets* tornam-se a fonte de consistência.

A normalização torna a geração utilizável.

A validação impede regressões.

Os atlas tornam-na eficiente para o runtime.

E o Flutter/Flame apenas consome o resultado final.

```text
              ┌─────────────────┐
              │   REFERENCES    │
              └────────┬────────┘
                       ↓
              ┌─────────────────┐
              │  STYLE SYSTEM   │
              └────────┬────────┘
                       ↓
              ┌─────────────────┐
              │ MASTER ASSETS   │
              └────────┬────────┘
                       ↓
              ┌─────────────────┐
              │ AI GENERATION   │
              └────────┬────────┘
                       ↓
              ┌─────────────────┐
              │  NORMALIZATION  │
              └────────┬────────┘
                       ↓
              ┌─────────────────┐
              │   VALIDATION    │
              └────────┬────────┘
                       ↓
              ┌─────────────────┐
              │     ATLAS       │
              └────────┬────────┘
                       ↓
              ┌─────────────────┐
              │  FLUTTER/FLAME  │
              └─────────────────┘
```

**Regra principal:**

> **Generate freely. Normalize aggressively. Validate automatically. Approve visually. Integrate deterministically.**

---

# 64. Estado Actual vs Estado Alvo vs Plano de Implementação

> Conforme §43 do MASTER_PROMPT, este documento distingue explicitamente:

---

## 64.1 CURRENT STATE (Estado Actual — Auditoria 2024-09-20)

| Componente | Estado | Evidência |
|------------|--------|-----------|
| **Sprites** | **0 assets** | `assets/sprites/` vazio; apenas placeholders (rectângulos) |
| **Tilesets** | 1/6 | Apenas `castle.tsx` existe; 5 em falta |
| `castle.tsx` | Existe mas **inválido** | 4 IDs duplicados (65, 74, 75, 76); `castle.png` em falta |
| `castle.png` | **Em falta** | Referenciado no TSX mas ficheiro não existe |
| TMX rooms | 21/21 | Todos usam `castle.tsx`; apenas GIDs 0 e 2 usados nas layers |
| Entidades | 19 tipos | Factory completa; rendering = placeholders (rectângulos) |
| Personagens | 3 tipos | State machine completa; rendering = placeholder |
| `assets/sprites/` | **VAZIO** | Declarado no `pubspec.yaml` mas vazio |
| `castle.png` | **AUSENTE** | Referenciado no `castle.tsx` linha 4 |
| 5 tilesets | **EM FALTA** | egyptus, penitentiary, safari, bookworld, moonbase |

**Pipeline visual:** Placeholder-only → Zero sprites reais → Zero atlases → Zero registry

---

## 64.2 TARGET STATE (Estado Alvo — Pós T029)

| Componente | Especificação |
|------------|---------------|
| **Sprites** | ~1.800 assets validados (chars: 72, entities: ~150, tiles: 1.536, UI: ~20, FX: ~40) |
| **Tilesets** | 6 completos (castle, egyptus, penitentiary, safari, bookworld, moonbase) × 256 tiles |
| `castle.tsx` | Corrigido (IDs únicos), `castle.png` (1024×512) gerado |
| 5 novos tilesets | egyptus, penitentiary, safari, bookworld, moonbase (.tsx + .png) |
| `assets/sprites/` | Populado com estrutura final (ver §29) |
| `assets/atlases/` | 7 atlases: characters, entities, castle, egyptus, penitentiary, safari, bookworld |
| `assets/sprites/manifest.json` | Manifest completo com asset IDs |
| `lib/core/assets/sprite_registry.dart` | Registry central funcional |
| `lib/core/assets/sprite_manifest.dart` | Manifest tipado |
| `CharacterComponent` | Rendering real via `SpriteRegistry` + `SpriteAnimationComponent` |
| `PuzzleEntity` subclasses | Rendering real via sprites (não placeholders) |
| `SpriteRegistry` | Resolução centralizada: `assetId` → `SpriteAnimation` |
| `VisualStateResolver` | `GameState` → `AssetID` → `SpriteAnimation` |

**Quality Gates (obrigatórios):**
- [ ] 0 invalid asset references
- [ ] 0 missing required sprites
- [ ] 0 invalid palette violations
- [ ] 0 invalid atlas references
- [ ] 0 invalid animation references
- [ ] 0 broken TSX/TMX references
- [ ] 0 palette violations (palette validation)
- [ ] 0 animation consistency errors
- [ ] 0 tile geometry errors
- [ ] Human visual approval (Gate 1–5)

---

## 64.3 IMPLEMENTATION PLAN (Plano de Implementação — Fases T016–T029)

### Fase 1: Fundação (T016–T017) — Semana 1–2
| Ticket | Entregável | Critério |
|--------|------------|----------|
| **T016** | `docs/ASSET_INVENTORY.md` ✅, `docs/SPRITE_GENERATION_SYSTEM.md` ✅ | Estrutura criada, docs disponíveis |
| | Fix `castle.tsx` (IDs únicos) | IDs únicos, validação passa |
| | Placeholder `castle.png` (1024×512) | Ficheiro existe, carrega no Flame |
| | `style/style-guide.md` | Documento aprovado visualmente |
| | `style/palette.json` | Paleta Spectrum+ definida |
| | `style/lighting.json` | Regras de iluminação definidas |
| | `style/geometry.json` | Geometria 64×32, anchors definidos |
| | `style/proportions.json` | Proporções chars/entities definidas |
| | `style/naming.md` | Convenção documentada |
| **T017** | Concept sheet (Head, Heels, Duo, floor, wall) | Aprovação visual humana (Gate 1) |

### Fase 2: Character Visual System (T018–T019) — Semana 2–3
| Ticket | Entregável | Critério |
|--------|------------|----------|
| **T018** | Master assets: Head, Heels, Duo (idle, walk, jump, climb, fire/carry, combined) | Master assets aprovados (Gate 2) |
| | Primeiro subconjunto de direcções (N, E, S, W) | 4 direcções funcionais |
| **T019** | `scripts/normalize_sprites.py` | Normalização determinística |
| | `scripts/validate_animation.py` | Baseline, anchor, scale, loop validados |
| | `scripts/build_spritesheets.py` | Spritesheets gerados + metadata JSON |

### Fase 3: Vertical Slice (T020) — Semana 3–4
| Ticket | Entregável | Critério |
|--------|------------|----------|
| **T020** | Environment masters: floor, wall, corner, stairs, door, switch, conveyor, spring, teleport, hazard, props | Masters aprovados |
| **T021** | Castle tileset completo (256 tiles, castle.tsx + castle.png) | GIDs compatíveis, atlas gerado |
| **T019** (cont.) | Character animation pipeline completo (8 dirs × 6 anims × 3 chars) | Animações fluidas, baseline/anchor consistentes |
| **T022** | Entity masters (19 tipos) | Masters aprovados |
| **T019** (cont.) | Castle completo (21 salas + entities) | Sala jogável completa |

### Fase 4: Vertical Slice (T019 cont.) — Semana 4–5
| Marco | Critério de Sucesso |
|-------|---------------------|
| **Visual Vertical Slice** | Uma sala (`castle_start`) jogável com: Head, Heels, Duo, floor, wall, stairs, door, switch, conveyor, spring, teleport, fish, rabbit, crown, item, shadows, animation, atlas, Flutter integration |

**Gate 3 — Visual Vertical Slice:** Sala completa jogável e visualmente coesa.

### Fase 5: Produção Completa (T022–T025) — Semana 5–8
| Ticket | Entregável |
|--------|-------------|
| **T022** | Entity Visual System (19 tipos) |
| **T023** | Validation pipeline (`make assets-check`) |
| **T024** | Atlas pipeline (TexturePacker, 7 atlases) |
| **T025** | Remaining themes (Egyptus, Penitentiary, Safari, Book World) |

### Fase 6: Integração & QA (T026–T029) — Semana 8–10
| Ticket | Entregável |
|--------|-------------|
| **T026** | Flutter Sprite Registry + Manifest |
| **T027** | Gameplay integration (chars → castle → entities → themes → UI) |
| **T028** | Visual QA (Sprite Gallery, 1×/2×/4×) |
| **T029** | Final Asset Migration + Build + Device test |

### Quality Gates por Fase

| Gate | Fase | Critério |
|------|------|----------|
| **Gate 1** | T017 | Style guide aprovado visualmente |
| **Gate 2** | T018 | Character masters aprovados |
| **Gate 3** | T019 | Vertical slice (castle_start) jogável e coeso |
| **Gate 4** | T021 | Castle completo visualmente consistente |
| **Gate 4** | T024 | `make assets-check` = 0 errors |
| **Gate 5** | T028 | Visual QA aprovado (1×, 2×, 4×) |

---

## 64.4 Rastreabilidade (Ticket → Spec §)

| Ticket | Spec §§ |
|--------|---------|
| T016 | §38, §60 (ordem) |
| T017 | §39, §18, §20, §21, §22 |
| T018 | §40, §14, §15, §16 |
| T019 | §41, §23, §26 |
| T020 | §42, §11, §12 |
| T021 | §43, §17, §27, §28 |
| T022 | §44, §12 |
| T023 | §45, §13 |
| T024 | §46, §24–§32 |
| T025 | §47, §28, §33 |
| T026 | §48, §16, §31, §32, §33 |
| T027 | §49, §30 |
| T028 | §50, §35, §36 |
| T029 | §51 |

---

**Princípio final:**  
> **Generate freely. Normalize aggressively. Validate automatically. Approve visually. Integrate deterministically.**

> O documento `docs/SPRITE_GENERATION_SYSTEM.md` deve ser **actualizado a cada milestone** para reflectir o estado real (Current/Target/Plan). Não copiar assumções — documentar o real.

