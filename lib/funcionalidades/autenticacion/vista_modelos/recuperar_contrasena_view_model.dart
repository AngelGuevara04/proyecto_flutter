import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecuperarContrasenaViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  Future<String?> enviarCorreoRecuperacion(String correo) async {
    if (correo.isEmpty) return 'Ingresa tu correo electrónico';

    _estaCargando = true;
    notifyListeners();

    try {
      await _supabase.auth.resetPasswordForEmail(correo);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error inesperado al enviar el correo';
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }
}
