import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // --- Estados de la Interfaz ---
  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  bool _ocultarContrasena = true;
  bool get ocultarContrasena => _ocultarContrasena;

  // --- Lógica de Seguridad (Bloqueo Progresivo) ---
  int _intentosFallidos = 0;
  DateTime? _bloqueadoHasta;
  Timer? _timerConteo;

  // Calcula cuántos segundos faltan para desbloquear
  int get segundosRestantes {
    if (_bloqueadoHasta == null) return 0;
    final diferencia = _bloqueadoHasta!.difference(DateTime.now()).inSeconds;
    return diferencia > 0 ? diferencia : 0;
  }

  bool get estaBloqueado => segundosRestantes > 0;

  // Alternar el ojo de la contraseña
  void alternarVisibilidadContrasena() {
    _ocultarContrasena = !_ocultarContrasena;
    notifyListeners();
  }

  // Actualiza la UI cada segundo mientras esté bloqueado
  void _iniciarCronometro() {
    _timerConteo?.cancel();
    _timerConteo = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (segundosRestantes <= 0) {
        timer.cancel();
      }
      notifyListeners();
    });
  }

  // Lógica principal de Inicio de Sesión
  Future<String?> iniciarSesion(String correo, String contrasena, Function() enExito) async {
    // 1. Verificamos si el usuario aún debe esperar
    if (estaBloqueado) {
      return 'Demasiados intentos. Espera $segundosRestantes segundos.';
    }

    _estaCargando = true;
    notifyListeners();

    try {
      final respuesta = await _supabase.auth.signInWithPassword(
        email: correo,
        password: contrasena,
      );

      if (respuesta.user != null) {
        // ÉXITO: Reiniciamos todo el historial de errores
        _intentosFallidos = 0;
        _bloqueadoHasta = null;
        _timerConteo?.cancel();
        enExito();
        return null;
      }
      return 'Error desconocido';
    } on AuthException catch (error) {
      _intentosFallidos++;

      // 2. APLICAR CASTIGO: Cada 5 intentos fallidos
      if (_intentosFallidos % 5 == 0) {
        // Bloque 1 (intento 5) -> 10 * 2^0 = 10s
        // Bloque 2 (intento 10) -> 10 * 2^1 = 20s
        // Bloque 3 (intento 15) -> 10 * 2^2 = 40s
        int exponente = (_intentosFallidos ~/ 5) - 1;
        int segundosCastigo = 10 * pow(2, exponente).toInt();

        _bloqueadoHasta = DateTime.now().add(Duration(seconds: segundosCastigo));
        _iniciarCronometro();
      }

      notifyListeners();
      return 'Correo o contraseña incorrectos (Intento $_intentosFallidos)';
    } catch (e) {
      return 'Ocurrió un error inesperado';
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timerConteo?.cancel();
    super.dispose();
  }
}
