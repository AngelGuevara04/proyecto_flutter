import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vista_modelos/pedido_cliente_view_model.dart';
import 'pantalla_confirmar_pedido.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaListaTaquerias extends StatelessWidget {
  final Map<String, dynamic> taqueria;
  const PantallaListaTaquerias({super.key, required this.taqueria});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PedidoClienteViewModel(),
      child: _Contenido(taqueria: taqueria),
    );
  }
}

class _Contenido extends StatefulWidget {
  final Map<String, dynamic> taqueria;
  const _Contenido({required this.taqueria});

  @override
  State<_Contenido> createState() => _ContenidoState();
}

class _ContenidoState extends State<_Contenido> {
  List<dynamic> _productos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    try {
      final supabase = Supabase.instance.client;
      final datos = await supabase
          .from('productos')
          .select()
          .eq('negocio_id', widget.taqueria['usuario_id'])
          .eq('disponible', true)
          .order('categoria');
      setState(() {
        _productos = datos;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PedidoClienteViewModel>();
    final fotos = widget.taqueria['galeria_fotos'];
    List<String> listaFotos = [];
    if (fotos != null) {
      final parsed = fotos is String ? jsonDecode(fotos) : fotos;
      listaFotos = List<String>.from(parsed ?? []);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Cabecera
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.taqueria['nombre_comercial'] ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black54)])),
              background: listaFotos.isNotEmpty
                  ? Image.network(listaFotos[0], fit: BoxFit.cover)
                  : Container(color: Colors.orange.shade300,
                  child: const Icon(Icons.storefront, size: 80, color: Colors.white)),
            ),
          ),

          // Info del negocio
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _badge(Icons.timer,
                      widget.taqueria['tiempo_entrega'] ?? '--', Colors.orange),
                  const SizedBox(width: 10),
                  _badge(Icons.star,
                      (widget.taqueria['estrellas'] ?? 5.0).toString(), Colors.amber),
                  const SizedBox(width: 10),
                  _badge(Icons.payments, 'Efectivo', Colors.green),
                ],
              ),
            ),
          ),

          // Título menú
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Menú',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),

          // Productos
          _cargando
              ? const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: Colors.orange)),
              ))
              : _productos.isEmpty
              ? const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                    child: Text('No hay platillos disponibles',
                        style: TextStyle(color: Colors.grey))),
              ))
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, i) =>
                  _tarjetaProducto(context, vm, _productos[i]),
              childCount: _productos.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // Botón flotante del carrito
      bottomNavigationBar: vm.totalItems > 0
          ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                        value: vm,
                        child: PantallaConfirmarPedido(
                            taqueria: widget.taqueria)))),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white,
                    child: Text('${vm.totalItems}',
                        style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12))),
                const Text('Ver pedido',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('\$${vm.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      )
          : null,
    );
  }

  Widget _tarjetaProducto(
      BuildContext context, PedidoClienteViewModel vm, dynamic producto) {
    final cantidad = vm.cantidadEnCarrito(producto['id'].toString());
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Imagen
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  image: producto['url_imagen'] != null
                      ? DecorationImage(
                      image: NetworkImage(producto['url_imagen']),
                      fit: BoxFit.cover)
                      : null),
              child: producto['url_imagen'] == null
                  ? const Icon(Icons.fastfood, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto['nombre'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  if (producto['descripcion'] != null &&
                      producto['descripcion'].toString().isNotEmpty)
                    Text(producto['descripcion'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                        const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('\$${producto['precio']}',
                      style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ],
              ),
            ),
            // Contador
            Row(
              children: [
                if (cantidad > 0) ...[
                  GestureDetector(
                    onTap: () =>
                        vm.quitarDelCarrito(producto['id'].toString()),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.orange)),
                      child: const Icon(Icons.remove,
                          size: 16, color: Colors.orange),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('$cantidad',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
                GestureDetector(
                  onTap: () => vm.agregarAlCarrito({
                    'id': producto['id'].toString(),
                    'nombre': producto['nombre'],
                    'precio': producto['precio'],
                    'detalles': '',
                  }),
                  child: Container(
                    width: 30, height: 30,
                    decoration: const BoxDecoration(
                        color: Colors.orange, shape: BoxShape.circle),
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icono, String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 4),
          Text(texto,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }
}