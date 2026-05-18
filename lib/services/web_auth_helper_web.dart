// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:async';

const _storageKey = 'dealsnap_pending_auth';

/// Opens the OAuth popup in a standard browser window.
void openWebAuthPopup(String url) {
  html.window.open(
    url,
    'dealsnap_auth',
    'width=600,height=700,scrollbars=yes,resizable=yes,status=yes',
  );
}

/// Polls localStorage every 250 ms until the callback URL appears (written by
/// the backend callback page) or the [timeout] expires.
/// Returns the raw callback URL string (e.g. "dealsnap://callback?token=...")
/// or null on timeout.
Future<String?> pollWebAuthCallback({
  Duration timeout = const Duration(minutes: 3),
}) async {
  // Clear any stale entry before we start
  html.window.localStorage.remove(_storageKey);

  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await Future.delayed(const Duration(milliseconds: 250));
    final val = html.window.localStorage[_storageKey];
    if (val != null && val.isNotEmpty) {
      html.window.localStorage.remove(_storageKey);
      return val;
    }
  }
  return null;
}
