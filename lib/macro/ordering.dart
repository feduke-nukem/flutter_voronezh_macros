import 'dart:async';

import 'package:macros/macros.dart';
import 'package:flutter_voronezh_macros/macro/_helpers.dart';

macro class FancyMethod implements ClassDeclarationsMacro, ClassDefinitionMacro {
  const FancyMethod();

  @override
  FutureOr<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) {
    builder.declareInType(
      DeclarationCode.fromParts([
        tab,
        FunctionBodyCode.fromString(' external void fancyMethod();'),
      ]),
    );
  }

  @override
  FutureOr<void> buildDefinitionForClass(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) async {
    final target = (await builder.methodsOf(clazz))
        .firstWhere((m) => m.identifier.name == 'fancyMethod')
        .identifier;
    final method = await builder.buildMethod(target);
    final fields = await builder.fieldsOf(clazz);

    if (!fields.any((f) => f.identifier.name == 'fancyField')) {
      builder.report(
        Diagnostic(
          DiagnosticMessage(
            'Class ${clazz.identifier.name} does not have a field named fancyField',
          ),
          Severity.error,
        ),
      );

      return;
    }
    method.augment(FunctionBodyCode.fromParts([
      '=> print(fancyField);',
    ]));
  }
}

macro class FancyField implements ClassDeclarationsMacro, ClassDefinitionMacro {
  const FancyField();

  @override
  FutureOr<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) {
    builder.declareInType(
      DeclarationCode.fromParts([
        tab,
        'external int fancyField;',
      ]),
    );
  }

  @override
  FutureOr<void> buildDefinitionForClass(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) async {
    final target = (await builder.fieldsOf(clazz))
        .firstWhere(
          (f) => f.identifier.name == 'fancyField',
        )
        .identifier;

    final field = await builder.buildField(target);

    field.augment(
      initializer: ExpressionCode.fromString('42'),
    );

    var type = (await builder.fieldsOf(clazz)).first.type;

    if(type is OmittedTypeAnnotation) {
      // Если смогли получить тип - то будет NamedTypeAnnotation
      // иначе - типа нет и работать с этим мы не будем
      type = await builder.inferType(type);
    }
  }
}

macro class NotFancyMethod implements MethodDefinitionMacro {
  final int value;

  const NotFancyMethod(this.value);

  @override
  FutureOr<void> buildDefinitionForMethod(
      MethodDeclaration method, FunctionDefinitionBuilder builder) async{
    // Value of the constructor parameter of metadata
    final val = method.metadata.whereType<ConstructorMetadataAnnotation>().first;

    builder.augment(FunctionBodyCode.fromParts([
      '{',
      newLine + tab * 2,
      'fancyField = ',
      val.positionalArguments.first,
      ';',
      newLine + tab * 2,
      'fancyMethod();',
      newLine + tab,
      '}'
    ]));
  }
}

