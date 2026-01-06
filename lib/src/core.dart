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

extension ContextUses on BuildContext {
  /// Binds [create] to this [BuildContext].
  ///
  /// You can use the value directly.
  T use<T>(
    T create(UseContext context), {
    void dispose(T value)?,
    Object? key,
  }) {
    return UseRef<T>(
      create,
      dispose: dispose,
      key: key,
    ).bind(this).watch(this) as T;
  }

  /// Binds [T] value to this [BuildContext].
  /// - [initialValue] is the initial value.
  ///
  /// You can use the record to manage the value state.
  (T, void Function(T)) useValue<T>(
    T initialValue, {
    Object? key,
  }) {
    return UseValueRef(
      initialValue,
      key: key,
    ).bind(this).watch(this) as (T, void Function(T));
  }

  /// Subscribes to a [Future] function and returns its snapshot.
  AsyncSnapshot<T> useFuture<T>(
    FutureOr<T> create(), {
    T? initialData,
    Object? key,
  }) {
    return UseFutureRef(
      create,
      initialData: initialData,
      key: key,
    ).bind(this).watch(this);
  }

  /// Subscribes to a [Stream] function and returns its snapshot.
  AsyncSnapshot<T> useStream<T>(
    Stream<T> create(), {
    T? initialData,
    Object? key,
  }) {
    return UseStreamRef(
      create,
      initialData: initialData,
      key: key,
    ).bind(this).watch(this);
  }
}

/// Extension methods that DO NOT depend on [BuildContext].
///
/// Use them freely.
extension ContextReaders on BuildContext {
  /// Reads a previously bound value by [T] and [key].
  T read<T>() {
    return scope.read<T>(this);
  }

  /// Reads a previously bound value by [T] and [key].
  ///
  /// Returns a [Future] if the value is not ready.
  FutureOr<T> readAsync<T>() {
    return scope.readAsync<T>();
  }

  /// The future when all [AsyncBind.isReady] are completed.
  FutureOr<void> allReady() => scope.allReady();

  /// Whether all [AsyncBind.isReady] are completed.
  bool allReadySync() => allReady() == null;

  /// The future when [T] is ready.
  FutureOr<void> isReady<T>({Object? key}) => scope.isReady<T>(key: key);

  /// Whether [T] is ready.
  bool isReadySync<T>({Object? key}) => isReady<T>(key: key) == null;

  Future<void> reload<T>() {
    return scope.reload<T>();
  }
}

/// Extension methods that DO DEPEND on [BuildContext].
///
/// Use them directly in [Widget] `build` methods.
extension ContextObservers on BuildContext {
  /// Watches a previously bound value by [T] and [key].
  ///
  /// Reads the bind if not already.
  T watch<T>() {
    return scope.watch<T>(this);
  }

  /// Selects a previously bound value by [T] and [key].
  ///
  /// Reads the bind if not already.
  R select<T, R>(R selector(T value)) {
    return scope.select<T, R>(this, selector);
  }

  /// Listens to a previously bound value by [T] and [key].
  ///
  /// Does not read a lazy bind.
  void listen<T>(void listener(T value)) {
    scope.listen<T>(this, listener);
  }

  /// Listens to a previously bound value by [T], [selector] and [key].
  ///
  /// Instantiates the bind if not already.
  void listenSelect<R, T>(
    R selector(T value),
    void listener(R prev, R next),
  ) {
    scope.listenSelect<T, R>(this, selector, listener);
  }
}

extension ContextBinds on BuildContext {
  /// Gets a [Bind] of [T] type. O(1).
  ///
  /// The return type is `dynamic` on purpose as some [Bind] types are inferred by [Injector].
  Bind? getBindOfType<T>() {
    return scope.getBindOfType<T>();
  }

  /// Inherits all [ContextProviders] from [parent] to `this`.
  ///
  /// This allows using [ContextReaders] and [ContextObservers] in simbling contexts,
  /// such as in dialogs, routes, overlays, etc.
  void inheritProviders(BuildContext parent) {
    scope.inheritProviders(this, parent);
  }

  /// Automatically calls [read] or [watch] based on the [listen] parameter.
  ///
  /// When listen is null (default), it automatically decides based on whether
  /// the widget is currently in build/layout/paint pipeline, but you can
  /// enforce specific behavior by explicitly setting listen to true or false.
  T of<T>({Object? key, bool? listen}) {
    return scope.of<T>(this, listen: listen);
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
