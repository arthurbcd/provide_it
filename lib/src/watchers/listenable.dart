import 'package:flutter/foundation.dart';

import '../framework/framework.dart';

class ListenableWatcher extends Watcher<Listenable> {
  @override
  void init() {
    value.addListener(notify);
  }

  @override
  void cancel() {
    value.removeListener(notify);
  }
}
