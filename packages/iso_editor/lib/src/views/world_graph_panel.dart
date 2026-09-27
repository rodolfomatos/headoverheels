import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iso_core/iso_core.dart';

import 'world_graph_view.dart';

class WorldGraphPanel extends StatefulWidget {
  const WorldGraphPanel({required this.source, this.onSave, super.key});

  /// Reads `world.json`; the editor never assumes a bundle here.
  final Future<String> Function() source;
  final Future<void> Function(String json)? onSave;

  @override
  State<WorldGraphPanel> createState() => _WorldGraphPanelState();
}

class _WorldGraphPanelState extends State<WorldGraphPanel> {
  WorldGraph? _graph;
  WorldValidation? _validation;
  String? _selectedRoomId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final json = jsonDecode(await widget.source()) as Map<String, dynamic>;
      final graph = WorldGraph.fromJson(json);
      setState(() {
        _graph = graph;
        _validation = validateWorld(graph);
        _error = null;
      });
    } catch (error) {
      setState(() => _error = '$error');
    }
  }

  void _update(WorldGraph graph) {
    setState(() {
      _graph = graph;
      _validation = validateWorld(graph);
    });
  }

  RoomInfo? get _room {
    final graph = _graph;
    final id = _selectedRoomId;
    if (graph == null || id == null) return null;
    return graph.getRoom(id);
  }

  @override
  Widget build(BuildContext context) {
    final graph = _graph;
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('World could not be read: $_error'),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('world-reload-button'),
                onPressed: _load,
                child: const Text('Reload'),
              ),
            ],
          ),
        ),
      );
    }
    if (graph == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final validation = _validation!;
    // Fill the slot: an editor panel must use all available space, and the
    // graph canvas needs a stable origin for hit testing.
    return SizedBox.expand(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: WorldGraphView(
              key: const Key('world-graph-view'),
              graph: graph,
              validation: validation,
              selectedRoomId: _selectedRoomId,
              onRoomSelected: (id) => setState(() => _selectedRoomId = id),
            ),
          ),
          const VerticalDivider(width: 1),
          SizedBox(
            width: 300,
            child: Material(
              type: MaterialType.transparency,
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${graph.rooms.length} rooms · '
                          '${graph.rooms.values.fold<int>(0, (sum, room) => sum + room.exits.length)} exits',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      if (widget.onSave != null)
                        IconButton(
                          key: const Key('world-save-button'),
                          tooltip: 'Save world.json',
                          onPressed: _save,
                          icon: const Icon(Icons.save_outlined),
                        ),
                    ],
                  ),
                  _IssueSummary(validation: validation),
                  const SizedBox(height: 8),
                  if (_room == null)
                    const Text('Select a room to edit its exits')
                  else ...[
                    _RoomExits(
                      room: _room!,
                      rooms: graph.rooms,
                      onChange: (exits) => _update(
                        graph.upsertRoom(_room!.copyWith(exits: exits)),
                      ),
                    ),
                    const Divider(),
                    _RoomTriggers(
                      room: _room!,
                      rooms: graph.rooms,
                      onChange: (triggers) => _update(
                        graph.upsertRoom(_room!.copyWith(triggers: triggers)),
                      ),
                    ),
                  ],
                  const Divider(),
                  Text('Issues', style: Theme.of(context).textTheme.titleSmall),
                  if (validation.issues.isEmpty)
                    const Text('No issues')
                  else
                    for (final issue in validation.issues)
                      ListTile(
                        key: Key('world-issue-${issue.kind.name}'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          issue.severity == WorldIssueSeverity.error
                              ? Icons.error_outline
                              : issue.severity == WorldIssueSeverity.warning
                              ? Icons.warning_amber_outlined
                              : Icons.info_outline,
                          size: 18,
                        ),
                        title: Text(
                          '${issue.roomId}: ${issue.message}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () =>
                            setState(() => _selectedRoomId = issue.roomId),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final graph = _graph;
    final onSave = widget.onSave;
    if (graph == null || onSave == null) return;
    await onSave(graph.toJsonString());
  }
}

class _IssueSummary extends StatelessWidget {
  const _IssueSummary({required this.validation});

  final WorldValidation validation;

  @override
  Widget build(BuildContext context) {
    final errors = validation.errors.length;
    final warnings = validation.warnings.length;
    final color = errors > 0
        ? Theme.of(context).colorScheme.error
        : warnings > 0
        ? Colors.orange
        : Colors.green;
    return Text(
      '$errors error(s) · $warnings warning(s)',
      key: const Key('world-issue-summary'),
      style: TextStyle(color: color, fontSize: 12),
    );
  }
}

class _RoomExits extends StatelessWidget {
  const _RoomExits({
    required this.room,
    required this.rooms,
    required this.onChange,
  });

  final RoomInfo room;
  final Map<String, RoomInfo> rooms;
  final ValueChanged<List<RoomExit>> onChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(room.id, style: Theme.of(context).textTheme.titleSmall),
        Text(
          '${room.file} · ${room.theme}',
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < room.exits.length; index++)
          _ExitRow(
            key: ValueKey('${room.id}-exit-$index'),
            exit: room.exits[index],
            rooms: rooms,
            onChanged: (updated) {
              final exits = [...room.exits];
              exits[index] = updated;
              onChange(exits);
            },
            onRemoved: () {
              final exits = [...room.exits]..removeAt(index);
              onChange(exits);
            },
          ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('world-add-exit-button'),
            onPressed: () => onChange([
              ...room.exits,
              RoomExit(
                direction: 'north',
                room: rooms.keys.firstWhere(
                  (id) => id != room.id,
                  orElse: () => room.id,
                ),
                entrance: 'south',
              ),
            ]),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add exit'),
          ),
        ),
      ],
    );
  }
}

