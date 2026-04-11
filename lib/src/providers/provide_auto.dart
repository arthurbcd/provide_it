import 'dart:async';

import 'package:provide_it/src/framework.dart';

import '../injector/injector.dart';

extension ContextProvideAuto on BuildContext {
  /// Provides [T] using [constructor], auto-injecting any previously provided types.
  ///
  /// Use [parameters] with a [Symbol] to manually provide or override by name or type:
  /// ```dart
  /// final user = User(id: '123');
  /// context.provideAuto(UserNotifier.new, parameters: {
  ///   #userId: user.id, // by parameter name
  ///   #User: user, // by parameter type
  /// });
  /// ```
  void provideAuto<T>(
    Function constructor, {
    void dispose(T value)?,
    Map<Symbol, dynamic>? parameters,
    bool lazy = true,
    Object? key,
  }) {
    assert(constructor is! Future<T> Function(), 'Use provideAsync instead.');
    bind(
      _ProvideAuto(
        key: key,
        constructor,
        dispose: dispose,
        parameters: parameters,
        lazy: lazy,
      ),
    );
  }
}

class _ProvideAuto<T> extends InheritedProvider<T> {
  /// The `provide` automatically injects dependencies using `constructor`.
  /// The `constructor` function represents the constructor of the dependency to be provided.
  /// ```dart
  /// context.provide(ProductNotifier.new);
  /// ```
  ///
  /// The optional parameters are:
  /// - `dispose`: A function to dispose of the provider.
  /// - `lazy`: If true, the provider is lazily initialized. Defaults to false.
  /// - `parameters`: Additional parameters for the provider.
  /// - `key`: An optional key for the provider.
  ///
  const _ProvideAuto(
    this.constructor, {
    this.parameters,
    this.dispose,
    super.lazy,
    super.key,
  });

  final Function constructor;

  /// How to dispose the value.
  final void Function(T value)? dispose;

  /// The [Injector.parameters] to manually pass to [constructor].
  /// Ex:
  /// ```dart
  /// context.provide(ProductNotifier.new, parameters: {
  ///   'productId': '123',
  /// });
  /// ```
  final Map<Symbol, dynamic>? parameters;

  @override
  InheritedState<T, _ProvideAuto<T>> createState() => _ProvideState();
}

typedef _Error = (Object error, StackTrace stackTrace);

class _ProvideState<T> extends InheritedState<T, _ProvideAuto<T>> {
  @override
  String get debugLabel => 'provide<$type>';

  @override
  String get type => _injector.type;

  FutureOr<T>? _value;
  _Error? _error;
  bool _created = false;

  late final _injector = Injector<T>(
    provider.constructor,
    locator: (p) {
      return (scope as ScopeIt).readAsync(context: context, type: p.type);
    },
  );

  void _create() {
    _created = true;
    _value = _injector(provider.parameters);

    // provideAuto is not async, but if it depends on a provideAsync, it
    // can return a Future. In that case, we wait for it.
    if (_value case Future<T> future) {
      future.then(
        (T value) {
          if (future != _value) return;

          _value = value;
          _error = null;
          notifyDependents();
        },
        onError: (Object error, StackTrace stackTrace) {
          if (future != _value) return;

          _value = null;
          _error = (error, stackTrace);
          notifyDependents();
        },
      );
    }
  }

  @override
  void dispose() {
    if (_value case T value when _created) {
      provider.dispose?.call(value);
    }
    super.dispose();
  }

  @override
  FutureOr<void> isReady() => _value;

  @override
  FutureOr<T> read() {
    if (!_created) {
      _create();
    }
    if (_error case (Object error, StackTrace stackTrace)) {
      assert(error is! InjectorError, '''
InjectorError: ${error.message}.

Did you provide the missing type?
context.provide<${error.expectedT}>(...); // <- provide it
        ''');
      Error.throwWithStackTrace(error, stackTrace);
    }

    return _value as FutureOr<T>;
  }
}
