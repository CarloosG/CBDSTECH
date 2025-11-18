import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientOrdersPage extends StatefulWidget {
  const ClientOrdersPage({super.key});

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


    final dynamic result = await _supabase
        .from('pedidos')
        .select()
        .eq('usuario_id', userId)
        .order('fecha', ascending: false);


    if (result is List) {
      return List<Map<String, dynamic>>.from(result);
    }


    if (result is Map) {
      if (result.containsKey('error') && result['error'] != null) {
        throw Exception(result['error'].toString());
      }
      final data = result['data'];
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(data as List<dynamic>);
    }


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
    final fechaEnvioRaw = order['fecha_envio'];
    final fechaEnvio = fechaEnvioRaw ?? 'Pendiente';

    bool canCancel = false;
    if (fechaEnvioRaw == null || fechaEnvioRaw.toString().trim().isEmpty) {
      canCancel = true;
    } else {
      try {
        final sendDate = DateTime.parse(fechaEnvioRaw.toString());

        if (sendDate.isAfter(DateTime.now())) {
          canCancel = true;
        }
      } catch (e) {

        canCancel = false;
      }
    }

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
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pedido #$pedidoId', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              if (fechaFormato.isNotEmpty) Text('Fecha: $fechaFormato'),
              Text('Cantidad: $cantidad'),
              Text('Total: \$${total.toStringAsFixed(2)}'),
              Text('Envío: $fechaEnvio'),
              const SizedBox(height: 8),
              if (canCancel)
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: () => _confirmCancel(pedidoId),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ),
            ],
          ),
        ),
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

  Future<void> _confirmCancel(dynamic pedidoId) async {
    final should = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar cancelación'),
        content: const Text('¿Deseas cancelar este pedido? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cancelar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (should == true) {
      await _cancelOrder(pedidoId);
    }
  }

  Future<void> _cancelOrder(dynamic pedidoId) async {
    try {

      final res = await _supabase.from('pedidos').delete().eq('pedido_id', pedidoId);


      if (res is Map && res.containsKey('error') && res['error'] != null) {
        throw Exception(res['error'].toString());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido cancelado correctamente')),
        );
      }
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cancelar pedido: $e')),
        );
      }
    }
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
