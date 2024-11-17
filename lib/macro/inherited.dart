import 'dart:async';

import 'package:flutter_voronezh_macros/macro/constructable.dart';
import 'package:macros/macros.dart';
import 'package:flutter_voronezh_macros/macro/_helpers.dart';

const _updateShouldNotify = 'updateShouldNotify';

macro class Inherited
    implements ClassDeclarationsMacro, ClassTypesMacro, ClassDefinitionMacro {
  const Inherited();

  @override
  Future<void> buildTypesForClass(
    ClassDeclaration clazz,
    ClassTypeBuilder builder,
  ) async {
    final inherited = await builder.codeFrom(
      flutterWidgets,
      'InheritedWidget',
    );
    builder.extendsType(inherited);
  }

  @override
  Future<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) async {
    final (override, boolean, buildContext) = await (
      builder.codeFrom(dartCore, 'override'),
      builder.codeFrom(dartCore, 'bool'),
      builder.codeFrom(flutterWidgets, 'BuildContext'),
    ).wait;

    await const Constructable().buildDeclarationsForClass(clazz, builder);
    builder.declareInType(
      DeclarationCode.fromParts(
        [
          newLine * 2 + tab,
          '@',
          override.code,
          newLine + tab,
          'external ',
          boolean.code,
          ' $_updateShouldNotify(',
          clazz.identifier,
          ' oldWidget);',
          newLine * 2,
          ExpressionCode.fromParts([
            tab,
            'external static ',
            clazz.identifier,
            ' of(',
            buildContext.code,
            ' context, ',
            '{',
            boolean.code.asNullable,
            ' listen});',
            newLine * 2,
            tab,
            'external static ',
            clazz.identifier,
            '? maybeOf(',
            buildContext.code,
            ' context, ',
            '{',
            boolean.code.asNullable,
            ' listen});',
          ]),
          newLine,
        ],
      ),
    );
  }

  @override
  Future<void> buildDefinitionForClass(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) async {
    final fields = await builder.fieldsOf(clazz);

    final updateShouldNotify = (await builder.methodsOf(clazz))
        .firstWhere((m) => m.identifier.name == _updateShouldNotify);
    final updateShouldNotifyBuilder =
        await builder.buildMethod(updateShouldNotify.identifier);

    // We can use fields, methods from our library
    final deepEquals = await builder.codeFrom(helpers, 'deepEquals');
    updateShouldNotifyBuilder.augment(FunctionBodyCode.fromParts([
      ExpressionCode.fromParts([
        '=> ',
        newLine + tab * 2,
        if (fields.isEmpty)
          'false'
        else
          for (final field in fields) ...[
            deepEquals,
            '('
                'oldWidget.',
            field.identifier.name,
            ', ',
            'this.',
            field.identifier.name,
            ')',
            if (field != fields.last) ' || ',
          ],
      ]),
      ';'
    ]));

    final of = (await builder.methodsOf(clazz))
        .firstWhere((m) => m.identifier.name == 'of');
    final ofBuilder = await builder.buildMethod(of.identifier);
    final maybeOf = (await builder.methodsOf(clazz))
        .firstWhere((m) => m.identifier.name == 'maybeOf');
    final maybeOfBuilder = await builder.buildMethod(maybeOf.identifier);

    maybeOfBuilder.augment(FunctionBodyCode.fromParts([
      '=> ',
      newLine,
      tab * 2,
      '(listen ?? true) ? ',
      newLine + tab * 2,
      ' context.dependOnInheritedWidgetOfExactType<',
      clazz.identifier,
      '>() : ',
      newLine + tab * 2,
      ' context.getInheritedWidgetOfExactType<',
      clazz.identifier,
      '>()',
      ';',
    ]));
    ofBuilder.augment(FunctionBodyCode.fromParts([
      '=> ',
      newLine + tab * 2,
      'maybeOf(context, listen: listen)!;',
    ]));
  }
}
