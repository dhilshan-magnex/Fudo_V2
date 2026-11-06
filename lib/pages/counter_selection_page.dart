import 'package:flutter/material.dart';
import 'package:fudo_v2/core/theme/global_colors.dart';
import 'package:fudo_v2/data/database/db_manager.dart';

class CounterSelectionPage extends StatefulWidget {
  const CounterSelectionPage({required this.onSelected, super.key});

  final ValueChanged<String> onSelected;

  @override
  State<CounterSelectionPage> createState() => _CounterSelectionPageState();
}

class _CounterSelectionPageState extends State<CounterSelectionPage> {
  List<Map<String, dynamic>> _counters = const [];
  String? _selectedCounterNo;
  String? _error;
  bool _loading = true;
  bool _savingSelection = false;

  @override
  void initState() {
    super.initState();
    _loadCounters();
  }

  Future<void> _loadCounters() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final counters = await DBManager.getCounterInfos();
      if (!mounted) return;
      setState(() {
        _counters = counters;
        _selectedCounterNo = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _continueWithSelectedCounter() async {
    final counterNo = _selectedCounterNo;
    if (counterNo == null) return;

    setState(() => _savingSelection = true);
    try {
      final selectedCounter = _counters.firstWhere(
        (counter) => counter['Counter_No']?.toString() == counterNo,
      );
      await DBManager.saveSelectedCounterInfo(selectedCounter);
      if (!mounted) return;
      widget.onSelected(counterNo);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save selected counter: $error')),
      );
    } finally {
      if (mounted) setState(() => _savingSelection = false);
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
                      'Select Counter Information',
                      style: TextStyle(
                        color: GlobalColors.secondaryText,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      _buildError()
                    else if (_counters.isEmpty)
                      const Text(
                        'No counters are registered. Complete setup and sync POS Mast first.',
                        style: TextStyle(color: GlobalColors.secondaryText),
                      )
                    else
                      ..._counters.map(_buildCounterOption),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            _selectedCounterNo == null || _savingSelection
                            ? null
                            : _continueWithSelectedCounter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalColors.homeActionBackground,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: GlobalColors
                              .homeActionBackground
                              .withValues(alpha: 0.45),
                        ),
                        child: _savingSelection
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Continue to sign in'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounterOption(Map<String, dynamic> counter) {
    final counterNo = counter['Counter_No']?.toString() ?? '';
    final posId = counter['POS_ID']?.toString().trim();
    final isSelected = counterNo == _selectedCounterNo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected ? const Color(0xFFEAF7F5) : const Color(0xFFF8FAFA),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedCounterNo = counterNo),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? GlobalColors.homeActionBackground
                    : GlobalColors.divider,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.point_of_sale_outlined,
                  color: isSelected
                      ? GlobalColors.homeActionBackground
                      : GlobalColors.secondaryText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Counter $counterNo',
                        style: const TextStyle(
                          color: GlobalColors.primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (posId != null && posId.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'POS $posId',
                          style: const TextStyle(
                            color: GlobalColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected
                      ? GlobalColors.homeActionBackground
                      : GlobalColors.secondaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(_error!, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 12),
      OutlinedButton(onPressed: _loadCounters, child: const Text('Retry')),
    ],
  );
}
