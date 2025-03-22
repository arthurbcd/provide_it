part of '../framework.dart';

class ProvideItScope with ReadItMixin {
  static ProvideItScope of(BuildContext context) {
    final it = context.getElementForInheritedWidgetOfExactType<ProvideIt>();
    assert(it != null, 'You must set `ProvideIt` in your app.');
    return (it as ProvideItElement).scope;
  }

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

    state?.listen(context, listener);
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
}

mixin ReadItMixin implements ReadIt {
  ProvideItElement? _element;

  /// The watchers to use. [ProvideIt.additionalWatchers] will be added to this.
  final watchers = ProvideIt.defaultWatchers;

  /// Whether [ProvideIt] is attached to the widget tree.
  bool get mounted => _element != null;

  // state binder tree by context and index.
  final _tree = TreeMap<Element?, TreeMap<int, RefState>>();
  final _treeIndex = <Element?, int>{};
  final _treeCache = HashMap<(String, Object?), Set<RefState>>(
    equals: (a, b) => a.$1 == b.$1 && Ref.equals(a.$2, b.$2),
  );

  // state dependencies by the dependent `context`.
  final _dependencies = <Element, Set<RefState>>{};
  final _dependencyIndex = <Element, int>{};

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
    return _element?.injector(create) ?? Injector<I>(create);
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

  @override
  RefState<T, Ref<T>> bind<T>(Ref<T> ref, {BuildContext? context}) {
    assert(
      context != null || !mounted,
      'ReadIt cannot bind after ProvideIt is attached to the widget tree.',
    );

    return _state<T>(context as Element?, ref);
  }

  RefState? bindOf<T>({Object? key, BuildContext? context}) {
    return _stateOf<T>(context as Element?, key: key);
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
