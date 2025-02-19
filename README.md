# Provide It

ProvideIt is a provider-like state binding, management, and injection using only context extensions.

**This is a proof of concept and is not recommended for production use.**

## Use

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

All of them support the `.new` auto-injection.

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

All of these methods are equivalent to the respective methods in the provider package.

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

**This is a proof of concept and is not recommended for production use.**