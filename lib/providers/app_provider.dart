// lib/providers/app_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class AppProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();
  SupabaseService get supabaseService => _service;
  Timer? _searchDebounce;

  // =================== AUTH ===================
  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      final res = await _service.signIn(email, password);
      print('AUTH RESULT: user=${res.user?.id}, session=${res.session != null}');
      _currentUser = await _service.getCurrentUserProfile();
      print('PROFILE RESULT: $_currentUser');
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      print('SIGN IN EXCEPTION: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    _currentUser = null;
    _selectedIndex = 0;
    _laboratories = [];
    _categories = [];
    _equipment = [];
    _borrowingRecords = [];
    _maintenanceRecords = [];
    _userProfiles = [];
    _labSeats = [];
    _notifications = [];
    notifyListeners();
  }

  Future<void> checkAuth() async {
    _currentUser = await _service.getCurrentUserProfile();
    notifyListeners();
  }

  // =================== ACCOUNT MANAGEMENT ===================
  Future<bool> updateCurrentUserProfile(UserProfile updated) async {
    try {
      _setLoading(true);
      await _service.updateUserProfile(updated.id, updated);
      _currentUser = await _service.getCurrentUserProfile();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =================== NAVIGATION ===================
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;
  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // =================== STATE ===================
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  /// Guards against concurrent save operations that would each trigger
  /// notifyListeners → context.watch rebuilds → re-opening save again.
  bool _isSaving = false;

  /// Only notify if the value actually changes to prevent spurious rebuilds.
  void _setLoading(bool v) {
    if (_isLoading == v) return;
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? m) {
    if (_error == m) return;
    _error = m;
    notifyListeners();
  }

  // =================== DATA ===================
  List<Laboratory>        _laboratories     = [];
  List<Category>          _categories       = [];
  List<Equipment>         _equipment        = [];
  List<BorrowingRecord>   _borrowingRecords = [];
  List<MaintenanceRecord> _maintenanceRecords = [];
  List<UserProfile>       _userProfiles     = [];
  List<LabSeat>           _labSeats         = [];
  Map<String, dynamic>    _dashboardStats   = {};
  List<AppNotification>   _notifications    = [];

  List<Laboratory>        get laboratories       => _laboratories;
  List<Category>          get categories         => _categories;
  List<Equipment>         get equipment          => _equipment;
  List<BorrowingRecord>   get borrowingRecords   => _borrowingRecords;
  List<MaintenanceRecord> get maintenanceRecords => _maintenanceRecords;
  List<UserProfile>       get userProfiles       => _userProfiles;
  List<LabSeat>           get labSeats           => _labSeats;
  Map<String, dynamic>    get dashboardStats     => _dashboardStats;
  List<AppNotification>   get notifications      => _notifications;
  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  // =================== FILTERS ===================
  String  _searchQuery = '';
  String? _filterLabId;
  String? _filterCatId;
  String? _filterStatus;

  String get searchQuery => _searchQuery;

  /// Debounced search — waits 400 ms after the user stops typing.
  void setSearchQuery(String q) {
    _searchQuery = q;
    _searchDebounce?.cancel();
    _searchDebounce =
        Timer(const Duration(milliseconds: 400), loadEquipment);
  }

  void setFilterLab(String? id)      { _filterLabId = id;  loadEquipment(); }
  void setFilterCategory(String? id) { _filterCatId = id;  loadEquipment(); }
  void setFilterStatus(String? s)    { _filterStatus = s;  loadEquipment(); }

  // =================== INIT ===================
  Future<void> init() async {
    await Future.wait([
      loadLaboratories(),
      loadCategories(),
      loadEquipment(),
      loadBorrowingRecords(),
      loadMaintenanceRecords(),
      loadDashboardStats(),
      loadUserProfiles(),
    ]);
    await loadNotifications();
  }

  // =================== DASHBOARD ===================
  Future<void> loadDashboardStats() async {
    try {
      _dashboardStats = await _service.getDashboardStats();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // =================== LABORATORIES ===================
  Future<void> loadLaboratories() async {
    try {
      _laboratories = await _service.getLaboratories();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> saveLaboratory(Laboratory lab, {String? id}) async {
    if (_isSaving) return false;
    try {
      _isSaving = true;
      _setLoading(true);
      if (id != null) await _service.updateLaboratory(id, lab);
      else             await _service.createLaboratory(lab);
      await Future.wait([loadLaboratories(), loadDashboardStats()]);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _isSaving = false;
      _setLoading(false);
    }
  }

  Future<bool> deleteLaboratory(String id) async {
    try {
      _setLoading(true);
      await _service.deleteLaboratory(id);
      await Future.wait([loadLaboratories(), loadDashboardStats()]);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =================== CATEGORIES ===================
  Future<void> loadCategories() async {
    try {
      _categories = await _service.getCategories();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> saveCategory(Category cat, {String? id}) async {
    if (_isSaving) return false;
    try {
      _isSaving = true;
      _setLoading(true);
      if (id != null) await _service.updateCategory(id, cat);
      else             await _service.createCategory(cat);
      await loadCategories();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _isSaving = false;
      _setLoading(false);
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      _setLoading(true);
      await _service.deleteCategory(id);
      await loadCategories();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =================== EQUIPMENT ===================
  Future<void> loadEquipment() async {
    try {
      _equipment = await _service.getEquipment(
        laboratoryId: _filterLabId,
        categoryId:   _filterCatId,
        status:       _filterStatus,
        search:       _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> saveEquipment(Equipment eq, {String? id}) async {
    if (_isSaving) return false;
    try {
      _isSaving = true;
      _setLoading(true);
      if (id != null) await _service.updateEquipment(id, eq);
      else             await _service.createEquipment(eq);
      await Future.wait([loadEquipment(), loadDashboardStats()]);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _isSaving = false;
      _setLoading(false);
    }
  }

  Future<bool> deleteEquipment(String id) async {
    try {
      _setLoading(true);
      await _service.deleteEquipment(id);
      await Future.wait([loadEquipment(), loadDashboardStats()]);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =================== BORROWING ===================
  Future<void> loadBorrowingRecords(
      {String? status, DateTime? dateFrom, DateTime? dateTo}) async {
    try {
      _borrowingRecords = await _service.getBorrowingRecords(
          status: status, dateFrom: dateFrom, dateTo: dateTo);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> saveBorrowingRecord(BorrowingRecord r, {String? id}) async {
    // ── Spike-fix: guard against concurrent calls ──────────────────────────
    if (_isSaving) return false;
    try {
      _isSaving = true;
      _setLoading(true);
      if (id != null) await _service.updateBorrowingRecord(id, r);
      else             await _service.createBorrowingRecord(r);
      await Future.wait([loadBorrowingRecords(), loadDashboardStats()]);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _isSaving = false;
      _setLoading(false);
    }
  }

  Future<bool> deleteBorrowingRecord(String id) async {
    try {
      _setLoading(true);
      await _service.deleteBorrowingRecord(id);
      await loadBorrowingRecords();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =================== MAINTENANCE ===================
  Future<void> loadMaintenanceRecords(
      {String? status, DateTime? dateFrom, DateTime? dateTo}) async {
    try {
      _maintenanceRecords = await _service.getMaintenanceRecords(
          status: status, dateFrom: dateFrom, dateTo: dateTo);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> saveMaintenanceRecord(MaintenanceRecord r, {String? id}) async {
    if (_isSaving) return false;
    try {
      _isSaving = true;
      _setLoading(true);
      if (id != null) await _service.updateMaintenanceRecord(id, r);
      else             await _service.createMaintenanceRecord(r);
      await Future.wait([loadMaintenanceRecords(), loadDashboardStats()]);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _isSaving = false;
      _setLoading(false);
    }
  }

  Future<bool> deleteMaintenanceRecord(String id) async {
    try {
      _setLoading(true);
      await _service.deleteMaintenanceRecord(id);
      await loadMaintenanceRecords();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =================== USER MANAGEMENT ===================
  Future<void> loadUserProfiles() async {
    try {
      _userProfiles = await _service.getUserProfiles();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> createUser(UserProfile profile, String password) async {
    if (_isSaving) return false;
    try {
      _isSaving = true;
      _setLoading(true);
      await _service.createUserProfile(profile, password);
      await loadUserProfiles();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _isSaving = false;
      _setLoading(false);
    }
  }

  Future<bool> updateUser(String id, UserProfile profile) async {
    if (_isSaving) return false;
    try {
      _isSaving = true;
      _setLoading(true);
      await _service.updateUserProfile(id, profile);
      await loadUserProfiles();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _isSaving = false;
      _setLoading(false);
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      _setLoading(true);
      await _service.deleteUserProfile(id);
      await loadUserProfiles();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleUserActive(String id, bool isActive) async {
    try {
      await _service.toggleUserActive(id, isActive);
      await loadUserProfiles();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // =================== LAB SEATS ===================
  Future<void> loadLabSeats(String laboratoryId) async {
    try {
      final seats = await _service.getLabSeats(laboratoryId);
      // Build a map of equipmentId → active borrowing record for O(1) lookup
      final borrowMap = <String, BorrowingRecord>{};
      for (final r in _borrowingRecords) {
        if (r.status == 'borrowed' || r.status == 'overdue') {
          borrowMap[r.equipmentId] = r;
        }
      }
      // Inject borrower info into every SeatEquipment so the map can show
      // "Borrowed" badges without extra DB queries.
      _labSeats = seats.map((seat) {
        final enriched = seat.seatEquipment.map((se) {
          final borrow = borrowMap[se.equipmentId];
          return se.withBorrowInfo(
            borrowerName: borrow?.borrowerName,
            borrowStatus: borrow?.status,
          );
        }).toList();
        return LabSeat(
          id:            seat.id,
          laboratoryId:  seat.laboratoryId,
          seatLabel:     seat.seatLabel,
          rowNumber:     seat.rowNumber,
          colNumber:     seat.colNumber,
          seatType:      seat.seatType,
          isActive:      seat.isActive,
          notes:         seat.notes,
          createdAt:     seat.createdAt,
          seatEquipment: enriched,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> markEquipmentAsNeedRepair({
    required String equipmentId,
    required String equipmentName,
    required String seatLabel,
    required String laboratoryId,
    String? repairNote,
  }) async {
    if (_isSaving) return false;
    try {
      _isSaving = true;
      _setLoading(true);
      await _service.updateEquipmentStatus(equipmentId, 'under_repair',
          notes: repairNote);

      final maintenanceRecord = MaintenanceRecord(
        id: '',
        equipmentId: equipmentId,
        maintenanceType: 'corrective',
        description: repairNote != null && repairNote.isNotEmpty
            ? 'Repair required at seat $seatLabel: $repairNote'
            : 'Repair required at seat $seatLabel. Marked by ${_currentUser?.fullName ?? 'Lab Custodian'}.',
        performedBy: _currentUser?.fullName,
        cost: 0,
        maintenanceDate: DateTime.now(),
        status: 'in_progress',
        notes: repairNote,
        createdAt: DateTime.now(),
      );
      await _service.createMaintenanceRecord(maintenanceRecord);

      final lab = _laboratories.firstWhere(
          (l) => l.id == laboratoryId,
          orElse: () => Laboratory(
              id: laboratoryId,
              name: 'Lab',
              roomNumber: '',
              capacity: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now()));
      await _service.notifyRepairWithNote(
        seatLabel: seatLabel,
        equipmentName: equipmentName,
        laboratoryName: lab.name,
        laboratoryId: laboratoryId,
        repairNote: repairNote,
      );
      await loadLabSeats(laboratoryId);
      await loadEquipment();
      await loadMaintenanceRecords();
      await loadNotifications();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _isSaving = false;
      _setLoading(false);
    }
  }

  Future<bool> markEquipmentAsFixed({
    required String equipmentId,
    required String equipmentName,
    required String seatLabel,
    required String laboratoryId,
  }) async {
    if (_isSaving) return false;
    try {
      _isSaving = true;
      _setLoading(true);
      await _service.updateEquipmentStatus(equipmentId, 'active', notes: '');
      await _service.completeMaintenanceRecordForEquipment(
        equipmentId: equipmentId,
        completedBy: _currentUser?.fullName ?? 'Student Assistant',
      );

      final lab = _laboratories.firstWhere(
          (l) => l.id == laboratoryId,
          orElse: () => Laboratory(
              id: laboratoryId,
              name: 'Lab',
              roomNumber: '',
              capacity: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now()));
      await _service.notifyEquipmentFixed(
        seatLabel: seatLabel,
        equipmentName: equipmentName,
        laboratoryName: lab.name,
        fixedByName: _currentUser?.fullName ?? 'Student Assistant',
      );
      await loadLabSeats(laboratoryId);
      await loadEquipment();
      await loadMaintenanceRecords();
      await loadNotifications();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _isSaving = false;
      _setLoading(false);
    }
  }

  // =================== NOTIFICATIONS ===================
  Future<void> loadNotifications() async {
    if (_currentUser == null) return;
    try {
      _notifications = await _service.getNotifications(_currentUser!.id);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> markNotificationRead(String id) async {
    try {
      await _service.markNotificationRead(id);
      await loadNotifications();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> markAllNotificationsRead() async {
    if (_currentUser == null) return;
    try {
      await _service.markAllNotificationsRead(_currentUser!.id);
      await loadNotifications();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _service.deleteNotification(id);
      await loadNotifications();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> saveLabSeat(LabSeat seat, {String? id}) async {
    if (_isSaving) return false;
    try {
      _isSaving = true;
      _setLoading(true);
      if (id != null) await _service.updateLabSeat(id, seat);
      else             await _service.createLabSeat(seat);
      await loadLabSeats(seat.laboratoryId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _isSaving = false;
      _setLoading(false);
    }
  }

  Future<bool> deleteLabSeat(String id, String laboratoryId) async {
    try {
      _setLoading(true);
      await _service.deleteLabSeat(id);
      await loadLabSeats(laboratoryId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> assignEquipmentToSeat(
      SeatEquipment se, String laboratoryId) async {
    if (_isSaving) return false;
    try {
      _isSaving = true;
      _setLoading(true);
      await _service.assignEquipmentToSeat(se);
      await loadLabSeats(laboratoryId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _isSaving = false;
      _setLoading(false);
    }
  }

  Future<bool> removeEquipmentFromSeat(
      String seatEquipmentId, String laboratoryId) async {
    try {
      _setLoading(true);
      await _service.removeEquipmentFromSeat(seatEquipmentId);
      await loadLabSeats(laboratoryId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}