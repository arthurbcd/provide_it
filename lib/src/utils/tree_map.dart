import 'dart:collection';

/// A reverse ordered map with O(1) insertion and efficient iteration.
class TreeMap<K, V> extends MapBase<K, V> {
  final _map = HashMap<K, V>();
  final _reversedKeys = Queue<K>();

  @override
  Iterable<K> get keys => _reversedKeys;

  @override
  V? operator [](Object? key) => _map[key];

  @override
  void operator []=(key, value) {
    if (!_map.containsKey(key)) _reversedKeys.addFirst(key);
    _map[key] = value;
  }

  @override
  void clear() {
    _reversedKeys.clear();
    _map.clear();
  }

  @override
  V? remove(Object? key) {
    _reversedKeys.remove(key);
    return _map.remove(key);
  }
}
