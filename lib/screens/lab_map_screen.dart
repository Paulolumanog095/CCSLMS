// lib/screens/lab_map_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class LabMapScreen extends StatefulWidget {
  final Laboratory laboratory;
  final String? highlightSeatLabel; // if set, auto-selects this seat on load
  const LabMapScreen({super.key, required this.laboratory, this.highlightSeatLabel});

  @override
  State<LabMapScreen> createState() => _LabMapScreenState();
}

class _LabMapScreenState extends State<LabMapScreen> {
  LabSeat? _selectedSeat;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  Future<void> _loadSeats() async {
    setState(() => _loading = true);
    await context.read<AppProvider>().loadLabSeats(widget.laboratory.id);
    // Auto-highlight the seat from notification tap
    if (widget.highlightSeatLabel != null && mounted) {
      final seats = context.read<AppProvider>().labSeats;
      final match = seats.where(
        (s) => s.seatLabel.toUpperCase() == widget.highlightSeatLabel!.toUpperCase()
      ).toList();
      if (match.isNotEmpty) {
        setState(() => _selectedSeat = match.first);
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final seats = provider.labSeats;

    // Compute grid dimensions
    int maxRow = 1, maxCol = 1;
    for (var s in seats) {
      if ((s.rowNumber ?? 1) > maxRow) maxRow = s.rowNumber ?? 1;
      if ((s.colNumber ?? 1) > maxCol) maxCol = s.colNumber ?? 1;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Top bar
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.map_rounded, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.laboratory.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  Text('Room ${widget.laboratory.roomNumber} • Floor Map • ${seats.length} seats',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
              const Spacer(),
              // Legend
              _Legend(color: AppTheme.success, label: 'Active'),
              const SizedBox(width: 16),
              _Legend(color: AppTheme.warning, label: 'Under Repair'),
              const SizedBox(width: 16),
              _Legend(color: AppTheme.textSecondary, label: 'Inactive'),
              const SizedBox(width: 16),
              _Legend(color: const Color(0xFF0891B2), label: 'Instructor'),
              const SizedBox(width: 24),
              ElevatedButton.icon(
                onPressed: () => _showAddSeatDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Seat'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _loadSeats,
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
                tooltip: 'Refresh',
              ),
            ]),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      // Map area
                      Expanded(
                        flex: 3,
                        child: Container(
                          color: AppTheme.background,
                          child: Column(
                            children: [
                              // Instructor/Board area
                              Container(
                                margin: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0891B2).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF0891B2).withOpacity(0.4), width: 2),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.tv_rounded, color: Color(0xFF0891B2), size: 20),
                                    SizedBox(width: 10),
                                    Text('INSTRUCTOR STATION / BOARD',
                                      style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0891B2), fontSize: 13, letterSpacing: 1)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Grid
                              Expanded(
                                child: seats.isEmpty
                                    ? Center(
                                        child: EmptyState(
                                          icon: Icons.chair_alt_rounded,
                                          message: 'No seats configured for this lab.',
                                          buttonLabel: 'Add Seats',
                                          onButtonPressed: () => _showAddSeatDialog(context),
                                        ),
                                      )
                                    : Scrollbar(
                                        thumbVisibility: true,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: _buildGrid(seats, maxRow, maxCol),
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Seat detail panel
                      if (_selectedSeat != null)
                        Container(
                          width: 340,
                          decoration: const BoxDecoration(
                            color: AppTheme.surface,
                            border: Border(left: BorderSide(color: AppTheme.border)),
                          ),
                          child: _SeatDetailPanel(
                            seat: _selectedSeat!,
                            laboratory: widget.laboratory,
                            onClose: () => setState(() => _selectedSeat = null),
                            onRefresh: _loadSeats,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Dynamic grid: auto-places seats by rowNumber/colNumber ──────────────────
Widget _buildGrid(List<LabSeat> seats, int maxRow, int maxCol) {
    final instructorSeats = seats.where((s) => s.seatType == 'instructor').toList();
    final workSeats = seats.where((s) => s.seatType != 'instructor').toList();

    final placed = <String, LabSeat>{};
    for (var s in workSeats) {
      if (s.rowNumber != null && s.colNumber != null) {
        placed['${s.rowNumber}-${s.colNumber}'] = s;
      }
    }

    final unplaced = workSeats
        .where((s) => s.rowNumber == null || s.colNumber == null)
        .toList();

    const double gap = 10;
    const double cellSize = 100;
    final double gridWidth = (maxCol * cellSize) + ((maxCol - 1) * gap); // ← moved here

    final List<Widget> gridRows = [];
    for (int row = 1; row <= maxRow; row++) {
      final List<Widget> cells = [];
      for (int col = 1; col <= maxCol; col++) {
        if (col > 1) cells.add(SizedBox(width: gap));
        final key = '$row-$col';
        if (placed.containsKey(key)) {
          cells.add(_buildSeatNode(placed[key]!));
        } else {
          cells.add(_buildEmptyCell(row, col));
        }
      }
      if (gridRows.isNotEmpty) gridRows.add(SizedBox(height: gap));
      gridRows.add(Row(children: cells));
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (instructorSeats.isNotEmpty)
                SizedBox(
                  width: gridWidth,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: instructorSeats
                          .map((s) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                child: _buildSeatNode(s),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              if (instructorSeats.isNotEmpty) const SizedBox(height: 24),
              if (instructorSeats.isNotEmpty) const Divider(),
              if (instructorSeats.isNotEmpty) const SizedBox(height: 16),

              ...gridRows,

              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GridButton(
                    icon: Icons.add_rounded,
                    label: 'Add Row',
                    onTap: () => _showAddSeatDialog(context,
                        suggestedRow: maxRow + 1, suggestedCol: 1),
                  ),
                  const SizedBox(width: 10),
                  _GridButton(
                    icon: Icons.add_rounded,
                    label: 'Add Column',
                    onTap: () => _showAddSeatDialog(context,
                        suggestedRow: 1, suggestedCol: maxCol + 1),
                  ),
                ],
              ),

              if (unplaced.isNotEmpty) const SizedBox(height: 24),
              if (unplaced.isNotEmpty) const Divider(),
              if (unplaced.isNotEmpty)
                const Text(
                  'Unplaced Seats',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary),
                ),
              if (unplaced.isNotEmpty) const SizedBox(height: 10),
              if (unplaced.isNotEmpty)
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: unplaced.map((s) => _buildSeatNode(s)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Empty cell in the grid — tappable to add a seat at that position
  Widget _buildEmptyCell(int row, int col) {
    return GestureDetector(
      onTap: () => _showAddSeatDialog(context, suggestedRow: row, suggestedCol: col),
      child: Container(
        width: 90,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded,
                color: AppTheme.textSecondary.withOpacity(0.3), size: 20),
            const SizedBox(height: 2),
            Text('$row-$col',
                style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.textSecondary.withOpacity(0.3))),
          ],
        ),
      ),
    );
  }

Widget _buildSeatNode(LabSeat seat) {
  final isSelected   = _selectedSeat?.id == seat.id;
  final isInstructor = seat.seatType == 'instructor';
  final statusColor  = isInstructor ? const Color(0xFF0891B2) : seat.statusColor;
  final isUnderRepair = seat.statusSummary == 'under_repair'; // ← adjust to match your status string

  return GestureDetector(
    onTap: () => setState(() => _selectedSeat = isSelected ? null : seat),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width:  isInstructor ? 130 : 90,
          height: isInstructor ? 90  : 80,
          decoration: BoxDecoration(
            color: isSelected ? statusColor.withOpacity(0.15) : AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? statusColor : statusColor.withOpacity(0.4),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: statusColor.withOpacity(0.25), blurRadius: 8, spreadRadius: 1)]
                : [const BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isInstructor ? Icons.computer_rounded : Icons.desktop_windows_rounded,
                color: statusColor,
                size: isInstructor ? 28 : 22,
              ),
              const SizedBox(height: 4),
              Text(seat.seatLabel,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? statusColor : AppTheme.textPrimary)),
              const SizedBox(height: 3),
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
            ],
          ),
        ),

        // ← Alert badge for under repair
        if (isUnderRepair)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.warning,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: AppTheme.warning.withOpacity(0.4), blurRadius: 4)],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.build_rounded, size: 9, color: Colors.white),
                  SizedBox(width: 3),
                  Text('Repair', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

  void _showAddSeatDialog(BuildContext context,
      {String? initialLabel, int? suggestedRow, int? suggestedCol}) {
    showDialog(
      context: context,
      builder: (_) => _AddSeatDialog(
        laboratoryId: widget.laboratory.id,
        initialLabel:  initialLabel,
        suggestedRow:  suggestedRow,
        suggestedCol:  suggestedCol,
        onSaved: _loadSeats,
      ),
    );
  }
}

