import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../vista_modelos/selector_mapa_view_model.dart';

// Importamos Placemark solo para el tipado de retorno del Navigator
import 'package:geocoding/geocoding.dart'; 

class PantallaSelectorMapa extends StatefulWidget {
  const PantallaSelectorMapa({super.key});

  @override
  State<PantallaSelectorMapa> createState() => _PantallaSelectorMapaState();
}

class _PantallaSelectorMapaState extends State<PantallaSelectorMapa> {
  // El controlador del mapa se queda en la vista porque es puramente visual
  final MapController _controladorMapa = MapController();

  void _confirmarUbicacion(SelectorMapaViewModel viewModel) async {
    // Le pedimos al ViewModel que nos consiga los datos exactos del lugar
    Placemark? lugarFinal = await viewModel.obtenerPlacemarkFinal();

    if (!mounted) return;

    if (lugarFinal != null) {
      // Regresamos el objeto Placemark a la pantalla anterior
      Navigator.pop(context, lugarFinal);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al obtener la dirección')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos los cambios del ViewModel (cuando cambia la dirección o está cargando)
    final viewModel = context.watch<SelectorMapaViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar en Misantla'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controladorMapa,
            options: MapOptions(
              initialCenter: viewModel.posicionActual,
              initialZoom: 15.0,
              maxZoom: 18.0,
              minZoom: 13.0,
              // Captura el cambio de posición cuando el mapa deja de moverse
              onMapEvent: (evento) {
                if (evento is MapEventMoveEnd) {
                  // Le enviamos las nuevas coordenadas al cerebro (ViewModel)
                  // Usamos read() porque estamos dentro de un callback, no queremos reconstruir todo
                  context.read<SelectorMapaViewModel>().actualizarPosicionPrevia(evento.camera.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.proyecto_flutter',
              ),
            ],
          ),
          // Marcador fijo en el centro
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35),
              child: Icon(Icons.location_on, size: 50, color: Colors.red),
            ),
          ),
          // Tarjeta que muestra el texto de la calle
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  viewModel.direccionPrevia,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // Botón para confirmar
          Positioned(
            bottom: 30,
            left: 50,
            right: 50,
            child: ElevatedButton(
              onPressed: viewModel.estaCargando 
                  ? null 
                  : () => _confirmarUbicacion(viewModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: viewModel.estaCargando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Confirmar esta ubicación"),
            ),
          ),
        ],
      ),
    );
  }
}