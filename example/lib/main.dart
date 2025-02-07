import 'package:context_plus/context_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider_plus/provider_plus.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [],
      builder: (context, _) {
        context.provide(() => CounterStore());
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
    final ctn = context.watch<CounterStore>();

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
                onPressed: () => ctn.increment(),
                child: Text('CounterStore: ${ctn.count}'),
              ),
              Builder(
                builder: (context) {
                  context.provide(() => CounterStore());
                  // final ac = context.provide(
                  //   () => AnimationController(vsync: context.vsync),
                  // );
                  final counter = context.useProvider((_) => CounterStore());
                  final counter2 = context.useProvider((_) => CounterStore());
                  final counter3 = context.useProvider((_) => CounterStore());
                  final counter4 = context.useProvider((_) => CounterStore());

                  final aCounter = context.findHookValueByType<CounterStore>();

                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          counter.increment();
                        },
                        child: Text('counter: ${counter.count}'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          counter2.increment();
                        },
                        child: Text('counter2: ${counter2.count}'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          counter3.increment();
                        },
                        child: Text('counter3: ${counter3.count}'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          counter4.increment();
                        },
                        child: Text('counter4: ${counter4.count}'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          aCounter.increment();
                        },
                        child: Text('aCounter: ${aCounter.count}'),
                      ),
                    ],
                  );
                },
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
