import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

import '../document/editor_document.dart';
import '../storage/editor_storage.dart';

enum EditorTool { select, tile, object, spawn, erase }

class EditorController extends ChangeNotifier {
  EditorController({required this.storage, EditorDocument? document})
    : _document = document ?? EditorDocument.empty();

  final EditorStorage storage;
  EditorDocument _document;
  EditorTool _tool = EditorTool.select;
  Object? _selection;
  bool _dirty = false;
  final List<String> _undo = [];
  final List<String> _redo = [];

  EditorDocument get document => _document;
  EditorTool get tool => _tool;
  Object? get selection => _selection;
  bool get dirty => _dirty;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void setTool(EditorTool value) {
    if (_tool == value) return;
    _tool = value;
    notifyListeners();
  }

  void select(Object? value) {
    _selection = value;
    notifyListeners();
  }

  void replaceDocument(EditorDocument value) {
    _pushUndo();
    _document = value;
    _markDirty();
  }

  void setTile(int layerIndex, CellAddress address, int? tileId) {
    if (layerIndex < 0 || layerIndex >= _document.layers.length) return;
    final layer = _document.layers[layerIndex];
    if (layer.locked) return;
    _pushUndo();
    final layers = [..._document.layers];
    layers[layerIndex] = layer.setCell(address, tileId);
    _document = _document.copyWith(layers: layers);
    _markDirty();
  }

  void placeObject(ObjectPlacement object) {
    _pushUndo();
    _document = _document.copyWith(objects: [..._document.objects, object]);
    _selection = object.id;
    _markDirty();
  }

  void moveObject(String id, Vector3 position) {
    var changed = false;
    final objects = _document.objects.map((object) {
      if (object.id != id) return object;
      changed = true;
      return object.copyWith(position: position);
    }).toList();
    if (!changed) return;
    _pushUndo();
    _document = _document.copyWith(objects: objects);
    _markDirty();
  }

  void removeObject(String id) {
    final objects = _document.objects
        .where((object) => object.id != id)
        .toList();
    if (objects.length == _document.objects.length) return;
    _pushUndo();
    _document = _document.copyWith(objects: objects);
    _selection = null;
    _markDirty();
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(jsonEncode(_document.toJson()));
    _document = EditorDocument.fromJson(
      jsonDecode(_undo.removeLast()) as Map<String, dynamic>,
    );
    _markDirty();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(jsonEncode(_document.toJson()));
    _document = EditorDocument.fromJson(
      jsonDecode(_redo.removeLast()) as Map<String, dynamic>,
    );
    _markDirty();
  }

  void markSaved() {
    _dirty = false;
    notifyListeners();
  }

  void _pushUndo() {
    _undo.add(jsonEncode(_document.toJson()));
    if (_undo.length > 100) _undo.removeAt(0);
    _redo.clear();
  }

  void _markDirty() {
    _dirty = true;
    notifyListeners();
  }
}
