import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  bool loading = true;
  String? error;

  List<Map<String, dynamic>> ventas = [];

  String filtroEstado = 'todos';
  String? filtroProducto;
  String? filtroCiudad;
  DateTimeRange? filtroFecha;

  List<String> productos = [];
  List<String> ciudades = [];

  @override
  void initState() {
    super.initState();
    cargarVentas();
  }

  Future<void> cargarVentas() async {
    try {
      final supabase = Supabase.instance.client;

      final pedidos = await supabase
          .from('pedidos')
          .select('pedido_id, usuario_id, producto_id, cantidad, total, fecha, fecha_envio')
          .order('fecha', ascending: false);

      final usuarios = await supabase
          .from('usuario')
          .select('id, nombre, ciudad');

      final productosDB = await supabase
          .from('productos')
          .select('id, nombre');

      final usuariosMap = {for (var u in usuarios) u['id']: u};
      final productosMap = {for (var p in productosDB) p['id']: p};

      final List<Map<String, dynamic>> resultado = [];

      for (var p in pedidos) {
        resultado.add({
          'pedido_id': p['pedido_id'],
          'cantidad': p['cantidad'],
          'total': p['total'],
          'fecha': p['fecha'],
          'fecha_envio': p['fecha_envio'],
          'usuario': usuariosMap[p['usuario_id']] ?? {},
          'producto': productosMap[p['producto_id']] ?? {},
        });
      }

      setState(() {
        ventas = resultado;
        productos = productosDB.map<String>((p) => p['nombre']).toList();
        ciudades = usuarios.map<String>((u) => u['ciudad']).toSet().toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get ventasFiltradas {
    final now = DateTime.now();
    var data = [...ventas];

    if (filtroEstado != 'todos') {
      data = data.where((v) {
        final fEnvio = DateTime.parse(v['fecha_envio']);
        if (filtroEstado == 'pendientes') return fEnvio.isAfter(now);
        return fEnvio.isBefore(now);
      }).toList();
    }

    if (filtroProducto != null) {
      data = data.where((v) => v['producto']['nombre'] == filtroProducto).toList();
    }

    if (filtroCiudad != null) {
      data = data.where((v) => v['usuario']['ciudad'] == filtroCiudad).toList();
    }

    if (filtroFecha != null) {
      data = data.where((v) {
        final f = DateTime.parse(v['fecha']);
        return f.isAfter(filtroFecha!.start) && f.isBefore(filtroFecha!.end);
      }).toList();
    }

    return data;
  }

  String formatDate(String date) {
    return DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade100,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : Column(
                  children: [
                    _buildHeader(),
                    _buildFiltros(),
                    Expanded(child: _buildTabla()),
                  ],
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: const Text(
        'Historial de ventas',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  value: filtroEstado,
                  items: const [
                    DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    DropdownMenuItem(value: 'pendientes', child: Text('Pendientes')),
                    DropdownMenuItem(value: 'enviados', child: Text('Enviados')),
                  ],
                  onChanged: (v) => setState(() => filtroEstado = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Producto',
                    border: OutlineInputBorder(),
                  ),
                  value: filtroProducto,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ...productos.map(
                      (p) => DropdownMenuItem(value: p, child: Text(p)),
                    ),
                  ],
                  onChanged: (v) => setState(() => filtroProducto = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Ciudad',
                    border: OutlineInputBorder(),
                  ),
                  value: filtroCiudad,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    ...ciudades.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (v) => setState(() => filtroCiudad = v),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  final rango = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (rango != null) {
                    setState(() => filtroFecha = rango);
                  }
                },
                child: const Text('Rango fechas'),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabla() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
          columnSpacing: 32,
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Cliente')),
            DataColumn(label: Text('Producto')),
            DataColumn(label: Text('Cantidad')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Fecha')),
            DataColumn(label: Text('Estado')),
          ],
          rows: ventasFiltradas.map((v) {
            final estado = DateTime.parse(v['fecha_envio']).isAfter(DateTime.now())
                ? 'Pendiente'
                : 'Enviado';

            return DataRow(
              cells: [
                DataCell(Text(v['pedido_id'].toString())),
                DataCell(Text(v['usuario']['nombre'] ?? 'N/A')),
                DataCell(Text(v['producto']['nombre'] ?? 'N/A')),
                DataCell(Text(v['cantidad'].toString())),
                DataCell(Text('\$${v['total']}')),
                DataCell(Text(formatDate(v['fecha']))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: estado == 'Pendiente'
                          ? Colors.orange.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      estado,
                      style: TextStyle(
                        color: estado == 'Pendiente'
                            ? Colors.orange.shade800
                            : Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
