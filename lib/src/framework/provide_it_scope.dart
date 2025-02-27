part of '../framework.dart';

class ProvideItScope with ReadItMixin {
  T watch<T>(BuildContext context, {Object? key}) {
    final state = _stateOf<T>(context, key: key);
    final value = state?.watch(context);

    return value as T;
  }

  R select<T, R>(BuildContext context, R selector(T value), {Object? key}) {
    final state = _stateOf<T>(context, key: key);
    final index = _dependencyIndex[context]!;
    final value = state?.select<T, R>(context, index, selector);

    return value as R;
  }

  void listen<T>(BuildContext context, void listener(T value), {Object? key}) {
    final state = _stateOf<T>(context, key: key);
    final index = _dependencyIndex[context]!;

    state?.listen(context, index, listener);
  }

  void listenSelect<T, R>(
    BuildContext context,
    R selector(T value),
    void listener(R previous, R next), {
    Object? key,
  }) {
    final state = _stateOf<T>(context, key: key);
    final index = _dependencyIndex[context]!;

    state?.listenSelect<T, R>(context, index, selector, listener);
  }

  RefState? findRefStateOfType<T>({Object? key}) {
    return _treeCache[(T.type, key)]?.firstOrNull;
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

  // state dependencies by the dependent `context`.
  final _dependencies = <Element, Set<RefState>>{};
  final _dependencyIndex = <Element, int>{};

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

  @override
  R bind<R, T>(Ref<T> ref, {BuildContext? context}) {
    assert(
      context != null || !isAttached,
      'ReadIt cannot bind after ProvideIt is attached to the widget tree.',
    );
    final state = _state<T>(context as Element?, ref);

    return state.bind() as R;
  }

  Future<void> reload<T>(BuildContext context, {Object? key}) async {
    final state = _stateOf<T>(context, key: key);
    assert(state is AsyncRefState?, 'AsyncRef<$T> not found, key: $key.');

    await (state as AsyncRefState?)?.load();
  }

  @override
  T read<T>({BuildContext? context, Object? key}) {
    final state = _stateOf<T>(context, key: key);
    final value = state?._value;

    if (value is! T && state is AsyncRefState) {
      throw StateError('AsyncRef<$T> not ready, key: $key.');
    }

    return value as T;
  }

  @override
  FutureOr<T> readAsync<T>({BuildContext? context, String? type, Object? key}) {
    type ??= T.type;

    final state = _stateOf(context, type: type, key: key);
    assert(state is AsyncRefState?, 'AsyncRef<$type> not found, key: $key.');

    final value = (state as AsyncRefState?)?.readAsync();
    if (value is Future) return value.then((it) => it as T);

    return value as T;
  }

  @override
  String toString() => _tree.toString();
}
