import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../vista_modelos/expres_view_model.dart';
import '../vista_modelos/pedido_cliente_view_model.dart';
import 'pantalla_rastrear_pedido.dart';

class PantallaModuloExpres extends StatefulWidget {
  final String descripcionInicial;
  final String direccionInicial;
  final String referenciasInicial;
  final String telefonoInicial;

  const PantallaModuloExpres({
    super.key,
    this.descripcionInicial = '',
    this.direccionInicial = '',
    this.referenciasInicial = '',
    this.telefonoInicial = '',
  });

  @override
  State<PantallaModuloExpres> createState() =>
      _PantallaModuloExpresState();
}

class _PantallaModuloExpresState extends State<PantallaModuloExpres> {
  late TextEditingController _direccionCtrl;
  late TextEditingController _referenciasCtrl;
  late TextEditingController _telefonoCtrl;

  // Lista de items del pedido
  final List<Map<String, dynamic>> _items = [];

  // Catálogo de tipos
  final List<String> _tiposTaco = [
    'Pastor', 'Bistec', 'Chorizo', 'Suadero', 'Longaniza',
    'Pollo', 'Carnitas', 'Cabeza', 'Lengua', 'Tripa', 'Gringa', 'Otro',
  ];

  final Map<String, double> _preciosEstimados = {
    'Pastor': 20, 'Bistec': 20, 'Chorizo': 18, 'Suadero': 20,
    'Longaniza': 18, 'Pollo': 18, 'Carnitas': 22, 'Cabeza': 20,
    'Lengua': 22, 'Tripa': 18, 'Quesadilla': 25, 'Gringa': 30,
    'Torta': 45, 'Otro': 20,
  };

  String _tipoSeleccionado = 'Pastor';
  int _cantidadSeleccionada = 1;
  String _personalizacion = 'Con todo';

  double get _totalEstimado => _items.fold(
      0, (suma, item) => suma + (item['precio'] * item['cantidad']));

  @override
  void initState() {
    super.initState();
    _telefonoCtrl =
        TextEditingController(text: widget.telefonoInicial);
    _referenciasCtrl =
        TextEditingController(text: widget.referenciasInicial);

    if (widget.direccionInicial.isNotEmpty) {
      _direccionCtrl =
          TextEditingController(text: widget.direccionInicial);
    } else {
      final meta =
          Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
      final calle = meta['calle'] ?? '';
      final colonia = meta['colonia'] ?? '';
      final ciudad = meta['ciudad'] ?? '';
      _direccionCtrl = TextEditingController(
          text: calle.isNotEmpty
              ? '$calle, $colonia, $ciudad'.trim()
              : '');
    }

    Future.microtask(
            () => context.read<ExpresViewModel>().obtenerUbicacion());
  }

  @override
  void dispose() {
    _direccionCtrl.dispose();
    _referenciasCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  void _agregarItem() {
    setState(() {
      final existente = _items.indexWhere((i) =>
      i['tipo'] == _tipoSeleccionado &&
          i['personalizacion'] == _personalizacion);
      if (existente >= 0) {
        _items[existente]['cantidad'] += _cantidadSeleccionada;
      } else {
        _items.add({
          'tipo': _tipoSeleccionado,
          'cantidad': _cantidadSeleccionada,
          'personalizacion': _personalizacion,
          'precio': _preciosEstimados[_tipoSeleccionado] ?? 20.0,
        });
      }
    });
  }

  void _eliminarItem(int index) {
    setState(() => _items.removeAt(index));
  }

  String _generarDescripcion() {
    return _items
        .map((item) =>
    '${item['cantidad']}x ${item['tipo']} (${item['personalizacion']})')
        .join(', ');
  }

  void _mostrarDialogoAgregarItem() {
    // Reiniciamos los valores del modal
    _tipoSeleccionado = _tiposTaco.first;
    _cantidadSeleccionada = 1;
    _personalizacion = 'Con todo';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Agregar al pedido',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Tipo de taco
              const Text('Tipo:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _tipoSeleccionado,
                decoration:
                const InputDecoration(border: OutlineInputBorder()),
                items: _tiposTaco
                    .map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(
                      '$t — \$${_preciosEstimados[t]?.toStringAsFixed(0)}'),
                ))
                    .toList(),
                onChanged: (val) =>
                    setModalState(() => _tipoSeleccionado = val!),
              ),
              const SizedBox(height: 12),

