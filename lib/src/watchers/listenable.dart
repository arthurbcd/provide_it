import 'package:flutter/foundation.dart';

import '../framework.dart';

class ListenableWatcher extends Watcher<Listenable> {
  @override
  void init() {
    value.addListener(notify);
  }

  @override
  void cancel() {
    value.removeListener(notify);
  }

  @override
  void dispose() {
    // Listenable is not disposable.
  }
}
