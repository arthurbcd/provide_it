import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provide_it/src/core.dart';
import 'package:provide_it/src/refs/ref_widget.dart';

import '../framework.dart';
import 'ref.dart';

abstract class AsyncRef<T> extends Ref<T> {
  const AsyncRef({this.initialData, super.key});
  final T? initialData;

  Future<void> reload(BuildContext context) => context.reload(key: this);

  @override
  AsyncRefState<T, AsyncRef<T>> createState();
}

abstract class AsyncRefWidget<T> extends RefWidget<T> implements AsyncRef<T> {
  const AsyncRefWidget({
    super.key,
    this.initialData,
    super.builder,
    super.child,
  });

  @override
  final T? initialData;

  @override
  Future<void> reload(BuildContext context) => context.reload(key: this);

  @override
  AsyncRefState<T, AsyncRef<T>> createState();
}

abstract class AsyncRefState<T, R extends AsyncRef<T>> extends RefState<T, R> {
  late var _snapshot = switch (ref.initialData) {
    var data? => AsyncSnapshot.withData(ConnectionState.none, data),
    null => AsyncSnapshot<T>.nothing(),
  };
  StreamSubscription<T>? _subscription;

  set snapshot(AsyncSnapshot<T> snapshot) {
    _snapshot = snapshot;
    notifyDependents();
  }

  /// The current [future] state.
  AsyncSnapshot<T> get snapshot => _snapshot;

  /// The future created by [create].
  Future<T>? get future => null;

  /// The stream created by [create].
  Stream<T>? get stream => null;

  /// Loads the value. Creates a new [future] or [snapshot].
  ///
  /// Awaiting this will complete when [future] or [stream] is done.
  Future<void> load() async {
    _subscription?.cancel();

    assert(future == null || stream == null);
    create();

    if (future case var future?) {
      snapshot = _snapshot.inState(ConnectionState.waiting);

      return future.then((value) {
        snapshot = AsyncSnapshot.withData(ConnectionState.done, value);
      }).catchError((e, s) {
        snapshot = AsyncSnapshot.withError(ConnectionState.done, e, s);
      });
    }

    if (stream case var stream?) {
      snapshot = _snapshot.inState(ConnectionState.waiting);

      _subscription = stream.listen((value) {
        snapshot = AsyncSnapshot.withData(ConnectionState.active, value);
      }, onError: (e, s) {
        snapshot = AsyncSnapshot.withError(ConnectionState.active, e, s);
      }, onDone: () {
        snapshot = _snapshot.inState(ConnectionState.done);
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
