import 'package:flutter/material.dart';
import 'package:fudo_v2/core/theme/global_colors.dart';
import 'package:fudo_v2/data/api/applicense_api.dart';
import 'package:fudo_v2/data/api/posmast_api.dart';
import 'package:fudo_v2/data/api/validuser_api.dart';
import 'package:fudo_v2/data/database/db_manager.dart';
import 'package:fudo_v2/pages/counter_selection_page.dart';
import 'package:fudo_v2/pages/login_page.dart';

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late Future<bool> _setupComplete;
  bool _completedSetup = false;
  List<Map<String, dynamic>>? _setupCounters;

  @override
  void initState() {
    super.initState();
    _setupComplete = DBManager.isInitialSetupComplete();
  }

  @override
  Widget build(BuildContext context) {
    if (_completedSetup) return _buildCounterSelectionPage(context);

    return FutureBuilder<bool>(
      future: _setupComplete,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StartupError(
            message: 'Could not load app setup: ${snapshot.error}',
            onRetry: () => setState(() {
              _setupComplete = DBManager.isInitialSetupComplete();
            }),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data!) return _buildCounterSelectionPage(context);

        return InitialSetupPage(
          onSaved: (counters) => setState(() {
            _setupCounters = counters;
            _completedSetup = true;
          }),
        );
      },
    );
  }

  Widget _buildCounterSelectionPage(BuildContext context) {
    return CounterSelectionPage(
      initialCounters: _setupCounters,
      onSelected: (counterNo) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => LoginPage(selectedCounterNo: counterNo),
          ),
        );
      },
    );
  }
}

class InitialSetupPage extends StatefulWidget {
  const InitialSetupPage({required this.onSaved, super.key});

  final ValueChanged<List<Map<String, dynamic>>> onSaved;

  @override
  State<InitialSetupPage> createState() => _InitialSetupPageState();
}

class _InitialSetupPageState extends State<InitialSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _clientIdController = TextEditingController();
  final _locationIdController = TextEditingController();
  final _nodeApiController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  List<Map<String, dynamic>>? _setupRows;
  String? _setupClientType;
  String? _setupLocationId;

  @override
  void initState() {
    super.initState();
    _loadExistingValues();
  }

  Future<void> _loadExistingValues() async {
    try {
      final values = await Future.wait<Object?>([
        DBManager.getClientInfo(),
        DBManager.getCounterInfo(),
        DBManager.getAppConfig('POS_PRINTER_API_BASE_URL'),
      ]);
      if (!mounted) return;
      final clientInfo = values[0] as Map<String, dynamic>?;
      final counterInfo = values[1] as Map<String, dynamic>?;
      _clientIdController.text = clientInfo?['Client_ID']?.toString() ?? '';
      _locationIdController.text =
          counterInfo?['Location_ID']?.toString() ?? '';
      _nodeApiController.text = (values[2]?.toString() ?? '').replaceFirst(
        RegExp(r'^http://', caseSensitive: false),
        '',
      );
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _locationIdController.dispose();
    _nodeApiController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_setupRows != null) {
        await DBManager.saveAppConfig(
          'POS_PRINTER_API_BASE_URL',
          _nodeApiBaseUrl(_nodeApiController.text),
        );
        final api = PosMastApi();
        if (_setupClientType == '2') {
          await api.savePosMastRowsOnServer(_setupRows!);
        } else {
          await api.savePosMastRows(_setupRows!, clearExistingData: true);
        }
        if (!mounted) return;
        widget.onSaved(
          _setupRows!
              .where((row) => row['Counter_No'] != null)
              .map((row) => {...row, 'Location_ID': _setupLocationId})
              .toList(),
        );
        return;
      }
      final clientId = _clientIdController.text.trim();
      final locationId = _locationIdController.text.trim();
      final isValid = await ValidUserApi().isValidClientLocation(
        clientId: clientId,
        locationId: locationId,
      );
      if (!isValid) {
        throw StateError('Client ID or Location ID is invalid.');
      }

      final licenseResult = await AppLicenseApi().syncAppLicense(
        clientId: clientId,
        locationId: locationId,
        clearExistingData: true,
      );
      if (licenseResult.savedCount == 0) {
        throw StateError('App License API returned no valid license data.');
      }
      final clientInfo = await DBManager.getClientInfo();
      final clientType = clientInfo?['Client_Type']?.toString().trim();
      if (clientType != '1' && clientType != '2') {
        throw StateError('App license has an unsupported Client_Type.');
      }
      final rows = await PosMastApi().fetchPosMast(
        clientId: clientId,
        locationId: locationId,
      );
      if (rows.isEmpty) {
        throw StateError('POS_Mast API returned no counters to select.');
      }
      if (!mounted) return;
      setState(() {
        _setupRows = rows;
        _setupClientType = clientType;
        _setupLocationId = locationId;
        _saving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save setup: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      backgroundColor: GlobalColors.homeBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 20 : 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: EdgeInsets.all(compact ? 24 : 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GlobalColors.billingCardBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _loadError != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Setup unavailable'),
                          const SizedBox(height: 8),
                          Text(_loadError!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _loading = true;
                                _loadError = null;
                              });
                              _loadExistingValues();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'FUDO V2',
                              style: TextStyle(
                                color: GlobalColors.primaryText,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _setupRows == null
                                  ? 'Set up this device'
                                  : 'Set API address',
                              style: TextStyle(
                                color: GlobalColors.secondaryText,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _setupRows == null
                                  ? 'We will validate these IDs and download your license and counter details.'
                                  : 'Enter the API IP address to finish setup.',
                              style: TextStyle(
                                color: GlobalColors.secondaryText,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 28),
                            if (_setupRows == null) ...[
                              TextFormField(
                                enabled: !_saving,
                                controller: _clientIdController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Client ID',
                                  hintText: 'Enter your Client_ID',
                                  prefixIcon: Icon(Icons.business_outlined),
                                ),
                                validator: _requiredValue,
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                enabled: !_saving,
                                controller: _locationIdController,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText: 'Location ID',
                                  hintText: 'Enter your Location_ID',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                ),
                                validator: _requiredValue,
                              ),
                            ] else
                              TextFormField(
                                key: const ValueKey('apiAddress'),
                                enabled: !_saving,
                                controller: _nodeApiController,
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText: 'API IP address',
                                  hintText: '192.168.x.xxx:xxx',
                                  prefixIcon: Icon(Icons.dns_outlined),
                                ),
                                validator: _validateNodeApiAddress,
                              ),
                            const SizedBox(height: 28),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      GlobalColors.homeActionBackground,
                                  foregroundColor: Colors.white,
                                ),
                                child: _saving
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _setupRows == null
                                            ? 'Continue'
                                            : 'Save and continue',
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredValue(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String _nodeApiBaseUrl(String value) {
    final address = value.trim().replaceFirst(RegExp(r'/+$'), '');
    return address.contains('://') ? address : 'http://$address';
  }

  String? _validateNodeApiAddress(String? value) {
    final required = _requiredValue(value);
    if (required != null) return required;
    final uri = Uri.tryParse(_nodeApiBaseUrl(value!));
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Enter an IP address like 192.168.1.60:81';
    }
    return null;
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    ),
  );
}
