import 'package:flutter/material.dart';
import 'package:provide_it/provide_it.dart';
import 'package:provide_it_example/benchmarks/context_watch/benchmark_screen.dart';

void main() {
  // readIt.provide(create);
  readIt.provide<Abstract>(AbstractImpl.new);

  final abstract = readIt.read<Abstract>();

  runApp(
    ProvideIt(
      child: Builder(
        builder: (context) {
          final abstract = context.read<Abstract>();
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: BenchmarkScreen(),
              ),
            ),
          );
        },
      ),
    ),
  );
}

abstract class Abstract {}

class AbstractImpl extends Abstract {}

class ServiceA {
  static Future<ServiceA> init() async {
    await Future.delayed(Duration(seconds: 1));
    return ServiceA();
  }
}

class ServiceB {}

class ServiceC {}

class RepositoryA {
  RepositoryA(this.a, this.b, this.c);

  final ServiceA a;
  final ServiceB b;
  final ServiceC c;
}

class RepositoryB {
  RepositoryB(this.a, this.b);

  final ServiceA a;
  final ServiceB b;
}

class StoreA {
  StoreA(this.a, this.b);

  final RepositoryA a;
  final RepositoryB b;
}

class StoreB {
  StoreB(this.a);

  final RepositoryA a;
}

final countRef = ValueRef<int>(0);

class CounterValue extends StatelessWidget {
  const CounterValue({super.key});

  @override
  Widget build(BuildContext context) {
    final (count, setValue) = context.value(0);
    final (count2, setValue2) = context.value(0);
    final (count3, setValue3) = context.value(0);

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            setValue(count + 1);
          },
          child: Text('Counter: $count'),
        ),
        ElevatedButton(
          onPressed: () {
            setValue2(count2 + 1);
          },
          child: Text('Counter2: $count2'),
        ),
        ElevatedButton(
          onPressed: () {
            setValue3(count3 + 1);
          },
          child: Text('Counter3: $count3'),
        ),
      ],
    );
  }
}
