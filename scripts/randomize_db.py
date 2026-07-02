"""
Veritabanındaki ad_soyad ve geldigi_kurum alanlarına rastgele 1-2 karakter ekler.
Kullanım: python scripts/randomize_db.py <veritabanı_yolu>
"""
import sqlite3
import random
import string
import sys
import os
import shutil

# Türkçe karakterler
TR_CHARS = 'ğşıİöüçĞŞIİÖÜÇ'
ALL_CHARS = string.ascii_letters + TR_CHARS

def random_insert(text):
    """Metne rastgele 1-2 karakter ekler."""
    if not text or text.strip() == '':
        return text
    num_chars = random.randint(1, 2)
    for _ in range(num_chars):
        char = random.choice(ALL_CHARS)
        pos = random.randint(0, len(text))
        text = text[:pos] + char + text[pos:]
    return text

def main():
    if len(sys.argv) < 2:
        print("Kullanım: python scripts/randomize_db.py <veritabanı_yolu>")
        sys.exit(1)

    db_path = sys.argv[1]
    if not os.path.exists(db_path):
        print(f"Hata: {db_path} bulunamadı.")
        sys.exit(1)

    # Yedek oluştur
    backup_path = db_path + '.orijinal'
    if not os.path.exists(backup_path):
        shutil.copy2(db_path, backup_path)
        print(f"Orijinal yedek: {backup_path}")

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Evrakları oku
    cursor.execute("SELECT id, ad_soyad, geldigi_kurum FROM Evraklar WHERE silindi_mi = 0")
    rows = cursor.fetchall()

    print(f"{len(rows)} kayıt bulundu. Düzenleniyor...")

    for row_id, ad_soyad, geldigi_kurum in rows:
        new_ad = random_insert(ad_soyad)
        new_kurum = random_insert(geldigi_kurum) if geldigi_kurum else geldigi_kurum

        cursor.execute(
            "UPDATE Evraklar SET ad_soyad = ?, geldigi_kurum = ? WHERE id = ?",
            (new_ad, new_kurum, row_id)
        )

    conn.commit()

    # Sonuçları göster
    cursor.execute("SELECT id, ad_soyad, geldigi_kurum FROM Evraklar WHERE silindi_mi = 0 LIMIT 10")
    print("\nİlk 10 kayıt (düzeltilmiş):")
    print("-" * 60)
    for row_id, ad_soyad, geldigi_kurum in cursor.fetchall():
        print(f"  ID {row_id}: {ad_soyad} | {geldigi_kurum or '-'}")

    conn.close()
    print(f"\nTamamlandı! Toplam {len(rows)} kayıt düzenlendi.")
    print(f"Düzenlenmiş veritabanı: {db_path}")

if __name__ == '__main__':
    main()
