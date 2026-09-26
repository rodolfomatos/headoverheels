import 'dart:io';

import 'package:iso_builder_cli/iso_builder_cli.dart';
import 'package:path/path.dart' as p;

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    _usage();
    exitCode = 64;
    return;
  }

  switch (arguments.first) {
    case 'create':
      _create(arguments.skip(1).toList());
      return;
    case 'analyze':
    case 'validate-assets':
      _analyze(arguments.skip(1).toList());
      return;
    case 'help':
    case '--help':
    case '-h':
      _usage();
      return;
    default:
      stderr.writeln('Unknown command: ${arguments.first}');
      _usage();
      exitCode = 64;
      return;
  }
}

void _create(List<String> arguments) {
  if (arguments.isEmpty) {
    stderr.writeln('Usage: iso_builder create <name> [target]');
    exitCode = 64;
    return;
  }
  final name = arguments.first;
  final target = arguments.length > 1
      ? arguments[1]
      : p.join('games', _slug(name));
  const ProjectScaffolder().create(name: name, targetPath: target);
  stdout.writeln('Created $name at $target');
}

void _analyze(List<String> arguments) {
  if (arguments.isEmpty) {
    stderr.writeln('Usage: iso_builder analyze <project>');
    exitCode = 64;
    return;
  }
  final report = const ProjectAnalyzer().analyze(arguments.first);
  for (final warning in report.warnings) {
    stdout.writeln('WARN  $warning');
  }
  for (final error in report.errors) {
    stderr.writeln('ERROR $error');
  }
  stdout.writeln(
    report.isValid
        ? 'Project valid with ${report.warnings.length} warning(s)'
        : 'Project invalid with ${report.errors.length} error(s)',
  );
  if (!report.isValid) exitCode = 1;
}

String _slug(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp('[^a-z0-9_]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

void _usage() {
  stdout.writeln('''
iso_builder

Commands:
  create <name> [target]
  analyze <project>
  validate-assets <project>
''');
}
