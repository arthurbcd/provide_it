part of '../framework.dart';

extension on ReadItMixin {
  int _initCacheIndex(BuildContext? context) {
    if (context == null) return 0;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // we reset the indexes for the next build.
      _cacheIndex.remove(context);
    });

    return 0;
  }

  _State? _stateOf<T>(BuildContext? context, {String? type, Object? key}) {
    // we depend so we can get notified by [removeDependent].
    context?.dependOnInheritedElement(_element!);
    type ??= T.type;

    final states = _treeCache[(type, key)];
    assert(states != null, 'Ref<$type> not found, key: $key.');

    final state = states?.firstOrNull;
    assert(states?.length == 1, 'Duplicate Ref<$T> found, key: $key.');

    if (state?.type == type) {
      final index = _cacheIndex[context] ??= _initCacheIndex(context);
      _cacheIndex[context] = index + 1;

      return state!;
    }

    // case it's a global ref, we can auto-bind it.
    if (key case Ref<T> ref) return _state(context as Element?, ref);
    return null;
  }

  // R? _findState<R extends _State>(BuildContext ctx, String type, Object? key) {
  //   final types = _element!.widget.allowedDuplicates?.map((e) => '$e');

  //   if (type == 'dynamic' && key == null) {
  //     final state = _tree[ctx]?.values.whereType<R>().singleOrNull;
  //     assert(
  //       state != null,
  //       'Reading dynamically is only allowed if single and at same context.',
  //     );
  //     return state;
  //   }

  //   // check same context first, then leafs to root.
  //   final states = (_tree[ctx]?.values ?? []).followedBy(
  //       _tree.entries.where((e) => e.key != ctx).expand((e) => e.value.values));

  //   R? lastState;

  //   for (var state in states.whereType<R>()) {
  //     if (type == 'dynamic' && Ref.equals(state.ref.key, key)) return state;

  //     if (state.type == type && Ref.equals(state.ref.key, key)) {
  //       if (!kDebugMode || types == null) {
  //         return state;
  //       }

  //       // print(state.hashCode);

  //       assert(
  //         lastState == null || types.contains(type),
  //         'Duplicate Ref<$type> found, key: $key',
  //       );

  //       lastState ??= state;
  //     }
  //   }

  //   return lastState;
  // }

  void _disposeCache(Element context) {
    _cacheIndex.remove(context);
    // _cache.remove(context)?.forEach((_, branch) =>
    //     branch.forEach((_, state) => state?.removeDependent(context)));
  }
}
