import 'dart:async';

import '../framework.dart';
import '../injector/injector.dart';

extension ContextProvide on BuildContext {
  /// Provides [T] using [create], auto-injecting any previously provided types.
  ///
  /// Use [parameters] with a [Symbol] to manually provide or override by name or type:
  /// ```dart
  /// final user = User(id: '123');
  /// context.provide(UserNotifier.new, parameters: {
  ///   #userId: user.id, // by parameter name
  ///   #User: user, // by parameter type
  /// });
  /// ```
  ///
  /// Or classic approach with an arrow function:
  /// ```dart
  /// context.provide(() => UserNotifier(userId: user.id));
  /// ```
  void provide<T>(
    Function create, {
    void dispose(T value)?,
    Map<Symbol, dynamic>? parameters,
    bool lazy = true,
    Object? key,
  }) {
    assert(create is! Future<T> Function(), 'Use provideAsync instead.');
    bind(
      _Provide(
        key: key,
        create,
        dispose: dispose,
        parameters: parameters,
        lazy: lazy,
      ),
    );
  }
}

class _Provide<T> extends InheritedProvider<T> {
  const _Provide(
    this.constructor, {
    this.parameters,
    this.dispose,
    super.lazy,
    super.key,
  });

  final Function constructor;
  final void Function(T value)? dispose;
  final Map<Symbol, dynamic>? parameters;

  @override
  InheritedState<T, _Provide<T>> createState() => _ProvideState();
}

typedef _Error = (Object error, StackTrace stackTrace);

class _ProvideState<T> extends InheritedState<T, _Provide<T>> {
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
