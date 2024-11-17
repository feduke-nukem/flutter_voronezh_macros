import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:macros/macros.dart';

final dartCore = Uri.parse('dart:core');
final dartAsync = Uri.parse('dart:async');
final helpers =
    Uri.parse('package:flutter_voronezh_macros/macro/_helpers.dart');
final flutterWidgets = Uri.parse('package:flutter/src/widgets/framework.dart');
final flutterFoundation = Uri.parse('package:flutter/foundation.dart');
const httpGet = get;
const httpPost = post;
const httpDelete = delete;
const httpPut = put;
const jsonEncodeCode = jsonEncode;
const jsonDecodeCode = jsonDecode;
const undefined = Object();
final deepEquals = const DeepCollectionEquality().equals;
final deepHash = const DeepCollectionEquality().hash;
const tab = '\t';
const newLine = '\n';

typedef FieldMetadata = ({String name, bool isRequired, TypeAnnotation? type});
typedef ConstructorParams = ({
  List<FieldMetadata> positional,
  List<FieldMetadata> named,
});

extension DeclarationPhaseIntrospectorX on DeclarationPhaseIntrospector {
  Future<ConstructorDeclaration?> defaultConstructor(
    ClassDeclaration clazz,
  ) async {
    return (await constructorsOf(clazz))
        .firstWhereOrNull((c) => c.identifier.name.isEmpty);
  }

  Future<List<FieldDeclaration>> allFieldsOf(ClassDeclaration clazz) {
    return _allFieldsOf(clazz, fieldsOf, superclassOf);
  }

  Future<List<FieldDeclaration>> _allFieldsOf(
    ClassDeclaration clazz,
    Future<List<FieldDeclaration>> Function(ClassDeclaration clazz) fieldsOf,
    Future<ClassDeclaration?> Function(ClassDeclaration clazz) superclassOf,
  ) async {
    final allFields = <FieldDeclaration>[];
    allFields.addAll(await fieldsOf(clazz));

    var superclass = await superclassOf(clazz);
    while (superclass != null && superclass.identifier.name != 'Object') {
      allFields.addAll(await fieldsOf(superclass));
      superclass = await superclassOf(superclass);
    }

    return allFields..removeWhere((f) => f.hasStatic);
  }

  Future<ConstructorParams> constructorParamsOf(
      ConstructorDeclaration constructor, ClassDeclaration clazz) async {
    return _constructorParamsOf(constructor, clazz, resolveType);
  }

  Future<ConstructorParams> _constructorParamsOf(
    ConstructorDeclaration constructor,
    ClassDeclaration clazz,
    Future<TypeAnnotation?> Function(
      FormalParameterDeclaration declaration,
      ClassDeclaration clazz,
    ) resolveType,
  ) async {
    final (positional, named) = await (
      Future.wait([
        ...constructor.positionalParameters.map((p) {
          return resolveType(p, clazz).then((type) {
            return (
              isRequired: type?.isNullable == false ? true : p.isRequired,
              name: p.identifier.name,
              type: type,
            );
          });
        }),
      ]),
      Future.wait([
        ...constructor.namedParameters.map((p) {
          return resolveType(p, clazz).then((type) {
            return (
              isRequired: type?.isNullable == false ? true : p.isRequired,
              name: p.identifier.name,
              type: type,
            );
          });
        }),
      ]),
    ).wait;

    return (positional: positional, named: named);
  }

  Future<ClassDeclaration?> superclassOf(ClassDeclaration clazz) {
    return _superclassOf(clazz, typeDeclarationOf);
  }

  Future<ClassDeclaration?> _superclassOf(
    ClassDeclaration clazz,
    Future<TypeDeclaration> Function(Identifier identifier) typeDeclarationOf,
  ) async {
    final superclassType = clazz.superclass != null
        ? await typeDeclarationOf(clazz.superclass!.identifier)
        : null;
    return superclassType is ClassDeclaration ? superclassType : null;
  }

  Future<TypeAnnotation?> resolveType(
    FormalParameterDeclaration declaration,
    ClassDeclaration clazz,
  ) async {
    return _resolveType(
      declaration,
      clazz,
      fieldsOf,
      superclassOf,
    );
  }

  Future<TypeAnnotation?> _resolveType(
    FormalParameterDeclaration declaration,
    ClassDeclaration clazz,
    Future<List<FieldDeclaration>> Function(TypeDeclaration type) fieldsOf,
    Future<ClassDeclaration?> Function(ClassDeclaration clazz) superclassOf,
  ) async {
    final type = declaration.type;
    final name = declaration.name;

    if (type is NamedTypeAnnotation) return type;

    final fieldDeclarations = await fieldsOf(clazz);
    final field = fieldDeclarations.firstWhereOrNull(
      (f) => f.identifier.name == name,
    );

    if (field != null) return field.type;

    final superclass = await superclassOf(clazz);

    if (superclass != null) {
      return _resolveType(
        declaration,
        superclass,
        fieldsOf,
        superclassOf,
      );
    }

    return null;
  }
}

extension TX<T> on T {
  R map<R>(R Function(T it) mapper) => mapper(this);
}

extension StringX on String {
  String capitalize() => this[0].toUpperCase() + substring(1);
}

extension TypePhaseIntrospectorX on TypePhaseIntrospector {
  Future<NamedTypeAnnotationCode> codeFrom(Uri library, String name) async {
    return _codeFrom(library, name, resolveIdentifier);
  }

  Future<NamedTypeAnnotationCode> _codeFrom(
    Uri library,
    String name,
    Future<Identifier> Function(Uri library, String name) resolveIdentifier,
  ) async {
    final identifier = await resolveIdentifier(library, name);
    return NamedTypeAnnotationCode(name: identifier);
  }
}
