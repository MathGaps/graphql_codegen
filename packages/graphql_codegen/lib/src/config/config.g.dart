// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GraphQLCodegenConfigScalar _$GraphQLCodegenConfigScalarFromJson(Map<String, dynamic> json) =>
    GraphQLCodegenConfigScalar(
      type: json['type'] as String,
      import: json['import'] as String?,
      fromJsonFunctionName: json['fromJsonFunctionName'] as String?,
      toJsonFunctionName: json['toJsonFunctionName'] as String?,
    );

Map<String, dynamic> _$GraphQLCodegenConfigScalarToJson(GraphQLCodegenConfigScalar instance) =>
    <String, dynamic>{
      'type': instance.type,
      'import': instance.import,
      'fromJsonFunctionName': instance.fromJsonFunctionName,
      'toJsonFunctionName': instance.toJsonFunctionName,
    };

GraphQLCodegenConfig _$GraphQLCodegenConfigFromJson(Map<String, dynamic> json) =>
    GraphQLCodegenConfig(
      clients: (json['clients'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$GraphQLCodegenConfigClientEnumMap, e))
              .toSet() ??
          const {},
      disableContextReplacement: json['disableContextReplacement'] as bool? ?? false,
      scalars: (json['scalars'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, GraphQLCodegenConfigScalar.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      addTypename: json['addTypename'] as bool? ?? true,
      assetsPath: json['assetsPath'] as String? ?? "lib/**{.graphql,.gql}",
      scopes: (json['scopes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const ["**{.graphql,.gql}"],
      addTypenameExcludedPaths:
          (json['addTypenameExcludedPaths'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      generatedFileHeader: json['generatedFileHeader'] as String? ?? "",
      namingSeparator: json['namingSeparator'] as String? ?? r"$",
      extraKeywords:
          (json['extraKeywords'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      outputDirectory: json['outputDirectory'] as String? ?? '.',
      clientDirectives:
          (json['clientDirectives'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      externalAssets:
          (json['externalAssets'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      externalSchemaScope: json['externalSchemaScope'] as String?,
    );

Map<String, dynamic> _$GraphQLCodegenConfigToJson(GraphQLCodegenConfig instance) =>
    <String, dynamic>{
      'clients': instance.clients.map((e) => _$GraphQLCodegenConfigClientEnumMap[e]!).toList(),
      'scalars': instance.scalars,
      'addTypename': instance.addTypename,
      'assetsPath': instance.assetsPath,
      'scopes': instance.scopes,
      'addTypenameExcludedPaths': instance.addTypenameExcludedPaths,
      'generatedFileHeader': instance.generatedFileHeader,
      'namingSeparator': instance.namingSeparator,
      'extraKeywords': instance.extraKeywords,
      'outputDirectory': instance.outputDirectory,
      'disableContextReplacement': instance.disableContextReplacement,
      'clientDirectives': instance.clientDirectives,
      'externalAssets': instance.externalAssets,
      'externalSchemaScope': instance.externalSchemaScope,
    };

const _$GraphQLCodegenConfigClientEnumMap = {
  GraphQLCodegenConfigClient.graphql: 'graphql',
  GraphQLCodegenConfigClient.graphqlFlutter: 'graphql_flutter',
};
