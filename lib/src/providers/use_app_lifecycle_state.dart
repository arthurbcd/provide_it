import 'dart:ui';

import '../framework.dart';

extension ContextUseAppLifecycleState on BuildContext {
  /// Returns the current app lifecycle state and rebuilds when it changes.
  /// See: [AppLifecycleState].
  AppLifecycleState? useAppLifecycleState() {
    return bind(const _UseAppLifecycleState());
  }
}

class _UseAppLifecycleState extends HookProvider<AppLifecycleState?> {
  const _UseAppLifecycleState();

  @override
  _UseAppLifecycleStateState createState() => _UseAppLifecycleStateState();
}

class _UseAppLifecycleStateState
    extends HookState<AppLifecycleState?, _UseAppLifecycleState>
    with WidgetsBindingObserver {
  @override
  String get debugLabel => 'useAppLifecycleState';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {});
  }

  @override
  AppLifecycleState? build(BuildContext context) {
    return WidgetsBinding.instance.lifecycleState;
  }
}

extension ContextUseAppLifecycleListener on BuildContext {
  /// Listens to app lifecycle events without rebuilding.
  /// See [AppLifecycleListener].
  void useAppLifecycleListener({
    VoidCallback? onResume,
    VoidCallback? onInactive,
    VoidCallback? onHide,
    VoidCallback? onShow,
    VoidCallback? onPause,
    VoidCallback? onRestart,
    VoidCallback? onDetach,
    ValueChanged<AppLifecycleState>? onStateChange,
    AppExitRequestCallback? onExitRequested,
  }) {
    bind(
      _UseAppLifecycleListener(
        onResume: onResume,
        onInactive: onInactive,
        onHide: onHide,
        onShow: onShow,
        onPause: onPause,
        onRestart: onRestart,
        onDetach: onDetach,
        onStateChange: onStateChange,
        onExitRequested: onExitRequested,
      ),
    );
  }
}

class _UseAppLifecycleListener extends HookProvider<void> {
  const _UseAppLifecycleListener({
    this.onResume,
    this.onInactive,
    this.onHide,
    this.onShow,
    this.onPause,
    this.onRestart,
    this.onDetach,
    this.onStateChange,
    this.onExitRequested,
  });

  final VoidCallback? onResume;
  final VoidCallback? onInactive;
  final VoidCallback? onHide;
  final VoidCallback? onShow;
  final VoidCallback? onPause;
  final VoidCallback? onRestart;
  final VoidCallback? onDetach;
  final ValueChanged<AppLifecycleState>? onStateChange;
  final AppExitRequestCallback? onExitRequested;

  @override
  _UseAppLifecycleListenerState createState() =>
      _UseAppLifecycleListenerState();
}

class _UseAppLifecycleListenerState
    extends HookState<void, _UseAppLifecycleListener>
    with WidgetsBindingObserver {
  @override
  String get debugLabel => 'useAppLifecycleListener';

  AppLifecycleState? _lifecycleState;

  @override
  void initState() {
    super.initState();
    _lifecycleState = WidgetsBinding.instance.lifecycleState;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    return provider.onExitRequested?.call() ?? AppExitResponse.exit;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final AppLifecycleState? previousState = _lifecycleState;
    if (state == previousState) {
      return;
    }
    _lifecycleState = state;
    switch (state) {
      case AppLifecycleState.resumed:
        assert(
          previousState == null ||
              previousState == AppLifecycleState.inactive ||
              previousState == AppLifecycleState.detached,
          'Invalid state transition from $previousState to $state',
        );
        provider.onResume?.call();
      case AppLifecycleState.inactive:
        assert(
          previousState == null ||
              previousState == AppLifecycleState.hidden ||
              previousState == AppLifecycleState.resumed,
          'Invalid state transition from $previousState to $state',
        );
        if (previousState == AppLifecycleState.hidden) {
          provider.onShow?.call();
        } else if (previousState == null ||
            previousState == AppLifecycleState.resumed) {
          provider.onInactive?.call();
        }
      case AppLifecycleState.hidden:
        assert(
          previousState == null ||
              previousState == AppLifecycleState.paused ||
              previousState == AppLifecycleState.inactive,
          'Invalid state transition from $previousState to $state',
        );
        if (previousState == AppLifecycleState.paused) {
          provider.onRestart?.call();
        } else if (previousState == null ||
            previousState == AppLifecycleState.inactive) {
          provider.onHide?.call();
        }
      case AppLifecycleState.paused:
        assert(
          previousState == null || previousState == AppLifecycleState.hidden,
          'Invalid state transition from $previousState to $state',
        );
        if (previousState == null ||
            previousState == AppLifecycleState.hidden) {
          provider.onPause?.call();
        }
      case AppLifecycleState.detached:
        assert(
          previousState == null || previousState == AppLifecycleState.paused,
          'Invalid state transition from $previousState to $state',
        );
        provider.onDetach?.call();
    }
    provider.onStateChange?.call(_lifecycleState!);
  }

  @override
  void build(BuildContext context) {}
}
