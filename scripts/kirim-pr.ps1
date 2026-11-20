# Kirim perubahan lewat Pull Request (code review), bukan push langsung ke main.
#
# Pemakaian (dari folder repo):
#   .\scripts\kirim-pr.ps1 -Judul "Tambah skrip uji beban k6"
#
# Alur:
#   - Sedang di branch main: ambil main terbaru, buat branch baru fitur/<judul>,
#     commit, push, lalu buka halaman Pull Request di browser.
#   - Sedang di branch fitur: commit dan push ke branch itu. Pull Request yang sudah
#     terbuka ikut ter-update, jadi perbaikan hasil review cukup dikirim dengan
#     perintah yang sama.
#
# Kalau PowerShell menolak menjalankan skrip, pakai:
#   powershell -ExecutionPolicy Bypass -File .\scripts\kirim-pr.ps1 -Judul "..."

param(
    [Parameter(Mandatory = $true)][string]$Judul,
    [string]$Branch
)

function Cek([string]$langkah) {
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Gagal saat: $langkah" -ForegroundColor Red
        exit 1
    }
}

# 1. Pastikan ini repo git dan ada perubahan
$null = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Jalankan skrip ini dari dalam folder repo siap-banjir." -ForegroundColor Red
    exit 1
}
if (-not (git status --porcelain)) {
    Write-Host "Tidak ada perubahan untuk dikirim." -ForegroundColor Yellow
    exit 0
}
$sekarang = (git rev-parse --abbrev-ref HEAD).Trim()
$branchBaru = ($sekarang -eq "main")

# 2. Tentukan branch tujuan
if ($branchBaru) {
    if (-not $Branch) {
        $slug = ($Judul.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
        if ($slug.Length -gt 40) { $slug = $slug.Substring(0, 40).Trim('-') }
        if (-not $slug) { $slug = "perubahan" }
        $Branch = "fitur/$slug-$(Get-Date -Format 'MMdd-HHmm')"
    }
    Write-Host "Mengambil main terbaru dari GitHub..." -ForegroundColor Cyan
    git fetch origin main
    Cek "git fetch origin main"
    $tertinggal = (git rev-list --count "HEAD..origin/main").Trim()
    if ($tertinggal -ne "0") {
        Write-Host "main lokal tertinggal $tertinggal commit; memperbarui dulu (perubahan kalian disimpan sementara)..." -ForegroundColor Yellow
        git stash push --include-untracked -m "kirim-pr"
        Cek "git stash"
        git pull --ff-only origin main
        Cek "git pull"
        git stash pop
        Cek "git stash pop (ada konflik: selesaikan dulu, lalu jalankan skrip lagi)"
    }
    git switch -c $Branch
    Cek "membuat branch $Branch"
} else {
    $Branch = $sekarang
    Write-Host "Melanjutkan branch $Branch (Pull Request yang sudah ada akan ter-update)." -ForegroundColor Cyan
}

# 3. Tunjukkan file yang akan dikirim dan minta konfirmasi
git add -A
Write-Host ""
Write-Host "File yang akan dikirim:" -ForegroundColor Cyan
git status --short
Write-Host ""
$jawab = Read-Host "Kirim perubahan ini? (y/n)"
if ($jawab -ne "y") {
    git reset -q
    Write-Host "Dibatalkan. Tidak ada yang di-commit (masih di branch $Branch)." -ForegroundColor Yellow
    exit 0
}

$nama = (git config user.name)
git commit -m $Judul -m "Dikirim oleh $nama lewat scripts/kirim-pr.ps1"
Cek "git commit"
git push -u origin $Branch
Cek "git push"

# 4. Buka halaman Pull Request (GitHub otomatis memasang template checklist)
if (-not $branchBaru) {
    Write-Host ""
    Write-Host "Selesai. Pull Request yang sudah ada ter-update; beri tahu reviewer." -ForegroundColor Green
    exit 0
}

$asal = ((git remote get-url origin).Trim() -replace '\.git$', '') -replace '^git@github\.com:', 'https://github.com/'
$url = "$asal/compare/main...$($Branch)?expand=1&title=$([uri]::EscapeDataString($Judul))"
Write-Host ""
Write-Host "Membuka halaman Pull Request di browser:" -ForegroundColor Green
Write-Host $url
Start-Process $url
Write-Host ""
Write-Host "Di halaman itu:" -ForegroundColor Green
Write-Host "  1. Isi ringkasan dan centang test yang sudah dijalankan."
Write-Host "  2. Pilih anggota lain di 'Reviewers' (kanan atas)."
Write-Host "  3. Klik 'Create pull request'."
Write-Host "Setelah PR di-merge, kembali ke main:  git switch main; git pull" -ForegroundColor Green
