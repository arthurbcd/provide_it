import 'dart:collection';

import '../framework.dart';
import 'listenable.dart';

class DefaultWatchers extends ListBase<Watcher> {
  const DefaultWatchers(this.additionals);
  final List<Watcher> additionals;

  List<Watcher> get watchers => [
        ListenableWatcher(),
        ...additionals,
      ];

  @override
  int get length => watchers.length;

  @override
  set length(int newLength) => watchers.length = newLength;

  @override
  operator [](int index) => watchers[index];

  @override
  void operator []=(int index, value) => watchers[index] = value;
}
