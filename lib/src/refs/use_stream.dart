import 'async.dart';

class UseStreamRef<T> extends AsyncRef<T> {
  const UseStreamRef(
    Stream<T> Function() this.create, {
    super.initialData,
    super.key,
  }) : value = null;

  @override
  final Stream<T> Function()? create;

  const UseStreamRef.value(
    Stream<T> this.value, {
    super.initialData,
    super.key,
  }) : create = null;

  /// An already created [Stream].
  final Stream<T>? value;

  @override
  AsyncBind<T, UseStreamRef<T>> createBind() => UseStreamBind<T>();
}

class UseStreamBind<T> extends AsyncBind<T, UseStreamRef<T>> {
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
