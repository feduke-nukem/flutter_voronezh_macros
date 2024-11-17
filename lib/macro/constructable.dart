import 'dart:async';

import 'package:macros/macros.dart';
import 'package:flutter_voronezh_macros/macro/_helpers.dart';


// Implementing constructor for a target class.
macro class Constructable implements ClassDeclarationsMacro {
  // Optional name of the constructor class.
  final String? name;

  const Constructable({
    this.name,
  });

  @override
  Future<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) async {
    // Getting fields of the target class.
    final fields = await builder.fieldsOf(clazz);
    // Getting superclass of the target class if exists.
    final superclass = await builder.map((b) => b.superclassOf(clazz));

    // Defining super constructor parameters.
    final ConstructorParams superParams = (positional: [], named: []);

    // If superclass exists, getting its default constructor and its parameters.
    if (superclass != null) {
      // Get default constructor of the superclass.
      final superCtor = await builder.defaultConstructor(superclass);
      // Get parameters of the superclass.
      final superCtorParams =
          await builder.constructorParamsOf(superCtor!, superclass);

      // Fill super constructor parameters.
      superParams.positional.addAll(superCtorParams.positional);
      superParams.named.addAll(superCtorParams.named);
    }

    // Checking if the target class already has same named constructor.
    if(name != null) {
      final ctors = await builder.constructorsOf(clazz);

      if (ctors.any((c) => c.identifier.name == name)) {
        builder.report(
          Diagnostic(
            DiagnosticMessage(
                '${clazz.identifier.name} already has a constructor named $name',
                target: clazz.asDiagnosticTarget),
            Severity.error,
          ),
        );

        return;
      }
    }

    final defaultCtor = await builder.defaultConstructor(clazz);
      
    // Report error if the target class already has a default constructor.
    if (defaultCtor != null) {
      builder.report(
        Diagnostic(
          DiagnosticMessage(
              '${clazz.identifier.name} already has a default constructor',
              target: clazz.asDiagnosticTarget),
          Severity.error,
        ),
      );

      return;
    }
   

    // Checking if the target class has any fields.
    if (fields.isEmpty &&
        superParams.positional.isEmpty &&
        superParams.named.isEmpty) {
      // Report error if the target class has no fields.
      builder.report(
        Diagnostic(
          DiagnosticMessage('${clazz.identifier.name} does not have any fields',
              target: clazz.asDiagnosticTarget),
          Severity.error,
        ),
      );

      return;
    }

    // Declaring constructor.
    builder.declareInType(
      DeclarationCode.fromParts(
        [
          RawCode.fromParts([
            tab,
            // If every field is final, declare const constructor.
            if(fields.every((f)=>f.hasFinal))
            'const ',
            clazz.identifier.name,
            if(name != null) '.${name!}',
            // Declaring arguments.
            '({',
            newLine,
            // Initializing class fields.
            for (final f in fields) ...[
              tab * 2,
              // Handling required fields.
              if (!f.type.isNullable) 'required ',
              'this.',
              f.identifier.name,
              ',',
              newLine,
            ],
            // Initializing super class fields.
            for (final p in superParams.named) ...[
              tab * 2,
              if (p.isRequired) 'required ',
              // We can use "code" field from TypeAnnotation to insert correct type
              // with library prefix.
              p.type!.code,
              ' ',
              p.name,
              ',',
              newLine,
            ],
            tab,
            '})',
            // Providing super constructor parameters.
            if(superParams.named.isNotEmpty || superParams.positional.isNotEmpty)...[
            ' : super(',
            for (final param in superParams.positional) ...[param.name, ','],
            for (final param in superParams.named) ...[
              param.name,
              ': ',
              param.name,
              ','
            ],
            ')',
            ],
            ';',
          ]),
        ],
      ),
    );
  }
}
