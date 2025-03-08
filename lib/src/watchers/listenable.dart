import 'package:flutter/foundation.dart';

import '../framework.dart';

class ListenableWatcher extends Watcher<Listenable> {
  @override
  void init(Listenable observable, VoidCallback notify) {
    observable.addListener(notify);
  }

  @override
  void cancel(Listenable observable, VoidCallback notify) {
    observable.removeListener(notify);
  }
}
