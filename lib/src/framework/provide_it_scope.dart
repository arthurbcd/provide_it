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
    final state = _stateOf<T>(context, key: key);
    final value = state?.value;
    state?.watch(context);

    if (value == null && null is T) return value;
    if (state != null) return state.read();

    throw StateError('Ref<$T> not found, key: $key.');
  }

  @protected
  R select<T, R>(BuildContext context, R selector(T value), {Object? key}) {
    final state = _stateOf<T>(context, key: key);
    final value = state?.select<T, R>(context, selector);

    return value as R;
  }

  @protected
  void listen<T>(BuildContext context, void listener(T value), {Object? key}) {
    final state = _stateOf<T>(context, key: key);

    state?.listen<T>(context, listener);
  }

  @protected
  void listenSelect<T, R>(
    BuildContext context,
    R selector(T value),
    void listener(R previous, R next), {
    Object? key,
  }) {
    final state = _stateOf<T>(context, key: key);

    state?.listenSelect<T, R>(context, selector, listener);
  }

  @override
  bool get mounted => _element != null;

  // state binder tree by context and index.
  late final _tree = TreeMap<Element?, TreeMap<int, RefState>>()._assert(this);
  late final _treeIndex = <Element?, int>{}._assert(this);
  late final _treeCache = HashMap<(String, Object?), Set<RefState>>(
    equals: (a, b) => a.$1 == b.$1 && Ref.equals(a.$2, b.$2),
  ).._assert(this);

  // state dependencies by the dependent `context`.
  late final _dependencies = <Element, Set<RefState>>{}._assert(this);
  late final _dependencyIndex = <Element, int>{}._assert(this);

  /// Iterates over all [Ref] states. Depth-first.
  Iterable<RefState> get states sync* {
    for (var branch in _tree.values) {
      for (var state in branch.values) {
        yield state;
      }
    }
  }

  @protected
  Injector<I> injector<I>(Function create) {
    return _element?.injector<I>(create) ?? Injector<I>(create);
  }

  /// The future of [AsyncRefState.isReady].
  @override
  FutureOr<void> allReady() {
    final futures = <Future>[];

    for (var state in states) {
      if (state is! AsyncRefState) continue;
      if (state.isReady() case Future it) futures.add(it);
    }
    if (futures.isEmpty) return null;

    return futures.wait as Future<void>;
  }

  /// The future when a [AsyncRefState.isReady] is completed.
  @override
  FutureOr<void> isReady<T>({String? type, Object? key}) {
    type ??= T.type;

    final states = _treeCache[(type, key)];
    assert(states != null, 'AsyncRef<$type> not found, key: $key.');
    assert(states?.length == 1, 'Duplicate AsyncRef<$type>, key: $key.');

    if (states?.firstOrNull case AsyncRefState s) return s.isReady();
    return null;
  }

  @protected
  RefState<T, Ref<T>> bind<T>(BuildContext context, Ref<T> ref) {
    return _state<T>(context as Element, ref);
  }

  @protected
  RefState? bindOf<T>(BuildContext context, {Object? key}) {
    return _stateOf<T>(context, key: key);
  }

  Future<void> reload<T>({Object? key}) async {
    final state = getRefStateOfType<T>(key: key);
    assert(state is AsyncRefState || null is T,
        'AsyncRef<$T> not found, key: $key.');

    await (state as AsyncRefState?)?.load();
  }

  @override
  T read<T>({Object? key}) {
    final state = getRefStateOfType<T>(key: key);
    final value = state?.value;

    if (value == null && null is T) return value;
    if (state != null) return state.read();

    throw StateError('Ref<$T> not found, key: $key.');
  }

  @override
  FutureOr<T> readAsync<T>({String? type, Object? key}) {
    type ??= T.type;

    final state = getRefStateOfType(type: type, key: key);

    if (state is AsyncRefState) {
      final value = state.readAsync();

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
  RefState? getRefStateOfType<T>({String? type, Object? key}) {
    type ??= T.type;

    final states = _treeCache[(type, key)] ?? {};
    final state = states.firstOrNull;

    assert(states.length < 2, 'Duplicate Ref<$type> found, key: $key.');
    return state;
  }

  @override
  String toString() => _tree.toString();
}

extension<K, V> on Map<K, V> {
  /// Creates a new [Map] that asserts the given function when mutating.
  ///
  /// This is useful for debugging and testing purposes.
  Map<K, V> _assert(ProvideItScope scope) {
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
