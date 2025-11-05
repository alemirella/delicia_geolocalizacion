import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'carrito_screen.dart';

class CatalogoScreen extends StatefulWidget {
  final void Function(int) onCartChanged;
  const CatalogoScreen({super.key, required this.onCartChanged});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final Query productosRef =
      FirebaseFirestore.instance.collection('productos').orderBy('nombre');

  String _busqueda = '';

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    final stock = producto['stock'] ?? 0;
    if (stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay stock disponible para este producto')),
      );
      return;
    }

    SimpleCart.instance.addItem(producto);

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
      appBar: AppBar(
        title: const Text('Catálogo de Productos'),
        backgroundColor: const Color.fromARGB(255, 245, 153, 96),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: (valor) {
                setState(() {
                  _busqueda = valor.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: productosRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar los productos.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 🔥 FILTRAR: Excluir productos en oferta
                final productos = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  
                  // ⚠️ NUEVO: Si está en oferta, NO mostrarlo en catálogo
                  final enOferta = data['en_oferta'] ?? false;
                  if (enOferta == true) return false;
                  
                  // Filtro de búsqueda normal
                  final nombre = (data['nombre'] ?? '').toString().toLowerCase();
                  final descripcion =
                      (data['descripcion'] ?? '').toString().toLowerCase();
                  return nombre.contains(_busqueda) ||
                      descripcion.contains(_busqueda);
                }).toList();

                if (productos.isEmpty) {
                  return const Center(child: Text('No se encontraron productos.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final doc = productos[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final imagen = convertirEnlaceDriveADirecto(data['imagen'] ?? '');
                    final descripcion = (data['descripcion'] ?? '').toString();
                    final stock = (data['stock'] is int)
                        ? data['stock'] as int
                        : int.tryParse((data['stock'] ?? '0').toString()) ?? 0;

                    // Validar cantidad
                    int cantidadValida = 0;
                    final cantidadField = data['cantidad'];
                    if (cantidadField != null) {
                      if (cantidadField is int) {
                        cantidadValida = cantidadField;
                      } else if (cantidadField is double) {
                        cantidadValida = cantidadField.toInt();
                      } else if (cantidadField is String) {
                        cantidadValida = int.tryParse(cantidadField) ?? 0;
                      }
                    }

                    Color stockColor;
                    if (stock <= 0) {
                      stockColor = Colors.red;
                    } else if (stock < 10) {
                      stockColor = Colors.orange;
                    } else {
                      stockColor = Colors.green;
                    }

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.network(
                                imagen,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 60),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['nombre'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  descripcion,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'S/ ${data['precio'] ?? 0.0}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Cant: $cantidadValida',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Stock: $stock',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: stockColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: stock > 0
                                        ? () => _agregarAlCarrito({
                                              'id': doc.id,
                                              'nombre': data['nombre'],
                                              'precio': data['precio'],
                                              'cantidad': cantidadValida,
                                              'stock': stock,
                                              'imagen': data['imagen'],
                                            })
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: stock > 0
                                          ? const Color.fromARGB(255, 202, 164, 74)
                                          : Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      stock > 0 ? 'Agregar' : 'Sin stock',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Convierte enlaces de Google Drive a formato directo
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