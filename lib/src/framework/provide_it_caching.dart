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
    final state = typeCache[key] ??= _findState(context, type, key);

    if (state?.type == type) {
      final index = _cacheIndex[context] ??= _initCacheIndex(context);
      _cacheIndex[context] = index + 1;

      return state!;
    }

    // case it's a global ref, we can auto-bind it.
    if (key case Ref<T> ref) return _state(context, ref);

    throw StateError('Ref<$T> not found, key: $key');
  }

  _State? _findState(BuildContext context, String type, Object? key) {
    final types = widget.allowedDuplicates?.map((e) => '$e');

    // check same context first, then leafs to root.
    var states = _tree[context]?.values ?? [];
    states = states.followedBy(_tree.values.expand((e) => e.values));
    _State? state;

    for (var s in states) {
      if (s.type == type && Ref.equals(s.ref.key, key)) {
        if (!kDebugMode || types == null) return state;
        assert(
          state == null && types.contains(type),
          'Duplicate Ref<$type> found, key: $key',
        );
        state ??= s;
      }
    }

    return state;
  }

  void _disposeCache(Element context) {
    _cacheIndex.remove(context);
    _cache.remove(context)?.forEach((_, branch) =>
        branch.forEach((_, state) => state?.removeDependent(context)));
  }
}
