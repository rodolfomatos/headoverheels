# iso_editor

The map editor: a room grid, a tileset browser, a sprite browser, and a Tiled
(TSX) authoring view, for the projects in this repository.

## Running it

```bash
make serve-editor        # builds it and serves it on http://localhost:8082
make run-editor          # the debug build, for working on the editor itself
```

`make serve-editor` is the one for using it: `make run-<game>` serves a debug
build, where the program is compiled in the browser as it loads.

## What it does not do yet

It keeps nothing between visits. The map lives in the page
(`MemoryEditorStorage`), so closing the browser loses the work. The editor can
read and write Tiled files through its file gateway, and it needs a project on
disk to point at. That is the next thing it wants, and it is recorded in
`aes/kanban.md` rather than left to be discovered.

## Using it

The library is `package:iso_editor/iso_editor.dart`. `EditorShell` is the whole
editor as a widget, and `EditorProject.shipped` is the pair of games this
repository builds.
