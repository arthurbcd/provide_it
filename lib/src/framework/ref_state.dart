part of 'framework.dart';

typedef _State<T> = RefState<T, Ref<T>>;
typedef _Selector = (dynamic, Function);
typedef _ListenSelector = (dynamic, Function, Function);

abstract class RefState<T, R extends Ref<T>> {
  final _watchers = <Element>{};
  final _listeners = <Element, Map<int, ValueSetter<T>>>{};
  final _selectors = <Element, Map<int, _Selector>>{};
  final _listenSelectors = <Element, Map<int, _ListenSelector>>{};
  Element? _element;
  T? _lastReadValue;
  R? _lastRef;
  R? _ref;

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
  void reassemble() {
    _lastRef = null;
    _watchers.clear();
    _listeners.clear();
    _selectors.clear();
    _listenSelectors.clear();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // on reassemble [didUpdateRef] should always be called
      // so we can safely self-dispose
      if (_lastRef == null) {
        ProvideItRootElement.instance._disposeRef(context, ref);
      }
    });
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
  void setState(VoidCallback fn) {
    fn();
    assert(_element != null && _element!.mounted);
    _element?.markNeedsBuild();
    _watchers.forEach(_markNeedsBuild);
    _listeners.forEach(_listen);
    _selectors.forEach(_select);
    _listenSelectors.forEach(_listenSelect);
  }

  void _markNeedsBuild(Element el) {
    assert(el.mounted);
    el.markNeedsBuild();
  }

  void _listen(Element el, Map<int, ValueSetter<T>> fn) {
    assert(el.mounted);
    final value = read(el);
    fn.forEach((_, listener) => listener(value));
  }

  void _select(Element el, Map<int, _Selector> fn) {
    assert(el.mounted);
    final val = read(el);

    for (final e in fn.entries) {
      final (previous, selector) = e.value;
      final value = selector(val);
      final didChange = !Ref.equals(previous, value);

      if (didChange) el.markNeedsBuild();
      _selectors[el]?[e.key] = (value, selector);
    }
  }

  void _listenSelect(Element el, Map<int, _ListenSelector> fn) {
    assert(el.mounted);
    final val = read(el);

    for (final e in fn.entries) {
      final (previous, selector, listener) = e.value;
      final value = selector(val);
      final didChange = !Ref.equals(previous, value);

      if (didChange) listener(previous, value);
      _listenSelectors[el]?[e.key] = (value, selector, listener);
    }
  }

  void _assert(BuildContext context, String method, [String? extra]) {
    assert(
      context.debugDoingBuild,
      '$method() can only be called during build. ${extra ?? ''}',
    );
  }

  @protected
  void listen(BuildContext context, int index, void listener(T value)) {
    _assert(context, 'listen');
    final branch = _listeners[context as Element] ??= {};
    branch[index] = listener;
  }

  @protected
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
  S select<S>(BuildContext context, int index, S selector(T value)) {
    _assert(context, 'select');

    final value = selector(read(context));
    final branch = _selectors[context as Element] ??= {};
    branch[index] = (value, selector);

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

  @override
  String toString() {
    final keyText = key == null ? '' : '#$key';
    final valueText = '${debugValue ?? 'null'}'.replaceAll('Instance of ', '');
    final desc = [
      if (_watchers.isNotEmpty) 'watchers: ${_watchers.length}',
      if (_listeners.isNotEmpty) 'listeners: ${_listeners.lengthExpanded}',
      if (_selectors.isNotEmpty) 'selectors: ${_selectors.lengthExpanded}',
      if (_listenSelectors.isNotEmpty)
        'listenSelectors: ${_listenSelectors.lengthExpanded}',
    ].join(', ');

    return '${ref.debugLabel}$keyText: $valueText${desc.isNotEmpty ? ', $desc' : ''}';
  }
}

extension on Ref {
  String get debugLabel {
    final parts = runtimeType.toString().split('<');
    final ref = parts.first.replaceAll('Ref', '').toLowerCase();
    final type = parts.last;
    return 'context.$ref<$type';
  }
}

extension<K> on Map<K, Map> {
  int get lengthExpanded => values.fold(0, (sum, value) => sum + value.length);
}
