// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'dart:typed_data';

enum ReportPeriod { weekly, monthly, semester, annual, custom }

extension ReportPeriodExt on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.weekly:   return 'Weekly';
      case ReportPeriod.monthly:  return 'Monthly';
      case ReportPeriod.semester: return 'Semester';
      case ReportPeriod.annual:   return 'Annual';
      case ReportPeriod.custom:   return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportPeriod.weekly:   return Icons.view_week_rounded;
      case ReportPeriod.monthly:  return Icons.calendar_month_rounded;
      case ReportPeriod.semester: return Icons.school_rounded;
      case ReportPeriod.annual:   return Icons.calendar_today_rounded;
      case ReportPeriod.custom:   return Icons.date_range_rounded;
    }
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.monthly;
  String _reportType = 'inventory';
  String? _filterLabId;
  DateTime _dateFrom = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dateTo = DateTime.now();
  bool _generating = false;

  void _applyPeriod(ReportPeriod period) {
    final now = DateTime.now();
    setState(() {
      _period = period;
      switch (period) {
        case ReportPeriod.weekly:
          _dateFrom = now.subtract(const Duration(days: 7));
          _dateTo = now;
          break;
        case ReportPeriod.monthly:
          _dateFrom = DateTime(now.year, now.month, 1);
          _dateTo = now;
          break;
        case ReportPeriod.semester:
          if (now.month >= 6 && now.month <= 10) {
            _dateFrom = DateTime(now.year, 6, 1);
            _dateTo = DateTime(now.year, 10, 31);
          } else if (now.month >= 11) {
            _dateFrom = DateTime(now.year, 11, 1);
            _dateTo = DateTime(now.year + 1, 3, 31);
          } else {
            _dateFrom = DateTime(now.year - 1, 11, 1);
            _dateTo = DateTime(now.year, 3, 31);
          }
          break;
        case ReportPeriod.annual:
          _dateFrom = DateTime(now.year, 1, 1);
          _dateTo = DateTime(now.year, 12, 31);
          break;
        case ReportPeriod.custom:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currency = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final fmt = DateFormat('MMM d, y');

    final borrowingInPeriod = provider.borrowingRecords.where((r) {
      return r.borrowDate.isAfter(_dateFrom.subtract(const Duration(days: 1))) &&
             r.borrowDate.isBefore(_dateTo.add(const Duration(days: 1)));
    }).toList();

    final maintenanceInPeriod = provider.maintenanceRecords.where((r) {
      return r.maintenanceDate.isAfter(_dateFrom.subtract(const Duration(days: 1))) &&
             r.maintenanceDate.isBefore(_dateTo.add(const Duration(days: 1)));
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Row(children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reports',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                Text('Generate and print inventory reports',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _generating ? null : () => _printReport(provider, currency),
              icon: _generating
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.print_rounded, size: 18),
              label: Text(_generating ? 'Generating...' : 'Print Report'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Report Settings Card (REDESIGNED) ───────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(children: [
                  const Icon(Icons.tune_rounded, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  const Text('Report Settings',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                  const Spacer(),
                  // Active date range badge (always visible)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${fmt.format(_dateFrom)}  -  ${fmt.format(_dateTo)}',
                        style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 16),

                // Row 1: Period segmented control + filters
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  // Label
                  const SizedBox(
                    width: 52,
                    child: Text('Period',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  ),

                  // Segmented control pill
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: ReportPeriod.values.map((p) {
                          final selected = _period == p;
                          final isLast = p == ReportPeriod.values.last;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _applyPeriod(p),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: selected ? AppTheme.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: selected
                                      ? [BoxShadow(
                                          color: AppTheme.primary.withOpacity(0.25),
                                          blurRadius: 6, offset: const Offset(0, 2))]
                                      : null,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(p.icon,
                                          size: 12,
                                          color: selected ? Colors.white : AppTheme.textSecondary),
                                      const SizedBox(width: 5),
                                      Text(p.label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                            color: selected ? Colors.white : AppTheme.textSecondary,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Laboratory dropdown
                  _FilterDropdown(
                    label: 'Laboratory',
                    icon: Icons.science_rounded,
                    width: 170,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterLabId,
                        isExpanded: true,
                        isDense: true,
                        hint: const Text('All Labs',
                            style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Labs')),
                          ...provider.laboratories.map(
                              (l) => DropdownMenuItem(value: l.id, child: Text(l.name))),
                        ],
                        onChanged: (v) => setState(() => _filterLabId = v),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Report type dropdown
                  _FilterDropdown(
                    label: 'Report Type',
                    icon: Icons.description_rounded,
                    width: 190,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _reportType,
                        isExpanded: true,
                        isDense: true,
                        items: const [
                          DropdownMenuItem(value: 'inventory',   child: Text('Inventory')),
                          DropdownMenuItem(value: 'borrowing',   child: Text('Borrowing')),
                          DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                          DropdownMenuItem(value: 'full',        child: Text('Full Report')),
                        ],
                        onChanged: (v) => setState(() => _reportType = v!),
                      ),
                    ),
                  ),
                ]),

                // Row 2: Custom date pickers (only shown when Custom is selected)
                if (_period == ReportPeriod.custom) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    const SizedBox(width: 52),
                    Expanded(child: _DatePickerField(
                      label: 'From Date',
                      value: _dateFrom,
                      onChanged: (d) => setState(() => _dateFrom = d ?? _dateFrom),
                    )),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(child: _DatePickerField(
                      label: 'To Date',
                      value: _dateTo,
                      onChanged: (d) => setState(() => _dateTo = d ?? _dateTo),
                    )),
                    const Spacer(),
                  ]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Report Content ───────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(children: [
                    _StatMini('Total Equipment', '${provider.equipment.length} types',
                        Icons.inventory_2_rounded, AppTheme.primary),
                    const SizedBox(width: 12),
                    _StatMini('Total Value',
                        currency.format(provider.equipment.fold(0.0, (s, e) => s + e.unitCost * e.quantity)),
                        Icons.attach_money_rounded, AppTheme.secondary),
                    const SizedBox(width: 12),
                    _StatMini('Borrowing (Period)', '${borrowingInPeriod.length} records',
                        Icons.swap_horiz_rounded, AppTheme.accent),
                    const SizedBox(width: 12),
                    _StatMini('Maintenance (Period)', '${maintenanceInPeriod.length} records',
                        Icons.build_rounded, AppTheme.warning),
                  ]),
                  const SizedBox(height: 20),

                  if (_reportType == 'inventory' || _reportType == 'full') ...[
                    _EquipmentSummaryTable(provider: provider, filterLabId: _filterLabId, currency: currency),
                    const SizedBox(height: 20),
                  ],
                  if (_reportType == 'borrowing' || _reportType == 'full') ...[
                    _BorrowingReportTable(records: borrowingInPeriod, dateFrom: _dateFrom, dateTo: _dateTo),
                    const SizedBox(height: 20),
                  ],
                  if (_reportType == 'maintenance' || _reportType == 'full') ...[
                    _MaintenanceReportTable(
                        records: maintenanceInPeriod, currency: currency,
                        dateFrom: _dateFrom, dateTo: _dateTo),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printReport(AppProvider provider, NumberFormat currency) async {
    setState(() => _generating = true);
    try {
      final pdf = await _generatePdf(provider, currency);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _PdfPreviewScreen(
            title: '${_period.label} ${_reportTypeLabel()} Report',
            pdfData: pdf,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Error generating PDF: \$e', type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<Uint8List> _generatePdf(AppProvider provider, NumberFormat currency) async {
    // ── Load fonts with full Unicode support (fixes ₱ symbol) ──────
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold    = await PdfGoogleFonts.notoSansBold();
    final fontItalic  = await PdfGoogleFonts.notoSansItalic();

    // ── Load the header image via rootBundle ─────────────────────────
    pw.ImageProvider? headerImage;
    try {
      final headerImageData = await rootBundle.load('assets/header.png');
      headerImage = pw.MemoryImage(headerImageData.buffer.asUint8List());
    } catch (_) {
      // fallback: header image will be skipped, text header used instead
    }

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base:   fontRegular,
        bold:   fontBold,
        italic: fontItalic,
      ),
    );
    final fmt      = DateFormat('MMM d, y');
    final timeFmt  = DateFormat('MMM d, y - hh:mm a');
    final now      = DateTime.now();

    // ── Filtered data ────────────────────────────────────────────
    final borrowingInPeriod = provider.borrowingRecords.where((r) =>
        r.borrowDate.isAfter(_dateFrom.subtract(const Duration(days: 1))) &&
        r.borrowDate.isBefore(_dateTo.add(const Duration(days: 1)))).toList();

    final maintenanceInPeriod = provider.maintenanceRecords.where((r) =>
        r.maintenanceDate.isAfter(_dateFrom.subtract(const Duration(days: 1))) &&
        r.maintenanceDate.isBefore(_dateTo.add(const Duration(days: 1)))).toList();

    var filteredEquipment = provider.equipment;
    if (_filterLabId != null) {
      filteredEquipment = filteredEquipment.where((e) => e.laboratoryId == _filterLabId).toList();
    }

    final labName = _filterLabId != null
        ? provider.laboratories.firstWhere((l) => l.id == _filterLabId,
            orElse: () => provider.laboratories.first).name
        : 'All Laboratories';

    // ── Colors ───────────────────────────────────────────────────
    final primary     = PdfColor.fromHex('#1E40AF');
    final primaryDark = PdfColor.fromHex('#1e3a8a');
    final accent      = PdfColor.fromHex('#0F766E');
    final warning     = PdfColor.fromHex('#B45309');
    final success     = PdfColor.fromHex('#15803D');
    final error       = PdfColor.fromHex('#B91C1C');
    final lightBlue   = PdfColor.fromHex('#EFF6FF');
    final lightGray   = PdfColor.fromHex('#F8FAFC');
    final borderColor = PdfColor.fromHex('#E2E8F0');
    final textGray    = PdfColor.fromHex('#64748B');

    // ── Helpers ──────────────────────────────────────────────────
    pw.Widget _cell(String text, {bool bold = false, PdfColor? color}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: pw.Text(text,
              style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: color ?? PdfColor.fromHex('#1E293B'))),
        );

    pw.Widget _headerCell(String text) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: pw.Text(text,
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8.5,
                  letterSpacing: 0.3)),
        );

    pw.Widget _statBox(String label, String value, PdfColor color) =>
        pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(right: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: borderColor, width: 0.8),
            ),
            child: pw.Row(
              children: [
                // Left colored accent bar
                pw.Container(width: 4, color: color),
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.fromLTRB(10, 9, 10, 9),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(value,
                            style: pw.TextStyle(
                                fontSize: 15, fontWeight: pw.FontWeight.bold, color: color)),
                        pw.SizedBox(height: 3),
                        pw.Text(label,
                            style: pw.TextStyle(fontSize: 7.5, color: textGray)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

    // ── Overview row: label + value with colored dot indicator ──
    pw.Widget _overviewRow(String label, String value, PdfColor color) =>
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(children: [
              pw.Container(
                width: 6, height: 6,
                decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
              ),
              pw.SizedBox(width: 6),
              pw.Text(label, style: pw.TextStyle(fontSize: 8, color: textGray)),
            ]),
            pw.Text(value,
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        );

    pw.Widget _sectionTitle(String title, String subtitle, PdfColor color) =>
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(14, 9, 14, 9),
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(5),
              topRight: pw.Radius.circular(5),
            ),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 3, height: 22,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(title,
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11)),
                pw.SizedBox(height: 1),
                pw.Text(subtitle,
                    style: pw.TextStyle(color: PdfColor.fromHex('#E0EAFF'), fontSize: 7.5)),
              ]),
            ],
          ),
        );

    // ── Page header (letterhead) ──────────────────────────────────
    pw.Widget letterhead() => pw.Column(children: [
      // White header area with official header image
      pw.Container(
        color: PdfColors.white,
        child: pw.Column(children: [
          // Official CPSU header image (logos + university name)
          if (headerImage != null)
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(40, 4, 40, 0),
              child: pw.Image(headerImage!, fit: pw.BoxFit.contain, height: 60),
            )
          else
            // Fallback text header if image not found
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                    pw.Text('CENTRAL PHILIPPINES STATE UNIVERSITY',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold,
                            color: primary, letterSpacing: 0.5)),
                    pw.Text('San Carlos Campus  |  Kabankalan City, Negros Occidental',
                        style: pw.TextStyle(fontSize: 9, color: textGray)),
                    pw.Text('College of Computer Studies',
                        style: pw.TextStyle(fontSize: 9, color: textGray,
                            fontStyle: pw.FontStyle.italic)),
                  ]),
                ],
              ),
            ),
          // Thin gold divider line
          pw.Container(height: 3, color: PdfColor.fromHex('#9B7A00')),
          // Dark blue info bar
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 7),
            color: primary,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(
                    '${_period.label.toUpperCase()} ${_reportTypeLabel().toUpperCase()} REPORT',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Laboratory Management System  |  College of Computer Studies',
                    style: pw.TextStyle(color: PdfColor.fromHex('#BFD7FF'), fontSize: 7.5),
                  ),
                ]),
                pw.Spacer(),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text(
                    'Period: ${fmt.format(_dateFrom)} to ${fmt.format(_dateTo)}',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Laboratory: $labName  |  Generated: ${timeFmt.format(now)}',
                    style: pw.TextStyle(color: PdfColor.fromHex('#BFD7FF'), fontSize: 7.5),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
      pw.SizedBox(height: 8),
    ]);

    // ── Page footer ──────────────────────────────────────────────
    pw.Widget footer(pw.Context ctx) => pw.Column(children: [
      pw.Container(height: 1, color: primary),
      pw.SizedBox(height: 5),
      pw.Row(children: [
        pw.Container(
          width: 4, height: 4,
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#9B7A00'), shape: pw.BoxShape.circle),
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          'Central Philippines State University - San Carlos Campus  |  College of Computer Studies',
          style: pw.TextStyle(fontSize: 7, color: textGray),
        ),
        pw.Spacer(),
        pw.Text(
          'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: pw.TextStyle(fontSize: 7, color: textGray, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 6),
        pw.Container(
          width: 4, height: 4,
          decoration: pw.BoxDecoration(color: primary, shape: pw.BoxShape.circle),
        ),
      ]),
    ]);


    // ── Signature section ─────────────────────────────────────────
    pw.Widget signatureSection() => pw.Container(
      margin: const pw.EdgeInsets.only(top: 32),
      child: pw.Column(children: [
        pw.Container(height: 1, color: borderColor),
        pw.SizedBox(height: 16),
        pw.Row(children: [
          // Prepared by
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
              pw.Container(height: 0.8, color: PdfColors.black, margin: const pw.EdgeInsets.symmetric(horizontal: 20)),
              pw.SizedBox(height: 5),
              pw.Text('Prepared by', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primary)),
              pw.Text('Lab Custodian / Student Assistant', style: pw.TextStyle(fontSize: 7.5, color: textGray)),
              pw.Text('College of Computer Studies', style: pw.TextStyle(fontSize: 7.5, color: textGray)),
            ]),
          ),
          pw.SizedBox(width: 20),
          // Approved by
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
              pw.Container(height: 0.8, color: PdfColors.black, margin: const pw.EdgeInsets.symmetric(horizontal: 20)),
              pw.SizedBox(height: 5),
              pw.Text('Approved by', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primary)),
              pw.Text('Dean / Department Head', style: pw.TextStyle(fontSize: 7.5, color: textGray)),
              pw.Text('College of Computer Studies', style: pw.TextStyle(fontSize: 7.5, color: textGray)),
            ]),
          ),
        ]),
      ]),
    );

    // ── SUMMARY PAGE ─────────────────────────────────────────────
    final totalEquipment   = filteredEquipment.fold(0, (s, e) => s + e.quantity);
    final totalValue       = filteredEquipment.fold(0.0, (s, e) => s + e.unitCost * e.quantity);
    final activeCount      = filteredEquipment.where((e) => e.status == 'active').fold(0, (s, e) => s + e.quantity);
    final repairCount      = filteredEquipment.where((e) => e.status == 'under_repair').fold(0, (s, e) => s + e.quantity);
    final borrowedCount    = borrowingInPeriod.where((r) => r.status == 'borrowed').length;
    final overdueCount     = borrowingInPeriod.where((r) => r.status == 'overdue').length;
    final returnedCount    = borrowingInPeriod.where((r) => r.status == 'returned').length;
    final maintenanceCost  = maintenanceInPeriod.fold(0.0, (s, r) => s + r.cost);
    final completedMaint   = maintenanceInPeriod.where((r) => r.status == 'completed').length;

    // Status breakdown for equipment
    final statusGroups = <String, List<Equipment>>{};
    for (final eq in filteredEquipment) {
      statusGroups.putIfAbsent(eq.status, () => []).add(eq);
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 8, 28, 20),
      header: (_) => letterhead(),
      footer: footer,
      build: (_) => [
        // ── REPORT OVERVIEW header ──
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: pw.BoxDecoration(
            color: primary,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(5),
              topRight: pw.Radius.circular(5),
            ),
          ),
          child: pw.Row(children: [
            pw.Container(width: 3, height: 20, color: PdfColors.white),
            pw.SizedBox(width: 10),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('REPORT OVERVIEW',
                  style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11, letterSpacing: 1)),
              pw.Text('Summary of inventory, borrowing, and maintenance for the selected period',
                  style: pw.TextStyle(color: PdfColor.fromHex('#BFD7FF'), fontSize: 7.5)),
            ]),
            pw.Spacer(),
            pw.Text('As of ${timeFmt.format(now)}',
                style: pw.TextStyle(color: PdfColor.fromHex('#BFD7FF'), fontSize: 7.5, fontStyle: pw.FontStyle.italic)),
          ]),
        ),

        // ── Three grouped stat sections side by side ──
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: borderColor),
            borderRadius: const pw.BorderRadius.only(
              bottomLeft: pw.Radius.circular(5),
              bottomRight: pw.Radius.circular(5),
            ),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Inventory group ──
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(right: pw.BorderSide(color: borderColor, width: 0.8)),
                  ),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    // Group label
                    pw.Row(children: [
                      pw.Container(width: 3, height: 12, color: primary,
                          margin: const pw.EdgeInsets.only(right: 6)),
                      pw.Text('INVENTORY',
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold,
                              color: primary, letterSpacing: 0.8)),
                    ]),
                    pw.SizedBox(height: 10),
                    // Stat rows
                    _overviewRow('Total Equipment', '$totalEquipment units', primary),
                    pw.SizedBox(height: 6),
                    _overviewRow('Inventory Value', currency.format(totalValue), accent),
                    pw.SizedBox(height: 6),
                    _overviewRow('Active Units', '$activeCount', success),
                    pw.SizedBox(height: 6),
                    _overviewRow('Under Repair', '$repairCount', warning),
                  ]),
                ),
              ),
              // ── Borrowing group ──
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(right: pw.BorderSide(color: borderColor, width: 0.8)),
                  ),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Row(children: [
                      pw.Container(width: 3, height: 12, color: PdfColor.fromHex('#7C3AED'),
                          margin: const pw.EdgeInsets.only(right: 6)),
                      pw.Text('BORROWING',
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#7C3AED'), letterSpacing: 0.8)),
                    ]),
                    pw.SizedBox(height: 10),
                    _overviewRow('Total Records', '${borrowingInPeriod.length}', primary),
                    pw.SizedBox(height: 6),
                    _overviewRow('Currently Borrowed', '$borrowedCount', accent),
                    pw.SizedBox(height: 6),
                    _overviewRow('Returned', '$returnedCount', success),
                    pw.SizedBox(height: 6),
                    _overviewRow('Overdue', '$overdueCount', error),
                  ]),
                ),
              ),
              // ── Maintenance group ──
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Row(children: [
                      pw.Container(width: 3, height: 12, color: warning,
                          margin: const pw.EdgeInsets.only(right: 6)),
                      pw.Text('MAINTENANCE',
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold,
                              color: warning, letterSpacing: 0.8)),
                    ]),
                    pw.SizedBox(height: 10),
                    _overviewRow('Total Records', '${maintenanceInPeriod.length}', primary),
                    pw.SizedBox(height: 6),
                    _overviewRow('Completed', '$completedMaint', success),
                    pw.SizedBox(height: 6),
                    _overviewRow('In Progress',
                        '${maintenanceInPeriod.where((r) => r.status == 'in_progress').length}', warning),
                    pw.SizedBox(height: 6),
                    _overviewRow('Total Cost', currency.format(maintenanceCost), error),
                  ]),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // ── Equipment by status breakdown ──
        _sectionTitle('Equipment Status Breakdown', 'Distribution of equipment across all status categories', primary),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: borderColor),
            borderRadius: const pw.BorderRadius.only(
              bottomLeft: pw.Radius.circular(6),
              bottomRight: pw.Radius.circular(6),
            ),
          ),
          child: pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: lightBlue),
                children: ['Status', 'Item Types', 'Total Units', 'Total Value']
                    .map(_headerCell).toList(),
              ),
              ...statusGroups.entries.toList().asMap().entries.map((me) {
                final e = me.value;
                final units = e.value.fold(0, (s, eq) => s + eq.quantity);
                final val = e.value.fold(0.0, (s, eq) => s + eq.unitCost * eq.quantity);
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: me.key.isEven ? lightGray : PdfColors.white),
                  children: [
                    _cell(AppConstants.formatStatus(e.key), bold: true),
                    _cell('${e.value.length}'),
                    _cell('$units'),
                    _cell(currency.format(val), bold: true),
                  ],
                );
              }),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // ── Category breakdown ──
        () {
          final catGroups = <String, List<Equipment>>{};
          for (final eq in filteredEquipment) {
            catGroups.putIfAbsent(eq.categoryName ?? 'Uncategorized', () => []).add(eq);
          }
          return pw.Column(children: [
            _sectionTitle('Equipment by Category', 'Item counts and values grouped by category', accent),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderColor),
                borderRadius: const pw.BorderRadius.only(
                  bottomLeft: pw.Radius.circular(6),
                  bottomRight: pw.Radius.circular(6),
                ),
              ),
              child: pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#ECFDF5')),
                    children: ['Category', 'Item Types', 'Total Units', 'Total Value']
                        .map(_headerCell).map((w) => pw.Container(
                            color: accent,
                            child: w)).toList(),
                  ),
                  ...catGroups.entries.toList().asMap().entries.map((me) {
                    final e = me.value;
                    final units = e.value.fold(0, (s, eq) => s + eq.quantity);
                    final val = e.value.fold(0.0, (s, eq) => s + eq.unitCost * eq.quantity);
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                          color: me.key.isEven ? lightGray : PdfColors.white),
                      children: [
                        _cell(e.key, bold: true),
                        _cell('${e.value.length}'),
                        _cell('$units'),
                        _cell(currency.format(val), bold: true),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ]);
        }(),

        signatureSection(),
      ],
    ));

    // ── EQUIPMENT INVENTORY PAGE ─────────────────────────────────
    if (_reportType == 'inventory' || _reportType == 'full') {
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(28, 8, 28, 20),
        header: (_) => letterhead(),
        footer: footer,
        build: (_) => [
          _sectionTitle(
            'Equipment Inventory',
            '${filteredEquipment.length} records  |  ${filteredEquipment.fold(0, (s, e) => s + e.quantity)} total units  |  ${currency.format(filteredEquipment.fold(0.0, (s, e) => s + e.unitCost * e.quantity))} total value',
            primary,
          ),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderColor),
              borderRadius: const pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(6),
                bottomRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Table(
              border: pw.TableBorder.symmetric(
                inside: pw.BorderSide(color: borderColor, width: 0.5),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(0.8),
                5: const pw.FlexColumnWidth(1.8),
                6: const pw.FlexColumnWidth(1.8),
                7: const pw.FlexColumnWidth(2),
                8: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primary),
                  children: ['Equipment', 'Brand', 'Model', 'Serial No.', 'Qty',
                    'Status', 'Condition', 'Unit Cost', 'Total Value']
                      .map(_headerCell).toList(),
                ),
                ...filteredEquipment.asMap().entries.map((entry) {
                  final eq = entry.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                        color: entry.key.isEven ? lightGray : PdfColors.white),
                    children: [
                      _cell(eq.name, bold: true),
                      _cell(eq.brand ?? '-'),
                      _cell(eq.model ?? '-'),
                      _cell(eq.serialNumber ?? '-'),
                      _cell('${eq.quantity}'),
                      _cell(AppConstants.formatStatus(eq.status)),
                      _cell(AppConstants.formatStatus(eq.condition)),
                      _cell(currency.format(eq.unitCost)),
                      _cell(currency.format(eq.unitCost * eq.quantity), bold: true),
                    ],
                  );
                }),
                // Totals row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#EFF6FF')),
                  children: [
                    _cell('TOTAL', bold: true),
                    _cell(''), _cell(''), _cell(''),
                    _cell('${filteredEquipment.fold(0, (s, e) => s + e.quantity)}', bold: true),
                    _cell(''), _cell(''), _cell(''),
                    _cell(currency.format(filteredEquipment.fold(0.0, (s, e) => s + e.unitCost * e.quantity)), bold: true),
                  ],
                ),
              ],
            ),
          ),
          signatureSection(),
        ],
      ));
    }

    // ── BORROWING PAGE ───────────────────────────────────────────
    if (_reportType == 'borrowing' || _reportType == 'full') {
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(28, 8, 28, 20),
        header: (_) => letterhead(),
        footer: footer,
        build: (_) => [
          // Borrowing summary boxes
          pw.Row(children: [
            _statBox('Total Records', '${borrowingInPeriod.length}', primary),
            _statBox('Borrowed', '$borrowedCount', warning),
            _statBox('Returned', '$returnedCount', success),
            _statBox('Overdue', '$overdueCount', error),
            pw.Expanded(child: pw.SizedBox()),
          ]),
          pw.SizedBox(height: 12),
          _sectionTitle(
            'Borrowing Records',
            'Period: ${fmt.format(_dateFrom)}  -  ${fmt.format(_dateTo)}',
            PdfColor.fromHex('#7C3AED'),
          ),
          borrowingInPeriod.isEmpty
              ? pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderColor),
                      borderRadius: const pw.BorderRadius.only(
                        bottomLeft: pw.Radius.circular(6),
                        bottomRight: pw.Radius.circular(6),
                      )),
                  child: pw.Center(
                    child: pw.Text('No borrowing records in this period.',
                        style: pw.TextStyle(color: textGray, fontSize: 10)),
                  ),
                )
              : pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderColor),
                    borderRadius: const pw.BorderRadius.only(
                      bottomLeft: pw.Radius.circular(6),
                      bottomRight: pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Table(
                    border: pw.TableBorder.symmetric(
                        inside: pw.BorderSide(color: borderColor, width: 0.5)),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2.5),
                      1: const pw.FlexColumnWidth(1.5),
                      2: const pw.FlexColumnWidth(2.5),
                      3: const pw.FlexColumnWidth(2),
                      4: const pw.FlexColumnWidth(0.8),
                      5: const pw.FlexColumnWidth(2),
                      6: const pw.FlexColumnWidth(2),
                      7: const pw.FlexColumnWidth(1.5),
                    },
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#7C3AED')),
                        children: ['Borrower', 'ID No.', 'Equipment',
                          'Department', 'Qty', 'Borrow Date', 'Return Date', 'Status']
                            .map(_headerCell).toList(),
                      ),
                      ...borrowingInPeriod.asMap().entries.map((entry) {
                        final r = entry.value;
                        return pw.TableRow(
                          decoration: pw.BoxDecoration(
                              color: entry.key.isEven ? lightGray : PdfColors.white),
                          children: [
                            _cell(r.borrowerName, bold: true),
                            _cell(r.borrowerIdNumber ?? '-'),
                            _cell(r.equipmentName ?? '-'),
                            _cell(r.department ?? '-'),
                            _cell('${r.quantityBorrowed}'),
                            _cell(fmt.format(r.borrowDate)),
                            _cell(r.expectedReturnDate != null
                                ? fmt.format(r.expectedReturnDate!) : '-'),
                            _cell(AppConstants.formatStatus(r.status)),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
          signatureSection(),
        ],
      ));
    }

    // ── MAINTENANCE PAGE ─────────────────────────────────────────
    if (_reportType == 'maintenance' || _reportType == 'full') {
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(28, 8, 28, 20),
        header: (_) => letterhead(),
        footer: footer,
        build: (_) => [
          pw.Row(children: [
            _statBox('Total Records', '${maintenanceInPeriod.length}', primary),
            _statBox('Completed', '$completedMaint', success),
            _statBox('In Progress',
                '${maintenanceInPeriod.where((r) => r.status == 'in_progress').length}', warning),
            _statBox('Total Cost', currency.format(maintenanceCost), error),
            pw.Expanded(child: pw.SizedBox()),
          ]),
          pw.SizedBox(height: 12),
          _sectionTitle(
            'Maintenance Records',
            'Period: ${fmt.format(_dateFrom)}  -  ${fmt.format(_dateTo)}  |  Total Cost: ${currency.format(maintenanceCost)}',
            PdfColor.fromHex('#B45309'),
          ),
          maintenanceInPeriod.isEmpty
              ? pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderColor),
                      borderRadius: const pw.BorderRadius.only(
                        bottomLeft: pw.Radius.circular(6),
                        bottomRight: pw.Radius.circular(6),
                      )),
                  child: pw.Center(
                    child: pw.Text('No maintenance records in this period.',
                        style: pw.TextStyle(color: textGray, fontSize: 10)),
                  ),
                )
              : pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderColor),
                    borderRadius: const pw.BorderRadius.only(
                      bottomLeft: pw.Radius.circular(6),
                      bottomRight: pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Table(
                    border: pw.TableBorder.symmetric(
                        inside: pw.BorderSide(color: borderColor, width: 0.5)),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2.5),
                      1: const pw.FlexColumnWidth(1.8),
                      2: const pw.FlexColumnWidth(3),
                      3: const pw.FlexColumnWidth(2),
                      4: const pw.FlexColumnWidth(1.8),
                      5: const pw.FlexColumnWidth(1.5),
                      6: const pw.FlexColumnWidth(1.5),
                    },
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#B45309')),
                        children: ['Equipment', 'Type', 'Description',
                          'Performed By', 'Date', 'Cost', 'Status']
                            .map(_headerCell).toList(),
                      ),
                      ...maintenanceInPeriod.asMap().entries.map((entry) {
                        final r = entry.value;
                        return pw.TableRow(
                          decoration: pw.BoxDecoration(
                              color: entry.key.isEven ? lightGray : PdfColors.white),
                          children: [
                            _cell(r.equipmentName ?? '-', bold: true),
                            _cell(AppConstants.formatStatus(r.maintenanceType)),
                            _cell(r.description ?? '-'),
                            _cell(r.performedBy ?? '-'),
                            _cell(fmt.format(r.maintenanceDate)),
                            _cell(currency.format(r.cost), bold: true),
                            _cell(AppConstants.formatStatus(r.status)),
                          ],
                        );
                      }),
                      // Totals row
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FEF3C7')),
                        children: [
                          _cell('TOTAL', bold: true),
                          _cell(''), _cell(''), _cell(''), _cell(''),
                          _cell(currency.format(maintenanceCost), bold: true),
                          _cell(''),
                        ],
                      ),
                    ],
                  ),
                ),
          signatureSection(),
        ],
      ));
    }

    return doc.save();
  }

  String _reportTypeLabel() {
    switch (_reportType) {
      case 'inventory':   return 'Inventory';
      case 'borrowing':   return 'Borrowing';
      case 'maintenance': return 'Maintenance';
      case 'full':        return 'Full';
      default:            return '';
    }
  }
}

