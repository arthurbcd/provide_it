import '../framework.dart';

extension UseAutomaticKeepAlive on BuildContext {
  /// Enables or disables automatic keep-alive for the current widget subtree.
  ///
  /// When enabled, the subtree will be kept alive even when it is not visible,
  /// preventing it from being disposed of.
  ///
  /// By default, automatic keep-alive is enabled.
  void useAutomaticKeepAlive({bool keepAlive = true}) {
    if (keepAlive) {
      return bind(const _AutomaticKeepAliveHook(keepAlive: true));
    }
    return bind(const _AutomaticKeepAliveHook(keepAlive: false));
  }
}

class _AutomaticKeepAliveHook extends HookProvider<void> {
  const _AutomaticKeepAliveHook({required this.keepAlive});
  final bool keepAlive;

  @override
  HookState<void, _AutomaticKeepAliveHook> createState() =>
      _AutomaticKeepAliveProviderState();
}

/// Copied from [AutomaticKeepAliveClientMixin].
class _AutomaticKeepAliveProviderState
    extends HookState<void, _AutomaticKeepAliveHook> {
  @override
  String get debugLabel => 'useAutomaticKeepAlive';

  KeepAliveHandle? _keepAliveHandle;

  bool get wantKeepAlive => provider.keepAlive;

  void _ensureKeepAlive() {
    assert(_keepAliveHandle == null);
    _keepAliveHandle = KeepAliveHandle();
    KeepAliveNotification(_keepAliveHandle!).dispatch(context);
  }

  void _releaseKeepAlive() {
    _keepAliveHandle!.dispose();
    _keepAliveHandle = null;
  }

  @protected
  void updateKeepAlive() {
    if (wantKeepAlive) {
      if (_keepAliveHandle == null) {
        _ensureKeepAlive();
      }
    } else {
      if (_keepAliveHandle != null) {
        _releaseKeepAlive();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (wantKeepAlive) {
      _ensureKeepAlive();
    }
  }

  @override
  void deactivate() {
    if (_keepAliveHandle != null) {
      _releaseKeepAlive();
    }
    super.deactivate();
  }

  @override
  void build(BuildContext context) {
    if (wantKeepAlive && _keepAliveHandle == null) {
      _ensureKeepAlive();
    }
  }
}
