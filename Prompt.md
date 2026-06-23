Windows ortamında çalışacak, modern, hızlı ve sade bir "Muhtarlık Tebligat Takip Sistemi" geliştir.

Amaç:
Muhtarlığa gelen tebligatların kayıt altına alınması, geçmiş yıllara ait kayıtların saklanması, vatandaş geldiğinde hızlı şekilde bulunması, teslim bilgilerinin kaydedilmesi ve arşiv yönetiminin yapılması.

Teknoloji:

* Flutter Desktop (Windows)
* SQLite veritabanı
* Türkçe arayüz
* Tek kullanıcı veya çoklu kullanıcı desteği
* Tek EXE olarak dağıtılabilsin
* Sunucu gerektirmesin

Genel Tasarım:

* Büyük ve okunaklı butonlar
* Sade ve hızlı kullanım
* Veri giriş ekranlarında minimum tıklama
* Koyu ve açık tema desteği
* Türkçe karakter desteği

Kullanıcı Rolleri:

* Yönetici
* Personel

Giriş Sistemi:

* Kullanıcı adı ve şifre ile giriş
* Tüm işlemler loglanmalı

Veritabanı Tasarımı:

Tablo: Evraklar

* id (integer primary key)
* gelis_tarihi
* ad_soyad
* geldigi_kurum
* evrak_sayisi
* durum
* teslim_tarihi
* olusturma_tarihi
* guncelleme_tarihi

Durum Alanı:

* Bekliyor
* Teslim Edildi
* Arşivlendi

Durum Açıklamaları:

Bekliyor:
Vatandaşa henüz teslim edilmemiş aktif evrak.

Teslim Edildi:
Vatandaş veya yakını tarafından teslim alınmış evrak.

Arşivlendi:
Teslim alınmamış ancak önceki yıllardan kalan veya aktif işlem süresi geçmiş kayıtlar.

Tablo: TeslimKayitlari

* id (integer primary key)
* evrak_id
* teslim_alan_ad_soyad
* tc_kimlik_no
* telefon
* teslim_tarihi
* aciklama

Ana Menü:

1. Yeni Evrak Kaydı
2. Evrak Ara
3. Bekleyen Evraklar
4. Teslim Edilen Evraklar
5. Arşivlenen Evraklar
6. Raporlar
7. Yedekleme
8. Ayarlar

Yeni Evrak Kaydı Ekranı:

Alanlar:

* Geliş Tarihi (varsayılan bugün)
* Ad Soyad
* Geldiği Kurum
* Evrak Sayısı

Kaydet butonu

Kaydedilen evrakın durumu otomatik olarak "Bekliyor" olmalıdır.

Evrak Arama Ekranı:

Canlı filtreleme desteklenmeli.

Arama kriterleri:

* Ad Soyad
* Evrak Sayısı
* Geldiği Kurum
* Tarih Aralığı
* Durum

Arama sonuçları DataGrid üzerinde gösterilmeli.

Kolonlar:

* Ad Soyad
* Geldiği Kurum
* Evrak Sayısı
* Geliş Tarihi
* Durum

Kayıt üzerine çift tıklanınca detay ekranı açılmalı.

Teslim İşlemi:

Bekleyen evrak seçildiğinde aşağıdaki bilgiler girilebilmeli:

* Teslim Alan Ad Soyad
* T.C. Kimlik No
* Telefon
* Açıklama

Kaydet butonuna basıldığında:

* Evrak durumu "Teslim Edildi" olarak güncellensin.
* Teslim tarihi otomatik kaydedilsin.
* TeslimKayitlari tablosuna kayıt oluşturulsun.

Arşivleme İşlemi:

Kullanıcı seçilen kayıtları manuel olarak "Arşivlendi" durumuna alabilsin.

Arşivlenen kayıtlar silinmemeli.

Arşivlenen kayıtlar ayrı ekranda görüntülenebilmeli.

Arşivlenen kayıtlar gerektiğinde tekrar "Bekliyor" durumuna döndürülebilmeli.

Raporlar:

* Toplam Evrak Sayısı
* Bekleyen Evrak Sayısı
* Teslim Edilen Evrak Sayısı
* Arşivlenen Evrak Sayısı

Filtreler:

* Günlük
* Aylık
* Yıllık
* Tarih Aralığı

Çıktılar:

* Excel'e Aktar
* PDF'e Aktar

Performans Gereksinimleri:

* 500.000+ kayıt ile sorunsuz çalışabilmeli.
* Ad Soyad alanında indeks oluşturulmalı.
* Evrak Sayısı alanında indeks oluşturulmalı.
* Durum alanında indeks oluşturulmalı.
* Sayfalama (pagination) kullanılmalı.
* Tüm kayıtlar aynı anda yüklenmemeli.

Yedekleme:

* SQLite veritabanını tek dosya olarak yedekle.
* Geri yükleme özelliği bulunsun.
* Otomatik günlük yedekleme seçeneği bulunsun.

İçe Aktarma:

Mevcut Excel kayıtları sisteme aktarılabilmeli.

Excel kolonları:

* Tarih
* Ad Soyad
* Geldiği Yer
* Sayı
* T.C. Kimlik No
* Telefon No
* Evrakı Alan
* Tarih

Excel'den toplu aktarım sihirbazı oluştur.

Log Sistemi:

Aşağıdaki işlemler loglansın:

* Evrak ekleme
* Evrak güncelleme
* Evrak teslim etme
* Evrak arşivleme
* Evrak silme
* Kullanıcı girişleri

Silme Politikası:

Kayıtlar fiziksel olarak silinmemeli.

Silinen kayıtlar için:

* silindi_mi
* silinme_tarihi

alanları kullanılmalı.

Arayüz Tasarımı:

Sol tarafta menü.
Sağ tarafta çalışma alanı.
Üst bölümde hızlı arama kutusu.

Ana ekranda kartlar halinde göster:

* Bekleyen Evraklar
* Teslim Edilen Evraklar
* Arşivlenen Evraklar
* Toplam Evraklar

Kod üretirken:

* Katmanlı mimari kullan.
* Repository Pattern kullan.
* SQLite işlemlerini servis katmanında yönet.
* Türkçe karakter sorunlarına karşı UTF-8 desteği kullan.
* Kodları modüler şekilde oluştur.
* Tüm ekranlar Flutter Desktop için optimize edilmiş olsun.
