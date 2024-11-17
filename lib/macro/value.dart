import 'dart:async';

import 'package:flutter_voronezh_macros/macro/constructable.dart';
import 'package:flutter_voronezh_macros/macro/copyable.dart';
import 'package:flutter_voronezh_macros/macro/equatable.dart';
import 'package:macros/macros.dart';



macro class Value implements ClassDeclarationsMacro, ClassDefinitionMacro {
  const Value();

  @override
  Future<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) async {
    await const Constructable().buildDeclarationsForClass(clazz, builder);
    await const Equatable().buildDeclarationsForClass(clazz, builder);
    await const Copyable().buildDeclarationsForClass(clazz, builder);
  }

  @override
  Future<void> buildDefinitionForClass(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) async {
    await const Copyable().buildDefinitionForClass(clazz, builder);
    await const Equatable().buildDefinitionForClass(clazz, builder);
  }
}
