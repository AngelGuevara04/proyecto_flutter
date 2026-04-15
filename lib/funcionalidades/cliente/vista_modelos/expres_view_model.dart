import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpresViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  double _lat = 0;
  double _lng = 0;
  bool _tieneUbicacion = false;
  bool get tieneUbicacion => _tieneUbicacion;

  String? _pedidoActivoId;
  String? get pedidoActivoId => _pedidoActivoId;

  Future<String?> obtenerUbicacion() async {
    _estaCargando = true;
    notifyListeners();
    try {
      bool activo = await Geolocator.isLocationServiceEnabled();
      if (!activo) return 'Activa el GPS de tu celular';

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return 'Necesitamos acceso a tu ubicación';
      }

      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _lat = pos.latitude;
      _lng = pos.longitude;
      _tieneUbicacion = true;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Error al obtener ubicación';
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  Future<String?> crearPedidoExpres({
    required String descripcion,
    required String direccionEntrega,
    required String referencias,
    required String telefonoContacto,
  }) async {
    if (descripcion.trim().isEmpty) return 'Describe qué quieres ordenar';
    if (direccionEntrega.trim().isEmpty) return 'Ingresa tu dirección de entrega';
    if (telefonoContacto.trim().isEmpty) return 'Ingresa tu número de contacto';
    if (!_tieneUbicacion) return 'Necesitamos tu ubicación para encontrar taquerías cercanas';

    _estaCargando = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser!;
      final meta = user.userMetadata ?? {};

      final respuesta = await _supabase.from('pedidos').insert({
        'cliente_id': user.id,
        'cliente_email': user.email,
        'nombre_cliente': meta['full_name'] ?? 'Cliente',
        'descripcion_expres': descripcion.trim(),
        'direccion_entrega': direccionEntrega.trim(),
        'referencias': referencias.trim(),
        'telefono_contacto': telefonoContacto.trim(),
        'lat_cliente': _lat,
        'lng_cliente': _lng,
        'tipo': 'expres',
        'estado': 'buscando',
        'productos': '[]',
        'total': 0,
      }).select().single();

      _pedidoActivoId = respuesta['id'].toString();
      return null;
    } catch (e) {
      return 'Error al crear pedido: $e';
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }
}