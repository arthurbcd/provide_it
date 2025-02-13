part of 'framework.dart';

extension<T, R extends Ref<T>> on RefState<T, R> {
  void _assert(BuildContext context, String method, [String? extra]) {
    assert(
      context.debugDoingBuild,
      '$method() can only be called during build. ${extra ?? ''}',
    );
  }

  void _markNeedsBuild(Element el) {
    assert(el.mounted);
    el.markNeedsBuild();
  }

  void _listen(Element el, Listeners<T> listeners) {
    assert(el.mounted);

    final value = read(el);
    listeners.forEach((_, listener) => listener(value));
  }

  void _listenSelect(Element el, ListenSelectors listenSelectors) {
    assert(el.mounted);
    final val = read(el);

    for (final e in listenSelectors.entries) {
      final (previous, selector, listener) = e.value;
      final value = selector(val);
      final didChange = !Ref.equals(previous, value);

      if (didChange) listener(previous, value);
      _listenSelectors[el]?[e.key] = (value, selector, listener);
    }
  }

  void _select(Element el, Selectors selectors) {
    assert(el.mounted);
    final val = read(el);

    for (final e in selectors.entries) {
      final (previous, selector) = e.value;
      final value = selector(val);
      final didChange = !Ref.equals(previous, value);

      if (didChange) el.markNeedsBuild();
      _selectors[el]?[e.key] = (value, selector);
    }
  }

  void _clean() {
    _lastRef = null;
    _watchers.clear();
    _listeners.clear();
    _selectors.clear();
    _listenSelectors.clear();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      /// on reassemble, [didUpdateRef] should always be called.
      /// null implies that the ref was removed, allowing safe disposal.
      if (_lastRef == null) {
        ProvideItRootElement.instance._disposeRef(context, ref);
      }
    });
  }

  String _debugState() {
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
