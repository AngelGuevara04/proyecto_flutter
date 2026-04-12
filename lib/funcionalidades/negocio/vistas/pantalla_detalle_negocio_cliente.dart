import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vista_modelos/inicio_negocio_view_model.dart';

class PantallaDetalleNegocioCliente extends StatelessWidget {
  const PantallaDetalleNegocioCliente({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InicioNegocioViewModel>();
    final perfil = vm.perfil;
    final productos = vm.productos;
    final fotos = vm.galeriaFotos;

    if (perfil == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));
    }

    // --- LÓGICA DINÁMICA DE ENVÍO CORREGIDA ---
    String textoEnvio = "Envío Gratis";
    Color colorEnvio = Colors.green;
    IconData iconoEnvio = Icons.pedal_bike;

    final tipoEnvio = perfil['tipo_envio'] ?? 'gratis';
    final costoEnvio = perfil['costo_envio'] ?? 0;
    final gratisDesde = perfil['envio_gratis_desde'] ?? 0;

    if (tipoEnvio == 'fijo') {
      textoEnvio = "Envío \$${costoEnvio.toStringAsFixed(2)}";
      colorEnvio = Colors.blue;
      iconoEnvio = Icons.delivery_dining;
    } else if (tipoEnvio == 'umbral') {
      // AQUÍ ESTÁ LA MAGIA: Usamos \n para poner dos líneas en la etiqueta
      textoEnvio = "Envío \$${costoEnvio.toStringAsFixed(0)}\nGratis > \$${gratisDesde.toStringAsFixed(0)}";
      colorEnvio = Colors.deepPurple;
      iconoEnvio = Icons.card_giftcard;
    }

    // --- LÓGICA DE ESTRELLAS ---
    final estrellasStr = (perfil['estrellas'] ?? 5.0).toString();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. CABECERA CON CARRUSEL DE FOTOS
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                  vm.nombreComercial,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black87)]
                  )
              ),
              background: fotos.isEmpty
                  ? Container(color: Colors.grey.shade300, child: const Icon(Icons.storefront, size: 80, color: Colors.white))
                  : PageView.builder(
                itemCount: fotos.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(fotos[index], fit: BoxFit.cover),
                      Container(
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black54],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          ),

          // 2. INFORMACIÓN GENERAL Y BADGES
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _badgeInfo(Icons.timer, "${perfil['tiempo_entrega'] ?? '30 min'}", Colors.orange)),
                      const SizedBox(width: 8),
                      Expanded(child: _badgeInfo(Icons.star, estrellasStr, Colors.amber)),
                      const SizedBox(width: 8),
                      Expanded(child: _badgeInfo(iconoEnvio, textoEnvio, colorEnvio)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text("Información", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _itemContacto(Icons.location_on, perfil['direccion_texto'] ?? "Dirección no especificada"),
                  _itemContacto(Icons.phone, perfil['telefono_movil'] ?? "Teléfono no especificado"),

                  const Divider(height: 40, thickness: 1, color: Colors.black12),
                  const Text("Nuestro Menú", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // 3. LISTA DE PRODUCTOS
          productos.isEmpty
              ? const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(Icons.restaurant_menu, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text("Aún no hay platillos en el menú", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              ),
            ),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final producto = productos[index];
                return _tarjetaProducto(producto);
              },
              childCount: productos.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  // --- WIDGETS DE APOYO (UI) ---

  Widget _badgeInfo(IconData icono, String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Column(
        children: [
          Icon(icono, size: 22, color: color),
          const SizedBox(height: 4),
          Text(
            texto,
            textAlign: TextAlign.center,
            // Ajustamos el tamaño para que quepan las dos líneas sin apretarse
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _itemContacto(IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.4))),
        ],
      ),
    );
  }

  Widget _tarjetaProducto(Map<String, dynamic> producto) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto['nombre'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  if (producto['descripcion'] != null && producto['descripcion'].toString().isNotEmpty)
                    Text(
                        producto['descripcion'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)
                    ),
                  const SizedBox(height: 8),
                  Text(
                      "\$${producto['precio']}",
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  image: producto['url_imagen'] != null
                      ? DecorationImage(image: NetworkImage(producto['url_imagen']), fit: BoxFit.cover)
                      : null
              ),
              child: producto['url_imagen'] == null ? const Icon(Icons.fastfood, color: Colors.grey) : null,
            )
          ],
        ),
      ),
    );
  }
}