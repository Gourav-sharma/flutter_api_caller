import 'model_generator.dart';
import 'openapi_parser.dart';

/// Typed API client generator from OpenAPI paths and operations.
class ApiGenerator {
  String generateApiCode({
    required String apiName,
    required List<ApiOperationSpec> operations,
    required Map<String, ModelSchemaSpec> models,
  }) {
    final StringBuffer buffer = StringBuffer();

    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln();
    buffer.writeln(
        "import 'package:flutter_api_caller/flutter_api_caller.dart';");

    // Imports for models if needed
    for (final modelName in models.keys) {
      buffer.writeln("import '../models/${modelName.toLowerCase()}.dart';");
    }
    buffer.writeln();

    final String interfaceName = '${apiName}Api';
    final String implName = '${apiName}ApiImpl';

    // 1. Abstract Interface Definition
    buffer.writeln('abstract class $interfaceName {');
    for (final op in operations) {
      final String returnType = _buildResponseType(op);
      final String methodName =
          ModelGenerator.sanitizeIdentifier(op.operationId);
      final String paramsSignature = _buildMethodParamsSignature(op);

      if (op.description != null && op.description!.isNotEmpty) {
        buffer.writeln('  /// ${op.description}');
      }
      buffer.writeln('  Future<$returnType> $methodName($paramsSignature);');
      buffer.writeln();
    }
    buffer.writeln('}');
    buffer.writeln();

    // 2. Concrete Implementation Class
    buffer.writeln('class $implName implements $interfaceName {');
    buffer.writeln('  final NetworkClient client;');
    buffer.writeln();
    buffer.writeln('  $implName(this.client);');
    buffer.writeln();

    for (final op in operations) {
      final String returnType = _buildResponseType(op);
      final String methodName =
          ModelGenerator.sanitizeIdentifier(op.operationId);
      final String paramsSignature = _buildMethodParamsSignature(op);

      buffer.writeln('  @override');
      buffer.writeln(
          '  Future<$returnType> $methodName($paramsSignature) async {');

      // Build path with path parameter interpolation
      String pathExpr = "'${op.path}'";
      for (final p in op.parameters.where((param) => param.inType == 'path')) {
        final String pName = ModelGenerator.sanitizeIdentifier(p.name);
        pathExpr = pathExpr.replaceAll('{${p.name}}', '\$$pName');
      }

      // Query params map
      final List<ApiParameterSpec> queryParams =
          op.parameters.where((p) => p.inType == 'query').toList();

      final String methodLower = op.method.toLowerCase();
      final String respDataType = op.isResponseList
          ? 'List<dynamic>'
          : (op.responseBodyModel != null ? 'Map<String, dynamic>' : 'dynamic');

      buffer.writeln(
          '    final response = await client.$methodLower<$respDataType>(');
      buffer.writeln('      $pathExpr,');

      if (op.requestBodyModel != null) {
        buffer.writeln('      data: body?.toJson(),');
      }

      if (queryParams.isNotEmpty) {
        buffer.writeln('      queryParameters: <String, dynamic>{');
        for (final q in queryParams) {
          final String qName = ModelGenerator.sanitizeIdentifier(q.name);
          buffer.writeln("        if ($qName != null) '${q.name}': $qName,");
        }
        buffer.writeln('      },');
      }

      buffer.writeln('      cancelToken: cancelToken,');
      buffer.writeln('    );');
      buffer.writeln();

      // Response mapping
      if (op.responseBodyModel != null) {
        final String modelName = op.responseBodyModel!;
        if (op.isResponseList) {
          buffer.writeln(
              '    final List<$modelName>? mappedData = response.data');
          buffer.writeln(
              '        ?.map((e) => $modelName.fromJson(e as Map<String, dynamic>))');
          buffer.writeln('        .toList();');
          buffer.writeln(
              '    return response.copyWith<List<$modelName>>(data: mappedData);');
        } else {
          buffer.writeln(
              '    final $modelName? mappedData = response.data != null');
          buffer.writeln(
              '        ? $modelName.fromJson(response.data as Map<String, dynamic>)');
          buffer.writeln('        : null;');
          buffer.writeln(
              '    return response.copyWith<$modelName>(data: mappedData);');
        }
      } else {
        buffer.writeln('    return response;');
      }

      buffer.writeln('  }');
      buffer.writeln();
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  String _buildResponseType(ApiOperationSpec op) {
    if (op.responseBodyModel != null) {
      if (op.isResponseList) {
        return 'NetworkResponse<List<${op.responseBodyModel}>>';
      }
      return 'NetworkResponse<${op.responseBodyModel}>';
    }
    return 'NetworkResponse<dynamic>';
  }

  String _buildMethodParamsSignature(ApiOperationSpec op) {
    final List<String> paramParts = <String>[];

    // Path parameters (required)
    for (final p in op.parameters.where((param) => param.inType == 'path')) {
      final String safeName = ModelGenerator.sanitizeIdentifier(p.name);
      paramParts.add('required ${p.type} $safeName');
    }

    // Optional params (query params, body, cancelToken)
    final List<String> namedParts = <String>[];
    if (op.requestBodyModel != null) {
      namedParts.add('${op.requestBodyModel}? body');
    }
    for (final p in op.parameters.where((param) => param.inType == 'query')) {
      final String safeName = ModelGenerator.sanitizeIdentifier(p.name);
      namedParts.add('${p.type}? $safeName');
    }
    namedParts.add('CancelToken? cancelToken');

    if (namedParts.isNotEmpty) {
      paramParts.add('{${namedParts.join(', ')}}');
    }

    return paramParts.join(', ');
  }
}
