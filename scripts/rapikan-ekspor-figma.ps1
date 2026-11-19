# Rapikan hasil ekspor Figma Siap Banjir ke docs/images/figma/
#
# Cara pakai (dari folder repo siap-banjir, di PowerShell):
#   1. Di Figma, ekspor semua frame halaman "Siap Banjir — Mobile" dan
#      "Siap Banjir — Desktop" sebagai PNG 1x ke satu folder, misalnya Downloads\figma.
#   2. Jalankan:
#        powershell -ExecutionPolicy Bypass -File .\scripts\rapikan-ekspor-figma.ps1 -Sumber "$HOME\Downloads\figma"
#
# Skrip ini menyalin dan mengganti nama file (mis. "Beranda · Risiko Rendah · Mobile.png"
# menjadi "mobile-beranda-rendah.png") sesuai nama yang dipakai README.

param(
    [Parameter(Mandatory = $true)][string]$Sumber,
    [string]$Tujuan = "docs\images\figma"
)

$peta = [ordered]@{
    "Beranda · Risiko Rendah"              = "beranda-rendah"
    "Beranda · Risiko Sedang"              = "beranda-sedang"
    "Beranda · Risiko Tinggi"              = "beranda-tinggi"
    "Beranda · Ubah wilayah"               = "beranda-ubah-wilayah"
    "Risiko"                               = "risiko"
    "Cuaca"                                = "cuaca"
    "Informasi"                            = "informasi"
    "Pengaturan"                           = "pengaturan"
    "Nomor Darurat · Wilayah dengan 112"   = "darurat-112"
    "Nomor Darurat · Wilayah tanpa 112"    = "darurat-tanpa-112"
    "Nomor Darurat · Konfirmasi panggilan" = "darurat-konfirmasi"
}

if (-not (Test-Path $Sumber)) { Write-Error "Folder sumber tidak ditemukan: $Sumber"; exit 1 }
New-Item -ItemType Directory -Force -Path $Tujuan | Out-Null

$berhasil = 0
$hilang = @()
foreach ($ukuran in @("Mobile", "Desktop")) {
    foreach ($judul in $peta.Keys) {
        $namaFigma = "$judul · $ukuran.png"
        $berkas = Get-ChildItem -LiteralPath $Sumber -File | Where-Object { $_.Name -eq $namaFigma } | Select-Object -First 1
        $namaBaru = "$($ukuran.ToLower())-$($peta[$judul]).png"
        if ($berkas) {
            Copy-Item -LiteralPath $berkas.FullName -Destination (Join-Path $Tujuan $namaBaru) -Force
            $berhasil++
        } else {
            $hilang += $namaFigma
        }
    }
}

Write-Host "$berhasil dari 22 gambar disalin ke $Tujuan"
if ($hilang.Count -gt 0) {
    Write-Host "Tidak ditemukan (periksa nama file hasil ekspor):" -ForegroundColor Yellow
    $hilang | ForEach-Object { Write-Host "  - $_" }
}
