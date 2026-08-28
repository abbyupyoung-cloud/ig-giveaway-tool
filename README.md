# IG 抽獎小工具

抽獎名單交集 + 公平抽獎工具,搭配 Meta Business Suite 人工匯出留言、人工複製按讚/私訊名單使用。

## 目前結論:留言自動抓取行不通,改用人工匯出

**曾經嘗試過用 Instagram API 自動抓留言,結論是走不通,不是操作問題,是 Meta 平台限制:**

- 申請了 Meta App、把帳號加為 Instagram 測試人員、拿到含 `instagram_business_manage_comments` 權限的 Access Token
- 但呼叫 `/comments` API,對**任何**貼文都回傳空陣列,即使 `comments_count` 顯示真的有上百則留言
- 這代表:雖然權限「有給」,但要真正**讀到**既有留言,還得再送 **Meta App Review 申請 Advanced Access**,需要人工審核、通常要等好幾天到幾週,而且不保證過
- 因為只是自己用、只抓自己帳號的留言,沒必要為此走一次正式審查

**所以留言名單改成跟按讚、私訊一樣,用 Meta Business Suite 人工匯出/複製**,詳見下方「每次活動的使用流程」。

工具本身([index.html](https://abbyupyoung-cloud.github.io/ig-giveaway-tool/)、`fetch-comments.ps1` 等)還留著、程式碼是對的,如果哪天決定要送 App Review 申請 Advanced Access,設定步驟在下面「(進階/暫不可用)API 自動抓取設定」保留供參考。

## 限制(API 本來就抓不到 / 已確認走不通的東西)

- **按讚名單**:Instagram API 不提供「誰按讚」的清單,只有讚數,只能人工點開「查看 N 人喜歡」複製。
- **私訊次數**:只能讀自己商業帳號收到的訊息,一樣需要 Advanced Access,私訊名單需人工從收件匣清點。
- **留言名單**:如上,API 技術上抓得到但實際資料被 Standard Access 擋住,改用人工匯出。

## 每次活動的使用流程(人工匯出版)

1. **留言**:登入 [business.facebook.com](https://business.facebook.com)(Meta Business Suite)→ 找到目標貼文 → 留言區可以看到全部留言,依 hashtag 篩選/搜尋,把帳號複製下來。
2. **按讚**:到該貼文點開「查看 N 人喜歡」,把帳號人工複製下來。
3. **私訊(2次)**:去 IG 私訊收件匣人工清點,篩出符合條件的帳號。
4. 打開 [開獎台(index.html)](https://abbyupyoung-cloud.github.io/ig-giveaway-tool/),把三份名單分別貼進「留言名單」「按讚名單」「私訊名單」欄位(每行一個帳號,前面加不加 @ 都可以)。
5. 右邊「符合資格名單」會即時顯示三項交集,填好獎項名稱、抽出人數,按「開始抽獎」。
6. 名單和抽獎紀錄會存在瀏覽器的 localStorage,下次打開還在。

---

## (進階/暫不可用)API 自動抓取設定

以下是留言自動抓取原本的完整設定紀錄,**目前卡在 Meta Advanced Access 審查,不建議照做**,除非你決定要送 App Review 並願意等審核。

這套工具走的是 Meta 目前的「**Instagram API with Instagram Login**」流程(不用連 Facebook 粉專),權杖開頭是 `IGAAT...`,呼叫網址是 `graph.instagram.com`(不是 `graph.facebook.com`,那是給另一套走 Facebook 登入的舊系統用的,兩邊權杖不通用)。

1. **確認 IG 帳號是專業帳號**:IG App → 設定 → 帳號類型 → 切換成「專業帳號」(商業或創作者皆可)。

2. **建立 Meta App**:[developers.facebook.com](https://developers.facebook.com) → 我的應用程式 → 建立應用程式 → 類型選「商業」。

3. **新增使用案例**:App 控制台左側「使用案例」→ 選「**管理 Instagram 的訊息和內容**」→ 繼續。會自動加上 `instagram_business_basic`、`instagram_business_manage_comments`、`instagram_business_manage_messages` 三個權限。

4. **把 IG 帳號加為測試人員**:
   - App 後台「應用程式角色」→「角色」→「新增人員」→ 角色選「**Instagram 測試人員**」→ 搜尋你的 IG 帳號送出邀請
   - **手機** Instagram App → 設定與隱私 → 應用程式和網站 → 測試人員邀請 → 接受(網頁版沒有這個選項)

5. **產生權杖**:App 後台「使用案例」→ Instagram 使用案例畫面「2. 產生存取權杖」→「新增帳號」。
   - **已知 bug**:這個彈窗常常在選帳號後直接跳回 IG 首頁,看不到列出權限的同意畫面,拿到的 Token 就只有基本資料權限。**卡住的話改用下面「手動授權」方法**,成功率高很多。
   - 短效 Token(約1小時)換長效(約60天):
     ```
     GET https://graph.instagram.com/access_token?grant_type=ig_exchange_token&client_secret={App Secret}&access_token={短效token}
     ```
     快到期前延長(不用重新授權):
     ```
     GET https://graph.instagram.com/refresh_access_token?grant_type=ig_refresh_token&access_token={長效token}
     ```

6. **找出 IG User ID**(App 後台表格顯示的 ID 不是這個):
   ```
   GET https://graph.instagram.com/v21.0/me?fields=id,username&access_token={你的token}
   ```

### 手動授權(繞過按鈕 bug)

1. **註冊 Redirect URI**:「使用案例」→ Instagram 使用案例「4. 設定 Instagram 商家登入」→「設定」→「有效的 OAuth 重新導向 URI」加入:
   ```
   https://abbyupyoung-cloud.github.io/ig-giveaway-tool/
   ```

2. **直接在瀏覽器網址列打開**(不透過按鈕):
   ```
   https://www.instagram.com/oauth/authorize?client_id=1348796017242096&redirect_uri=https://abbyupyoung-cloud.github.io/ig-giveaway-tool/&response_type=code&scope=instagram_business_basic,instagram_business_manage_comments,instagram_business_manage_messages
   ```

3. 同意後網址列會變成 `...?code=一串英數字#_`,複製 `code=` 後面那段。

4. 本機執行(App Secret 只留在自己電腦):
   ```powershell
   .\exchange-code.ps1 -Code "剛複製的code" -AppId "1348796017242096" -AppSecret "應用程式設定→基本資料裡按顯示"
   ```
   會印出 Token 和**實際拿到的權限清單**,`instagram_business_manage_comments` 有出現不代表留言讀得到——如前述,還需要 Advanced Access 審查通過才真正讀得到資料。

### PowerShell 備援腳本(同樣卡在 Advanced Access)

`fetch-comments.ps1`、`find-media-id.ps1` 邏輯正確,但一樣會因為 Advanced Access 未過審而抓回空結果,先不建議使用,保留供以後審查過了再用。

## 安全提醒

- Access Token / App Secret 等同帳號密碼,**不要貼到聊天記錄、不要 commit 進任何版本控制**。
- 懷疑權杖外洩時,回 App 後台重新產生一次會讓舊權杖失效。
