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

  String get documentKey {
    final slug = _document.projectName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return 'projects/${slug.isEmpty ? 'untitled' : slug}/editor.json';
  }

  Future<void> load({String? key}) async {
    final document = EditorDocument.fromJson(
      jsonDecode(await storage.readText(key ?? documentKey))
          as Map<String, dynamic>,
    );
    _document = document;
    _selection = null;
    _dirty = false;
    _undo.clear();
    _redo.clear();
    notifyListeners();
  }

  Future<void> save({String? key}) async {
    await storage.writeText(key ?? documentKey, _document.encode());
    markSaved();
  }

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

  void applyCell(
    CellAddress address, {
    int tileId = 1,
    String objectType = 'entity',
  }) {
    switch (_tool) {
      case EditorTool.select:
        _selection = _objectAt(address)?.id;
        notifyListeners();
        return;
      case EditorTool.tile:
        setTile(0, address, tileId);
        return;
      case EditorTool.object:
        placeObject(_newObject(address, objectType));
        return;
      case EditorTool.spawn:
        placeObject(_newObject(address, 'spawn'));
        return;
      case EditorTool.erase:
        setTile(0, address, null);
        final object = _objectAt(address);
        if (object != null) removeObject(object.id);
        return;
    }
  }

  void setLayerVisibility(int layerIndex, bool visible) {
    if (layerIndex < 0 || layerIndex >= _document.layers.length) return;
    final layer = _document.layers[layerIndex];
    if (layer.visible == visible) return;
    _pushUndo();
    final layers = [..._document.layers];
    layers[layerIndex] = TileLayer(
      name: layer.name,
      visible: visible,
      locked: layer.locked,
      cells: layer.cells,
    );
    _document = _document.copyWith(layers: layers);
    _markDirty();
  }

  ObjectPlacement _newObject(CellAddress address, String type) {
    final id =
        '${type}_${address.x}_${address.y}_${_document.objects.length + 1}';
    return ObjectPlacement(
      id: id,
      name: id,
      type: type,
      position: Vector3(address.x.toDouble(), address.y.toDouble(), 0),
    );
  }

  ObjectPlacement? _objectAt(CellAddress address) {
    for (final object in _document.objects.reversed) {
      final x = object.position.x.round();
      final y = object.position.y.round();
      if (x == address.x && y == address.y) return object;
    }
    return null;
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
