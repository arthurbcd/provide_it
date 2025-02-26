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
  ProvideItScope? _scope;
  ({Element? element, int index})? _bind;
  T? _lastReadValue;
  R? _lastRef;
  R? _ref;

  /// Whether [RefState] is attached to the widget tree.
  bool get isAttached => _bind!.element != null;

  /// Whether [notifyDependents] should also notify this [RefState.context].
  bool get shouldNotifySelf => false;

  // dependents
  final _watchers = <Element>{};
  final _selectors = <Element, Selectors>{};
  final _listeners = <Element?, Listeners>{};
  final _listenSelectors = <Element?, ListenSelectors>{};

  // value watchers
  final _valueWatchers = <Watcher>{};

  void _initWatching(Object value) {
    if (_valueWatchers.isNotEmpty) return;

    for (var watcher in _scope!.watchers.toSet()) {
      if (watcher.canWatch(value)) {
        _valueWatchers.add(watcher
          .._state = this
          ..init());
      }
    }
  }

  /// The [Ref] that this state is associated with.
  R get ref => _ref!;

  /// The [context] of [Ref.bind].
  BuildContext get context {
    assert(
      _scope!.isAttached,
      'ProvideIt is not attached to the widget tree, `context` is not available.',
    );
    return _bind!.element ?? _scope!._element!;
  }

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
  T? get value => _lastReadValue;

  /// How a [RefState] should be displayed in debug output.
  String get debugLabel {
    final parts = runtimeType.toString().split('<');
    final ref = parts.first.replaceAll('RefState', '').toLowerCase();
    return 'context.$ref<${_lastReadValue?.runtimeType ?? T}>';
  }

  @protected
  @mustCallSuper
  void initState() {
    if (_scope!.isAttached) context.dependOnRefState(this, 'bind');
    final cache = _scope!._treeCache[(type, ref.key)] ??= {};
    cache.add(this);
  }

  @protected
  @mustCallSuper
  void didUpdateRef(R oldRef) {
    if (updateShouldNotify(oldRef)) notifyDependents();
    _lastRef = oldRef;
  }

  @protected
  bool updateShouldNotify(R oldRef) => false;

  @protected
  @mustCallSuper
  void notifyDependents() {
    if (value != null) _initWatching(value!);

    _watchers.forEach(_markNeedsBuild);
    _listeners.forEach(_listen);
    _selectors.forEach(_select);
    _listenSelectors.forEach(_listenSelect);

    if (isAttached && shouldNotifySelf) {
      assert(_bind!.element!.mounted);
      _bind!.element!.markNeedsBuild();
    }
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
  void deactivate() {}

  @protected
  void activate() {}

  @protected
  @mustCallSuper
  void dispose() {
    for (var watcher in _valueWatchers) {
      watcher.cancel();
    }
    _scope!._treeCache.remove((type, ref.key));
  }

  @protected
  @mustCallSuper
  void reassemble() {
    // only hot restart can reassemble [ReadIt] global bindings.
    if (isAttached) _removeDependents();
  }

  @protected
  @mustCallSuper
  void listen<L>(BuildContext context, int index, Function listener) {
    context.dependOnRefState(this, 'listen');

    tryListen(value) {
      if (value is! L) return;
      listener(value);
    }

    final listeners = _listeners[context as Element?] ??= {};
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
    context.dependOnRefState(this, 'listenSelect');

    trySelect(value) {
      if (value is! L) return null;
      return selector(value);
    }

    tryListen(previous, next) {
      if (previous is! S || next is! S) return;
      listener(previous, next);
    }

    final value = trySelect(this.value);
    final listenSelectors = _listenSelectors[context as Element?] ??= {};
    listenSelectors[index] = (value, trySelect, tryListen);
  }

  @protected
  @mustCallSuper
  S select<L, S>(BuildContext context, int index, Function selector) {
    context.dependOnRefState(this, 'select');

    trySelect(value) {
      if (value is! L) return null;
      return selector(value);
    }

    final value = trySelect(_value);
    final selectors = _selectors[context as Element] ??= {};
    selectors[index] = (value, trySelect);

    return value;
  }

  @protected
  @mustCallSuper
  T watch(BuildContext context) {
    context.dependOnRefState(this, 'watch', 'Use `read()` instead.');

    _watchers.add(context as Element);
    return _value;
  }

  T get _value {
    final value = _lastReadValue = read();
    if (isAttached && value != null) _initWatching(value);

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
  void bind(BuildContext context) {}

  /// The method to construct the value of this [Ref].
  void create();

  /// How to locate the value of this [Ref].
  /// Used by [watch], [select], [listen] and [listenSelect].
  /// Ex: `context.read<MyClass>()`
  T read();

  @override
  String toString() => _debugState();
}

extension RefStateExtension<T> on RefState<T, Ref<T>> {
  /// Attempts to dispose [value] by calling `value.dispose`.
  ///
  /// This won't throw an error if `value.dispose` is not a function.
  void tryDispose(value) {
    if (value is num || value is String || value is bool) return;
    if (value is Iterable || value is Map) return;

    // if there is a proper watcher, we let it dispose the value
    if (_valueWatchers.isNotEmpty) {
      for (var watcher in _valueWatchers) {
        watcher.dispose();
      }
      _valueWatchers.clear();
      return;
    }

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
}
