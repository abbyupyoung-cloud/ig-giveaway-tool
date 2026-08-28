<#
.SYNOPSIS
  抓取一則 Instagram 貼文的留言(透過 Instagram Graph API),依 hashtag/關鍵字篩選,輸出 CSV。

.DESCRIPTION
  只能抓「你自己管理的 IG 專業帳號」底下的貼文留言。權杖與設定方式見同資料夾的 README.md。
  輸出的 CSV 可直接貼進「開獎台」抽獎工具的「留言名單」欄位(它只取每行第一欄,會自動忽略標題列)。

.PARAMETER AccessToken
  Graph API 存取權杖,需具備 instagram_basic + instagram_manage_comments 權限。

.PARAMETER MediaId
  目標貼文的 Instagram Media ID(不是短碼、不是網址)。用 find-media-id.ps1 找。

.PARAMETER Hashtag
  篩選用的關鍵字/hashtag,例如 "把日常美好收藏進Duralex"(# 可加可不加)。留空則抓全部留言不篩選。

.PARAMETER OutCsv
  輸出的 CSV 檔案路徑,預設在目前資料夾產生 comments.csv。

.EXAMPLE
  .\fetch-comments.ps1 -AccessToken "EAAxxxx..." -MediaId "17912345678901234" -Hashtag "把日常美好收藏進Duralex"
#>

param(
    [Parameter(Mandatory = $true)][string]$AccessToken,
    [Parameter(Mandatory = $true)][string]$MediaId,
    [string]$Hashtag = "",
    [string]$OutCsv = ".\comments.csv"
)

$ErrorActionPreference = "Stop"

$fields = "id,text,username,timestamp"
$url = "https://graph.facebook.com/v20.0/$MediaId/comments?fields=$fields&access_token=$AccessToken&limit=100"
$all = @()

Write-Host "抓取留言中..."
while ($url) {
    try {
        $resp = Invoke-RestMethod -Uri $url -Method Get
    } catch {
        Write-Host "呼叫 Graph API 失敗,請確認 AccessToken / MediaId 是否正確、權杖是否過期。" -ForegroundColor Red
        throw
    }
    $all += $resp.data
    Write-Host ("已取得 {0} 則留言..." -f $all.Count)
    if ($resp.paging -and $resp.paging.next) {
        $url = $resp.paging.next
    } else {
        $url = $null
    }
}

if ($Hashtag) {
    $needle = $Hashtag.TrimStart('#')
    $filtered = $all | Where-Object { $_.text -match [regex]::Escape($needle) }
    Write-Host ("符合『{0}』的留言:{1} / 共 {2} 則" -f $Hashtag, $filtered.Count, $all.Count)
} else {
    $filtered = $all
}

$filtered |
    Select-Object username, text, timestamp, id |
    Export-Csv -Path $OutCsv -Encoding UTF8 -NoTypeInformation

Write-Host "已輸出至 $OutCsv"
Write-Host "可以打開這個檔案,把 username 那一欄整段複製貼到「開獎台」的留言名單欄位(有標題列也沒關係,工具會自動忽略)。"
