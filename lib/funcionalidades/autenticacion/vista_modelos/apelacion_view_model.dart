import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApelacionViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  Future<String?> enviarApelacion(String motivo) async {
    if (motivo.trim().isEmpty) return 'El motivo no puede estar vacío';

    _estaCargando = true;
    notifyListeners();

    try {
      final usuarioId = _supabase.auth.currentUser!.id;

      // Verificar si ya tiene una apelación en espera
      final pendientes = await _supabase
          .from('apelaciones')
          .select()
          .eq('usuario_id', usuarioId)
          .eq('estatus', 'pendiente');

      if (pendientes.isNotEmpty) {
        return 'Ya tienes una apelación en revisión. Por favor espera la respuesta del Administrador.';
      }

      // Enviar la apelación
      await _supabase.from('apelaciones').insert({
        'usuario_id': usuarioId,
        'motivo': motivo,
      });

      return null;
    } catch (e) {
      return 'Error al enviar tu apelación. Intenta más tarde.';
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }
}