<#
.SYNOPSIS
  把手動授權網址拿到的 authorization code,交換成 Access Token(在本機執行,App Secret 不會傳給任何人)。

.DESCRIPTION
  搭配手動授權流程使用(見 README.md「手動授權(繞過後台按鈕 bug)」段落)。
  換回來的 JSON 裡有一個 permissions 欄位,列出這組 Token 實際拿到哪些權限——
  一定要確認裡面有 instagram_business_manage_comments,沒有的話代表授權畫面還是沒同意到,要重來一次。

.PARAMETER Code
  瀏覽器網址列裡 `?code=` 後面那一串(通常結尾會帶 `#_`,腳本會自動處理,不用手動去掉)。

.PARAMETER AppId
  Instagram 應用程式編號(App 後台「Instagram 應用程式名稱/編號/密鑰」那排可以找到)。

.PARAMETER AppSecret
  Instagram 應用程式密鑰(同一排,按「顯示」才看得到)。只在這裡輸入,不要貼給任何人。

.PARAMETER RedirectUri
  跟產生授權網址時用的同一個 redirect_uri,預設用工具的 GitHub Pages 網址。

.EXAMPLE
  .\exchange-code.ps1 -Code "AQD8x...#_" -AppId "1348796017242096" -AppSecret "xxxxxxxx"
#>

param(
    [Parameter(Mandatory = $true)][string]$Code,
    [Parameter(Mandatory = $true)][string]$AppId,
    [Parameter(Mandatory = $true)][string]$AppSecret,
    [string]$RedirectUri = "https://abbyupyoung-cloud.github.io/ig-giveaway-tool/"
)

$ErrorActionPreference = "Stop"

# 網址列複製下來常會帶著結尾的 #_,交換時要拿掉
$cleanCode = $Code -replace '#_$', ''

$body = @{
    client_id     = $AppId
    client_secret = $AppSecret
    grant_type    = "authorization_code"
    redirect_uri  = $RedirectUri
    code          = $cleanCode
}

Write-Host "交換短效權杖中..."
$resp = Invoke-RestMethod -Uri "https://api.instagram.com/oauth/access_token" -Method Post -Body $body

Write-Host "`n=== 換到的短效權杖(約1小時有效)==="
$resp | ConvertTo-Json

if ($resp.permissions) {
    Write-Host "`n=== 這組權杖實際拿到的權限 ==="
    $resp.permissions | ForEach-Object { Write-Host " - $_" }
    if ($resp.permissions -notcontains "instagram_business_manage_comments") {
        Write-Host "`n⚠ 沒有看到 instagram_business_manage_comments,代表授權畫面還是沒同意到留言權限,要重新走一次手動授權網址流程。" -ForegroundColor Yellow
    } else {
        Write-Host "`n✓ instagram_business_manage_comments 有拿到,可以拿這組短效權杖去換長效權杖了(見 README)。" -ForegroundColor Green
    }
}

Write-Host "`n把上面的 access_token 拿去換長效權杖(README 第5步),再貼進開獎台使用。"
