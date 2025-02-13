import 'package:flutter/widgets.dart';

import 'framework/framework.dart';

@Deprecated('Use `readIt` instead.')
final getIt = readIt;

/// A contextless version of [ProvideIt.read].
final readIt = _instance.readIt;

extension ProvideIt on BuildContext {
  /// The root of the [ProvideIt] framework.
  ///
  /// This is required to be set at the root of your app.
  static ProvideItRoot root({Key? key, required Widget child}) {
    return ProvideItRoot(key: key, child: child);
  }

  /// Logs the current state of the [ProvideIt] framework.
  static void log() => _instance.debugTree();

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
    R selector(T value),
    void listener(R previous, R next), {
    Object? key,
  }) {
    _instance.listenSelect<T, R>(this, selector, listener, key: key);
  }
}

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

ProvideItRootElement get _instance => ProvideItRootElement.instance;