// =================== SEAT DETAIL PANEL ===================
class _SeatDetailPanel extends StatelessWidget {
  final LabSeat seat;
  final Laboratory laboratory;
  final VoidCallback onClose;
  final VoidCallback onRefresh;

  const _SeatDetailPanel({
    required this.seat,
    required this.laboratory,
    required this.onClose,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final provider = context.watch<AppProvider>();

    // Refresh the seat from provider
    final latestSeat = provider.labSeats.firstWhere(
      (s) => s.id == seat.id,
      orElse: () => seat,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panel header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.zero,
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.desktop_windows_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(latestSeat.seatLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(AppConstants.formatStatus(latestSeat.seatType),
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                ],
              ),
            ),
            IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: Colors.white, size: 18)),
          ]),
        ),

        // Status banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: latestSeat.statusColor.withOpacity(0.1),
          child: Row(children: [
            Container(width: 10, height: 10,
              decoration: BoxDecoration(color: latestSeat.statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('Status: ${AppConstants.formatStatus(latestSeat.statusSummary)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: latestSeat.statusColor)),
            const Spacer(),
            Text('${latestSeat.seatEquipment.length} device(s)',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ]),
        ),

        // Equipment list
        Expanded(
          child: latestSeat.seatEquipment.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.devices_rounded, size: 48, color: AppTheme.textSecondary.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      const Text('No equipment assigned', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAssignDialog(context, latestSeat),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Assign Equipment'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...latestSeat.seatEquipment.map((se) {
                      final eq = se.equipment;
                      if (eq == null) return const SizedBox();
                      return _EquipmentCard(
                        seatEquipment: se,
                        currency: currency,
                        laboratoryId: laboratory.id,
                        seatLabel: latestSeat.seatLabel,
                        onRemove: () async {
                          await provider.removeEquipmentFromSeat(se.id, laboratory.id);
                          onRefresh();
                        },
                        onMarkFixed: eq.status == 'under_repair' &&
                                provider.currentUser?.role == UserRole.studentAssistant
                            ? () async {
                                final success = await provider.markEquipmentAsFixed(
                                  equipmentId: eq.id,
                                  equipmentName: eq.name,
                                  seatLabel: latestSeat.seatLabel,
                                  laboratoryId: laboratory.id,
                                );
                                if (success && context.mounted) {
                                  AppToast.show(context, '\${eq.name} marked as fixed! Custodian & Department Head notified.',
                                  );
                                }
                              }
                            : null,
                      );
                    }),
                  ],
                ),
        ),

        // Actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAssignDialog(context, latestSeat),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Device'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primary),
                      foregroundColor: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    ConfirmDialog.show(
                      context,
                      title: 'Remove Seat',
                      content: 'Delete seat "${latestSeat.seatLabel}"? All equipment assignments will also be removed.',
                      onConfirm: () async {
                        await provider.deleteLabSeat(latestSeat.id, laboratory.id);
                        onClose();
                        onRefresh();
                      },
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.error),
                    foregroundColor: AppTheme.error,
                  ),
                  child: const Icon(Icons.delete_rounded, size: 16),
                ),
              ]),
              // Mark as Need Repair — lab custodian only, only when there's equipment
              if (provider.currentUser?.role == UserRole.laboratoryCustodian &&
                  latestSeat.seatEquipment.isNotEmpty) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _showMarkRepairDialog(context, latestSeat),
                  icon: const Icon(Icons.build_rounded, size: 15),
                  label: const Text('Mark as Need Repair'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.warning),
                    foregroundColor: AppTheme.warning,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showAssignDialog(BuildContext context, LabSeat seat) {
    showDialog(
      context: context,
      builder: (_) => _AssignEquipmentDialog(seat: seat, laboratory: laboratory),
    );
  }

  void _showMarkRepairDialog(BuildContext context, LabSeat seat) {
    showDialog(
      context: context,
      builder: (_) => _MarkRepairDialog(seat: seat, laboratory: laboratory),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final SeatEquipment seatEquipment;
  final NumberFormat currency;
  final String laboratoryId;
  final String seatLabel;
  final VoidCallback onRemove;
  final VoidCallback? onMarkFixed;

  const _EquipmentCard({
    required this.seatEquipment,
    required this.currency,
    required this.laboratoryId,
    required this.seatLabel,
    required this.onRemove,
    this.onMarkFixed,
  });

  @override
  Widget build(BuildContext context) {
    final eq = seatEquipment.equipment!;
    final provider = context.watch<AppProvider>();
    final isUnderRepair = eq.status == 'under_repair';
    final isStudentAssistant = provider.currentUser?.role == UserRole.studentAssistant;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnderRepair ? AppTheme.warning.withOpacity(0.04) : AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUnderRepair
              ? AppTheme.warning.withOpacity(0.5)
              : seatEquipment.isPrimary
                  ? AppTheme.primary.withOpacity(0.4)
                  : AppTheme.border,
          width: isUnderRepair || seatEquipment.isPrimary ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: eq.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(_categoryIcon(eq.categoryName), color: eq.statusColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(eq.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                    ),
                    if (isUnderRepair)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.build_rounded, size: 9, color: AppTheme.warning),
                          SizedBox(width: 3),
                          Text('Under Repair', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.warning)),
                        ]),
                      )
                    else if (seatEquipment.isPrimary)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: const Text('PRIMARY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                      ),
                  ]),
                  Text(eq.categoryName ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline_rounded, size: 16, color: AppTheme.error),
              tooltip: 'Remove',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 10),
          _DetailRow('Brand', eq.brand ?? '-'),
          _DetailRow('Model', eq.model ?? '-'),
          _DetailRow('Serial No.', eq.serialNumber ?? '-'),
          _DetailRow('Status', AppConstants.formatStatus(eq.status)),
          _DetailRow('Condition', AppConstants.formatStatus(eq.condition)),
          _DetailRow('Unit Cost', currency.format(eq.unitCost)),
          if (eq.warrantyExpiry != null)
            _DetailRow('Warranty', DateFormat('MMM d, y').format(eq.warrantyExpiry!)),
          if (eq.specifications != null && eq.specifications!.isNotEmpty)
            _DetailRow('Specs', eq.specifications!),

          // Repair note — shown when under repair
          if (isUnderRepair && eq.notes != null && eq.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_rounded, size: 14, color: AppTheme.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Repair Note', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.warning)),
                        const SizedBox(height: 2),
                        Text(eq.notes!, style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Mark as Fixed — student assistant only, under repair only
          if (isUnderRepair && isStudentAssistant && onMarkFixed != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isLoading ? null : onMarkFixed,
                icon: provider.isLoading
                    ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_rounded, size: 15),
                label: Text(provider.isLoading ? 'Updating...' : 'Mark as Fixed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _categoryIcon(String? category) {
    if (category == null) return Icons.device_unknown_rounded;
    final c = category.toLowerCase();
    if (c.contains('monitor')) return Icons.monitor_rounded;
    if (c.contains('computer') || c.contains('laptop')) return Icons.computer_rounded;
    if (c.contains('printer') || c.contains('scanner')) return Icons.print_rounded;
    if (c.contains('network')) return Icons.router_rounded;
    if (c.contains('storage')) return Icons.storage_rounded;
    if (c.contains('audio') || c.contains('visual')) return Icons.videocam_rounded;
    if (c.contains('power')) return Icons.power_rounded;
    return Icons.devices_rounded;
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ),
          const Text(': ', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

// =================== GRID BUTTON HELPER ===================
class _GridButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GridButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
        ]),
      ),
    );
  }
}

