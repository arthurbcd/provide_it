import 'dart:async';

import '../framework.dart';

extension ContextProvideAsync on BuildContext {
  /// Provides the future value of [create].
  void provideAsync<T>(
    FutureOr<T> create(), {
    void dispose(T value)?,
    bool lazy = false,
    Object? key,
  }) {
    bind(_ProvideAsync(key: key, create, dispose: dispose, lazy: lazy));
  }
}

class _ProvideAsync<T> extends InheritedProvider<T> {
  const _ProvideAsync(this.create, {this.dispose, super.lazy, super.key});

  final FutureOr<T> Function() create;
  final void Function(T value)? dispose;

  @override
  InheritedState<T, _ProvideAsync<T>> createState() => _ProvideAsyncState();
}

typedef _Error = (Object error, StackTrace stackTrace);

class _ProvideAsyncState<T> extends InheritedState<T, _ProvideAsync<T>> {
  @override
  String get debugLabel => 'provideAsync<$T>';

  bool _created = false;
  FutureOr<T>? _value;
  _Error? _error;

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
      Error.throwWithStackTrace(error, stackTrace);
    }

    return _value as FutureOr<T>;
  }
}
