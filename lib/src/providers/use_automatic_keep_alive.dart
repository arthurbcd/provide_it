import '../framework.dart';

extension ContextUseAutomaticKeepAlive on BuildContext {
  /// Enables or disables automatic keep-alive for the current widget subtree.
  ///
  /// When enabled, the subtree will be kept alive even when it is not visible,
  /// preventing it from being disposed of.
  ///
  /// By default, automatic keep-alive is enabled.
  /// See: [AutomaticKeepAliveClientMixin].
  void useAutomaticKeepAlive({bool wantKeepAlive = true}) {
    return bind(
      wantKeepAlive
          ? const _UseAutomaticKeepAlive(wantKeepAlive: true)
          : const _UseAutomaticKeepAlive(wantKeepAlive: false),
    );
  }
}

class _UseAutomaticKeepAlive extends HookProvider<void> {
  const _UseAutomaticKeepAlive({required this.wantKeepAlive});

  final bool wantKeepAlive;

  @override
  HookState<void, _UseAutomaticKeepAlive> createState() =>
      _UseAutomaticKeepAliveState();
}

/// Copied from [AutomaticKeepAliveClientMixin].
class _UseAutomaticKeepAliveState
    extends HookState<void, _UseAutomaticKeepAlive> {
  @override
  String get debugLabel => 'useAutomaticKeepAlive';

  KeepAliveHandle? _keepAliveHandle;

  bool get wantKeepAlive => provider.wantKeepAlive;

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
