part of '../framework.dart';

class ProvideItScope with ReadItMixin {
  @protected
  T watch<T>(BuildContext context, {Object? key}) {
    final state = _stateOf<T>(context, key: key);
    final value = state?.watch(context);

    return value as T;
  }

  @protected
  R select<T, R>(BuildContext context, R selector(T value), {Object? key}) {
    final state = _stateOf<T>(context, key: key);
    final index = _dependencyIndex[context]!;
    final value = state?.select<T, R>(context, index, selector);

    return value as R;
  }

  @protected
  void listen<T>(BuildContext context, void listener(T value), {Object? key}) {
    final state = _stateOf<T>(context, key: key);
    final index = _dependencyIndex[context]!;

    state?.listen(context, index, listener);
  }

  @protected
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
    final state = _state<T>(context as Element?, ref, false);

    return state.bind() as R;
  }

  Future<void> reload<T>({Object? key}) async {
    final state = findRefStateOfType<T>(key: key);
    assert(state is AsyncRefState?, 'AsyncRef<$T> not found, key: $key.');

    await (state as AsyncRefState?)?.load();
  }

  @override
  T read<T>({Object? key}) {
    final state = findRefStateOfType<T>(key: key);
    if (null is T) return state?.value;
    if (state != null) return state.read();

    throw StateError('Ref<$T> not found, key: $key.');
  }

  @override
  void write<T>(T value, {Object? key}) {
    final state = findRefStateOfType<T>(key: key);
    if (null is T) return;
    if (state != null) return state.write(value);

    throw StateError('Ref<$T> not found, key: $key.');
  }

  @override
  FutureOr<T> readAsync<T>({String? type, Object? key}) {
    type ??= T.type;

    final state = findRefStateOfType(type: type, key: key);

    if (state is AsyncRefState) {
      final value = state.readAsync();

      // we need to cast the future/value to T.
      if (value is Future) return value.then((it) => it as T);
      return value as T;
    }

    throw StateError('AsyncRef<$type> not found, key: $key.');
  }

  @protected
  RefState? findRefStateOfType<T>({String? type, Object? key}) {
    type ??= T.type;

    final states = _treeCache[(type, key)] ?? {};
    final state = states.firstOrNull;

    assert(states.length <= 1, 'Duplicate Ref<$type> found, key: $key.');
    return state;
  }

  @override
  String toString() => _tree.toString();
}
