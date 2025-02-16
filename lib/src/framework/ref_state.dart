part of 'framework.dart';

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

  /// The [Ref] that was previously associated with this state.
  R? get lastRef => _lastRef;

  /// The [context] of [Ref.bind].
  BuildContext get context => _element!;

  /// The type used to bind this state.
  late final type = () {
    final type = T.toString();
    assert(type != 'dynamic', 'Type must not be dynamic.');
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

    _element?.markNeedsBuild();
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
  void listen(BuildContext context, int index, Function listener) {
    _assert(context, 'listen');

    final listeners = _listeners[context as Element] ??= {};
    listeners[index] = listener;
    _rootWatchers;
  }

  @protected
  @mustCallSuper
  void listenSelect(
    BuildContext context,
    int index,
    Function selector,
    Function listener,
  ) {
    _assert(context, 'listenSelect');

    final value = selector(_read(context));
    final listSelectors = _listenSelectors[context as Element] ??= {};
    listSelectors[index] = (value, selector, listener);
    _rootWatchers;
  }

  @protected
  @mustCallSuper
  S select<S>(BuildContext context, int index, Function selector) {
    _assert(context, 'select');

    final value = selector(_read(context));
    final selectors = _selectors[context as Element] ??= {};
    selectors[index] = (value, selector);
    _rootWatchers;

    return value;
  }

  @protected
  @mustCallSuper
  T watch(BuildContext context) {
    _assert(context, 'watch', 'Use `read()` instead.');

    final value = _read(context);
    _watchers.add(context as Element);
    _rootWatchers;

    return value;
  }

  @protected
  @mustCallSuper
  void removeDependent(Element dependent) {
    _watchers.remove(dependent);
    _listeners.remove(dependent);
    _selectors.remove(dependent);
    _listenSelectors.remove(dependent);
  }

  /// The method called by [Ref.bind].
  ///
  /// Override this method to make [Ref.bind] return a custom value.
  /// See: [CreateRef] or [ValueRef].
  ///
  /// Some [Ref] may not need to override this method.
  /// See: [ProvideRef].
  @protected
  void bind(BuildContext context) {}

  /// The value to be read by [watch], [select], [listen] and [listenSelect].
  @protected
  T read(BuildContext context);

  @override
  String toString() => _debugState();
}

extension RefStateExtension<T> on RefState<T, Ref<T>> {
  /// Attempts to dispose [value] by calling `value.dispose`.
  ///
  /// This won't throw an error if `value.dispose` is not a function.
  void tryDispose(dynamic value) {
    runZonedGuarded(
      () => value.dispose(),
      (e, s) {
        if (e is NoSuchMethodError) return;
        final errorStr = e.toString();
        if (!errorStr.contains('dispose\$0 is not a function') &&
            !errorStr.contains('has no instance method \'dispose\'')) {
          throw e;
        }
      },
    );
  }
}
