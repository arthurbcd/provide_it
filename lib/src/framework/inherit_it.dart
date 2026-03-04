part of '../framework.dart';

mixin InheritIt {
  // inherited state cache by type
  final _inheritedCache = HashMap<String, InheritedCache>();

  void _registerType(InheritedState state) {
    _inheritedCache.update(
      state.type,
      (cache) => cache.add(state),
      ifAbsent: () => InheritedCache.single(state),
    );
  }

  void _unregisterType(InheritedState state) {
    if (_inheritedCache[state.type]?.remove(state) case final cache?) {
      _inheritedCache[state.type] = cache;
    } else {
      _inheritedCache.remove(state.type);
    }
  }
}
