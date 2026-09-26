# Builder Architecture

## Objectives

- `iso_core`: reusable runtime for 2:1 dimetric games.
- `iso_editor`: desktop/web map editor, sprite browser/animator and asset importer.
- `iso_builder_cli`: project scaffolding, validation and build orchestration.
- `games/headoverheels`: first game package; keeps Head, Heels and original puzzle logic out of the generic core.

## Runtime

```text
Game state
    ↓
VisualState
    ↓
asset.id
    ↓
SpriteRegistry
    ↓
SpriteAnimation
```

`iso_core` owns coordinates, physics, entity contracts, input, level loading, manifest lookup and sprite resolution. It does not own Head/Heels, crowns, doughnuts, hush puppies or any other Head over Heels rule.

## Editor

```text
EditorController
    ├── EditorDocument
    ├── EditorStorage
    ├── AssetImportService
    └── tools
          ├── select
          ├── tile
          ├── object
          ├── spawn
          └── erase
```

### Map editor

- Loads TMX through `RoomComponent` and world metadata through `WorldGraph`.
- Uses the same 64×32 dimetric coordinates as the runtime.
- Writes edits to a serializable `EditorDocument`; export to TMX/TSX happens through a dedicated exporter.
- Object layers store semantic `type` values instead of assuming that an object is a tile.
- `TmxCodec` supports CSV tile layers and round-trips object properties.
- Object coordinates have two explicit modes: `tiledIsometric` (standard Tiled projection) and `grid` (used by the current Head over Heels generated rooms, where object x/y are grid values multiplied by tile size). The mode is stored in document metadata; the editor never guesses.
- When a TSX tileset is loaded, tiles are painted on the canvas as cropped sprites and the palette browser lists every tile with its `type`, `class` and properties.
- `EditorFileGateway` isolates the platform file system: `FileSelectorEditorGateway` uses `file_selector` (desktop + web) and `MemoryEditorFileGateway` is used by tests. The editor degrades to clipboard and dialogs when no gateway is configured.

### Sprite browser and animator

- Reads `AssetManifest`, never derives semantics from filenames.
- Groups assets by `id`, `category`, `subject`, `animation` and `direction`.
- Shows real frame count versus declared frame count; incomplete animations are labelled rather than hidden.
- Accepts `metadata.frame_files` for multi-frame assets and uploads new frame lists through the manifest editor.
- `SpriteManager` filters by category or free text, then edits the semantic fields that the runtime reads: `runtime_size`, `anchor`, `alpha`, `palette`, `frames`, `frame_duration` and `loop`. The id, subject, animation and direction are treated as identity and are not editable after import.
- `SpriteAnimator` plays `metadata.frame_files` (falling back to `file`), honours the entry `loop` flag, and exposes step, duration and scrub controls.
- `AssetManifestService` is the only writer of `manifest.yaml`; `AssetImportService` writes binaries and upserts entries.
- Appending frames keeps the existing master `file` and replaces frames with the same name, so re-uploading a corrected frame is idempotent. Frames whose dimensions differ from the entry are rejected instead of silently rescaling.

### Asset import

1. Accept PNG bytes through a platform-neutral storage interface.
2. Inspect dimensions and alpha.
3. Let the user assign id, category, subject, animation, direction, anchor, palette and alpha mode.
4. Write the binary and upsert the manifest atomically.
5. Validate before marking the asset available to the runtime.

## Storage

The common editor uses abstractions so the same code compiles on web and desktop:

- `EditorStorage`: project JSON and binary assets.
- Web implementation: browser storage or IndexedDB.
- Desktop implementation: file-system directory.
- Tests: in-memory implementation.

No common editor module may import `dart:io` directly.

## CLI

```text
iso_builder create <name>
iso_builder analyze <project>
iso_builder validate-assets <project>
iso_builder export <project>
iso_builder build <project>
```

The CLI owns filesystem access; the runtime and shared editor models do not.

## Migration sequence

1. Stabilise and test `iso_core`.
2. Add `iso_editor` document model, undo/redo and storage adapters.
3. Add TMX map editing and TSX/tileset inspection.
4. Add sprite gallery, frame management and PNG import.
5. Add entity/property inspectors.
6. Add exporters and CLI commands.
7. Move Head over Heels code into `games/headoverheels` without changing gameplay behaviour.
8. Run the full game through the builder and verify parity with the existing build.
