<#
.SYNOPSIS
  列出一個 IG 專業帳號最近的貼文,附 permalink 和 Media ID,方便找到目標貼文要用的 MediaId。

.PARAMETER AccessToken
  Graph API 存取權杖(同 fetch-comments.ps1)。

.PARAMETER IgUserId
  IG 專業帳號的 Instagram User ID(不是帳號名稱)。取得方式見 README.md 第 6 步。

.EXAMPLE
  .\find-media-id.ps1 -AccessToken "EAAxxxx..." -IgUserId "17841400000000000"
#>

param(
    [Parameter(Mandatory = $true)][string]$AccessToken,
    [Parameter(Mandatory = $true)][string]$IgUserId
)

$ErrorActionPreference = "Stop"
$url = "https://graph.instagram.com/v21.0/$IgUserId/media?fields=id,permalink,caption,timestamp&access_token=$AccessToken&limit=25"

do {
    $resp = Invoke-RestMethod -Uri $url -Method Get
    $resp.data | ForEach-Object {
        $captionPreview = ""
        if ($_.caption) { $captionPreview = ($_.caption -replace "`r?`n", " ").Substring(0, [Math]::Min(40, $_.caption.Length)) }
        [PSCustomObject]@{
            MediaId  = $_.id
            Time     = $_.timestamp
            Caption  = $captionPreview
            Permalink = $_.permalink
        }
    } | Format-Table -Wrap
    $url = if ($resp.paging -and $resp.paging.next) { $resp.paging.next } else { $null }
} while ($url)

Write-Host "找到目標貼文後,把該筆的 MediaId 用在 fetch-comments.ps1 的 -MediaId 參數。"
