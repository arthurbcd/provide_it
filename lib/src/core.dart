import 'package:flutter/widgets.dart';

import 'framework/framework.dart';
import 'refs/create.dart';
import 'refs/provide.dart';
import 'refs/value.dart';

@Deprecated('Use `readIt` instead.')
final getIt = readIt;

/// A contextless version of [ContextReaders.read].
final readIt = _instance.readIt;

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
      create,
      dispose: dispose,
      key: key,
      parameters: parameters,
      lazy: true,
    ).bind(this);
  }
}

extension ContextStates on BuildContext {
  /// Binds [Ref] to this [BuildContext].
  R bind<R, T>(Ref<T> ref) {
    return _instance.bind(this, ref);
  }

  (T, void Function(T)) value<T>(T initialValue, {Object? key}) {
    return ValueRef(
      initialValue,
      key: key,
    ).bind(this);
  }

  T create<T>(T create(), {void dispose(T value)?, Object? key}) {
    return CreateRef<T>(
      create,
      dispose: dispose,
      key: key,
    ).bind(this);
  }
}

extension ContextReaders on BuildContext {
  /// Reads a previously bound value by [T] and [key].
  ///
  /// Instantiates the bind if not already.
  T read<T>({Object? key}) {
    return _instance.read<T>(this, key: key);
  }

  /// Watches a previously bound value by [T] and [key].
  ///
  /// Instantiates the bind if not already.
  T watch<T>({Object? key}) {
    return _instance.watch<T>(this, key: key);
  }

  /// Selects a previously bound value by [T] and [key].
  ///
  /// Instantiates the bind if not already.
  R select<T, R>(R selector(T value), {Object? key}) {
    return _instance.select<T, R>(this, selector, key: key);
  }

  /// Listens to a previously bound value by [T] and [key].
  ///
  /// Does not instantiate the bind.
  void listen<T>(void listener(T value), {Object? key}) {
    _instance.listen<T>(this, listener, key: key);
  }

  /// Listens to a previously bound value by [T], [selector] and [key].
  ///
  /// Instantiates the bind if not already.
  void listenSelect<R, T>(
    R selector(T value),
    void listener(R previous, R next), {
    Object? key,
  }) {
    _instance.listenSelect<T, R>(this, selector, listener, key: key);
  }
}

ProvideItElement get _instance => ProvideItElement.instance;
