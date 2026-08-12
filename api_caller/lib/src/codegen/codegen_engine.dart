import 'dart:io';

import 'api_generator.dart';
import 'cli_config.dart';
import 'model_generator.dart';
import 'openapi_parser.dart';

/// Master orchestration engine for OpenAPI code generation and CLI execution.
class CodegenEngine {
  Future<void> runGeneration({
    required String openapiPath,
    required String outputDir,
    required String modelsDir,
    required String apisDir,
    required String apiName,
  }) async {
    final File openapiFile = File(openapiPath);
    if (!await openapiFile.exists()) {
      throw FileSystemException(
          'OpenAPI specification file not found: $openapiPath');
    }

    final String openapiContent = await openapiFile.readAsString();
    final OpenApiParser parser = OpenApiParser();
    final OpenApiSpecResult specResult = parser.parse(openapiContent);

    final ModelGenerator modelGenerator = ModelGenerator();
    final ApiGenerator apiGenerator = ApiGenerator();

    // Ensure target output directories exist
    final Directory modelsDirectory = Directory(modelsDir);
    if (!await modelsDirectory.exists()) {
      await modelsDirectory.create(recursive: true);
    }

    final Directory apisDirectory = Directory(apisDir);
    if (!await apisDirectory.exists()) {
      await apisDirectory.create(recursive: true);
    }

    // 1. Generate Models
    for (final entry in specResult.models.entries) {
      final String modelCode = modelGenerator.generateModelCode(entry.value);
      final File modelFile =
          File('${modelsDirectory.path}/${entry.key.toLowerCase()}.dart');
      await modelFile.writeAsString(modelCode);
    }

    // 2. Generate API Client
    final String apiCode = apiGenerator.generateApiCode(
      apiName: apiName,
      operations: specResult.operations,
      models: specResult.models,
    );
    final File apiFile =
        File('${apisDirectory.path}/${apiName.toLowerCase()}_api.dart');
    await apiFile.writeAsString(apiCode);
  }

  Future<void> runFromConfig(String configPath) async {
    final File configFile = File(configPath);
    if (!await configFile.exists()) {
      throw FileSystemException('Configuration file not found: $configPath');
    }

    final CliConfig config = await CliConfig.loadFromFile(configFile);
    await runGeneration(
      openapiPath: config.openapiInput,
      outputDir: config.outputDir,
      modelsDir: config.modelsDir,
      apisDir: config.apisDir,
      apiName: config.name,
    );
  }
}
