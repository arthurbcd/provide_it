part of '../framework.dart';

extension on ReadItMixin {
  int _initCacheIndex(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // we reset the indexes for the next build.
      _dependencyIndex.remove(context);
    });

    return 0;
  }

  _State? _stateOf<T>(BuildContext? context, {Object? key}) {
    final state = getRefStateOfType<T>(key: key);

    if (key case Ref<T> ref) {
      final bind = (element: context, index: _treeIndex[context] ?? 0);
      // get-or-bind
      if (state == null || state._bind == bind) {
        return _state<T>(context as Element?, ref);
      }
    }

    if (state != null && context is Element) {
      final index = _dependencyIndex[context] ??= _initCacheIndex(context);
      _dependencyIndex[context] = index + 1;
    }

    return state;
  }
}
