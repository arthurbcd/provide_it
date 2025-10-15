part of '../framework.dart';

extension on ProvideItScope {
  int _initCacheIndex(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // we reset the indexes for the next build.
      _observerIndex.remove(context);
    });

    return 0;
  }

  Bind? _bindOf<T>(BuildContext context) {
    final bind = getBindOfType<T>(context: context);

    if (bind != null && context is Element) {
      final index = _observerIndex[context] ??= _initCacheIndex(context);
      _observerIndex[context] = index + 1;
    }

    return bind;
  }
}
