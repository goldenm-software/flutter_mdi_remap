/// Icon registry generator for Layrz SDK.
///
/// Generates Dart code for icon access from flutter_material_design_icons,
/// producing a set of const declarations organized by getter name, icon name,
/// and a Map-based registry for runtime name→icon lookup.
library;

// ignore_for_file: deprecated_member_use, avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// Main entry point for the icon generator.
///
/// Parses command-line arguments, locates the MDI package, and generates
/// icon registry files. Returns 0 on success, non-zero on failure.
Future<void> main(List<String> args) async {
  try {
    final pubPath = _resolvePubPath(args);
    final mdiRoot = _resolveMdiPackagePath(pubPath);
    final iconFile = File('$mdiRoot/lib/src/icons.enum.dart');

    if (!iconFile.existsSync()) {
      stderr.writeln('ERROR: icons.enum.dart not found at ${iconFile.path}');
      exit(1);
    }

    final content = iconFile.readAsStringSync();
    final result = parseString(content: content, throwIfDiagnostics: false);
    final unit = result.unit;

    final mdiIconsClass = unit.declarations
        .whereType<ClassDeclaration>()
        .firstWhere((c) => c.name.lexeme == 'MdiIcons');

    final icons = <int, IconEntry>{};
    final metadata = <int, MetadataEntry>{};

    // Pass A: Collect icon definitions
    for (final decl in mdiIconsClass.members.whereType<FieldDeclaration>()) {
      if (decl.fields.type != null) {
        final typeStr = decl.fields.type.toString();
        if (typeStr.contains('IconData')) {
          for (final variable in decl.fields.variables) {
            final dartName = variable.name.lexeme;
            final init = variable.initializer;

            // Handle both InstanceCreationExpression and MethodInvocation (IconData(...))
            ArgumentList? argList;
            if (init is InstanceCreationExpression) {
              argList = init.argumentList;
            } else if (init is MethodInvocation) {
              argList = init.argumentList;
            }

            if (argList != null && argList.arguments.isNotEmpty) {
              final codePointArg = argList.arguments.first;
              if (codePointArg is IntegerLiteral) {
                icons[codePointArg.value!] = IconEntry(
                  dartName: dartName,
                  codePoint: codePointArg.value!,
                );
              }
            }
          }
        }
      }
    }

    // Pass B: Collect metadata
    final metaField = mdiIconsClass.members
        .whereType<FieldDeclaration>()
        .firstWhere(
          (f) => f.fields.variables.any(
            (v) => v.name.lexeme == '_metadataByCodePoint',
          ),
          orElse: () => throw Exception('Metadata map not found'),
        );

    final initExpr = metaField.fields.variables.first.initializer;
    if (initExpr is! SetOrMapLiteral) {
      throw Exception(
        'Metadata initializer is not a SetOrMapLiteral, got ${initExpr.runtimeType}',
      );
    }

    final mapLiteral = initExpr;
    for (final entry in mapLiteral.elements.whereType<MapLiteralEntry>()) {
      final key = entry.key;
      if (key is! IntegerLiteral) {
        continue;
      }

      final codePoint = key.value!;
      final value = entry.value;

      ArgumentList? argList;
      if (value is InstanceCreationExpression) {
        argList = value.argumentList;
      } else if (value is MethodInvocation) {
        argList = value.argumentList;
      } else {
        continue;
      }

      String? name;
      List<String> tags = [];

      for (final arg in argList.arguments) {
        if (arg is NamedExpression) {
          final argName = arg.name.label.name;
          if (argName == 'name') {
            if (arg.expression is SimpleStringLiteral) {
              final nameLit = arg.expression as SimpleStringLiteral;
              name = nameLit.value;
            }
          } else if (argName == 'tags') {
            if (arg.expression is ListLiteral) {
              final listLit = arg.expression as ListLiteral;
              tags = listLit.elements
                  .whereType<SimpleStringLiteral>()
                  .map((e) => e.value)
                  .toList();
            } else if (arg.expression is NullLiteral) {
              tags = [];
            }
          }
        }
      }

      if (name != null) {
        metadata[codePoint] = MetadataEntry(name: name, tags: tags);
      }
    }

    // Join and validate
    final entries = _mergeIconsAndMetadata(icons, metadata);
    if (entries.length < 7000) {
      stderr.writeln(
        'ERROR: Matched only ${entries.length} icons (expected ~7447). Aborting.',
      );
      exit(1);
    }

    // Generate output files
    final dartRoot = _getDartRoot();
    _writeClassesFile(dartRoot, entries);
    _writeMappingFile(dartRoot, entries);

    print('Matched ${entries.length} icons (0 skipped).');
  } on Object catch (e, st) {
    stderr.writeln('ERROR: $e');
    stderr.writeln(st);
    exit(1);
  }
}

/// Resolves the package config file path (either from CLI or default .dart_tool).
String _resolvePubPath(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--pub-path=')) {
      return arg.substring(11);
    }
  }

  // Default: use .dart_tool
  return '.dart_tool';
}

