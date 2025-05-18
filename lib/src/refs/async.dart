import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provide_it/src/refs/ref_widget.dart';

import '../framework.dart';
import 'ref.dart';

abstract class AsyncRef<T> extends Ref<T> {
  const AsyncRef({this.initialData, super.key});
  final T? initialData;

  @override
  AsyncBind<T, AsyncRef<T>> createBind();
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
  AsyncBind<T, AsyncRef<T>> createBind();
}

abstract class AsyncBind<T, R extends AsyncRef<T>> extends Bind<T, R> {
  late var _snapshot = switch (ref.initialData) {
    var data? => AsyncSnapshot.withData(ConnectionState.none, data),
    null => AsyncSnapshot<T>.nothing(),
  };
  StreamSubscription? _subscription;
  var _completer = Completer<T?>();
  bool _didLoad = false;
  bool _canNotify = false;

  set snapshot(AsyncSnapshot<T> snapshot) {
    _snapshot = snapshot;

    if (snapshot.connectionState == ConnectionState.done) {
      snapshot.hasError
          ? _completer.completeError(snapshot.error!, snapshot.stackTrace!)
          : _completer.complete(snapshot.data);
    }

    // we prevent notifying when not ready
    if (_canNotify) notifyObservers();
  }

  /// The current [future] state.
  AsyncSnapshot<T> get snapshot => _snapshot;

  /// The future created by [create].
  Future<T>? get future => null;

  /// The stream created by [create].
  Stream<T>? get stream => null;

  /// The future when [read] is [isReady] to read it.
  /// Won't trigger lazy refs.
  FutureOr<void> isReady() {
    if (!_didLoad) return null;
    if (snapshot.hasData) return null;

    return _completer.future as Future<void>;
  }

  /// Loads the value. Creates a new [future] or [snapshot].
  ///
  /// Awaiting this will complete when [future] or [stream] is done.
  @protected
  Future<void> load() async {
    final old = (future: future, stream: stream);

    try {
      create();
    } on AssertionError catch (_) {
      rethrow;
    } catch (e, s) {
      snapshot = AsyncSnapshot.withError(ConnectionState.done, e, s);
    }

    assert(future == null || stream == null, 'Only one future/stream allowed');
    _didLoad = true;
    _completer = Completer<T?>();

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

    // we prevent notifications while building
    WidgetsBinding.instance.addPostFrameCallback((_) => _canNotify = true);
  }

  @protected
  FutureOr<T> readAsync() {
    if (!_didLoad) load();
    if (snapshot.hasData) return snapshot.data as T;

    // if `data as T` throws, then it's probably a Stream.empty.
    return _completer.future.then((data) => data as T);
  }

  @override
  AsyncSnapshot<T> watch(BuildContext context) {
    super.watch(context);

    return snapshot;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void create();

  @override
  T read() {
    if (!_didLoad) load();
    return super.read();
  }

  @override
  T? get value {
    // even listen/read<T?> should init lazy values
    stream;
    future;
    return snapshot.data;
  }
}
