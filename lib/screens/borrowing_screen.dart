// lib/screens/borrowing_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

bool _isLogbookEquipment(String name) {
  final lower = name.toLowerCase();
  return lower.contains('logbook') ||
      lower.contains('log book') ||
      lower.contains('thesis') ||
      lower.contains('record book') ||
      lower.contains('journal book');
}

class BorrowingScreen extends StatefulWidget {
  const BorrowingScreen({super.key});
  @override
  State<BorrowingScreen> createState() => _BorrowingScreenState();
}

class _BorrowingScreenState extends State<BorrowingScreen> {
  String? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final role = provider.currentUser?.role;
    final isFaculty = role == UserRole.faculty;
    final userId = provider.currentUser?.id;

    var records = isFaculty
        ? provider.borrowingRecords
            .where((r) => r.requestedByUserId == userId)
            .toList()
        : provider.borrowingRecords;

    if (_filterStatus != null) {
      records = records.where((r) => r.status == _filterStatus).toList();
    }

    final filterStatuses = isFaculty
        ? <String?>[null, 'pending', 'borrowed', 'returned', 'overdue']
        : <String?>[null, 'pending', 'borrowed', 'returned', 'overdue', 'lost'];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: isFaculty ? 'My Borrow Requests' : 'Borrowing Records',
            subtitle: isFaculty
                ? 'Submit and track your equipment borrow requests'
                : 'Manage equipment lending and returns',
            action: ElevatedButton.icon(
              onPressed: () => _showBorrowingDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text(isFaculty ? 'Request Borrow' : 'New Record'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isFaculty ? AppTheme.secondary : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (isFaculty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppTheme.secondary.withOpacity(0.25)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded,
                    color: AppTheme.secondary, size: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Submit a borrow request and wait for approval from the '
                    'Department Head or Laboratory Custodian. Pending requests '
                    'will be reviewed and processed by the staff.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondary,
                        height: 1.5),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              const Text('Filter:',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(width: 10),
              ...filterStatuses.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                          s == null ? 'All' : AppConstants.formatStatus(s)),
                      selected: _filterStatus == s,
                      onSelected: (_) =>
                          setState(() => _filterStatus = s),
                      selectedColor: s == 'pending'
                          ? AppTheme.primaryLight.withOpacity(0.2)
                          : AppTheme.primary.withOpacity(0.15),
                      checkmarkColor: AppTheme.primary,
                    ),
                  )),
              const Spacer(),
              Text('${records.length} records',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: records.isEmpty
                ? EmptyState(
                    icon: Icons.swap_horiz_rounded,
                    message: isFaculty
                        ? 'No borrow requests yet.\nTap "Request Borrow" to get started.'
                        : 'No borrowing records found.',
                    buttonLabel: isFaculty ? 'Request Borrow' : null,
                    onButtonPressed: isFaculty
                        ? () => _showBorrowingDialog(context)
                        : null,
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: const BoxDecoration(
                              border: Border(
                                  bottom:
                                      BorderSide(color: AppTheme.border))),
                          child: Row(children: [
                            const Expanded(flex: 2, child: _H('Borrower')),
                            const Expanded(
                                flex: 2, child: _H('Equipment')),
                            const Expanded(
                                flex: 2, child: _H('Department')),
                            const Expanded(child: _H('Qty')),
                            const Expanded(
                                flex: 2, child: _H('Borrow Date')),
                            const Expanded(
                                flex: 2, child: _H('Return Date')),
                            const Expanded(flex: 2, child: _H('Status')),
                            SizedBox(width: isFaculty ? 48 : 80),
                          ]),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: records.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, color: AppTheme.border),
                            itemBuilder: (ctx, i) {
                              final r = records[i];
                              final isPending = r.status == 'pending';
                              return Container(
                                color: isPending
                                    ? AppTheme.primaryLight.withOpacity(0.04)
                                    : null,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(r.borrowerName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13)),
                                        if (r.borrowerType != null)
                                          Text(r.borrowerType!,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      AppTheme.textSecondary)),
                                        if (r.borrowerIdNumber != null)
                                          Text(r.borrowerIdNumber!,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      AppTheme.textSecondary)),
                                        if (r.bookTitle != null)
                                          Text('📖 ${r.bookTitle!}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.primary),
                                              overflow:
                                                  TextOverflow.ellipsis),
                                        if (isPending && !isFaculty)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 4),
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color:
                                                  AppTheme.primaryLight.withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Faculty Request',
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      AppTheme.primaryLight),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                      flex: 2,
                                      child: Text(r.equipmentName ?? '-',
                                          style: const TextStyle(
                                              fontSize: 13))),
                                  Expanded(
                                      flex: 2,
                                      child: Text(r.department ?? '-',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color:
                                                  AppTheme.textSecondary))),
                                  Expanded(
                                      child: Text(
                                          '${r.quantityBorrowed}',
                                          style: const TextStyle(
                                              fontSize: 13))),
                                  Expanded(
                                      flex: 2,
                                      child: Text(
                                          DateFormat('MMM d, y')
                                              .format(r.borrowDate),
                                          style: const TextStyle(
                                              fontSize: 13))),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      r.expectedReturnDate != null
                                          ? DateFormat('MMM d, y').format(
                                              r.expectedReturnDate!)
                                          : '-',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: r.status == 'overdue'
                                              ? AppTheme.error
                                              : AppTheme.textSecondary),
                                    ),
                                  ),
                                  Expanded(
                                      flex: 2,
                                      child: StatusBadge(status: r.status)),
                                  SizedBox(
                                    width: isFaculty ? 48 : 80,
                                    child: Row(children: [
                                      if (isFaculty && isPending)
                                        IconButton(
                                          onPressed: () async {
                                            await context
                                                .read<AppProvider>()
                                                .deleteBorrowingRecord(r.id);
                                          },
                                          icon: const Icon(
                                              Icons.cancel_outlined,
                                              size: 16,
                                              color: AppTheme.error),
                                          tooltip: 'Cancel Request',
                                        ),
                                      if (!isFaculty) ...[
                                        IconButton(
                                          onPressed: () =>
                                              _showBorrowingDialog(context,
                                                  record: r),
                                          icon: const Icon(Icons.edit_rounded,
                                              size: 16,
                                              color: AppTheme.primary),
                                          tooltip: isPending
                                              ? 'Process Request'
                                              : 'Edit',
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            await context
                                                .read<AppProvider>()
                                                .deleteBorrowingRecord(r.id);
                                          },
                                          icon: const Icon(
                                              Icons.delete_rounded,
                                              size: 16,
                                              color: AppTheme.error),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ]),
                                  ),
                                ]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showBorrowingDialog(BuildContext context,
      {BorrowingRecord? record}) {
    final provider = context.read<AppProvider>();
    showDialog(
      context: context,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: provider,
        child: BorrowingFormDialog(record: record),
      ),
    );
  }
}

