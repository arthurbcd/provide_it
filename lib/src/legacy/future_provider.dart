part of '../legacy.dart';

class FutureProvider<T> extends ProviderWidget<T> {
  @Deprecated('Use `context.provide` or `context.useFuture` instead.')
  const FutureProvider({
    super.key,
    this.create,
    this.initialData,
    this.catchError,
    this.updateShouldNotify,
    super.lazy,
    super.builder,
    super.child,
  }) : future = null;

  @Deprecated('Use `context.provideValue` instead.')
  const FutureProvider.value({
    super.key,
    this.future,
    this.initialData,
    this.updateShouldNotify,
    this.catchError,
    super.builder,
    super.child,
  }) : create = null;

  final Create<Future<T>>? create;
  final T? initialData;

  /// The internal [Future.catchError].
  final T Function(BuildContext, Object error)? catchError;

  /// Whether to notify dependents when the value changes.
  /// Defaults to `(T prev, T next) => prev != next`.
  final UpdateShouldNotify<T>? updateShouldNotify;

  /// The value to provide.
  final Future<T>? future;

  @override
  InheritedState<T, FutureProvider<T>> createState() =>
      _FutureInheritedState<T>();
}

typedef _Error = (Object error, StackTrace stackTrace);

class _FutureInheritedState<T> extends InheritedState<T, FutureProvider<T>> {
  @override
  String get debugLabel => 'FutureProvider<$T>';

  FutureOr<T>? _value;
  _Error? _error;
  bool _created = false;

  @override
  void initState() {
    super.initState();
    _value = provider.initialData;
    if (provider.lazy == false) {
      _subscribe();
    }
  }

  @override
  void updated(oldProvider) {
    if (oldProvider.future != provider.future ||
        (provider.create == null) != (oldProvider.create == null)) {
      if (_value is Future<T>) {
        _unsubscribe();
      }
    }
    _subscribe();
    super.updated(oldProvider);
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    final future = _value = provider.create?.call(context) ?? provider.future;
    _created = true;

    if (future == null) return;

    future.then<void>(
      (T data) {
        if (future == _value) {
          _value = data;
          notifyDependents();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (future == _value) {
          _value = null;
          _error = (error, stackTrace);
          notifyDependents();
        }
        assert(() {
          if (FutureBuilder.debugRethrowError) {
            Future<Object>.error(error, stackTrace);
          }
          return true;
        }());
      },
    );
  }

  void _unsubscribe() {
    _value = null;
  }

  @override
  FutureOr<void> isReady() => _value;

  @override
  FutureOr<T> read() {
    if (!_created) {
      _subscribe();
    }
    if (_error case (Object error, StackTrace stackTrace)) {
      Error.throwWithStackTrace(error, stackTrace);
    }
    return _value as FutureOr<T>;
  }
}
