part of '../framework.dart';

/// Signature for `void listener(T value)`
typedef Listeners = Map<int, Function>;

/// Signature for `void listenSelector(T previous, R selector(T value))`
typedef Selectors = Map<int, (dynamic, Function)>;

/// Signature for `void listenSelector(R selector(T), void listener(S previous, S next))`
typedef ListenSelectors = Map<int, (dynamic, Function, Function)>;

/// An abstract class that represents the state of a [Ref].
///
/// This class is intended to be extended by other classes that manage the state
/// of a [Ref] of type [T] and a reference type [R] that extends [Ref<T>].
///
/// The [RefState] class provides a base for managing the lifecycle and state
/// transitions of a reference, allowing for more complex state management
/// patterns to be implemented.
///
/// This class is designed with the [State] class of a [StatefulWidget] in mind,
/// and like it, will be used to persist the state of its reference [Ref].
///
/// Type Parameters:
/// - [T]: The type of the value used by [read], [watch], [select], [listen]
/// - [R]: The [Ref] type that this state is associated with.
///
/// See also:
/// - [ProvideRef]
/// - [ValueRef]
///
abstract class RefState<T, R extends Ref<T>> {
  // binding states
  ProvideItElement? _root;
  Element? _element;
  T? _lastReadValue;
  R? _lastRef;
  R? _ref;

  // dependents
  final _watchers = <Element>{};
  final _listeners = <Element, Listeners>{};
  final _selectors = <Element, Selectors>{};
  final _listenSelectors = <Element, ListenSelectors>{};

  // root watchers
  late final _rootWatchers =
      _root!.widget.watchers.where((e) => e.canInit(_lastReadValue))
        ..forEach((watcher) => watcher
          .._state = this
          ..init());

  /// The [Ref] that this state is associated with.
  R get ref => _ref!;

  /// The [context] of [Ref.bind].
  BuildContext get context => _element!;

  /// The type used to [Ref.bind] this state.
  late final type = () {
    final type = T.type;
    assert(
      type != 'dynamic' && type != 'Object',
      'This is likely a mistake. Provide a non-generic type.',
    );
    return type;
  }();

  /// The last value read by [read].
  T? get debugValue => _lastReadValue;

  /// How a [RefState] should be displayed in debug output.
  String get debugLabel {
    final parts = runtimeType.toString().split('<');
    final ref = parts.first.replaceAll('RefState', '').toLowerCase();
    return 'context.$ref<${_lastReadValue?.runtimeType ?? T}>';
  }

  @protected
  @mustCallSuper
  void initState() {}

  @protected
  @mustCallSuper
  void dispose() {
    for (var watcher in _rootWatchers) {
      watcher.cancel();
    }
  }

  @protected
  void didChangeDependencies() {}

  @protected
  @mustCallSuper
  void didUpdateRef(R oldRef) {
    if (updateShouldNotify(oldRef)) notifyDependents();
    _lastRef = oldRef;
  }

  @protected
  bool updateShouldNotify(R oldRef) => false;

  @protected
  void deactivate() {}

  @protected
  void activate() {}

  @protected
  @mustCallSuper
  void reassemble() => _clean();

  @protected
  @mustCallSuper
  void setState(VoidCallback fn) {
    assert(_element != null && _element!.mounted);
    fn();

    _element!.markNeedsBuild();
    notifyDependents();
  }

  @protected
  @mustCallSuper
  void notifyDependents() {
    _watchers.forEach(_markNeedsBuild);
    _listeners.forEach(_listen);
    _selectors.forEach(_select);
    _listenSelectors.forEach(_listenSelect);
  }

  @protected
  @mustCallSuper
  void removeDependent(Element dependent) {
    _watchers.remove(dependent);
    _listeners.remove(dependent);
    _selectors.remove(dependent);
    _listenSelectors.remove(dependent);
  }

  @protected
  @mustCallSuper
  void listen<L>(BuildContext context, int index, Function listener) {
    _assert(context, 'listen');

    tryListen(value) {
      if (value is! L) return;
      listener(value);
    }

    final listeners = _listeners[context as Element] ??= {};
    listeners[index] = tryListen;
  }

  @protected
  @mustCallSuper
  void listenSelect<L, S>(
    BuildContext context,
    int index,
    Function selector,
    Function listener,
  ) {
    _assert(context, 'listenSelect');

    trySelect(value) {
      if (value is! L) return null;
      return selector(value);
    }

    tryListen(previous, next) {
      if (previous is! S || next is! S) return;
      listener(previous, next);
    }

    final listSelectors = _listenSelectors[context as Element] ??= {};
    listSelectors[index] = (trySelect(of(context)), trySelect, tryListen);
  }

  @protected
  @mustCallSuper
  S select<L, S>(BuildContext context, int index, Function selector) {
    _assert(context, 'select');

    trySelect(value) {
      if (value is! L) return null;
      return selector(value);
    }

    final value = trySelect(of(context));
    final selectors = _selectors[context as Element] ??= {};
    selectors[index] = (value, trySelect);

    return value;
  }

  @protected
  @mustCallSuper
  T watch(BuildContext context) {
    _assert(context, 'watch', 'Use `read()` instead.');

    _watchers.add(context as Element);
    return of(context);
  }

  @protected
  @mustCallSuper
  T of(BuildContext context, {bool listen = true}) {
    final value = _lastReadValue = read(context);
    if (listen) _rootWatchers;

    return value;
  }

  /// The method called by [Ref.bind].
  ///
  /// Override this method to make [Ref.bind] return a custom value.
  /// See: [CreateRef] or [ValueRef].
  ///
  /// Some [Ref] may not need to override this method.
  /// See: [ProvideRef].
  @protected
  void bind(BuildContext context) {
    // when void we don't need to self rebuild
    _watchers.remove(context);
  }

  /// The method to construct the value of this [Ref].
  void create();

  /// The value to be read by [watch], [select], [listen] and [listenSelect].
  T read(BuildContext context);

  @override
  String toString() => _debugState();
}

extension RefStateExtension<T> on RefState<T, Ref<T>> {
  /// Attempts to dispose [value] by calling `value.dispose`.
  ///
  /// This won't throw an error if `value.dispose` is not a function.
  void tryDispose(value) {
    for (var watcher in _rootWatchers) {
      watcher.dispose();
    }

    // if there is a proper watcher, we let it dispose the value
    if (_rootWatchers.isNotEmpty) return;

    // well, you should have provided a dispose function, but I'll try
    // to dispose it for you 🫡
    runZonedGuarded(
      () => value.dispose(),
      (e, s) {
        if (e is NoSuchMethodError) return;
        final message = e.toString();
        if (!message.contains('dispose\$0 is not a function') &&
            !message.contains('has no instance method \'dispose\'')) {
          throw e;
        }
      },
    );
  }

  /// Attempts to dispose [value] by calling `value.dispose`.
  ///
  /// This won't throw an error if `value.dispose` is not a function.
  R? tryRun<R>(R fn()) {
    final r = runZonedGuarded(
      () {
        final value = fn();

        return value;
      },
      (e, s) {
        if (e is! TypeError) return;
        final message = e.toString();
        if (!message.contains("type 'Null' is not a subtype of type")) {
          throw e;
        }
      },
    );

    return r;
  }
}
