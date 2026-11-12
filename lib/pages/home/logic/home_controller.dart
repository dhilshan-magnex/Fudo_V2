part of '../home_page.dart';

// Owns page state, lifecycle, and actions; layout is implemented by the view.
abstract class _HomeController extends State<HomePage> {
  final _clientService = ClientService();

  void _openDataSync() {
    showDialog<void>(context: context, builder: (_) => const DataSyncDialog());
  }

  late final Future<Map<String, dynamic>?> _clientInfoFuture;

  late DateTime _now;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _clientInfoFuture = _clientService.getClientInfo();

    _now = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
