import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../vista_modelos/inicio_negocio_view_model.dart';

class PantallaHistorialPedidos extends StatelessWidget {
  const PantallaHistorialPedidos({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InicioNegocioViewModel>();
    final historial = vm.historialPedidos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pedidos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade100,
      // ---> AÑADIMOS REFRESH INDICATOR AQUÍ TAMBIÉN <---
      body: RefreshIndicator(
        onRefresh: vm.recargarPantalla,
        color: Colors.orange,
        child: historial.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: const Center(child: Text('Aún no tienes pedidos finalizados', style: TextStyle(color: Colors.grey, fontSize: 16))),
            )
          ],
        )
            : ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(), // Obligatorio para Pull to Refresh
          padding: const EdgeInsets.all(12),
          itemCount: historial.length,
          itemBuilder: (context, index) {
            final pedido = historial[index];
            final estado = pedido['estado'];
            final productos = pedido['productos'] as List<dynamic>;

            final DateTime fechaRecibido = DateTime.parse(pedido['creado_el']).toLocal();
            final String horaRecibido = DateFormat('dd/MM/yyyy HH:mm').format(fechaRecibido);

            String horaFinal = "No registrada";
            if (pedido['entregado_el'] != null) {
              final DateTime fechaFinal = DateTime.parse(pedido['entregado_el']).toLocal();
              horaFinal = DateFormat('HH:mm').format(fechaFinal);
            }

            Color colorEstado = estado == 'entregado' ? Colors.green : Colors.red;
            IconData iconoEstado = estado == 'entregado' ? Icons.check_circle : Icons.cancel;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  backgroundColor: Colors.white,
                  collapsedBackgroundColor: Colors.white,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Icon(iconoEstado, color: colorEstado, size: 36),
                  title: Text(
                      'Pedido #${pedido['id'].toString().substring(0, 5).toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(pedido['nombre_cliente'], style: const TextStyle(color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text('\$${pedido['total']} • $horaRecibido', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),

                  children: [
                    Container(
                      color: Colors.grey.shade50,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('Recibido a las: ${DateFormat('HH:mm').format(fechaRecibido)}', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.delivery_dining, size: 16, color: colorEstado),
                              const SizedBox(width: 8),
                              Text('${estado == 'entregado' ? 'Entregado' : 'Cancelado'} a las: $horaFinal', style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 24),

                          const Text('Entregado en:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, size: 18, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(child: Text(pedido['direccion_entrega'], style: const TextStyle(color: Colors.black87))),
                            ],
                          ),
                          const Divider(height: 24),

                          const Text('Resumen del pedido:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...productos.map((prod) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                  child: Text('${prod['cantidad']}x', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(prod['nombre'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                      if (prod['detalles'] != null && prod['detalles'].toString().isNotEmpty)
                                        Text(prod['detalles'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}