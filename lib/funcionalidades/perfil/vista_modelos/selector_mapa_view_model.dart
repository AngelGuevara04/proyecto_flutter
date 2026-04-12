import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class SelectorMapaViewModel extends ChangeNotifier {
  // Coordenadas iniciales (Misantla)
  LatLng _posicionActual = const LatLng(19.9288, -96.8520);
  LatLng get posicionActual => _posicionActual;

  String _direccionPrevia = "Mueve el mapa para seleccionar";
  String get direccionPrevia => _direccionPrevia;

  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  // Se llama cada vez que el mapa deja de moverse
  Future<void> actualizarPosicionPrevia(LatLng nuevaPosicion) async {
    _posicionActual = nuevaPosicion;
    notifyListeners(); // Actualiza la posición inmediatamente

    try {
      List<Placemark> lugares = await placemarkFromCoordinates(
        nuevaPosicion.latitude, 
        nuevaPosicion.longitude
      );
      
      if (lugares.isNotEmpty) {
        Placemark lugar = lugares[0];
        _direccionPrevia = "${lugar.thoroughfare ?? ''} ${lugar.subThoroughfare ?? ''}, ${lugar.subLocality ?? ''}".trim();
        
        if (_direccionPrevia.isEmpty || _direccionPrevia == ",") {
          _direccionPrevia = "Dirección no encontrada";
        }
        notifyListeners(); // Avisa a la vista que ya tenemos el texto de la calle
      }
    } catch (e) {
      debugPrint('Error obteniendo dirección previa: $e');
    }
  }

  // Se llama al presionar el botón de confirmar. Devuelve el objeto Placemark final.
  Future<Placemark?> obtenerPlacemarkFinal() async {
    _estaCargando = true;
    notifyListeners();

    try {
      List<Placemark> lugares = await placemarkFromCoordinates(
        _posicionActual.latitude, 
        _posicionActual.longitude
      );
      return lugares.isNotEmpty ? lugares[0] : null;
    } catch (e) {
      return null; // Si hay error, devolvemos null para que la vista muestre el SnackBar
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }
}