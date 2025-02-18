import 'package:flutter/material.dart';
import 'package:provide_it/provide_it.dart';
// import 'package:provide_it/provide_it.dart';

void main() {
  runApp(
    ProvideIt(
      provide: (context) {
        context.provide<Abstract>(AbstractImpl.new);
      },
      builder: (context, _) {
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: CounterValue(),
            ),
          ),
        );
      },
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
    final counter = context.value(0);

    return ElevatedButton(
      onPressed: () async {
        final abs = await context.readAsync<Abstract>();
        print("abs $abs");
      },
      child: Text('Counter: ${counter.value}'),
    );
  }
}
