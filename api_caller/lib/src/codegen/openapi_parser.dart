import 'package:yaml/yaml.dart';

class ApiParameterSpec {
  final String name;
  final String inType; // 'path', 'query', 'header'
  final bool required;
  final String type;
  final String? description;

  ApiParameterSpec({
    required this.name,
    required this.inType,
    required this.required,
    required this.type,
    this.description,
  });
}

class ApiOperationSpec {
  final String operationId;
  final String method;
  final String path;
  final String? description;
  final List<ApiParameterSpec> parameters;
  final String? requestBodyModel;
  final String? responseBodyModel;
  final bool isResponseList;
  final bool requiresAuth;
  final Map<String, dynamic> vendorExtensions;

  ApiOperationSpec({
    required this.operationId,
    required this.method,
    required this.path,
    this.description,
    this.parameters = const <ApiParameterSpec>[],
    this.requestBodyModel,
    this.responseBodyModel,
    this.isResponseList = false,
    this.requiresAuth = false,
    this.vendorExtensions = const <String, dynamic>{},
  });
}

class SchemaPropertySpec {
  final String name;
  final String dartType;
  final bool isNullable;
  final bool isList;
  final String? itemType;
  final bool isEnum;
  final List<String> enumValues;

  SchemaPropertySpec({
    required this.name,
    required this.dartType,
    required this.isNullable,
    this.isList = false,
    this.itemType,
    this.isEnum = false,
    this.enumValues = const <String>[],
  });
}

class ModelSchemaSpec {
  final String name;
  final Map<String, SchemaPropertySpec> properties;
  final String? description;

  ModelSchemaSpec({
    required this.name,
    required this.properties,
    this.description,
  });
}

class OpenApiSpecResult {
  final String title;
  final String version;
  final Map<String, ModelSchemaSpec> models;
  final List<ApiOperationSpec> operations;
  final List<String> warnings;

  OpenApiSpecResult({
    required this.title,
    required this.version,
    required this.models,
    required this.operations,
    this.warnings = const <String>[],
  });
}

