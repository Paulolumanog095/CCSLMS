// lib/models/models.dart
import 'package:flutter/material.dart';

// ============================================================
// USER ROLE ENUM
// ============================================================
enum UserRole { departmentHead, laboratoryCustodian, faculty, studentAssistant }

extension UserRoleExt on UserRole {
  String get value {
    switch (this) {
      case UserRole.departmentHead:       return 'department_head';
      case UserRole.laboratoryCustodian:  return 'laboratory_custodian';
      case UserRole.faculty:              return 'faculty';
      case UserRole.studentAssistant:     return 'student_assistant';
    }
  }

  String get label {
    switch (this) {
      case UserRole.departmentHead:       return 'Department Head';
      case UserRole.laboratoryCustodian:  return 'Laboratory Custodian';
      case UserRole.faculty:              return 'Faculty';
      case UserRole.studentAssistant:     return 'Student Assistant';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.departmentHead:       return const Color(0xFF7C3AED);
      case UserRole.laboratoryCustodian:  return const Color(0xFF1E40AF);
      case UserRole.faculty:              return const Color(0xFF0F766E);
      case UserRole.studentAssistant:     return const Color(0xFFF59E0B);
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.departmentHead:       return Icons.admin_panel_settings_rounded;
      case UserRole.laboratoryCustodian:  return Icons.manage_accounts_rounded;
      case UserRole.faculty:              return Icons.school_rounded;
      case UserRole.studentAssistant:     return Icons.person_rounded;
    }
  }

  static UserRole fromString(String val) {
    return UserRole.values.firstWhere(
      (r) => r.value == val,
      orElse: () => UserRole.faculty,
    );
  }
}

// ============================================================
// USER PROFILE
// ============================================================
class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String? idNumber;
  final UserRole role;
  final String? department;
  final String? laboratoryId;
  final String? phone;
  final bool isActive;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Joined
  final String? laboratoryName;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.idNumber,
    required this.role,
    this.department,
    this.laboratoryId,
    this.phone,
    required this.isActive,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.laboratoryName,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id:             map['id'],
      fullName:       map['full_name'],
      email:          map['email'],
      idNumber:       map['id_number'],
      role:           UserRoleExt.fromString(map['role'] ?? 'faculty'),
      department:     map['department'],
      laboratoryId:   map['laboratory_id'],
      phone:          map['phone'],
      isActive:       map['is_active'] ?? true,
      avatarUrl:      map['avatar_url'],
      createdAt:      DateTime.parse(map['created_at']),
      updatedAt:      DateTime.parse(map['updated_at']),
      laboratoryName: map['laboratories'] is Map ? map['laboratories']['name'] : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'full_name':     fullName,
    'email':         email,
    'id_number':     idNumber,
    'role':          role.value,
    'department':    department,
    'laboratory_id': laboratoryId,
    'phone':         phone,
    'is_active':     isActive,
  };

  // Permission helpers
  bool get canManageEquipment  => role == UserRole.departmentHead || role == UserRole.laboratoryCustodian;
  bool get canApproveBorrowing => role == UserRole.departmentHead || role == UserRole.laboratoryCustodian;
  bool get canManageUsers      => role == UserRole.departmentHead;
  bool get canPrintReports     => role == UserRole.departmentHead || role == UserRole.laboratoryCustodian;
  bool get canManageMaintenance=> role == UserRole.departmentHead || role == UserRole.laboratoryCustodian;
  bool get canDeleteRecords    => role == UserRole.departmentHead;
  bool get canManageFloorMap   => role == UserRole.departmentHead || role == UserRole.laboratoryCustodian;
}

// ============================================================
// LAB SEAT
// ============================================================
class LabSeat {
  final String id;
  final String laboratoryId;
  final String seatLabel;
  final int? rowNumber;
  final int? colNumber;
  final String seatType;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final List<SeatEquipment> seatEquipment;

  LabSeat({
    required this.id,
    required this.laboratoryId,
    required this.seatLabel,
    this.rowNumber,
    this.colNumber,
    required this.seatType,
    required this.isActive,
    this.notes,
    required this.createdAt,
    this.seatEquipment = const [],
  });

