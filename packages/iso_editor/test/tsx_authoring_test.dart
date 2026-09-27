import 'package:flutter_test/flutter_test.dart';
import 'package:iso_editor/iso_editor.dart';

/// Proves the editor can write a tileset, not only read one.
///
/// The point of authoring is that a tile's type and properties can be changed
/// and the file written back, and that what comes back is what Tiled would have
/// read.
void main() {
  const source = '''<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.10.2" name="castle" tilewidth="64"
    tileheight="32" tilecount="6" columns="3">
  <image source="castle.png" width="192" height="64"/>
  <tile id="0" type="floor">
    <properties>
      <property name="walkable" type="bool" value="true"/>
      <property name="cost" type="int" value="1"/>
    </properties>
  </tile>
  <tile id="2" type="wall" class="stone"/>
  <tile id="5" type="chest">
    <properties>
      <property name="itemId" value="diamond"/>
      <property name="scale" type="float" value="1.5"/>
    </properties>
  </tile>
</tileset>
''';

  group('reading and writing', () {
    test('a parsed tileset writes back the same one', () {
      final parsed = TsxTilesetDefinition.parse(source);
      final again = TsxTilesetDefinition.parse(parsed.toXmlString());

      expect(again.name, parsed.name);
      expect(again.tileWidth, parsed.tileWidth);
      expect(again.tileHeight, parsed.tileHeight);
      expect(again.tileCount, parsed.tileCount);
      expect(again.columns, parsed.columns);
      expect(again.imageSource, parsed.imageSource);
      expect(again.imageWidth, parsed.imageWidth);
      expect(again.imageHeight, parsed.imageHeight);
      expect(again.tiles.length, parsed.tiles.length);
      for (final tile in parsed.tiles) {
        final other = again.tileById(tile.id)!;
        expect(other.type, tile.type, reason: 'tile ${tile.id} lost its type');
        expect(other.className, tile.className);
        expect(other.properties, tile.properties, reason: 'tile ${tile.id}');
      }
    });

    test('property types survive the round trip', () {
      final parsed = TsxTilesetDefinition.parse(source);
      final floor = parsed.tileById(0)!;
      expect(floor.properties['walkable'], isA<bool>());
      expect(floor.properties['cost'], isA<int>());
      expect(parsed.tileById(5)!.properties['scale'], isA<double>());
      expect(parsed.tileById(5)!.properties['itemId'], isA<String>());
    });

    test('what is written is what Tiled expects', () {
      final xml = TsxTilesetDefinition.parse(source).toXmlString();
      expect(xml, contains('<tileset'));
      expect(xml, contains('name="castle"'));
      expect(xml, contains('tilewidth="64"'));
      expect(xml, contains('tilecount="6"'));
      expect(xml, contains('columns="3"'));
      expect(xml, contains('<image source="castle.png"'));
      // A tile with no class must not write an empty class attribute.
      expect(xml, isNot(contains('class=""')));
      // Every property declares its type, which is what Tiled reads back.
      expect(xml, contains('type="bool"'));
      expect(xml, contains('type="int"'));
      expect(xml, contains('type="float"'));
      // A string property may omit its type, which is what Tiled defaults to.
      expect(xml, contains('name="itemId"'));
      expect(xml, contains('value="diamond"'));
    });

    test('a file that is not a tileset is refused', () {
      expect(
        () => TsxTilesetDefinition.parse('<map name="a"/>'),
        throwsFormatException,
      );
    });
  });

  group('editing a tile', () {
    test('a type can be set and cleared', () {
      final tileset = TsxTilesetDefinition.parse(source);
      final changed = tileset.upsertTile(
        tileset.tileById(2)!.copyWith(type: 'water'),
      );
      expect(changed.tileById(2)!.type, 'water');
      // The original is untouched: the tileset is a value.
      expect(tileset.tileById(2)!.type, 'wall');
      // And the write carries it.
      expect(changed.toXmlString(), contains('type="water"'));

      final cleared = changed.upsertTile(
        changed.tileById(2)!.copyWith(type: ''),
      );
      expect(cleared.toXmlString(), isNot(contains('type="water"')));
    });

    test('a property keeps its type when it is edited', () {
      final tileset = TsxTilesetDefinition.parse(source);
      final floor = tileset.tileById(0)!;
      expect(floor.withProperty('cost', '4').properties['cost'], 4);
      expect(
        floor.withProperty('cost', '4').properties['cost'],
        isA<int>(),
        reason: 'editing a number must not turn it into text',
      );
      expect(
        floor.withProperty('walkable', 'false').properties['walkable'],
        false,
      );
      expect(
        floor.withProperty('walkable', 'false').properties['walkable'],
        isA<bool>(),
      );
      // A new property with no type to follow is text.
      expect(floor.withProperty('note', '42').properties['note'], '42');
      // An empty name is not a property.
      expect(floor.withProperty('  ', 'x').properties.length, 2);
    });

    test('a property can be removed', () {
      final floor = TsxTilesetDefinition.parse(source).tileById(0)!;
      final without = floor.withoutProperty('cost');
      expect(without.properties.containsKey('cost'), isFalse);
      expect(without.properties['walkable'], true);
      expect(
        floor.properties.containsKey('cost'),
        isTrue,
        reason: 'again, a value',
      );
    });

    test('tiles stay sorted by id however they are added', () {
      var tileset = TsxTilesetDefinition.parse(source);
      tileset = tileset
          .upsertTile(const TsxTileDefinition(id: 1, type: 'first'))
          .upsertTile(const TsxTileDefinition(id: 4, type: 'second'));
      expect(tileset.tiles.map((tile) => tile.id), [0, 1, 2, 4, 5]);
    });

    test('a tile can be removed and one can be invented', () {
      final tileset = TsxTilesetDefinition.parse(source);
      expect(tileset.removeTile(2).tiles.length, 2);
      expect(tileset.removeTile(2).toXmlString(), isNot(contains('"wall"')));
      // Authoring a tile nobody described starts from an empty value.
      final fresh = tileset.tileOrNew(4);
      expect(fresh.id, 4);
      expect(fresh.type, isEmpty);
      expect(fresh.properties, isEmpty);
      expect(
        tileset.tileOrNew(0).type,
        'floor',
        reason: 'an existing one comes back',
      );
    });
  });

  group('authoring a tileset', () {
    test('a new tileset is sized from its sheet', () {
      final tileset = TsxTilesetDefinition.create(
        name: 'jungle',
        imageSource: 'jungle.png',
        imageWidth: 192,
        imageHeight: 64,
      );
      expect(tileset.columns, 3);
      expect(tileset.rows, 2);
      expect(tileset.tileCount, 6);
      expect(tileset.tiles, isEmpty);
      // And it writes a file Tiled can open.
      final parsed = TsxTilesetDefinition.parse(tileset.toXmlString());
      expect(parsed.name, 'jungle');
      expect(parsed.imageSource, 'jungle.png');
      expect(parsed.tileCount, 6);
    });

    test('a sheet that holds no tile is refused', () {
      expect(
        () => TsxTilesetDefinition.create(
          name: 'tiny',
          imageSource: 'tiny.png',
          imageWidth: 32,
          imageHeight: 16,
        ),
        throwsArgumentError,
      );
      expect(
        () => TsxTilesetDefinition.create(
          name: 'empty',
          imageSource: 'empty.png',
          imageWidth: 0,
          imageHeight: 0,
        ),
        throwsArgumentError,
      );
    });

    test('the catalog adds, replaces and removes', () {
      final castle = TsxTilesetDefinition.parse(source);
      final jungle = TsxTilesetDefinition.create(
        name: 'jungle',
        imageSource: 'jungle.png',
        imageWidth: 192,
        imageHeight: 64,
      );
      var catalog = TsxCatalog([castle]).upsert(jungle);
      expect(catalog.tilesets.map((set) => set.name), ['castle', 'jungle']);
      expect(catalog.byName('jungle')?.imageSource, 'jungle.png');

      // The same name replaces rather than duplicates.
      catalog = catalog.upsert(
        jungle.copyWith(name: 'jungle', imageWidth: 256),
      );
      expect(catalog.tilesets.length, 2);
      expect(catalog.byName('jungle')?.imageWidth, 256);
      expect(catalog.byName('nowhere'), isNull);

      expect(catalog.remove('jungle').byName('jungle'), isNull);
      expect(catalog.tileCount, castle.tileCount + 6);
    });
  });

  group('validation', () {
    test('a good tileset has nothing to say', () {
      final validation = TsxValidation.of([TsxTilesetDefinition.parse(source)]);
      expect(validation.isValid, isTrue);
      expect(validation.errors, isEmpty);
      expect(validation.warnings, isEmpty);
    });

    test('a tile off the sheet is an error', () {
      final tileset = TsxTilesetDefinition.parse(
        source,
      ).upsertTile(const TsxTileDefinition(id: 99, type: 'ghost'));
      final validation = TsxValidation.of([tileset]);
      expect(validation.isValid, isFalse);
      expect(validation.errors.join(), contains('off the sheet'));
    });

    test('a tileset with no image or no columns is an error', () {
      final tileset = TsxTilesetDefinition.parse(
        source,
      ).copyWith(imageSource: '', columns: 0);
      final validation = TsxValidation.of([tileset]);
      expect(validation.errors.length, 2, reason: validation.errors.join('; '));
      expect(validation.errors.join(), contains('no image'));
      expect(validation.errors.join(), contains('no columns'));
    });

    test('a nameless tileset is an error', () {
      final validation = TsxValidation.of([
        TsxTilesetDefinition.parse(source).copyWith(name: '  '),
      ]);
      expect(validation.errors.join(), contains('needs a name'));
    });

    test('a tile with neither type nor property is a warning, not an error', () {
      // It is allowed, but the game cannot tell it apart from anything else, so
      // the author is told.
      final tileset = TsxTilesetDefinition.parse(
        source,
      ).upsertTile(const TsxTileDefinition(id: 1));
      final validation = TsxValidation.of([tileset]);
      expect(validation.isValid, isTrue);
      expect(validation.warnings.join(), contains('tile 1 has no type'));
    });

    test('the catalog validates everything it holds', () {
      final broken = TsxTilesetDefinition.parse(
        source,
      ).copyWith(imageSource: '');
      final catalog = TsxCatalog([TsxTilesetDefinition.parse(source), broken]);
      expect(catalog.validation.isValid, isFalse);
      expect(catalog.validation.errors.length, 1);
    });
  });
}
