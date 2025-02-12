part of '../framework.dart';

typedef _State<T> = RefState<T, Ref<T>>;
typedef _Selector = (dynamic, Function);
typedef _ListenSelector = (dynamic, Function, Function);

abstract class RefState<T, R extends Ref<T>> {
  final _watchers = <Element>{};

  // TODO(arthurbcd): Currently, we can have 1 listener per context.
  // TODO(arthurbcd): Check if we need to remove any listener when disposing.
  final _listeners = <Element, ValueSetter<T>>{};
  final _selectors = <Element, _Selector>{};
  final _listenSelectors = <Element, _ListenSelector>{};
  Element? _element;
  R? _ref;

  /// The [key] of the [Ref].
  Object? get key {
    if (ref.key case ObjectKey key) return key.value;
    return ref.key;
  }

  /// The [Ref] that this state is associated with.
  R get ref => _ref!;

  /// The [context] of [Ref.bind].
  BuildContext get context => _element!;

  @protected
  void initState() {}

  @protected
  void dispose() {}

  @protected
  void didChangeDependencies() {}

  @protected
  void didUpdateRef(R oldRef) {}

  @protected
  void deactivate() {}

  @protected
  void activate() {}

  @protected
  void reassemble() {}

  @protected
  @mustCallSuper
  void setState(VoidCallback fn) {
    fn();
    _element!.markNeedsBuild();

    _garbageCollect();
    _watchers.forEach(_markNeedsBuild);
    _listeners.forEach(_listen);
    _selectors.forEach(_select);
    _listenSelectors.forEach(_listenSelect);
  }

  void _garbageCollect() {
    _watchers.removeWhere((e) => !e.mounted);
    _listeners.removeWhere((e, _) => !e.mounted);
    _selectors.removeWhere((e, _) => !e.mounted);
    _listenSelectors.removeWhere((e, _) => !e.mounted);
  }

  void _markNeedsBuild(Element el) => el.markNeedsBuild();
  void _listen(Element el, ValueSetter<T> fn) => fn(read(el));
  void _select(Element el, _Selector fn) {
    final (previous, selector) = fn;
    final value = selector(read(el));
    final didChange = !Ref.equals(previous, value);

    if (didChange) el.markNeedsBuild();
    _selectors[el] = (value, selector);
  }

  void _listenSelect(Element el, _ListenSelector fn) {
    final (previous, selector, listener) = fn;
    final value = selector(read(el));
    final didChange = !Ref.equals(previous, value);

    if (didChange) listener(previous, value);
    _listenSelectors[el] = (value, selector, listener);
  }

  void _assert(BuildContext context, String method, [String? extra]) {
    assert(
      context.debugDoingBuild,
      '$method() can only be called during build. ${extra ?? ''}',
    );
  }

  @protected
  void listen(BuildContext context, void listener(T value)) {
    _assert(context, 'listen');
    _listeners[context as Element] = listener;
  }

  @protected
  void listenSelect<S>(
    BuildContext context,
    S selector(T value),
    void listener(S previous, S next),
  ) {
    _assert(context, 'listenSelect');

    final value = selector(read(context));
    _listenSelectors[context as Element] = (value, selector, listener);
  }

  @protected
  S select<S>(BuildContext context, S selector(T value)) {
    _assert(context, 'select');

    final value = selector(read(context));
    _selectors[context as Element] = (value, selector);

    return value;
  }

  @protected
  T watch(BuildContext context) {
    _assert(context, 'watch', 'Use `read()` instead.');

    _watchers.add(context as Element);
    return read(context);
  }

  @protected
  T read(BuildContext context);

  @protected
  void build(BuildContext context);
}
