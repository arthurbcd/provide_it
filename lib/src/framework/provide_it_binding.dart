part of '../framework.dart';

typedef _State<T> = RefState<T, Ref<T>>;

extension on ReadItMixin {
  int _initTreeIndex(BuildContext? context) {
    if (context == null) return 0;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      // we reset the index for the next build.
      _treeIndex.remove(context);
    });

    return 0;
  }

  _State<T> _state<T>(Element? context, Ref<T> ref, bool topLevel) {
    final branch = _tree[context] ??= TreeMap<int, _State>();
    final index = _treeIndex[context] ??= _initTreeIndex(context);
    _treeIndex[context] = index + 1;

    _State<T> create() {
      _doingInit = true;

      final state = branch[index] = ref.createState()
        .._bind = (element: context, index: index)
        .._scope = this as ProvideItScope
        .._topLevel = topLevel
        .._ref = ref
        ..initState();

      _doingInit = false;

      return state;
    }

    _State<T> update(_State<T> old) => old
      .._ref = ref
      ..didUpdateRef(old.ref);

    _State<T> reset(_State<dynamic> old) {
      if (_element!._reassembled) return create();
      throw StateError('${old.ref.runtimeType} != ${ref.runtimeType}');
    }

    return switch (branch[index]) {
      var old? when old.ref.runtimeType != ref.runtimeType => reset(old),
      _State<T> old when Ref.canUpdate(old.ref, ref) => update(old),
      _ => create(),
    };
  }
}
