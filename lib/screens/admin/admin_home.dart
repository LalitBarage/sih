import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({Key? key}) : super(key: key);

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  late Future<Map<String, int>> _patientDataFuture;

  @override
  void initState() {
    super.initState();
    _patientDataFuture = fetchPatientDataFromSupabase();
  }

  Future<Map<String, int>> fetchPatientDataFromSupabase() async {
    final response =
        await Supabase.instance.client.from('diseases').select('disease');

    final data = response as List<dynamic>;

    // Group data by disease
    Map<String, int> diseaseCount = {};
    for (var entry in data) {
      final disease = entry['disease'] as String;
      diseaseCount[disease] = (diseaseCount[disease] ?? 0) + 1;
    }

    return diseaseCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, int>>(
        future: _patientDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available'));
          } else {
            final data = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Disease Status',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    DiseasesChart(diseaseData: data),
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text(
                      'Other Components',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Add your action here
                      },
                      child: const Text('View Patient Details'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Add your action here
                      },
                      child: const Text('Generate Reports'),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      child: ListTile(
                        leading: const Icon(Icons.info),
                        title: const Text('Notifications'),
                        subtitle:
                            const Text('Manage alerts and notifications.'),
                        onTap: () {
                          // Add your navigation logic here
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class DiseasesChart extends StatelessWidget {
  final Map<String, int> diseaseData;

  const DiseasesChart({required this.diseaseData});

  @override
  Widget build(BuildContext context) {
    // Truncate to the first 10 diseases if there are more
    final limitedData = diseaseData.entries.take(10).toList();

    // Maximum value for scaling
    final maxValue =
        limitedData.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    // Add buffer to maxValue for better visualization
    final maxY = (maxValue * 1.2).ceilToDouble();
    final interval = (maxY / 5).ceilToDouble(); // Reasonable intervals

    // Bar groups with animation
    final barGroups = limitedData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.value.toDouble(),
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [Colors.blue.shade300, Colors.blue.shade700],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            width: 20,
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: Colors.grey.shade200,
            ),
          ),
        ],
      );
    }).toList();

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          maxY: maxY,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              bottom: BorderSide(color: Colors.grey, width: 1),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  if (value == 0)
                    return const Text(''); // Avoid duplicates at zero
                  String formattedValue = value >= 1000
                      ? '${(value / 1000).toStringAsFixed(1)}K'
                      : value.toInt().toString();
                  return Text(
                    formattedValue,
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < limitedData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        limitedData[index].key,
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final disease = limitedData[group.x.toInt()].key;
                return BarTooltipItem(
                  '$disease\n',
                  const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: '${rod.toY.toInt()} cases',
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
