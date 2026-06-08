// lib/screens/equipment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'borrowing_screen.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});
  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final equipment = provider.equipment;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Equipment', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  Text('Manage all laboratory equipment and assets', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
              const Spacer(),
              if (provider.currentUser?.role != UserRole.studentAssistant)
                ElevatedButton.icon(
                  onPressed: () => _showEquipmentDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Equipment'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Filters
Column(
  children: [
    TextField(
      controller: _searchCtrl,
      decoration: const InputDecoration(
        hintText: 'Search equipment, serial number, brand...',
        prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
      ),
      onChanged: provider.setSearchQuery,
    ),
    const SizedBox(height: 10),
    Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: null,
            isExpanded: true, // 👈 prevents overflow
            hint: const Text('All Labs'),
            decoration: const InputDecoration(),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Labs')),
              ...provider.laboratories.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))),
            ],
            onChanged: provider.setFilterLab,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: null,
            isExpanded: true, // 👈 prevents overflow
            hint: const Text('All Categories'),
            decoration: const InputDecoration(),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Categories')),
              ...provider.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
            ],
            onChanged: provider.setFilterCategory,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: null,
            isExpanded: true, // 👈 prevents overflow
            hint: const Text('All Status'),
            decoration: const InputDecoration(),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Status')),
              ...AppConstants.equipmentStatuses.map((s) => DropdownMenuItem(value: s, child: Text(AppConstants.formatStatus(s)))),
            ],
            onChanged: provider.setFilterStatus,
          ),
        ),
      ],
    ),
  ],
),
          const SizedBox(height: 16),
          // Stats bar
          Row(
            children: [
              Text('${equipment.length} items found', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          // Table
          Expanded(
            child: equipment.isEmpty
                ? const EmptyState(icon: Icons.inventory_2_rounded, message: 'No equipment found. Add your first equipment.')
                : _buildTable(context, provider, equipment),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, AppProvider provider, List<Equipment> equipment) {
    final role = provider.currentUser?.role;
    final isFaculty = role == UserRole.faculty;
    final isStudent = role == UserRole.studentAssistant;
    final canEdit = !isFaculty && !isStudent;
    final canDelete = provider.currentUser?.canDeleteRecords == true;

    // Build borrowed equipment id set
    final borrowedIds = provider.borrowingRecords
        .where((r) => r.status == 'borrowed' || r.status == 'overdue' || r.status == 'pending')
        .map((r) => r.equipmentId)
        .toSet();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                const Expanded(flex: 3, child: _HeaderCell('Equipment')),
                const Expanded(flex: 2, child: _HeaderCell('Serial No.')),
                const Expanded(flex: 2, child: _HeaderCell('Category')),
                const Expanded(flex: 2, child: _HeaderCell('Laboratory')),
                const Expanded(child: _HeaderCell('Qty')),
                const Expanded(flex: 2, child: _HeaderCell('Status')),
                const Expanded(flex: 2, child: _HeaderCell('Condition')),
                if (isStudent)
                  const Expanded(flex: 2, child: _HeaderCell('Availability'))
                else if (isFaculty)
                  const SizedBox(width: 140)
                else
                  const SizedBox(width: 80),
              ],
            ),
          ),
          // Table rows
          Expanded(
            child: ListView.separated(
              itemCount: equipment.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
              itemBuilder: (ctx, i) {
                final eq = equipment[i];
                final isBorrowed = borrowedIds.contains(eq.id);
                return _EquipmentRow(
                  equipment: eq,
                  isBorrowed: isBorrowed,
                  isFaculty: isFaculty,
                  isStudent: isStudent,
                  onEdit: canEdit ? () => _showEquipmentDialog(context, equipment: eq) : null,
                  onDelete: canDelete ? () => _confirmDelete(context, eq) : null,
                  onRequestBorrow: isFaculty
                      ? () {
                          final prov = context.read<AppProvider>();
                          showDialog(
                            context: context,
                            builder: (ctx) => ChangeNotifierProvider.value(
                              value: prov,
                              child: BorrowingFormDialog(preselectedEquipmentId: eq.id),
                            ),
                          );
                        }
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Equipment eq) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Equipment'),
        content: Text('Are you sure you want to delete "${eq.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<AppProvider>();
              await provider.deleteEquipment(eq.id);
              if (context.mounted) {
                AppToast.show(context, 'Equipment deleted successfully');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEquipmentDialog(BuildContext context, {Equipment? equipment}) {
    showDialog(
      context: context,
      builder: (ctx) => EquipmentFormDialog(equipment: equipment),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);
  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary));
  }
}

class _EquipmentRow extends StatelessWidget {
  final Equipment equipment;
  final bool isBorrowed;
  final bool isFaculty;
  final bool isStudent;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRequestBorrow;

  const _EquipmentRow({
    required this.equipment,
    required this.isBorrowed,
    required this.isFaculty,
    required this.isStudent,
    this.onEdit,
    this.onDelete,
    this.onRequestBorrow,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(equipment.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              if (equipment.brand != null || equipment.model != null)
                Text('${equipment.brand ?? ''} ${equipment.model ?? ''}'.trim(),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          )),
          Expanded(flex: 2, child: Text(equipment.serialNumber ?? '-', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
          Expanded(flex: 2, child: Text(equipment.categoryName ?? '-', style: const TextStyle(fontSize: 13))),
          Expanded(flex: 2, child: Text(equipment.laboratoryName ?? '-', style: const TextStyle(fontSize: 13))),
          Expanded(child: Text('${equipment.quantity}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: StatusBadge(status: equipment.status)),
          Expanded(flex: 2, child: StatusBadge(status: equipment.condition)),

          // ── Student Assistant: show Availability badge ──
          if (isStudent)
            Expanded(
              flex: 2,
              child: _AvailabilityBadge(isBorrowed: isBorrowed),
            )

          // ── Faculty: Request Borrow button (disabled if borrowed) ──
          else if (isFaculty)
            SizedBox(
              width: 140,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Tooltip(
                  message: isBorrowed ? 'Currently borrowed — unavailable' : 'Request to borrow this equipment',
                  child: ElevatedButton.icon(
                    onPressed: isBorrowed ? null : onRequestBorrow,
                    icon: Icon(
                      isBorrowed ? Icons.block_rounded : Icons.send_rounded,
                      size: 13,
                    ),
                    label: Text(
                      isBorrowed ? 'Unavailable' : 'Request Borrow',
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBorrowed ? AppTheme.textSecondary : AppTheme.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                  ),
                ),
              ),
            )

          // ── Staff / Dept Head: Edit + Delete buttons ──
          else
            SizedBox(
              width: 80,
              child: Row(
                children: [
                  if (onEdit != null)
                    IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, size: 16, color: AppTheme.primary)),
                  if (onDelete != null)
                    IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_rounded, size: 16, color: AppTheme.error)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool isBorrowed;
  const _AvailabilityBadge({required this.isBorrowed});

  @override
  Widget build(BuildContext context) {
    final color = isBorrowed ? AppTheme.warning : AppTheme.success;
    final label = isBorrowed ? 'Borrowed' : 'Available';
    final icon  = isBorrowed ? Icons.swap_horiz_rounded : Icons.check_circle_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class EquipmentFormDialog extends StatefulWidget {
  final Equipment? equipment;
  const EquipmentFormDialog({super.key, this.equipment});
  @override
  State<EquipmentFormDialog> createState() => _EquipmentFormDialogState();
}

class _EquipmentFormDialogState extends State<EquipmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.equipment?.name);
  late final _serialCtrl = TextEditingController(text: widget.equipment?.serialNumber);
  late final _brandCtrl = TextEditingController(text: widget.equipment?.brand);
  late final _modelCtrl = TextEditingController(text: widget.equipment?.model);
  late final _qtyCtrl = TextEditingController(text: widget.equipment?.quantity.toString() ?? '1');
  late final _costCtrl = TextEditingController(text: widget.equipment?.unitCost.toString() ?? '0');
  late final _specsCtrl = TextEditingController(text: widget.equipment?.specifications);
  late final _notesCtrl = TextEditingController(text: widget.equipment?.notes);
  String? _categoryId;
  String? _laboratoryId;
  String _status = 'active';
  String _condition = 'good';
  DateTime? _dateAcquired;
  DateTime? _warrantyExpiry;

  @override
  void initState() {
    super.initState();
    if (widget.equipment != null) {
      _categoryId = widget.equipment!.categoryId;
      _laboratoryId = widget.equipment!.laboratoryId;
      _status = widget.equipment!.status;
      _condition = widget.equipment!.condition;
      _dateAcquired = widget.equipment!.dateAcquired;
      _warrantyExpiry = widget.equipment!.warrantyExpiry;
    }
  }

  @override
  void dispose() {
    for (var c in [_nameCtrl, _serialCtrl, _brandCtrl, _modelCtrl, _qtyCtrl, _costCtrl, _specsCtrl, _notesCtrl]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Dialog(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Text(widget.equipment != null ? 'Edit Equipment' : 'Add New Equipment',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(child: _field('Equipment Name *', _nameCtrl, required: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _field('Serial Number', _serialCtrl)),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _field('Brand', _brandCtrl)),
                        const SizedBox(width: 16),
                        Expanded(child: _field('Model', _modelCtrl)),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: DropdownButtonFormField<String>(
                          value: _categoryId,
                          decoration: const InputDecoration(labelText: 'Category'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Select Category')),
                            ...provider.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (v) => setState(() => _categoryId = v),
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: DropdownButtonFormField<String>(
                          value: _laboratoryId,
                          decoration: const InputDecoration(labelText: 'Laboratory'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Select Laboratory')),
                            ...provider.laboratories.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))),
                          ],
                          onChanged: (v) => setState(() => _laboratoryId = v),
                        )),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _field('Quantity *', _qtyCtrl, keyboardType: TextInputType.number, required: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _field('Unit Cost', _costCtrl, keyboardType: TextInputType.number)),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: DropdownButtonFormField<String>(
                          value: _status,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: AppConstants.equipmentStatuses.map((s) => DropdownMenuItem(
                            value: s, child: Text(AppConstants.formatStatus(s)))).toList(),
                          onChanged: context.read<AppProvider>().currentUser?.role == UserRole.laboratoryCustodian
                              ? null  // disabled for lab custodian
                              : (v) => setState(() => _status = v!),
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: DropdownButtonFormField<String>(
                          value: _condition,
                          decoration: const InputDecoration(labelText: 'Condition'),
                          items: AppConstants.equipmentConditions.map((s) => DropdownMenuItem(
                            value: s, child: Text(AppConstants.formatStatus(s)))).toList(),
                          onChanged: (v) => setState(() => _condition = v!),
                        )),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _DateField(
                          label: 'Date Acquired',
                          value: _dateAcquired,
                          onChanged: (d) => setState(() => _dateAcquired = d),
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _DateField(
                          label: 'Warranty Expiry',
                          value: _warrantyExpiry,
                          onChanged: (d) => setState(() => _warrantyExpiry = d),
                        )),
                      ]),
                      const SizedBox(height: 16),
                      TextFormField(controller: _specsCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Specifications')),
                      const SizedBox(height: 16),
                      TextFormField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    child: Text(widget.equipment != null ? 'Update' : 'Add Equipment'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {bool required = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: required ? (v) => (v == null || v.isEmpty) ? '$label is required' : null : null,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final eq = Equipment(
      id: widget.equipment?.id ?? '',
      name: _nameCtrl.text,
      categoryId: _categoryId,
      laboratoryId: _laboratoryId,
      serialNumber: _serialCtrl.text.isNotEmpty ? _serialCtrl.text : null,
      brand: _brandCtrl.text.isNotEmpty ? _brandCtrl.text : null,
      model: _modelCtrl.text.isNotEmpty ? _modelCtrl.text : null,
      quantity: int.tryParse(_qtyCtrl.text) ?? 1,
      unitCost: double.tryParse(_costCtrl.text) ?? 0,
      status: _status,
      condition: _condition,
      dateAcquired: _dateAcquired,
      warrantyExpiry: _warrantyExpiry,
      specifications: _specsCtrl.text.isNotEmpty ? _specsCtrl.text : null,
      notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final provider = context.read<AppProvider>();
    final success = await provider.saveEquipment(eq, id: widget.equipment?.id);
    if (success && mounted) {
      Navigator.pop(context);
      AppToast.show(context, widget.equipment != null ? 'Equipment updated!' : 'Equipment added!');
    }
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const _DateField({required this.label, this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        onChanged(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today, size: 16),
        ),
        child: Text(
          value != null ? DateFormat('MMM d, y').format(value!) : 'Select date',
          style: TextStyle(color: value != null ? AppTheme.textPrimary : AppTheme.textSecondary),
        ),
      ),
    );
  }
}