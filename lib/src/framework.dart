// ignore_for_file: deprecated_member_use_from_same_package, unused_element

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../provide_it.dart';
import 'utils/tree_map.dart';

part 'framework/provide_it_root.dart';
part 'framework/ref.dart';
part 'framework/ref_state.dart';
part 'framework/ref_widget.dart';

extension ProvideIt on BuildContext {
  ProvideItRootElement get _provider => ProvideItRoot.of(this);

  /// The root of the [ProvideIt] framework.
  ///
  /// This is required to be set at the root of your app.
  static ProvideItRoot root({Key? key, required Widget child}) {
    return ProvideItRoot(key: key, child: child);
  }

  /// Binds [Ref] to this [BuildContext].
  R bind<R, T>(Ref<T> ref) {
    return _provider.bind(this, ref);
  }

  /// Reads a previously bound value by [T] and [key].
  T read<T>({Object? key}) {
    return _provider.read<T>(this, key: key);
  }

  /// Watches a previously bound value by [T] and [key].
  T watch<T>({Object? key}) {
    return _provider.watch<T>(this, key: key);
  }

  /// Selects a previously bound value by [T] and [key].
  R select<T, R>(R selector(T value), {Object? key}) {
    return _provider.select<T, R>(this, selector, key: key);
  }

  /// Listens to a previously bound value by [T] and [key].
  void listen<T>(void listener(T value), {Object? key}) {
    _provider.listen<T>(this, listener, key: key);
  }

  /// Listens to a previously bound value by [T], [selector] and [key].
  void listenSelect<R, T>(
      R selector(T value), void listener(R previous, R next),
      {Object? key}) {
    _provider.listenSelect<T, R>(this, selector, listener, key: key);
  }
}
