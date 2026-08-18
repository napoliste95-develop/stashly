import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/category.dart';
import '../models/saved_item.dart';
import '../services/firestore_service.dart';
import '../widgets/item_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiche')),
      body: StreamBuilder<List<Category>>(
        stream: _service.watchCategories(),
        builder: (context, categorySnapshot) {
          final categories = categorySnapshot.data ?? [];
          return StreamBuilder<List<SavedItem>>(
            stream: _service.watchItems(),
            builder: (context, itemsSnapshot) {
              if (!categorySnapshot.hasData && !itemsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = itemsSnapshot.data ?? [];
              if (items.isEmpty) return _buildEmptyState();
              return _buildContent(context, categories, items);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Ancora nessuna statistica disponibile.\n'
          'Salva qualche link per vedere qui le tue statistiche.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Category> categories,
    List<SavedItem> items,
  ) {
    final categoryCounts = <Category, int>{
      for (final c in categories)
        c: items.where((i) => i.categoryIds.contains(c.id)).length,
    };
    final sortedCategoryCounts = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildUnseenCard(context, items),
        if (sortedCategoryCounts.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildMostLeastUsedRow(context, sortedCategoryCounts),
        ],
        const SizedBox(height: 16),
        _buildPlatformDistributionCard(context, items),
        const SizedBox(height: 16),
        _buildCategoryDistributionCard(context, categories, items),
      ],
    );
  }

  Widget _buildUnseenCard(BuildContext context, List<SavedItem> items) {
    final unseenCount = items.where((i) => i.seenAt == null).length;
    final unseenPercent = unseenCount / items.length * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${unseenPercent.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mai aperti ($unseenCount di ${items.length})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMostLeastUsedRow(
    BuildContext context,
    List<MapEntry<Category, int>> sortedCategoryCounts,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildCategoryStatCard(
            context,
            label: 'Più usata',
            entry: sortedCategoryCounts.first,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCategoryStatCard(
            context,
            label: 'Meno usata',
            entry: sortedCategoryCounts.last,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryStatCard(
    BuildContext context, {
    required String label,
    required MapEntry<Category, int> entry,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: entry.key.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.key.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.value} elementi',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformDistributionCard(
    BuildContext context,
    List<SavedItem> items,
  ) {
    final counts = <SocialPlatform, int>{
      for (final p in SocialPlatform.values)
        p: items.where((i) => i.platform == p).length,
    }..removeWhere((_, count) => count == 0);
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildDistributionCard(
      context,
      title: 'Distribuzione per piattaforma',
      sections: [
        for (final entry in sorted)
          PieChartSectionData(
            value: entry.value.toDouble(),
            color: platformColor(entry.key),
            title: '',
            radius: 60,
          ),
      ],
      legend: [
        for (final entry in sorted)
          _LegendRow(
            icon: FaIcon(
              platformIcon(entry.key),
              color: platformColor(entry.key),
              size: 16,
            ),
            label: platformLabel(entry.key),
            count: entry.value,
            percent: entry.value / items.length * 100,
          ),
      ],
    );
  }

  Widget _buildCategoryDistributionCard(
    BuildContext context,
    List<Category> categories,
    List<SavedItem> items,
  ) {
    final noCategoryCount = items.where((i) => i.categoryIds.isEmpty).length;
    final entries = <_CategorySlice>[
      for (final c in categories)
        _CategorySlice(
          color: c.color,
          label: c.name,
          count: items.where((i) => i.categoryIds.contains(c.id)).length,
        ),
      if (noCategoryCount > 0)
        _CategorySlice(
          color: Colors.grey.shade400,
          label: 'Senza categoria',
          count: noCategoryCount,
        ),
    ]..removeWhere((s) => s.count == 0);
    entries.sort((a, b) => b.count.compareTo(a.count));

    return _buildDistributionCard(
      context,
      title: 'Distribuzione per categoria',
      sections: [
        for (final s in entries)
          PieChartSectionData(
            value: s.count.toDouble(),
            color: s.color,
            title: '',
            radius: 60,
          ),
      ],
      legend: [
        for (final s in entries)
          _LegendRow(
            icon: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
            ),
            label: s.label,
            count: s.count,
            percent: s.count / items.length * 100,
          ),
      ],
    );
  }

  Widget _buildDistributionCard(
    BuildContext context, {
    required String title,
    required List<PieChartSectionData> sections,
    required List<_LegendRow> legend,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...legend,
          ],
        ),
      ),
    );
  }
}

class _CategorySlice {
  final Color color;
  final String label;
  final int count;

  _CategorySlice({required this.color, required this.label, required this.count});
}

class _LegendRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final int count;
  final double percent;

  const _LegendRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          Text('$count · ${percent.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }
}
