import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provide_it/src/refs/ref_widget.dart';

import '../framework.dart';
import 'ref.dart';

abstract class AsyncRef<T> extends Ref<T> {
  const AsyncRef({this.initialData, super.key});
  final T? initialData;

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
  AsyncRefState<T, AsyncRef<T>> createState();
}

abstract class AsyncRefState<T, R extends AsyncRef<T>> extends RefState<T, R> {
  late var _snapshot = switch (ref.initialData) {
    var data? => AsyncSnapshot.withData(ConnectionState.none, data),
    null => AsyncSnapshot<T>.nothing(),
  };
  StreamSubscription? _subscription;
  var _completer = Completer<T>();
  bool _hasLoaded = false;

  set snapshot(AsyncSnapshot<T> snapshot) {
    _snapshot = snapshot;

    if (snapshot.connectionState == ConnectionState.done) {
      snapshot.hasError
          ? _completer.completeError(snapshot.error!, snapshot.stackTrace!)
          : _completer.complete(snapshot.data as T);
    }
    notifyDependents();
  }

  @override
  T? get value => snapshot.data;

  /// The current [future] state.
  AsyncSnapshot<T> get snapshot => _snapshot;

  /// The future created by [create].
  Future<T>? get future => null;

  /// The stream created by [create].
  Stream<T>? get stream => null;

  /// The future when [read] is [isReady] to read it.
  /// Won't trigger lazy refs.
  FutureOr<void> isReady() {
    if (!_hasLoaded) return null;
    if (snapshot.hasData) return null;

    return _completer.future as Future<void>;
  }

  /// Loads the value. Creates a new [future] or [snapshot].
  ///
  /// Awaiting this will complete when [future] or [stream] is done.
  @protected
  Future<void> load() async {
    _hasLoaded = true;
    _completer = Completer<T>();

    final old = (future: future, stream: stream);
    create();
    assert(future == null || stream == null, 'No async operations created');

    if (future case var future? when old.future != future) {
      snapshot = _snapshot.inState(ConnectionState.waiting);

      future.then((value) {
        if (this.future != future) return;
        snapshot = AsyncSnapshot.withData(ConnectionState.done, value);
      }).catchError((e, s) {
        if (this.future != future) return;
        snapshot = AsyncSnapshot.withError(ConnectionState.done, e, s);
      });
    }

    if (stream case var stream? when old.stream != stream) {
      snapshot = _snapshot.inState(ConnectionState.waiting);

      _subscription?.cancel();
      _subscription = stream.listen((value) {
        snapshot = AsyncSnapshot.withData(ConnectionState.active, value);
      }, onError: (e, s) {
        snapshot = AsyncSnapshot.withError(ConnectionState.active, e, s);
      }, onDone: () {
        if (this.stream != stream) return;
        snapshot = _snapshot.inState(ConnectionState.done);
      });
    }
  }

  @protected
  FutureOr<T> readAsync() {
    if (!_hasLoaded) load();
    if (snapshot.hasData) return snapshot.data as T;

    return _completer.future;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
