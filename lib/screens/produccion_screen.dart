import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProduccionScreen extends StatefulWidget {
  const ProduccionScreen({super.key});

  @override
  State<ProduccionScreen> createState() => _ProduccionScreenState();
}

class _ProduccionScreenState extends State<ProduccionScreen> {
  String? _productoId;
  int _cantidadProducida = 0;
  int _stockActual = 0;

  final TextEditingController _cantidadController = TextEditingController();

  Future<void> _cargarStock(String productoId) async {
    final doc = await FirebaseFirestore.instance.collection('productos').doc(productoId).get();
    if (doc.exists) {
      final stock = doc.data()?['stock'] ?? 0;
      setState(() {
        _stockActual = stock;
      });
    }
  }

  Future<void> _guardarProduccion() async {
    if (_productoId == null || _cantidadProducida <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un producto y cantidad válida')),
      );
      return;
    }

    final hoy = DateTime.now();
    final fecha = DateTime(hoy.year, hoy.month, hoy.day);

    // Guardar producción
    final docRef = FirebaseFirestore.instance.collection('produccion_diaria').doc();

    await docRef.set({
      'productoId': _productoId,
      'cantidadProducida': _cantidadProducida,
      'fecha': fecha,
    });

    // Actualizar stock
    final productoRef = FirebaseFirestore.instance.collection('productos').doc(_productoId);
    final productoSnap = await productoRef.get();
    if (productoSnap.exists) {
      final stockActual = productoSnap.data()?['stock'] ?? 0;
      await productoRef.update({'stock': stockActual + _cantidadProducida});
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Producción registrada y stock actualizado')),
    );

    setState(() {
      _productoId = null;
      _stockActual = 0;
      _cantidadProducida = 0;
      _cantidadController.clear();
    });
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('productos')
                .orderBy('nombre')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();

              final productos = snapshot.data!.docs;

              return DropdownButtonFormField<String>(
                value: _productoId,
                hint: const Text('Selecciona un producto'),
                onChanged: (val) {
                  setState(() {
                    _productoId = val;
                    _stockActual = 0;
                  });
                  if (val != null) {
                    _cargarStock(val);
                  }
                },
                items: productos.map((doc) {
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(doc['nombre']),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Producto',
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          if (_productoId != null)
            Text('Stock actual: $_stockActual unidades',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _cantidadController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cantidad producida',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              setState(() {
                _cantidadProducida = int.tryParse(val) ?? 0;
              });
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            onPressed: _guardarProduccion,
            label: const Text('Registrar Producción'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 231, 167, 71),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
