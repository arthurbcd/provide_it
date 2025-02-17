import 'package:flutter/widgets.dart';

import '../framework.dart';
import '../injector/injector.dart';
import 'async.dart';

class ProvideRef<T> extends AsyncRef<T> {
  const ProvideRef(
    Function this.create, {
    this.dispose,
    this.lazy = false,
    this.factory = false,
    this.parameters,
    super.key,
  })  : value = null,
        updateShouldNotify = null,
        assert(!lazy || !factory, 'Cannot be both lazy and factory.');

  /// How to create the value.
  final Function? create;

  /// How to dispose the value.
  final void Function(T value)? dispose;

  /// The [Injector.parameters] to pass to [create].
  final Map<String, dynamic>? parameters;

  /// Whether to create the value only when it's first called.
  final bool lazy;

  /// Whether to create a new instance each time.
  final bool factory;

  /// Directly provide a value.
  const ProvideRef.value(
    T this.value, {
    this.updateShouldNotify,
    super.key,
  })  : create = null,
        lazy = false,
        factory = false,
        dispose = null,
        parameters = null;

  /// The value to provide.
  final T? value;

  /// Whether to notify dependents when the value changes.
  final bool Function(T, T)? updateShouldNotify;

  @override
  AsyncRefState<T, ProvideRef<T>> createState() => ProvideRefState<T>();
}

class ProvideRefState<T> extends AsyncRefState<T, ProvideRef<T>> {
  var _created = false;
  Injector? _injector;
  Future<T>? _future;
  Stream<T>? _stream;

  @override
  String get type => _injector?.type ?? T.type;

  @override
  Future<T>? get future => _future;

  @override
  Stream<T>? get stream => _stream;

  @override
  bool updateShouldNotify(ProvideRef<T> oldRef) {
    var didChange = oldRef.value != ref.value;

    if ((oldRef.value, ref.value) case (var prev?, var next?)) {
      didChange = ref.updateShouldNotify?.call(prev, next) ?? prev != next;
    }

    if (didChange) {
      create();
    }

    return didChange;
  }

  @override
  void create() {
    _injector = _stream = _future = null;

    if (ref.create != null) {
      _injector = Injector(ref.create!, parameters: ref.parameters);
    }

    final value = _injector?.call() ?? ref.value;

    if (value is Future<T>) {
      _future = value;
    } else if (value is Stream<T>) {
      _stream = value;
    } else if (value is T) {
      snapshot = AsyncSnapshot.withData(ConnectionState.none, value);
    }

    _created = true;
  }

  @override
  void initState() {
    if (!ref.lazy && !ref.factory) load();
    super.initState();
  }

  @override
  void dispose() {
    if (!ref.factory && snapshot.data is T) {
      (ref.dispose ?? tryDispose)(snapshot.data as T);
    }
    super.dispose();
  }

  @override
  T read(BuildContext context) {
    if (ref.factory || !_created) load();
    if (snapshot.data case T data) return data;

    return snapshot.requireData;
  }

  @override
  T of(BuildContext context, {bool listen = true}) {
    assert(!ref.factory || !listen, 'Cannot listen to factory values.');
    return super.of(context, listen: listen);
  }

  @override
  String get debugLabel {
    var async = '';
    if (future != null) async = '(future)';
    if (stream != null) async = '(stream)';

    final label = switch ((ref.lazy, ref.factory)) {
      (_, true) => 'provideFactory',
      (true, _) => 'provideLazy',
      _ => '',
    };

    return 'context.provide$label<$type> $async';
  }
}
