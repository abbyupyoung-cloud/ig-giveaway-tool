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

1. **確認 IG 帳號是專業帳號並已連結 Facebook 粉專**:IG App → 設定 → 帳號類型 → 切換成「專業帳號」,並在「連結的帳號」裡確認已連到你管理的 Facebook 粉專。

2. **建立 Meta App**:前往 [developers.facebook.com](https://developers.facebook.com) → 我的應用程式 → 建立應用程式 → 類型選「商業」。建好之後你(建立者)自動是 App 的管理員。

3. **加入 Instagram 相關產品**:在 App 控制台的「新增產品」裡加入 Instagram Graph API(介面可能顯示為「Instagram」,依 Meta 目前版本命名)。

4. **用 Graph API Explorer 產生權杖**:前往 [developers.facebook.com/tools/explorer](https://developers.facebook.com/tools/explorer)
   - 右上角選你剛建立的 App
   - 「User or Page」選 User Token
   - 權限勾選:`instagram_basic`、`instagram_manage_comments`、`pages_show_list`、`pages_read_engagement`
   - 按「Generate Access Token」,依畫面用你自己的 Facebook 帳號登入並同意授權你管理的粉專

5. **換成長效權杖(60天)**:短效權杖幾小時就過期,用下面這支呼叫換成 60 天效期的長效權杖(App ID / App Secret 在 App 控制台「設定 > 基本資料」可以找到):
   ```
   GET https://graph.facebook.com/v20.0/oauth/access_token
       ?grant_type=fb_exchange_token
       &client_id={你的App ID}
       &client_secret={你的App Secret}
       &fb_exchange_token={上一步拿到的短效權杖}
   ```
   可以直接把這個網址貼到瀏覽器(帶著參數)按下 Enter 呼叫。回傳的 `access_token` 就是要用在下面腳本的權杖。60 天後失效時,重複第 4、5 步重新產生即可,不需要再走審查。

6. **找出 IG User ID**:
   ```
   GET https://graph.facebook.com/v20.0/me/accounts?access_token={長效權杖}
   ```
   找到對應粉專的 `id`,再呼叫:
   ```
   GET https://graph.facebook.com/v20.0/{粉專id}?fields=instagram_business_account&access_token={長效權杖}
   ```
   拿到的 `instagram_business_account.id` 就是 IG User ID,`find-media-id.ps1` 會用到。

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
