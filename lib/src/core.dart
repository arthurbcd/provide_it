import 'package:flutter/widgets.dart';

import 'framework/framework.dart';

ProvideItRootElement get _instance => ProvideItRootElement.instance;

@Deprecated('Use `readIt` instead.')
final getIt = readIt;

/// Reads a previously bound value by [T], without context.
final readIt = _instance.readIt;

extension ProvideIt on BuildContext {
  static void log() => _instance.debugTree();

  /// The root of the [ProvideIt] framework.
  ///
  /// This is required to be set at the root of your app.
  static ProvideItRoot root({Key? key, required Widget child}) {
    return ProvideItRoot(key: key, child: child);
  }

  /// Binds [Ref] to this [BuildContext].
  R bind<R, T>(Ref<T> ref) {
    return _instance.bind(this, ref);
  }

  /// Reads a previously bound value by [T] and [key].
  T read<T>({Object? key}) {
    return _instance.read<T>(this, key: key);
  }

  /// Watches a previously bound value by [T] and [key].
  T watch<T>({Object? key}) {
    return _instance.watch<T>(this, key: key);
  }

  /// Selects a previously bound value by [T] and [key].
  R select<T, R>(R selector(T value), {Object? key}) {
    return _instance.select<T, R>(this, selector, key: key);
  }

  /// Listens to a previously bound value by [T] and [key].
  void listen<T>(void listener(T value), {Object? key}) {
    _instance.listen<T>(this, listener, key: key);
  }

  /// Listens to a previously bound value by [T], [selector] and [key].
  void listenSelect<R, T>(
      R selector(T value), void listener(R previous, R next),
      {Object? key}) {
    _instance.listenSelect<T, R>(this, selector, listener, key: key);
  }
}
