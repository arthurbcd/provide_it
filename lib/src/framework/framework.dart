import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:provide_it/src/injector/injector.dart';
import 'package:provide_it/src/injector/param.dart';
import 'package:provide_it/src/watchers/listenable.dart';

import '../../provide_it.dart';
import '../utils/tree_map.dart';
import '../watchers/defaults.dart';

part 'provide_it.dart';
part 'provide_it_binding.dart';
part 'provide_it_caching.dart';
part 'provide_it_element.dart';
part 'ref.dart';
part 'ref_state.dart';
part 'ref_state_cycling.dart';
part 'ref_widget.dart';
part 'watcher.dart';

extension RefExtension<T> on Ref<T> {
  /// Reads the value of this [Ref]. Auto-binds if not already.
  T read(BuildContext context) {
    return _instance.read(context, key: this);
  }

  /// Watches the value of this [Ref]. Auto-binds if not already.
  T watch(BuildContext context) {
    return _instance.watch(context, key: this);
  }

  /// Selects a value from this [Ref] using [selector].
  R select<R>(BuildContext context, R selector(T value)) {
    return _instance.select(context, selector, key: this);
  }

  /// Listens to the value of this [Ref] using [listener].
  void listen(BuildContext context, void listener(T value)) {
    _instance.listen(context, listener, key: this);
  }

  /// Listens to the value of this [Ref] using [selector] and [listener].
  void listenSelect<R>(BuildContext context, R selector(T value),
      void listener(R? previous, R next)) {
    _instance.listenSelect(context, selector, listener, key: this);
  }
}

ProvideItElement get _instance => ProvideItElement.instance;