// =================== ADD SEAT DIALOG ===================
class _AddSeatDialog extends StatefulWidget {
  final String laboratoryId;
  final String? initialLabel;
  final int?    suggestedRow;
  final int?    suggestedCol;
  final VoidCallback? onSaved;

  const _AddSeatDialog({
    required this.laboratoryId,
    this.initialLabel,
    this.suggestedRow,
    this.suggestedCol,
    this.onSaved,
  });

  @override
  State<_AddSeatDialog> createState() => _AddSeatDialogState();
}

class _AddSeatDialogState extends State<_AddSeatDialog> {
  final _formKey  = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _seatType = 'workstation';
  bool   _saving   = false;
  late int _row;
  late int _col;

  @override
  void initState() {
    super.initState();
    _labelCtrl.text = widget.initialLabel ?? '';
    _row = widget.suggestedRow ?? 1;
    _col = widget.suggestedCol ?? 1;
    if (widget.initialLabel?.toUpperCase().contains('INSTR') ?? false) {
      _seatType = 'instructor';
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.desktop_windows_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text('Add Seat',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            ),

            // ── Form ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seat label
                    TextFormField(
                      controller: _labelCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Seat Label *',
                        hintText: 'e.g. PC-01',
                        prefixIcon: Icon(Icons.label_outline_rounded, size: 18),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Seat label is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Seat type
                    DropdownButtonFormField<String>(
                      value: _seatType,
                      decoration: const InputDecoration(
                        labelText: 'Seat Type',
                        prefixIcon: Icon(Icons.category_outlined, size: 18),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'workstation', child: Text('Workstation')),
                        DropdownMenuItem(value: 'instructor',  child: Text('Instructor')),
                        DropdownMenuItem(value: 'server',      child: Text('Server')),
                        DropdownMenuItem(value: 'storage',     child: Text('Storage')),
                        DropdownMenuItem(value: 'empty',       child: Text('Empty')),
                      ],
                      onChanged: (v) => setState(() => _seatType = v!),
                    ),
                    const SizedBox(height: 20),

                    // ── Grid position picker ──────────────────────
                    const Text('Position on Map',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary)),
                    const SizedBox(height: 10),
                    Row(children: [
                      // Row picker
                      Expanded(child: _SpinnerField(
                        label: 'Row',
                        value: _row,
                        min: 1,
                        max: 20,
                        onChanged: (v) => setState(() => _row = v),
                      )),
                      const SizedBox(width: 16),
                      // Column picker
                      Expanded(child: _SpinnerField(
                        label: 'Column',
                        value: _col,
                        min: 1,
                        max: 20,
                        onChanged: (v) => setState(() => _col = v),
                      )),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.info_outline_rounded, size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 5),
                      Text('Will be placed at Row $_row, Column $_col on the floor map',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ]),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        prefixIcon: Icon(Icons.notes_rounded, size: 18),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Actions ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_rounded, size: 16),
                    label: Text(_saving ? 'Saving...' : 'Add Seat'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final seat = LabSeat(
      id: '',
      laboratoryId: widget.laboratoryId,
      seatLabel: _labelCtrl.text.trim().toUpperCase(),
      rowNumber: _row,
      colNumber: _col,
      seatType: _seatType,
      isActive: true,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      createdAt: DateTime.now(),
    );

    final provider = context.read<AppProvider>();
    final success  = await provider.saveLabSeat(seat);
    if (mounted) {
      if (success) {
        widget.onSaved?.call();
        Navigator.pop(context);
      } else {
        setState(() => _saving = false);
        AppToast.show(context, 'Failed to save seat. Please try again.', type: ToastType.error,
        );
      }
    }
  }
}