              // Personalización
              const Text('¿Cómo lo quieres?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  'Con todo',
                  'Sin cilantro',
                  'Sin cebolla',
                  'Sin salsa',
                  'Solo carne'
                ]
                    .map((op) => ChoiceChip(
                  label: Text(op),
                  selected: _personalizacion == op,
                  selectedColor: Colors.orange,
                  onSelected: (_) =>
                      setModalState(() => _personalizacion = op),
                ))
                    .toList(),
              ),
              const SizedBox(height: 12),

              // Cantidad
              const Text('Cantidad:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setModalState(() {
                      if (_cantidadSeleccionada > 1)
                        _cantidadSeleccionada--;
                    }),
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.orange),
                  ),
                  Text('$_cantidadSeleccionada',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () =>
                        setModalState(() => _cantidadSeleccionada++),
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  _agregarItem();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48)),
                child: const Text('Agregar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpresViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido Exprés ⚡'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepOrange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.flash_on,
                      color: Colors.deepOrange, size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Agrega lo que quieres y la primera taquería disponible cerca de ti tomará tu pedido.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ubicacion
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: vm.tieneUbicacion
                    ? Colors.green.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    vm.tieneUbicacion
                        ? Icons.location_on
                        : Icons.location_off,
                    color: vm.tieneUbicacion ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    vm.tieneUbicacion
                        ? 'Ubicación obtenida ✅'
                        : vm.estaCargando
                        ? 'Obteniendo ubicación...'
                        : 'Sin ubicación',
                    style: TextStyle(
                      color: vm.tieneUbicacion
                          ? Colors.green
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (!vm.tieneUbicacion && !vm.estaCargando)
                    TextButton(
                      onPressed: () => vm.obtenerUbicacion(),
                      child: const Text('Reintentar',
                          style:
                          TextStyle(color: Colors.deepOrange)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            //Orden
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tu orden',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _mostrarDialogoAgregarItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Lista vacía
            if (_items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12)),
                child: const Column(
                  children: [
                    Icon(Icons.restaurant_menu,
                        size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Agrega los tacos que quieres',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              ...List.generate(_items.length, (i) {
                final item = _items[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepOrange.shade50,
                      child: Text('${item['cantidad']}',
                          style: const TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(item['tipo'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(item['personalizacion']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$${(item['precio'] * item['cantidad']).toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red, size: 20),
                          onPressed: () => _eliminarItem(i),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            // Total estimado
            if (_items.isNotEmpty) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total estimado:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('\$${_totalEstimado.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.amber),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'El total es estimado. La taquería confirmará el precio exacto.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.amber),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Datos de entrega ──
            const Text('Datos de entrega',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _direccionCtrl,
              decoration: const InputDecoration(
                labelText: 'Dirección de entrega',
                border: OutlineInputBorder(),
                prefixIcon:
                Icon(Icons.location_on, color: Colors.deepOrange),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referenciasCtrl,
              decoration: const InputDecoration(
                labelText: 'Referencias (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline,
                    color: Colors.deepOrange),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Número de contacto (10 dígitos)',
                border: OutlineInputBorder(),
                prefixIcon:
                Icon(Icons.phone, color: Colors.deepOrange),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.payments, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Pago en efectivo al recibir.',
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ── Botón enviar ──
            ElevatedButton.icon(
              onPressed: (vm.estaCargando || _items.isEmpty)
                  ? null
                  : () async {
                final tel = _telefonoCtrl.text.trim();
                if (tel.length != 10 ||
                    !RegExp(r'^[0-9]+$').hasMatch(tel)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'El número debe tener exactamente 10 dígitos'),
                          backgroundColor: Colors.red));
                  return;
                }
                if (_direccionCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Ingresa tu dirección'),
                          backgroundColor: Colors.red));
                  return;
                }

                final error = await vm.crearPedidoExpres(
                  descripcion: _generarDescripcion(),
                  direccionEntrega: _direccionCtrl.text.trim(),
                  referencias: _referenciasCtrl.text.trim(),
                  telefonoContacto: tel,
                  items: _items,
                  totalEstimado: _totalEstimado,
                );

                if (!mounted) return;
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(error),
                          backgroundColor: Colors.red));
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => PedidoClienteViewModel(),
                        child: PantallaRastrearPedido(
                            pedidoId: vm.pedidoActivoId!),
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.flash_on),
              label: vm.estaCargando
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : Text(
                  _items.isEmpty
                      ? 'Agrega al menos un item'
                      : 'Buscar taquería exprés (\$${_totalEstimado.toStringAsFixed(0)})',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                _items.isEmpty ? Colors.grey : Colors.deepOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}