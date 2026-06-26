@echo off
echo ========================================
echo  Muhtar Tebligat Takip - Installer Olusturma
echo ========================================
echo.

echo [1/3] Flutter build aliniyor...
call flutter build windows
if %errorlevel% neq 0 (
    echo HATA: Flutter build basarisiz!
    pause
    exit /b 1
)
echo Build basarili!
echo.

echo [2/3] Inno Setup derleniyor...
where iscc >nul 2>nul
if %errorlevel% equ 0 (
    iscc /Q installer.iss
    if %errorlevel% neq 0 (
        echo HATA: Inno Setup derlemesi basarisiz!
        pause
        exit /b 1
    )
    echo Installer basariyla olusturuldu!
) else (
    echo UYARI: Inno Setup bulunamadi!
    echo Inno Setup'i buradan indirin: https://jrsoftware.org/isdl.php
    echo Indirdikten sonra iscc.exe'nin oldugu klasoru PATH'e ekleyin
    echo veya asagidaki komutu calistirin:
    echo.
    echo   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
    echo.
)
echo.

echo [3/3] Tamamlandi!
echo.
if exist "installer\muhtar_tebligat_takip_setup_1.3.0.exe" (
    echo Installer konumu: installer\muhtar_tebligat_takip_setup_1.3.0.exe
) else (
    echo Installer klasoru: installer\
)
echo.
pause
