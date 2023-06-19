import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:gql/language.dart';
import 'package:graphql_codegen/graphql_codegen.dart';
import 'package:graphql_codegen/src/transform/transform.dart';
import 'package:package_file_loader/package_file_loader.dart';
import 'package:path/path.dart' as path;

final p = path.Context(style: path.Style.posix);

/// The builder class.
class GraphQLBuilder extends Builder {
  final BuilderOptions options;
  final GraphQLCodegenConfig config;

  static final wildcardPattern = new RegExp(r"[\[\]\?\*]+");

  /// A static method to initialize the builder.
  static GraphQLBuilder builder(BuilderOptions options) => GraphQLBuilder(options);

  GraphQLBuilder(this.options)
      : config = GraphQLCodegenConfig.fromJson(
          jsonDecode(
            jsonEncode(
              options.config,
            ),
          ) as Map<String, dynamic>,
        );

  String get _assetsPrefix {
    final glob = config.assetsPath;
    String path = '';
    for (final segment in p.split(glob)) {
      if (wildcardPattern.hasMatch(segment)) {
        break;
      }
      path = p.join(path, segment);
    }
    return path;
  }

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final scope = (config.scopes).whereType<String?>().firstWhere(
          (element) => element != null && Glob(element).matches(buildStep.inputId.path),
          orElse: () => null,
        );
    if (scope == null) {
      return;
    }
    final assets = buildStep.findAssets(Glob(scope));
    final assetsPathGlob = Glob(config.assetsPath);
    final entries = await assets
        .where((asset) => assetsPathGlob.matches(asset.path))
        .asyncMap(
          (event) async => MapEntry(
            event,
            parseString(await buildStep.readAsString(event)),
          ),
        )
        .map((event) => MapEntry(event.key, transform(config, event.value)))
        .toList();

    final scopeGlob = Glob(scope);
    final externalAssets = config.externalAssets;
    for (final p in externalAssets) {
      Future<void> addAssetFileAsEntry(LoadedFileAsset file) async {
        final package = 'package:${file.assetId.package}';
        final targetPath = file.file.path;
        final isDirectory = FileSystemEntity.isDirectorySync(targetPath);
        if (isDirectory) {
          final dir = Directory(targetPath);
          final files = dir.listSync(recursive: true).where((f) => scopeGlob.matches(f.path));
          for (final f in files) {
            final filePath = '${file.assetId.path}/${path.relative(f.path, from: targetPath)}';
            entries.add(
              MapEntry(
                AssetId(
                  package,
                  filePath,
                ),
                parseString(
                  await File(f.path).readAsString(),
                ),
              ),
            );
          }
        } else {
          if (scopeGlob.matches(targetPath)) {
            final filePath = file.assetId.path;
            entries.add(
              MapEntry(
                AssetId(package, filePath),
                parseString(await file.file.readAsString()),
              ),
            );
          }
        }
      }

      final file = await loadPackageFileAsAsset(p);
      await addAssetFileAsEntry(file);
    }

    final result = await generate<AssetId>(
      SchemaConfig<AssetId>(
        entries: BuiltMap.of(Map.fromEntries(entries)),
        lookupPath: (id) => _resolveOutputDir(
          p.dirname(id.path),
          p.basename(id.path) + ".dart",
        ),
      ),
      config,
    );
    final targetAsset = buildStep.inputId.addExtension('.dart');
    _writeProgram(
      config,
      buildStep,
      AssetId(
        targetAsset.package,
        _resolveOutputDir(
          p.dirname(targetAsset.path),
          p.basename(targetAsset.path),
        ),
      ),
      result.entries[buildStep.inputId]!,
    );
  }

  void _writeProgram(
    GraphQLCodegenConfig config,
    BuildStep buildStep,
    AssetId targetAssetId,
    Library library,
  ) {
    final formatter = DartFormatter();
    final emitter = DartEmitter(useNullSafetySyntax: true);
    final generatedCode = library.accept(emitter);
    final contents = formatter.format(
      "${config.generatedFileHeader}${generatedCode}",
    );
    buildStep.writeAsString(targetAssetId, contents);
  }

  String _resolveOutputDir(String dir, String file) {
    if (!p.isAbsolute(config.outputDirectory)) {
      return p.join(dir, config.outputDirectory, file);
    }
    return p.join(
      p.relative(config.outputDirectory, from: '/'),
      p.relative(dir, from: _assetsPrefix),
      file,
    );
  }

  @override
  Map<String, List<String>> get buildExtensions {
    if (p.isRelative(config.outputDirectory)) {
      return {
        '{{dir}}/{{file}}.graphql': [
          p.join('{{dir}}', config.outputDirectory, '{{file}}.graphql.dart')
        ],
        '{{dir}}/{{file}}.gql': [p.join('{{dir}}', config.outputDirectory, '{{file}}.gql.dart')]
      };
    }
    return {
      path.join(_assetsPrefix, '{{dir}}', '{{file}}.graphql'): [
        p.join(
          p.relative(config.outputDirectory, from: '/'),
          '{{dir}}',
          '{{file}}.graphql.dart',
        )
      ],
      path.join(_assetsPrefix, '{{dir}}', '{{file}}.gql'): [
        p.join(
          p.relative(config.outputDirectory, from: '/'),
          '{{dir}}',
          '{{file}}.gql.dart',
        )
      ],
    };
  }
}
