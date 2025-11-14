import 'dart:collection';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _DashMode { timeline, products }

class DashboardsPage extends StatefulWidget {
  const DashboardsPage({super.key});

  @override
  State<DashboardsPage> createState() => _DashboardsPageState();
}

class _DashboardsPageState extends State<DashboardsPage> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _pedidos = [];
  Map<int, String> _productos = {};

  _DashMode _mode = _DashMode.timeline;
  int _rangeDays = 30; // 7, 30, 0(all)
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final supabase = Supabase.instance.client;
      final pedidosResp = await supabase
          .from('pedidos')
          .select('pedido_id, producto_id, cantidad, total, fecha')
          .order('fecha', ascending: false);
      final productosResp = await supabase
          .from('productos')
          .select('id, nombre')
          .order('nombre');

      setState(() {
        _pedidos = List<Map<String, dynamic>>.from(pedidosResp);
        _productos = {
          for (final p in productosResp) (p['id'] as int): (p['nombre'] ?? ''),
        };
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
        _loading = false;
      });
    }
  }

  bool _inRange(DateTime dt) {
    if (_customRange != null) {
      return !dt.isBefore(_customRange!.start) &&
          !dt.isAfter(_customRange!.end);
    }
    if (_rangeDays <= 0) return true;
    final cutoff = DateTime.now().subtract(Duration(days: _rangeDays));
    return dt.isAfter(cutoff);
  }

  Map<DateTime, double> _salesTimeline() {
    final Map<DateTime, double> map = {};
    for (final p in _pedidos) {
      final dt = DateTime.tryParse('${p['fecha']}') ?? DateTime.now();
      if (!_inRange(dt)) continue;
      final day = DateTime(dt.year, dt.month, dt.day);
      final total = (p['total'] as num).toDouble();
      map[day] = (map[day] ?? 0) + total;
    }
    return SplayTreeMap<DateTime, double>.from(map);
  }

  Map<int, double> _salesByProduct() {
    final Map<int, double> map = {};
    for (final p in _pedidos) {
      final dt = DateTime.tryParse('${p['fecha']}') ?? DateTime.now();
      if (!_inRange(dt)) continue;
      final id = p['producto_id'] as int;
      final total = (p['total'] as num).toDouble();
      map[id] = (map[id] ?? 0) + total;
    }
    return map;
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange:
          _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );
    if (picked != null) setState(() => _customRange = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboards')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        ToggleButtons(
                          isSelected: [
                            _mode == _DashMode.timeline,
                            _mode == _DashMode.products,
                          ],
                          onPressed:
                              (i) => setState(
                                () =>
                                    _mode =
                                        i == 0
                                            ? _DashMode.timeline
                                            : _DashMode.products,
                              ),
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Por fecha'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Por producto'),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<int>(
                          value: _rangeDays,
                          items: const [
                            DropdownMenuItem(
                              value: 7,
                              child: Text('Últimos 7 días'),
                            ),
                            DropdownMenuItem(
                              value: 30,
                              child: Text('Últimos 30 días'),
                            ),
                            DropdownMenuItem(value: 0, child: Text('Todo')),
                          ],
                          onChanged:
                              (v) => setState(() {
                                _rangeDays = v ?? 30;
                                _customRange = null;
                              }),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _pickRange,
                          child: const Text('Rango personalizado'),
                        ),
                        if (_customRange != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${DateFormat('dd/MM/yyyy').format(_customRange!.start)} — ${DateFormat('dd/MM/yyyy').format(_customRange!.end)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_mode == _DashMode.timeline) _buildTimelineChart(),
                    if (_mode == _DashMode.products) _buildProductBarChart(),
                  ],
                ),
              ),
    );
  }

  Widget _buildTimelineChart() {
    final data = _salesTimeline();
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No hay ventas en el rango seleccionado.'),
      );
    }

    // Build dense timeline with daily points
    List<MapEntry<DateTime, double>> points;
    if (_customRange != null || _rangeDays > 0) {
      final DateTime end = _customRange?.end ?? DateTime.now();
      final DateTime start =
          _customRange?.start ?? end.subtract(Duration(days: _rangeDays - 1));
      final days = <DateTime>[];
      DateTime d = DateTime(start.year, start.month, start.day);
      final DateTime endDay = DateTime(end.year, end.month, end.day);
      while (!d.isAfter(endDay)) {
        days.add(d);
        d = d.add(const Duration(days: 1));
      }
      final map = {for (var day in days) day: data[day] ?? 0.0};
      points = map.entries.toList();
    } else {
      points = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    }

    final spots = <FlSpot>[];
    final dates = <DateTime>[];
    for (int i = 0; i < points.length; i++) {
      dates.add(points[i].key);
      spots.add(FlSpot(i.toDouble(), points[i].value));
    }
    final maxY = (points
                .map((e) => e.value)
                .fold<double>(0, (a, b) => a > b ? a : b) *
            1.1)
        .clamp(1.0, double.infinity);

    int labelStep = (points.length / 6).ceil();
    if (labelStep < 1) labelStep = 1;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 260,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY.toDouble(),
              minX: 0,
              maxX: (points.length > 1 ? points.length - 1 : 1).toDouble(),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.round();
                      if (idx < 0 || idx >= dates.length)
                        return const SizedBox.shrink();
                      if (idx % labelStep != 0 && idx != dates.length - 1)
                        return const SizedBox.shrink();
                      final d = dates[idx];
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Transform.rotate(
                          angle: -0.5,
                          child: Text(
                            DateFormat('dd/MM').format(d),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      );
                    },
                    reservedSize: 48,
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.orange,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductBarChart() {
    final data = _salesByProduct();
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No hay ventas en el rango seleccionado.'),
      );
    }

    final entries =
        data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(8).toList();
    double maxY = (top.first.value * 1.1).toDouble();
    if (maxY < 1.0) maxY = 1.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 300,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(enabled: true),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= top.length)
                        return const SizedBox.shrink();
                      final id = top[idx].key;
                      final label = _productos[id] ?? 'ID:$id';
                      return RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                    reservedSize: 56,
                  ),
                ),
              ),
              barGroups: List.generate(top.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: top[i].value,
                      color: Colors.blue,
                      width: 24,
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
