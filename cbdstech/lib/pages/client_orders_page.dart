import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientOrdersPage extends StatefulWidget {
  const ClientOrdersPage({Key? key}) : super(key: key);

  @override
  State<ClientOrdersPage> createState() => _ClientOrdersPageState();
}

class _ClientOrdersPageState extends State<ClientOrdersPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchOrders();
  }

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    final userId = user.id;

    // Obtener pedidos del usuario actual filtrados por usuario_id
    final dynamic result = await _supabase
        .from('pedidos')
        .select()
        .eq('usuario_id', userId)
        .order('fecha', ascending: false);

    // Si la respuesta es una lista directa
    if (result is List) {
      return List<Map<String, dynamic>>.from(result);
    }

    // Si la respuesta es un mapa con data / error (antigua API)
    if (result is Map) {
      if (result.containsKey('error') && result['error'] != null) {
        throw Exception(result['error'].toString());
      }
      final data = result['data'];
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(data as List<dynamic>);
    }

    // Caso por defecto: no hay datos
    return [];
  }

  Future<void> _refresh() async {
    setState(() {
      _ordersFuture = _fetchOrders();
    });
    await _ordersFuture;
  }

  Widget _buildOrderTile(Map<String, dynamic> order) {
    final pedidoId = order['pedido_id'] ?? '—';
    final fecha = order['fecha'] ?? '';
    final total = order['total'] ?? 0.0;
    final cantidad = order['cantidad'] ?? 0;
    final fechaEnvio = order['fecha_envio'] ?? 'Pendiente';

    // Formatear fecha
    String fechaFormato = '';
    if (fecha.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(fecha.toString());
        fechaFormato = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } catch (e) {
        fechaFormato = fecha.toString();
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text('Pedido #$pedidoId'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fechaFormato.isNotEmpty) Text('Fecha: $fechaFormato'),
            Text('Cantidad: $cantidad'),
            Text('Total: \$${total.toStringAsFixed(2)}'),
            Text('Envío: $fechaEnvio'),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showOrderDetails(order),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final pedidoId = order['pedido_id'] ?? '—';
    final productoId = order['producto_id'] ?? '—';
    final cantidad = order['cantidad'] ?? 0;
    final total = order['total'] ?? 0.0;
    final fecha = order['fecha'] ?? '';
    final fechaEnvio = order['fecha_envio'] ?? 'Pendiente';

    String fechaFormato = '';
    if (fecha.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(fecha.toString());
        fechaFormato = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } catch (e) {
        fechaFormato = fecha.toString();
      }
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del pedido #$pedidoId'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID Pedido', pedidoId.toString()),
              _buildDetailRow('Producto ID', productoId.toString()),
              _buildDetailRow('Cantidad', cantidad.toString()),
              _buildDetailRow('Total', '\$${total.toStringAsFixed(2)}'),
              _buildDetailRow('Fecha Pedido', fechaFormato),
              _buildDetailRow('Fecha Envío', fechaEnvio.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          )
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Error al cargar pedidos: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Reintentar'),
                    )
                  ],
                ),
              ),
            );
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No has realizado pedidos todavía')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, i) => _buildOrderTile(orders[i]),
            ),
          );
        },
      ),
    );
  }
}
