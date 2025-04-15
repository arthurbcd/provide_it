part of '../framework.dart';

extension on ProvideItScope {
  int _initCacheIndex(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // we reset the indexes for the next build.
      _dependencyIndex.remove(context);
    });

    return 0;
  }

  Bind? _bindOf<T>(BuildContext context, {Object? key}) {
    final bind = getBindOfType<T>(key: key);

    if (key case Ref<T> ref) {
      final index = _treeIndex[context] ?? 0;

      // get-or-bind
      if (bind == null || bind.context == context && bind.index == index) {
        return _bind<T>(context as Element, ref);
      }
    }

    if (bind != null && context is Element) {
      final index = _dependencyIndex[context] ??= _initCacheIndex(context);
      _dependencyIndex[context] = index + 1;
    }

    return bind;
  }
}
