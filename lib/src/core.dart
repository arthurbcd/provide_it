import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provide_it/src/refs/async.dart';
import 'package:provide_it/src/refs/init.dart';
import 'package:provide_it/src/refs/stream.dart';

import 'framework.dart';
import 'refs/create.dart';
import 'refs/future.dart';
import 'refs/provide.dart';
import 'refs/value.dart';

@Deprecated('Use `readIt` instead.')
final getIt = readIt;

/// A contextless version of [ContextReaders.read].
final readIt = ProvideItElement.instance.readItAsync;

extension ContextProviders on BuildContext {
  void provide<T>(
    Function create, {
    void dispose(T value)?,
    Map<String, dynamic>? parameters,
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

  void provideLazy<T>(
    Function create, {
    void dispose(T value)?,
    Map<String, dynamic>? parameters,
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

  void provideFactory<T>(
    Function create, {
    void dispose(T value)?,
    Map<String, dynamic>? parameters,
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

  void provideValue<T>(
    T value, {
    bool Function(T, T)? updateShouldNotify,
    Object? key,
  }) {
    ProvideRef.value(
      value,
      key: key,
      updateShouldNotify: updateShouldNotify,
    ).bind(this);
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

  /// Subscribes to a [Future] and updates the value.
  AsyncSnapshot<T> future<T>(
    FutureOr<T> create(), {
    T? initialData,
    Object? key,
  }) {
    return FutureRef<T>(
      create,
      initialData: initialData,
      key: key,
    ).bind(this);
  }

  /// Subscribes to a [Stream] and updates the value.
  AsyncSnapshot<T> stream<T>(
    Stream<T> create(), {
    T? initialData,
    Object? key,
  }) {
    return StreamRef<T>(
      create,
      initialData: initialData,
      key: key,
    ).bind(this);
  }

  /// The future when all [AsyncRefState.isReady] are completed.
  FutureOr<void> allReady() => provideIt.allReady();

  /// Whether all [AsyncRefState.isReady] are completed.
  bool allReadySync() => allReady() == null;

  /// The future when [T] is ready.
  FutureOr<void> isReady<T>({Object? key}) => provideIt.isReady<T>(key: key);

  /// Whether [T] is ready.
  bool isReadySync<T>({Object? key}) => isReady<T>(key: key) == null;

  /// Calls [fn] when the [BuildContext] is mounted.
  ///
  /// Changing [key] re-calls [fn].
  void init(VoidCallback fn, {VoidCallback? dispose, Object? key}) {
    InitRef(init: fn, dispose: dispose, key: key).bind(this);
  }

  /// Calls [fn] when the [BuildContext] is unmounted.
  void dispose(VoidCallback fn, {Object? key}) {
    InitRef(dispose: fn, key: key).bind(this);
  }
}

extension ContextReaders on BuildContext {
  /// Reads a previously bound value by [T] and [key].
  ///
  /// Instantiates the bind if not already.
  T read<T>({Object? key}) {
    return provideIt.read<T>(this, key: key);
  }

  /// Reads a previously bound value by [T] and [key].
  ///
  /// Returns a [Future] if the value is not ready.
  FutureOr<T> readAsync<T>({Object? key}) {
    return provideIt.readItAsync<T>(key: key);
  }

  /// Watches a previously bound value by [T] and [key].
  ///
  /// Instantiates the bind if not already.
  T watch<T>({Object? key}) {
    return provideIt.watch<T>(this, key: key);
  }

  /// Selects a previously bound value by [T] and [key].
  ///
  /// Instantiates the bind if not already.
  R select<T, R>(R selector(T value), {Object? key}) {
    return provideIt.select<T, R>(this, selector, key: key);
  }

  /// Listens to a previously bound value by [T] and [key].
  ///
  /// Does not instantiate the bind.
  void listen<T>(void listener(T value), {Object? key}) {
    provideIt.listen<T>(this, listener, key: key);
  }

  /// Listens to a previously bound value by [T], [selector] and [key].
  ///
  /// Instantiates the bind if not already.
  void listenSelect<R, T>(
    R selector(T value),
    void listener(R previous, R next), {
    Object? key,
  }) {
    provideIt.listenSelect<T, R>(this, selector, listener, key: key);
  }

  Future<void> reload({Object? key}) {
    return provideIt.reload(this, key: key);
  }
}
