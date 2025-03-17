import 'dart:async';

import 'package:flutter/widgets.dart';

import 'async.dart';

class FutureRef<T> extends AsyncRef<T> {
  const FutureRef(
    FutureOr<T> Function() this.create, {
    super.initialData,
    super.key,
  }) : value = null;

  @override
  final FutureOr<T> Function()? create;

  const FutureRef.value(
    FutureOr<T> this.value, {
    super.initialData,
    super.key,
  }) : create = null;

  /// An already created [value].
  final FutureOr<T>? value;

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
    final value = ref.create != null ? ref.create!() : ref.value as T;

    if (value is Future<T>) {
      _future = value;
    } else {
      snapshot = AsyncSnapshot.withData(ConnectionState.done, value);
    }
  }
}
