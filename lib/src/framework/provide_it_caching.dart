part of '../framework.dart';

extension on ReadItMixin {
  int _initCacheIndex(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // we reset the indexes for the next build.
      _dependencyIndex.remove(context);
    });

    return 0;
  }

  _State? _stateOf<T>(BuildContext? context, {String? type, Object? key}) {
    type ??= T.type;

    final states = _treeCache[(type, key)];
    assert(states != null, 'Ref<$type> not found, key: $key.');

    final state = states?.firstOrNull;
    assert(states?.length == 1, 'Duplicate Ref<$type> found, key: $key.');

    if (state?.type == type && context is Element) {
      final index = _dependencyIndex[context] ??= _initCacheIndex(context);
      _dependencyIndex[context] = index + 1;

      return state!;
    }

    // case it's a global ref, we can auto-bind it.
    if (key case Ref<T> ref) return _state(context as Element?, ref);
    return state;
  }
}
