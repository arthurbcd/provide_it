import 'package:flutter/material.dart';
import 'package:provide_it/provide_it.dart';
// import 'package:provide_it/provide_it.dart';

void main() {
  runApp(
    ProvideIt(
      // provide: (context) async {
      //   await Future.delayed(Duration(seconds: 3));

      //   context.provide(Counter.futureCounter);
      //   print('Init');
      // },
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: CounterProvider(),
          ),
        ),
      ),
    ),
  );
}

class Counter extends ChangeNotifier {
  Counter();

  static Future<Counter> futureCounter() async {
    await Future.delayed(Duration(seconds: 3));
    return Counter();
  }

  static Stream<Counter> streamCounter() async* {
    for (var i = 0; i < 10; i++) {
      await Future.delayed(Duration(seconds: 1));
      yield Counter();
    }
  }

  int count = 0;

  void increment() {
    count++;
    notifyListeners();
  }
}

Stream<int> streamCounter() async* {
  for (var i = 0; i < 10; i++) {
    await Future.delayed(Duration(seconds: 1));
    yield i;
  }
}

final countRef = ValueRef<int>(0);

class CounterProvider extends StatelessWidget {
  const CounterProvider({super.key});

  @override
  Widget build(BuildContext context) {
    // Injector;
    context.value(10);
    context.provideLazy(Counter.new);
    context.provide(streamCounter, key: 'streamCounter');

    context.watch<int?>(key: 'streamCounter');

    final (count, setCount) = context.value(0);

    context.listenSelect((int count) => count, (previous, next) {
      print('Count1: $previous -> $next');
    }, key: 'streamCounter');

    context.listenSelect((int count) => count, (previous, next) {
      print('Count2: $previous -> $next');
    }, key: 'streamCounter');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Reloader(),
        ElevatedButton(
          onPressed: () {
            setCount(count + 1);

            showDialog(
              context: context,
              builder: (context) {
                final count = context.watch<Counter>();

                return AlertDialog(
                  title: Text('Text: ${count.count}'),
                  actions: [
                    ElevatedButton(
                      onPressed: () => context.read<Counter>().increment(),
                      child: Text('Increment'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close'),
                    ),
                  ],
                );
              },
            );
          },
          child: Text('Opened: $count'),
        ),
      ],
    );
  }
}

class Reloader extends StatelessWidget {
  const Reloader({super.key});

  @override
  Widget build(BuildContext context) {
    final snapshot = context.future(Counter.futureCounter, key: 'counter');

    return ElevatedButton(
      onPressed: () => context.reload(key: 'counter'),
      child: Text('Reload: ${snapshot.connectionState}'),
    );
  }
}

class CounterValue extends StatelessWidget {
  const CounterValue({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = context.value(0);

    return ElevatedButton(
      onPressed: () => counter.value++,
      child: Text('Counter: ${counter.value}'),
    );
  }
}