// =================== MARK AS NEED REPAIR DIALOG ===================
class _MarkRepairDialog extends StatefulWidget {
  final LabSeat seat;
  final Laboratory laboratory;
  const _MarkRepairDialog({required this.seat, required this.laboratory});
  @override
  State<_MarkRepairDialog> createState() => _MarkRepairDialogState();
}

class _MarkRepairDialogState extends State<_MarkRepairDialog> {
  String? _selectedEquipmentId;
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() { _noteCtrl.dispose(); super.dispose(); }

  List<SeatEquipment> get _activeEquipment =>
      widget.seat.seatEquipment.where((se) => se.equipment?.status != 'under_repair').toList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppTheme.warning,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.build_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mark as Need Repair', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('Seat ${widget.seat.seatLabel}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ]),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_activeEquipment.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.info_outline_rounded, color: AppTheme.warning, size: 16),
                        SizedBox(width: 8),
                        Expanded(child: Text('All equipment is already marked as under repair.', style: TextStyle(fontSize: 12, color: AppTheme.warning))),
                      ]),
                    )
                  else ...[
                    const Text('Select Equipment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedEquipmentId,
                      decoration: const InputDecoration(hintText: 'Choose equipment to flag...'),
                      items: _activeEquipment.map((se) {
                        final eq = se.equipment!;
                        return DropdownMenuItem(
                          value: eq.id,
                          child: Text('${eq.name} (${eq.brand ?? eq.model ?? 'No brand'})', style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedEquipmentId = v),
                    ),
                    const SizedBox(height: 16),
                    const Text('Repair Note', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noteCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Describe what needs to be repaired...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.info_outline_rounded, size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 5),
                      const Expanded(
                        child: Text('Student assistants will be notified to fix this equipment.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ),
                    ]),
                  ],
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_saving || _selectedEquipmentId == null || _activeEquipment.isEmpty)
                        ? null
                        : _submit,
                    icon: _saving
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.build_rounded, size: 16),
                    label: Text(_saving ? 'Saving...' : 'Mark Repair'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning, foregroundColor: Colors.white),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedEquipmentId == null) return;
    setState(() => _saving = true);

    final se = widget.seat.seatEquipment.firstWhere((s) => s.equipment?.id == _selectedEquipmentId);
    final eq = se.equipment!;
    final provider = context.read<AppProvider>();
    final note = _noteCtrl.text.trim();

    final success = await provider.markEquipmentAsNeedRepair(
      equipmentId: eq.id,
      equipmentName: eq.name,
      seatLabel: widget.seat.seatLabel,
      laboratoryId: widget.laboratory.id,
      repairNote: note.isNotEmpty ? note : null,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        AppToast.show(context, '\${eq.name} flagged for repair. Student assistants notified.', type: ToastType.warning,
        );
      } else {
        setState(() => _saving = false);
      }
    }
  }
}

