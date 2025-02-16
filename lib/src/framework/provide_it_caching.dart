part of 'framework.dart';

extension on ProvideItElement {
  int _initCacheIndex(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // we reset the indexes for the next build.
      _cacheIndex.remove(context);
      _reassembled = false;
    });

    return 0;
  }

  _State _stateOf<T>(BuildContext context, {String? type, Object? key}) {
    // we depend so we can get notified by [removeDependent].
    context.dependOnInheritedElement(this);
    type ??= T.toString();

    final contextCache = _cache[context] ??= {};
    final typeCache = contextCache[type] ??= HashMap(equals: Ref.equals);
    final state = typeCache[key] ??= _findState(type, key: key);

    if (state?.type == type) {
      final index = _cacheIndex[context] ??= _initCacheIndex(context);
      _cacheIndex[context] = index + 1;

      return state!;
    }

    // we assume it's a global lazy ref, so we can bind/read it.
    if (key case Ref<T> ref) return _state(context, ref);

    throw StateError('No state found for $T with key $key');
  }

  _State? _findState(String type, {Object? key}) {
    for (var branch in _tree.values) {
      for (var state in branch.values) {
        if (state.type == type) {
          if (Ref.equals(state.ref.key, key)) return state;
        }
      }
    }
    return null;
  }

  void _disposeCache(Element context) {
    _cacheIndex.remove(context);
    _cache.remove(context)?.forEach((_, branch) =>
        branch.forEach((_, state) => state?.removeDependent(context)));
  }
}
