import 'package:flutter/widgets.dart';
import 'package:provide_it/src/core.dart';

import '../async.dart';
import 'provider.dart';

@Deprecated('Use `FutureRef` or `context.future` instead.')
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

  /// How to create the value.
  final Create<Future<T>>? create;

  /// The internal [Future.catchError].
  final T Function(BuildContext, Object error)? catchError;

  /// Whether to notify dependents when the value changes.
  /// Defaults to `(T prev, T next) => prev != next`.
  final UpdateShouldNotify<T>? updateShouldNotify;

  /// Whether to create the value only when it's first called.
  final bool? lazy;

  @Deprecated('Use `FutureRef.value` or `context.futureValue` instead.')
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

  @Deprecated('Use `context.read/watch` instead.')
  static T of<T>(BuildContext context, {bool listen = true, Object? key}) {
    return listen ? context.watch(key: key) : context.read(key: key);
  }

  @override
  AsyncRefState<T, FutureProvider<T>> createState() => FutureProviderState<T>();
}

class FutureProviderState<T> extends AsyncRefState<T, FutureProvider<T>> {
  late var _future = ref.create?.call(context) ?? ref.future;

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
  void initState() {
    if (ref.lazy == false) create();
    super.initState();
  }

  @override
  void create() {
    _future = ref.create?.call(context) ?? ref.future;
  }

  @override
  T read(BuildContext context) {
    _future;

    return snapshot.data as T;
  }
}
