import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provide_it/provide_it.dart';

final pathParameters = <String, String>{
  'counterId': 'my-counter-id',
};

void main() {
  runApp(
    ProvideIt(
      // Auto-injects dependencies
      provide: (context) {
        context.provide(CounterService.init); // <- async
        context.provide(CounterRepository.new);
        context.provide(Counter.new);
      },
      // Auto-injects path parameters
      locator: (param) => pathParameters[param.name],

      // ProvideIt will take care of loading/error, but you can customize it:
      // - loadingBuilder: (context) => (...),
      // - errorBuilder: (context, error, stackTrae) =>ce(...),
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            final counter = context.watch<Counter>();

            context.listen<Counter>((counter) {
              if (kDebugMode) {
                print('Counter changed: ${counter.count}');
              }
            });

            return Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final counter = context.watch<Counter>();

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
                child: Text('${counter.count}'),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class CounterService {
  CounterService();

  static Future<CounterService> init() async {
    await Future.delayed(Duration(seconds: 3));
    return CounterService();
  }
}

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
