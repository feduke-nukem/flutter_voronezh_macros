import 'package:flutter_voronezh_macros/macro/rest_api.dart';
import 'package:flutter_voronezh_macros/macro/value.dart';
import 'package:json/json.dart';

@RestApi(baseUrl: 'https://rickandmortyapi.com/api')
class RickAndMortyApi {
  @Get(path: '/character')
  external Future<CharactersPage> getCharacters();

  @Get(path: '/character/{id}')
  external Future<Character> getCharacter(String id);
}

@Value()
@JsonCodable()
class CharactersPage {
  final CharactersPageInfo info;
  final List<Character> results;
}

@Value()
@JsonCodable()
class CharactersPageInfo {
  final int count;
  final int pages;
  final String? next;
  final String? prev;
}

@Value()
@JsonCodable()
class Character {
  final int id;
  final String name;
  final String status;
  final String species;
  final String type;
  final String gender;
  final Origin origin;
  final Location location;
  final String image;
  final List<String> episode;
  final String url;
  final String created;
}

@JsonCodable()
@Value()
class Origin {
  final String name;
  final String url;
}

@Value()
@JsonCodable()
class Location {
  final String name;
  final String url;
}
