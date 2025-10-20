import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  List<Map<String, dynamic>> _pedidos = [];
  bool _isLoading = true;
  String? _error;
  String _filtroEstado = 'todos'; // todos, pendientes, enviados

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final supabase = Supabase.instance.client;

      // Obtenemos los pedidos
      final pedidosResponse = await supabase
          .from('pedidos')
          .select('pedido_id, usuario_id, producto_id, cantidad, total, fecha, fecha_envio')
          .order('fecha', ascending: false);

      // Obtenemos todos los usuarios
      final usuariosResponse = await supabase
          .from('usuario')
          .select('id, nombre, email, ciudad, direccion');

      // Obtenemos todos los productos
      final productosResponse = await supabase
          .from('productos')
          .select('id, nombre, precio');

      // Creamos mapas para búsqueda rápida
      final Map<String, dynamic> usuariosMap = {};
      for (var usuario in usuariosResponse) {
        usuariosMap[usuario['id']] = usuario;
      }

      final Map<int, dynamic> productosMap = {};
      for (var producto in productosResponse) {
        productosMap[producto['id']] = producto;
      }

      // Combinamos los datos
      final List<Map<String, dynamic>> pedidosCompletos = [];
      for (var pedido in pedidosResponse) {
        pedidosCompletos.add({
          'pedido_id': pedido['pedido_id'],
          'cantidad': pedido['cantidad'],
          'total': pedido['total'],
          'fecha': pedido['fecha'],
          'fecha_envio': pedido['fecha_envio'],
          'usuario': usuariosMap[pedido['usuario_id']],
          'producto': productosMap[pedido['producto_id']],
        });
      }

      setState(() {
        _pedidos = pedidosCompletos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar pedidos: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _pedidosFiltrados {
    final now = DateTime.now();
    
    if (_filtroEstado == 'pendientes') {
      return _pedidos.where((pedido) {
        final fechaEnvio = DateTime.parse(pedido['fecha_envio']);
        return fechaEnvio.isAfter(now);
      }).toList();
    } else if (_filtroEstado == 'enviados') {
      return _pedidos.where((pedido) {
        final fechaEnvio = DateTime.parse(pedido['fecha_envio']);
        return fechaEnvio.isBefore(now) || fechaEnvio.isAtSameMomentAs(now);
      }).toList();
    }
    
    return _pedidos;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateOnly(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getEstadoColor(String fechaEnvio) {
    final fecha = DateTime.parse(fechaEnvio);
    final now = DateTime.now();
    
    if (fecha.isAfter(now)) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getEstadoTexto(String fechaEnvio) {
    final fecha = DateTime.parse(fechaEnvio);
    final now = DateTime.now();
    
    if (fecha.isAfter(now)) {
      return 'Pendiente';
    } else {
      return 'Enviado';
    }
  }

  Widget _buildEstadisticas() {
    final totalPedidos = _pedidos.length;
    final totalIngresos = _pedidos.fold<double>(
      0,
      (sum, pedido) => sum + (pedido['total'] as num).toDouble(),
    );
    
    final pedidosPendientes = _pedidos.where((pedido) {
      final fechaEnvio = DateTime.parse(pedido['fecha_envio']);
      return fechaEnvio.isAfter(DateTime.now());
    }).length;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Estadísticas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEstadisticaItem(
                  'Total Pedidos',
                  totalPedidos.toString(),
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                _buildEstadisticaItem(
                  'Pendientes',
                  pedidosPendientes.toString(),
                  Icons.pending_actions,
                  Colors.orange,
                ),
                _buildEstadisticaItem(
                  'Ingresos',
                  '\$${totalIngresos.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticaItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildPedidoCard(Map<String, dynamic> pedido) {
    final usuario = pedido['usuario'] as Map<String, dynamic>?;
    final producto = pedido['producto'] as Map<String, dynamic>?;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getEstadoColor(pedido['fecha_envio']),
          child: const Icon(Icons.receipt_long, color: Colors.white),
        ),
        title: Text(
          producto?['nombre'] ?? 'Producto desconocido',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Cliente: ${usuario?['nombre'] ?? 'Desconocido'} • ${_formatDate(pedido['fecha'])}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getEstadoColor(pedido['fecha_envio']).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getEstadoTexto(pedido['fecha_envio']),
            style: TextStyle(
              color: _getEstadoColor(pedido['fecha_envio']),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.shopping_bag,
                  'Producto',
                  producto?['nombre'] ?? 'N/A',
                ),
                _buildInfoRow(
                  Icons.attach_money,
                  'Precio unitario',
                  '\$${(producto?['precio'] ?? 0).toStringAsFixed(2)}',
                ),
                _buildInfoRow(
                  Icons.numbers,
                  'Cantidad',
                  pedido['cantidad'].toString(),
                ),
                _buildInfoRow(
                  Icons.calculate,
                  'Total',
                  '\$${pedido['total'].toStringAsFixed(2)}',
                  isHighlighted: true,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Información del Cliente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.person,
                  'Nombre',
                  usuario?['nombre'] ?? 'N/A',
                ),
                _buildInfoRow(
                  Icons.email,
                  'Email',
                  usuario?['email'] ?? 'N/A',
                ),
                _buildInfoRow(
                  Icons.location_city,
                  'Ciudad',
                  usuario?['ciudad'] ?? 'N/A',
                ),
                _buildInfoRow(
                  Icons.home,
                  'Dirección',
                  usuario?['direccion'] ?? 'N/A',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Fechas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Fecha del pedido',
                  _formatDate(pedido['fecha']),
                ),
                _buildInfoRow(
                  Icons.local_shipping,
                  'Fecha de envío',
                  _formatDateOnly(pedido['fecha_envio']),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontWeight:
                          isHighlighted ? FontWeight.bold : FontWeight.normal,
                      color: isHighlighted ? Colors.green.shade700 : null,
                      fontSize: isHighlighted ? 16 : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando pedidos...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarPedidos,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildEstadisticas(),
                    // Filtros
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Text(
                            'Filtrar: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'todos',
                                  label: Text('Todos'),
                                  icon: Icon(Icons.all_inclusive),
                                ),
                                ButtonSegment(
                                  value: 'pendientes',
                                  label: Text('Pendientes'),
                                  icon: Icon(Icons.pending),
                                ),
                                ButtonSegment(
                                  value: 'enviados',
                                  label: Text('Enviados'),
                                  icon: Icon(Icons.check_circle),
                                ),
                              ],
                              selected: {_filtroEstado},
                              onSelectionChanged: (Set<String> newSelection) {
                                setState(() {
                                  _filtroEstado = newSelection.first;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Lista de pedidos
                    Expanded(
                      child: _pedidosFiltrados.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No hay pedidos $_filtroEstado',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _cargarPedidos,
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 16),
                                itemCount: _pedidosFiltrados.length,
                                itemBuilder: (context, index) {
                                  return _buildPedidoCard(
                                      _pedidosFiltrados[index]);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}