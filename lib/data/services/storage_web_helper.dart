import 'dart:html' as html;

/// Trigger a browser download for web and return a placeholder path.
String? triggerBrowserDownload(List<int> bytes, String fileName) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
  return 'web_download:$fileName';
}

/// Open a URL in a new browser tab/window. Returns true if invoked.
bool openInBrowser(String url) {
  html.window.open(url, '_blank');
  return true;
}
