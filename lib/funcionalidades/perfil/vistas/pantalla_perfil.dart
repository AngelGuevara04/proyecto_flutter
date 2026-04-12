import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import '../vista_modelos/perfil_view_model.dart';
import 'pantalla_selector_mapa.dart'; // Importamos tu pantalla de mapa ya refactorizada
import '../vista_modelos/selector_mapa_view_model.dart'; // Necesario para inyectar el mapa

class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  final _controladorCalle = TextEditingController();
  final _controladorColonia = TextEditingController();
  final _controladorCiudad = TextEditingController();
  final _controladorCodigoPostal = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Llenamos los controladores con la información que el ViewModel saca de Supabase
    final viewModel = context.read<PerfilViewModel>();
    final datos = viewModel.obtenerDatosDireccion();
    
    _controladorCalle.text = datos['calle'] ?? '';
    _controladorColonia.text = datos['colonia'] ?? '';
    _controladorCiudad.text = datos['ciudad'] ?? '';
    _controladorCodigoPostal.text = datos['codigo_postal'] ?? '';
  }

  @override
  void dispose() {
    _controladorCalle.dispose();
    _controladorColonia.dispose();
    _controladorCiudad.dispose();
    _controladorCodigoPostal.dispose();
    super.dispose();
  }

  // Toma el objeto de geocodificación y actualiza las cajas de texto
  void _actualizarCampos(Placemark lugar) {
    setState(() {
      _controladorCalle.text = "${lugar.thoroughfare ?? ''} ${lugar.subThoroughfare ?? ''}".trim();
      _controladorColonia.text = lugar.subLocality ?? '';
      _controladorCiudad.text = lugar.locality ?? '';
      _controladorCodigoPostal.text = lugar.postalCode ?? '';
    });
  }

  // Navega al mapa y espera el resultado
  Future<void> _abrirMapa() async {
    final Placemark? lugarSeleccionado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => SelectorMapaViewModel(),
          child: const PantallaSelectorMapa(),
        ),
      ),
    );

    if (lugarSeleccionado != null) {
      _actualizarCampos(lugarSeleccionado);
    }
  }

  // Pide el GPS al ViewModel y maneja los errores
  Future<void> _procesarGps(PerfilViewModel viewModel) async {
    try {
      Placemark? lugar = await viewModel.obtenerUbicacionGps();
      if (lugar != null) {
        _actualizarCampos(lugar);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Envía los textos al ViewModel para guardarlos
  Future<void> _procesarGuardado(PerfilViewModel viewModel) async {
    final error = await viewModel.guardarPerfil(
      _controladorCalle.text.trim(),
      _controladorColonia.text.trim(),
      _controladorCiudad.text.trim(),
      _controladorCodigoPostal.text.trim(),
    );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el estado general del ViewModel
    final viewModel = context.watch<PerfilViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.orange,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              viewModel.nombreUsuario,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(viewModel.correoUsuario),
            const Divider(height: 40),
            const Text(
              'Dirección de Domicilio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controladorCalle,
              decoration: const InputDecoration(
                labelText: 'Calle y Número',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controladorColonia,
              decoration: const InputDecoration(
                labelText: 'Colonia',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _controladorCiudad,
                    decoration: const InputDecoration(
                      labelText: 'Ciudad',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controladorCodigoPostal,
                    decoration: const InputDecoration(
                      labelText: 'C.P.',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: viewModel.estaCargandoGps ? null : () => _procesarGps(viewModel),
                    icon: viewModel.estaCargandoGps
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: const Text('GPS'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _abrirMapa,
                    icon: const Icon(Icons.map),
                    label: const Text('Mapa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: viewModel.estaGuardando ? null : () => _procesarGuardado(viewModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: viewModel.estaGuardando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }
}