/// Triggers are the puzzle layer: switches, doors, teleports, monsters. The
/// graph stores identity and targets; the game binds behaviour to them.
class _RoomTriggers extends StatelessWidget {
  const _RoomTriggers({
    required this.room,
    required this.rooms,
    required this.onChange,
  });

  final RoomInfo room;
  final Map<String, RoomInfo> rooms;
  final ValueChanged<List<RoomTrigger>> onChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Triggers (${room.triggers.length})',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (room.triggers.isEmpty) const Text('No triggers in this room'),
        for (var index = 0; index < room.triggers.length; index++)
          _TriggerRow(
            key: ValueKey('${room.id}-trigger-$index'),
            trigger: room.triggers[index],
            rooms: rooms,
            onChanged: (updated) {
              final triggers = [...room.triggers];
              triggers[index] = updated;
              onChange(triggers);
            },
            onRemoved: () {
              final triggers = [...room.triggers]..removeAt(index);
              onChange(triggers);
            },
          ),
      ],
    );
  }
}

class _TriggerRow extends StatefulWidget {
  const _TriggerRow({
    required this.trigger,
    required this.rooms,
    required this.onChanged,
    required this.onRemoved,
    super.key,
  });

  final RoomTrigger trigger;
  final Map<String, RoomInfo> rooms;
  final ValueChanged<RoomTrigger> onChanged;
  final VoidCallback onRemoved;

  @override
  State<_TriggerRow> createState() => _TriggerRowState();
}

class _TriggerRowState extends State<_TriggerRow> {
  late final TextEditingController _target;
  String? _roomTarget;

  @override
  void initState() {
    super.initState();
    _target = TextEditingController(text: localTargetOf(widget.trigger) ?? '');
    _roomTarget = roomTargetOf(widget.trigger);
  }

  @override
  void didUpdateWidget(_TriggerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger.id != widget.trigger.id) {
      _target.text = localTargetOf(widget.trigger) ?? '';
      _roomTarget = roomTargetOf(widget.trigger);
    }
  }

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  void _writeTargets() {
    final target = _target.text.trim();
    final roomTarget = _roomTarget;
    final properties = Map<String, dynamic>.from(widget.trigger.properties);
    final nested = Map<String, dynamic>.from(
      (properties['properties'] as Map?) ?? const {},
    );
    if (target.isEmpty) {
      nested.remove('targetId');
    } else {
      nested['targetId'] = target;
    }
    if (roomTarget == null) {
      nested.remove('room');
    } else {
      nested['room'] = roomTarget;
    }
    if (nested.isEmpty) {
      properties.remove('properties');
    } else {
      properties['properties'] = nested;
    }
    widget.onChanged(widget.trigger.copyWith(properties: properties));
  }

  @override
  Widget build(BuildContext context) {
    final trigger = widget.trigger;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${trigger.type} · ${trigger.id}',
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '(${trigger.position.x.toInt()}, ${trigger.position.y.toInt()})',
                style: const TextStyle(fontSize: 10),
              ),
              IconButton(
                key: Key('trigger-remove-${trigger.id}'),
                iconSize: 16,
                onPressed: widget.onRemoved,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: Key('trigger-target-${trigger.id}'),
                  controller: _target,
                  onChanged: (_) => _writeTargets(),
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'targetId',
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 96,
                child: DropdownButton<String>(
                  key: Key('trigger-room-${trigger.id}'),
                  isExpanded: true,
                  value:
                      _roomTarget != null &&
                          widget.rooms.containsKey(_roomTarget)
                      ? _roomTarget
                      : null,
                  hint: const Text('room', style: TextStyle(fontSize: 10)),
                  onChanged: (value) {
                    setState(() => _roomTarget = value);
                    _writeTargets();
                  },
                  items: [
                    for (final id in widget.rooms.keys)
                      DropdownMenuItem(
                        value: id,
                        child: Text(
                          id,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExitRow extends StatelessWidget {
  const _ExitRow({
    required this.exit,
    required this.rooms,
    required this.onChanged,
    required this.onRemoved,
    super.key,
  });

  static const directions = ['north', 'south', 'east', 'west', 'up', 'down'];

  final RoomExit exit;
  final Map<String, RoomInfo> rooms;
  final ValueChanged<RoomExit> onChanged;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: DropdownButton<String>(
              key: const Key('exit-direction'),
              isExpanded: true,
              value: directions.contains(exit.direction)
                  ? exit.direction
                  : null,
              onChanged: (value) {
                if (value != null) onChanged(exit.copyWith(direction: value));
              },
              items: [
                for (final direction in directions)
                  DropdownMenuItem(
                    value: direction,
                    child: Text(
                      direction,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: DropdownButton<String>(
              key: const Key('exit-target'),
              isExpanded: true,
              value: rooms.containsKey(exit.room) ? exit.room : null,
              onChanged: (value) {
                if (value != null) onChanged(exit.copyWith(room: value));
              },
              items: [
                for (final id in rooms.keys)
                  DropdownMenuItem(
                    value: id,
                    child: Text(id, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
          IconButton(
            key: const Key('exit-lock'),
            tooltip: 'Locked',
            iconSize: 18,
            onPressed: () => onChanged(exit.copyWith(isLocked: !exit.isLocked)),
            icon: Icon(exit.isLocked ? Icons.lock : Icons.lock_open),
          ),
          IconButton(
            key: const Key('exit-remove'),
            iconSize: 18,
            onPressed: onRemoved,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
