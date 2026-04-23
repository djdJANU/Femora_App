import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/period_cycle.dart';
import 'period_repository.dart';
import 'prediction_engine.dart';
import 'irregularity_analyzer.dart';

/// PDF Report Service
/// Generates comprehensive period tracking reports
class PDFReportService {
  final PeriodRepository _repository = PeriodRepository();
  final PredictionEngine _predictionEngine = PredictionEngine();
  final IrregularityAnalyzer _analyzer = IrregularityAnalyzer();

  /// Generate and save PDF report
  Future<File> generateReport() async {
    try {
      final pdf = pw.Document();

      // Fetch data
      final cycles = await _repository.fetchUserCycles(limit: 12);
      final prediction = await _predictionEngine.generatePrediction();
      final irregularityReport = await _analyzer.analyzeCycles();

      // Add cover page
      pdf.addPage(_buildCoverPage());

      // Add cycle summary page
      if (cycles.isNotEmpty) {
        pdf.addPage(_buildCycleSummaryPage(cycles, prediction));
      }

      // Add statistics page
      pdf.addPage(_buildStatisticsPage(cycles, irregularityReport));

      // Add cycle history page
      if (cycles.isNotEmpty) {
        pdf.addPage(_buildCycleHistoryPage(cycles));
      }

      // Save the PDF
      final output = await _getPdfPath();
      final file = File(output);
      await file.writeAsBytes(await pdf.save());

      return file;
    } catch (e) {
      throw Exception('Failed to generate PDF report: $e');
    }
  }

  /// Build cover page
  pw.Page _buildCoverPage() {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'FEMORA',
              style: pw.TextStyle(
                fontSize: 48,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.purple700,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Period Tracking Report',
              style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 40),
            pw.Text(
              'Generated on ${DateTime.now().toString().split(' ')[0]}',
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );
  }

  /// Build cycle summary page
  pw.Page _buildCycleSummaryPage(List<PeriodCycle> cycles, prediction) {
    final validCycles = cycles.where((c) => c.cycleLength != null).toList();

    final avgCycleLength = validCycles.isNotEmpty
        ? validCycles.map((c) => c.cycleLength!).reduce((a, b) => a + b) /
              validCycles.length
        : 0.0;

    final avgBleedingDays =
        validCycles
            .where((c) => c.bleedingDays != null)
            .map((c) => c.bleedingDays!)
            .fold(0, (a, b) => a + b) /
        validCycles.where((c) => c.bleedingDays != null).length;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Cycle Summary',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple700,
            ),
          ),
          pw.SizedBox(height: 20),
          _buildInfoRow('Total Cycles Tracked', '${cycles.length}'),
          _buildInfoRow(
            'Average Cycle Length',
            '${avgCycleLength.toStringAsFixed(1)} days',
          ),
          _buildInfoRow(
            'Average Bleeding Days',
            avgBleedingDays.isNaN
                ? 'N/A'
                : '${avgBleedingDays.toStringAsFixed(1)} days',
          ),
          if (prediction != null) ...[
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text(
              'Predictions',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildInfoRow(
              'Next Period Expected',
              prediction.nextPeriodDate.toString().split(' ')[0],
            ),
            _buildInfoRow(
              'Ovulation Date',
              prediction.ovulationDate.toString().split(' ')[0],
            ),
            _buildInfoRow(
              'Fertile Window',
              '${prediction.fertileWindowStart.toString().split(' ')[0]} to '
                  '${prediction.fertileWindowEnd.toString().split(' ')[0]}',
            ),
            _buildInfoRow(
              'Prediction Confidence',
              '${(prediction.confidence * 100).toStringAsFixed(0)}%',
            ),
          ],
        ],
      ),
    );
  }

  /// Build statistics page
  pw.Page _buildStatisticsPage(
    List<PeriodCycle> cycles,
    IrregularityReport report,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Cycle Statistics',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple700,
            ),
          ),
          pw.SizedBox(height: 20),
          _buildInfoRow(
            'Cycle Regularity',
            report.isIrregular ? 'Irregular' : 'Regular',
          ),
          _buildInfoRow(
            'Standard Deviation',
            '${report.standardDeviation.toStringAsFixed(2)} days',
          ),
          if (report.minLength != null)
            _buildInfoRow('Shortest Cycle', '${report.minLength} days'),
          if (report.maxLength != null)
            _buildInfoRow('Longest Cycle', '${report.maxLength} days'),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.purple50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              report.message,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
          pw.SizedBox(height: 30),
          pw.Text(
            'Cycle Length Distribution',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 15),
          _buildCycleLengthTable(cycles),
        ],
      ),
    );
  }

  /// Build cycle history page
  pw.Page _buildCycleHistoryPage(List<PeriodCycle> cycles) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Cycle History',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple700,
            ),
          ),
          pw.SizedBox(height: 20),
          _buildCycleHistoryTable(cycles),
        ],
      ),
    );
  }

  /// Build info row
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(value, style: const pw.TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  /// Build cycle length distribution table
  pw.Widget _buildCycleLengthTable(List<PeriodCycle> cycles) {
    final validCycles = cycles.where((c) => c.cycleLength != null).toList();

    if (validCycles.isEmpty) {
      return pw.Text('No cycle data available');
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.purple200),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.purple100),
          children: [
            _buildTableCell('Cycle #', isHeader: true),
            _buildTableCell('Length (days)', isHeader: true),
            _buildTableCell('Status', isHeader: true),
          ],
        ),
        ...List.generate(validCycles.length > 10 ? 10 : validCycles.length, (
          index,
        ) {
          final cycle = validCycles[index];
          return pw.TableRow(
            children: [
              _buildTableCell('${index + 1}'),
              _buildTableCell('${cycle.cycleLength}'),
              _buildTableCell(cycle.isConfirmed ? 'Confirmed' : 'Predicted'),
            ],
          );
        }),
      ],
    );
  }

  /// Build cycle history table
  pw.Widget _buildCycleHistoryTable(List<PeriodCycle> cycles) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.purple200),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.purple100),
          children: [
            _buildTableCell('Start Date', isHeader: true),
            _buildTableCell('End Date', isHeader: true),
            _buildTableCell('Length', isHeader: true),
          ],
        ),
        ...cycles.take(15).map((cycle) {
          return pw.TableRow(
            children: [
              _buildTableCell(cycle.startDate.toString().split(' ')[0]),
              _buildTableCell(
                cycle.endDate?.toString().split(' ')[0] ?? 'Ongoing',
              ),
              _buildTableCell(cycle.cycleLength?.toString() ?? '-'),
            ],
          );
        }),
      ],
    );
  }

  /// Build table cell
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  /// Get PDF file path
  Future<String> _getPdfPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/femora_period_report_$timestamp.pdf';
  }

  /// Generate and share report
  Future<void> generateAndShare() async {
    try {
      final file = await generateReport();
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Femora Period Tracking Report',
        text: 'Your period tracking report from Femora',
      );
    } catch (e) {
      throw Exception('Failed to share PDF report: $e');
    }
  }
}
