import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vista_modelos/inicio_negocio_view_model.dart';
import 'pantalla_editar_perfil_negocio.dart';
import 'pantalla_detalle_negocio_cliente.dart';
import 'pantalla_agregar_producto.dart';
import 'pantalla_reportar_cliente.dart';
import 'pantalla_historial_pedidos.dart';

class PantallaInicioNegocio extends StatelessWidget {
  const PantallaInicioNegocio({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InicioNegocioViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.nombreComercial),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: viewModel.cerrarSesion,
          ),
        ],
      ),
      body: viewModel.estaCargando
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _construirCuerpo(context, viewModel),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: viewModel.indiceTab,
        onTap: viewModel.cambiarTab,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Mi Menú'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _construirCuerpo(BuildContext context, InicioNegocioViewModel viewModel) {
    switch (viewModel.indiceTab) {
      case 0: return _buildTabInicio(context, viewModel);
      case 1: return _buildTabPedidos(context, viewModel);
      case 2: return _buildTabMenu(context, viewModel);
      case 3: return _buildTabPerfil(context, viewModel);
      default: return const Center(child: Text('Error de pestaña'));
    }
  }

  Widget _buildTabInicio(BuildContext context, InicioNegocioViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: viewModel.recargarPantalla,
      color: Colors.orange,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¡Hola, ${viewModel.nombreComercial}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Resumen de hoy', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: _tarjetaResumen('Pedidos Hoy', '${viewModel.pedidosHoy}', Icons.shopping_bag, Colors.blue)),
                const SizedBox(width: 10),
                Expanded(child: _tarjetaResumen('Ganancias', '\$${viewModel.gananciasHoy.toStringAsFixed(2)}', Icons.attach_money, Colors.green)),
              ],
            ),
            const SizedBox(height: 10),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.orange, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(viewModel.tiempoPromedioHoy, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const Text('Tiempo promedio de entrega (hoy)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            ListTile(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: viewModel, child: const PantallaHistorialPedidos()))
                );
              },
              leading: const Icon(Icons.history, color: Colors.orange),
              title: const Text('Ver historial de pedidos'),
              subtitle: const Text('Consulta ventas pasadas y horarios'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaResumen(String titulo, String valor, IconData icono, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icono, color: color, size: 40),
            const SizedBox(height: 10),
            Text(valor, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPedidos(BuildContext context, InicioNegocioViewModel viewModel) {
    if (viewModel.pedidosActivos.isEmpty) {
      return RefreshIndicator(
        onRefresh: viewModel.recargarPantalla,
        color: Colors.orange,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tienes pedidos activos', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text('Desliza hacia abajo para actualizar.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.recargarPantalla,
      color: Colors.orange,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: viewModel.pedidosActivos.length,
        itemBuilder: (context, index) {
          final pedido = viewModel.pedidosActivos[index];
          final id = pedido['id'].toString();
          final estado = pedido['estado'];
          final productos = pedido['productos'] as List<dynamic>;

          Color colorEstado = Colors.grey;
          if (estado == 'pendiente') colorEstado = Colors.orange;
          if (estado == 'aceptado') colorEstado = Colors.blue;
          if (estado == 'preparacion') colorEstado = Colors.purple;
          if (estado == 'reparto') colorEstado = Colors.teal;

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pedido #${id.substring(0, 5).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: colorEstado.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: colorEstado)),
                            child: Text(estado.toUpperCase(), style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          // BOTÓN DE REPORTAR EN LA ESQUINA DEL TICKET
                          IconButton(
                            icon: const Icon(Icons.report_problem, color: Colors.redAccent),
                            tooltip: 'Reportar Problema',
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
                                  value: viewModel,
                                  child: PantallaReportarCliente(pedidoActivo: pedido) // Pasamos el pedido completo
                              )));
                            },
                          )
                        ],
                      )
                    ],
                  ),
                  const Divider(),
                  Row(children: [const Icon(Icons.person, size: 16, color: Colors.grey), const SizedBox(width: 8), Text(pedido['nombre_cliente'], style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.location_on, size: 16, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(pedido['direccion_entrega'], style: const TextStyle(color: Colors.grey)))]),
                  const Divider(),
                  const Text('Detalle de la orden:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...productos.map((prod) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${prod['cantidad']}x ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prod['nombre']),
                            if (prod['detalles'] != null && prod['detalles'].toString().isNotEmpty)
                              Text(prod['detalles'], style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                          ],
                        )),
                      ],
                    ),
                  )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total a cobrar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('\$${pedido['total']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _construirBotoneraEstado(viewModel, id, estado)
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _construirBotoneraEstado(InicioNegocioViewModel vm, String id, String estado) {
    if (estado == 'pendiente') {
      return Row(
        children: [
          Expanded(child: OutlinedButton(onPressed: () => vm.actualizarEstadoPedido(id, 'cancelado'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text('Rechazar'))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(onPressed: () => vm.actualizarEstadoPedido(id, 'aceptado'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), child: const Text('Aceptar'))),
        ],
      );
    }
    if (estado == 'aceptado') {
      return ElevatedButton(onPressed: () => vm.actualizarEstadoPedido(id, 'preparacion'), style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40), backgroundColor: Colors.purple, foregroundColor: Colors.white), child: const Text('Iniciar Preparación'));
    }
    if (estado == 'preparacion') {
      return ElevatedButton(onPressed: () => vm.actualizarEstadoPedido(id, 'reparto'), style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40), backgroundColor: Colors.teal, foregroundColor: Colors.white), child: const Text('Enviar a Reparto'));
    }
    if (estado == 'reparto') {
      return ElevatedButton(onPressed: () => vm.actualizarEstadoPedido(id, 'entregado'), style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40), backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text('Marcar como Entregado'));
    }
    return const SizedBox.shrink();
  }

  Widget _buildTabMenu(BuildContext context, InicioNegocioViewModel viewModel) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: viewModel.recargarPantalla,
        color: Colors.orange,
        child: viewModel.productos.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fastfood, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Tu menú está vacío', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text('Toca el botón + para agregar un platillo.'),
                ],
              ),
            ),
          ],
        )
            : ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: viewModel.productos.length,
          itemBuilder: (context, index) {
            final producto = viewModel.productos[index];
            final disponible = producto['disponible'] ?? true;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      image: producto['url_imagen'] != null
                          ? DecorationImage(image: NetworkImage(producto['url_imagen']), fit: BoxFit.cover)
                          : null
                  ),
                  child: producto['url_imagen'] == null ? const Icon(Icons.fastfood, color: Colors.grey) : null,
                ),
                title: Text(producto['nombre'], style: TextStyle(decoration: disponible ? null : TextDecoration.lineThrough, color: disponible ? Colors.black : Colors.grey)),
                subtitle: Text('\$${producto['precio']} • ${producto['categoria']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: disponible,
                      activeColor: Colors.orange,
                      onChanged: (val) => viewModel.cambiarDisponibilidadProducto(producto['id'], val),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmarEliminar(context, viewModel, producto['id']),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: viewModel,
                    child: const PantallaAgregarProducto(),
                  )
              )
          );
        },
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Platillo'),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, InicioNegocioViewModel vm, String id) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Eliminar platillo?'),
          content: const Text('Esto no se puede deshacer.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(
                onPressed: () {
                  vm.eliminarProducto(id);
                  Navigator.pop(ctx);
                },
                child: const Text('Eliminar', style: TextStyle(color: Colors.red))
            ),
          ],
        )
    );
  }

  Widget _buildTabPerfil(BuildContext context, InicioNegocioViewModel viewModel) {
    final perfil = viewModel.perfil;
    if (perfil == null) return const Center(child: Text('No se pudo cargar el perfil'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Configuración Pública', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Text('Esto es lo que ven tus clientes.', style: TextStyle(color: Colors.grey)),
        const Divider(height: 30),
        ListTile(
          leading: const Icon(Icons.phone),
          title: const Text('Teléfono Móvil'),
          subtitle: Text(perfil['telefono_movil'] ?? 'N/A'),
        ),
        ListTile(
          leading: const Icon(Icons.timer),
          title: const Text('Tiempo de Entrega Estimado (Manual)'),
          subtitle: Text(perfil['tiempo_entrega'] ?? 'N/A'),
        ),
        ListTile(
          leading: const Icon(Icons.location_on),
          title: const Text('Dirección Física'),
          subtitle: Text(perfil['direccion_texto'] ?? 'No especificada'),
        ),
        const Divider(height: 30),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: viewModel,
                      child: const PantallaEditarPerfilNegocio(),
                    )
                )
            );
          },
          icon: const Icon(Icons.edit),
          label: const Text('Editar Perfil Completo', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12)
          ),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: viewModel,
                      child: const PantallaDetalleNegocioCliente(),
                    )
                )
            );
          },
          icon: const Icon(Icons.preview),
          label: const Text('Ver como Cliente', style: TextStyle(fontSize: 16)),
        )
      ],
    );
  }
}