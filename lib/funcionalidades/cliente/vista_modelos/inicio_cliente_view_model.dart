import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InicioClienteViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  List<Map<String, dynamic>> _taquerias = [];
  List<Map<String, dynamic>> get taquerias => _taquerias;

  List<Map<String, dynamic>> _tarqueriasFiltered = [];
  List<Map<String, dynamic>> get taqueriasFiltradas => _tarqueriasFiltered;

  String _busqueda = '';

  String get nombreUsuario =>
      _supabase.auth.currentUser?.userMetadata?['full_name'] ?? 'Cliente';

  InicioClienteViewModel() {
    cargarTaquerias();
  }

  Future<void> cargarTaquerias() async {
    _estaCargando = true;
    notifyListeners();
    try {
      final datos = await _supabase
          .from('perfiles_negocios')
          .select()
          .order('nombre_comercial');
      _taquerias = List<Map<String, dynamic>>.from(datos);
      _aplicarFiltro();
    } catch (e) {
      debugPrint('Error cargando taquerías: $e');
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  void buscar(String termino) {
    _busqueda = termino.toLowerCase();
    _aplicarFiltro();
    notifyListeners();
  }

  void _aplicarFiltro() {
    if (_busqueda.isEmpty) {
      _tarqueriasFiltered = List.from(_taquerias);
    } else {
      _tarqueriasFiltered = _taquerias.where((t) {
        final nombre = (t['nombre_comercial'] ?? '').toString().toLowerCase();
        final direccion = (t['direccion_texto'] ?? '').toString().toLowerCase();
        return nombre.contains(_busqueda) || direccion.contains(_busqueda);
      }).toList();
    }
  }

  Future<void> cerrarSesion(Function() enExito) async {
    _estaCargando = true;
    notifyListeners();
    try {
      await _supabase.auth.signOut();
      enExito();
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }
}