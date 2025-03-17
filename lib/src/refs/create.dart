import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../framework.dart';
import 'ref.dart';

class CreateRef<T> extends Ref<T> {
  const CreateRef(
    this.create, {
    this.dispose,
    super.key,
  });

  @override
  final T Function(CreateContext context) create;

  /// How to dispose the created value.
  final void Function(T value)? dispose;

  @override
  RefState<T, CreateRef<T>> createState() => CreateRefState<T>();
}

class CreateRefState<T> extends RefState<T, CreateRef<T>> {
  final _states = <State>{};

  @override
  late T value = ref.create(CreateContext(this));

  @override
  void activate() {
    for (var state in _states) {
      state.activate();
    }
    super.activate();
  }

  @override
  void dispose() {
    for (var state in _states) {
      state.dispose();
    }
    ref.dispose?.call(value);
    super.dispose();
  }

  @override
  T watch(BuildContext context) {
    super.watch(context);

    return read();
  }
}

extension type CreateContext._(BuildContext context) implements BuildContext {
  static CreateRefState? _currentState;

  /// Creates a [CreateContext] for the current [CreateRef.create].
  factory CreateContext(CreateRefState state) {
    _currentState = state;
    SchedulerBinding.instance.addPostFrameCallback((_) => _currentState = null);

    return CreateContext._(state.context);
  }

  /// Creates a single [TickerProvider] for the current [CreateContext].
  TickerProvider get vsync {
    assert(_currentState != null, 'vsync can only be used on create');
    final state = _TickerProvider(context);
    _currentState?._states.add(state);

    return state;
  }
}

class _TickerProvider extends _State with SingleTickerProviderStateMixin {
  _TickerProvider(this.context);

  @override
  final BuildContext context;
}

class _State extends State {
  @override
  // ignore: must_call_super so only [SingleTickerProviderStateMixin.dispose] is called
  void dispose() {}

  @override
  Widget build(BuildContext context) => throw UnimplementedError();
}
