part of '../framework.dart';

class ProvideItScope with ReadItMixin {
  T watch<T>(BuildContext context, {Object? key}) {
    _assertContext(context, 'watch');

    final state = _stateOf<T?>(context, key: key);
    final value = state?.watch(context);

    if (value is T) return value;
    throw StateError('watch<$T> not found, key: $key');
  }

  R select<T, R>(BuildContext context, R selector(T value), {Object? key}) {
    _assertContext(context, 'select');

    final state = _stateOf<T>(context, key: key);
    final value = state?.select(context, _cacheIndex[context]!, selector);

    if (value is R) return value;
    throw StateError('Ref<$T> not found, key: $key');
  }
}

mixin ReadItMixin implements ReadIt {
  ProvideItElement? _element;

  /// The watchers to use. [ProvideIt.additionalWatchers] will be added to this.
  final watchers = ProvideIt.defaultWatchers;

  /// Whether [ProvideIt] is attached to the widget tree.
  bool get isAttached => _element != null;

  // state binder tree by context and index.
  final _tree = TreeMap<Element?, TreeMap<int, RefState>>();
  final _treeIndex = <Element?, int>{};
  final _treeCache = HashMap<(String, Object?), Set<RefState>>(
    equals: (a, b) => a.$1 == b.$1 && Ref.equals(a.$2, b.$2),
  );
  final _cacheIndex = <BuildContext?, int>{};

  /// Iterates over all [Ref] states. Leaf to root.
  Iterable<RefState> get states sync* {
    for (var branch in _tree.values) {
      for (var state in branch.values) {
        yield state;
      }
    }
  }

  bool _doingInit = false;
  bool get debugDoingInit => _doingInit;

  /// The future of [AsyncRefState.isReady].
  @override
  FutureOr<void> allReady() {
    final futures = <Future>[];

    for (var state in states) {
      if (state is! AsyncRefState) continue;
      if (state.isReady() case Future it) futures.add(it);
    }
    if (futures.isEmpty) return null;

    return futures.wait.then((_) {});
  }

  /// The future when a [AsyncRefState.isReady] is completed.
  @override
  FutureOr<void> isReady<T>({String? type, Object? key}) {
    type ??= T.type;

    final states = _treeCache[(type, key)];
    assert(states != null, 'AsyncRef<$T> not found, key: $key.');
    assert(states?.length == 1, 'Duplicate AsyncRef<$T>, key: $key.');

    if (states?.firstOrNull case AsyncRefState s) return s.isReady();
    return null;
  }

  @override
  void bind<T>(Ref<T> ref, {BuildContext? context}) {
    _assertContext(context, 'bind');

    final state = _state(context as Element?, ref);

    // we return `state.value` as some binds might need it.
    return context == null ? state.value : state.bind(context);
  }

  @override
  void listen<T>(void listener(T value), {BuildContext? context, Object? key}) {
    _assertContext(context, 'listen');

    final state = _stateOf<T>(context, key: key);
    _assertState<T>(state, 'listen', key);

    state?.listen(context, _cacheIndex[context]!, listener);
  }

  @override
  void listenSelect<T, R>(
    R selector(T value),
    void listener(R previous, R next), {
    BuildContext? context,
    Object? key,
  }) {
    _assertContext(context, 'listenSelect');

    final state = _stateOf<T>(context, key: key);
    final index = _cacheIndex[context]!;
    _assertState<T>(state, 'listenSelect', key);

    state?.listenSelect<T, R>(context, index, selector, listener);
  }

  Future<void> reload<T>(BuildContext context, {Object? key}) async {
    final state = _stateOf<T>(context, key: key);
    assert(state is AsyncRefState, 'AsyncRef<$T> not found, key: $key.');

    (state as AsyncRefState).load();
  }

  @override
  T read<T>({BuildContext? context, Object? key}) {
    final value = _stateOf<T>(context, key: key)?._value;
    if (value is T) return value;

    throw StateError('Ref<$T> not found, key: $key');
  }

  @override
  FutureOr<T> readAsync<T>({BuildContext? context, String? type, Object? key}) {
    final state = _stateOf<T>(context, key: key);
    assert(state is AsyncRefState, 'AsyncRef<$T> not found, key: $key.');

    final value = (state as AsyncRefState).readAsync();
    if (value is Future) return value.then((it) => it as T);

    return value as T;
  }

  @override
  String toString() => _tree.toString();
}
