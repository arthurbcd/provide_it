part of '../framework.dart';

typedef _State<T> = RefState<T, Ref<T>>;

extension on ProvideItElement {
  int _initTreeIndex(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // we reset the index for the next build.
      _treeIndex.remove(context);
      _reassembled = false;
    });

    return 0;
  }

  _State<T> _state<T>(BuildContext context, Ref<T> ref) {
    // we depend so we can get notified by [removeDependent].
    context.dependOnInheritedElement(this);

    final branch = _tree[context as Element] ??= TreeMap<int, _State>();
    final index = _treeIndex[context] ??= _initTreeIndex(context);
    _treeIndex[context] = index + 1;

    _State<T> create() {
      _doingInit = true;

      final state = branch[index] = ref.createState()
        .._element = context
        .._root = this
        .._ref = ref
        ..initState();

      _doingInit = false;

      return state;
    }

    _State<T> update(_State<T> old) {
      return old
        .._ref = ref
        ..didUpdateRef(old.ref);
    }

    _State<T> reset(_State<dynamic> old) {
      if (_reassembled) return create();
      throw StateError('${old.ref.runtimeType} != ${ref.runtimeType}');
    }

    return switch (branch[index]) {
      var old? when old.ref.runtimeType != ref.runtimeType => reset(old),
      _State<T> old when Ref.canUpdate(old.ref, ref) => update(old),
      _ => create(),
    };
  }

  void _disposeBinds(Element context) {
    _tree.remove(context)?.forEach((_, state) => state.dispose());
    _treeIndex.remove(context);
  }

  void _disposeRef<T>(BuildContext context, Ref<T> ref) {
    final branch = _tree[context] ?? TreeMap<int, _State>();

    for (var e in branch.entries.toList()) {
      if (e.value.ref == ref) return branch.remove(e.key)?.dispose();
    }
  }
}