/// OpenAPI 3.x specification parser converting raw YAML/JSON into structured codegen specs.
class OpenApiParser {
  OpenApiSpecResult parse(String content) {
    dynamic rawYaml;
    try {
      rawYaml = loadYaml(content);
    } catch (e) {
      throw FormatException(
          'Malformed OpenAPI YAML specification document: $e');
    }

    if (rawYaml is! Map) {
      throw const FormatException(
          'OpenAPI specification must be a key-value map.');
    }

    final List<String> warnings = <String>[];

    final Map<dynamic, dynamic> info =
        (rawYaml['info'] as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};
    final String title = (info['title'] as String?) ?? 'API';
    final String version = (info['version'] as String?) ?? '1.0.0';

    final Map<String, ModelSchemaSpec> models = <String, ModelSchemaSpec>{};
    final List<ApiOperationSpec> operations = <ApiOperationSpec>[];

    // Parse Components / Schemas
    final Map<dynamic, dynamic> components =
        (rawYaml['components'] as Map<dynamic, dynamic>?) ??
            <dynamic, dynamic>{};
    final Map<dynamic, dynamic> schemas =
        (components['schemas'] as Map<dynamic, dynamic>?) ??
            <dynamic, dynamic>{};

    schemas.forEach((dynamic key, dynamic value) {
      if (value is Map) {
        final String modelName = _capitalize(key.toString());
        final Map<dynamic, dynamic> props =
            (value['properties'] as Map<dynamic, dynamic>?) ??
                <dynamic, dynamic>{};
        final List<dynamic> requiredFields =
            (value['required'] as List<dynamic>?) ?? <dynamic>[];

        final Map<String, SchemaPropertySpec> propertySpecs =
            <String, SchemaPropertySpec>{};

        props.forEach((dynamic pKey, dynamic pValue) {
          if (pValue is Map) {
            final String propName = pKey.toString();
            final bool isReq = requiredFields.contains(propName);
            final String typeStr = pValue['type']?.toString() ?? 'string';
            final bool isNullable = !isReq || (pValue['nullable'] == true);

            if (typeStr == 'array') {
              final Map<dynamic, dynamic> items =
                  (pValue['items'] as Map<dynamic, dynamic>?) ??
                      <dynamic, dynamic>{};
              final String itemRef = items['\$ref']?.toString() ?? '';
              final String rawItemType = itemRef.isNotEmpty
                  ? itemRef.split('/').last
                  : _mapOpenApiType(items['type']?.toString());
              final String itemType = _capitalize(rawItemType);

              propertySpecs[propName] = SchemaPropertySpec(
                name: propName,
                dartType: 'List<$itemType>',
                isNullable: isNullable,
                isList: true,
                itemType: itemType,
              );
            } else if (pValue['enum'] != null && pValue['enum'] is List) {
              final List<String> enumVals = (pValue['enum'] as List)
                  .map((dynamic e) => e.toString())
                  .toList();
              final String enumType = _capitalize(propName);

              propertySpecs[propName] = SchemaPropertySpec(
                name: propName,
                dartType: enumType,
                isNullable: isNullable,
                isEnum: true,
                enumValues: enumVals,
              );
            } else if (pValue['\$ref'] != null) {
              final String refStr = pValue['\$ref'].toString();
              final String refModel = _capitalize(refStr.split('/').last);
              propertySpecs[propName] = SchemaPropertySpec(
                name: propName,
                dartType: refModel,
                isNullable: isNullable,
              );
            } else {
              final String dType = _mapOpenApiType(typeStr);
              propertySpecs[propName] = SchemaPropertySpec(
                name: propName,
                dartType: dType,
                isNullable: isNullable,
              );
            }
          }
        });

        models[modelName] = ModelSchemaSpec(
          name: modelName,
          properties: propertySpecs,
          description: value['description']?.toString(),
        );
      }
    });

    // Parse Paths & Operations
    final Map<dynamic, dynamic> paths =
        (rawYaml['paths'] as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};
    paths.forEach((dynamic pathUrl, dynamic pathValue) {
      if (pathValue is Map) {
        pathValue.forEach((dynamic methodKey, dynamic methodValue) {
          final String method = methodKey.toString().toLowerCase();
          if (<String>['get', 'post', 'put', 'patch', 'delete', 'head']
              .contains(method)) {
            if (methodValue is Map) {
              final String opId = methodValue['operationId']?.toString() ??
                  '${method}_${pathUrl.toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

              final List<ApiParameterSpec> params = <ApiParameterSpec>[];
              final List<dynamic> rawParams =
                  (methodValue['parameters'] as List<dynamic>?) ?? <dynamic>[];
              for (final dynamic p in rawParams) {
                if (p is Map) {
                  final Map<dynamic, dynamic> schema =
                      (p['schema'] as Map<dynamic, dynamic>?) ??
                          <dynamic, dynamic>{};
                  params.add(ApiParameterSpec(
                    name: p['name'].toString(),
                    inType: p['in'].toString(),
                    required: p['required'] == true,
                    type: _mapOpenApiType(schema['type']?.toString()),
                    description: p['description']?.toString(),
                  ));
                }
              }

              // Extract Request Body model
              String? reqModel;
              if (methodValue['requestBody'] != null &&
                  methodValue['requestBody'] is Map) {
                final Map<dynamic, dynamic> content =
                    (methodValue['requestBody']['content']
                            as Map<dynamic, dynamic>?) ??
                        <dynamic, dynamic>{};
                final Map<dynamic, dynamic> jsonContent =
                    (content['application/json'] as Map<dynamic, dynamic>?) ??
                        <dynamic, dynamic>{};
                final Map<dynamic, dynamic> schema =
                    (jsonContent['schema'] as Map<dynamic, dynamic>?) ??
                        <dynamic, dynamic>{};
                if (schema['\$ref'] != null) {
                  reqModel =
                      _capitalize(schema['\$ref'].toString().split('/').last);
                }
              }

              // Extract Response Body model
              String? respModel;
              bool isList = false;
              final Map<dynamic, dynamic> responses =
                  (methodValue['responses'] as Map<dynamic, dynamic>?) ??
                      <dynamic, dynamic>{};
              final Map<dynamic, dynamic> okResp =
                  (responses['200'] as Map<dynamic, dynamic>?) ??
                      (responses['201'] as Map<dynamic, dynamic>?) ??
                      (responses['default'] as Map<dynamic, dynamic>?) ??
                      <dynamic, dynamic>{};
              if (okResp['content'] != null && okResp['content'] is Map) {
                final Map<dynamic, dynamic> content =
                    (okResp['content'] as Map<dynamic, dynamic>?) ??
                        <dynamic, dynamic>{};
                final Map<dynamic, dynamic> jsonContent =
                    (content['application/json'] as Map<dynamic, dynamic>?) ??
                        <dynamic, dynamic>{};
                final Map<dynamic, dynamic> schema =
                    (jsonContent['schema'] as Map<dynamic, dynamic>?) ??
                        <dynamic, dynamic>{};
                if (schema['\$ref'] != null) {
                  respModel =
                      _capitalize(schema['\$ref'].toString().split('/').last);
                } else if (schema['type'] == 'array') {
                  isList = true;
                  final Map<dynamic, dynamic> items =
                      (schema['items'] as Map<dynamic, dynamic>?) ??
                          <dynamic, dynamic>{};
                  if (items['\$ref'] != null) {
                    respModel =
                        _capitalize(items['\$ref'].toString().split('/').last);
                  }
                }
              }

              final bool reqAuth = methodValue['security'] != null;
              final Map<String, dynamic> vendorExts = <String, dynamic>{};
              methodValue.forEach((dynamic k, dynamic v) {
                if (k.toString().startsWith('x-')) {
                  vendorExts[k.toString()] = v;
                }
              });

              operations.add(ApiOperationSpec(
                operationId: opId,
                method: method.toUpperCase(),
                path: pathUrl.toString(),
                description: methodValue['description']?.toString(),
                parameters: params,
                requestBodyModel: reqModel,
                responseBodyModel: respModel,
                isResponseList: isList,
                requiresAuth: reqAuth,
                vendorExtensions: vendorExts,
              ));
            }
          }
        });
      }
    });

    return OpenApiSpecResult(
      title: title,
      version: version,
      models: models,
      operations: operations,
      warnings: warnings,
    );
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static String _mapOpenApiType(String? type) {
    switch (type) {
      case 'integer':
        return 'int';
      case 'number':
        return 'double';
      case 'boolean':
        return 'bool';
      case 'string':
        return 'String';
      default:
        return 'dynamic';
    }
  }
}
