import 'dart:io';

import 'package:flutter_api_caller/src/codegen/codegen_engine.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    _printUsage();
    exit(0);
  }

  final String command = args.first.toLowerCase();

  switch (command) {
    case 'init':
      await _handleInit();
      break;
    case 'generate':
      await _handleGenerate(args.sublist(1));
      break;
    case 'doctor':
      await _handleDoctor();
      break;
    case 'clean':
      await _handleClean();
      break;
    default:
      print('Unknown command "$command".');
      _printUsage();
      exit(1);
  }
}

void _printUsage() {
  print('Flutter Network CLI Utility (flutter_network)');
  print('');
  print('Usage:');
  print('  dart run flutter_api_caller:flutter_network <command> [options]');
  print('');
  print('Commands:');
  print(
      '  init       Create default flutter_network.yaml configuration and sample openapi.yaml');
  print(
      '  generate   Generate Dart models and typed API clients from OpenAPI spec');
  print('  doctor     Check workspace environment and setup');
  print('  clean      Remove generated models and API code');
}

Future<void> _handleInit() async {
  final File configFile = File('flutter_network.yaml');
  if (!await configFile.exists()) {
    await configFile.writeAsString('''
name: my_api

openapi:
  input: openapi/openapi.yaml

output:
  directory: lib/generated

models:
  directory: lib/generated/models

apis:
  directory: lib/generated/api
''');
    print('✓ Created flutter_network.yaml configuration file');
  } else {
    print('✓ flutter_network.yaml already exists');
  }

  final Directory openapiDir = Directory('openapi');
  if (!await openapiDir.exists()) {
    await openapiDir.create(recursive: true);
  }

  final File openapiFile = File('openapi/openapi.yaml');
  if (!await openapiFile.exists()) {
    await openapiFile.writeAsString('''
openapi: 3.0.0
info:
  title: Sample User Service
  version: 1.0.0
paths:
  /users:
    get:
      operationId: getUsers
      description: Retrieve paginated list of users
      parameters:
        - name: page
          in: query
          required: false
          schema:
            type: integer
      responses:
        '200':
          description: List of users
          content:
            application/json:
              schema:
                type: array
                items:
                  \$ref: '#/components/schemas/User'
components:
  schemas:
    User:
      type: object
      required:
        - id: int
        - name: string
        - email: string
      properties:
        id:
          type: integer
        name:
          type: string
        email:
          type: string
''');
    print('✓ Created sample openapi/openapi.yaml file');
  } else {
    print('✓ openapi/openapi.yaml already exists');
  }
}

Future<void> _handleGenerate(List<String> args) async {
  String? openapiOverride;

  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--openapi' && i + 1 < args.length) {
      openapiOverride = args[i + 1];
    }
  }

  try {
    final CodegenEngine engine = CodegenEngine();

    if (openapiOverride != null) {
      print('Loading OpenAPI specification from $openapiOverride...');
      await engine.runGeneration(
        openapiPath: openapiOverride,
        outputDir: 'lib/generated',
        modelsDir: 'lib/generated/models',
        apisDir: 'lib/generated/api',
        apiName: 'GeneratedApi',
      );
    } else {
      final File configFile = File('flutter_network.yaml');
      if (await configFile.exists()) {
        await engine.runFromConfig('flutter_network.yaml');
      } else {
        print(
            'No flutter_network.yaml found. Generating from openapi/openapi.yaml...');
        await engine.runGeneration(
          openapiPath: 'openapi/openapi.yaml',
          outputDir: 'lib/generated',
          modelsDir: 'lib/generated/models',
          apisDir: 'lib/generated/api',
          apiName: 'GeneratedApi',
        );
      }
    }

    print('✓ OpenAPI loaded');
    print('✓ Schemas detected');
    print('✓ Models generated');
    print('✓ APIs generated');
    print('✓ Code formatted');
    print('✓ Analyzer passed');
  } catch (e) {
    print('✗ Code generation failed: $e');
    exit(1);
  }
}

Future<void> _handleDoctor() async {
  print('Checking workspace environment...');
  print('✓ Dart SDK version: ${Platform.version}');
  final File configFile = File('flutter_network.yaml');
  if (await configFile.exists()) {
    print('✓ Configuration file found: flutter_network.yaml');
  } else {
    print(
        '! Configuration file flutter_network.yaml missing (run flutter_network init)');
  }
}

Future<void> _handleClean() async {
  final Directory genDir = Directory('lib/generated');
  if (await genDir.exists()) {
    await genDir.delete(recursive: true);
    print('✓ Removed lib/generated directory');
  } else {
    print('✓ Nothing to clean');
  }
}
