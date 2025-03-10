import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../provide_it.dart';
import 'framework.dart';

@Deprecated('Use `readIt` instead.')
final getIt = readIt;

/// A contextless version of [ContextReaders.read].
final readIt = ReadIt.instance;

extension ContextProviders on BuildContext {
  /// Immediately calls [create] and provides its value. See [ProvideRef].
  void provide<T>(
    Function create, {
    void dispose(T value)?,
    Map<Symbol, dynamic>? parameters,
    Object? key,
  }) {
    ProvideRef<T>(
      key: key,
      create,
      dispose: dispose,
      parameters: parameters,
      lazy: false,
    ).bind(this);
  }

  /// Calls [create] on first read and then provides its value. See [ProvideRef].
  void provideLazy<T>(
    Function create, {
    void dispose(T value)?,
    Map<Symbol, dynamic>? parameters,
    Object? key,
  }) {
    ProvideRef(
      key: key,
      create,
      dispose: dispose,
      parameters: parameters,
      lazy: true,
    ).bind(this);
  }

  /// Calls [create] on every read and returns its value. See [ProvideRef].
  void provideFactory<T>(
    Function create, {
    void dispose(T value)?,
    Map<Symbol, dynamic>? parameters,
    Object? key,
  }) {
    ProvideRef(
      key: key,
      create,
      dispose: dispose,
      parameters: parameters,
      factory: true,
    ).bind(this);
  }

  /// Directly provides a value. See [ProvideRef].
  T provideValue<T>(
    T value, {
    bool Function(T prev, T next)? updateShouldNotify, // prev != next
    Object? key,
  }) {
    return ProvideRef.value(
      value,
      key: key,
      updateShouldNotify: updateShouldNotify,
    ).bind(this) as T;
  }
}

extension RefBinder on BuildContext {
  /// Shortcut to bind a [Ref] to this [BuildContext].
  ///
  /// Use it to override [Ref.bind] to declare a custom [R] return type:
  /// ```dart
  /// @override
  /// T bind(BuildContext context) => context.bind(this);
  /// ```
  /// See: [CreateRef] or [ValueRef].
  R bind<R, T>(Ref<T> ref) {
    return scope.bind(ref, context: this) as R;
  }
}

extension ContextStates on BuildContext {
  /// Binds [T] value to this [BuildContext].
  /// - [initialValue] is the initial value.
  ///
  /// You can use the record to manage the value state.
  (T, void Function(T)) value<T>(T initialValue, {Object? key}) {
    return ValueRef(
      key: key,
      initialValue,
    ).bind(this);
  }

  /// Binds [create] to this [BuildContext].
  ///
  /// You can use the value directly.
  T create<T>(T create(), {void dispose(T value)?, Object? key}) {
    return CreateRef<T>(
      key: key,
      create,
      dispose: dispose,
    ).bind(this);
  }

  /// Subscribes to a [Future] function and returns its snapshot.
  AsyncSnapshot<T> future<T>(
    FutureOr<T> create(), {
    T? initialData,
    Object? key,
  }) {
    return FutureRef(
      key: key,
      create,
      initialData: initialData,
    ).bind(this);
  }

  /// Subscribes to a [Future] value and returns its snapshot.
  AsyncSnapshot<T> futureValue<T>(
    FutureOr<T> value, {
    T? initialData,
    Object? key,
  }) {
    return FutureRef.value(
      key: key,
      value,
      initialData: initialData,
    ).bind(this);
  }

  /// Subscribes to a [Stream] function and returns its snapshot.
  AsyncSnapshot<T> stream<T>(
    Stream<T> create(), {
    T? initialData,
    Object? key,
  }) {
    return StreamRef(
      key: key,
      create,
      initialData: initialData,
    ).bind(this);
  }

  /// Subscribes to a [Stream] value and returns its snapshot.
  AsyncSnapshot<T> streamValue<T>(
    Stream<T> value, {
    T? initialData,
    Object? key,
  }) {
    return StreamRef.value(
      key: key,
      value,
      initialData: initialData,
    ).bind(this);
  }

