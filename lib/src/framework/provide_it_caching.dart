part of 'framework.dart';

extension on ProvideItRootElement {
  int _initCacheIndex(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // we reset the indexes for the next build.
      _cacheIndex.remove(context);
      _reassembled = false;
    });

    return 0;
  }

  _State<T> _stateOf<T>(BuildContext context, {Object? key}) {
    // we depend so we can get notified by [removeDependent].
    context.dependOnInheritedElement(this);

    final contextCache = _cache[context] ??= {};
    final typeCache = contextCache[T] ??= HashMap(equals: Ref.equals);
    final state = typeCache[key] ??= _findState<T>(key: key);

    if (state case _State<T> state) {
      final index = _cacheIndex[context] ??= _initCacheIndex(context);
      _cacheIndex[context] = index + 1;

      return state;
    }

    // we assume it's a global lazy ref, so we can bind/read it.
    if (key case Ref<T> ref) return _state(context, ref);

    throw StateError('No state found for $T with key $key');
  }

  _State<T>? _findState<T>({Object? key}) {
    for (var branch in _tree.values) {
      for (var leaf in branch.values) {
        if (leaf case _State<T> state) {
          if (Ref.equals(state.key, key)) return state;
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
