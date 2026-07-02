"""
Son 10 günde gelmiş 35 test kaydı oluşturur.
5-6 tanesi teslim edilmiş, gerisi bekliyor.
Kullanım: python scripts/add_recent_records.py
"""
import sqlite3
import random
import os
from datetime import datetime, timedelta

ERKEK_ISIMLER = [
    'Mehmet', 'Mustafa', 'Ahmet', 'Ali', 'Hasan', 'Hüseyin', 'İbrahim',
    'Ömer', 'Yusuf', 'Emre', 'Burak', 'Oğuz', 'Kemal', 'Selim', 'Tolga',
    'Murat', 'Fatih', 'Serkan', 'Onur', 'Gökhan', 'Batuhan', 'Kaan', 'Arda'
]

KIZ_ISIMLER = [
    'Fatma', 'Ayşe', 'Emine', 'Zeynep', 'Elif', 'Merve', 'Büşra', 'Seda',
    'Eda', 'Deniz', 'Aslı', 'Gamze', 'Pınar', 'Selin', 'Burcu', 'Ceren'
]

SOYADLAR = [
    'Yılmaz', 'Kaya', 'Demir', 'Çelik', 'Şahin', 'Yıldız', 'Yıldırım',
    'Öztürk', 'Aydın', 'Özdemir', 'Arslan', 'Doğan', 'Kılıç', 'Aslan',
    'Çetin', 'Kara', 'Koç', 'Kurt', 'Özkan', 'Şimşek', 'Polat', 'Karaca'
]

KURUMLAR = [
    'Antalya Büyükşehir Belediyesi', 'Konyaaltı Belediyesi', 'Muratpaşa Belediyesi',
    'Kepez Belediyesi', 'Antalya Valiliği', 'İl Nüfus Müdürlüğü',
    'Tapu ve Kadastro', 'Antalya Adliyesi', 'Emniyet Müdürlüğü',
    'SGK İl Müdürlüğü', 'İl Sağlık Müdürlüğü', 'İl Milli Eğitim Müdürlüğü',
    'Göç İdaresi Müdürlüğü', 'Belediye Zabıta Müdürlüğü', 'İl Jandarma Komutanlığı'
]


def random_date_last_10_days():
    now = datetime.now()
    days_ago = random.randint(0, 9)
    d = now - timedelta(days=days_ago)
    hour = random.randint(8, 17)
    minute = random.randint(0, 59)
    return d.replace(hour=hour, minute=minute, second=0, microsecond=0)


def random_phone():
    return f'0{random.choice([530,532,533,534,535,536,537,538,539])}{random.randint(1000000,9999999)}'


def random_tc():
    first = str(random.randint(1, 9))
    rest = ''.join([str(random.randint(0, 9)) for _ in range(10)])
    return first + rest


def main():
    db_path = os.path.join(os.path.dirname(__file__), '..', 'build', 'windows', 'x64', 'runner', 'Release', 'tebligat.db')
    if not os.path.exists(db_path):
        db_path = os.path.expanduser(r'~\AppData\Roaming\MuhtarTebligat\tebligat.db')
    
    if not os.path.exists(db_path):
        print(f"Hata: Veritabanı bulunamadı.")
        return

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    cursor.execute("SELECT COUNT(*) FROM Evraklar WHERE silindi_mi = 0")
    mevcut = cursor.fetchone()[0]
    print(f"Mevcut kayıt sayısı: {mevcut}")

    # 35 kayıt oluştur
    toplam = 35
    teslim_sayisi = 6  # 6 tanesi teslim edilmiş
    
    # Tarihleri oluştur ve sırala (eskiden yeniye)
    tarihler = []
    for _ in range(toplam):
        tarihler.append(random_date_last_10_days())
    tarihler.sort()

    eklenen = 0
    for i in range(toplam):
        tarih = tarihler[i]
        
        isim = random.choice(ERKEK_ISIMLER + KIZ_ISIMLER)
        soyisim = random.choice(SOYADLAR)
        ad_soyad = f'{isim} {soyisim}'
        kurum = random.choice(KURUMLAR)
        evrak_sayisi = str(random.randint(1, 12))

        # İlk 6 kayıt teslim edilmiş, gerisi bekliyor
        if i < teslim_sayisi:
            durum = 'Teslim Edildi'
            # Teslim tarihi geliş tarihinden 1-2 gün sonra
            gun_fark = random.randint(1, 2)
            teslim = tarih + timedelta(days=gun_fark, hours=random.randint(1, 4))
            teslim_tarihi = teslim.strftime('%Y-%m-%dT%H:%M:%S')
        else:
            durum = 'Bekliyor'
            teslim_tarihi = None

        now_str = datetime.now().strftime('%Y-%m-%dT%H:%M:%S')
        gelis_str = tarih.strftime('%Y-%m-%d')

        cursor.execute("""
            INSERT INTO Evraklar (
                gelis_tarihi, ad_soyad, geldigi_kurum, evrak_sayisi,
                durum, teslim_tarihi, olusturma_tarihi, guncelleme_tarihi,
                silindi_mi, silinme_tarihi
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, NULL)
        """, (gelis_str, ad_soyad, kurum, evrak_sayisi, durum, teslim_tarihi, now_str, now_str))

        # Teslim edildiyse teslim kaydı da ekle
        if durum == 'Teslim Edildi':
            cursor.execute("SELECT last_insert_rowid()")
            evrak_id = cursor.fetchone()[0]
            
            teslim_ad = random.choice(ERKEK_ISIMLER + KIZ_ISIMLER) + ' ' + random.choice(SOYADLAR)
            tc = random_tc()
            tel = random_phone()
            
            cursor.execute("""
                INSERT INTO TeslimKayitlari (
                    evrak_id, teslim_alan_ad_soyad, tc_kimlik_no, telefon,
                    teslim_tarihi, olusturma_tarihi
                ) VALUES (?, ?, ?, ?, ?, ?)
            """, (evrak_id, teslim_ad, tc, tel, teslim_tarihi, now_str))

        eklenen += 1

    conn.commit()

    cursor.execute("SELECT COUNT(*) FROM Evraklar WHERE silindi_mi = 0")
    toplam_db = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM Evraklar WHERE silindi_mi = 0 AND durum = 'Bekliyor'")
    bekleyen = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM Evraklar WHERE silindi_mi = 0 AND durum = 'Teslim Edildi'")
    teslim = cursor.fetchone()[0]

    conn.close()

    print(f"\n{eklenen} yeni kayıt eklendi (son 10 gün).")
    print(f"Toplam: {toplam_db} | Bekleyen: {bekleyen} | Teslim: {teslim}")


if __name__ == '__main__':
    main()
