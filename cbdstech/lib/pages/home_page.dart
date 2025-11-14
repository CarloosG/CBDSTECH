import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_detail_page.dart';

// Modelo para el producto
class Producto {
  final int id;
  final String nombre;
  final String especificaciones;
  final double precio;
  final String? imagenUrl;

  Producto({
    required this.id,
    required this.nombre,
    required this.especificaciones,
    required this.precio,
    this.imagenUrl,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      especificaciones: json['especificaciones'] as String,
      precio: (json['precio'] as num).toDouble(),
      imagenUrl: json['imagen_url'] as String?,
    );
  }
}

final Map<int, String> imagenesProductos = {
  1: 'assets/images/iphone15.png',
  2: 'assets/images/Samsung.png',
  3: 'assets/images/macbook.png',
  4: 'assets/images/dell.png',
  5: 'assets/images/ipad.png',
  6: 'assets/images/sony.png',
  7: 'assets/images/switch.png',
  8: 'assets/images/airpods.png',
};

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Producto> productos = [];
  List<Producto> productosFiltrados = [];
  bool isLoading = true;
  String? error;
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _cargarProductos();
  }

  // Función para cargar productos desde Supabase
  Future<void> _cargarProductos() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final response = await Supabase.instance.client
          .from('productos') // Nombre de tu tabla en Supabase
          .select('id, nombre, especificaciones, precio, imagen_url')
          .order('id', ascending: true);

      final List<Producto> productosTemp = [];
      for (final item in response) {
        productosTemp.add(Producto.fromJson(item));
      }

      setState(() {
        productos = productosTemp;
        productosFiltrados = productosTemp;
        isLoading = false;
      });
      _filtrarProductos(searchQuery);
    } catch (e) {
      setState(() {
        error = 'Error al cargar productos: $e';
        isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text;
      _filtrarProductos(searchQuery);
    });
  }

  void _filtrarProductos(String query) {
    if (query.isEmpty) {
      productosFiltrados = List.from(productos);
    } else {
      productosFiltrados =
          productos.where((producto) {
            final nombre = producto.nombre.toLowerCase();
            final especificaciones = producto.especificaciones.toLowerCase();
            final q = query.toLowerCase();
            return nombre.contains(q) || especificaciones.contains(q);
          }).toList();
    }
  }

  // Widget para mostrar cada producto
  Widget _buildProductoCard(Producto producto) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(producto: producto),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 170,
                    width: double.infinity,
                    child:
                        (producto.imagenUrl != null &&
                                producto.imagenUrl!.isNotEmpty)
                            ? Image.network(
                              producto.imagenUrl!,
                              fit: BoxFit.cover,
                            )
                            : Image.asset(
                              imagenesProductos[producto.id] ??
                                  'assets/images/iphone15.png',
                              fit: BoxFit.cover,
                            ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        producto.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '\$${producto.precio.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Productos Tecnológicos',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarProductos,
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Header con información
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${productos.length} productos disponibles',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                // Barra de búsqueda
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar productos...',
                      prefixIcon: const Icon(Icons.search, color: Colors.blue),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          // Lista de productos
          Expanded(
            child:
                isLoading
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Cargando productos...',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : error != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _cargarProductos,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                    : productosFiltrados.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay productos disponibles',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Los productos aparecerán aquí cuando estén disponibles',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _cargarProductos,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: productosFiltrados.length,
                        itemBuilder: (context, index) {
                          return _buildProductoCard(productosFiltrados[index]);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
