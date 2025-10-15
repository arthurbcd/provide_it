import 'package:flutter/material.dart';
import 'package:provide_it/provide_it.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();
final pathParameters = {'counterId': 'my-counter-id'};
void main() {
  runApp(
    ProvideIt(
      // Auto-injects dependencies
      provide: (context) {
        context.provide<CounterService>(CounterServiceImpl.async); // async
        context.provide(CounterRepository.new);
        context.provide(Counter.new);
      },
      // Auto-injects path parameters
      locator: (param) => pathParameters[param.name],

      // ProvideIt will take care of loading/error, but you can customize it:
      // - loadingBuilder: (context) => (...),
      // - errorBuilder: (context, error, stackTrae) =>ce(...),
      child: MaterialApp(
        scaffoldMessengerKey: messengerKey,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              context.listen<Counter>((counter) {
                messengerKey.currentState?.hideCurrentSnackBar();
                messengerKey.currentState?.showSnackBar(
                  SnackBar(content: Text('Counter changed: ${counter.count}')),
                );
              });

              return Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            final counter = context.of<Counter>();

                            return AlertDialog(
                              title: Text('Works in a dialog!'),
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
                          return Builder(
                            builder: (context) {
                              context.provide(() => ValueNotifier(0));
                              final vn = context.watch<ValueNotifier<int>>();
                              return ListTile(
                                title: Text('Counter: ${vn.value}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) {
                                        // // This child context is now scoped to the parent context
                                        ctx.inheritScope(context);
                                        final vn =
                                            ctx.watch<ValueNotifier<int>>();
                                        return AlertDialog(
                                          title: Text('Counter from dialog'),
                                          content: Text('${vn.value}'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => vn.value++,
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class CounterServiceImpl extends CounterService {
  CounterServiceImpl._();
  static Future<CounterServiceImpl> async() async {
    await Future.delayed(Duration(seconds: 3));
    return CounterServiceImpl._();
  }
}

class CounterService {}

class CounterRepository {
  CounterRepository(this.service);
  final CounterService service;
}

class Counter extends ChangeNotifier {
  Counter(this.repository, {required this.counterId});
  final CounterRepository repository;
  final String counterId;

  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}
