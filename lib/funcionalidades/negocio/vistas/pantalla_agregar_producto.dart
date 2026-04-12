import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../vista_modelos/inicio_negocio_view_model.dart';

class PantallaAgregarProducto extends StatefulWidget {
  const PantallaAgregarProducto({super.key});

  @override
  State<PantallaAgregarProducto> createState() => _PantallaAgregarProductoState();
}

class _PantallaAgregarProductoState extends State<PantallaAgregarProducto> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _palabrasClaveCtrl = TextEditingController();

  String _categoria = 'Tacos';
  bool _permitePersonalizacion = true;
  File? _imagenSeleccionada;

  Future<void> _seleccionarImagen() async {
    final resultado = await FilePicker.pickFiles(type: FileType.image);
    if (resultado != null) {
      setState(() {
        _imagenSeleccionada = File(resultado.files.single.path!);
      });
    }
  }

  void _guardar() async {
    if (_formKey.currentState!.validate()) {
      final vm = context.read<InicioNegocioViewModel>();
      final error = await vm.agregarProducto(
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descCtrl.text.trim(),
        precio: double.parse(_precioCtrl.text),
        categoria: _categoria,
        permitePersonalizacion: _permitePersonalizacion,
        palabrasClave: _palabrasClaveCtrl.text.trim(),
        imagen: _imagenSeleccionada,
      );

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Platillo agregado ✅')));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InicioNegocioViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Platillo')),
      body: vm.estaCargando
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _seleccionarImagen,
                  child: Container(
                    width: 150, height: 150,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                        // CORREGIDO AQUÍ: Cambiado a BorderStyle.solid
                        border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid)
                    ),
                    child: _imagenSeleccionada != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_imagenSeleccionada!, fit: BoxFit.cover))
                        : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Icon(Icons.add_a_photo, size: 40, color: Colors.grey), SizedBox(height: 8), Text('Foto del platillo', style: TextStyle(color: Colors.grey))],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre (Ej. Orden de Pastor)', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _precioCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Precio (\$)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                validator: (v) => v!.isEmpty ? 'Ingresa el precio' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _categoria,
                decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Tacos', child: Text('Tacos')),
                  DropdownMenuItem(value: 'Tortas', child: Text('Tortas')),
                  DropdownMenuItem(value: 'Bebidas', child: Text('Bebidas')),
                  DropdownMenuItem(value: 'Postres', child: Text('Postres')),
                  DropdownMenuItem(value: 'Otros', child: Text('Otros')),
                ],
                onChanged: (val) => setState(() => _categoria = val!),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Descripción corta (Opcional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              const Text('Optimización de Búsqueda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _palabrasClaveCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Palabras clave (separadas por coma)',
                    hintText: 'Ej: pastor, cerdo, trompo, especial',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search, color: Colors.blue)
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4),
                child: Text(
                    'Ayuda a los clientes a encontrar este platillo cuando usen el buscador.',
                    style: TextStyle(color: Colors.grey, fontSize: 12)
                ),
              ),
              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
                child: SwitchListTile(
                  title: const Text('¿Permite elegir salsas/verduras?'),
                  subtitle: const Text('Se preguntará al cliente "Con todo o sin..." al pedir.'),
                  value: _permitePersonalizacion,
                  activeColor: Colors.orange,
                  onChanged: (val) => setState(() => _permitePersonalizacion = val),
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _guardar,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.orange),
                child: const Text('Guardar Platillo', style: TextStyle(color: Colors.white, fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}