@echo off
echo ========================================
echo  Muhtar Tebligat Takip - Installer Olusturma
echo ========================================
echo.

echo [1/4] Flutter build aliniyor...
call flutter build windows
if %errorlevel% neq 0 (
    echo HATA: Flutter build basarisiz!
    pause
    exit /b 1
)
echo Build basarili!
echo.

echo [2/4] Inno Setup derleniyor...
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
    if exist "C:\Users\savas.boluk\AppData\Local\Programs\Inno Setup 6\ISCC.exe" (
        "C:\Users\savas.boluk\AppData\Local\Programs\Inno Setup 6\ISCC.exe" /Q installer.iss
    ) else (
        echo UYARI: Inno Setup bulunamadi!
        echo Inno Setup'i buradan indirin: https://jrsoftware.org/isdl.php
        echo Indirdikten sonra asagidaki komutu calistirin:
        echo.
        echo   "C:\Users\savas.boluk\AppData\Local\Programs\Inno Setup 6\ISCC.exe" installer.iss
        echo.
    )
)
echo.

echo [3/4] WiX MSI derleniyor...
where wix >nul 2>nul
if %errorlevel% equ 0 (
    wix build -o "installer\muhtar_tebligat_takip_msi_1.3.0.msi" -b "%~dp0" -ext WixToolset.UI.wixext installer.wxs
    if %errorlevel% neq 0 (
        echo UYARI: WiX MSI derlemesi basarisiz!
    ) else (
        echo MSI installer basariyla olusturuldu!
        del /q "installer\*.wixpdb" 2>nul
    )
) else (
    echo UYARI: WiX bulunamadi! MSI olusturulamadi.
)
echo.

echo [4/4] Tamamlandi!
echo.
if exist "installer\muhtar_tebligat_takip_setup_1.3.0.exe" (
    echo EXE Installer: installer\muhtar_tebligat_takip_setup_1.3.0.exe
)
if exist "installer\muhtar_tebligat_takip_msi_1.3.0.msi" (
    echo MSI Installer: installer\muhtar_tebligat_takip_msi_1.3.0.msi
)
echo.
pause
