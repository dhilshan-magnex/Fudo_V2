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
          onSaved: () => setState(() => _completedSetup = true),
        );
      },
    );
  }

  Widget _buildCounterSelectionPage(BuildContext context) {
    return CounterSelectionPage(
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

  final VoidCallback onSaved;

  @override
  State<InitialSetupPage> createState() => _InitialSetupPageState();
}

class _InitialSetupPageState extends State<InitialSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _clientIdController = TextEditingController();
  final _locationIdController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadExistingValues();
  }

  Future<void> _loadExistingValues() async {
    try {
      final values = await Future.wait([
        DBManager.getClientInfo(),
        DBManager.getCounterInfo(),
      ]);
      if (!mounted) return;
      final clientInfo = values[0];
      final counterInfo = values[1];
      _clientIdController.text = clientInfo?['Client_ID']?.toString() ?? '';
      _locationIdController.text =
          counterInfo?['Location_ID']?.toString() ?? '';
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
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final clientId = _clientIdController.text.trim();
      final locationId = _locationIdController.text.trim();
      final isValid = await ValidUserApi().isValidClientLocation(
        clientId: clientId,
        locationId: locationId,
      );
      if (!isValid) {
        throw StateError('Client ID or Location ID is invalid.');
      }

      await DBManager.saveInitialConfiguration(
        clientId: clientId,
        locationId: locationId,
      );
      await AppLicenseApi().syncAppLicense(
        clientId: clientId,
        locationId: locationId,
        clearExistingData: true,
      );
      await PosMastApi().syncPosMast(
        clientId: clientId,
        locationId: locationId,
        clearExistingData: true,
      );
      if (!mounted) return;
      widget.onSaved();
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
                            const Text(
                              'Set up this device',
                              style: TextStyle(
                                color: GlobalColors.secondaryText,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'We’ll validate these IDs and download your license details.',
                              style: TextStyle(
                                color: GlobalColors.secondaryText,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
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
                              controller: _locationIdController,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Location ID',
                                hintText: 'Enter your Location_ID',
                                prefixIcon: Icon(Icons.location_on_outlined),
                              ),
                              validator: _requiredValue,
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
                                    : const Text('Save and continue'),
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
