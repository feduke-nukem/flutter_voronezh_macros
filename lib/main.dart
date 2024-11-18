import 'package:flutter/material.dart';
import 'package:flutter_voronezh_macros/macro/constructable.dart';
import 'package:flutter_voronezh_macros/macro/dispose.dart';
import 'package:flutter_voronezh_macros/macro/inherited.dart';
import 'package:flutter_voronezh_macros/macro/ordering.dart';
import 'package:flutter_voronezh_macros/macro/value.dart';
import 'package:flutter_voronezh_macros/rick_and_morty_api.dart';

// https://github.com/dart-lang/language/issues/3728
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // https://github.com/dart-lang/sdk/issues/44748
  // @Notifiable()
  // int _counter = 0;

  // https://github.com/dart-lang/sdk/issues/44748
  // @Reactive()
  // CharactersState _charactersState = const CharactersLoading();

  final _api = RickAndMortyApi();

  Future<void> _incrementCounter() async {
    try {
      // _charactersState = const CharactersLoading();
      await Future.delayed(const Duration(seconds: 3));
      final result = await _api.getCharacters();
      // _charactersState = CharactersLoaded(characters: result.results);
      print(result);
    } on Object catch (e, stackTrace) {
      // _charactersState = const CharactersError();
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            // SomeInherited(
            //   number: 1,
            //   text: '',
            //   child: SomeWidget(
            //     context,
            //     text: '_counter',
            //   ),
            // ),
            // ValueListenableBuilder(
            //   valueListenable: _counterListenable,
            //   builder: (context, value, _) => Text(
            //     '$value',
            //     style: Theme.of(context).textTheme.headlineMedium,
            //   ),
            // ),
            // StreamBuilder(
            //   stream: _counterRStream,
            //   initialData: _counterR,
            //   builder: (context, snapshot) => Text(
            //     '${snapshot.data}',
            //     style: Theme.of(context).textTheme.headlineMedium,
            //   ),
            // ),
            // const SomeInherited(
            //   number: 2,
            //   text: '',
            //   child: SizedBox.shrink(),
            // )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    // _counterNotifier.dispose();
    super.dispose();
  }
}

// @Inherited()
// class SomeInherited {
//   final int number;
//   final String text;
// }

// @Stateless()
// Widget someWidget(BuildContext context, {required String text}) => Text(text);

sealed class CharactersState {
  const CharactersState();
}

class CharactersLoading extends CharactersState {
  const CharactersLoading();
}

@Value()
class CharactersLoaded extends CharactersState {
  final Iterable<Character> characters;
}

class CharactersError extends CharactersState {
  const CharactersError();
}

@FancyField()
@FancyMethod()
class FancyClass {
  @NotFancyMethod(5)
  external void notFancyMethodYet();
}

@Constructable(name: 'fromSomething')
class Fedor {
  final String name;
  final int age;
}

@DisposeMacro()
class ClassToDispose extends Dispose {}

class Dispose {
  void dispose() {}
}