// ── Helper widget: labeled filter dropdown box ──────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final double width;
  final Widget child;
  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.width,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 11, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ]),
          const SizedBox(height: 4),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

// =================== REPORT TABLES (SCREEN) ===================

class _EquipmentSummaryTable extends StatelessWidget {
  final AppProvider provider;
  final String? filterLabId;
  final NumberFormat currency;
  const _EquipmentSummaryTable({required this.provider, this.filterLabId, required this.currency});

  @override
  Widget build(BuildContext context) {
    var equipment = provider.equipment;
    if (filterLabId != null) equipment = equipment.where((e) => e.laboratoryId == filterLabId).toList();

    final statusCounts = <String, int>{};
    for (var e in equipment) {
      statusCounts[e.status] = (statusCounts[e.status] ?? 0) + e.quantity;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.inventory_2_rounded, color: AppTheme.primary, size: 20),
            const SizedBox(width: 10),
            const Expanded(child: Text('Equipment Inventory',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
            ...statusCounts.entries.map((e) => Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.statusColor(e.key).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${AppConstants.formatStatus(e.key)}: ${e.value}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppConstants.statusColor(e.key))),
            )),
          ]),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: const Row(children: [
                  Expanded(flex: 3, child: _RH('Equipment')),
                  Expanded(flex: 2, child: _RH('Category')),
                  Expanded(flex: 2, child: _RH('Laboratory')),
                  Expanded(child: _RH('Qty')),
                  Expanded(flex: 2, child: _RH('Status')),
                  Expanded(flex: 2, child: _RH('Unit Cost')),
                  Expanded(flex: 2, child: _RH('Total Value')),
                ]),
              ),
              ...equipment.take(20).map((eq) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border))),
                child: Row(children: [
                  Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(eq.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    if (eq.serialNumber != null)
                      Text(eq.serialNumber!,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ])),
                  Expanded(flex: 2, child: Text(eq.categoryName ?? '-', style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 2, child: Text(eq.laboratoryName ?? '-',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                  Expanded(child: Text('${eq.quantity}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: StatusBadge(status: eq.status)),
                  Expanded(flex: 2, child: Text(currency.format(eq.unitCost),
                      style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 2, child: Text(currency.format(eq.unitCost * eq.quantity),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppTheme.primary))),
                ]),
              )),
              if (equipment.length > 20)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('+ ${equipment.length - 20} more items (visible in printed report)',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text(
              'Total: ${equipment.fold(0, (s, e) => s + e.quantity)} items  |  '
              'Value: ${currency.format(equipment.fold(0.0, (s, e) => s + e.unitCost * e.quantity))}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 14),
            ),
          ]),
        ],
      ),
    );
  }
}

