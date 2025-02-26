import 'dart:async';

import 'package:flutter/widgets.dart';

import '../framework.dart';
import '../injector/injector.dart';
import 'async.dart';

class ProvideRef<T> extends AsyncRef<T> {
  /// A reference to a provider with various configuration options.
  ///
  /// The `ProvideRef` class allows you to create a reference to a provider
  /// with specific behaviors such as lazy initialization and factory creation.
  ///
  /// The `create` function is required and is used to create the provider.
  ///
  /// The optional parameters are:
  /// - `dispose`: A function to dispose of the provider.
  /// - `lazy`: If true, the provider is lazily initialized. Defaults to false.
  /// - `factory`: If true, the provider is created as a factory. Defaults to false.
  /// - `parameters`: Additional parameters for the provider.
  /// - `key`: An optional key for the provider.
  ///
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

  /// The [Injector.parameters] to manually pass to [create].
  /// Ex:
  /// ```dart
  /// context.provide(ProductNotifier.new, parameters: {
  ///   #productId: '123',
  /// });
  /// ```
  final Map<Symbol, dynamic>? parameters;

  /// Whether to create the value only when it's first called.
  final bool lazy;

  /// Whether to create a new instance each time.
  final bool factory;

  /// Creates a [ProvideRef] with a constant value.
  ///
  /// The [value] parameter is the constant value to be provided.
  ///
  /// The [updateShouldNotify] parameter is an optional callback that determines
  /// whether listeners should be notified when the value changes.
  ///
  /// The [key] parameter is an optional key for the ref.
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
  late Injector? _injector = ref.create != null
      ? Injector<T>(ref.create!, parameters: ref.parameters)
      : null;
  Future<T>? _future;
  Stream<T>? _stream;

  @override
  String get type => _injector?.type ?? T.type;

  @override
  Future<T>? get future => _future;

  @override
  Stream<T>? get stream => _stream;

  @override
  bool get shouldNotifySelf => ref.create == null;

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
      _injector = Injector<T>(ref.create!, parameters: ref.parameters);
    }

    final value = ref.value ?? _injector!();

    if (value is Future) {
      _future = value.then((it) => it);
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
    if (!ref.factory && ref.create != null && snapshot.data is T) {
      (ref.dispose ?? tryDispose)(snapshot.data as T);
    }
    super.dispose();
  }

  @override
  void bind(BuildContext context) => snapshot.data;

  @override
  T watch(BuildContext context) {
    assert(!ref.factory, 'Cannot watch factory values.');
    return super.watch(context);
  }

  @override
  S select<L, S>(BuildContext context, int index, Function selector) {
    assert(!ref.factory, 'Cannot select factory values.');
    return super.select(context, index, selector);
  }

  @override
  T read() {
    if (ref.factory || !_created) load();
    if (snapshot.data case T data) return data;

    return snapshot.requireData;
  }

  @override
  String get debugLabel {
    var async = '';
    if (future != null) async = '(future)';
    if (stream != null) async = '(stream)';

    final label = switch ((ref.lazy, ref.factory)) {
      (_, true) => 'provideFactory',
      (true, _) => 'provideLazy',
      _ => 'provide',
    };

    return 'context.$label<$type> $async';
  }
}
