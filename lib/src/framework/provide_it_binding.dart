part of '../framework.dart';

extension on ProvideItScope {
  int _initTreeIndex(BuildContext? context) {
    if (context == null) return 0;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      // we reset the index for the next build.
      _treeIndex.remove(context);
    });

    return 0;
  }

  Bind<T, Ref<T>> _bind<T>(Element context, Ref<T> ref) {
    final branch = _tree[context] ??= TreeMap();
    final index = _treeIndex[context] ??= _initTreeIndex(context);
    _treeIndex[context] = index + 1;

    Bind<T, Ref<T>> create() => branch[index] = ref.createBind()
      .._scope = this
      .._element = context
      ..index = index
      .._ref = ref
      ..initBind();

    Bind<T, Ref<T>> update(Bind<T, Ref<T>> old) => old
      .._ref = ref
      ..didUpdateRef(old.ref);

    Bind<T, Ref<T>> reset(Bind old) {
      assert(_element!._reassembled || old.ref.runtimeType == ref.runtimeType);
      return create(); // reassembled or key changed
    }

    return switch (branch[index]) {
      null => create(),
      Bind<T, Ref<T>> old when Ref.canUpdate(old.ref, ref) => update(old),
      final old => reset(old),
    };
  }
}
