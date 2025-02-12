# Provide It

ProvideIt is a provider-like state binding, management, and injection using only context extensions.

**This is a proof of concept and is not recommended for production use.**

## Use

### Setup

Set `Provider.root` on the root of your app.

```dart
void main() {
  runApp(
    Provider.root(
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
    final counter = context.provide((_) => CounterNotifier());

    return ElevatedButton(
      onPressed: () => counter.increment(),
      child: Text('Counter: ${counter.count}'),
    );
  }
}
```

#### `context.value`

Use the `value` method to bind a state to the context. The state will **not** be disposed when the context is unmounted.

This is equivalent to `Provider.value` in the provider package.

```dart
class CounterProvider extends StatelessWidget {
  const CounterProvider({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = context.value(0);

    return ElevatedButton(
      onPressed: () => counter.value++,
      child: Text('Counter: ${counter.value}'),
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

**This is a proof of concept and is not recommended for production use.**