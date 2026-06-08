// lib/screens/other_screens.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'lab_map_screen.dart';

// =================== LABORATORIES SCREEN ===================
class LaboratoriesScreen extends StatelessWidget {
  const LaboratoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final labs = provider.laboratories;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Laboratories',
            subtitle: 'Manage computer laboratory rooms and floor maps',
            action: ElevatedButton.icon(
              onPressed: () => _showDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Laboratory'),
            ),
          ),
          const SizedBox(height: 24),
          labs.isEmpty
              ? const Expanded(child: EmptyState(icon: Icons.meeting_room_rounded, message: 'No laboratories found.'))
              : Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: labs.length,
                    itemBuilder: (ctx, i) {
                      final lab = labs[i];
                      final eqCount = provider.equipment.where((e) => e.laboratoryId == lab.id).length;
                      return _LabCard(lab: lab, eqCount: eqCount);
                    },
                  ),
                ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, {Laboratory? lab}) {
    showDialog(context: context, builder: (ctx) => _LabDialog(lab: lab));
  }
}

class _LabCard extends StatefulWidget {
  final Laboratory lab;
  final int eqCount;
  const _LabCard({required this.lab, required this.eqCount});

  @override
  State<_LabCard> createState() => _LabCardState();
}

class _LabCardState extends State<_LabCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered ? AppTheme.primaryLight : AppTheme.border,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: _hovered
              ? [BoxShadow(color: AppTheme.primary.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.meeting_room_rounded, color: AppTheme.primary, size: 22),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => showDialog(context: context, builder: (_) => _LabDialog(lab: widget.lab)),
                icon: const Icon(Icons.edit_rounded, size: 16, color: AppTheme.primary),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: () async { await provider.deleteLaboratory(widget.lab.id); },
                icon: const Icon(Icons.delete_rounded, size: 16, color: AppTheme.error),
                tooltip: 'Delete',
              ),
            ]),
            const SizedBox(height: 10),
            Text(widget.lab.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            Text('Room ${widget.lab.roomNumber}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            if (widget.lab.building != null)
              Text(widget.lab.building!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const Spacer(),
            Row(children: [
              _Stat('Capacity', '${widget.lab.capacity}'),
              const SizedBox(width: 16),
              _Stat('Equipment', '${widget.eqCount}'),
              const Spacer(),
              // View Map button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: provider,
                        child: LabMapScreen(laboratory: widget.lab),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map_rounded, size: 14),
                label: const Text('Floor Map', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
    ]);
  }
}

class _LabDialog extends StatefulWidget {
  final Laboratory? lab;
  const _LabDialog({this.lab});
  @override
  State<_LabDialog> createState() => _LabDialogState();
}

class _LabDialogState extends State<_LabDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.lab?.name);
  late final _roomCtrl = TextEditingController(text: widget.lab?.roomNumber);
  late final _buildingCtrl = TextEditingController(text: widget.lab?.building);
  late final _capacityCtrl = TextEditingController(text: widget.lab?.capacity.toString() ?? '0');
  late final _descCtrl = TextEditingController(text: widget.lab?.description);

  @override
  void dispose() {
    for (var c in [_nameCtrl, _roomCtrl, _buildingCtrl, _capacityCtrl, _descCtrl]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: AppTheme.secondary, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
              child: Row(children: [
                Text(widget.lab != null ? 'Edit Laboratory' : 'Add Laboratory',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  Row(children: [
                    Expanded(child: TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Lab Name *'), validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null)),
                    const SizedBox(width: 16),
                    Expanded(child: TextFormField(controller: _roomCtrl, decoration: const InputDecoration(labelText: 'Room Number *'), validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null)),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: TextFormField(controller: _buildingCtrl, decoration: const InputDecoration(labelText: 'Building'))),
                    const SizedBox(width: 16),
                    Expanded(child: TextFormField(controller: _capacityCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacity'))),
                  ]),
                  const SizedBox(height: 16),
                  TextFormField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                  child: Text(widget.lab != null ? 'Update' : 'Add Lab'),
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
    final lab = Laboratory(
      id: widget.lab?.id ?? '',
      name: _nameCtrl.text,
      roomNumber: _roomCtrl.text,
      building: _buildingCtrl.text.isNotEmpty ? _buildingCtrl.text : null,
      capacity: int.tryParse(_capacityCtrl.text) ?? 0,
      description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final provider = context.read<AppProvider>();
    final success = await provider.saveLaboratory(lab, id: widget.lab?.id);
    if (success && mounted) {
      Navigator.pop(context);
      AppToast.show(context, 'Laboratory saved!');
    }
  }
}

// =================== CATEGORIES SCREEN ===================
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cats = provider.categories;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Categories',
            subtitle: 'Equipment classification categories',
            action: ElevatedButton.icon(
              onPressed: () => _showDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Category'),
            ),
          ),
          const SizedBox(height: 24),
          cats.isEmpty
              ? const Expanded(child: EmptyState(icon: Icons.category_rounded, message: 'No categories found.'))
              : Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2,
                    ),
                    itemCount: cats.length,
                    itemBuilder: (ctx, i) {
                      final cat = cats[i];
                      final eqCount = provider.equipment.where((e) => e.categoryId == cat.id).length;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.category_rounded, color: AppTheme.accent, size: 18),
                              ),
                              const Spacer(),
                              IconButton(onPressed: () => _showDialog(context, cat: cat), icon: const Icon(Icons.edit_rounded, size: 14, color: AppTheme.primary)),
                              IconButton(onPressed: () async { await provider.deleteCategory(cat.id); }, icon: const Icon(Icons.delete_rounded, size: 14, color: AppTheme.error)),
                            ]),
                            const Spacer(),
                            Text(cat.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            Text('$eqCount items', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, {Category? cat}) {
    showDialog(context: context, builder: (ctx) => _CatDialog(cat: cat));
  }
}

class _CatDialog extends StatefulWidget {
  final Category? cat;
  const _CatDialog({this.cat});
  @override
  State<_CatDialog> createState() => _CatDialogState();
}

class _CatDialogState extends State<_CatDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.cat?.name);
  late final _descCtrl = TextEditingController(text: widget.cat?.description);

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
              child: Row(children: [
                Text(widget.cat != null ? 'Edit Category' : 'Add Category',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Category Name *'), validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                  child: Text(widget.cat != null ? 'Update' : 'Add'),
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
    final cat = Category(id: widget.cat?.id ?? '', name: _nameCtrl.text, description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null, createdAt: DateTime.now());
    final provider = context.read<AppProvider>();
    final success = await provider.saveCategory(cat, id: widget.cat?.id);
    if (success && mounted) {
      Navigator.pop(context);
      AppToast.show(context, 'Category saved!');
    }
  }
}

// =================== MAINTENANCE SCREEN ===================
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});
  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  String? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    var records = provider.maintenanceRecords;
    if (_filterStatus != null) records = records.where((r) => r.status == _filterStatus).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Maintenance',
            subtitle: 'Track equipment maintenance and repairs',
            action: ElevatedButton.icon(
              onPressed: () => showDialog(context: context, builder: (ctx) => const MaintenanceFormDialog()),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Record'),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            const Text('Filter:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(width: 10),
            ...[null, 'scheduled', 'in_progress', 'completed', 'cancelled'].map((s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(s == null ? 'All' : AppConstants.formatStatus(s)),
                selected: _filterStatus == s,
                onSelected: (_) => setState(() => _filterStatus = s),
                selectedColor: AppTheme.warning.withOpacity(0.15),
                checkmarkColor: AppTheme.warning,
              ),
            )),
            const Spacer(),
            Text('${records.length} records', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: records.isEmpty
                ? const EmptyState(icon: Icons.build_circle_rounded, message: 'No maintenance records found.')
                : Container(
                    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
                        child: const Row(children: [
                          Expanded(flex: 3, child: _MH('Equipment')),
                          Expanded(flex: 2, child: _MH('Type')),
                          Expanded(flex: 3, child: _MH('Description')),
                          Expanded(flex: 2, child: _MH('Performed By')),
                          Expanded(flex: 2, child: _MH('Date')),
                          Expanded(child: _MH('Cost')),
                          Expanded(flex: 2, child: _MH('Status')),
                          SizedBox(width: 80),
                        ]),
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: records.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                          itemBuilder: (ctx, i) {
                            final r = records[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(children: [
                                Expanded(flex: 3, child: Text(r.equipmentName ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                                Expanded(flex: 2, child: Text(AppConstants.formatStatus(r.maintenanceType), style: const TextStyle(fontSize: 13))),
                                Expanded(flex: 3, child: Text(r.description ?? '-', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis)),
                                Expanded(flex: 2, child: Text(r.performedBy ?? '-', style: const TextStyle(fontSize: 13))),
                                Expanded(flex: 2, child: Text(DateFormat('MMM d, y').format(r.maintenanceDate), style: const TextStyle(fontSize: 13))),
                                Expanded(child: Text('₱${r.cost.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13))),
                                Expanded(flex: 2, child: StatusBadge(status: r.status)),
                                SizedBox(width: 80, child: Row(children: [
                                  IconButton(onPressed: () => showDialog(context: context, builder: (ctx) => MaintenanceFormDialog(record: r)), icon: const Icon(Icons.edit_rounded, size: 16, color: AppTheme.primary)),
                                  IconButton(onPressed: () async { await provider.deleteMaintenanceRecord(r.id); }, icon: const Icon(Icons.delete_rounded, size: 16, color: AppTheme.error)),
                                ])),
                              ]),
                            );
                          },
                        ),
                      ),
                    ]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MH extends StatelessWidget {
  final String label;
  const _MH(this.label);
  @override
  Widget build(BuildContext context) => Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary));
}

class MaintenanceFormDialog extends StatefulWidget {
  final MaintenanceRecord? record;
  const MaintenanceFormDialog({super.key, this.record});
  @override
  State<MaintenanceFormDialog> createState() => _MaintenanceFormDialogState();
}

class _MaintenanceFormDialogState extends State<MaintenanceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _descCtrl = TextEditingController(text: widget.record?.description);
  late final _performedByCtrl = TextEditingController(text: widget.record?.performedBy);
  late final _costCtrl = TextEditingController(text: widget.record?.cost.toString() ?? '0');
  late final _notesCtrl = TextEditingController(text: widget.record?.notes);
  String? _equipmentId;
  String _type = 'preventive';
  String _status = 'completed';
  DateTime _date = DateTime.now();
  DateTime? _nextDate;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _equipmentId = widget.record!.equipmentId;
      _type = widget.record!.maintenanceType;
      _status = widget.record!.status;
      _date = widget.record!.maintenanceDate;
      _nextDate = widget.record!.nextMaintenanceDate;
    }
  }

  @override
  void dispose() {
    for (var c in [_descCtrl, _performedByCtrl, _costCtrl, _notesCtrl]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Dialog(
      child: Container(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppTheme.warning, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
              child: Row(children: [
                Text(widget.record != null ? 'Edit Maintenance' : 'New Maintenance Record',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  DropdownButtonFormField<String>(
                    value: _equipmentId,
                    decoration: const InputDecoration(labelText: 'Equipment *'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Select Equipment')),
                      ...provider.equipment.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))),
                    ],
                    validator: (v) => v == null ? 'Required' : null,
                    onChanged: (v) => setState(() => _equipmentId = v),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: AppConstants.maintenanceTypes.map((s) => DropdownMenuItem(value: s, child: Text(AppConstants.formatStatus(s)))).toList(),
                      onChanged: (v) => setState(() => _type = v!),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: AppConstants.maintenanceStatuses.map((s) => DropdownMenuItem(value: s, child: Text(AppConstants.formatStatus(s)))).toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    )),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: TextFormField(controller: _performedByCtrl, decoration: const InputDecoration(labelText: 'Performed By'))),
                    const SizedBox(width: 16),
                    Expanded(child: TextFormField(controller: _costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost (₱)'))),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _DField(label: 'Maintenance Date', value: _date, onChanged: (d) => setState(() => _date = d ?? _date))),
                    const SizedBox(width: 16),
                    Expanded(child: _DField(label: 'Next Maintenance Date', value: _nextDate, onChanged: (d) => setState(() => _nextDate = d))),
                  ]),
                  const SizedBox(height: 16),
                  TextFormField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 16),
                  TextFormField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
                  child: Text(widget.record != null ? 'Update' : 'Save'),
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
    final record = MaintenanceRecord(
      id: widget.record?.id ?? '',
      equipmentId: _equipmentId!,
      maintenanceType: _type,
      description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
      performedBy: _performedByCtrl.text.isNotEmpty ? _performedByCtrl.text : null,
      cost: double.tryParse(_costCtrl.text) ?? 0,
      maintenanceDate: _date,
      nextMaintenanceDate: _nextDate,
      status: _status,
      notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
      createdAt: DateTime.now(),
    );
    final provider = context.read<AppProvider>();
    final success = await provider.saveMaintenanceRecord(record, id: widget.record?.id);
    if (success && mounted) {
      Navigator.pop(context);
      AppToast.show(context, 'Record saved!');
    }
  }
}

class _DField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  const _DField({required this.label, this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: value ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
        onChanged(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today, size: 16)),
        child: Text(value != null ? DateFormat('MMM d, y').format(value!) : 'Select date',
          style: TextStyle(color: value != null ? AppTheme.textPrimary : AppTheme.textSecondary)),
      ),
    );
  }
}