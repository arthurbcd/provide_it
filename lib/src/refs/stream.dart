import 'package:flutter/widgets.dart';
import 'package:provide_it/src/core.dart';

import 'async.dart';

class StreamRef<T> extends AsyncRef<T> {
  const StreamRef(
    Stream<T> Function() this.create, {
    super.initialData,
    super.key,
  }) : value = null;

  /// How to create the stream.
  final Stream<T> Function()? create;

  const StreamRef.value(
    Stream<T> this.value, {
    super.initialData,
    super.key,
  }) : create = null;

  /// The stream to use.
  final Stream<T>? value;

  @override
  AsyncSnapshot<T> bind(BuildContext context) => context.bind(this);

  @override
  AsyncRefState<T, StreamRef<T>> createState() => StreamRefState<T>();
}

class StreamRefState<T> extends AsyncRefState<T, StreamRef<T>> {
  Stream<T>? _stream;

  @override
  Stream<T>? get stream => _stream;

  @override
  bool get shouldNotifySelf => true;

  @override
  void initState() {
    load();
    super.initState();
  }

  @override
  void create() {
    _stream = ref.value ?? ref.create!();
  }

  @override
  AsyncSnapshot<T> bind() => snapshot;

  @override
  T read() => snapshot.data as T;
}
