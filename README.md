# Provide It

ProvideIt is a provider-like state binding, management, and injection using only context extensions.

**`provide_it` is a proof of concept and is not recommended for production use.**

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
      locator: (param) => pathParameters[param.name], // e.g: go_router

      // ProvideIt will take care of loading/error, but you can customize it:
      // - loadingBuilder: (context) => (...),
      // - errorBuilder: (context, error, trace) => (...),
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

Use `provide` method to bind a value to a context. The value will be unbound/disposed when the same context is unmounted.

This is equivalent to a widget-less `Provider` in the provider package.

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

By default, its located by instance type: `read<Type>`.

You can manually specify one using `locator` parameter:

```dart
ProvideIt(
  locator: (param) => pathParameters[param.name], // e.g: go_router
)
```

This will automatically inject the parameters to the constructor.

When needed, you can also specify the parameters using `parameters`:

```dart
 context.provide(Counter.new, parameters: {
  'counterId': 'my-id', // by name
  'String': 'my-id', // by type
  '0': 'my-id', // by position
 });
```

> Both `locator` and `parameters` are optional and fallback to the default behavior when `null`.

#### `context.value` & `context.create`

Those were common constructors you would find in the `Provider` widgets.

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

When using complex objects, you can use `context.create` to create a new instance. The objects will persist until the context is unmounted, then they will be disposed.

```dart
class CounterProvider extends StatelessWidget {
  const CounterProvider({super.key});

  @override
  Widget build(BuildContext context) {
    // yes! `CreateContext.vsync` is a thing, but only inside `create`.
    final controller = context.create((c) => AnimationController(vsync: c.vsync));

    return ElevatedButton(
      onPressed: () => controller.forward(),
      child: Text('Animation: ${controller.value}'),
    );
  }
}
```

> Both `value` and `create` will watch the `context` and rebuilt on it. By default, it watches `Listenable` objects. You can add a custom `Watcher` to watch other objects. See [Additional Watchers](#4-additional-watchers).

### 2. Accessing

For accessing a state, several methods are available:

```dart
final count = context.watch<CounterNotifier>().count;
final count2 = context.read<int>();
final count3 = context.select((CounterNotifier counter) => counter.count);
```

You can contextlessly read using `ReadIt.intance`, `ReadIt.I` or simply `readIt`.

They are available outside of the widget-tree (ex: tests). Some context dependent methods such as `watch` and `select` are not.

Equivalent deprecations were included to help migrating from `provider`/`get_it` packages.

```dart
final count = readIt<CounterNotifier>().count; // <- callable
final count = readIt.read<CounterNotifier>().count;
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

You can implement a custom [Watcher] to tell the framework how to watch an observable.

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

**`provide_it` is a proof of concept and is not recommended for production use.**