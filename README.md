# Provide It

A minimalist state sharing library.

## Setup

```dart
// Wrap your app with ProvideIt.
void main() => runApp(ProvideIt(child: MyApp()));
```

## Usage

For handling local state quickly.

### Local State (Hooks)
```dart
// Hook & use locally.
final counter = context.use(() => Counter());
final (count, setCount) = context.useValue(0);
```

### Hook Example
```dart
class CounterExample extends StatelessWidget {
  const CounterExample({super.key});

  @override
  Widget build(BuildContext context) {
    final (count, setCount) = context.useValue(0);

    return GestureDetector(
      onTap: () => setCount(count + 1),
      child: Text('Increment: $count'),
    );
  }
}
```

### Shared State (DI)

For sharing state across screens and routes.

```dart
// Provide it...
context.provide(() => Counter()); // classic
context.provideAuto(Counter.new); // auto-injects dependencies
context.provideValue(0);

// ... and use it anywhere
final counter = context.watch<Counter>();
final count = context.select((Counter c) => c.count);

// ... or just listen for side-effects!
context.listen<Counter>((it) => print(it.count));
context.listenSelected((Counter it) => it.count, (prev, next) {
  print('Count changed $prev -> $next');
});
```

### Inherited Example

```dart
class InheritedExample extends StatelessWidget {
  const InheritedExample({super.key});

  @override
  Widget build(BuildContext context) {
    // handle local state with HookProvider
    final snapshot = context.useFuture(() async => fetchData());

    // provide shared state with InheritedProvider
    context.provideValue(snapshot.data);

    return switch (snapshot) {
      AsyncSnapshot(:final data?) => Text('data: $data'),
      AsyncSnapshot(:final error?) => Text('error: $error'),
      _ => Text('loading'),
    };
  }
}
```

### Available Providers

Below is a list of all `context` providers currently available.

| Extension method | Provider type | Description |
|------------------|---------------|-------------|
| `context.provide` | InheritedProvider | Provides a value using a manual factory |
| `context.provideAuto` | InheritedProvider | Provides a value with auto-dependency injection |
| `context.provideAsync` | InheritedProvider | Provides a `Future` value asynchronously |
| `context.provideValue` | InheritedProvider | Provides an existing value with optional update callback |
| `context.use` | HookProvider | Creates a local value tied to the context |
| `context.useValue` | HookProvider | Returns a mutable value record |
| `context.useStream` | HookProvider | Subscribes to a `Stream` and returns `AsyncSnapshot` |
| `context.useStreamValue` | HookProvider | Subscribes to an existing `Stream` |
| `context.useFuture` | HookProvider | Subscribes to a `Future` and returns `AsyncSnapshot` |
| `context.useFutureValue` | HookProvider | Subscribes to an existing `Future` |
| `context.useSingleTickerProvider` | HookProvider | Provides a `TickerProvider` for animations |
| `context.useAnimationController` | HookProvider | Creates an `AnimationController` tied to context |
| `context.useAutomaticKeepAlive` | HookProvider | Enables/disables automatic keep-alive for the subtree |

---

### The "What Ifs" behind the Magic

ProvideIt was born from a few questions:

- *What if I could context.listen with provider?*
- *What if I could scope and auto-dispose with get_it?*
- *What if I could provide/hook state without custom widgets?*

### Inspirations

This project took cues from several existing packages and ideas:

- **provider** – syntax and scoping.
- **flutter_hooks & context_watch** – binding and reactivity engine.
- **auto_injector** – automatic injection without code generation.

> And of course **flutter**, by using native tools like `Listenable`, `ValueNotifier` and `AsyncSnapshot`. This package depends only on `flutter/widgets`.

### How it Works: The Scoped Container

ProvideIt doesn't behave exactly like a Service Locator or a traditional Provider chain. It's a scoped container designed to be Flutter-native.

- **Not a Service Locator**: Unlike **get_it**, ProvideIt is lifecycle-aware. It knows when a widget dies and cleans up the mess.

- **Not a Scoped Wrapper**: Unlike **provider**, it isn't strictly chained to the parent-child hierarchy. You can access states in sibling routes or dialogs without complex nesting.

### State Binding

At its core, ProvideIt is a **single** `InheritedWidget` acting as a container. When you use an extension like `context.useValue` or `context.provide`, you are performing State Binding.

There are two types of bindings:

1. **HookProvider** (Local): Private state. It lives and dies with that specific widget.
2. **InheritedProvider** (Shared): Global-ish state. It's registered in the container and becomes available to other contexts.

### Scoping & Disambiguation

Wait, if it's a single container, how does it handle multiple states of the same type?
ProvideIt is **smart about context**:

- **Closest Wins**: If you have two providers of the same type, ProvideIt looks for the one closest to your current context.
- **Sibling Safety**: If you try to access a state that exists in two different sibling branches (like two different routes) at the same time, ProvideIt throws an exception to prevent bugs.

This makes ProvideIt "retro-compatible" with the provider mental model, but with the freedom to reach across the app tree.

