import 'package:flutter/foundation.dart';
import 'package:fudo_v2/features/tables/data/table_repository.dart';
import 'package:fudo_v2/features/tables/domain/table_models.dart';

class TableLayoutProvider extends ChangeNotifier {
  TableLayoutProvider({TableRepository? repository})
    : _repository = repository ?? const TableRepository();

  final TableRepository _repository;
  TableLayoutData? _data;
  Object? _error;
  bool _isLoading = false;

  TableLayoutData? get data => _data;
  Object? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await _repository.loadTableLayout();
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
