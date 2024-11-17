import 'package:collection/collection.dart';
import 'package:macros/macros.dart';
import 'package:flutter_voronezh_macros/macro/_helpers.dart';



macro class Equatable implements ClassDeclarationsMacro, ClassDefinitionMacro {
  /// {@macro equatable}
  const Equatable();

  @override
  Future<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  )  {
    return [
      _declareEquals(clazz, builder),
      _declareHashCode(clazz, builder),
    ].wait;
  }

  @override
  Future<void> buildDefinitionForClass(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) {
    return [
      _buildEquals(clazz, builder),
      _buildHashCode(clazz, builder),
    ].wait;
  }

  Future<void> _declareEquals(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) async {
    final (object, boolean) = await (
      builder.codeFrom(dartCore, 'Object'),
      builder.codeFrom(dartCore, 'bool'),      
    ).wait;
    return builder.declareInType(
      DeclarationCode.fromParts(
        ['external ', boolean, ' operator==(', object, ' other);'],
      ),
    );
  }

  Future<void> _declareHashCode(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) async {
    final integer = await builder.codeFrom(dartCore, 'int');
    return builder.declareInType(
      DeclarationCode.fromParts(['external ', integer, ' get hashCode;']),
    );
  }

  Future<void> _buildEquals(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) async {
    final methods = await builder.methodsOf(clazz);
    final equality = methods.firstWhereOrNull(
      (m) => m.identifier.name == '==',
    );
    if (equality == null) return;
    
    final (equalsMethod, deepEquals, identical, fields) = await (
      builder.buildMethod(equality.identifier),
      builder.codeFrom(helpers, 'deepEquals'),
      builder.codeFrom(dartCore, 'identical'),
      builder.allFieldsOf(clazz),
    ).wait;

    if (fields.isEmpty) {
      return equalsMethod.augment(
        FunctionBodyCode.fromParts(
          [
            '{',
            'if (', identical,' (this, other)',')', 'return true;',
            'return other is ${clazz.identifier.name} && ',
            'other.runtimeType == runtimeType;',
            '}',
          ],
        ),      
      );
    }

    final fieldNames = fields.map((f) => f.identifier.name);
    final lastField = fieldNames.last;
    return equalsMethod.augment(
      FunctionBodyCode.fromParts(
        [
          '{',
          'if (', identical,' (this, other)',')', 'return true;',
          'return other is ${clazz.identifier.name} && ',
          'other.runtimeType == runtimeType && ',
          for (final field in fieldNames)
            ...[deepEquals, '(${field}, other.$field)', if (field != lastField) ' && '],
          ';',
          '}',
        ],
      ),      
    );
  }

  Future<void> _buildHashCode(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) async {
    final methods = await builder.methodsOf(clazz);
    final hashCode = methods.firstWhereOrNull(
      (m) => m.identifier.name == 'hashCode',
    );
    if (hashCode == null) return;

    final (hashCodeMethod, deepHash, fields) = await (
      builder.buildMethod(hashCode.identifier),
      builder.codeFrom(helpers, 'deepHash'),
      builder.allFieldsOf(clazz),
    ).wait;

    final fieldNames = fields.map((f) => f.identifier.name);

    return hashCodeMethod.augment(
      FunctionBodyCode.fromParts(
        [
          '=> ',
          for (final field in fieldNames)
            ...[deepHash, '(${field})', if (field != fieldNames.last) ' ^ '],
          ';',
        ],
      ),
    );
  }
}
