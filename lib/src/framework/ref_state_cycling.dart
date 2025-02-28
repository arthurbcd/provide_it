part of '../framework.dart';

extension<T, R extends Ref<T>> on RefState<T, R> {
  void _markNeedsBuild(Element el) {
    assert(el.mounted);

    el.markNeedsBuild();
  }

  void _listen(Element? el, Listeners listeners) {
    assert(el!.mounted);

    for (final listener in listeners.values) {
      listener(value);
    }
  }

  void _listenSelect(Element? el, ListenSelectors listenSelectors) {
    assert(el!.mounted);

    for (final e in listenSelectors.entries) {
      final (previous, selector, listener) = e.value;

      final current = selector(value);
      final didChange = !Ref.equals(previous, current);

      if (didChange) listener(previous, current);
      _listenSelectors[el]?[e.key] = (current, selector, listener);
    }
  }

  void _select(Element el, Selectors selectors) {
    assert(el.mounted);

    for (final e in selectors.entries) {
      final (previous, selector) = e.value;
      final current = selector(read());
      final didChange = !Ref.equals(previous, current);

      if (didChange) el.markNeedsBuild();
      _selectors[el]?[e.key] = (current, selector);
    }
  }

  void _removeDependents() {
    _lastRef = null;
    _watchers.clear();
    _listeners.clear();
    _selectors.clear();
    _listenSelectors.clear();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      /// on reassemble, [didUpdateRef] should always be called.
      /// null implies that the ref was removed, allowing safe disposal.
      if (_lastRef == null) {
        _scope!._tree[_bind!.element]![_bind!.index]?.dispose();
      }
    });
  }

  String _debugState() {
    final keyText = ref.key == null ? '' : '#${ref.key}';
    final valueText = '${value ?? 'null'}'.replaceAll('Instance of ', '');
    final desc = [
      if (_watchers.isNotEmpty) 'watchers: ${_watchers.length}',
      if (_listeners.isNotEmpty) 'listeners: ${_listeners.lengthExpanded}',
      if (_selectors.isNotEmpty) 'selectors: ${_selectors.lengthExpanded}',
      if (_listenSelectors.isNotEmpty)
        'listenSelectors: ${_listenSelectors.lengthExpanded}',
    ].join(', ');

    return '$debugLabel$keyText: $valueText${desc.isNotEmpty ? ', $desc' : ''}';
  }
}

extension<K> on Map<K, Map> {
  int get lengthExpanded => values.fold(0, (sum, value) => sum + value.length);
}
