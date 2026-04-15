import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistroViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  bool _esNegocio = false;
  bool get esNegocio => _esNegocio;

  bool _ocultarContrasena = true;
  bool get ocultarContrasena => _ocultarContrasena;

  bool _ocultarConfirmarContrasena = true;
  bool get ocultarConfirmarContrasena => _ocultarConfirmarContrasena;

  void alternarVisibilidadContrasena() {
    _ocultarContrasena = !_ocultarContrasena;
    notifyListeners();
  }

  void alternarVisibilidadConfirmarContrasena() {
    _ocultarConfirmarContrasena = !_ocultarConfirmarContrasena;
    notifyListeners();
  }

  void cambiarTipoNegocio(bool valor) {
    _esNegocio = valor;
    notifyListeners();
  }

  Future<String?> registrarUsuario(
      String nombre,
      String apellidoPat,
      String apellidoMat,
      String correo,
      String contrasena,
      String confirmarContrasena,
      ) async {
    if (nombre.isEmpty ||
        apellidoPat.isEmpty ||
        apellidoMat.isEmpty ||
        correo.isEmpty ||
        contrasena.isEmpty) {
      return 'Por favor completa todos los campos';
    }

    if (contrasena.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    final tieneLetras = contrasena.contains(RegExp(r'[a-zA-Z]'));
    final tieneNumeros = contrasena.contains(RegExp(r'[0-9]'));
    if (!tieneLetras || !tieneNumeros) {
      return 'La contraseña debe combinar letras y números';
    }

    if (contrasena != confirmarContrasena) {
      return 'Las contraseñas no coinciden';
    }

    _estaCargando = true;
    notifyListeners();

    try {
      final rolAsignado = _esNegocio ? 'negocio' : 'usuario';

      await _supabase.auth.signUp(
        email: correo,
        password: contrasena,
        emailRedirectTo: 'tacohub://login',
        data: {
          'first_name': nombre,
          'paternal_last_name': apellidoPat,
          'maternal_last_name': apellidoMat,
          'full_name': '$nombre $apellidoPat $apellidoMat',
          'rol': rolAsignado,
          // Negocio arranca sin solicitud enviada
          // El estatus cambia a 'pendiente' cuando envía documentos
          'estatus_aprobacion':
          rolAsignado == 'negocio' ? 'sin_solicitud' : 'aprobado',
          'perfil_completado': false,
          'suspendido': false,
        },
      );

      return null;
    } on AuthException catch (error) {
      if (error.message == 'User already registered') {
        return 'Este correo ya está registrado';
      }
      return error.message;
    } catch (error) {
      return 'Ocurrió un error inesperado';
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }
}