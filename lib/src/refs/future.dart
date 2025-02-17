import 'dart:async';

import 'package:flutter/widgets.dart';

import 'async.dart';
import 'ref.dart';

class FutureRef<T> extends AsyncRef<T> {
  const FutureRef(
    this.create, {
    super.initialData,
    super.key,
  });

  /// How to create the value.
  final FutureOr<T> Function() create;

  @override
  AsyncSnapshot<T> bind(BuildContext context) => context.bind(this);

  @override
  AsyncRefState<T, FutureRef<T>> createState() => FutureRefState<T>();
}

class FutureRefState<T> extends AsyncRefState<T, FutureRef<T>> {
  Future<T>? _future;

  @override
  Future<T>? get future => _future;

  @override
  void initState() {
    load();
    super.initState();
  }

  @override
  void create() {
    final value = ref.create();
    if (value is Future<T>) {
      _future = value;
    } else {
      snapshot = AsyncSnapshot.withData(ConnectionState.done, value);
    }
  }

  @override
  AsyncSnapshot<T> bind(BuildContext context) => snapshot;

  @override
  T read(BuildContext context) => snapshot.data as T;
}
