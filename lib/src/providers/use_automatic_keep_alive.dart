import '../framework.dart';

extension ContextUseAutomaticKeepAlive on BuildContext {
  /// Expresses desire to remain alive when offstage, e.g in a [PageView] or [ListView].
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
