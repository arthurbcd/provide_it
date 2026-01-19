import 'package:flutter/foundation.dart';

import '../framework.dart';

class ListenableWatcher extends Watcher<Listenable> {
  const ListenableWatcher();

  @override
  void init(Listenable observable, VoidCallback notify) {
    observable.addListener(notify);
  }

  @override
  void cancel(Listenable observable, VoidCallback notify) {
    observable.removeListener(notify);
  }

  @override
  void dispose(Listenable observable) {
    if (observable is ChangeNotifier) {
      observable.dispose();
    }
  }
}
