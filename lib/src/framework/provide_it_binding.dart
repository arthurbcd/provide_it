part of '../framework.dart';

extension on ProvideItScope {
  int _initTreeIndex(BuildContext? context) {
    if (context == null) return 0;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      // we reset the index for the next build.
      _bindIndex.remove(context);
    });

    return 0;
  }

  Bind<T, Ref<T>> _bind<T>(Element context, Ref<T> ref) {
    final branch = _binds[context] ??= TreeMap();
    final index = _bindIndex[context] ??= _initTreeIndex(context);
    _bindIndex[context] = index + 1;

    Ref<T> getRef(String type) => _element?.overrides[type] as Ref<T>? ?? ref;

    Bind<T, Ref<T>> create() {
      final type = ref.getType();
      ref = getRef(type);

      return branch[index] = ref.createBind()
        .._element = context
        .._scope = this
        .._ref = ref
        ..type = type
        ..index = index
        ..initBind();
    }

    bool canUpdate(Bind<T, Ref<T>> bind) {
      final (oldRef, ref) = (bind.ref, getRef(bind.type));
      return Ref.canUpdate(oldRef, ref);
    }

    Bind<T, Ref<T>> update(Bind<T, Ref<T>> bind) {
      final (oldRef, ref) = (bind.ref, getRef(bind.type));
      return bind
        .._ref = ref
        ..didUpdateRef(oldRef);
    }

    Bind<T, Ref<T>> reset(Bind bind) {
      bind
        ..deactivate()
        ..dispose();
      final (oldRef, ref) = (bind.ref, getRef(bind.type));
      assert(_element!._reassembled || oldRef.runtimeType == ref.runtimeType);
      return create(); // reassembled or key changed
    }

    return switch (branch[index]) {
      null => create(),
      Bind<T, Ref<T>> bind when canUpdate(bind) => update(bind),
      final bind => reset(bind),
    };
  }
}

extension<T> on Ref<T> {
  String getType() {
    final type = create != null ? Injector<T>(create!).type : T.type;
    assert(
      type != 'dynamic' && type != 'Object',
      'This is likely a mistake. Provide a non-generic type.',
    );
    return type;
  }
}
