import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vista_modelos/inicio_cliente_view_model.dart';
import '../vista_modelos/expres_view_model.dart';
import 'pantalla_lista_taquerias.dart';
import 'pantalla_mis_pedidos_cliente.dart';
import 'pantalla_modulo_expres.dart';
import '../../perfil/vistas/pantalla_perfil.dart';
import '../../perfil/vista_modelos/perfil_view_model.dart';

class PantallaInicioCliente extends StatelessWidget {
  const PantallaInicioCliente({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InicioClienteViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TacoHub',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text('Hola, ${viewModel.nombreUsuario.split(' ').first} 👋',
                style: const TextStyle(fontSize: 13)),
          ],
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                        create: (_) => PerfilViewModel(),
                        child: const PantallaPerfil()))),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: viewModel.estaCargando
                ? null
                : () => viewModel.cerrarSesion(() {
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (r) => false);
              }
            }),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: viewModel.cargarTaquerias,
        color: Colors.orange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Buscador
              TextField(
                onChanged: viewModel.buscar,
                decoration: InputDecoration(
                  hintText: 'Buscar taquería...',
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // Accesos rápidos
              Row(
                children: [
                  Expanded(
                    child: _tarjetaAccion(
                      context,
                      icono: Icons.flash_on,
                      label: 'Modo Exprés',
                      color: Colors.deepOrange,
                      subtitulo: 'Pedido rápido',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider(
                                  create: (_) => ExpresViewModel(),
                                  child: const PantallaModuloExpres()))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _tarjetaAccion(
                      context,
                      icono: Icons.receipt_long,
                      label: 'Mis Pedidos',
                      color: Colors.teal,
                      subtitulo: 'Ver historial',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const PantallaMisPedidosCliente())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Título lista
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Taquerías disponibles',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${viewModel.taqueriasFiltradas.length} encontradas',
                      style:
                      const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),

              // Lista de taquerías
              viewModel.estaCargando
                  ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Colors.orange),
                  ))
                  : viewModel.taqueriasFiltradas.isEmpty
                  ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(children: [
                      Icon(Icons.storefront_outlined,
                          size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No hay taquerías disponibles',
                          style: TextStyle(color: Colors.grey)),
                    ]),
                  ))
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: viewModel.taqueriasFiltradas.length,
                itemBuilder: (context, i) {
                  final t = viewModel.taqueriasFiltradas[i];
                  return _tarjetaTaqueria(context, t);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaAccion(
      BuildContext context, {
        required IconData icono,
        required String label,
        required String subtitulo,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icono, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                Text(subtitulo,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // calcular texto de envío
  String _textoEnvio(Map<String, dynamic> taqueria) {
    final tipo = taqueria['tipo_envio'] ?? 'gratis';
    final costo = (taqueria['costo_envio'] ?? 0).toDouble();
    final gratisDesde = (taqueria['envio_gratis_desde'] ?? 0).toDouble();

    if (tipo == 'gratis') return 'Envío gratis';
    if (tipo == 'fijo') return 'Envío \$${costo.toStringAsFixed(0)}';
    if (tipo == 'umbral') {
      return 'Envío \$${costo.toStringAsFixed(0)} • Gratis +\$${gratisDesde.toStringAsFixed(0)}';
    }
    return 'Envío gratis';
  }

  Color _colorEnvio(Map<String, dynamic> taqueria) {
    final tipo = taqueria['tipo_envio'] ?? 'gratis';
    if (tipo == 'gratis') return Colors.green;
    if (tipo == 'fijo') return Colors.blue;
    return Colors.deepPurple;
  }

  Widget _tarjetaTaqueria(
      BuildContext context, Map<String, dynamic> taqueria) {
    final fotosRaw = taqueria['galeria_fotos'];
    String? urlFoto;
    if (fotosRaw != null) {
      try {
        final lista = fotosRaw is String
            ? jsonDecode(fotosRaw) as List
            : fotosRaw as List;
        if (lista.isNotEmpty) urlFoto = lista[0].toString();
      } catch (e) {
        debugPrint('Error parseando galeria_fotos: $e');
      }
    }

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  PantallaListaTaquerias(taqueria: taqueria))),
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            Container(
              height: 140,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: urlFoto != null
                  ? Image.network(urlFoto, fit: BoxFit.cover)
                  : const Center(
                  child: Icon(Icons.storefront,
                      size: 50, color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(taqueria['nombre_comercial'] ?? 'Sin nombre',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(
                              taqueria['direccion_texto'] ??
                                  'Sin dirección',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // ── Chips con envío incluido ──
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _chip(Icons.timer,
                          taqueria['tiempo_entrega'] ?? '-- min',
                          Colors.orange),
                      _chip(Icons.star,
                          (taqueria['estrellas'] ?? 5.0).toString(),
                          Colors.amber),
                      _chip(Icons.delivery_dining,
                          _textoEnvio(taqueria),
                          _colorEnvio(taqueria)),
                      _chip(Icons.payments, 'Efectivo', Colors.green),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icono, String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: color),
          const SizedBox(width: 4),
          Text(texto,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}