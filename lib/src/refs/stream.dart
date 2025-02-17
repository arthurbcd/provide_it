import 'package:flutter/widgets.dart';

import 'async.dart';
import 'ref.dart';

class StreamRef<T> extends AsyncRef<T> {
  const StreamRef(
    this.create, {
    super.initialData,
    super.key,
  });

  /// How to create the value.
  final Stream<T> Function() create;

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
  void initState() {
    load();
    super.initState();
  }

  @override
  void create() {
    _stream = ref.create();
  }

  @override
  AsyncSnapshot<T> bind(BuildContext context) => snapshot;

  @override
  T read(BuildContext context) => snapshot.data as T;
}
