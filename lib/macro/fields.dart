import 'package:macros/macros.dart';
import 'package:flutter_voronezh_macros/macro/_helpers.dart';


macro class Fields implements ClassDeclarationsMacro {
  final String target;

  const Fields(this.target);

  @override
  Future<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder,) async{
    final target = await builder.resolveIdentifier(clazz.library.uri, this.target);
    final targetType = await builder.typeDeclarationOf(target);

    if (targetType is! ClassDeclaration){
      builder.report(
        Diagnostic(
          DiagnosticMessage(
            '${targetType.identifier.name} is not class',
             target: clazz.asDiagnosticTarget
            ),
            Severity.error
        ),
      );

      return;
    }

    final targetFields = await builder.allFieldsOf(targetType);

    if (targetFields.isEmpty) {
      builder.report(
        Diagnostic(
          DiagnosticMessage(
            '${targetType.identifier.name} does not have any fields',
             target: clazz.asDiagnosticTarget
            ),
            Severity.error
        ),
      );

      return null;
    }

    if (targetFields.any((f) => f.type is! NamedTypeAnnotation)) {
      builder.report(
        Diagnostic(
          DiagnosticMessage(
            '${targetType.identifier.name} has a field that is not explicit type',
             target: clazz.asDiagnosticTarget
            ),
            Severity.error
        ),
      );
    }

    final overrideAnnotation = NamedTypeAnnotationCode(
      name: await builder.resolveIdentifier(dartCore, 'override')
    );

    final declaration = DeclarationCode.fromParts([
      for (final field in targetFields) ...[
        '\n',
        ' @',
        overrideAnnotation.code,
        '\n',
        ' final ',
        field.type.code,
        ' ${field.identifier.name};',
        '\n',
      ]
    ]);

    return builder.declareInType(declaration);
  }
}
