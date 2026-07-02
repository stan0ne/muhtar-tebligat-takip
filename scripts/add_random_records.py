"""
Veritabanına rastgele evrak kayıtları ekler.
Kullanım: python scripts/add_random_records.py <veritabanı_yolu> <adet>
"""
import sqlite3
import random
import sys
import os
from datetime import datetime, timedelta

# Türkçe isimler
ERKEK_ISIMLER = [
    'Mehmet', 'Mustafa', 'Ahmet', 'Ali', 'Hasan', 'Hüseyin', 'İbrahim',
    'Ömer', 'Yusuf', 'Emre', 'Burak', 'Oğuz', 'Kemal', 'Selim', 'Tolga',
    'Cemal', 'Cemil', 'Murat', 'Fatih', 'Serkan', 'Onur', 'Gökhan', 'Serhat',
    'Bülent', 'Cengiz', 'Koray', 'Tuncer', 'Volkan', 'Sinan', 'Erhan', 'Levent',
    'Yasin', 'Osman', 'Ramazan', 'Süleyman', 'Abdullah', 'Mikail', 'Enes', 'Batuhan',
    'Kaan', 'Arda', 'Eren', 'Yiğit', 'Berk', 'Ozan', 'Furkan', 'Görkem', 'Umut'
]

KIZ_ISIMLER = [
    'Fatma', 'Ayşe', 'Emine', 'Zeynep', 'Elif', 'Merve', 'Büşra', 'Seda',
    'Eda', 'Deniz', 'Aslı', 'Gamze', 'Pınar', 'Selin', 'Burcu', 'Gülşen',
    'Songül', 'Nurgül', 'Emel', 'Yasemin', 'Ebru', 'Melek', 'Didem', 'Ceren',
    'Tuğba', 'Özlem', 'Sinem', 'Nihan', 'Kübra', 'Hatice', 'Hacer', 'Aysel',
    'Sevim', 'Gülistan', 'Leyla', 'Müjde', 'Birsen', 'Jale', 'Seval', 'Tülay'
]

SOYADLAR = [
    'Yılmaz', 'Kaya', 'Demir', 'Çelik', 'Şahin', 'Yıldız', 'Yıldırım',
    'Öztürk', 'Aydın', 'Özdemir', 'Arslan', 'Doğan', 'Kılıç', 'Aslan',
    'Çetin', 'Kara', 'Koç', 'Kurt', 'Özkan', 'Şimşek', 'Polat', 'Karaca',
    'Erdem', 'Güneş', 'Yalçın', 'Taş', 'Bulut', 'Acar', 'Bayrak', 'Erdoğan',
    'Gül', 'Tekin', 'Tanrıkulu', 'Balkan', 'Acar', 'Baykal', 'Karabacak',
    'Sonmez', 'Akgül', 'Tosun', 'Başaran', 'Güven', 'Kaplan', 'Aksoy',
    'Birkan', 'Turan', 'Korkmaz', 'Balcı', 'Ersoy', 'Gürsoy', 'Mertoğlu'
]

KURUMLAR = [
    'Antalya Büyükşehir Belediyesi', 'Konyaaltı Belediyesi', 'Muratpaşa Belediyesi',
    'Kepez Belediyesi', 'Aksu Belediyesi', 'Döşemealtı Belediyesi',
    'Antalya Valiliği', 'İl Nüfus Müdürlüğü', 'Tapu ve Kadastro',
    'Antalya Adliyesi', 'Emniyet Müdürlüğü', 'Jandarma Komutanlığı',
    'SGK İl Müdürlüğü', 'İl Sağlık Müdürlüğü', 'İl Milli Eğitim Müdürlüğü',
    'Antalya Trafik Denetleme', 'Devlet Malzeme Ofisi', 'Defterdarlık',
    'Gıda Tarım ve Hayvancılık İl Müdürlüğü', 'Çevre ve Şehircilik İl Müdürlüğü',
    'Karayolları 13. Bölge Müdürlüğü', 'DSİ 13. Bölge Müdürlüğü',
    'Meteoroloji 7. Bölge Müdürlüğü', 'Türkiye İş Kurumu', 'Kadastro Müdürlüğü',
    'Nüfus ve Vatandaşlık İşleri', 'Göç İdaresi Müdürlüğü', 'İl Emniyet Müdürlüğü',
    'Belediye Zabıta Müdürlüğü', 'İl Jandarma Komutanlığı'
]

ACIKLAMALAR = [
    'Bilgi talebi', 'Talep dilekçesi', 'İtiraz dilekçesi', 'Bilgi edinme',
    'Şikayet dilekçesi', 'Müracaat', 'Başvuru', 'Talep', 'Dilekçe',
    'İş talebi', 'Ruhsat başvurusu', 'İzin talebi', 'Proje onayı',
    'Denetim raporu', 'Tebliğ', 'İhbar', 'Bildirim', 'Onay',
    'Staj başvurusu', 'Referans mektubu', 'Görüş yazısı', 'Karar',
    'Seminer başvurusu', 'Eğitim talebi', 'Kayıt yenileme'
]


