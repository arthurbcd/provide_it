// ignore_for_file: unused_local_variable, avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provide_it/provide_it.dart';

void main() {
  runApp(
    // You must set ProvideIt in the root of your app for any provider (hook/inherited) to work.
    ProvideIt(
      provide: (context) {
        // provide async dependencies
        context.provideAsync<CounterService>(() async {
          await Future.delayed(Duration(seconds: 3));
          return MyCounterService();
        });

        // Zero boilerplate injection
        context.provideAuto(CounterRepository.new);
        context.provideAuto(Counter.new); // <- auto-injects CounterRepository
      },
      // show something while loading async dependencies, defaults to black screen
      loadingBuilder: (context) {
        return Center(child: Text('loading'));
      },
      // by default auto-notify/dispose listenable/notifier inherited providers
      watchers: [const ListenableWatcher()], // empty disables
      child: WidgetsApp(
        color: Color(0xFF7B0328),
        builder: (context, child) => Home(),
      ),
    ),
  );
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    // read you inherited Counter with read, watch or select
    final counter = context.watch<Counter>();
    final count = context.select((Counter c) => c.count);

    // side-effect with listen or listenSelected
    context.listen<Counter>((counter) {
      print('Counter updated: ${counter.count}');
    });
    context.listenSelected((Counter it) => it.count, (prev, next) {
      print('count changed: $prev -> $next');
    });

    return GestureDetector(
      // you can also read singletons contextlessly with [readIt]. fails on duplicates.
      onTap: () => readIt<Counter>().increment(),
      child: Text('Count: $count'),
    );
  }
}

/// you can also use [HookProvider]'s for local state, they can't be read elsewhere!
class HookExample extends StatelessWidget {
  const HookExample({super.key});

  @override
  Widget build(BuildContext context) {
    final (count, setCount) = context.useValue(0);

    return GestureDetector(
      onTap: () => setCount(count + 1),
      child: Text('Count: $count'),
    );
  }
}

class CombinedExample extends StatelessWidget {
  const CombinedExample({super.key});

  @override
  Widget build(BuildContext context) {
    // handle async state locally with useFuture/useStream or useFutureValue/useStreamValue.
    final snapshot = context.useFuture(() async => 'Hello World!');

    // optionally provide for descendants without needing a provider class
    context.provideValue(snapshot.data);

    return switch (snapshot) {
      AsyncSnapshot(:final data?) => Text('data: $data'),
      AsyncSnapshot(:final error?) => Text('error: $error'),
      _ => Text('loading'),
    };
  }
}

// create your own reusable providers through context extension!
extension CustomProviders on BuildContext {
  AsyncSnapshot<T> provideFuture<T>(Future<T> Function() future) {
    final snapshot = useFuture(() => future());
    provideValue(snapshot.data);
    return snapshot;
  }
}

class MyCounterService extends CounterService {}

class CounterService {}

class CounterRepository {
  CounterRepository(this.service);
  final CounterService service;
}

class Counter extends ChangeNotifier {
  Counter({required this.repository, required this.counterId});
  final CounterRepository repository;
  final String counterId;

  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}

class CounterExample extends StatelessWidget {
  const CounterExample({super.key});

  @override
  Widget build(BuildContext context) {
    final (count, setCount) = context.useValue(0);
    return GestureDetector(
      onTap: () => setCount(count + 1),
      child: Text('Count: $count'),
    );
  }
}
