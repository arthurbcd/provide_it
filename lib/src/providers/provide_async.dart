import 'dart:async';

import 'package:provide_it/src/framework.dart';

import '../injector/injector.dart';

extension ContextProvideAsync on BuildContext {
  /// Provides the future value of [create].
  void provideAsync<T>(
    FutureOr<T> create(), {
    void dispose(T value)?,
    bool lazy = false,
    Object? key,
  }) {
    bind(_InheritedAsync<T>(key: key, create, dispose: dispose, lazy: lazy));
  }
}

class _InheritedAsync<T> extends InheritedProvider<T> {
  const _InheritedAsync(this.create, {this.dispose, this.lazy, super.key});

  final FutureOr<T> Function() create;
  final void Function(T value)? dispose;
  final bool? lazy;

  @override
  InheritedState<T, _InheritedAsync<T>> createState() => _InheritedAsyncState();
}

typedef _Error = (Object error, StackTrace stackTrace);

class _InheritedAsyncState<T> extends InheritedState<T, _InheritedAsync<T>> {
  @override
  String get debugLabel => 'provideAsync<$T>';

  bool _created = false;
  FutureOr<T>? _value;
  _Error? _error;

  @override
  void initState() {
    super.initState();
    if (provider.lazy == false) {
      _create();
    }
  }

  void _create() {
    _value = provider.create();
    _created = true;

    if (_value case Future<T> future) {
      future.then(
        (T data) {
          if (future != _value) return;

          _value = data;
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
    if (_value case T value) {
      provider.dispose?.call(value);
    }
    _value = null;
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
