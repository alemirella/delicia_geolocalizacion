import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'carrito_screen.dart';

class OfertasScreen extends StatefulWidget {
  final void Function(int) onCartChanged;
  const OfertasScreen({super.key, required this.onCartChanged});

  @override
  State<OfertasScreen> createState() => _OfertasScreenState();
}

class _OfertasScreenState extends State<OfertasScreen> {
  String convertirEnlaceDriveADirecto(String url) {
    if (url.contains('drive.google.com')) {
      final regex = RegExp(r'/d/([a-zA-Z0-9_-]+)');
      final match = regex.firstMatch(url);
      if (match != null) {
        final id = match.group(1);
        return 'https://drive.google.com/uc?export=view&id=$id';
      }
    }
    return url;
  }

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    final stock = producto['stock'] ?? 0;
    if (stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay stock disponible para este producto')),
      );
      return;
    }

    // Agregar al carrito usando el singleton
    SimpleCart.instance.addItem({
      'id': producto['id'],
      'nombre': producto['nombre'],
      'precio': producto['precio'],
      'cantidad': producto['cantidad'],
      'stock': producto['stock'],
      'imagen': producto['imagen'],
    });

    // Actualizar el contador del carrito
    widget.onCartChanged(
      SimpleCart.instance.items.fold<int>(
          0, (prev, item) => prev + (item['cantidad'] as int)),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${producto['nombre']} añadido al carrito'),
        duration: const Duration(milliseconds: 900),
      ),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        title: const Text('🔥 Ofertas - Próximos a Vencer'),
        backgroundColor: Colors.red.shade600,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('productos')
            .where('en_oferta', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer, size: 100, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay ofertas disponibles por ahora',
                    style: TextStyle(fontSize: 16, color: Colors.brown),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final productos = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: GridView.builder(
              itemCount: productos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.70,
              ),
              itemBuilder: (context, index) {
                final doc = productos[index];
                final data = doc.data() as Map<String, dynamic>;

                final imagen = convertirEnlaceDriveADirecto(data['imagen'] ?? '');
                final nombre = data['nombre'] ?? '';
                final descripcion = data['descripcion'] ?? '';
                final precioOriginal = (data['precio'] ?? 0).toDouble();
                final descuento = (data['descuento'] ?? 10).toInt();
                final precioOferta = precioOriginal * (1 - descuento / 100);
                final stock = (data['stock'] ?? 0) as int;

                // Validar cantidad
                int cantidadValida = 1;
                final cantidadField = data['cantidad'];
                if (cantidadField != null) {
                  if (cantidadField is int) {
                    cantidadValida = cantidadField;
                  } else if (cantidadField is double) {
                    cantidadValida = cantidadField.toInt();
                  } else if (cantidadField is String) {
                    cantidadValida = int.tryParse(cantidadField) ?? 1;
                  }
                }

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 5,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(15)),
                              child: Image.network(
                                imagen,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.bakery_dining,
                                        size: 80, color: Colors.brown),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    nombre,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    descripcion,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.brown,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'S/ ${precioOriginal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.red,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'S/ ${precioOferta.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: stock > 0
                                          ? () => _agregarAlCarrito({
                                                'id': doc.id,
                                                'nombre': nombre,
                                                'precio': precioOferta,
                                                'cantidad': cantidadValida,
                                                'stock': stock,
                                                'imagen': data['imagen'],
                                              })
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: stock > 0
                                            ? Color.fromARGB(255, 202, 164, 74)
                                            : Colors.grey,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        stock > 0 ? 'Agregar' : 'Sin stock',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Etiqueta de descuento
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-$descuento%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}