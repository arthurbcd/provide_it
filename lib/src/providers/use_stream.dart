import 'dart:async';

import '../framework.dart';

extension ContextUseStream on BuildContext {
  /// Creates and subscribes to the [Stream] of [create] and returns its snapshot.
  AsyncSnapshot<T> useStream<T>(
    Stream<T> create()?, {
    T? initialData,
    Object? key,
  }) {
    return bind(_UseStream(create, initialData: initialData, key: key));
  }

  /// Subscribes to an already created [Stream] and returns its snapshot.
  @Deprecated('Use Stream.watch() instead.')
  AsyncSnapshot<T> useStreamValue<T>(
    Stream<T> stream, {
    T? initialData,
    Object? key,
  }) {
    return stream.watch(this, initialData: initialData, key: key);
  }
}

extension StreamWatch<T> on Stream<T> {
  /// Subscribes to this [Stream] and returns its snapshot.
  AsyncSnapshot<T> watch(BuildContext context, {T? initialData, Object? key}) {
    return context.bind(
      _UseStream.value(this, initialData: initialData, key: key),
    );
  }
}

class _UseStream<T> extends HookProvider<AsyncSnapshot<T>> {
  const _UseStream(this.create, {this.initialData, super.key})
    : value = null,
      label = 'useStream';

  const _UseStream.value(this.value, {this.initialData, super.key})
    : create = null,
      label = 'useStreamValue';

  final Stream<T> Function()? create;
  final Stream<T>? value;
  final T? initialData;
  final String label;

  @override
  _StreamHookState<T> createState() => _StreamHookState();
}

/// [StreamBuilder] clone.
class _StreamHookState<T> extends HookState<AsyncSnapshot<T>, _UseStream<T>> {
  @override
  String get debugLabel => '{${provider.label}}<$T>';

  StreamSubscription<T>? _subscription;
  AsyncSnapshot<T> _snapshot = AsyncSnapshot<T>.nothing();

  @override
  void initState() {
    super.initState();
    if (provider.initialData case final data?) {
      _snapshot = AsyncSnapshot.withData(ConnectionState.none, data);
    }
    _subscribe();
  }

  @override
  void didUpdateProvider(covariant _UseStream<T> oldProvider) {
    super.didUpdateProvider(oldProvider);

    if (oldProvider.value != provider.value ||
        (provider.create == null) != (oldProvider.create == null)) {
      if (_subscription != null) {
        _unsubscribe();
        _snapshot = _snapshot.inState(ConnectionState.none);
      }
      _subscribe();
    }
  }

  void _subscribe() {
    final stream = provider.create?.call() ?? provider.value;
    if (stream == null) return;

    _subscription = stream.listen(
      (data) {
        setState(() {
          _snapshot = AsyncSnapshot.withData(ConnectionState.active, data);
        });
      },
      onError: (e, s) {
        setState(() {
          _snapshot = AsyncSnapshot.withError(ConnectionState.active, e, s);
        });
      },
      onDone: () {
        setState(() {
          _snapshot = _snapshot.inState(ConnectionState.done);
        });
      },
    );
    _snapshot = _snapshot.inState(ConnectionState.waiting);
  }

  void _unsubscribe() {
    if (_subscription != null) {
      _subscription!.cancel();
      _subscription = null;
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  AsyncSnapshot<T> build(BuildContext context) {
    return _snapshot;
  }
}
