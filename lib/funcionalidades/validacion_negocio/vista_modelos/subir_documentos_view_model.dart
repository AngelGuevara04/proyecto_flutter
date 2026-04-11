import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubirDocumentosViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  Future<String?> enviarDocumentacion(String rfc, String nombreComercial) async {
    if (rfc.isEmpty || nombreComercial.isEmpty) return 'Campos obligatorios';

    _estaCargando = true;
    notifyListeners();

    try {
      final usuarioId = _supabase.auth.currentUser!.id;

      // 1. Insertamos en la tabla de solicitudes para el admin
      await _supabase.from('solicitudes_registro').insert({
        'usuario_id': usuarioId,
        'nombre_comercial': nombreComercial,
        'rfc': rfc.toUpperCase(),
      });

      // 2. Actualizamos metadatos para que el semáforo sepa que está 'pendiente'
      await _supabase.auth.updateUser(
        UserAttributes(data: {'estatus_aprobacion': 'pendiente'}),
      );

      return null;
    } catch (e) {
      return 'Error al enviar: $e';
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }
}