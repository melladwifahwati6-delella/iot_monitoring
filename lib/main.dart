import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const IoTApp());

class IoTApp extends StatelessWidget {
  const IoTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Monitoring',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF2F5F8),
      ),
      home: const DashboardPage(),
    );
  }
}

class Reading {
  final DateTime time;
  final double temp;
  final double hum;
  Reading(this.time, this.temp, this.hum);
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final Random _rand = Random();
  Timer? _timer;

  bool _connected = true;
  bool _showTemp = true; // true = grafik suhu, false = grafik kelembapan
  late List<Reading> _history;

  // Konfigurasi MQTT dummy (belum terhubung sungguhan)
  static const String _broker = 'broker.hivemq.com';
  static const String _topic = 'polinela/iot/sensor';

  Reading get _latest => _history.last;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _history = List.generate(6, (i) {
      return Reading(
        now.subtract(Duration(seconds: (6 - i) * 3)),
        27 + _rand.nextDouble() * 4,
        60 + _rand.nextDouble() * 15,
      );
    });
    // Simulasi data sensor masuk tiap 3 detik (data dummy)
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _addReading());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _addReading() {
    if (!_connected) return;
    setState(() {
      _history.add(Reading(
        DateTime.now(),
        25 + _rand.nextDouble() * 10, // 25 - 35 °C
        55 + _rand.nextDouble() * 30, // 55 - 85 %
      ));
      if (_history.length > 10) _history.removeAt(0);
    });
  }

  void _toggleConnection() {
    setState(() => _connected = !_connected);
    if (_connected) _addReading();
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _hms(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Monitoring',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSensorCard(
                  title: 'Suhu',
                  value: _connected ? _latest.temp.toStringAsFixed(1) : '--',
                  unit: '°C',
                  icon: Icons.thermostat,
                  color: Colors.blue,
                  bg: Colors.blue.shade50,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSensorCard(
                  title: 'Kelembapan',
                  value: _connected ? _latest.hum.toStringAsFixed(0) : '--',
                  unit: '%',
                  icon: Icons.water_drop,
                  color: Colors.green,
                  bg: Colors.green.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMqttCard(),
          const SizedBox(height: 16),
          _buildHistoryCard(),
        ],
      ),
    );
  }

  // Judul dashboard + badge status koneksi
  Widget _buildHeader() {
    final color = _connected ? Colors.green : Colors.red;
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('IoT Monitoring',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Dashboard Monitoring Sensor',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: 6),
              Text(_connected ? 'Connected' : 'Disconnected',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // Kartu nilai suhu / kelembapan
  Widget _buildSensorCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              text: value,
              style: TextStyle(
                  fontSize: 30, fontWeight: FontWeight.bold, color: color),
              children: [
                TextSpan(
                    text: unit,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.normal)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Kartu informasi koneksi MQTT
  Widget _buildMqttCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MQTT Connection',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _infoRow('Status', _connected ? 'Connected' : 'Disconnected',
                valueColor: _connected ? Colors.green : Colors.red),
            _infoRow('Broker', _broker),
            _infoRow('Topic', _topic),
            _infoRow('Last Update', _connected ? _hms(_latest.time) : '--'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _toggleConnection,
                style: FilledButton.styleFrom(
                    backgroundColor: _connected ? Colors.red : Colors.green),
                icon: Icon(_connected ? Icons.link_off : Icons.link),
                label: Text(_connected ? 'Putuskan' : 'Hubungkan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: valueColor)),
          ),
        ],
      ),
    );
  }

  // Monitoring history: pilihan data, grafik, dan tabel
  Widget _buildHistoryCard() {
    final color = _showTemp ? Colors.blue : Colors.green;
    final unit = _showTemp ? '°C' : '%';
    final data = _history.map((r) => _showTemp ? r.temp : r.hum).toList();
    final rows = _history.reversed.take(5).toList();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Monitoring History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Suhu')),
                ButtonSegment(value: false, label: Text('Kelembapan')),
              ],
              selected: {_showTemp},
              onSelectionChanged: (s) => setState(() => _showTemp = s.first),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: CustomPaint(painter: LineChartPainter(data, color)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Waktu',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(_showTemp ? 'Suhu' : 'Kelembapan',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
            const Divider(),
            ...rows.map((r) {
              final v = _showTemp ? r.temp : r.hum;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_hms(r.time)),
                    Text('${v.toStringAsFixed(1)}$unit',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: color)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  LineChartPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minV = data.reduce(min) - 1;
    final maxV = data.reduce(max) + 1;
    final range = maxV - minV;

    final grid = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final y = size.height - ((data[i] - minV) / range) * size.height;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withOpacity(0.12));

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    final dot = Paint()..color = color;
    for (final p in points) {
      canvas.drawCircle(p, 4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter old) => true;
}