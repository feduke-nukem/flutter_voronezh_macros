import 'dart:async';

import 'package:macros/macros.dart';
import 'package:flutter_voronezh_macros/macro/_helpers.dart';


macro class Reactive implements FieldDeclarationsMacro, FieldDefinitionMacro {
  final bool isHot;

  const Reactive({
    this.isHot = true,
  });

  @override
  Future<void> buildDeclarationsForField(
    VariableDeclaration variable,
    MemberDeclarationBuilder builder,
  ) async {
    final name = variable.identifier.name;
    final streamController = await builder.resolveIdentifier(
      dartAsync,
      'StreamController',
    );
    final stream = await builder.resolveIdentifier(
      dartAsync,
      'Stream',
    );

    final streamControllerType = NamedTypeAnnotationCode(
      name: streamController,
      typeArguments: [variable.type.code],
    );
    final streamType = NamedTypeAnnotationCode(
      name: stream,
      typeArguments: [variable.type.code],
    );

    builder.declareInType(
      DeclarationCode.fromParts(
        [
          // tab,
          // 'external set $name(',
          // variable.type.code,
          // ' value);',
          // newLine + tab,
          // 'external ',
          // variable.type.code,
          // ' get $name;',
          // newLine + tab,
          tab,
          'late var _${name}Value = $name;',
          newLine + tab,
          'late final ',
          if(!name.startsWith('_')) '_',
          '${name}StreamController',
          ' = ',
          streamControllerType.code,
          if (isHot) '.broadcast',
          '()',
          if (variable.hasInitializer) '..add(${name})',
          ';',
          newLine + tab,
          streamType.code,
          ' get ${name}Stream => ${name}StreamController.stream;',
        ],
      ),
    );
  }

  @override
  Future<void> buildDefinitionForField(
    VariableDeclaration variable,
    VariableDefinitionBuilder builder,
  ) async{
    final name = variable.identifier.name;
    builder.augment(
      getter: DeclarationCode.fromParts([
        ExpressionCode.fromParts([
          variable.type.code,
          ' get $name => _${name}Value;',
        ]),
      ]),
      setter: DeclarationCode.fromParts(
        [
          ExpressionCode.fromParts([
            tab,
            'set $name(',
            variable.type.code,
            ' value) => ',
            '${name}StreamController.add(',
            '_${name}Value = value);',
          ]),
        ]
      ),
    );
  }
}