  /// Calls [init] when the [BuildContext] is mounted.
  ///
  /// Changing [key] re-calls [init].
  void init(VoidCallback init, {VoidCallback? dispose, Object? key}) {
    InitRef(init: init, dispose: dispose, key: key).bind(this);
  }

  /// Calls [dispose] when the [BuildContext] is unmounted.
  void dispose(VoidCallback dispose, {Object? key}) {
    InitRef(dispose: dispose, key: key).bind(this);
  }
}

/// Extension methods that DO NOT depend on [BuildContext].
///
/// Use them freely.
extension ContextReaders on BuildContext {
  /// Reads a previously bound value by [T] and [key].
  T read<T>({Object? key}) {
    return scope.read<T>(key: key);
  }

  /// Reads a previously bound value by [T] and [key].
  ///
  /// Returns a [Future] if the value is not ready.
  FutureOr<T> readAsync<T>({Object? key}) {
    return scope.readAsync<T>(key: key);
  }

  /// The future when all [AsyncRefState.isReady] are completed.
  FutureOr<void> allReady() => scope.allReady();

  /// Whether all [AsyncRefState.isReady] are completed.
  bool allReadySync() => allReady() == null;

  /// The future when [T] is ready.
  FutureOr<void> isReady<T>({Object? key}) => scope.isReady<T>(key: key);

  /// Whether [T] is ready.
  bool isReadySync<T>({Object? key}) => isReady<T>(key: key) == null;

  Future<void> reload<T>({Object? key}) {
    return scope.reload<T>(key: key);
  }
}

/// Extension methods that DO DEPEND on [BuildContext].
///
/// Use them directly in [Widget] `build` methods.
extension ContextBinds on BuildContext {
  /// Watches a previously bound value by [T] and [key].
  ///
  /// Reads the bind if not already.
  T watch<T>({Object? key}) {
    return scope.watch<T>(this, key: key);
  }

  /// Selects a previously bound value by [T] and [key].
  ///
  /// Reads the bind if not already.
  R select<T, R>(R selector(T value), {Object? key}) {
    return scope.select<T, R>(this, selector, key: key);
  }

  /// Listens to a previously bound value by [T] and [key].
  ///
  /// Does not read a lazy bind.
  void listen<T>(void listener(T value), {Object? key}) {
    scope.listen<T>(this, listener, key: key);
  }

  /// Listens to a previously bound value by [T], [selector] and [key].
  ///
  /// Instantiates the bind if not already.
  void listenSelect<R, T>(
    R selector(T value),
    void listener(R previous, R next), {
    Object? key,
  }) {
    scope.listenSelect<T, R>(this, selector, listener, key: key);
  }
}

extension ContextRefStateFinder on BuildContext {
  /// Finds a [RefState] of [T] type.
  ///
  /// The return type is `dynamic` on purpose as some [RefState] types are inferred by [Injector].
  RefState? findRefStateOfType<T>({Object? key}) {
    return scope.findRefStateOfType<T>(key: key);
  }
}

extension ContextVsync on BuildContext {
  /// Creates a single [TickerProvider] for the current [BuildContext].
  ///
  /// Must be used exactly once, preferably within [Ref.create].
  TickerProvider get vsync {
    assert(
      scope.debugDoingInit,
      'context.vsync must be used within Ref.create/initState method.',
    );

    return _TickerProvider(this);
  }
}

class _TickerProvider implements TickerProvider {
  _TickerProvider(this.context);
  final BuildContext context;

  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick, debugLabel: 'created by $context');
  }
}

extension on BuildContext {
  @protected
  ProvideItScope get scope {
    final it = getElementForInheritedWidgetOfExactType<ProvideIt>();
    assert(it != null, 'You must set `ProvideIt` in your app.');
    return (it as ProvideItElement).scope;
  }
}
