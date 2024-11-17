import 'dart:async';

import 'package:macros/macros.dart';
import 'package:flutter_voronezh_macros/macro/_helpers.dart';


macro class RestApi implements ClassDeclarationsMacro {
  final String baseUrl;

  const RestApi({required this.baseUrl});

  @override
  Future<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) async {
    builder.declareInType(
      DeclarationCode.fromString('  static const baseUrl = "$baseUrl";'),
    );
  }
}

macro class Get implements MethodDefinitionMacro {
  final String path;

  const Get({required this.path});

  @override
  Future<void> buildDefinitionForMethod(
    MethodDeclaration method,
    FunctionDefinitionBuilder builder,
  ) async {
    final (httpGet, jsonDecode, string, dynamicCode, uri) = await (
      builder.codeFrom(helpers, 'httpGet'),
      builder.codeFrom(helpers, 'jsonDecodeCode'),
      builder.codeFrom(dartCore, 'String'),
      builder.codeFrom(dartCore, 'dynamic'),
      builder.codeFrom(dartCore, 'Uri'),
    ).wait;
    final returnType = method.returnType as NamedTypeAnnotation;
    final resultType = switch (returnType) {
      final NamedTypeAnnotation type when type.identifier.name == 'Future' =>
        type.typeArguments.first as NamedTypeAnnotation,
      _ => returnType
    };
    final map = await builder
        .resolveIdentifier(dartCore, 'Map')
        .then((i) => NamedTypeAnnotationCode(name: i, typeArguments: [
              string,
              dynamicCode,
            ]));

    builder.augment(
      FunctionBodyCode.fromParts(
        [
          'async {',
          newLine + tab * 2,
          'final response = await ',
          httpGet.code,
          '(',
          uri.code,
          '.parse(baseUrl + \'${path.replaceAll('{', '\${')}\'));',
          newLine + tab * 2,
          if (resultType.identifier == string.name) ...[
            'return response.body;',
          ] else ...[
            'final body = ',
            jsonDecode.code,
            '(response.body);',
            newLine + tab * 2,
            'return ',
            resultType.code,
            '.fromJson(',
            'body as ',
            map.code,
            ');',
          ],
          newLine + tab,
          '}'
        ],
      ),
    );
  }
}