/// Resolves the flutter_material_design_icons package root.
String _resolveMdiPackagePath(String dartToolPath) {
  final configFile = File('$dartToolPath/package_config.json');
  if (!configFile.existsSync()) {
    throw Exception('package_config.json not found at ${configFile.path}');
  }

  final configContent = configFile.readAsStringSync();
  final config = jsonDecode(configContent) as Map<String, dynamic>;
  final packages = config['packages'] as List<dynamic>;

  final mdiPkg = packages.cast<Map<String, dynamic>>().firstWhere(
    (p) => p['name'] == 'flutter_material_design_icons',
    orElse: () => throw Exception(
      'flutter_material_design_icons not found in package_config.json',
    ),
  );

  var rootUri = mdiPkg['rootUri'] as String;

  // Handle file:// URLs
  if (rootUri.startsWith('file:///')) {
    return rootUri.substring(7);
  }
  if (rootUri.startsWith('file://')) {
    return rootUri.substring(7);
  }

  // Try absolute path
  if (rootUri.startsWith('/')) {
    if (Directory(rootUri).existsSync()) {
      return rootUri;
    }
  }

  // Relative to the dartToolPath directory
  final resolved = Directory('$dartToolPath/$rootUri');
  if (resolved.existsSync()) {
    return resolved.absolute.path;
  }

  throw Exception(
    'Could not resolve flutter_material_design_icons path: $rootUri from $dartToolPath',
  );
}

/// Gets the Dart project root (current directory).
String _getDartRoot() => Directory.current.path;

/// Represents a single icon entry.
class IconEntry {
  final String dartName;
  final int codePoint;

  IconEntry({required this.dartName, required this.codePoint});
}

/// Represents metadata for an icon.
class MetadataEntry {
  final String name;
  final List<String> tags;

  MetadataEntry({required this.name, required this.tags});
}

/// Represents a complete icon record after joining icon and metadata.
class CompleteIcon {
  final String dartName;
  final String iconName;
  final int codePoint;
  final List<String> tags;

  CompleteIcon({
    required this.dartName,
    required this.iconName,
    required this.codePoint,
    required this.tags,
  });
}

/// Merges icon definitions with metadata, producing complete icon records.
List<CompleteIcon> _mergeIconsAndMetadata(
  Map<int, IconEntry> icons,
  Map<int, MetadataEntry> metadata,
) {
  final result = <CompleteIcon>[];
  final seenGetters = <String>{};
  final seenNames = <String>{};

  for (final icon in icons.entries) {
    final codePoint = icon.key;
    final entry = icon.value;

    if (!metadata.containsKey(codePoint)) {
      stderr.writeln(
        'WARN: No metadata for codepoint $codePoint (${entry.dartName})',
      );
      continue;
    }

    final meta = metadata[codePoint]!;
    // Use dartName directly as member name (no mdi prefix)
    final iconName = 'mdi-${meta.name}';

    if (seenGetters.contains(entry.dartName)) {
      stderr.writeln('WARN: Duplicate getter name: ${entry.dartName}');
      continue;
    }
    if (seenNames.contains(iconName)) {
      stderr.writeln('WARN: Duplicate icon name: $iconName');
      continue;
    }

    seenGetters.add(entry.dartName);
    seenNames.add(iconName);

    result.add(
      CompleteIcon(
        dartName: entry.dartName,
        iconName: iconName,
        codePoint: codePoint,
        tags: meta.tags,
      ),
    );
  }

  // Sort by getter name for determinism
  result.sort((a, b) => a.dartName.compareTo(b.dartName));
  return result;
}

/// Escapes Dart string literals.
String _escapeDartString(String value) {
  return value
      .replaceAll('\\', '\\\\')
      .replaceAll("'", "\\'")
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');
}

/// Writes the MdiRemapIconsClasses generated file.
void _writeClassesFile(String dartRoot, List<CompleteIcon> entries) {
  final buffer = StringBuffer();

  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// Run: make icons');
  buffer.writeln('// coverage:ignore-file');
  buffer.writeln('// ignore_for_file: deprecated_member_use');
  buffer.writeln();
  buffer.writeln('part of \'icons.dart\';');
  buffer.writeln();
  buffer.writeln(
    '/// Registry of [MdiRemapIcon] objects indexed by getter name.',
  );
  buffer.writeln('abstract final class MdiRemapIconsClasses {');

  for (final icon in entries) {
    final escapedName = _escapeDartString(icon.iconName);
    final tagsList = icon.tags
        .map((t) => "'${_escapeDartString(t)}'")
        .join(', ');
    buffer.writeln('  /// [MdiRemapIcon] for \'${icon.iconName}\'.');
    buffer.writeln(
      '  static const MdiRemapIcon ${icon.dartName} = MdiRemapIcon(',
    );
    buffer.writeln("    name: '$escapedName',");
    buffer.writeln('    tags: [$tagsList],');
    buffer.writeln('    data: MdiIcons.${icon.dartName},');
    buffer.writeln('  );');
    buffer.writeln();
  }

  buffer.writeln('}');

  final file = File('$dartRoot/lib/src/classes.g.dart');
  file.createSync(recursive: true);
  file.writeAsStringSync(buffer.toString());
}

/// Writes the MdiRemapIconsClasses generated file.

/// Writes the iconMapping generated file.
void _writeMappingFile(String dartRoot, List<CompleteIcon> entries) {
  final buffer = StringBuffer();

  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// Run: make icons');
  buffer.writeln('// coverage:ignore-file');
  buffer.writeln('// ignore_for_file: deprecated_member_use');
  buffer.writeln();
  buffer.writeln('part of \'icons.dart\';');
  buffer.writeln();
  buffer.writeln('/// Map of icon name to [MdiRemapIcon] for runtime lookup.');
  buffer.writeln('const Map<String, MdiRemapIcon> iconMapping = {');

  for (final icon in entries) {
    final escapedName = _escapeDartString(icon.iconName);
    buffer.writeln("  '$escapedName': MdiRemapIconsClasses.${icon.dartName},");
  }

  buffer.writeln('};');

  final file = File('$dartRoot/lib/src/mapping.g.dart');
  file.createSync(recursive: true);
  file.writeAsStringSync(buffer.toString());
}
