import 'dart:async';

import 'package:flutter/widgets.dart';

import '../provide_it.dart';
import 'framework.dart';

/// Contextless [ContextReaders]. Reads the root [ProvideItScope].
final readIt = ReadIt.instance;

extension ContextProviders on BuildContext {
  /// Provides the value of [create]. See [ProvideRef].
  void provide<T>(
    Function create, {
    void dispose(T value)?,
    Map<String, dynamic>? parameters,
    bool? lazy,
    Object? key,
  }) {
    ProvideRef<T>(
      key: key,
      create,
      dispose: dispose,
      parameters: parameters,
      lazy: lazy,
    ).bind(this);
  }

  /// Directly provides [value]. See [ProvideRef].
  T provideValue<T>(
    T value, {
    bool Function(T prev, T next)? updateShouldNotify, // prev != next
    Object? key,
  }) {
    return ProvideRef.value(
      value,
      key: key,
      updateShouldNotify: updateShouldNotify,
    ).bind(this).read();
  }
}

extension ContextStates on BuildContext {
  /// Binds [T] value to this [BuildContext].
  /// - [initialValue] is the initial value.
  ///
  /// You can use the record to manage the value state.
  (T, void Function(T)) value<T>(T initialValue, {Object? key}) {
    return ValueRef(
      initialValue,
      key: key,
    ).bind(this).watch(this) as (T, void Function(T));
  }

  /// Binds [create] to this [BuildContext].
  ///
  /// You can use the value directly.
  T create<T>(
    T create(CreateContext context), {
    void dispose(T value)?,
    Object? key,
  }) {
    return CreateRef<T>(
      create,
      dispose: dispose,
      key: key,
    ).bind(this).watch(this) as T;
  }

  /// Subscribes to a [Future] function and returns its snapshot.
  AsyncSnapshot<T> future<T>(
    FutureOr<T> create(), {
    T? initialData,
    Object? key,
  }) {
    return FutureRef(
      create,
      initialData: initialData,
      key: key,
    ).bind(this).watch(this);
  }

  /// Subscribes to a [Future] value and returns its snapshot.
  AsyncSnapshot<T> futureValue<T>(
    FutureOr<T> value, {
    T? initialData,
    Object? key,
  }) {
    return FutureRef.value(
      value,
      initialData: initialData,
      key: key,
    ).bind(this).watch(this);
  }

  /// Subscribes to a [Stream] function and returns its snapshot.
  AsyncSnapshot<T> stream<T>(
    Stream<T> create(), {
    T? initialData,
    Object? key,
  }) {
    return StreamRef(
      create,
      initialData: initialData,
      key: key,
    ).bind(this).watch(this);
  }

  /// Subscribes to a [Stream] value and returns its snapshot.
  AsyncSnapshot<T> streamValue<T>(
    Stream<T> value, {
    T? initialData,
    Object? key,
  }) {
    return StreamRef.value(
      value,
      initialData: initialData,
      key: key,
    ).bind(this).watch(this);
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
  @Deprecated('Use of instead.')
  T read<T>({Object? key}) {
    return scope.read<T>(key: key);
  }

  /// Reads a previously bound value by [T] and [key].
  ///
  /// Returns a [Future] if the value is not ready.
  FutureOr<T> readAsync<T>({Object? key}) {
    return scope.readAsync<T>(key: key);
  }

  /// The future when all [AsyncBind.isReady] are completed.
  FutureOr<void> allReady() => scope.allReady();

  /// Whether all [AsyncBind.isReady] are completed.
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
  @Deprecated('Use of instead.')
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

extension ContextBindFinder on BuildContext {
  /// Gets a [Bind] of [T] type. O(1).
  ///
  /// The return type is `dynamic` on purpose as some [Bind] types are inferred by [Injector].
  Bind? getBindOfType<T>({Object? key}) {
    return scope.getBindOfType<T>(key: key);
  }

  /// Automatically calls [read] or [watch] based on the [listen] parameter.
  ///
  /// When listen is null (default), it automatically decides based on whether
  /// the widget is currently in build/layout/paint pipeline, but you can
  /// enforce specific behavior by explicitly setting listen to true or false.
  T of<T>({Object? key, bool? listen}) {
    return scope.of<T>(this, key: key, listen: listen);
  }
}

extension on BuildContext {
  @protected
  ProvideItScope get scope => ProvideItScope.of(this);
}

extension<T> on AsyncRef<T> {
  AsyncBind<T, AsyncRef<T>> bind(BuildContext context) {
    return context.scope.bind(context, this) as AsyncBind<T, AsyncRef<T>>;
  }
}
