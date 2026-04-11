import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PanelAdminViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _solicitudes = [];
  List<Map<String, dynamic>> get solicitudes => _solicitudes;

  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  // Cargar solicitudes pendientes de la DB
  Future<void> consultarSolicitudes() async {
    _estaCargando = true;
    notifyListeners();

    try {
      final datos = await _supabase
          .from('solicitudes_registro')
          .select()
          .eq('estatus', 'pendiente');

      _solicitudes = List<Map<String, dynamic>>.from(datos);
    } catch (e) {
      debugPrint('Error al consultar: $e');
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  // Aprobar negocio
  Future<void> gestionarSolicitud(String idSolicitud, String usuarioId, String nuevoEstatus) async {
    try {
      // 1. Actualizamos la tabla de solicitudes
      await _supabase
          .from('solicitudes_registro')
          .update({'estatus': nuevoEstatus})
          .eq('id', idSolicitud);

      // 2. IMPORTANTE: Aquí deberías usar una Edge Function de Supabase para
      // actualizar los metadatos de OTRO usuario, ya que por seguridad
      // un usuario no puede editar los metadatos de otro directamente desde la App.

      // Por ahora, eliminamos de la lista local para feedback visual
      _solicitudes.removeWhere((s) => s['id'] == idSolicitud);
      notifyListeners();
    } catch (e) {
      debugPrint('Error al gestionar: $e');
    }
  }
}