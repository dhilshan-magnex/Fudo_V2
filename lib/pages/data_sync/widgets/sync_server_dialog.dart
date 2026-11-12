part of '../data_sync_page.dart';

class _SyncServerDialog extends StatefulWidget {
  const _SyncServerDialog();

  @override
  State<_SyncServerDialog> createState() => _SyncServerDialogState();
}

class _SyncServerDialogState extends _SyncServerController {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: const Text('Configure API server'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter the address of your running API server to '
                  'continue Data Sync.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controller,
                  enabled: !_saving,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'API IP address',
                    hintText: '192.168.1.100:3000',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter the server address and port.';
                    }
                    final uri = Uri.tryParse(_baseUrl(value));
                    if (uri == null ||
                        !['http', 'https'].contains(uri.scheme) ||
                        uri.host.isEmpty ||
                        uri.host.contains(RegExp(r'\s')) ||
                        uri.hasQuery ||
                        uri.hasFragment ||
                        uri.userInfo.isNotEmpty) {
                      return 'Enter a valid HTTP or HTTPS server address.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _save(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Connecting...' : 'Save and sync'),
          ),
        ],
      ),
    );
  }
}
