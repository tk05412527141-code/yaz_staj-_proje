import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_veri;
import 'package:timezone/timezone.dart' as tz;

/// Cihaz uzerinde yerel bildirim gonderen servis.
///
/// NE YAPAR, NE YAPMAZ
///   Bu servis SADECE cihazin kendi zamanlayicisini kullanir. Sunucu yok,
///   internet gerekmez. Bu yuzden yalnizca ONCEDEN BILINEN zamanlar icin
///   bildirim gonderebilir — yani hazirlik hatirlatmalari.
///
///   Deprem OLDUKTAN sonra bildirim gondermek icin sunucu tarafi gerekir
///   (bir servis surekli API'yi izleyip itmeli bildirim gonderir).
///   Deprem OLMADAN once uyarmak — yani tahmin — bilimsel olarak mumkun
///   degildir; bkz. erken_uyari_ekrani.dart
///
/// SURUM NOTU
///   flutter_local_notifications ^19.0.0 API'si kullaniliyor.
///   20.x tum parametreleri adlandirilmisa cevirdi, 21.x Flutter 3.38
///   istiyor. Bu yuzden 19.x'e sabitlendi; pubspec'te ^19.0.0 yazili.
class BildirimServisi {
  const BildirimServisi._();

  static final _eklenti = FlutterLocalNotificationsPlugin();

  static bool _hazir = false;
  static bool get hazir => _hazir;

  /// Hazirlik hatirlatmalari icin Android bildirim kanali.
  static const _kanalKimlik = 'hazirlik_hatirlatmalari';
  static const _kanalAd = 'Hazırlık hatırlatmaları';
  static const _kanalAciklama =
      'Deprem çantası, tatbikat ve ev güvenliği hatırlatmaları';

  /// Uygulama Turkiye odakli oldugu icin sabit saat dilimi kullaniyoruz.
  /// Boylece ek bir paket (flutter_timezone) gerekmiyor.
  static const _saatDilimi = 'Europe/Istanbul';

  // ------------------------------------------------------------------
  // Baslatma
  // ------------------------------------------------------------------

  /// Uygulama acilirken bir kez cagrilir.
  ///
  /// Hata durumunda sessizce false doner: bildirimler calismasa bile
  /// uygulamanin geri kalani calismaya devam etmeli.
  static Future<bool> baslat() async {
    if (_hazir) return true;

    try {
      // Zaman dilimi veritabani - zamanlanmis bildirimler icin sart
      tz_veri.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(_saatDilimi));

      const androidAyar = AndroidInitializationSettings('@mipmap/ic_launcher');
      const appleAyar = DarwinInitializationSettings(
        // Izni acilista degil, kullanici ilgili ekrana geldiginde
        // isteyecegiz. Sebepsiz izin istemi kabul oranini dusurur.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _eklenti.initialize(
        const InitializationSettings(android: androidAyar, iOS: appleAyar),
      );

      await _kanaliOlustur();

      _hazir = true;
      return true;
    } catch (e) {
      debugPrint('BildirimServisi baslatilamadi: $e');
      return false;
    }
  }

  static Future<void> _kanaliOlustur() async {
    final android = _eklenti.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _kanalKimlik,
        _kanalAd,
        description: _kanalAciklama,
        importance: Importance.defaultImportance,
      ),
    );
  }

  // ------------------------------------------------------------------
  // Izinler
  // ------------------------------------------------------------------

  /// Bildirim izni ister. Kullanici reddederse false doner.
  static Future<bool> izinIste() async {
    if (!await baslat()) return false;

    try {
      if (Platform.isAndroid) {
        final android = _eklenti.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        // Android 13 (API 33) oncesinde izin gerekmiyor, null doner
        final sonuc = await android?.requestNotificationsPermission();
        return sonuc ?? true;
      }

      if (Platform.isIOS) {
        final apple = _eklenti.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final sonuc = await apple?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return sonuc ?? false;
      }

      return false;
    } catch (e) {
      debugPrint('Bildirim izni istenemedi: $e');
      return false;
    }
  }

  /// Izin verilmis mi? (Android 13 oncesi her zaman true)
  static Future<bool> izinVarMi() async {
    if (!await baslat()) return false;

    try {
      if (Platform.isAndroid) {
        final android = _eklenti.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.areNotificationsEnabled() ?? false;
      }

      if (Platform.isIOS) {
        final apple = _eklenti.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final durum = await apple?.checkPermissions();
        return durum?.isEnabled ?? false;
      }

      return false;
    } catch (e) {
      debugPrint('Bildirim izni okunamadi: $e');
      return false;
    }
  }

  // ------------------------------------------------------------------
  // Zamanlama
  // ------------------------------------------------------------------

  static NotificationDetails _ayrintilar() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _kanalKimlik,
        _kanalAd,
        channelDescription: _kanalAciklama,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        // Uzun metinler kirpilmadan gorunsun
        styleInformation: BigTextStyleInformation(''),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Belirli bir tarihte gosterilecek bildirim planlar.
  ///
  /// [ne] gecmiste kaliyorsa hicbir sey yapmaz.
  static Future<bool> planla({
    required int id,
    required String baslik,
    required String govde,
    required DateTime ne,
  }) async {
    if (!await baslat()) return false;

    final hedef = tz.TZDateTime.from(ne, tz.local);
    if (!hedef.isAfter(tz.TZDateTime.now(tz.local))) return false;

    try {
      await _eklenti.zonedSchedule(
        id,
        baslik,
        govde,
        hedef,
        _ayrintilar(),
        // inexact: SCHEDULE_EXACT_ALARM izni gerektirmez. Hazirlik
        // hatirlatmalarinda dakika hassasiyeti gerekmedigi icin dogru
        // secim; sistem pil dostu bir zamanda gonderir.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return true;
    } catch (e) {
      debugPrint('Bildirim planlanamadi (id=$id): $e');
      return false;
    }
  }

  /// Hemen bir bildirim gosterir (ayarlardaki "test et" icin).
  static Future<bool> hemenGoster({
    required int id,
    required String baslik,
    required String govde,
  }) async {
    if (!await baslat()) return false;
    try {
      await _eklenti.show(id, baslik, govde, _ayrintilar());
      return true;
    } catch (e) {
      debugPrint('Bildirim gosterilemedi: $e');
      return false;
    }
  }

  static Future<void> iptalEt(int id) async {
    if (!_hazir) return;
    try {
      await _eklenti.cancel(id);
    } catch (e) {
      debugPrint('Bildirim iptal edilemedi (id=$id): $e');
    }
  }

  static Future<void> tumunuIptalEt() async {
    if (!_hazir) return;
    try {
      await _eklenti.cancelAll();
    } catch (e) {
      debugPrint('Bildirimler iptal edilemedi: $e');
    }
  }

  /// Planlanmis ama henuz gonderilmemis bildirimler.
  /// Ayarlar ekraninda "sonraki hatirlatma" gostermek icin kullaniliyor.
  static Future<List<PendingNotificationRequest>> bekleyenler() async {
    if (!await baslat()) return const [];
    try {
      return await _eklenti.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Bekleyen bildirimler okunamadi: $e');
      return const [];
    }
  }
}