  factory LabSeat.fromMap(Map<String, dynamic> map) {
    return LabSeat(
      id:            map['id'],
      laboratoryId:  map['laboratory_id'],
      seatLabel:     map['seat_label'],
      rowNumber:     map['row_number'],
      colNumber:     map['col_number'],
      seatType:      map['seat_type'] ?? 'workstation',
      isActive:      map['is_active'] ?? true,
      notes:         map['notes'],
      createdAt:     DateTime.parse(map['created_at']),
      seatEquipment: (map['seat_equipment'] as List<dynamic>? ?? [])
          .map((e) => SeatEquipment.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'laboratory_id': laboratoryId,
    'seat_label':    seatLabel,
    'row_number':    rowNumber,
    'col_number':    colNumber,
    'seat_type':     seatType,
    'is_active':     isActive,
    'notes':         notes,
  };

  String get statusSummary {
    if (!isActive) return 'inactive';
    if (seatEquipment.any((se) => se.equipment?.status == 'under_repair')) return 'under_repair';
    if (seatEquipment.any((se) => se.isBorrowed))                          return 'borrowed';
    if (seatEquipment.any((se) => se.equipment?.status == 'inactive'))     return 'inactive';
    return 'active';
  }

  Color get statusColor {
    switch (statusSummary) {
      case 'active':       return const Color(0xFF22C55E);
      case 'under_repair': return const Color(0xFFF59E0B);
      case 'borrowed':     return const Color(0xFF7C3AED);
      case 'inactive':     return const Color(0xFF94A3B8);
      default:             return const Color(0xFF94A3B8);
    }
  }
}

// ============================================================
// SEAT EQUIPMENT (junction: seat ↔ equipment)
// ============================================================
class SeatEquipment {
  final String id;
  final String seatId;
  final String equipmentId;
  final bool isPrimary;
  final DateTime? installedDate;
  final String? notes;
  final DateTime createdAt;
  final Equipment? equipment;
  // Populated at runtime by the provider — not stored in DB
  final String? borrowerName;
  final String? borrowStatus; // 'borrowed' | 'overdue' | null

  SeatEquipment({
    required this.id,
    required this.seatId,
    required this.equipmentId,
    required this.isPrimary,
    this.installedDate,
    this.notes,
    required this.createdAt,
    this.equipment,
    this.borrowerName,
    this.borrowStatus,
  });

  /// True when this specific equipment piece has an active borrow record.
  bool get isBorrowed => borrowStatus == 'borrowed' || borrowStatus == 'overdue';

  factory SeatEquipment.fromMap(Map<String, dynamic> map) {
    return SeatEquipment(
      id:            map['id'],
      seatId:        map['seat_id'],
      equipmentId:   map['equipment_id'],
      isPrimary:     map['is_primary'] ?? false,
      installedDate: map['installed_date'] != null ? DateTime.parse(map['installed_date']) : null,
      notes:         map['notes'],
      createdAt:     DateTime.parse(map['created_at']),
      equipment:     map['equipment'] != null
          ? Equipment.fromMap(map['equipment'] as Map<String, dynamic>)
          : null,
      // borrowerName / borrowStatus are injected by the provider after load
    );
  }

  /// Returns a copy with borrowing info injected.
  SeatEquipment withBorrowInfo({required String? borrowerName, required String? borrowStatus}) {
    return SeatEquipment(
      id:            id,
      seatId:        seatId,
      equipmentId:   equipmentId,
      isPrimary:     isPrimary,
      installedDate: installedDate,
      notes:         notes,
      createdAt:     createdAt,
      equipment:     equipment,
      borrowerName:  borrowerName,
      borrowStatus:  borrowStatus,
    );
  }

  Map<String, dynamic> toMap() => {
    'seat_id':        seatId,
    'equipment_id':   equipmentId,
    'is_primary':     isPrimary,
    'installed_date': installedDate?.toIso8601String().split('T')[0],
    'notes':          notes,
  };
}

// ============================================================
// LABORATORY
// ============================================================
class Laboratory {
  final String id;
  final String name;
  final String roomNumber;
  final String? building;
  final int capacity;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Laboratory({
    required this.id,
    required this.name,
    required this.roomNumber,
    this.building,
    required this.capacity,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Laboratory.fromMap(Map<String, dynamic> map) {
    return Laboratory(
      id:          map['id'],
      name:        map['name'],
      roomNumber:  map['room_number'],
      building:    map['building'],
      capacity:    map['capacity'] ?? 0,
      description: map['description'],
      createdAt:   DateTime.parse(map['created_at']),
      updatedAt:   DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'name':        name,
    'room_number': roomNumber,
    'building':    building,
    'capacity':    capacity,
    'description': description,
  };
}

// ============================================================
// CATEGORY
// ============================================================
class Category {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id:          map['id'],
      name:        map['name'],
      description: map['description'],
      createdAt:   DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'description': description};
}

// ============================================================
// EQUIPMENT
// ============================================================
class Equipment {
  final String id;
  final String name;
  final String? categoryId;
  final String? laboratoryId;
  final String? serialNumber;
  final String? model;
  final String? brand;
  final int quantity;
  final double unitCost;
  final String status;
  final String condition;
  final DateTime? dateAcquired;
  final DateTime? warrantyExpiry;
  final String? specifications;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Joined
  final String? categoryName;
  final String? laboratoryName;

  Equipment({
    required this.id,
    required this.name,
    this.categoryId,
    this.laboratoryId,
    this.serialNumber,
    this.model,
    this.brand,
    required this.quantity,
    required this.unitCost,
    required this.status,
    required this.condition,
    this.dateAcquired,
    this.warrantyExpiry,
    this.specifications,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.laboratoryName,
  });

  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id:             map['id'],
      name:           map['name'],
      categoryId:     map['category_id'],
      laboratoryId:   map['laboratory_id'],
      serialNumber:   map['serial_number'],
      model:          map['model'],
      brand:          map['brand'],
      quantity:       map['quantity'] ?? 1,
      unitCost:       (map['unit_cost'] ?? 0).toDouble(),
      status:         map['status'] ?? 'active',
      condition:      map['condition'] ?? 'good',
      dateAcquired:   map['date_acquired']   != null ? DateTime.parse(map['date_acquired'])   : null,
      warrantyExpiry: map['warranty_expiry'] != null ? DateTime.parse(map['warranty_expiry']) : null,
      specifications: map['specifications'],
      notes:          map['notes'],
      createdAt:      DateTime.parse(map['created_at']),
      updatedAt:      DateTime.parse(map['updated_at']),
      categoryName:   map['categories'] is Map  ? map['categories']['name']  : null,
      laboratoryName: map['laboratories'] is Map ? map['laboratories']['name'] : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'name':           name,
    'category_id':    categoryId,
    'laboratory_id':  laboratoryId,
    'serial_number':  serialNumber,
    'model':          model,
    'brand':          brand,
    'quantity':       quantity,
    'unit_cost':      unitCost,
    'status':         status,
    'condition':      condition,
    'date_acquired':  dateAcquired?.toIso8601String().split('T')[0],
    'warranty_expiry':warrantyExpiry?.toIso8601String().split('T')[0],
    'specifications': specifications,
    'notes':          notes,
  };

  Color get statusColor {
    switch (status) {
      case 'active':       return const Color(0xFF22C55E);
      case 'inactive':     return const Color(0xFF94A3B8);
      case 'under_repair': return const Color(0xFFF59E0B);
      case 'disposed':     return const Color(0xFFEF4444);
      default:             return const Color(0xFF94A3B8);
    }
  }

  Color get conditionColor {
    switch (condition) {
      case 'excellent': return const Color(0xFF22C55E);
      case 'good':      return const Color(0xFF3B82F6);
      case 'fair':      return const Color(0xFFF59E0B);
      case 'poor':      return const Color(0xFFEF4444);
      default:          return const Color(0xFF94A3B8);
    }
  }
}

// ============================================================
// BORROWING RECORD
// ============================================================

/// The type of borrower: student, faculty, or staff.
/// Stored as a plain string in the DB (e.g. 'Student', 'Faculty', 'Staff').
const List<String> kBorrowerTypes = ['Student', 'Faculty', 'Staff'];

/// Colleges / departments for the department dropdown.
const List<String> kDepartments = [
  'College of Computer Studies',
  'College of Hospitality Management',
  'College of Agriculture and Forestry',
  'College of Criminal Justice Education',
  'College of Teacher Education',
];

class BorrowingRecord {
  final String id;
  final String equipmentId;
  final String borrowerName;
  /// Replaced email with borrowerType ('Student' | 'Faculty' | 'Staff').
  final String? borrowerType;
  final String? borrowerIdNumber;
  final String? department;
  final String? purpose;
  /// Only set when the equipment is a logbook/thesis book.
  final String? bookTitle;
  final int quantityBorrowed;
  final DateTime borrowDate;
  final DateTime? expectedReturnDate;
  final DateTime? actualReturnDate;
  final String status;
  final String? conditionOnReturn;
  final String? approvedBy;
  final String? notes;
  final DateTime createdAt;
  // Joined
  final String? equipmentName;
  /// The auth user id of the faculty member who submitted this request.
  final String? requestedByUserId;

  BorrowingRecord({
    required this.id,
    required this.equipmentId,
    required this.borrowerName,
    this.borrowerType,
    this.borrowerIdNumber,
    this.department,
    this.purpose,
    this.bookTitle,
    required this.quantityBorrowed,
    required this.borrowDate,
    this.expectedReturnDate,
    this.actualReturnDate,
    required this.status,
    this.conditionOnReturn,
    this.approvedBy,
    this.notes,
    required this.createdAt,
    this.equipmentName,
    this.requestedByUserId,
  });

  factory BorrowingRecord.fromMap(Map<String, dynamic> map) {
    // Determine effective status: auto-overdue when past expected return date.
    String status = map['status'] ?? 'borrowed';
    if (status == 'borrowed') {
      final expectedRaw = map['expected_return_date'];
      if (expectedRaw != null) {
        final expected = DateTime.parse(expectedRaw);
        final today = DateTime.now();
        if (today.isAfter(DateTime(expected.year, expected.month, expected.day + 1))) {
          status = 'overdue';
        }
      }
    }

    return BorrowingRecord(
      id:                  map['id'],
      equipmentId:         map['equipment_id'],
      borrowerName:        map['borrower_name'],
      // Support legacy records that stored email in borrower_email — map to borrowerType field.
      borrowerType:        map['borrower_type'] ?? map['borrower_email'],
      borrowerIdNumber:    map['borrower_id_number'],
      department:          map['department'],
      purpose:             map['purpose'],
      bookTitle:           map['book_title'],
      quantityBorrowed:    map['quantity_borrowed'] ?? 1,
      borrowDate:          DateTime.parse(map['borrow_date']),
      expectedReturnDate:  map['expected_return_date'] != null ? DateTime.parse(map['expected_return_date']) : null,
      actualReturnDate:    map['actual_return_date']   != null ? DateTime.parse(map['actual_return_date'])   : null,
      status:              status,
      conditionOnReturn:   map['condition_on_return'],
      approvedBy:          map['approved_by'],
      notes:               map['notes'],
      createdAt:           DateTime.parse(map['created_at']),
      equipmentName:       map['equipment']?['name'],
      requestedByUserId:   map['requested_by_user_id'],
    );
  }

  Map<String, dynamic> toMap() => {
    'equipment_id':          equipmentId,
    'borrower_name':         borrowerName,
    'borrower_type':         borrowerType,
    'borrower_id_number':    borrowerIdNumber,
    'department':            department,
    'purpose':               purpose,
    'book_title':            bookTitle,
    'quantity_borrowed':     quantityBorrowed,
    'borrow_date':           borrowDate.toIso8601String(),
    'expected_return_date':  expectedReturnDate?.toIso8601String(),
    'actual_return_date':    actualReturnDate?.toIso8601String(),
    'status':                status,
    'condition_on_return':   conditionOnReturn,
    'approved_by':           approvedBy,
    'notes':                 notes,
    'requested_by_user_id':  requestedByUserId,
  };
}

// ============================================================
// MAINTENANCE RECORD
// ============================================================
class MaintenanceRecord {
  final String id;
  final String equipmentId;
  final String maintenanceType;
  final String? description;
  final String? performedBy;
  final double cost;
  final DateTime maintenanceDate;
  final DateTime? nextMaintenanceDate;
  final String status;
  final String? notes;
  final DateTime createdAt;
  // Joined
  final String? equipmentName;

  MaintenanceRecord({
    required this.id,
    required this.equipmentId,
    required this.maintenanceType,
    this.description,
    this.performedBy,
    required this.cost,
    required this.maintenanceDate,
    this.nextMaintenanceDate,
    required this.status,
    this.notes,
    required this.createdAt,
    this.equipmentName,
  });

  factory MaintenanceRecord.fromMap(Map<String, dynamic> map) {
    return MaintenanceRecord(
      id:                   map['id'],
      equipmentId:          map['equipment_id'],
      maintenanceType:      map['maintenance_type'] ?? 'preventive',
      description:          map['description'],
      performedBy:          map['performed_by'],
      cost:                 (map['cost'] ?? 0).toDouble(),
      maintenanceDate:      DateTime.parse(map['maintenance_date']),
      nextMaintenanceDate:  map['next_maintenance_date'] != null ? DateTime.parse(map['next_maintenance_date']) : null,
      status:               map['status'] ?? 'completed',
      notes:                map['notes'],
      createdAt:            DateTime.parse(map['created_at']),
      equipmentName:        map['equipment']?['name'],
    );
  }

  Map<String, dynamic> toMap() => {
    'equipment_id':         equipmentId,
    'maintenance_type':     maintenanceType,
    'description':          description,
    'performed_by':         performedBy,
    'cost':                 cost,
    'maintenance_date':     maintenanceDate.toIso8601String().split('T')[0],
    'next_maintenance_date':nextMaintenanceDate?.toIso8601String().split('T')[0],
    'status':               status,
    'notes':                notes,
  };
}

// ============================================================
// APP NOTIFICATION
// ============================================================
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'under_repair', 'equipment_fixed'
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id:          map['id'],
      userId:      map['user_id'],
      title:       map['title'],
      message:     map['message'],
      type:        map['type'] ?? 'general',
      referenceId: map['reference_id'],
      isRead:      map['is_read'] ?? false,
      createdAt:   DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'user_id':      userId,
    'title':        title,
    'message':      message,
    'type':         type,
    'reference_id': referenceId,
    'is_read':      isRead,
  };
}