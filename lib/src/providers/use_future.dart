import 'dart:async';

import '../framework.dart';

extension ContextUseFuture on BuildContext {
  /// Creates and subscribes to the [Future] of [create] and returns its snapshot.
  AsyncSnapshot<T> useFuture<T>(
    FutureOr<T>? create(), {
    T? initialData,
    Object? key,
  }) {
    return bind(_FutureHook(create, initialData: initialData, key: key));
  }

  /// Subscribes to an already created [Future] and returns its snapshot.
  @Deprecated('Use Future.watch() instead.')
  AsyncSnapshot<T> useFutureValue<T>(FutureOr<T>? future, {T? initialData}) {
    return bind(_FutureHook.value(future, initialData: initialData));
  }
}

extension FutureWatch<T> on Future<T> {
  /// Subscribes to this [Future] and returns its snapshot.
  AsyncSnapshot<T> watch(BuildContext context, {T? initialData}) {
    return context.bind(_FutureHook.value(this, initialData: initialData));
  }
}

class _FutureHook<T> extends HookProvider<AsyncSnapshot<T>> {
  const _FutureHook(this.create, {this.initialData, super.key}) : value = null;
  const _FutureHook.value(this.value, {this.initialData}) : create = null;

  final FutureOr<T>? Function()? create;
  final FutureOr<T>? value;
  final T? initialData;

  @override
  _FutureHookState<T> createState() => _FutureHookState();
}

class _FutureHookState<T> extends HookState<AsyncSnapshot<T>, _FutureHook<T>> {
  @override
  String get debugLabel => switch (provider.create) {
    null => 'useFutureValue<$T>',
    _ => 'useFuture<$T>',
  };

  Object? _activeCallbackIdentity;
  late AsyncSnapshot<T> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = provider.initialData == null
        ? AsyncSnapshot<T>.nothing()
        : AsyncSnapshot<T>.withData(
            ConnectionState.none,
            provider.initialData as T,
          );
    _subscribe();
  }

  @override
  void didUpdateProvider(oldProvider) {
    super.didUpdateProvider(oldProvider);
    if (oldProvider.value != provider.value ||
        (provider.create == null) != (oldProvider.create == null)) {
      if (_activeCallbackIdentity != null) {
        _unsubscribe();
        _snapshot = _snapshot.inState(ConnectionState.none);
      }
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    if (provider.create == null && provider.value == null) return;
    final future = (provider.create?.call() ?? provider.value) as FutureOr<T>;

    if (future is! Future<T>) {
      _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, future);
      return;
    }

    final callbackIdentity = Object();
    _activeCallbackIdentity = callbackIdentity;
    future.then<void>(
      (T data) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, data);
          });
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withError(
              ConnectionState.done,
              error,
              stackTrace,
            );
          });
        }
        assert(() {
          if (FutureBuilder.debugRethrowError) {
            Future<Object>.error(error, stackTrace);
          }
          return true;
        }());
      },
    );
    if (_snapshot.connectionState != ConnectionState.done) {
      _snapshot = _snapshot.inState(ConnectionState.waiting);
    }
  }

  void _unsubscribe() {
    _activeCallbackIdentity = null;
  }

  @override
  AsyncSnapshot<T> build(BuildContext context) {
    return _snapshot;
  }
}
