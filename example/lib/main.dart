import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provide_it/provide_it.dart';

void main() {
  runApp(
    ProvideIt.root(
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
  var _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}

class CounterProvider extends StatelessWidget {
  const CounterProvider({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = context.provide((_) => Counter());
    final (count, setCount) = context.value(0);

    context.listenSelect((Counter counter) => counter.count, (previous, next) {
      if (kDebugMode) {
        print('Count1: $previous -> $next');
      }
    });
    context.listenSelect((Counter counter) => counter.count, (previous, next) {
      if (kDebugMode) {
        print('Count2: $previous -> $next');
      }
    });

    return ElevatedButton(
      onPressed: () {
        setCount(count + 1);

        showDialog(
          context: context,
          builder: (context) {
            final count = context.watch<Counter>();

            return AlertDialog(
              title: Text('Count: ${count.count}'),
              actions: [
                ElevatedButton(
                  onPressed: () => counter.increment(),
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
