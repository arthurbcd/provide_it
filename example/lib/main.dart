import 'package:context_plus/context_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider_plus/provider_plus.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [],
      builder: (context, _) {
        context.bind(() => CounterStore());
        return const MainApp();
      },
    ),
  );
}

final counter = Ref<CounterStore>();

class CounterStore extends ChangeNotifier {
  var _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.useState(0);
    final (count, setCount) = context.useState(0);
    final (names, setNames) = context.useState(<String>[]);
    final ac = context.useAnimationController();

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorTween(
                    begin: Colors.yellow,
                    end: Colors.red,
                  ).evaluate(ac),
                ),
                onPressed: () {
                  ac.animateTo(
                    ac.value < 0.5 ? 1 : 0,
                    curve: Curves.fastOutSlowIn,
                    duration: const Duration(seconds: 1),
                  );
                },
                child: Text('Animar cor'),
              ),
              ElevatedButton(
                onPressed: () => setCount(count + 1),
                child: Text('Increment: $count'),
              ),
              ElevatedButton(
                onPressed: () => setNames(names + ['Name ${names.length}']),
                child: Text('Names: $names'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Counter extends StatelessWidget {
  const Counter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: ${counter.watchOnly(context, (vm) => vm.count)}'),
        ElevatedButton(
          onPressed: () => showDialog(
            context: context,
            useRootNavigator: false,
            builder: (context) => AlertDialog(
              title: const Text('Alert'),
              content: const Text('Alert content'),
              actions: [
                TextButton(
                  onPressed: () => counter.of(context).increment(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
          child: const Text('Increment'),
        ),
        ElevatedButton(
          onPressed: () => counter.of(context).increment(),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
