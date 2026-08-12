import 'dart:io';

import 'package:yaml/yaml.dart';

/// Configuration options loaded from `flutter_network.yaml`.
class CliConfig {
  final String name;
  final String openapiInput;
  final String outputDir;
  final String modelsDir;
  final String apisDir;

  CliConfig({
    required this.name,
    required this.openapiInput,
    required this.outputDir,
    required this.modelsDir,
    required this.apisDir,
  });

  factory CliConfig.fromYamlString(String content) {
    final dynamic yaml = loadYaml(content);
    if (yaml is! Map) {
      throw const FormatException('Invalid yaml configuration file structure.');
    }

    final String name = (yaml['name'] as String?) ?? 'my_api';
    final Map<dynamic, dynamic> openapiMap =
        (yaml['openapi'] as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};
    final Map<dynamic, dynamic> outputMap =
        (yaml['output'] as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};
    final Map<dynamic, dynamic> modelsMap =
        (yaml['models'] as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};
    final Map<dynamic, dynamic> apisMap =
        (yaml['apis'] as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};

    return CliConfig(
      name: name,
      openapiInput: (openapiMap['input'] as String?) ?? 'openapi/openapi.yaml',
      outputDir: (outputMap['directory'] as String?) ?? 'lib/generated',
      modelsDir: (modelsMap['directory'] as String?) ?? 'lib/generated/models',
      apisDir: (apisMap['directory'] as String?) ?? 'lib/generated/api',
    );
  }

  static Future<CliConfig> loadFromFile(File file) async {
    final String content = await file.readAsString();
    return CliConfig.fromYamlString(content);
  }
}
