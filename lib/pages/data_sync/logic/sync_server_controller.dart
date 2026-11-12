part of '../data_sync_page.dart';

abstract class _SyncServerController extends State<_SyncServerDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _baseUrl(String value) {
    final address = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final url = address.contains('://') ? address : 'http://$address';
    // The API clients append /api themselves.
    return url.replaceFirst(RegExp(r'/api$', caseSensitive: false), '');
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final address = _baseUrl(_controller.text);
      await UsersApi(baseUrl: address).getUsers();
      await ServerSettings.saveBaseUrl(address);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            'Could not connect or save the address. Check the server '
            'address and port, then retry.\n$error';
      });
    }
  }
}
