import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class PerfilViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // Estados de carga
  bool _estaCargandoGps = false;
  bool get estaCargandoGps => _estaCargandoGps;

  bool _estaGuardando = false;
  bool get estaGuardando => _estaGuardando;

  // Datos básicos del usuario en sesión
  String get nombreUsuario => _supabase.auth.currentUser?.userMetadata?['full_name'] ?? 'Usuario';
  String get correoUsuario => _supabase.auth.currentUser?.email ?? '';

  // Extrae la dirección inicial guardada en la base de datos
  Map<String, String> obtenerDatosDireccion() {
    final metadatos = _supabase.auth.currentUser?.userMetadata;
    return {
      'calle': metadatos?['calle'] ?? '',
      'colonia': metadatos?['colonia'] ?? '',
      'ciudad': metadatos?['ciudad'] ?? '',
      'codigo_postal': metadatos?['codigo_postal'] ?? '',
    };
  }

  // Activa el hardware del teléfono para obtener la ubicación actual
  Future<Placemark?> obtenerUbicacionGps() async {
    _estaCargandoGps = true;
    notifyListeners();

    try {
      bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) {
        throw 'Los servicios de ubicación están desactivados.';
      }

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          throw 'Los permisos de ubicación fueron denegados.';
        }
      }

      if (permiso == LocationPermission.deniedForever) {
        throw 'Los permisos de ubicación están denegados permanentemente.';
      }

      Position posicion = await Geolocator.getCurrentPosition();
      List<Placemark> lugares = await placemarkFromCoordinates(
        posicion.latitude,
        posicion.longitude,
      );

      return lugares.isNotEmpty ? lugares[0] : null;
    } finally {
      _estaCargandoGps = false;
      notifyListeners();
    }
  }

  // Sube los datos a Supabase. Retorna null si es exitoso, o un texto si hay error.
  Future<String?> guardarPerfil(String calle, String colonia, String ciudad, String codigoPostal) async {
    _estaGuardando = true;
    notifyListeners();

    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'calle': calle,
            'colonia': colonia,
            'ciudad': ciudad,
            'codigo_postal': codigoPostal,
          },
        ),
      );
      return null; // Operación exitosa
    } catch (error) {
      return 'Error al guardar el perfil'; 
    } finally {
      _estaGuardando = false;
      notifyListeners();
    }
  }
}