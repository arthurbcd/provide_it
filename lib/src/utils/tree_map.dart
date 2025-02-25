import 'dart:collection';

import 'package:flutter/widgets.dart';

/// A reverse ordered map with O(1) insertion and efficient iteration.
class TreeMap<K, V> extends MapBase<K, V> {
  final _map = HashMap<K, V>();
  final _reversedKeys = Queue<K>();

  @override
  Iterable<K> get keys => _reversedKeys;
  Iterable<K> get baseKeys => _map.keys;

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

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('TreeMap:');
    _writeIndented(buffer, this, 0);
    return buffer.toString();
  }

  void _writeIndented(StringBuffer buffer, TreeMap tree, int indentLevel) {
    final indent = '  ' * indentLevel;
    for (final (index, key) in tree.baseKeys.indexed) {
      final value = tree[key];
      if (value is TreeMap) {
        buffer.writeln('$indent - $index: ${_text(key)}:');
        _writeIndented(buffer, value, indentLevel + 1);
      } else {
        buffer.writeln('$indent - $index: ${_text(value)}');
      }
    }
  }

  String _text(o) => switch (o) {
        num _ => '',
        Element el => '${el.widget}',
        var o => o.toString(),
      };
}
