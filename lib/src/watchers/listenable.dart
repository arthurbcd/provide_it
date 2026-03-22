import '../framework.dart';

class ListenableWatcher extends Watcher<Listenable> {
  const ListenableWatcher();

  @override
  void listen(Listenable value, VoidCallback notify) {
    value.addListener(notify);
  }

  @override
  void cancel(Listenable value, VoidCallback notify) {
    value.removeListener(notify);
  }

  @override
  void dispose(Listenable value) {
    if (value is ChangeNotifier) {
      value.dispose();
    }
  }
}
