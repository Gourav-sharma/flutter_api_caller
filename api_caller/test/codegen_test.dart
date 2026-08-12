import 'package:flutter_api_caller/flutter_api_caller.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAPI Code Generation & CLI Engine', () {
    const String sampleOpenApiYaml = '''
openapi: 3.0.0
info:
  title: Product API
  version: 1.0.0
paths:
  /products/{id}:
    get:
      operationId: getProductById
      description: Get product details
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: integer
      responses:
        '200':
          description: Product object
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/Product'
components:
  schemas:
    Product:
      type: object
      required:
        - id
        - name
      properties:
        id:
          type: integer
        name:
          type: string
        price:
          type: number
          nullable: true
''';

    test('Parses OpenAPI 3.x schema and generates valid models and API clients',
        () {
      final parser = OpenApiParser();
      final spec = parser.parse(sampleOpenApiYaml);

      expect(spec.title, 'Product API');
      expect(spec.models.containsKey('Product'), isTrue);
      expect(spec.operations.length, 1);

      final modelGenerator = ModelGenerator();
      final modelCode =
          modelGenerator.generateModelCode(spec.models['Product']!);

      expect(modelCode, contains('class Product'));
      expect(modelCode, contains('factory Product.fromJson'));
      expect(modelCode, contains('Map<String, dynamic> toJson'));

      final apiGenerator = ApiGenerator();
      final apiCode = apiGenerator.generateApiCode(
        apiName: 'Product',
        operations: spec.operations,
        models: spec.models,
      );

      expect(apiCode, contains('abstract class ProductApi'));
      expect(apiCode, contains('class ProductApiImpl implements ProductApi'));
      expect(apiCode, contains('getProductById'));
    });
  });
}
