// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // =================== AUTH ===================
  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

Future<UserProfile?> getCurrentUserProfile() async {
  final user = client.auth.currentUser;
  if (user == null) {
    print('DEBUG: No current user in auth');
    return null;
  }
  print('DEBUG: Auth user found: ${user.id} / ${user.email}');
  try {
    final res = await client
        .from('user_profiles')
        .select('*, laboratories(name)')
        .eq('id', user.id)
        .single();
    print('DEBUG: Profile found: $res');
    return UserProfile.fromMap(res);
  } catch (e) {
    print('DEBUG: Profile fetch error: $e'); // ← THIS will show the real error
    return null;
  }
}
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // =================== USER PROFILES ===================
  Future<List<UserProfile>> getUserProfiles() async {
    final res = await client
        .from('user_profiles')
        .select('*, laboratories(name)')
        .order('full_name');
    return (res as List).map((e) => UserProfile.fromMap(e)).toList();
  }

  Future<UserProfile> createUserProfile(UserProfile profile, String password) async {
    final authRes = await client.auth.admin.createUser(
      AdminUserAttributes(email: profile.email, password: password, emailConfirm: true),
    );
    final uid = authRes.user!.id;
    final map = profile.toMap();
    map['id'] = uid;
    final res = await client.from('user_profiles').insert(map).select('*, laboratories(name)').single();
    return UserProfile.fromMap(res);
  }

  Future<UserProfile> updateUserProfile(String id, UserProfile profile) async {
    final res = await client.from('user_profiles').update(profile.toMap()).eq('id', id).select('*, laboratories(name)').single();
    return UserProfile.fromMap(res);
  }

  Future<void> deleteUserProfile(String id) async {
    await client.from('user_profiles').delete().eq('id', id);
    try { await client.auth.admin.deleteUser(id); } catch (_) {}
  }

  Future<void> toggleUserActive(String id, bool isActive) async {
    await client.from('user_profiles').update({'is_active': isActive}).eq('id', id);
  }

  // =================== LABORATORIES ===================
  Future<List<Laboratory>> getLaboratories() async {
    final res = await client.from('laboratories').select().order('name');
    return (res as List).map((e) => Laboratory.fromMap(e)).toList();
  }

  Future<Laboratory> createLaboratory(Laboratory lab) async {
    final res = await client.from('laboratories').insert(lab.toMap()).select().single();
    return Laboratory.fromMap(res);
  }

  Future<Laboratory> updateLaboratory(String id, Laboratory lab) async {
    final res = await client.from('laboratories').update(lab.toMap()).eq('id', id).select().single();
    return Laboratory.fromMap(res);
  }

  Future<void> deleteLaboratory(String id) async {
    await client.from('laboratories').delete().eq('id', id);
  }

  // =================== CATEGORIES ===================
  Future<List<Category>> getCategories() async {
    final res = await client.from('categories').select().order('name');
    return (res as List).map((e) => Category.fromMap(e)).toList();
  }

  Future<Category> createCategory(Category cat) async {
    final res = await client.from('categories').insert(cat.toMap()).select().single();
    return Category.fromMap(res);
  }

  Future<Category> updateCategory(String id, Category cat) async {
    final res = await client.from('categories').update(cat.toMap()).eq('id', id).select().single();
    return Category.fromMap(res);
  }

  Future<void> deleteCategory(String id) async {
    await client.from('categories').delete().eq('id', id);
  }

  // =================== EQUIPMENT ===================
  Future<List<Equipment>> getEquipment({String? laboratoryId, String? categoryId, String? status, String? search}) async {
    var query = client.from('equipment').select('*, categories(name), laboratories(name)');
    if (laboratoryId != null) query = query.eq('laboratory_id', laboratoryId) as dynamic;
    if (categoryId   != null) query = query.eq('category_id', categoryId) as dynamic;
    if (status       != null) query = query.eq('status', status) as dynamic;
    if (search != null && search.isNotEmpty) {
      query = query.or('name.ilike.%$search%,serial_number.ilike.%$search%,brand.ilike.%$search%') as dynamic;
    }
    final res = await query.order('name');
    return (res as List).map((e) => Equipment.fromMap(e)).toList();
  }

  Future<Equipment> createEquipment(Equipment eq) async {
    final res = await client.from('equipment').insert(eq.toMap()).select('*, categories(name), laboratories(name)').single();
    return Equipment.fromMap(res);
  }

  Future<Equipment> updateEquipment(String id, Equipment eq) async {
    final res = await client.from('equipment').update(eq.toMap()).eq('id', id).select('*, categories(name), laboratories(name)').single();
    return Equipment.fromMap(res);
  }

  Future<void> deleteEquipment(String id) async {
    await client.from('equipment').delete().eq('id', id);
  }

  // =================== DASHBOARD STATS ===================
  Future<Map<String, dynamic>> getDashboardStats() async {
    final eqList = await client.from('equipment').select('status, quantity, unit_cost') as List;
    final brList = await client.from('borrowing_records').select('status') as List;
    final mList  = await client.from('maintenance_records').select('status') as List;

    int totalItems = 0, activeItems = 0, underRepair = 0;
    double totalValue = 0;
    for (var e in eqList) {
      totalItems += (e['quantity'] as int);
      totalValue += (e['unit_cost'] as num) * (e['quantity'] as num);
      if (e['status'] == 'active')       activeItems += (e['quantity'] as int);
      if (e['status'] == 'under_repair') underRepair += (e['quantity'] as int);
    }
    return {
      'totalItems': totalItems, 'activeItems': activeItems, 'underRepair': underRepair,
      'totalValue': totalValue,
      'borrowed':  brList.where((b) => b['status'] == 'borrowed').length,
      'overdue':   brList.where((b) => b['status'] == 'overdue').length,
      'scheduledMaintenance': mList.where((m) => m['status'] == 'scheduled').length,
      'totalEquipmentRecords': eqList.length,
    };
  }

  // =================== BORROWING ===================
  Future<List<BorrowingRecord>> getBorrowingRecords({String? status, String? equipmentId, DateTime? dateFrom, DateTime? dateTo}) async {
    var query = client.from('borrowing_records').select('*, equipment(name)');
    if (status      != null) query = query.eq('status', status) as dynamic;
    if (equipmentId != null) query = query.eq('equipment_id', equipmentId) as dynamic;
    if (dateFrom    != null) query = query.gte('borrow_date', dateFrom.toIso8601String()) as dynamic;
    if (dateTo      != null) query = query.lte('borrow_date', dateTo.toIso8601String()) as dynamic;
    final res = await query.order('borrow_date', ascending: false);
    return (res as List).map((e) => BorrowingRecord.fromMap(e)).toList();
  }

  Future<BorrowingRecord> createBorrowingRecord(BorrowingRecord r) async {
    final res = await client.from('borrowing_records').insert(r.toMap()).select('*, equipment(name)').single();
    return BorrowingRecord.fromMap(res);
  }

  Future<BorrowingRecord> updateBorrowingRecord(String id, BorrowingRecord r) async {
    final res = await client.from('borrowing_records').update(r.toMap()).eq('id', id).select('*, equipment(name)').single();
    return BorrowingRecord.fromMap(res);
  }

  Future<void> deleteBorrowingRecord(String id) async {
    await client.from('borrowing_records').delete().eq('id', id);
  }

  // =================== MAINTENANCE ===================
  Future<List<MaintenanceRecord>> getMaintenanceRecords({String? status, String? equipmentId, DateTime? dateFrom, DateTime? dateTo}) async {
    var query = client.from('maintenance_records').select('*, equipment(name)');
    if (status      != null) query = query.eq('status', status) as dynamic;
    if (equipmentId != null) query = query.eq('equipment_id', equipmentId) as dynamic;
    if (dateFrom    != null) query = query.gte('maintenance_date', dateFrom.toIso8601String().split('T')[0]) as dynamic;
    if (dateTo      != null) query = query.lte('maintenance_date', dateTo.toIso8601String().split('T')[0]) as dynamic;
    final res = await query.order('maintenance_date', ascending: false);
    return (res as List).map((e) => MaintenanceRecord.fromMap(e)).toList();
  }

  Future<MaintenanceRecord> createMaintenanceRecord(MaintenanceRecord r) async {
    final res = await client.from('maintenance_records').insert(r.toMap()).select('*, equipment(name)').single();
    return MaintenanceRecord.fromMap(res);
  }

  Future<MaintenanceRecord> updateMaintenanceRecord(String id, MaintenanceRecord r) async {
    final res = await client.from('maintenance_records').update(r.toMap()).eq('id', id).select('*, equipment(name)').single();
    return MaintenanceRecord.fromMap(res);
  }

  Future<void> deleteMaintenanceRecord(String id) async {
    await client.from('maintenance_records').delete().eq('id', id);
  }

  // =================== LAB SEATS ===================
  Future<List<LabSeat>> getLabSeats(String laboratoryId) async {
    final res = await client
        .from('lab_seats')
        .select('*, seat_equipment(*, equipment(*, categories(name)))')
        .eq('laboratory_id', laboratoryId)
        .order('row_number')
        .order('col_number');
    return (res as List).map((e) => LabSeat.fromMap(e)).toList();
  }

  Future<LabSeat> createLabSeat(LabSeat seat) async {
    final res = await client.from('lab_seats').insert(seat.toMap()).select().single();
    return LabSeat.fromMap({...res, 'seat_equipment': []});
  }

  Future<LabSeat> updateLabSeat(String id, LabSeat seat) async {
    final res = await client.from('lab_seats').update(seat.toMap()).eq('id', id).select().single();
    return LabSeat.fromMap({...res, 'seat_equipment': []});
  }

  Future<void> deleteLabSeat(String id) async {
    await client.from('lab_seats').delete().eq('id', id);
  }

  Future<SeatEquipment> assignEquipmentToSeat(SeatEquipment se) async {
    final res = await client.from('seat_equipment').insert(se.toMap()).select('*, equipment(*, categories(name))').single();
    return SeatEquipment.fromMap(res);
  }

  Future<void> removeEquipmentFromSeat(String seatEquipmentId) async {
    await client.from('seat_equipment').delete().eq('id', seatEquipmentId);
  }

  // =================== NOTIFICATIONS ===================
  Future<List<AppNotification>> getNotifications(String userId) async {
    final res = await client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return (res as List).map((e) => AppNotification.fromMap(e)).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllNotificationsRead(String userId) async {
    await client.from('notifications').update({'is_read': true}).eq('user_id', userId);
  }

  Future<void> deleteNotification(String id) async {
    await client.from('notifications').delete().eq('id', id);
  }

  /// Notify ONLY student assistants when equipment needs repair.
  /// Scans all under-repair seats and sends ONE summarized notification per user.
  /// Skips users who already have an unread summary notification for this lab.
  Future<void> notifyStudentAssistants(List<LabSeat> underRepairSeats, String laboratoryName) async {
    if (underRepairSeats.isEmpty) return;

    final users = await client
        .from('user_profiles')
        .select('id')
        .eq('role', 'student_assistant') as List;

    // Build a single summarized message listing all affected seats
    final seatLabels = underRepairSeats.map((s) => s.seatLabel).join(', ');
    final count      = underRepairSeats.length;
    final message    = count == 1
        ? 'Seat $seatLabels in $laboratoryName has equipment that needs repair. Please check and mark it as fixed when done.'
        : '$count seats ($seatLabels) in $laboratoryName have equipment that need repair. Please check each and mark them as fixed when done.';

    for (final user in users) {
      // Only send if there is no existing unread summary notification for this lab
      final existing = await client
          .from('notifications')
          .select('id')
          .eq('user_id', user['id'])
          .eq('type', 'under_repair')
          .eq('is_read', false)
          .ilike('message', '%$laboratoryName%')
          .limit(1) as List;

      if (existing.isNotEmpty) continue;

      await client.from('notifications').insert({
        'user_id': user['id'],
        'title':   '🔧 Equipment Needs Repair',
        'message': message,
        'type':    'under_repair',
        'is_read': false,
      });
    }
  }

  /// Notify student assistants that a specific equipment needs repair (with note).
  /// Sends ONE notification per user — skips if they already have an unread one for
  /// this exact equipment + seat combination.
  /// Stores laboratoryId in reference_id so tapping the notification navigates to the lab map.
  Future<void> notifyRepairWithNote({
    required String seatLabel,
    required String equipmentName,
    required String laboratoryName,
    required String laboratoryId,
    String? repairNote,
  }) async {
    final users = await client
        .from('user_profiles')
        .select('id')
        .eq('role', 'student_assistant') as List;

    final message = repairNote != null && repairNote.isNotEmpty
        ? '$equipmentName at seat $seatLabel in $laboratoryName needs repair.\nNote: $repairNote'
        : '$equipmentName at seat $seatLabel in $laboratoryName needs repair.';

    for (final user in users) {
      // Skip if already has an unread notification for this exact equipment + seat
      final existing = await client
          .from('notifications')
          .select('id')
          .eq('user_id', user['id'])
          .eq('type', 'under_repair')
          .eq('is_read', false)
          .ilike('message', '%$equipmentName%$seatLabel%')
          .limit(1) as List;

      if (existing.isNotEmpty) continue;

      await client.from('notifications').insert({
        'user_id':      user['id'],
        'title':        '🔧 Equipment Needs Repair',
        'message':      message,
        'type':         'under_repair',
        'reference_id': laboratoryId,   // used for navigation on tap
        'is_read':      false,
      });
    }
  }

  /// Notify lab custodians and department head that equipment has been fixed.
  Future<void> notifyEquipmentFixed({
    required String seatLabel,
    required String equipmentName,
    required String laboratoryName,
    required String fixedByName,
  }) async {
    final users = await client
        .from('user_profiles')
        .select('id')
        .inFilter('role', ['laboratory_custodian', 'department_head']) as List;

    for (final user in users) {
      await client.from('notifications').insert({
        'user_id': user['id'],
        'title':   '✅ Equipment Fixed',
        'message': '$equipmentName at seat $seatLabel in $laboratoryName has been marked as fixed by $fixedByName.',
        'type':    'equipment_fixed',
        'is_read': false,
      });
    }
  }

  Future<void> updateEquipmentStatus(String equipmentId, String status, {String? notes}) async {
    final update = {'status': status};
    if (notes != null) update['notes'] = notes;
    await client.from('equipment').update(update).eq('id', equipmentId);
  }

  /// Finds the most recent 'in_progress' maintenance record for the given equipment
  /// and marks it as 'completed'. Called automatically when student assistant marks equipment fixed.
  Future<void> completeMaintenanceRecordForEquipment({
    required String equipmentId,
    required String completedBy,
  }) async {
    try {
      final records = await client
          .from('maintenance_records')
          .select('id')
          .eq('equipment_id', equipmentId)
          .eq('status', 'in_progress')
          .order('maintenance_date', ascending: false)
          .limit(1) as List;

      if (records.isEmpty) return;

      await client.from('maintenance_records').update({
        'status':       'completed',
        'performed_by': completedBy,
        'notes':        'Marked as fixed by $completedBy on ${DateTime.now().toLocal().toString().split('.').first}.',
      }).eq('id', records.first['id']);
    } catch (e) {
      print('completeMaintenanceRecordForEquipment error: $e');
    }
  }
}