def random_date():
    """Rastgele bir tarih döndürür (son 2 yıl içinde)."""
    now = datetime.now()
    days_ago = random.randint(1, 730)
    d = now - timedelta(days=days_ago)
    return d.strftime('%Y-%m-%d')


def random_phone():
    """Rastgele telefon numarası."""
    return f'0{random.choice([530,531,532,533,534,535,536,537,538,539,540,541,542,543,544,545])}{random.randint(1000000,9999999)}'


def random_tc():
    """Rastgele TC kimlik no (11 haneli)."""
    first = str(random.randint(1, 9))
    rest = ''.join([str(random.randint(0, 9)) for _ in range(10)])
    return first + rest


def random_evrak_no():
    """Rastgele evrak numarası."""
    prefix = random.choice(['E', 'B', 'M', 'T', 'İ'])
    year = random.choice([2024, 2025, 2026])
    num = random.randint(1, 9999)
    return f'{prefix}{year}/{num}'


def main():
    if len(sys.argv) < 3:
        print("Kullanım: python scripts/add_random_records.py <veritabanı_yolu> <adet>")
        sys.exit(1)

    db_path = sys.argv[1]
    count = int(sys.argv[2])

    if not os.path.exists(db_path):
        print(f"Hata: {db_path} bulunamadı.")
        sys.exit(1)

    from datetime import datetime, timedelta

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Mevcut kayıt sayısını al
    cursor.execute("SELECT COUNT(*) FROM Evraklar WHERE silindi_mi = 0")
    mevcut = cursor.fetchone()[0]
    print(f"Mevcut kayıt sayısı: {mevcut}")

    eklenen = 0
    for _ in range(count):
        # İsim üret
        isim = random.choice(ERKEK_ISIMLER + KIZ_ISIMLER)
        soyisim = random.choice(SOYADLAR)
        ad_soyad = f'{isim} {soyisim}'

        # Kurum
        kurum = random.choice(KURUMLAR)

        # Tarih
        tarih = random_date()

        # Durum
        durum = random.choice(['Bekliyor', 'Bekliyor', 'Bekliyor', 'Teslim Edildi', 'Arşivlendi'])

        # Evrak sayısı
        evrak_sayisi = str(random.randint(1, 15))

        # Teslim bilgileri (sadece Teslim Edildi ise)
        teslim_tarihi = None
        if durum == 'Teslim Edildi':
            # Tarihten sonra bir teslim tarihi
            gelis = datetime.strptime(tarih, '%Y-%m-%d')
            gun_fark = random.randint(1, 30)
            teslim = gelis + timedelta(days=gun_fark)
            teslim_tarihi = teslim.strftime('%Y-%m-%dT%H:%M:%S')

        now = datetime.now().strftime('%Y-%m-%dT%H:%M:%S')

        cursor.execute("""
            INSERT INTO Evraklar (
                gelis_tarihi, ad_soyad, geldigi_kurum, evrak_sayisi,
                durum, teslim_tarihi, olusturma_tarihi, guncelleme_tarihi,
                silindi_mi, silinme_tarihi
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, NULL)
        """, (tarih, ad_soyad, kurum, evrak_sayisi, durum, teslim_tarihi, now, now))

        # Teslim edildiyse teslim kaydı ekle
        if durum == 'Teslim Edildi' and teslim_tarihi:
            cursor.execute("SELECT last_insert_rowid()")
            evrak_id = cursor.fetchone()[0]

            teslim_ad = random.choice(ERKEK_ISIMLER + KIZ_ISIMLER) + ' ' + random.choice(SOYADLAR)
            tc = random_tc()
            tel = random_phone()
            aciklama = random.choice(ACIKLAMALAR)

            cursor.execute("""
                INSERT INTO TeslimKayitlari (
                    evrak_id, teslim_alan_ad_soyad, tc_kimlik_no, telefon,
                    aciklama, teslim_tarihi, olusturma_tarihi
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (evrak_id, teslim_ad, tc, tel, aciklama, teslim_tarihi, now))

        eklenen += 1

    conn.commit()

    # Sonuç
    cursor.execute("SELECT COUNT(*) FROM Evraklar WHERE silindi_mi = 0")
    toplam = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM Evraklar WHERE silindi_mi = 0 AND durum = 'Bekliyor'")
    bekleyen = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM Evraklar WHERE silindi_mi = 0 AND durum = 'Teslim Edildi'")
    teslim = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM Evraklar WHERE silindi_mi = 0 AND durum = 'Arşivlendi'")
    arsiv = cursor.fetchone()[0]

    conn.close()

    print(f"\n{eklenen} yeni kayıt eklendi.")
    print(f"Toplam: {toplam} | Bekleyen: {bekleyen} | Teslim: {teslim} | Arşiv: {arsiv}")


if __name__ == '__main__':
    main()
