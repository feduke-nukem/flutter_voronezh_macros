import 'dart:async';

import 'package:collection/collection.dart';
import 'package:macros/macros.dart';
import 'package:flutter_voronezh_macros/macro/_helpers.dart';


macro class Copyable implements ClassDeclarationsMacro, ClassDefinitionMacro {
  const Copyable();

  @override
  Future<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) async {
    final fields = await builder.allFieldsOf(clazz);

    if (fields.isEmpty) return;

    builder.declareInType(
      DeclarationCode.fromParts(
        [
          'external ${clazz.identifier.name} Function({',
          for (final field in fields) ...[
            field.type.code,
            ' ',
            field.identifier.name,
            ',',
          ],
          '}) get copyWith;',
        ],
      ),
    );
  }

  @override
  Future<void> buildDefinitionForClass(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) async {
    final methods = await builder.methodsOf(clazz);
    final copyWith = methods.firstWhere((m) => m.identifier.name == 'copyWith');
    final copyWithBuilder = await builder.buildMethod(copyWith.identifier);

    final defaultCtor = await builder.constructorsOf(clazz).then((ctors) =>
        ctors.firstWhereOrNull((ctor) => ctor.identifier.name.isEmpty));

    if (defaultCtor == null) {
      builder.report(
        Diagnostic(
            DiagnosticMessage(
                '${clazz.identifier.name} has no default constructor',
                target: clazz.asDiagnosticTarget),
            Severity.error),
      );

      return;
    }

    final constructorParams =
        await builder.constructorParamsOf(defaultCtor, clazz);
    final params = [
      ...constructorParams.positional,
      ...constructorParams.named,
    ];
    final (object, undefined) = await (
      builder.codeFrom(dartCore, 'Object'),
      builder.codeFrom(helpers, 'undefined'),
    ).wait;
    final body = FunctionBodyCode.fromParts(
      [
        '=> ',
        '({',
        newLine,
        for (final param in params) ...[
          tab * 2,
          object,
          '? ',
          param.name,
          ' = ',
          undefined,
          ',',
          if (param != params.last) newLine,
        ],
        newLine + tab,
        '}) { ',
        newLine + tab * 2,
        'return ',
        clazz.identifier.name,
        '(',
        newLine ,
        for (final param in params) ...[
          tab * 3,
          param.name,
          ': ',
          param.name,
          ' == ',
          undefined,
          ' ? this.',
          param.name,
          ' : ',
          param.name,
          ' as ',
          param.type!.code,
          ',',
          if (param != params.last) newLine,
        ],
        newLine + tab * 2,
        ');',
        newLine + tab,
        '};',
      ],
    );

    copyWithBuilder.augment(body);
  }
}
