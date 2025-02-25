import 'package:flutter/foundation.dart';

import '../framework.dart';

class ChangeNotifierWatcher extends Watcher<ChangeNotifier> {
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
    value.dispose();
  }
}
