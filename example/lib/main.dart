import 'package:flutter/material.dart';
import 'package:provide_it/provide_it.dart';
// import 'package:provide_it/provide_it.dart';

void main() {
  runApp(
    ProvideIt(
      provide: (context) {
        context.provideLazy(StoreA.new);
        context.provideLazy(StoreB.new);
        context.provideLazy(ServiceA.new);
        context.provideLazy(ServiceB.new);
        context.provideLazy(ServiceC.new);
        context.provideLazy(RepositoryA.new);
        context.provideLazy(RepositoryB.new);
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
        final storeA = await context.readAsync<StoreA>();
        print("storeA $storeA");
        final storeB = await context.readAsync<StoreB>();
        print("storeB $storeB");
      },
      child: Text('Counter: ${counter.value}'),
    );
  }
}
