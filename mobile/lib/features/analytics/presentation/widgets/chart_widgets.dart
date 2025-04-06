import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StockTrendLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> trendData;
  final Color lineColor;
  final Color gradientColor;

  const StockTrendLineChart({
    super.key,
    required this.trendData,
    this.lineColor = Colors.blue,
    this.gradientColor = Colors.blueAccent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 18,
          left: 12,
          top: 24,
          bottom: 12,
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 50,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value < 0 || value >= trendData.length) {
                      return const SizedBox();
                    }
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
                      child: Text(
                        trendData[value.toInt()]['month'],
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 50,
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
                      child: Text(
                        value.toInt().toString(),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                  reservedSize: 40,
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
              ),
            ),
            minX: 0,
            maxX: trendData.length - 1,
            minY: 0,
            maxY: _calculateMaxY(),
            lineBarsData: [
              LineChartBarData(
                spots: _createSpots(),
                isCurved: true,
                gradient: LinearGradient(
                  colors: [
                    lineColor,
                    gradientColor,
                  ],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(
                  show: true,
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      lineColor.withOpacity(0.3),
                      gradientColor.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> _createSpots() {
    final List<FlSpot> spots = [];
    for (int i = 0; i < trendData.length; i++) {
      spots.add(
        FlSpot(i.toDouble(), trendData[i]['items'].toDouble()),
      );
    }
    return spots;
  }

  double _calculateMaxY() {
    double maxValue = 0;
    for (final data in trendData) {
      if (data['items'] > maxValue) {
        maxValue = data['items'].toDouble();
      }
    }
    // Add padding to the max value
    return (maxValue * 1.2);
  }
}

class CategoryPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> categoryData;
  final List<Color> colorList;

  const CategoryPieChart({
    super.key,
    required this.categoryData,
    this.colorList = const [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ],
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 40,
          sections: _createSections(),
        ),
      ),
    );
  }

  List<PieChartSectionData> _createSections() {
    final List<PieChartSectionData> sections = [];

    // Calculate total for percentage
    final int total = categoryData.fold(
        0, (previousValue, element) => previousValue + element['count'] as int);

    for (int i = 0; i < categoryData.length; i++) {
      final data = categoryData[i];
      final double percentage = (data['count'] / total) * 100;

      sections.add(
        PieChartSectionData(
          color: i < colorList.length ? colorList[i] : Colors.grey,
          value: data['count'].toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    return sections;
  }
}

class StockStatusBarChart extends StatelessWidget {
  final Map<String, dynamic> statsData;

  const StockStatusBarChart({
    super.key,
    required this.statsData,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 18,
          left: 12,
          top: 24,
          bottom: 12,
        ),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.center,
            maxY: _calculateMaxY(),
            minY: 0,
            groupsSpace: 30,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor:
                    colorScheme.surfaceContainerHighest.withOpacity(0.8),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    rod.toY.toInt().toString(),
                    textTheme.bodySmall!.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: _bottomTitles,
                  reservedSize: 30,
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
              ),
            ),
            barGroups: _createBarGroups(),
          ),
        ),
      ),
    );
  }

  Widget _bottomTitles(double value, TitleMeta meta) {
    final titles = [
      'Total',
      'Low Stock',
      'Expiring',
      'Priority',
    ];

    final Widget text = Text(
      titles[value.toInt()],
      style: const TextStyle(
        color: Colors.grey,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: text,
    );
  }

  List<BarChartGroupData> _createBarGroups() {
    final List<BarChartGroupData> barGroups = [];

    barGroups.add(
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: statsData['totalItems'].toDouble(),
            color: Colors.blue,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      ),
    );

    barGroups.add(
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: statsData['lowStockCount'].toDouble(),
            color: Colors.orange,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      ),
    );

    barGroups.add(
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(
            toY: statsData['expiringCount'].toDouble(),
            color: Colors.red,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      ),
    );

    barGroups.add(
      BarChartGroupData(
        x: 3,
        barRods: [
          BarChartRodData(
            toY: statsData['priorityCount'].toDouble(),
            color: Colors.purple,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      ),
    );

    return barGroups;
  }

  double _calculateMaxY() {
    return (statsData['totalItems'] * 1.2).toDouble();
  }
}

// Widget for showing a stats card with a title, value and icon
class StatsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final String? subtitle;
  final bool trending;
  final bool trendingUp;

  const StatsCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    this.color = Colors.blue,
    this.subtitle,
    this.trending = false,
    this.trendingUp = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: colorScheme.surfaceContainerHighest,
          width: 1,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 110, // Fixed width to ensure consistent layout
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row with icon and trend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 12,
                    ),
                  ),
                  if (trending)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trendingUp
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: trendingUp ? Colors.green : Colors.red,
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '8.3%',
                          style: TextStyle(
                            color: trendingUp ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 4),

              // Title
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              // Value
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Subtitle if present
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
