# Riskli Ağaç Takip ve Müdahale Sistemi

Trabzon Büyükşehir Belediyesi bünyesinde, şehir genelindeki kurumuş, hastalıklı, devrilme riski taşıyan, budama ihtiyacı olan veya fırtına öncesi risk oluşturan ağaçların takibi ve müdahale sürecinin yönetilmesi amacıyla geliştirilmiş bir mobil uygulamadır.

Uygulama tek bir Flutter projesi içinde, rol bazlı yönlendirme ile üç farklı kullanıcı tipine hizmet verir: **Vatandaş**, **Yetkili Personel** ve **Saha Ekibi**.

---

## İçindekiler

- [Genel Bakış](#genel-bakış)
- [Kullanıcı Rolleri ve Özellikler](#kullanıcı-rolleri-ve-özellikler)
- [Teknoloji Yığını](#teknoloji-yığını)
- [Klasör Mimarisi](#klasör-mimarisi)
- [State Management Yaklaşımı](#state-management-yaklaşımı)
- [Kullanılan Paketler (pubspec.yaml)](#kullanılan-paketler-pubspecyaml)
- [Firebase Yapılandırması](#firebase-yapılandırması)
- [Veritabanı Şeması](#veritabanı-şeması)
- [Kurulum Adımları](#kurulum-adımları)
- [Bilinen Sınırlamalar](#bilinen-sınırlamalar)

---

## Genel Bakış

Sistem, üç ana iş akışını birbirine bağlar:

1. **Vatandaş**, gördüğü riskli bir ağacı konum, fotoğraf/video/belge ve açıklama ile bildirir.
2. **Yetkili Personel** (Park ve Bahçeler, Fen İşleri, Afet Koordinasyon, Çağrı Merkezi gibi kurumlardan), gelen bildirimleri inceler, risk seviyesi atar ve ilgili saha ekibine görev atar.
3. **Saha Ekibi**, kendisine atanan görevleri görüntüler, sahada gerekli müdahaleyi (budama, dal temizleme, destekleme, kesme, kontrol) yapar ve kanıt (fotoğraf/video/belge) ile birlikte kaydı tamamlar.

Tüm veri akışı Firebase Firestore üzerinde gerçek zamanlı olarak senkronize edilir.

---

## Kullanıcı Rolleri ve Özellikler

### Vatandaş
- Telefon numarası + OTP (SMS) ile giriş
- Riskli ağaç bildirimi oluşturma (GPS ile veya haritadan manuel konum seçimi)
- Fotoğraf, video ve belge ekleme
- Kendi bildirimlerini ve durumlarını takip etme (Beklemede / İncelendi / Görev Atandı / Müdahale Edildi / Kapatıldı)
- Profil yönetimi (avatar seçimi, bilgi güncelleme, hesap silme)

### Yetkili Personel
- E-posta + şifre ile giriş
- Ana sayfa: durum bazlı istatistikler, acil/yüksek riskli bildirim uyarıları, son bildirimler
- Bildirim listesi (durum filtreleme ile)
- Bildirim inceleme: risk seviyesi atama (Düşük/Orta/Yüksek/Acil) veya kaydı kapatma
- Görev atama: saha personeli seçimi ve öncelik belirleme
- Harita görünümü: tüm bildirimlerin durum bazlı renkli pinlerle gösterimi, normal/uydu/hibrit görünüm, sağ panelden bildirim listesi
- Personel yönetimi: yeni personel (yetkili/saha personeli) ekleme, mevcut personeli listeleme/düzenleme/silme
- Kurum yönetimi: kurum ekleme, listeleme, silme
- Profil yönetimi

### Saha Ekibi
- E-posta + şifre ile giriş (Yetkili ile aynı giriş sistemi, rol bazlı yönlendirme)
- Ana sayfa: görev durumu istatistikleri, bekleyen görevler özeti
- Görevlerim listesi
- Görev detayı: ilgili bildirimin tüm bilgilerini görüntüleme
- Müdahale formu: yapılan işlem seçimi, öncesi/sonrası fotoğraf, video kaydı, belge ekleme, açıklama (min. 10 karakter)
- Profil yönetimi

---

## Teknoloji Yığını

| Katman | Teknoloji |
|---|---|
| Uygulama Çatısı | Flutter (Dart) |
| Kimlik Doğrulama | Firebase Authentication (Phone + Email/Password) |
| Veritabanı | Cloud Firestore |
| Dosya Depolama | Firebase Storage |
| Harita | Google Maps Platform (`google_maps_flutter`) |
| Konum Servisleri | `geolocator`, `geocoding` |

---

## Klasör Mimarisi

Proje, **feature-based (özellik bazlı)** bir klasör yapısı kullanır. Ortak altyapı (`core`, `models`, `services`) tüm roller tarafından paylaşılırken, her rolün ekranları kendi `features/` alt klasöründe izole edilmiştir.

```
lib/
├── main.dart                      # Uygulama giriş noktası, tema ve Firebase başlatma
├── firebase_options.dart          # FlutterFire CLI tarafından otomatik oluşturulur
│
├── core/
│   ├── theme/
│   │   └── app_theme.dart         # Kurumsal renk paleti, tipografi, bileşen temaları
│   └── router/
│       └── auth_gate.dart         # Giriş durumuna göre rol bazlı yönlendirme
│
├── models/                        # Firestore verisinin Dart karşılıkları
│   ├── kullanici_model.dart
│   ├── kurum_model.dart
│   ├── bildirim_model.dart
│   ├── gorev_model.dart
│   └── mudahale_model.dart
│
├── services/                      # Firebase ile iletişim kuran katman
│   ├── auth_service.dart          # Giriş, kayıt, çıkış, personel ekleme
│   ├── firestore_service.dart     # Tüm CRUD ve stream sorguları
│   ├── storage_service.dart       # Fotoğraf/video/belge yükleme
│   └── location_service.dart      # GPS konumu ve reverse geocoding
│
└── features/
    ├── auth/
    │   └── screens/
    │       └── login_screen.dart          # Tek ekranda açılır/kapanır giriş panelleri
    │
    ├── vatandas/
    │   └── screens/
    │       ├── vatandas_home_screen.dart      # Sekmeli dashboard (PageView + BottomNav)
    │       ├── vatandas_anasayfa_view.dart
    │       ├── bildirimlerim_view.dart
    │       ├── bildirim_form_screen.dart
    │       └── konum_duzenle_screen.dart      # Haritadan manuel konum seçimi
    │
    ├── yetkili/
    │   └── screens/
    │       ├── yetkili_dashboard_screen.dart
    │       ├── yetkili_anasayfa_view.dart
    │       ├── bildirim_listesi_screen.dart
    │       ├── bildirim_inceleme_screen.dart
    │       ├── gorev_atama_screen.dart
    │       ├── harita_screen.dart
    │       ├── personel_listesi_screen.dart
    │       ├── personel_ekle_screen.dart
    │       ├── personel_duzenle_screen.dart
    │       ├── kurum_listesi_screen.dart
    │       └── profil_screen.dart              # Yetkili ve Saha Ekibi tarafından ortak kullanılır
    │
    └── saha_ekibi/
        └── screens/
            ├── saha_ekibi_dashboard_screen.dart
            ├── saha_anasayfa_view.dart
            ├── gorevlerim_screen.dart
            ├── gorev_detay_screen.dart
            └── mudahale_form_screen.dart
```

---

## State Management Yaklaşımı

Bu projede harici bir state management paketi (Provider, Riverpod, Bloc vb.) **kullanılmamıştır**. Bunun yerine Flutter'ın kendi yerleşik araçları tercih edilmiştir:

- **`StatefulWidget` + `setState`**: Form alanları, yükleniyor durumları, açık/kapalı panel durumları gibi yerel (local) UI durumları için kullanılmıştır.
- **`StreamBuilder`**: Firestore koleksiyonlarını (bildirimler, görevler, personel listesi vb.) gerçek zamanlı dinlemek için kullanılmıştır. Bir veri değiştiğinde arayüz otomatik olarak güncellenir, manuel yenileme gerekmez.
- **`FutureBuilder`**: Tek seferlik asenkron veri çekme işlemleri (örneğin bir bildirimin detayını getirme) için kullanılmıştır.
- **`PageView` + `BottomNavigationBar`**: Her rolün dashboard'unda sekmeler arası geçiş için kullanılmıştır; sekme durumu (`_secilenSekme`) dashboard widget'ının kendi state'inde tutulur.

Bu yaklaşımın tercih edilme sebebi, projenin ölçeğinde (orta büyüklükte, ekranlar arası karmaşık paylaşımlı state olmadan) ekstra bir state management kütüphanesinin gereksiz karmaşıklık yaratacak olmasıdır. Firebase'in kendisi zaten `Stream` tabanlı olduğu için, `StreamBuilder` ile doğrudan entegrasyon hem daha az kod hem de daha az bağımlılık anlamına gelmiştir.

---

## Kullanılan Paketler (pubspec.yaml)

| Paket | Amaç |
|---|---|
| `firebase_core` | Firebase'i uygulamaya bağlamak için temel paket |
| `firebase_auth` | Telefon (OTP) ve e-posta/şifre ile kimlik doğrulama |
| `cloud_firestore` | Gerçek zamanlı veritabanı işlemleri |
| `firebase_storage` | Fotoğraf, video ve belge dosyalarının depolanması |
| `geolocator` | Cihazın GPS konumunu alma |
| `geocoding` | Koordinatları okunabilir adrese çevirme (reverse geocoding) |
| `image_picker` | Kameradan fotoğraf/video çekme, galeriden seçme |
| `file_picker` | PDF, Word, Excel gibi belge dosyalarını seçme |
| `google_maps_flutter` | Harita görüntüleme, pin ekleme, dokunma/sürükleme etkileşimleri |
| `flutter_svg` | Giriş ekranındaki logonun SVG formatında gösterimi |
| `cupertino_icons` | iOS tarzı ikon seti (Flutter varsayılanı) |
| `flutter_launcher_icons` *(dev)* | Uygulama simgesinin (app icon) otomatik oluşturulması |

> Tam sürüm numaraları için projenin `pubspec.yaml` dosyasına bakınız.

---

## Firebase Yapılandırması

### 1. Firebase Projesi Oluşturma
[Firebase Console](https://console.firebase.google.com) üzerinden yeni bir proje oluşturuldu (`riskli-agac-takip`).

### 2. FlutterFire CLI ile Bağlama
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
Bu komut, `android` ve `ios` platformları seçilerek çalıştırılmış, `lib/firebase_options.dart` dosyası otomatik oluşturulmuştur.

### 3. Authentication
Firebase Console → Authentication → Sign-in method üzerinden şu sağlayıcılar etkinleştirilmiştir:
- **Phone** (Vatandaş girişi için)
- **Email/Password** (Yetkili ve Saha Ekibi girişi için)

Geliştirme sürecinde gerçek SMS kotasını korumak amacıyla "Phone numbers for testing" bölümünden test numaraları tanımlanmıştır.

### 4. Firestore Database
- **Konum**: Avrupa bölgesi (Frankfurt / europe-west3)
- **Mod**: Production mode
- Güvenlik kuralları (`firestore.rules`), her koleksiyon için rol bazlı okuma/yazma izinlerini tanımlar (örn. bir vatandaş yalnızca kendi bildirimini okuyabilir, sadece yetkili risk seviyesi atayabilir).
- Bazı sorgular (`where` + `orderBy` kombinasyonu) için Firebase Console üzerinden composite index'ler oluşturulmuştur.

### 5. Storage
- Fotoğraf, video ve belge dosyaları için etkinleştirilmiştir (Blaze plan gereklidir).
- Güvenlik kuralları, yalnızca giriş yapmış kullanıcıların dosya yükleyip okuyabilmesine izin verir; dosya boyutu 50MB ile sınırlandırılmıştır.

### 6. Google Maps API
Google Cloud Console üzerinden "Maps SDK for Android" etkinleştirilmiş, oluşturulan API anahtarı `android/app/src/main/AndroidManifest.xml` içine eklenmiştir.

---

## Veritabanı Şeması

Firestore üzerinde birbiriyle ilişkili yedi ana koleksiyon kullanılmaktadır:

| Koleksiyon | Açıklama |
|---|---|
| `Kullanicilar` | Tüm kullanıcılar (vatandaş, yetkili, saha personeli), rol ve avatar bilgisiyle birlikte |
| `Kurumlar` | Belediye birimleri (Park ve Bahçeler, Fen İşleri vb.) |
| `Bildirimler` | Vatandaşlar tarafından oluşturulan riskli ağaç bildirimleri |
| `Gorevler` | Yetkili tarafından saha personeline atanan görevler |
| `Mudahaleler` | Saha personeli tarafından tamamlanan müdahale kayıtları |
| `DurumGecmisi` | Bildirim durum değişikliklerinin denetim (audit) kaydı |
| `AnlikBildirimler` | Kullanıcılara gönderilen bildirim/notification kayıtları |

Koleksiyonlar arası ilişkiler (örn. `Bildirimler.bildirenKullaniciId → Kullanicilar`) doküman ID referansları ile sağlanır.

---

## Kurulum Adımları

```bash
# 1. Depoyu klonla
git clone <repo-url>
cd riskli_agac_takip

# 2. Bağımlılıkları yükle
flutter pub get

# 3. Firebase'i bağla (kendi Firebase projenle)
flutterfire configure

# 4. Uygulamayı çalıştır
flutter run
```

> Not: `lib/firebase_options.dart` ve `android/app/google-services.json` dosyaları güvenlik nedeniyle `.gitignore` ile depo dışında tutulabilir; bu durumda her geliştirici kendi `flutterfire configure` komutunu çalıştırmalıdır.

---

## Bilinen Sınırlamalar

- Personel silme işlemi yalnızca Firestore profil dokümanını kaldırır; ilgili Firebase Authentication hesabı, istemci (client) SDK'nın yetkisi dışında olduğu için silinmez. Bu işlem için Firebase Admin SDK / Cloud Functions gerekir.
- Avatar sistemi, gerçek fotoğraf yükleme yerine önceden tanımlanmış 6 adet hazır görsel arasından seçim şeklinde çalışır.
- Uygulama şu an yalnızca Android platformu için test edilmiştir.

---

## Geliştirici

Bu proje, Trabzon Büyükşehir Belediyesi bünyesinde yürütülen staj kapsamında tek bir geliştirici tarafından sıfırdan tasarlanmış ve geliştirilmiştir.
