part of 'framework.dart';

typedef Listeners<T> = Map<int, void Function(T)>;
typedef Selectors = Map<int, (dynamic, Function)>;
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
  Element? _element;
  T? _lastReadValue;
  R? _lastRef;
  R? _ref;

  // dependencies
  final _watchers = <Element>{};
  final _listeners = <Element, Listeners<T>>{};
  final _selectors = <Element, Selectors>{};
  final _listenSelectors = <Element, ListenSelectors>{};

  /// The [key] of the [Ref].
  Object? get key {
    if (ref.key case ObjectKey key) return key.value;
    return ref.key;
  }

  /// The [Ref] that this state is associated with.
  R get ref => _ref!;

  /// The [Ref] that was previously associated with this state.
  R? get lastRef => _lastRef;

  /// The [context] of [Ref.bind].
  BuildContext get context => _element!;

  /// The last value read by [read].
  T? get debugValue => _lastReadValue;

  @protected
  void initState() {}

  @protected
  void dispose() {}

  @protected
  void didChangeDependencies() {}

  @protected
  @mustCallSuper
  void didUpdateRef(R oldRef) => _lastRef = oldRef;

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
    _watchers.forEach(_markNeedsBuild);
    _listeners.forEach(_listen);
    _selectors.forEach(_select);
    _listenSelectors.forEach(_listenSelect);
  }

  @protected
  @mustCallSuper
  void listen(BuildContext context, int index, void listener(T value)) {
    _assert(context, 'listen');

    final branch = _listeners[context as Element] ??= {};
    branch[index] = listener;
  }

  @protected
  @mustCallSuper
  void listenSelect<S>(
    BuildContext context,
    int index,
    S selector(T value),
    void listener(S previous, S next),
  ) {
    _assert(context, 'listenSelect');

    final value = selector(read(context));
    final branch = _listenSelectors[context as Element] ??= {};
    branch[index] = (value, selector, listener);
  }

  @protected
  @mustCallSuper
  S select<S>(BuildContext context, int index, S selector(T value)) {
    _assert(context, 'select');

    final value = selector(read(context));
    final branch = _selectors[context as Element] ??= {};
    branch[index] = (value, selector);

    return value;
  }

  @protected
  @mustCallSuper
  T watch(BuildContext context) {
    _assert(context, 'watch', 'Use `read()` instead.');

    _watchers.add(context as Element);
    return read(context);
  }

  @protected
  @mustCallSuper
  void removeDependent(Element dependent) {
    _watchers.remove(dependent);
    _listeners.remove(dependent);
    _selectors.remove(dependent);
    _listenSelectors.remove(dependent);
  }

  @override
  String toString() => _debugState();

  /// The value to be read by [watch], [select], [listen] and [listenSelect].
  @protected
  T read(BuildContext context);

  /// The method called by [Ref.bind]. You can override this method to
  /// return a custom value. See [ProvideRef] or [ValueRef].
  @protected
  void build(BuildContext context);
}
