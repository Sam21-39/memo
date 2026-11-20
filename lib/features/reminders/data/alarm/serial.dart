/// Runs tasks one at a time, in call order. A task that throws fails only its
/// own caller; the next one still runs.
class Serial {
  Future<void> _last = Future.value();

  Future<T> run<T>(Future<T> Function() task) {
    final run = _last.then((_) => task());
    _last = run.then((_) {}, onError: (_) {});
    return run;
  }
}
