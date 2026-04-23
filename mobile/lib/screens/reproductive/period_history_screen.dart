import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/period_cycle.dart';
import '../../services/period_repository.dart';
import '../../services/pdf_report_service.dart';

/// Period History Screen
/// Displays past cycles with details and export functionality
class PeriodHistoryScreen extends StatefulWidget {
  const PeriodHistoryScreen({super.key});

  @override
  State<PeriodHistoryScreen> createState() => _PeriodHistoryScreenState();
}

class _PeriodHistoryScreenState extends State<PeriodHistoryScreen> {
  final PeriodRepository _repository = PeriodRepository();
  final PDFReportService _pdfService = PDFReportService();

  List<PeriodCycle> _cycles = [];
  bool _isLoading = true;
  String? _expandedCycleId;

  @override
  void initState() {
    super.initState();
    _loadCycles();
  }

  Future<void> _loadCycles() async {
    setState(() => _isLoading = true);
    try {
      final cycles = await _repository.fetchUserCycles(limit: 24);
      setState(() {
        _cycles = cycles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading cycles: $e')));
      }
    }
  }

  Future<void> _exportPDF() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _pdfService.generateAndShare();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report generated and ready to share'),
            backgroundColor: FemoraColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: FemoraColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemoraColors.lightBackgroundTint,
      appBar: AppBar(
        backgroundColor: FemoraColors.lightBackgroundTint,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: FemoraColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Period History',
          style: FemoraTextStyles.headlineMedium.copyWith(
            color: FemoraColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.file_download_rounded,
              color: FemoraColors.primary,
            ),
            onPressed: _exportPDF,
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cycles.isEmpty
          ? _buildEmptyState()
          : _buildCyclesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: FemoraColors.lavenderWhisper.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              size: 50,
              color: FemoraColors.primary,
            ),
          ),
          const SizedBox(height: FemoraSpacing.lg),
          Text(
            'No Period Data Yet',
            style: FemoraTextStyles.headlineMedium.copyWith(
              color: FemoraColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: FemoraSpacing.sm),
          Text(
            'Start tracking your cycle to see history',
            style: FemoraTextStyles.bodyMedium.copyWith(
              color: FemoraColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCyclesList() {
    return ListView.separated(
      padding: const EdgeInsets.all(FemoraSpacing.lg),
      itemCount: _cycles.length + 1,
      separatorBuilder: (context, index) =>
          const SizedBox(height: FemoraSpacing.md),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSummaryCard();
        }

        final cycle = _cycles[index - 1];
        return _buildCycleCard(cycle, index);
      },
    );
  }

  Widget _buildSummaryCard() {
    final validCycles = _cycles.where((c) => c.cycleLength != null).toList();

    if (validCycles.isEmpty) {
      return const SizedBox.shrink();
    }

    final avgCycleLength =
        validCycles.map((c) => c.cycleLength!).reduce((a, b) => a + b) /
        validCycles.length;

    final avgBleedingDays =
        validCycles
            .where((c) => c.bleedingDays != null)
            .map((c) => c.bleedingDays!)
            .fold(0, (a, b) => a + b) /
        validCycles.where((c) => c.bleedingDays != null).length;

    return Container(
      padding: const EdgeInsets.all(FemoraSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FemoraColors.primary, FemoraColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(FemoraBorderRadius.large),
        boxShadow: [
          BoxShadow(
            color: FemoraColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Averages',
            style: FemoraTextStyles.headlineMedium.copyWith(
              color: FemoraColors.textLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: FemoraSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Cycle Length',
                '${avgCycleLength.toStringAsFixed(0)} days',
              ),
              Container(
                width: 1,
                height: 40,
                color: FemoraColors.textLight.withValues(alpha: 0.3),
              ),
              _buildStatItem(
                'Period Days',
                avgBleedingDays.isNaN
                    ? 'N/A'
                    : '${avgBleedingDays.toStringAsFixed(0)} days',
              ),
              Container(
                width: 1,
                height: 40,
                color: FemoraColors.textLight.withValues(alpha: 0.3),
              ),
              _buildStatItem('Total Cycles', '${_cycles.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: FemoraTextStyles.headlineMedium.copyWith(
            color: FemoraColors.textLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: FemoraTextStyles.caption.copyWith(
            color: FemoraColors.textLight.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildCycleCard(PeriodCycle cycle, int index) {
    final isExpanded = _expandedCycleId == cycle.id;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedCycleId = isExpanded ? null : cycle.id;
        });
      },
      child: AnimatedContainer(
        duration: FemoraAnimations.normal,
        padding: const EdgeInsets.all(FemoraSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(FemoraBorderRadius.medium),
          boxShadow: [
            BoxShadow(
              color: FemoraColors.primary.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cycle #$index',
                        style: FemoraTextStyles.titleLarge.copyWith(
                          color: FemoraColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(cycle.startDate),
                        style: FemoraTextStyles.bodyMedium.copyWith(
                          color: FemoraColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (cycle.cycleLength != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: FemoraColors.lavenderWhisper,
                          borderRadius: BorderRadius.circular(
                            FemoraBorderRadius.small,
                          ),
                        ),
                        child: Text(
                          '${cycle.cycleLength} days',
                          style: FemoraTextStyles.bodyMedium.copyWith(
                            color: FemoraColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: FemoraColors.primary,
                    ),
                  ],
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: FemoraSpacing.md),
              const Divider(),
              const SizedBox(height: FemoraSpacing.md),
              _buildDetailRow('Start Date', dateFormat.format(cycle.startDate)),
              if (cycle.endDate != null)
                _buildDetailRow('End Date', dateFormat.format(cycle.endDate!)),
              if (cycle.bleedingDays != null)
                _buildDetailRow('Bleeding Days', '${cycle.bleedingDays} days'),
              _buildDetailRow(
                'Status',
                cycle.isConfirmed ? 'Confirmed' : 'Predicted',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FemoraSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: FemoraTextStyles.bodyMedium.copyWith(
              color: FemoraColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: FemoraTextStyles.bodyMedium.copyWith(
              color: FemoraColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
