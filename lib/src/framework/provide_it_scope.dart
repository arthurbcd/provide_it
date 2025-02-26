part of '../framework.dart';

class ProvideItScope with ReadItMixin {
  T watch<T>(BuildContext context, {Object? key}) {
    final state = _stateOf<T>(context, key: key);
    final value = state?.watch(context);

    if (value is T) return value;
    throw ArgumentError.notNull('watch');
  }

  R select<T, R>(BuildContext context, R selector(T value), {Object? key}) {
    final state = _stateOf<T>(context, key: key);
    final value =
        state?.select<T, R>(context, _dependentIndex[context]!, selector);

    if (value is R) return value;
    throw ArgumentError.notNull('select');
  }

  void listen<T>(BuildContext context, void listener(T value), {Object? key}) {
    final state = _stateOf<T>(context, key: key);
    _assertState<T>(state, 'listen', key);

    state?.listen(context, _dependentIndex[context]!, listener);
  }

  void listenSelect<T, R>(
    BuildContext context,
    R selector(T value),
    void listener(R previous, R next), {
    Object? key,
  }) {
    final state = _stateOf<T>(context, key: key);
    final index = _dependentIndex[context]!;
    _assertState<T>(state, 'listenSelect', key);

    state?.listenSelect<T, R>(context, index, selector, listener);
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

  // dependents and the state they depend on.
  final _dependents = <BuildContext?, Set<RefState>>{};
  final _dependentIndex = <BuildContext?, int>{};

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
    assert(states != null, 'AsyncRef<$type> not found, key: $key.');
    assert(states?.length == 1, 'Duplicate AsyncRef<$type>, key: $key.');

    if (states?.firstOrNull case AsyncRefState s) return s.isReady();
    return null;
  }

  @override
  void bind<T>(Ref<T> ref, {BuildContext? context}) {
    assert(
      context != null || _element == null,
      'ReadIt cannot bind after ProvideIt initialization.',
    );
    final state = _state(context as Element?, ref);

    // we return `state.value` as some binds might need it.
    return context == null ? state.value : state.bind(context);
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
    type ??= T.type;

    final state = _stateOf(context, type: type, key: key);
    assert(state is AsyncRefState, 'AsyncRef<$type> not found, key: $key.');

    final value = (state as AsyncRefState).readAsync();
    if (value is Future) return value.then((it) => it as T);

    return value as T;
  }

  @override
  String toString() => _tree.toString();
}
