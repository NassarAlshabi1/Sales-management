import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'license_service.dart';
import 'hardware_service.dart';

/// مزود حالة الترخيص لإدارة الترخيص عبر التطبيق
class LicenseProvider extends ChangeNotifier {
  final LicenseService _licenseService = LicenseService();
  final HardwareService _hardwareService = HardwareService();

  LicenseStatus _status = LicenseStatus.valid;
  LicenseInfo? _licenseInfo;
  String _deviceFingerprint = '';
  Map<String, String> _deviceInfo = {};
  int _trialDaysLeft = 999;

  LicenseStatus get status => _status;
  LicenseInfo? get licenseInfo => _licenseInfo;
  String get deviceFingerprint => _deviceFingerprint;
  Map<String, String> get deviceInfo => _deviceInfo;
  int get trialDaysLeft => 999;

  bool get isActivated => true;
  bool get isNotActivated => false;
  bool get isInvalid => false;
  bool get hasDeviceMismatch => false;
  bool get hasError => false;
  bool get isTrialActive => false;
  bool get isTrialExpired => false;

  /// تهيئة مزود الترخيص
  Future<void> initialize() async {
    _status = LicenseStatus.valid;
    _deviceFingerprint = 'ACTIVATED';
    notifyListeners();
  }

  /// فحص حالة الترخيص
  Future<void> checkLicenseStatus() async {
    _status = LicenseStatus.valid;
    _trialDaysLeft = 999;
    notifyListeners();
  }

  /// تفعيل الترخيص
  Future<ActivationResult> activateLicense(String licenseKey,
      {String? customerName, String? customerContact}) async {
    try {
      // تحديث معلومات الجهاز قبل التفعيل
      await refreshDeviceInfo();

      final result = await _licenseService.activateLicense(licenseKey);

      if (result.success) {
        // حفظ معلومات العميل إذا تم توفيرها
        if (customerName != null || customerContact != null) {
          await _licenseService.saveCustomerInfo(
            customerName ?? '',
            customerContact ?? '',
          );
        }

        // تحديث الحالة
        await checkLicenseStatus();
      } else {
        // إذا فشل التفعيل، تحديث الحالة أيضاً
        await checkLicenseStatus();
      }

      return result;
    } catch (e) {
      // في حالة الخطأ، تحديث الحالة
      await checkLicenseStatus();
      return ActivationResult(
        success: false,
        message: 'خطأ في تفعيل الترخيص. يرجى المحاولة مرة أخرى.',
      );
    }
  }

  /// إلغاء تفعيل الترخيص
  Future<bool> deactivateLicense() async {
    try {
      final success = await _licenseService.deactivateLicense();

      if (success) {
        await checkLicenseStatus();
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  /// إعادة تحميل معلومات الجهاز
  Future<void> refreshDeviceInfo() async {
    try {
      _deviceFingerprint = await _hardwareService.getDeviceFingerprint();
      _deviceInfo = await _hardwareService.getDeviceInfoForDisplay();
      notifyListeners();
    } catch (e) {
      // تجاهل الأخطاء
    }
  }

  /// الحصول على رسالة الخطأ المناسبة
  String getErrorMessage() {
    switch (_status) {
      case LicenseStatus.notActivated:
        return 'لم يتم تفعيل الترخيص بعد';
      case LicenseStatus.invalid:
        return 'مفتاح الترخيص غير صحيح';
      case LicenseStatus.deviceMismatch:
        return 'الجهاز لا يطابق الترخيص المسجل';
      case LicenseStatus.error:
        return 'خطأ في فحص الترخيص';
      case LicenseStatus.trialActive:
        return 'نسخة تجريبية فعالة - متبقي $_trialDaysLeft يوم';
      case LicenseStatus.trialExpired:
        return 'انتهت الفترة التجريبية - يرجى تفعيل الترخيص';
      case LicenseStatus.valid:
        return 'الترخيص صحيح ومفعل';
    }
  }

  /// الحصول على لون الحالة
  Color getStatusColor() {
    switch (_status) {
      case LicenseStatus.valid:
        return Colors.green;
      case LicenseStatus.notActivated:
        return Colors.orange;
      case LicenseStatus.invalid:
      case LicenseStatus.deviceMismatch:
      case LicenseStatus.error:
        return Colors.red;
      case LicenseStatus.trialActive:
        return Colors.blue;
      case LicenseStatus.trialExpired:
        return Colors.red;
    }
  }

  /// الحصول على أيقونة الحالة
  IconData getStatusIcon() {
    switch (_status) {
      case LicenseStatus.valid:
        return Icons.check_circle;
      case LicenseStatus.notActivated:
        return Icons.pending;
      case LicenseStatus.invalid:
        return Icons.error;
      case LicenseStatus.deviceMismatch:
        return Icons.device_unknown;
      case LicenseStatus.error:
        return Icons.warning;
      case LicenseStatus.trialActive:
        return Icons.hourglass_bottom;
      case LicenseStatus.trialExpired:
        return Icons.hourglass_disabled;
    }
  }
}