// =================== ASSIGN EQUIPMENT DIALOG ===================
class _AssignEquipmentDialog extends StatefulWidget {
  final LabSeat seat;
  final Laboratory laboratory;
  const _AssignEquipmentDialog({required this.seat, required this.laboratory});
  @override
  State<_AssignEquipmentDialog> createState() => _AssignEquipmentDialogState();
}

class _AssignEquipmentDialogState extends State<_AssignEquipmentDialog> {
  String? _equipmentId;
  bool _isPrimary = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // Filter out already-assigned AND currently-borrowed equipment
    final allAssignedIds = provider.labSeats
        .expand((seat) => seat.seatEquipment)
        .map((se) => se.equipmentId)
        .toSet();

    // Equipment is considered borrowed if it has an active borrowing record
    final borrowedIds = provider.borrowingRecords
        .where((r) => r.status == 'borrowed' || r.status == 'overdue')
        .map((r) => r.equipmentId)
        .toSet();

    final available = provider.equipment
        .where((e) => !allAssignedIds.contains(e.id) && !borrowedIds.contains(e.id))
        .toList();

    return Dialog(
      child: Container(
        width: 420,
        constraints: const BoxConstraints(maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(children: [
                Text(
                  'Assign Equipment to ${widget.seat.seatLabel}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ]),
            ),
            // ── Scrollable body ──────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _equipmentId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Equipment *',
                        // No helperText — it reserves space and causes overflow
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Choose equipment...')),
                        // Single-line items to avoid height inflation on the closed dropdown
                        ...available.map((e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(
                            '${e.name}${e.serialNumber != null ? ' • SN: ${e.serialNumber}' : ''}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        )),
                      ],
                      onChanged: (v) => setState(() => _equipmentId = v),
                    ),
                    // Small note below the dropdown instead of helperText
                    const SizedBox(height: 4),
                    const Text(
                      'Borrowed or already-assigned equipment is excluded.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Switch.adaptive(
                        value: _isPrimary,
                        activeColor: AppTheme.primary,
                        onChanged: (v) => setState(() => _isPrimary = v),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mark as Primary Device',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('e.g. the main CPU/desktop unit',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ]),
                    if (available.isEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                        ),
                        child: const Row(children: [
                          Icon(Icons.info_outlined, color: AppTheme.warning, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'All equipment is assigned to other seats or currently borrowed.',
                              style: TextStyle(fontSize: 12, color: AppTheme.warning),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // ── Actions ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _equipmentId == null ? null : _assign,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                  child: const Text('Assign'),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assign() async {
    if (_equipmentId == null) return;
    final se = SeatEquipment(
      id: '',
      seatId: widget.seat.id,
      equipmentId: _equipmentId!,
      isPrimary: _isPrimary,
      installedDate: DateTime.now(),
      createdAt: DateTime.now(),
    );
    final provider = context.read<AppProvider>();
    final success = await provider.assignEquipmentToSeat(se, widget.laboratory.id);
    if (success && mounted) Navigator.pop(context);
  }
}
// =================== SPINNER FIELD ===================
class _SpinnerField extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _SpinnerField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            // Decrement
            InkWell(
              onTap: value > min ? () => onChanged(value - 1) : null,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Icon(Icons.remove_rounded,
                    size: 16,
                    color: value > min ? AppTheme.textPrimary : AppTheme.textSecondary.withOpacity(0.3)),
              ),
            ),
            // Value
            Expanded(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            // Increment
            InkWell(
              onTap: value < max ? () => onChanged(value + 1) : null,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Icon(Icons.add_rounded,
                    size: 16,
                    color: value < max ? AppTheme.textPrimary : AppTheme.textSecondary.withOpacity(0.3)),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}