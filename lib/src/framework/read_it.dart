part of '../framework.dart';

mixin ReadIt on InheritIt {
  @protected
  FutureOr<void> allReady() {
    final futures = <Future<void>>[];

    void isReady(InheritedBind bind) {
      if (bind.isReady() case Future<void> future) {
        futures.add(future);
      }
    }

    _cache.forEach((_, cache) => cache.forEach(isReady));

    if (futures.isNotEmpty) {
      return Future.wait(futures, eagerError: true).then((_) {});
    }
  }

  @protected
  FutureOr<void> isReady<T>(BuildContext context) {
    final state = getInheritedBind<T>(context: context);
    assert(state != null || null is T, 'InheritedProvider<$T> not found.');

    if (state?.isReady() case Future<void> future) {
      return future.then((_) {});
    }
  }

  @protected
  T read<T>(BuildContext context) {
    if (readAsync<T>(context) case T value) return value;
    if (null is T) return null as T;
    throw ProviderNotReadyException('$T is loading');
  }

  @protected
  FutureOr<T> readAsync<T>(BuildContext context, {String? type}) {
    final state = getInheritedBind<T>(context: context, type: type);

    return switch (state?.read()) {
      T value => value,
      Future future => future.then((it) => it as T),
      _ => throw ProviderNotFoundException('$type not found.'),
    };
  }
}
