import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provide_it/src/framework.dart';
import 'package:provide_it/src/utils/async_snapshot_extension.dart';

import '../injector/injector.dart';
import 'async.dart';

/// Determines the default behavior when `lazy` is `null`.
typedef LazyDefault<T> = bool Function(ProvideBind<T> state);

class ProvideRef<T> extends AsyncRef<T> {
  /// A reference to a provider with various configuration options.
  ///
  /// The `ProvideRef` class allows you to create a reference to a provider
  /// with specific behaviors such as lazy initialization and factory creation.
  ///
  /// The `create` function is required and is used to create the provider.
  ///
  /// The optional parameters are:
  /// - `dispose`: A function to dispose of the provider.
  /// - `lazy`: If true, the provider is lazily initialized. Defaults to false.
  /// - `factory`: If true, the provider is created as a factory. Defaults to false.
  /// - `parameters`: Additional parameters for the provider.
  /// - `key`: An optional key for the provider.
  ///
  const ProvideRef(
    Function this.create, {
    this.dispose,
    this.lazy = false,
    this.parameters,
    super.key,
  })  : value = null,
        updateShouldNotify = null;

  @override
  final Function? create;

  /// How to dispose the value.
  final void Function(T value)? dispose;

  /// The [Injector.parameters] to manually pass to [create].
  /// Ex:
  /// ```dart
  /// context.provide(ProductNotifier.new, parameters: {
  ///   'productId': '123',
  /// });
  /// ```
  final Map<String, dynamic>? parameters;

  /// How to create the value.
  ///
  /// - true, is created when first read.
  /// - false, is immediately created.
  /// - null, defined by [lazyDefault].
  final bool? lazy;

  /// How [lazy] should behave when `null`.
  ///
  /// - By default, sync providers are lazy and async are not.
  ///
  /// You can override this behavior:
  /// ```dart
  /// ProvideRef.lazyDefault = (_) => true; // always lazy (when null)
  /// ```
  static LazyDefault lazyDefault = (state) => !state.isAsync;

  /// Creates a [ProvideRef] with a constant value.
  ///
  /// The [value] parameter is the constant value to be provided.
  ///
  /// The [updateShouldNotify] parameter is an optional callback that determines
  /// whether listeners should be notified when [value] changes.
  ///
  /// The [key] parameter is an optional key for the ref.
  const ProvideRef.value(
    T this.value, {
    this.updateShouldNotify,
    super.key,
  })  : lazy = false,
        create = null,
        dispose = null,
        parameters = null;

  /// An already created [value].
  final T? value;

  /// Whether to notify dependents when the value changes.
  final bool Function(T prev, T next)? updateShouldNotify;

  @override
  AsyncBind<T, ProvideRef<T>> createBind() => ProvideBind<T>();
}

class ProvideBind<T> extends AsyncBind<T, ProvideRef<T>> with Scope {
  Future<T>? _future;

  /// Whether value is created lazily.
  bool get lazy => ref.lazy ?? ProvideRef.lazyDefault(this);

  /// Whether the [ref] is async.
  bool get isAsync {
    if (ref.value is Future || ref.value is Stream) return true;
    return injector?.isAsync == true;
  }

  @override
  Future<T>? get future => _future;

  @override
  void initBind() {
    if (!lazy) load();
    super.initBind();
  }

  @override
  bool updateShouldNotify(ProvideRef<T> oldRef) {
    var didChange = oldRef.value != ref.value;

    if ((oldRef.value, ref.value) case (var prev?, var next?)) {
      didChange = ref.updateShouldNotify?.call(prev, next) ?? prev != next;
    }

    if (didChange) {
      load();
    }

    return didChange;
  }

  @override
  void create() {
    _future = null;

    final value = ref.value ?? injector!(ref.parameters);

    if (value is Future<T>) {
      _future = value;
    } else {
      snapshot = AsyncSnapshot.withData(ConnectionState.none, value);
    }
  }

  @override
  void dispose() {
    if (snapshot.data is T) {
      ref.dispose?.call(snapshot.data as T);
    }
    super.dispose();
  }

  @override
  T read() {
    value; // init lazy

    if (snapshot.hasData) {
      return super.read();
    }
    if (snapshot.isLoading) {
      throw LoadingProvideException('$type is loading.');
    }

    final e = snapshot.error;
    assert(
      e is! InjectorError,
      '''
InjectorError: ${e.message}.

Did you provide the missing type?
context.provide<${e.expectedT}>(...); // <- provide it
        ''',
    );

    throw ErrorProvideException('$type got error: $e');
  }

  @override
  String get debugLabel {
    var lazy = this.lazy ? 'lazy ' : '';
    if (isAsync) lazy += 'async';
    lazy = lazy.trim();
    if (lazy.isNotEmpty) lazy = '($lazy)';

    return 'context.provide<$type> $lazy';
  }
}

class LoadingProvideException implements Exception {
  LoadingProvideException(this.message);
  final String message;

  @override
  String toString() => 'LoadingProvideException: $message';
}

class ErrorProvideException implements Exception {
  ErrorProvideException(this.message);
  final String message;

  @override
  String toString() => 'ErrorProvideException: $message';
}
