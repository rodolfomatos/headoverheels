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

### Sprite browser and animator

- Reads `AssetManifest`, never derives semantics from filenames.
- Groups assets by `id`, `category`, `subject`, `animation` and `direction`.
- Shows real frame count versus declared frame count; incomplete animations are labelled rather than hidden.
- Accepts `metadata.frame_files` for multi-frame assets and uploads new frame lists through the manifest editor.

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
