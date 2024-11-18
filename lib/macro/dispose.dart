import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_voronezh_macros/macro/_helpers.dart';
import 'package:macros/macros.dart';

macro class DisposeMacro implements ClassDeclarationsMacro {
  const DisposeMacro();

  @override
  FutureOr<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) async {
    final superClass = await builder.superclassOf(clazz);
    final methods = superClass == null ? const <MethodDeclaration>[] : await builder.methodsOf(superClass);
    final dispose = methods.firstWhereOrNull(
      (m) => m.identifier.name == 'dispose',
    );
    final override = await builder.codeFrom(dartCore, 'override');

    builder.declareInType(
      DeclarationCode.fromParts([
        if(dispose != null)
        ...[
          newLine,
          '@',
          override.code,
          newLine,
        ],
        'void dispose() {',
        newLine + tab,
        'final a = 1; // some code',
        newLine + tab,
        'super.dispose();',
        newLine,
        '}',
      ]),
    );
  }
}