class _BorrowingReportTable extends StatelessWidget {
  final List<BorrowingRecord> records;
  final DateTime dateFrom;
  final DateTime dateTo;
  const _BorrowingReportTable(
      {required this.records, required this.dateFrom, required this.dateTo});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, y');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.swap_horiz_rounded, color: AppTheme.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(
              'Borrowing Records: ${fmt.format(dateFrom)} - ${fmt.format(dateTo)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          Text('${records.length} records',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ]),
        const SizedBox(height: 16),
        records.isEmpty
            ? const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No borrowing records in this period.',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ))
            : Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border)),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    ),
                    child: const Row(children: [
                      Expanded(flex: 2, child: _RH('Borrower')),
                      Expanded(flex: 2, child: _RH('Equipment')),
                      Expanded(flex: 2, child: _RH('Department')),
                      Expanded(child: _RH('Qty')),
                      Expanded(flex: 2, child: _RH('Borrow Date')),
                      Expanded(flex: 2, child: _RH('Return Date')),
                      Expanded(flex: 2, child: _RH('Status')),
                    ]),
                  ),
                  ...records.take(15).map((r) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppTheme.border))),
                    child: Row(children: [
                      Expanded(flex: 2, child: Text(r.borrowerName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                      Expanded(flex: 2, child: Text(r.equipmentName ?? '-',
                          style: const TextStyle(fontSize: 13))),
                      Expanded(flex: 2, child: Text(r.department ?? '-',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                      Expanded(child: Text('${r.quantityBorrowed}',
                          style: const TextStyle(fontSize: 13))),
                      Expanded(flex: 2, child: Text(fmt.format(r.borrowDate),
                          style: const TextStyle(fontSize: 13))),
                      Expanded(flex: 2, child: Text(
                          r.expectedReturnDate != null ? fmt.format(r.expectedReturnDate!) : '-',
                          style: const TextStyle(fontSize: 13))),
                      Expanded(flex: 2, child: StatusBadge(status: r.status)),
                    ]),
                  )),
                ]),
              ),
      ]),
    );
  }
}

