import 'async.dart';

class StreamRef<T> extends AsyncRef<T> {
  const StreamRef(
    Stream<T> Function() this.create, {
    super.initialData,
    super.key,
  }) : value = null;

  @override
  final Stream<T> Function()? create;

  const StreamRef.value(
    Stream<T> this.value, {
    super.initialData,
    super.key,
  }) : create = null;

  /// An already created [Stream].
  final Stream<T>? value;

  @override
  AsyncBind<T, StreamRef<T>> createBind() => StreamBind<T>();
}

class StreamBind<T> extends AsyncBind<T, StreamRef<T>> {
  Stream<T>? _stream;

  @override
  Stream<T>? get stream => _stream;

  @override
  void initBind() {
    load();
    super.initBind();
  }

  @override
  void create() {
    _stream = ref.value ?? ref.create!();
  }
}
