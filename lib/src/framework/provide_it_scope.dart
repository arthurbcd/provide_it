part of '../framework.dart';

class ProvideItScope implements ReadIt {
  static ProvideItScope of(BuildContext context) {
    final it = context.getElementForInheritedWidgetOfExactType<ProvideIt>();
    assert(it != null, 'You must set a `ProvideIt` above your app.');
    return (it as ProvideItElement).scope;
  }

  /// The attached [ProvideIt] element.
  ProvideItElement? _element;

  /// The watchers to use. Including [ProvideIt.additionalWatchers].
  Set<Watcher> get watchers => {
        ...ProvideIt.defaultWatchers,
        ...?_element?.widget.additionalWatchers,
      };

  @protected
  T watch<T>(BuildContext context, {Object? key}) {
    final bind = _bindOf<T>(context, key: key);
    final value = bind?.value;
    bind?.watch(context);

    if (value == null && null is T) return value;
    if (bind != null) return bind.read();

    throw StateError('Ref<$T> not found, key: $key.');
  }

  @protected
  R select<T, R>(BuildContext context, R selector(T value), {Object? key}) {
    final bind = _bindOf<T>(context, key: key);
    final value = bind?.select<T, R>(context, selector);

    return value as R;
  }

  @protected
  void listen<T>(BuildContext context, void listener(T value), {Object? key}) {
    final bind = _bindOf<T>(context, key: key);

    bind?.listen<T>(context, listener);
  }

  @protected
  void listenSelect<T, R>(
    BuildContext context,
    R selector(T value),
    void listener(R previous, R next), {
    Object? key,
  }) {
    final bind = _bindOf<T>(context, key: key);

    bind?.listenSelect<T, R>(context, selector, listener);
  }

  @override
  bool get mounted => _element != null;

  // bind tree by context and index.
  late final _tree = TreeMap<Element?, TreeMap<int, Bind>>()._assert(this);
  late final _treeIndex = <Element?, int>{}._assert(this);
  late final _treeCache = HashMap<(String, Object?), Set<Bind>>(
    equals: (a, b) => a.$1 == b.$1 && Ref.equals(a.$2, b.$2),
  ).._assert(this);

  // bind dependencies by the dependent `context`.
  late final _dependencies = <Element, Set<Bind>>{}._assert(this);
  late final _dependencyIndex = <Element, int>{}._assert(this);

  /// Iterates over all [Ref] binds. Depth-first.
  Iterable<Bind> get binds sync* {
    for (var branch in _tree.values) {
      for (var bind in branch.values) {
        yield bind;
      }
    }
  }

  @protected
  Injector<I> injector<I>(Function create) {
    return _element?.injector<I>(create) ?? Injector<I>(create);
  }

  /// The future of [AsyncBind.isReady].
  @override
  FutureOr<void> allReady() {
    final futures = <Future>[];

    for (var bind in binds) {
      if (bind is! AsyncBind) continue;
      if (bind.isReady() case Future it) futures.add(it);
    }
    if (futures.isEmpty) return null;

    return futures.wait as Future<void>;
  }

  /// The future when a [AsyncBind.isReady] is completed.
  @override
  FutureOr<void> isReady<T>({String? type, Object? key}) {
    type ??= T.type;

    final binds = _treeCache[(type, key)];
    assert(binds != null, 'AsyncRef<$type> not found, key: $key.');
    assert(binds?.length == 1, 'Duplicate AsyncRef<$type>, key: $key.');

    if (binds?.firstOrNull case AsyncBind s) return s.isReady();
    return null;
  }

  @protected
  Bind<T, Ref<T>> bind<T>(BuildContext context, Ref<T> ref) {
    return _bind<T>(context as Element, ref);
  }

  @protected
  Bind? bindOf<T>(BuildContext context, {Object? key}) {
    return _bindOf<T>(context, key: key);
  }

  Future<void> reload<T>({Object? key}) async {
    final bind = getBindOfType<T>(key: key);
    assert(
        bind is AsyncBind || null is T, 'AsyncRef<$T> not found, key: $key.');

    await (bind as AsyncBind?)?.load();
  }

  @override
  T read<T>({Object? key}) {
    final bind = getBindOfType<T>(key: key);
    final value = bind?.value;

    if (value == null && null is T) return value;
    if (bind != null) return bind.read();

    throw StateError('Ref<$T> not found, key: $key.');
  }

  @override
  FutureOr<T> readAsync<T>({String? type, Object? key}) {
    type ??= T.type;

    final bind = getBindOfType(type: type, key: key);

    if (bind is AsyncBind) {
      final value = bind.readAsync();

      // we need to cast the future/value to T.
      if (value is Future) return value.then((it) => it as T);
      return value as T;
    }
    if (null is T) return null as T;
    assert(
      false,
      '''
ReadError: '$type not found, key: $key.'.

Did you provide the missing type?
context.provide<$type>(...); // <- provide it
''',
    );
    throw StateError('AsyncRef<$type> not found, key: $key.');
  }

  @protected
  Bind? getBindOfType<T>({String? type, Object? key}) {
    type ??= T.type;

    final binds = _treeCache[(type, key)] ?? {};
    final bind = binds.firstOrNull;

    assert(binds.length < 2, 'Duplicate Ref<$type> found, key: $key.');
    return bind;
  }

  @override
  String toString() => _tree.toString();
}

extension<K, V> on Map<K, V> {
  /// Creates a new [Map] that asserts the given function when mutating.
  ///
  /// This is useful for debugging and testing purposes.
  Map<K, V> _assert(ProvideItScope scope) {
    if (!kDebugMode) return this;

    return AssertMap(this, () {
      final to = scope == readIt ? 'to this scope.' : 'above your app.';
      assert(scope.mounted, 'Scope not attached. You must set a ProvideIt $to');
    });
  }
}

class AssertMap<K, V> extends MapBase<K, V> {
  AssertMap(this._map, this._assert);
  final Map<K, V> _map;
  final VoidCallback _assert;

  @override
  void operator []=(key, value) {
    _assert();
    _map[key] = value;
  }

  @override
  void clear() {
    _assert();
    _map.clear();
  }

  @override
  Iterable<K> get keys {
    _assert();
    return _map.keys;
  }

  @override
  V? remove(Object? key) {
    _assert();
    return _map.remove(key);
  }

  @override
  V? operator [](Object? key) {
    _assert();
    return _map[key];
  }
}
