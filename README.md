# IG 抽獎留言自動抓取工具

只抓「自己管理的 IG 專業帳號」貼文留言,自動篩選 hashtag。有兩種用法:

- **`index.html`(推薦)**:貼上貼文網址就能自動抓留言 + 現場抽獎,一站完成。可以雙擊在本機開,也已經放上 GitHub Pages,任何電腦打開網址就能用:**https://abbyupyoung-cloud.github.io/ig-giveaway-tool/**。Token 是你自己貼進網頁欄位、存在瀏覽器的 localStorage,檔案本身不含任何密鑰,repo 公開也沒有洩漏風險。因為頁面會要求輸入 Access Token,只在這個你自己管理、能確認程式碼沒被竄改的網址使用,不要把 Token 貼到其他來路不明的網站。
- **`fetch-comments.ps1`(備援)**:如果本機版因為瀏覽器擋下跨網域請求而抓取失敗,改用 PowerShell 腳本抓,輸出 CSV 後貼到雲端版[開獎台](https://claude.ai/code/artifact/3d456d86-e0b3-4537-a5da-21dc0e1ecacc)。

兩種都需要先完成下面的「一次性設定」拿到 Access Token 和 IG User ID。

**重要更正**:因為這個工具只給你自己(@duralextaiwan 的管理者)用,**不需要送 Meta App 審查、也不需要商業驗證**。App 審查只有在你想讓「其他不相關的人」透過你的 App 存取*他們自己*的帳號時才需要。你自己的帳號留在 App 的「開發模式」、把自己設為 App 的管理員/開發人員,就能無限期使用這些權限 —— 不會過期(權杖本身會過期,但重新產生不需要再審查一次)。

## 限制(API 本來就抓不到的東西)

- **按讚名單**:Instagram Graph API 不提供「誰按讚」的清單,只有讚數。這輩子只能人工點開「查看 N 人喜歡」複製。
- **私訊次數**:只能讀「自己商業帳號收到」的訊息,而且要另外申請 `instagram_manage_messages` 權限並走審查,設定成本很高。目前這套工具**沒有**做私訊自動抓,私訊名單仍需人工從收件匣清點後貼進開獎台。

## 一次性設定(之後每場活動不用重做)

這套工具走的是 Meta 目前的「**Instagram API with Instagram Login**」流程(不用連 Facebook 粉專),權杖開頭是 `IGAAT...`,呼叫網址是 `graph.instagram.com`(不是 `graph.facebook.com`,那是給另一套走 Facebook 登入的舊系統用的,兩邊權杖不通用)。

1. **確認 IG 帳號是專業帳號**:IG App → 設定 → 帳號類型 → 切換成「專業帳號」(商業或創作者皆可,不需要連 Facebook 粉專)。

2. **建立 Meta App**:前往 [developers.facebook.com](https://developers.facebook.com) → 我的應用程式 → 建立應用程式 → 類型選「商業」。

3. **新增使用案例**:在 App 控制台左側點「使用案例」,選「**管理 Instagram 的訊息和內容**」(圖示是 IG 那個,不是 Messenger 或 WhatsApp),按繼續。這步會自動幫你加上 `instagram_business_basic`、`instagram_business_manage_comments`、`instagram_business_manage_messages` 三個權限。

4. **把你的 IG 帳號加為測試人員**(Development 模式下,只有被加為 Tester 的帳號能授權):
   - App 後台左側「應用程式角色」→「角色」→「新增人員」
   - 角色選「**Instagram 測試人員**」(不是上面那個籠統的「測試人員」)
   - 搜尋欄輸入你的 IG 帳號(例如 `duralextaiwan`)送出邀請
   - **手機**打開 Instagram App(網頁版沒有這個選項)→ 設定與隱私 → 應用程式和網站 → 測試人員邀請 → 接受

5. **產生權杖**:回 App 後台「使用案例」→ Instagram 使用案例畫面「2. 產生存取權杖」→「新增帳號」,跳出的 IG 授權彈窗選你的帳號、按繼續。
   - **重要**:繼續之後一定要看到一個列出「留言 / 私訊」等權限項目、要你按「允許」的畫面,才代表留言權限真的有給。如果按繼續後直接跳回 IG 首頁、完全沒看到權限列表,代表授權被中斷了,權杖只會有基本資料權限、留言 API 會回空值——這時候換個瀏覽器或用無痕視窗重試。
   - 帳號成功加入後,表格裡該帳號那列會有「產生權杖」的藍字連結,點下去直接複製出 Token,**不用像舊版教學那樣去 Graph API Explorer**。
   - 這個 Token 效期較短(約 1 小時),要換長效的話呼叫:
     ```
     GET https://graph.instagram.com/access_token
         ?grant_type=ig_exchange_token
         &client_secret={App Secret,在「應用程式設定→基本資料」找}
         &access_token={剛剛產生的短效token}
     ```
     回傳的 `access_token` 效期約 60 天。快到期前用這支延長(不用重新走授權):
     ```
     GET https://graph.instagram.com/refresh_access_token
         ?grant_type=ig_refresh_token
         &access_token={目前的長效token}
     ```

6. **找出 IG User ID**(注意:App 後台表格顯示的那組 ID 不是這裡要用的):
   ```
   GET https://graph.instagram.com/v21.0/me?fields=id,username&access_token={你的token}
   ```
   回傳的 `id` 才是要填進工具的 IG User ID。

## 每次活動的使用流程(推薦:本機版一站完成)

1. 打開 https://abbyupyoung-cloud.github.io/ig-giveaway-tool/(或雙擊本機的 `index.html`)。
2. 在「留言名單」卡片裡貼上 Access Token、IG User ID、貼文網址(例如 `https://www.instagram.com/p/DcH2A2nTthL/`),要篩選 hashtag 就填,不用就留空。
3. 按「抓取留言」——它會先在你最近 300 則貼文裡比對網址找出 Media ID,再抓該貼文全部留言,自動篩選、填入留言名單。
4. 按讚名單、私訊(2次)名單一樣人工複製貼上。
5. 右邊「符合資格名單」會即時顯示三項交集,填好獎項名稱、抽出人數,按「開始抽獎」。
6. Token / IG User ID / 名單都會存在這台電腦的瀏覽器裡,下次打開還在。

如果按「抓取留言」出現「瀏覽器擋下跨網域請求」之類的錯誤,改用備援流程:

1. 在這個資料夾按右鍵「用 VS Code 開啟」。
2. 按 `Ctrl+Shift+P` → 打「Run Task」→ 選 **「IG抽獎: 找 Media ID」**,依提示貼權杖、貼 IG User ID,會列出最近貼文的 Media ID 和連結,比對出目標貼文那筆。
3. 再跑一次「Run Task」→ 選 **「IG抽獎: 抓留言」**,貼權杖、貼上一步找到的 Media ID、輸入要篩選的 hashtag,會在資料夾產生 `comments.csv`。
4. 打開 `comments.csv`,把整欄 `username` 複製起來,貼進 [index.html](https://abbyupyoung-cloud.github.io/ig-giveaway-tool/) 或雲端版[開獎台](https://claude.ai/code/artifact/3d456d86-e0b3-4537-a5da-21dc0e1ecacc)的「留言名單」欄位(有標題列沒關係,工具會自動忽略)。

## 安全提醒

- Access Token 等同帳號密碼,**不要貼到聊天記錄、不要 commit 進任何版本控制**。只在跑腳本時貼在 VS Code 的輸入框裡(有加密顯示 `password: true`),用完就好。
- 懷疑權杖外洩時,回 Graph API Explorer 重新 Generate 一次會讓舊權杖失效。
