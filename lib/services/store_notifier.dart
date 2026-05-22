import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/store.dart';
import 'api_service.dart';

/// Maneja la lista de stores disponibles y los seleccionados por el usuario.
///
/// Comportamiento:
/// - Sin login: todos los stores seleccionados (persiste en SharedPreferences)
/// - Con login: usa las preferencias del usuario (cargadas desde el backend)
///   y al primer login asigna todos por defecto
class StoreNotifier extends ChangeNotifier {
  StoreNotifier._();
  static final instance = StoreNotifier._();

  static const _prefKey = 'selected_store_ids';

  List<Store> _stores = [];
  Set<String> _selectedIds = {};
  bool _loaded = false;

  List<Store> get stores => _stores;
  Set<String> get selectedIds => _selectedIds;
  bool get isLoaded => _loaded;

  /// Todos los IDs seleccionados como lista separada por comas para la API.
  /// Si todos están seleccionados (o ninguno está guardado), retorna null
  /// para no enviar el parámetro y mostrar todos.
  String? get storeIdsParam {
    if (_stores.isEmpty || _selectedIds.length == _stores.length) return null;
    if (_selectedIds.isEmpty) return null;
    return _selectedIds.join(',');
  }

  bool isSelected(String storeId) => _selectedIds.contains(storeId);

  /// Carga stores desde la API e inicializa la selección.
  Future<void> load() async {
    if (_loaded) return;
    try {
      _stores = await ApiService.getStores();
      if (_stores.isEmpty) return;

      // Cargar selección guardada en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefKey);

      if (saved == null) {
        // Primera vez: seleccionar todos
        _selectedIds = _stores.map((s) => s.id).toSet();
        await _persist();
      } else {
        // Filtrar solo IDs que aún existen
        final validIds = _stores.map((s) => s.id).toSet();
        _selectedIds = saved.where((id) => validIds.contains(id)).toSet();
        if (_selectedIds.isEmpty) {
          // Si todos los IDs guardados ya no existen, reiniciar con todos
          _selectedIds = validIds;
          await _persist();
        }
      }

      _loaded = true;
      notifyListeners();
    } catch (_) {}
  }

  /// Aplica preferencias de stores del usuario logueado.
  /// [storeIds] son los IDs guardados en el backend (preferences.stores).
  Future<void> applyUserPreferences(List<String> storeIds) async {
    if (_stores.isEmpty) await load();
    if (storeIds.isEmpty) {
      // Usuario sin preferencia → todos seleccionados
      _selectedIds = _stores.map((s) => s.id).toSet();
    } else {
      final validIds = _stores.map((s) => s.id).toSet();
      _selectedIds = storeIds.where((id) => validIds.contains(id)).toSet();
      if (_selectedIds.isEmpty) _selectedIds = validIds;
    }
    await _persist();
    notifyListeners();
  }

  /// Alterna la selección de un store.
  Future<void> toggle(String storeId) async {
    if (_selectedIds.contains(storeId)) {
      // No permitir deseleccionar el último
      if (_selectedIds.length <= 1) return;
      _selectedIds = Set.from(_selectedIds)..remove(storeId);
    } else {
      _selectedIds = Set.from(_selectedIds)..add(storeId);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, _selectedIds.toList());
  }
}
