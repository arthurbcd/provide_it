import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provide_it/src/core.dart';

import 'async.dart';

class FutureRef<T> extends AsyncRef<T> {
  const FutureRef(
    FutureOr<T> Function() this.create, {
    super.initialData,
    super.key,
  }) : value = null;

  /// How to create the value.
  final FutureOr<T> Function()? create;

  const FutureRef.value(
    FutureOr<T> this.value, {
    super.initialData,
    super.key,
  }) : create = null;

  /// How to create the value.
  final FutureOr<T>? value;

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
  bool get shouldNotifySelf => true;

  @override
  void initState() {
    load();
    super.initState();
  }

  @override
  void create() {
    final value = ref.value ?? ref.create!();

    if (value is Future<T>) {
      _future = value;
    } else {
      snapshot = AsyncSnapshot.withData(ConnectionState.done, value);
    }
  }

  @override
  AsyncSnapshot<T> bind() => snapshot;

  @override
  T read() => snapshot.data as T;
}
