import 'dart:async';

import 'package:flutter/widgets.dart';

import 'async.dart';

class UseFutureRef<T> extends AsyncRef<T> {
  const UseFutureRef(
    FutureOr<T> Function() this.create, {
    super.initialData,
    super.key,
  }) : value = null;

  @override
  final FutureOr<T> Function()? create;

  const UseFutureRef.value(
    FutureOr<T> this.value, {
    super.initialData,
    super.key,
  }) : create = null;

  /// An already created [value].
  final FutureOr<T>? value;

  @override
  AsyncBind<T, UseFutureRef<T>> createBind() => UseFutureBind<T>();
}

class UseFutureBind<T> extends AsyncBind<T, UseFutureRef<T>> {
  Future<T>? _future;

  @override
  Future<T>? get future => _future;

  @override
  void initBind() {
    load();
    super.initBind();
  }

  @override
  void create() {
    final value = ref.create != null ? ref.create!() : ref.value!;

    if (value is Future<T>) {
      _future = value;
    } else {
      snapshot = AsyncSnapshot.withData(ConnectionState.done, value);
    }
  }
}
