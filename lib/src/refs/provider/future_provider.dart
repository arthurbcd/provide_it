import 'package:flutter/widgets.dart';
import 'package:provide_it/src/framework.dart';

import '../async.dart';
import 'provider.dart';

@Deprecated('Use `context.useFuture` instead.')
class FutureProvider<T> extends AsyncRefWidget<T> {
  const FutureProvider({
    super.key,
    this.create,
    super.initialData,
    this.catchError,
    this.updateShouldNotify,
    this.lazy,
    super.builder,
    super.child,
  }) : future = null;

  @override
  final Create<Future<T>>? create;

  /// The internal [Future.catchError].
  final T Function(BuildContext, Object error)? catchError;

  /// Whether to notify dependents when the value changes.
  /// Defaults to `(T prev, T next) => prev != next`.
  final UpdateShouldNotify<T>? updateShouldNotify;

  /// Whether to create the value only when it's first called.
  final bool? lazy;

  @Deprecated('Use `context.useFuture` instead.')
  const FutureProvider.value({
    super.key,
    this.future,
    super.initialData,
    this.updateShouldNotify,
    this.catchError,
    super.builder,
    super.child,
  })  : create = null,
        lazy = null;

  /// The value to provide.
  final Future<T>? future;

  @override
  AsyncBind<T, FutureProvider<T>> createBind() => FutureProviderState<T>();
}

class FutureProviderState<T> extends AsyncBind<T, FutureProvider<T>>
    with Scope {
  Future<T>? _future;

  @override
  set snapshot(AsyncSnapshot<T> snapshot) {
    final data = (super.snapshot.data, snapshot.data);
    if (data case (var prev?, var next?)) {
      ref.updateShouldNotify?.call(prev, next);
    }
    super.snapshot = snapshot;
  }

  @override
  Future<T>? get future => _future;

  @override
  void initBind() {
    if (ref.lazy == false) load();
    super.initBind();
  }

  @override
  void create() {
    _future = ref.create?.call(context) ?? ref.future;
  }
}
