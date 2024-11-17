import 'dart:async';

import 'package:macros/macros.dart';
import 'package:flutter_voronezh_macros/macro/_helpers.dart';

macro class Stateless
    implements
        FunctionDeclarationsMacro,
        FunctionTypesMacro {

  const Stateless();

  @override
  Future<void> buildTypesForFunction(
    FunctionDeclaration function,
    TypeBuilder builder,
  ) async {
    if (!function.hasBody) {
      builder.report(
        Diagnostic(
          DiagnosticMessage(
            'Function has no body',
            target: function.asDiagnosticTarget,
          ),
          Severity.error,
        ),
      );

      return;
    }

    final returnType = function.returnType;

    if (returnType is! NamedTypeAnnotation) {
      builder.report(Diagnostic(
        DiagnosticMessage(
          'Function has no return type',
          target: function.asDiagnosticTarget,
        ),
        Severity.error,
      ));

      return;
    }

    if (returnType.identifier.name != 'Widget') {
      builder.report(Diagnostic(
        DiagnosticMessage(
          'Function has a return type that is not Widget',
          target: function.asDiagnosticTarget,
        ),
        Severity.error,
      ));

      return;
    }

    final (statelessWidget, override, widget, context) = await (
      builder.codeFrom(flutterWidgets, 'StatelessWidget'),
      builder.codeFrom(dartCore, 'override'),
      builder.codeFrom(flutterWidgets, 'Widget'),
      builder.codeFrom(flutterWidgets, 'BuildContext'),
    ).wait;

    final name = function.identifier.name.capitalize();
    final allParams = [
      ...function.positionalParameters,
      ...function.namedParameters
    ];
    builder.declareType(
      name,
      DeclarationCode.fromParts([
        'class $name extends ',
        statelessWidget.code,
        ' {',
        newLine + tab,
        for (final p in allParams) ...[
          'final ',
          // https://github.com/dart-lang/sdk/issues/56560
          //p.type.code
          p.identifier.name,
          ';',
          if (p != allParams.last) newLine + tab,
        ],
        newLine * 2 + tab,
        'const $name(',
        for (final p in function.positionalParameters) ...[
          newLine + tab * 2,
          'this.',
          p.identifier.name,
          ', ',
        ],
        if (function.namedParameters.isNotEmpty) ...[
          '{',
          for (final p in function.namedParameters) ...[
            newLine + tab * 2,
            if (p.isRequired) 'required ',
            'this.',
            p.identifier.name,
            ',',
          ],
          newLine + tab,
          '}',
        ],
        ');',
        newLine * 2 + tab,
        '@',
        override.code,
        newLine + tab,
        widget.code,
        ' build(',
        context.code,
        ' context) => ',
        newLine + tab * 2,
        FunctionBodyCode.fromParts([
          '${function.identifier.name}(',
          newLine + tab * 3,
          for (final p in function.positionalParameters) ...[
            p.identifier.name,
            ',',
            if (p != allParams.last) newLine + tab * 3,
          ],
          for (final p in function.namedParameters) ...[
            p.identifier.name,
            ': ',
            p.identifier.name,
            ',',
            if (p != allParams.last) newLine + tab * 3,
          ],
          newLine + tab * 2,
          ');'
        ]),
        newLine,
        '}',
      ]),
    );
  }

  @override
  Future<void> buildDeclarationsForFunction(
    FunctionDeclaration function,
    DeclarationBuilder builder,
  ) async {
    if (!function.hasBody) {
      builder.report(
        Diagnostic(
          DiagnosticMessage(
            'Function has no body',
            target: function.asDiagnosticTarget,
          ),
          Severity.error,
        ),
      );

      return;
    }

    if (function.returnType.isNullable) {
      builder.report(
        Diagnostic(
          DiagnosticMessage(
            'Function has a nullable return type',
            target: function.asDiagnosticTarget,
          ),
          Severity.error,
        ),
      );

      return;
    }
  }

}
