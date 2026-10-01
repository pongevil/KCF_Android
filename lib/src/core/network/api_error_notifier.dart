/// Decouples [ApiClient] from UI alert widgets.
class ApiErrorNotifier {
  void Function(String message)? onError;

  void showError(String message) => onError?.call(message);
}
