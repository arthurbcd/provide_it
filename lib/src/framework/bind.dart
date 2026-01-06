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
/// The [Bind] class provides a base for managing the lifecycle and state
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
/// - [UseValueRef]
///
abstract class Bind<T, R extends Ref<T>> {
  // binding
  late final String type;
  late final ProvideItScope _scope;
  late final Element _element;
  late final int index;
  late final Watcher? _watcher = () {
    if (!_element.mounted) return null;
    assert(value != null);

    for (var watcher in _scope.watchers.reversed) {
      if (watcher.canWatch(value)) {
        return watcher..init(value, notifyObservers);
      }
    }

    return null;
  }();

  // state
  late R _ref;
  R? _lastRef;

  // scoped cache
  final _scopedDependents = <BuildContext>{};

  // observers
  final _watchers = <Element>{};
  final _selectors = <Element, Selectors>{};
  final _listeners = <Element, Listeners>{};
  final _listenSelectors = <Element, ListenSelectors>{};

  /// The [Ref] key used to bind this state.
  Object? get key => ref.key;

  /// The [Ref] that this state is associated with.
  R get ref => _ref;

  /// The [context] this [Ref] is bound to.
  BuildContext get context => _element;

  /// The [Injector] of [Ref.create] in this scope.
  Injector<T>? get injector =>
      ref.create != null ? _scope.injector<T>(ref.create!) : null;

  /// How a [Bind] should be displayed in debug output.
  String get debugLabel {
    final parts = runtimeType.toString().split('<');
    final ref = parts.first.replaceAll('Bind', '').toLowerCase();

    return 'context.$ref<$type>';
  }

  @visibleForTesting
  Set<Element> get dependents => {
        ..._watchers,
        ..._selectors.keys,
        ..._listeners.keys,
        ..._listenSelectors.keys,
      };

  @protected
  @mustCallSuper
  void initBind() {
    context.dependOnBind(this, 'bind');
    _scope._register(this);
  }

  @protected
  @mustCallSuper
  void didUpdateRef(covariant R oldRef) {
    if (updateShouldNotify(oldRef)) notifyObservers();
    _lastRef = oldRef;
  }

  @protected
  bool updateShouldNotify(covariant R oldRef) => false;

  @protected
  @mustCallSuper
  void notifyObservers() {
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

  bool _deactivated = false;

  @protected
  bool get deactivated => _deactivated;

  @protected
  @mustCallSuper
  void deactivate() {
    _deactivated = true;
  }

  @protected
  @mustCallSuper
  void activate() {
    context.dependOnBind(this, 'bind');
    _deactivated = false;
  }

  bool _disposed = false;

  @protected
  @mustCallSuper
  void dispose() {
    if (value case var value?) {
      _watcher?.cancel(value, notifyObservers);
      if (ref.create != null) {
        _watcher?.dispose(value);
      }
    }
    _scope._unregister(this);
    _disposed = true;
  }

  @protected
  @mustCallSuper
  void reassemble() {
    _removeDirty();
  }

  @protected
  @mustCallSuper
  void listen<L>(BuildContext context, Function listener) {
    context.dependOnBind(this, 'listen');

    tryListen(value) {
      if (value is! L) return;
      listener(value);
    }

    final listeners = _listeners[context as Element] ??= {};
    final index = _scope._observerIndex[context]!;

    listeners[index] = tryListen;
  }

  @protected
  @mustCallSuper
  void listenSelect<L, S>(
    BuildContext context,
    Function selector,
    Function listener,
  ) {
    context.dependOnBind(this, 'listenSelect');

    trySelect(value) {
      if (value is! L) return null;
      return selector(value);
    }

    tryListen(previous, next) {
      if (previous is! S || next is! S) return;
      listener(previous, next);
    }

    final value = trySelect(this.value);
    final listenSelectors = _listenSelectors[context as Element] ??= {};
    final index = _scope._observerIndex[context]!;

    listenSelectors[index] = (value, trySelect, tryListen);
  }

  @protected
  @mustCallSuper
  S select<L, S>(BuildContext context, Function selector) {
    context.dependOnBind(this, 'select');

    trySelect(value) {
      if (value is! L) return null;
      return selector(value);
    }

    final value = trySelect(read());
    final selectors = _selectors[context as Element] ??= {};
    final index = _scope._observerIndex[context]!;

    selectors[index] = (value, trySelect);

    return value;
  }

  @protected
  @mustCallSuper
  void watch(BuildContext context) {
    context.dependOnBind(this, 'watch', 'Use `read` instead.');

    _watchers.add(context as Element);
  }

  @protected
  @mustCallSuper
  T read() {
    if (value case final value?) {
      _watcher;
      return value;
    }

    throw NullBindException('$type got null.');
  }

  /// The value to provide.
  ///
  /// Used by [read], [watch], [select], [listen] and [listenSelect].
  T? get value;

  @override
  String toString() => _debugState();
}

class NullBindException implements Exception {
  NullBindException(this.message);
  final String message;

  @override
  String toString() => 'NullBindException: $message';
}

/// Binds marked with [Scope] can use [ContextReaders] and [ContextObservers].
/// Otherwise, are restricted to the current build context. E.g: [ContextUses].
mixin Scope {}
