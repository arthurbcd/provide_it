# Provide It

ProvideIt is a provider-like state binding, management, and injection using only context extensions.

**This is a proof of concept and is not recommended for production use.**

## Use

```dart
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
      namedLocator: (param) => pathParameters[param.name], // e.g: go_router

      // ProvideIt will take care of loading/error, but you can customize it:
      // - loadingBuilder: (context) => (...),
      // - errorBuilder: (context, error, stackTrae) =>ce(...),
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            final counter = context.watch<Counter>();

            context.listen<Counter>((counter) {
              // do something
            });

            return Center(
              child: ElevatedButton(
                onPressed: counter.increment,
                child: Text('${counter.count}'),
              ),
            );
          },
        ),
      ),
    ),
  );
}
```

### Setup

Set `ProvideIt` above your app.

```dart
void main() {
  runApp(
    ProvideIt(
      child: App(), // Ex: MaterialApp
    ),
  );
}
```

### 1. Providing

#### `context.provide`

Use the `provide` method to bind a state to the context. The state will be disposed when the context is unmounted.

This is equivalent to `Provider` in the provider package.

```dart
class CounterProvider extends StatelessWidget {
  const CounterProvider({super.key});

  @override
  Widget build(BuildContext context) {
    context.provide(Counter.new);

      return ElevatedButton(
        onPressed: () => context.read<Counter>().increment(),
        child: Text('Count: ${context.watch<Counter>().count}'),
      );
  }
}
```

Did you see the `.new`? This is a new feature that allows you automatically inject instances that were previously bound.

In addition to `context.provide`, there are several other methods available:

- `context.provideFactory`
- `context.provideValue`
- `context.provideLazy`

All of them support the `.new` auto-injection, no matter if `async` or not.

For manually providing a single named paramater, use flutter's [Symbol]:

```dart
 context.provide(Counter.new, parameters: {
  #counterId: 'my-counter-id',
 });
```

All of these methods are equivalent to the respective methods in the `get_it` package, deprecations were included for help in migration.

#### `context.value` & `context.create`

Those were common properties you would find in the `Provider` widgets.

Now you can use them directly from the context, for simple state management.

```dart
class CounterProvider extends StatelessWidget {
  const CounterProvider({super.key});

  @override
  Widget build(BuildContext context) {
    // like this
    final counter = context.value(0); // use with primitives

    // or with destructuring!
    final (count, setCount) = context.value(0); // dart records!

    return ElevatedButton(
      onPressed: () => counter.value++,
      child: Text('Counter: ${counter.value}'),
    );
  }
}
```

When using complex objects, you can use the `create` method to create a new instance. The objects will persist until the context is unmounted, then they will be disposed.

You can recreate.

```dart
class CounterProvider extends StatelessWidget {
  const CounterProvider({super.key});

  @override
  Widget build(BuildContext context) {
    // yes! `context.vsync` is a thing, but only available inside `create`.
    final controller = context.create(() => AnimationController(vsync: context.vsync));

    return ElevatedButton(
      onPressed: () => controller.forward(),
      child: Text('Animation: ${controller.value}'),
    );
  }
}
```

### 2. Accessing

For accessing a state, several methods are available:

```dart
final count = context.watch<CounterNotifier>().count;
final count2 = context.read<int>();
final count3 = context.select((CounterNotifier counter) => counter.count);
```

All of these methods are equivalent to the respective methods in the `provider` package, deprecations were included for help in migration.

You can access contextlessly using `ReadIt.intance`, `ReadIt.I` or simply `readIt`.

`ReadIt` is contextless, and can be used in tests or outside of widgets. `watch`, `select` and etc are not available in `ReadIt`.

```dart
final count = readIt.read<CounterNotifier>().count;
final count = readIt.listen<CounterNotifier>((counter) {
  print('Counter changed: ${counter.count}');
});
```

### 3. Listening

A highly requested feature is the ability to listen to a state without rebuilding the widget.

There is no equivalent in the `provider` package.

```dart
context.listen<CounterNotifier>((counter) {
  print('Counter changed: ${counter.count}');
});
```

And you can also listen with a selector:

```dart
context.listenSelect((CounterNotifier it) => it.count, (prev, next) {
  print('Counter changed: $prev -> $next');
});
```

### 4. Additional Watchers

You can implement a custom [Watcher] to tell the framework how to watch a state.

```dart
import 'package:bloc/bloc.dart';

class CubitWatcher extends Watcher<Cubit> {
  final subscriptions = <Object, StreamSubscription>{};

  @override
  void init(Cubit observable, VoidCallback notify) {
    subscriptions[notify] = observable.stream.listen((_) => notify());
  }

  @override
  void cancel(Cubit observable, VoidCallback notify) {
    subscriptions.remove(notify)?.cancel();
  }

  @override
  void dispose(Cubit observable) {
    observable.close();
  }
}
```

Then you can add it:

```dart
ProvideIt(
  additionalWatchers: [CubitWatcher()],
);
```

And now you can `watch`, `select` and `listen` as usual:

```dart
final state = context.watch<MyCubit>().state;
```

**This is a proof of concept and is not recommended for production use.**