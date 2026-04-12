import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InicioClienteViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  // Variable para evitar que el usuario presione el botón varias veces
  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  // Procesa el cierre de sesión y ejecuta la navegación cuando termina
  Future<void> cerrarSesion(Function() enExito) async {
    _estaCargando = true;
    notifyListeners();

    try {
      await _supabase.auth.signOut();
      enExito(); // Avisa a la vista que ya puede cambiar de pantalla
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }
}