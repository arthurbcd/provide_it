import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provide_it/provide_it.dart';

void main() {
  runApp(
    ProvideIt(
      provide: (context) {
        context.provideAsync(() async {
          await Future.delayed(Duration(seconds: 2));
          return Size(1, 2);
        });
        context.provideValue(AppAnalytics.instance);
        context.provideAsync<CounterService>(CounterServiceImpl.init);

        // auto-inject dependencies by type:
        context.provide(CounterRepository.new);
        context.provide(Counter.new);
      },
      // provide custom values by parameter type or name:
      locator: (param) => pathParameters[param.name],

      // show something while waiting for async providers to be ready.
      loadingBuilder: (context) {
        return Center(child: CircularProgressIndicator());
      },
      child: MaterialApp(
        scaffoldMessengerKey: messengerKey,
        home: const Scaffold(body: AppBody()),
      ),
    ),
  );
}

final pathParameters = {'counterId': 'my-counter-id'};
final messengerKey = GlobalKey<ScaffoldMessengerState>();

class AppBody extends StatelessWidget {
  const AppBody({super.key});

  @override
  Widget build(BuildContext context) {
    context.listen<Counter>((counter) {
      messengerKey.currentState?.hideCurrentSnackBar();
      messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Counter changed: ${counter.count}')),
      );
    });
    context.listenSelected((Counter e) => e.count, (prev, next) {
      print('Counter changed from $prev to $next');
    });
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                final counter = context.watch<Counter>();

                return AlertDialog(
                  title: Text('You can watch inside the dialog!'),
                  content: Text('${counter.count}'),
                  actions: [
                    TextButton(
                      onPressed: () => counter.increment(),
                      child: const Text('Increment'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
            );
          },
          child: Text('Open Counter dialog'),
        ),
        Expanded(
          child: ListView.builder(
            itemBuilder: (context, index) {
              // we wrap with Builder to obtain a stable context for each item
              return Builder(
                builder: (context) {
                  // we can bind hook providers, for local state management
                  context.useAutomaticKeepAlive();
                  final (count, setCount) = context.useValue(0);

                  return ListTile(
                    title: Text('Counter: $count'),
                    onTap: () {
                      setCount(count + 1);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class CounterServiceImpl extends CounterService {
  CounterServiceImpl._();
  static Future<CounterServiceImpl> init() async {
    await Future.delayed(Duration(seconds: 3));
    return CounterServiceImpl._();
  }
}

class AppAnalytics {
  AppAnalytics._();
  static final instance = AppAnalytics._();
}

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
