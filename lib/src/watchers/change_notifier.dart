import 'package:flutter/foundation.dart';

import '../framework.dart';

class ChangeNotifierWatcher extends Watcher<ChangeNotifier> {
  @override
  void init(ChangeNotifier observable, VoidCallback notify) {
    observable.addListener(notify);
  }

  @override
  void cancel(ChangeNotifier observable, VoidCallback notify) {
    observable.removeListener(notify);
  }

  @override
  void dispose(ChangeNotifier observable) {
    observable.dispose();
  }
}
