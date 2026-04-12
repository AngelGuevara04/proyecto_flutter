import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';

import '../../perfil/vista_modelos/selector_mapa_view_model.dart';
import '../../perfil/vistas/pantalla_selector_mapa.dart';
import '../vista_modelos/inicio_negocio_view_model.dart';

class PantallaEditarPerfilNegocio extends StatefulWidget {
  const PantallaEditarPerfilNegocio({super.key});

  @override
  State<PantallaEditarPerfilNegocio> createState() => _PantallaEditarPerfilNegocioState();
}

class _PantallaEditarPerfilNegocioState extends State<PantallaEditarPerfilNegocio> {
  late TextEditingController _nombreCtrl;
  late TextEditingController _telCtrl;
  late TextEditingController _tiempoCtrl;
  late TextEditingController _dirCtrl;
  late TextEditingController _costoEnvioCtrl;
  late TextEditingController _gratisDesdeCtrl;

  double _latActual = 0;
  double _lngActual = 0;
  String _tipoEnvio = 'gratis';

  @override
  void initState() {
    super.initState();
    final perfil = context.read<InicioNegocioViewModel>().perfil;
    final nombreComercial = context.read<InicioNegocioViewModel>().nombreComercial;

    _nombreCtrl = TextEditingController(text: perfil?['nombre_comercial'] ?? nombreComercial);
    _telCtrl = TextEditingController(text: perfil?['telefono_movil'] ?? '');
    _tiempoCtrl = TextEditingController(text: perfil?['tiempo_entrega'] ?? '');
    _dirCtrl = TextEditingController(text: perfil?['direccion_texto'] ?? '');

    _costoEnvioCtrl = TextEditingController(text: (perfil?['costo_envio'] ?? 0).toString());
    _gratisDesdeCtrl = TextEditingController(text: (perfil?['envio_gratis_desde'] ?? 0).toString());
    _tipoEnvio = perfil?['tipo_envio'] ?? 'gratis';

    _latActual = (perfil?['latitud'] ?? 0).toDouble();
    _lngActual = (perfil?['longitud'] ?? 0).toDouble();
  }

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
      String direccionFormateada = "${lugarSeleccionado.thoroughfare ?? ''} ${lugarSeleccionado.subThoroughfare ?? ''}, ${lugarSeleccionado.subLocality ?? ''}, ${lugarSeleccionado.locality ?? ''}".trim();
      try {
        List<Location> ubicaciones = await locationFromAddress(direccionFormateada);
        if (ubicaciones.isNotEmpty) {
          _latActual = ubicaciones.first.latitude;
          _lngActual = ubicaciones.first.longitude;
        }
      } catch (e) {}

      setState(() {
        _dirCtrl.text = direccionFormateada;
      });
    }
  }

  void _guardar() async {
    final vm = context.read<InicioNegocioViewModel>();

    // Convertimos de texto a número con seguridad
    double costoEnvioParsed = double.tryParse(_costoEnvioCtrl.text) ?? 0.0;
    double gratisDesdeParsed = double.tryParse(_gratisDesdeCtrl.text) ?? 0.0;

    final error = await vm.actualizarInformacionBasica(
      nombre: _nombreCtrl.text,
      telefono: _telCtrl.text,
      tiempo: _tiempoCtrl.text,
      direccion: _dirCtrl.text,
      lat: _latActual,
      lng: _lngActual,
      tipoEnvio: _tipoEnvio,
      costoEnvio: costoEnvioParsed,
      envioGratisDesde: gratisDesdeParsed,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Perfil actualizado ✅')));
      if (error == null) Navigator.pop(context);
    }
  }

  void _manejarSubidaFoto(InicioNegocioViewModel vm) async {
    final error = await vm.agregarFotoGaleria();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InicioNegocioViewModel>();
    final List<String> fotos = vm.galeriaFotos;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Mi Taquería')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre Comercial', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _telCtrl, decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 12),
            TextField(controller: _tiempoCtrl, decoration: const InputDecoration(labelText: 'Tiempo de Entrega (ej. 30 min)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.timer))),
            const SizedBox(height: 12),

            TextField(
                controller: _dirCtrl,
                readOnly: true,
                onTap: _abrirMapa,
                decoration: const InputDecoration(
                  labelText: 'Ubicación en Mapa',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map, color: Colors.orange),
                )
            ),
            const SizedBox(height: 30),

            // --- CONFIGURACIÓN DE ENVÍO ---
            const Text('Configuración de Envío', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _tipoEnvio,
              items: const [
                DropdownMenuItem(value: 'gratis', child: Text('Envío Gratis')),
                DropdownMenuItem(value: 'fijo', child: Text('Costo Fijo')),
                DropdownMenuItem(value: 'umbral', child: Text('Gratis a partir de monto')),
              ],
              onChanged: (val) => setState(() => _tipoEnvio = val!),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            if (_tipoEnvio == 'fijo' || _tipoEnvio == 'umbral') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _costoEnvioCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Costo de envío (\$)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
              ),
            ],
            if (_tipoEnvio == 'umbral') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _gratisDesdeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Gratis a partir de (\$)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.shopping_cart)),
              ),
            ],
            const SizedBox(height: 30),

            // --- GALERÍA ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Galería del Negocio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${fotos.length} / 10', style: TextStyle(color: fotos.length >= 10 ? Colors.red : Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ...List.generate(fotos.length, (index) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                        child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(fotos[index], fit: BoxFit.cover)),
                      ),
                      Positioned(
                        top: -5, right: -5,
                        child: GestureDetector(
                          onTap: vm.estaCargando ? null : () => vm.eliminarFotoGaleria(index),
                          child: const CircleAvatar(radius: 14, backgroundColor: Colors.red, child: Icon(Icons.delete, color: Colors.white, size: 16)),
                        ),
                      )
                    ],
                  );
                }),
                if (fotos.length < 10)
                  GestureDetector(
                    onTap: vm.estaCargando ? null : () => _manejarSubidaFoto(vm),
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: vm.estaCargando
                          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                          : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.add_a_photo, color: Colors.orange, size: 30), Text('Agregar', style: TextStyle(color: Colors.orange))],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: vm.estaCargando ? null : _guardar,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.orange),
              child: const Text('Guardar Cambios', style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}