class _H extends StatelessWidget {
  final String label;
  const _H(this.label);
  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary));
}

// ============================================================
// BORROWING FORM DIALOG
// ============================================================
class BorrowingFormDialog extends StatefulWidget {
  final BorrowingRecord? record;
  final String? preselectedEquipmentId;
  const BorrowingFormDialog({super.key, this.record, this.preselectedEquipmentId});
  @override
  State<BorrowingFormDialog> createState() => _BorrowingFormDialogState();
}

class _BorrowingFormDialogState extends State<BorrowingFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _idCtrl;
  late final TextEditingController _purposeCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _bookTitleCtrl;

  String? _equipmentId;
  String? _borrowerType;
  String? _department;
  String _status = 'pending';
  DateTime _borrowDate = DateTime.now();
  DateTime? _expectedReturn;
  DateTime? _actualReturn;
  bool _isLogbook = false;
  bool _saving = false;
  String? _saveError;
  bool _facultyPrefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_facultyPrefilled) return;
    final provider = context.read<AppProvider>();
    final role = provider.currentUser?.role;
    final isFaculty = role == UserRole.faculty;
    if (isFaculty && widget.record == null) {
      _nameCtrl.text = provider.currentUser?.fullName ?? '';
      _borrowerType  = 'Faculty';
      _department    = provider.currentUser?.department;
      _facultyPrefilled = true;
    }
  }

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _nameCtrl      = TextEditingController(text: r?.borrowerName);
    _idCtrl        = TextEditingController(text: r?.borrowerIdNumber);
    _purposeCtrl   = TextEditingController(text: r?.purpose);
    _qtyCtrl       = TextEditingController(
        text: r?.quantityBorrowed.toString() ?? '1');
    _notesCtrl     = TextEditingController(text: r?.notes);
    _bookTitleCtrl = TextEditingController(text: r?.bookTitle);

    if (r != null) {
      _equipmentId    = r.equipmentId;
      _borrowerType   = r.borrowerType;
      _department     = r.department;
      _status         = r.status;
      _borrowDate     = r.borrowDate;
      _expectedReturn = r.expectedReturnDate;
      _actualReturn   = r.actualReturnDate;
      _isLogbook      = r.bookTitle != null && r.bookTitle!.isNotEmpty;
    }
    // Pre-select equipment when opened from Equipment screen
    if (widget.preselectedEquipmentId != null && _equipmentId == null) {
      _equipmentId = widget.preselectedEquipmentId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _purposeCtrl.dispose();
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    _bookTitleCtrl.dispose();
    super.dispose();
  }

  String _computeStatus(bool isFaculty) {
    if (isFaculty) return 'pending';
    if (_status == 'returned' || _status == 'lost' || _status == 'pending')
      return _status;
    if (_expectedReturn != null) {
      final today = DateTime.now();
      final due = _expectedReturn!;
      if (today.isAfter(
          DateTime(due.year, due.month, due.day + 1))) {
        return 'overdue';
      }
    }
    return _status == 'overdue' ? 'borrowed' : _status;
  }

  Future<void> _save(bool isFaculty, String? currentUserId) async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;
    setState(() { _saving = true; _saveError = null; });

    final provider = context.read<AppProvider>();
    final effectiveStatus = _computeStatus(isFaculty);
    final approvedBy =
        isFaculty ? null : provider.currentUser?.fullName;

    final record = BorrowingRecord(
      id:                 widget.record?.id ?? '',
      equipmentId:        _equipmentId!,
      borrowerName:       _nameCtrl.text.trim(),
      borrowerType:       _borrowerType,
      borrowerIdNumber:   _idCtrl.text.trim().isNotEmpty
          ? _idCtrl.text.trim()
          : null,
      department:         _department,
      purpose:            _purposeCtrl.text.trim().isNotEmpty
          ? _purposeCtrl.text.trim()
          : null,
      bookTitle:          _isLogbook &&
              _bookTitleCtrl.text.trim().isNotEmpty
          ? _bookTitleCtrl.text.trim()
          : null,
      quantityBorrowed:   int.tryParse(_qtyCtrl.text) ?? 1,
      borrowDate:         _borrowDate,
      expectedReturnDate: _expectedReturn,
      actualReturnDate:   isFaculty ? null : _actualReturn,
      status:             effectiveStatus,
      approvedBy:         approvedBy,
      notes:              _notesCtrl.text.trim().isNotEmpty
          ? _notesCtrl.text.trim()
          : null,
      createdAt:          widget.record?.createdAt ?? DateTime.now(),
      requestedByUserId:  widget.record?.requestedByUserId ??
          (isFaculty ? currentUserId : null),
    );

    // Double-check at submit time: ensure the equipment is still available
    final activeBorrow = provider.borrowingRecords.where((r) =>
        r.equipmentId == _equipmentId &&
        (r.status == 'borrowed' || r.status == 'overdue' || r.status == 'pending') &&
        r.id != (widget.record?.id ?? '')).firstOrNull;

    if (activeBorrow != null) {
      setState(() {
        _saving = false;
        _saveError =
            'This equipment is currently ${activeBorrow.status} by ${activeBorrow.borrowerName}. '
            'Please select a different item.';
      });
      return;
    }

    bool success = false;
    try {
      // Bypass the shared _isSaving guard by calling the service directly
      // for faculty requests — the guard can be held by unrelated background ops.
      if (widget.record?.id != null && widget.record!.id.isNotEmpty) {
        await provider.supabaseService.updateBorrowingRecord(
            widget.record!.id, record);
      } else {
        await provider.supabaseService.createBorrowingRecord(record);
      }
      await provider.loadBorrowingRecords();
      success = true;
    } catch (e) {
      if (mounted) {
        setState(() => _saveError = e.toString().replaceAll('Exception: ', ''));
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      Navigator.pop(context);
      AppToast.show(
        context,
        isFaculty
            ? 'Borrow request submitted! Staff will review it shortly.'
            : (widget.record != null ? 'Record updated!' : 'Record saved!'),
        type: isFaculty ? ToastType.info : ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final role = provider.currentUser?.role;
    final isFaculty = role == UserRole.faculty;
    final currentUserId = provider.currentUser?.id;
    final equipmentList = provider.equipment;
    final currentUserName = provider.currentUser?.fullName ?? '';

    // Equipment IDs currently borrowed, overdue, or pending (excluding this record if editing)
    final unavailableEquipmentIds = provider.borrowingRecords
        .where((r) =>
            (r.status == 'borrowed' ||
                r.status == 'overdue' ||
                r.status == 'pending') &&
            r.id != (widget.record?.id ?? ''))
        .map((r) => r.equipmentId)
        .toSet();

    final isProcessingRequest = !isFaculty &&
        widget.record != null &&
        widget.record!.status == 'pending';

    if (_equipmentId != null) {
      final eq =
          equipmentList.where((e) => e.id == _equipmentId).firstOrNull;
      if (eq != null) {
        final shouldBeLogbook = _isLogbookEquipment(eq.name);
        if (shouldBeLogbook != _isLogbook) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isLogbook = shouldBeLogbook);
          });
        }
      }
    }

    // Pre-fill faculty name on new request (done in initState via didChangeDependencies instead)

    final headerColor = isFaculty
        ? AppTheme.secondary
        : isProcessingRequest
            ? AppTheme.primaryLight
            : AppTheme.accent;

    final headerTitle = isFaculty
        ? (widget.record != null
            ? 'Edit Borrow Request'
            : 'Request Equipment Borrow')
        : isProcessingRequest
            ? 'Process Borrow Request'
            : (widget.record != null
                ? 'Edit Borrowing Record'
                : 'New Borrowing Record');

    final headerIcon = isFaculty
        ? Icons.send_rounded
        : isProcessingRequest
            ? Icons.task_alt_rounded
            : Icons.swap_horiz_rounded;

    return Dialog(
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 780),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(children: [
                Icon(headerIcon, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(headerTitle,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      if (isFaculty)
                        const Text(
                          'Your request will be reviewed by staff before processing.',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      if (isProcessingRequest)
                        const Text(
                          'Review the faculty request and set the final status.',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white)),
              ]),
            ),

            // Processing banner
            if (isProcessingRequest)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                color: AppTheme.primaryLight.withOpacity(0.08),
                child: const Row(children: [
                  Icon(Icons.pending_actions_rounded,
                      color: AppTheme.primaryLight, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This is a faculty borrow request. Change the status to '
                      '"Borrowed" to approve, or delete the record to reject.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryLight,
                          height: 1.4),
                    ),
                  ),
                ]),
              ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Equipment
                      DropdownButtonFormField<String>(
                        value: _equipmentId,
                        decoration: const InputDecoration(
                          labelText: 'Equipment *',
                          prefixIcon:
                              Icon(Icons.inventory_2_rounded, size: 18),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null,
                              child: Text('Select Equipment')),
                          ...equipmentList.map((e) {
                            final isUnavailable = unavailableEquipmentIds.contains(e.id);
                            return DropdownMenuItem(
                              value: e.id,
                              enabled: !isUnavailable,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    e.name,
                                    style: TextStyle(
                                      color: isUnavailable
                                          ? AppTheme.textSecondary
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (isUnavailable) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warning.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: AppTheme.warning.withOpacity(0.4)),
                                      ),
                                      child: const Text(
                                        'Borrowed',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                        validator: (v) =>
                            v == null ? 'Please select equipment' : null,
                        onChanged: (v) {
                          setState(() {
                            _equipmentId = v;
                            if (v != null) {
                              final eq = equipmentList
                                  .where((e) => e.id == v)
                                  .firstOrNull;
                              _isLogbook = eq != null &&
                                  _isLogbookEquipment(eq.name);
                              if (!_isLogbook) _bookTitleCtrl.clear();
                            }
                          });
                        },
                      ),

                      // Book title
                      if (_isLogbook) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    AppTheme.primary.withOpacity(0.25)),
                          ),
                          child: const Row(children: [
                            Icon(Icons.book_rounded,
                                color: AppTheme.primary, size: 16),
                            SizedBox(width: 8),
                            Text('Logbook / Thesis Book detected',
                                style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _bookTitleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Book Title *',
                            prefixIcon: Icon(Icons.title_rounded, size: 18),
                            hintText:
                                'Enter the title of the logbook or thesis',
                          ),
                          validator: (v) =>
                              _isLogbook && (v?.trim().isEmpty ?? true)
                                  ? 'Book title is required'
                                  : null,
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Borrower Name + ID
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nameCtrl,
                            readOnly: isFaculty && widget.record == null,
                            decoration: InputDecoration(
                              labelText: 'Borrower Name *',
                              prefixIcon:
                                  const Icon(Icons.person_rounded, size: 18),
                              filled: isFaculty && widget.record == null,
                              fillColor: AppTheme.background,
                              suffixIcon: isFaculty && widget.record == null
                                  ? const Tooltip(
                                      message: 'Auto-filled from your account',
                                      child: Icon(Icons.lock_outline_rounded,
                                          size: 16,
                                          color: AppTheme.textSecondary))
                                  : null,
                            ),
                            validator: (v) =>
                                (v?.trim().isEmpty ?? true) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _idCtrl,
                            decoration: const InputDecoration(
                              labelText: 'ID Number',
                              prefixIcon:
                                  Icon(Icons.badge_rounded, size: 18),
                            ),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 16),

                      // Borrower Type + Department
                      Row(children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: kBorrowerTypes.contains(_borrowerType)
                                ? _borrowerType
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Borrower Type *',
                              prefixIcon:
                                  Icon(Icons.people_alt_rounded, size: 18),
                            ),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('Select Type')),
                              ...kBorrowerTypes.map((t) => DropdownMenuItem(
                                  value: t, child: Text(t))),
                            ],
                            validator: (v) =>
                                v == null ? 'Please select type' : null,
                            onChanged: (v) =>
                                setState(() => _borrowerType = v),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: kDepartments.contains(_department)
                                ? _department
                                : null,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Department *',
                              prefixIcon:
                                  Icon(Icons.school_rounded, size: 18),
                            ),
                            items: [
                              const DropdownMenuItem(
                                  value: null,
                                  child: Text('Select Department')),
                              ...kDepartments.map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d,
                                      overflow: TextOverflow.ellipsis))),
                            ],
                            validator: (v) =>
                                v == null ? 'Please select department' : null,
                            onChanged: (v) =>
                                setState(() => _department = v),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 16),

                      // Quantity + Status
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: _qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              prefixIcon: Icon(
                                  Icons.format_list_numbered, size: 18),
                            ),
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n < 1)
                                return 'Enter a valid quantity';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Faculty: locked to Pending; Staff: dropdown
                        if (isFaculty)
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                prefixIcon:
                                    Icon(Icons.flag_rounded, size: 18),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primaryLight.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: AppTheme.primaryLight
                                          .withOpacity(0.3)),
                                ),
                                child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.pending_actions_rounded,
                                          size: 13,
                                          color: AppTheme.primaryLight),
                                      SizedBox(width: 6),
                                      Text('Pending Review',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primaryLight)),
                                    ]),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _status,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                prefixIcon:
                                    Icon(Icons.flag_rounded, size: 18),
                              ),
                              items: AppConstants.borrowingStatuses
                                  .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                          AppConstants.formatStatus(s))))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _status = v!),
                            ),
                          ),
                      ]),

                      const SizedBox(height: 16),

                      // Dates
                      Row(children: [
                        Expanded(
                          child: _DateField2(
                            label: 'Borrow Date *',
                            value: _borrowDate,
                            onChanged: (d) => setState(
                                () => _borrowDate = d ?? _borrowDate),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _DateField2(
                            label: 'Expected Return',
                            value: _expectedReturn,
                            onChanged: (d) =>
                                setState(() => _expectedReturn = d),
                          ),
                        ),
                      ]),

                      // Overdue warning
                      if (_expectedReturn != null &&
                          DateTime.now().isAfter(DateTime(
                              _expectedReturn!.year,
                              _expectedReturn!.month,
                              _expectedReturn!.day + 1)) &&
                          _status != 'returned' &&
                          _status != 'lost') ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.error.withOpacity(0.3)),
                          ),
                          child: const Row(children: [
                            Icon(Icons.warning_amber_rounded,
                                color: AppTheme.error, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Expected return date has passed — status will be Overdue.',
                              style: TextStyle(
                                  color: AppTheme.error, fontSize: 12),
                            ),
                          ]),
                        ),
                      ],

                      // Actual return (staff only, when returned)
                      if (!isFaculty && _status == 'returned') ...[
                        const SizedBox(height: 16),
                        _DateField2(
                          label: 'Actual Return Date',
                          value: _actualReturn,
                          onChanged: (d) =>
                              setState(() => _actualReturn = d),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Purpose
                      TextFormField(
                        controller: _purposeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Purpose',
                          prefixIcon:
                              Icon(Icons.description_rounded, size: 18),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Processed By (staff only)
                      if (!isFaculty)
                        TextFormField(
                          readOnly: true,
                          initialValue: currentUserName,
                          decoration: InputDecoration(
                            labelText: 'Processed By',
                            prefixIcon: const Icon(
                                Icons.verified_user_rounded, size: 18),
                            filled: true,
                            fillColor: AppTheme.background,
                            suffixIcon: Tooltip(
                              message: 'Auto-filled with your account name',
                              child: Icon(Icons.lock_outline_rounded,
                                  size: 16,
                                  color:
                                      AppTheme.textSecondary.withOpacity(0.5)),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: isFaculty
                              ? 'Notes / Additional Info'
                              : 'Notes',
                          prefixIcon:
                              const Icon(Icons.notes_rounded, size: 18),
                        ),
                      ),

                      // Faculty bottom reminder
                      if (isFaculty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    AppTheme.secondary.withOpacity(0.2)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  color: AppTheme.secondary, size: 15),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your request will be submitted as Pending. '
                                  'The Department Head, Laboratory Custodian, or Student Assistant '
                                  'will review and process your request.',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.secondary,
                                      height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_saveError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _saveError!,
                            style: const TextStyle(color: AppTheme.error, fontSize: 12),
                          ),
                        ),
                      ]),
                    ),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                    TextButton(
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () => _save(isFaculty, currentUserId),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: headerColor),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(isFaculty
                              ? (widget.record != null
                                  ? 'Update Request'
                                  : 'Submit Request')
                              : isProcessingRequest
                                  ? 'Save & Process'
                                  : (widget.record != null
                                      ? 'Update'
                                      : 'Save Record')),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DATE PICKER FIELD
// ============================================================
class _DateField2 extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  const _DateField2(
      {required this.label, this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100));
        onChanged(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today, size: 16)),
        child: Text(
          value != null
              ? DateFormat('MMM d, y').format(value!)
              : 'Select date',
          style: TextStyle(
              color: value != null
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary),
        ),
      ),
    );
  }
}