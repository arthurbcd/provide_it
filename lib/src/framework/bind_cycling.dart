part of '../framework.dart';

extension<T, R extends Ref<T>> on Bind<T, R> {
  void _markNeedsBuild(Element el) {
    assert(el.mounted);

    el.markNeedsBuild();
  }

  void _listen(Element el, Listeners listeners) {
    assert(el.mounted);

    for (final listener in listeners.values) {
      listener(read());
    }
  }

  void _listenSelect(Element el, ListenSelectors listenSelectors) {
    assert(el.mounted);

    listenSelectors.forEach((index, record) {
      final (previous, selector, listener) = record;

      final current = selector(read());
      final didChange = !Ref.equals(previous, current);

      if (didChange) listener(previous, current);
      _listenSelectors[el]?[index] = (current, selector, listener);
    });
  }

  void _select(Element el, Selectors selectors) {
    assert(el.mounted);

    selectors.forEach((index, record) {
      final (previous, selector) = record;

      final current = selector(read());
      final didChange = !Ref.equals(previous, current);

      if (didChange) el.markNeedsBuild();
      _selectors[el]?[index] = (current, selector);
    });
  }

  // we check if developer removed any ref/observer
  void _removeDirty() {
    // they'll be re-added in the next build phase.
    _watchers.clear();
    _listeners.clear();
    _selectors.clear();
    _listenSelectors.clear();

    // it'll be re-set in the next build phase.
    _lastRef = null;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // null implies that the ref was removed
      if (_lastRef == null && !_disposed) {
        _scope._binds[_element]!.remove(index)!
          ..deactivate()
          ..dispose();
      }
    });
  }

  String _debugState() {
    final keyText = ref.key == null ? '' : '#${ref.key}';
    var valueText = type == 'void' ? "'void'" : null;
    valueText ??= '${value ?? 'null'}'.replaceAll('Instance of ', '');
    if (valueText.length > 30) {
      valueText = '${valueText.substring(0, 30)}...';
    }
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
