@echo off
echo ========================================
echo  Muhtar Tebligat Takip - Installer Olusturma
echo ========================================
echo.

echo [1/5] Flutter build aliniyor...
call flutter build windows --release
if %errorlevel% neq 0 (
    echo HATA: Flutter build basarisiz!
    pause
    exit /b 1
)
echo Build basarili!
echo.

echo [2/5] MSIX olusturuluyor...
dart run msix:create
if %errorlevel% neq 0 (
    echo UYARI: MSIX olusturma basarisiz!
) else (
    echo MSIX basariyla olusturuldu!
    copy "build\windows\x64\runner\Release\muhtar_tebligat_takip.msix" "installer\muhtar_tebligat_takip_1.5.10.msix" >nul 2>nul
)
echo.

echo [3/5] MSI (WiX) derleniyor...
where wix >nul 2>nul
if %errorlevel% equ 0 (
    wix build -o "installer\muhtar_tebligat_takip_setup_1.5.10.msi" -b "%~dp0" -pdb "none" -ext WixToolset.UI.wixext installer.wxs
    if %errorlevel% neq 0 (
        echo UYARI: WiX MSI derlemesi basarisiz!
    ) else (
        echo MSI basariyla olusturuldu!
    )
) else (
    echo UYARI: WiX bulunamadi! MSI olusturulamadi.
)
echo.

echo [4/5] EXE (Inno Setup) derleniyor...
where iscc >nul 2>nul
if %errorlevel% equ 0 (
    iscc /Q installer.iss
) else (
    if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" /Q installer.iss
    ) else (
        echo UYARI: Inno Setup bulunamadi! EXE olusturulamadi.
    )
)
if exist "installer\muhtar_tebligat_takip_setup_1.5.10.exe" (
    echo EXE basariyla olusturuldu!
) else (
    echo UYARI: EXE olusturulamadi!
)
echo.

echo [5/5] Tamamlandi!
echo.
echo Olusturulan dosyalar:
if exist "installer\muhtar_tebligat_takip_1.5.10.msix" (
    echo   MSIX: installer\muhtar_tebligat_takip_1.5.10.msix
)
if exist "installer\muhtar_tebligat_takip_setup_1.5.10.msi" (
    echo   MSI:  installer\muhtar_tebligat_takip_setup_1.5.10.msi
)
if exist "installer\muhtar_tebligat_takip_setup_1.5.10.exe" (
    echo   EXE:  installer\muhtar_tebligat_takip_setup_1.5.10.exe
)
echo.
pause
