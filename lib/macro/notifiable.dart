import 'dart:async';

import 'package:macros/macros.dart';
import 'package:flutter_voronezh_macros/macro/_helpers.dart';

macro class Notifiable implements FieldDeclarationsMacro, FieldDefinitionMacro {
  const Notifiable();

  @override
  Future<void> buildDeclarationsForField(
    VariableDeclaration variable,
    MemberDeclarationBuilder builder,
  ) async {
    if (!variable.hasInitializer && !variable.type.isNullable) {
      builder.report(
        Diagnostic(
          DiagnosticMessage(
            'Variable has no initializer',
            target: variable.asDiagnosticTarget,
          ),
          Severity.error,
        ),
      );

      return;
    }
    final name = variable.identifier.name;
    final valueNotifier = await builder.resolveIdentifier(
      flutterFoundation,
      'ValueNotifier',
    );
    final valueListenable = await builder.resolveIdentifier(
      flutterFoundation,
      'ValueListenable',
    );

    final notifierType = NamedTypeAnnotationCode(
      name: valueNotifier,
      typeArguments: [variable.type.code],
    );
    final listenableType = NamedTypeAnnotationCode(
      name: valueListenable,
      typeArguments: [variable.type.code],
    );

    builder.declareInType(
      DeclarationCode.fromParts(
        [
          tab,
          'late final ',
          if(!name.startsWith('_')) '_',
          '${name}Notifier',
          ' = ',
          notifierType.code,
          '($name);',
          newLine + tab,
          listenableType.code,
          ' get ${name}Listenable => ${name}Notifier;',
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
        variable.type.code,
        ' get $name => ${name}Notifier.value;',
      ]),
      setter: DeclarationCode.fromParts(
        [
          'set ${name}(',
          variable.type.code,
          ' value) => ',
          '${name}Notifier.value = value;',
        ]
      ),
    );
  }
}