class _MaintenanceReportTable extends StatelessWidget {
  final List<MaintenanceRecord> records;
  final NumberFormat currency;
  final DateTime dateFrom;
  final DateTime dateTo;
  const _MaintenanceReportTable(
      {required this.records, required this.currency,
       required this.dateFrom, required this.dateTo});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, y');
    final totalCost = records.fold(0.0, (s, r) => s + r.cost);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.build_rounded, color: AppTheme.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(
              'Maintenance Records: ${fmt.format(dateFrom)} - ${fmt.format(dateTo)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          Text('Total Cost: ${currency.format(totalCost)}',
              style: const TextStyle(
                  color: AppTheme.warning, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 16),
        records.isEmpty
            ? const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No maintenance records in this period.',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ))
            : Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border)),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    ),
                    child: const Row(children: [
                      Expanded(flex: 3, child: _RH('Equipment')),
                      Expanded(flex: 2, child: _RH('Type')),
                      Expanded(flex: 3, child: _RH('Description')),
                      Expanded(flex: 2, child: _RH('Performed By')),
                      Expanded(flex: 2, child: _RH('Date')),
                      Expanded(flex: 2, child: _RH('Cost')),
                      Expanded(flex: 2, child: _RH('Status')),
                    ]),
                  ),
                  ...records.take(15).map((r) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppTheme.border))),
                    child: Row(children: [
                      Expanded(flex: 3, child: Text(r.equipmentName ?? '-',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                      Expanded(flex: 2, child: Text(AppConstants.formatStatus(r.maintenanceType),
                          style: const TextStyle(fontSize: 13))),
                      Expanded(flex: 3, child: Text(r.description ?? '-',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          overflow: TextOverflow.ellipsis)),
                      Expanded(flex: 2, child: Text(r.performedBy ?? '-',
                          style: const TextStyle(fontSize: 13))),
                      Expanded(flex: 2, child: Text(fmt.format(r.maintenanceDate),
                          style: const TextStyle(fontSize: 13))),
                      Expanded(flex: 2, child: Text(currency.format(r.cost),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                      Expanded(flex: 2, child: StatusBadge(status: r.status)),
                    ]),
                  )),
                ]),
              ),
      ]),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatMini(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ])),
        ]),
      ),
    );
  }
}

class _RH extends StatelessWidget {
  final String label;
  const _RH(this.label);
  @override
  Widget build(BuildContext context) =>
      Text(label, style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary));
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime?> onChanged;
  const _DatePickerField(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        onChanged(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today, size: 16)),
        child: Text(DateFormat('MMM d, y').format(value),
            style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

// ── PDF Preview Screen ──────────────────────────────────────────────────────

class _PdfPreviewScreen extends StatefulWidget {
  final String title;
  final Uint8List pdfData;
  const _PdfPreviewScreen({required this.title, required this.pdfData});

  @override
  State<_PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<_PdfPreviewScreen> {
  bool _isPrinting = false;

  Future<void> _printPdf() async {
    setState(() => _isPrinting = true);
    try {
      await Printing.layoutPdf(onLayout: (_) => widget.pdfData);
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Error printing: \$e', type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print',
            onPressed: _isPrinting ? null : _printPdf,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isPrinting
          ? const Center(child: CircularProgressIndicator())
          : PdfPreview(
              build: (_) => widget.pdfData,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              maxPageWidth: 1000,
            ),
    );
  }
}