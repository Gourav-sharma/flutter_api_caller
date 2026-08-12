import 'openapi_parser.dart';

/// Dart model source code generator from OpenAPI schemas.
class ModelGenerator {
  static const Set<String> _reservedWords = <String>{
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'function',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'new',
    'null',
    'on',
    'operator',
    'part',
    'required',
    'rethrow',
    'return',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'typedef',
    'var',
    'void',
    'while',
    'with',
    'yield',
  };

  /// Sanitizes property name to prevent Dart reserved word collision.
  static String sanitizeIdentifier(String name) {
    if (_reservedWords.contains(name.toLowerCase())) {
      return '${name}Value';
    }
    final String clean = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return clean;
  }

  /// Generates full Dart source code string for a given model schema.
  String generateModelCode(ModelSchemaSpec schema) {
    final StringBuffer buffer = StringBuffer();

    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln();

    if (schema.description != null && schema.description!.isNotEmpty) {
      buffer.writeln('/// ${schema.description}');
    }
    buffer.writeln('class ${schema.name} {');

    // Field definitions
    schema.properties.forEach((propName, propSpec) {
      final String safeName = sanitizeIdentifier(propName);
      final String nullabilityStr = propSpec.isNullable ? '?' : '';
      buffer.writeln('  final ${propSpec.dartType}$nullabilityStr $safeName;');
    });
    buffer.writeln();

    // Constructor
    buffer.writeln('  const ${schema.name}({');
    schema.properties.forEach((propName, propSpec) {
      final String safeName = sanitizeIdentifier(propName);
      final String reqStr = propSpec.isNullable ? '' : 'required ';
      buffer.writeln('    ${reqStr}this.$safeName,');
    });
    buffer.writeln('  });');
    buffer.writeln();

    // fromJson
    buffer.writeln(
        '  factory ${schema.name}.fromJson(Map<String, dynamic> json) {');
    buffer.writeln('    return ${schema.name}(');
    schema.properties.forEach((propName, propSpec) {
      final String safeName = sanitizeIdentifier(propName);
      buffer.writeln(
          '      $safeName: ${_buildFromJsonExpr(propName, propSpec)},');
    });
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // toJson
    buffer.writeln('  Map<String, dynamic> toJson() {');
    buffer.writeln('    return <String, dynamic>{');
    schema.properties.forEach((propName, propSpec) {
      final String safeName = sanitizeIdentifier(propName);
      buffer.writeln(
          "      '$propName': ${_buildToJsonExpr(safeName, propSpec)},");
    });
    buffer.writeln('    };');
    buffer.writeln('  }');

    buffer.writeln('}');

    return buffer.toString();
  }

  String _buildFromJsonExpr(String key, SchemaPropertySpec spec) {
    final String jsonAccess = "json['$key']";
    if (spec.isList && spec.itemType != null) {
      final String itemType = spec.itemType!;
      final bool isPrimitive = <String>[
        'int',
        'double',
        'bool',
        'String',
        'dynamic'
      ].contains(itemType);
      if (isPrimitive) {
        return '($jsonAccess as List?)?.map((e) => e as $itemType).toList()';
      } else {
        return '($jsonAccess as List?)?.map((e) => $itemType.fromJson(e as Map<String, dynamic>)).toList()';
      }
    }

    final bool isPrimitive = <String>[
      'int',
      'double',
      'bool',
      'String',
      'dynamic'
    ].contains(spec.dartType);
    if (isPrimitive) {
      return '$jsonAccess as ${spec.dartType}?';
    } else {
      return '$jsonAccess != null ? ${spec.dartType}.fromJson($jsonAccess as Map<String, dynamic>) : null';
    }
  }

  String _buildToJsonExpr(String fieldName, SchemaPropertySpec spec) {
    if (spec.isList && spec.itemType != null) {
      final String itemType = spec.itemType!;
      final bool isPrimitive = <String>[
        'int',
        'double',
        'bool',
        'String',
        'dynamic'
      ].contains(itemType);
      if (isPrimitive) {
        return fieldName;
      } else {
        return '$fieldName?.map((e) => e.toJson()).toList()';
      }
    }

    final bool isPrimitive = <String>[
      'int',
      'double',
      'bool',
      'String',
      'dynamic'
    ].contains(spec.dartType);
    if (isPrimitive) {
      return fieldName;
    } else {
      return '$fieldName?.toJson()';
    }
  }
}
