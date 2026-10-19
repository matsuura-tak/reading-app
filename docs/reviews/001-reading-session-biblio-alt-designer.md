（指揮役の注）書誌を端末の中で完結させる方法の調べもの（Takuma の 2026-10-20 の問い）のうち、designer の報告（使い勝手）。pdm（製品への影響）と tech-lead（作れるか、危険）も並べて調べている。判定ではない。報告の文はそのまま保存した。

# 書誌を端末の中で完結させる登録：使い勝手から見た調べもの（designer）

調べた日：2026-10-20。どの案も実機では試していない。アプリの画面も見ておらず、説明文とレビューだけを読んだ。秒数はすべて見積もり［推測］。新しく見つけたことには、調査の文書の続きの番号として R-36〜R-55 を振った（下の「HIG と手本」に、出典と確認日をまとめた）。リポジトリの中の資料は I-1〜I-4 と書いた。

## 結論と推す形

**推す形 F-1：「奥付から写して、行を選ぶ」を主の道にし、「手で入れる」を同じ所に置く。外部の API は使わない。バーコードと書名で探す道は外す。**

流れ：S-8「奥付から写す」→ 奥付にかざして「写す」→ 止めた写真の行に番号つきの枠が付く → 書名の行と著者の行を押す → 下の欄で確かめて直す →「加える」。

- **型は撮る道と同じにする。** v1.0 に入った撮る道は「撮る → 枠を選ぶ → 欄で直す → 写真は残さない → 読めなければ撮り直すか手で入れる」の形（AC-65〜AC-69、AC-94）。奥付もこの形にして、新しい操作の型を増やさない。
- **アプリが先に当てるか（初めの選択）は、あとで決める。** 撮る道と同じく、アプリが当てた行を先に選んでおき、利用者が別の枠を押して替える形にするか、という問題。本物の奥付で当たる率を見てから決める（未解決）。当てなくても流れは成り立つ。
- **書名のない本がなくなる。** 本はいつも利用者が確かめた書名を持って加わる。そのため、書誌を待つ、見つからない、ISBN を書名の代わりに出す、ウィジェットの「今の本」（決定 66）といった状態がまとめて消える。
- **次点 F-2：** tech-lead が「書誌のデータをアプリに入れる案（C）は大きさも新しさも足りる」と判断したときだけ選ぶ。形は「バーコード → アプリの中の書誌 → 無ければその場で奥付から写す」。積読をまとめて入れる速さが A に近づく。

**いちばん強い反論**
- 1冊を加える手間は A の約1.5倍、10冊では約3〜5倍になる（40〜60秒 → 2.5〜4分）［推測］。
- 読書アプリはどれもバーコードで書名が出る（R-8、R-10、R-48）。積読をまとめて入れたい人には、古くて面倒に見える。
- 日本語の奥付（縦組み、漢数字の日付、小さい仮名）を本物の写真で読めるかは、まだ誰も確かめていない（I-1）。

**それでも推す理由**
1. **外部に頼らない案の中で、「見つからない」がいちばん起きにくい。**
   - 奥付は「本の本文が終わった後や巻末に設けられる」もので、書名、著者、発行所、発行年月、刷数を載せる（R-55）。
   - 手元の本そのものの字を写すので、次の問題が起きない。
     - 出て14日以内の本は、今の方法だと5件中3件しか取れない（I-3）。
     - データベースに当てる形には、違う品を当てる失敗がある（Vivino「スキャンしても毎回違うワインを提案してくる」R-54）。
   - 競合への不満で多い「見つからない」（R-5、R-7）が、仕組みの上で起きなくなる。
2. **読み違いと取り違えを、その場で目に見える形で直せる。**
   - 自動で欄に振り分ける形は、並びが違うと気づかないまま外れる。名刺のアプリで「たて名刺で、名前を横書きの郵便番号の下4桁部を認識する」（R-51）。
   - 読み違いは、直せることが前提になる。レシートのアプリで「読み取れても文字化けが多いので、都度手動での修正が必要」（R-52）。
   - 押して選ぶ形なら、どの行がどの欄に入ったかが枠の札で見え、欄でそのまま直せる。
3. **撮る道と同じ型なので、覚えることも作るものも増えにくい。** HIG「Prefer system gestures and behaviors people are already familiar with」（R-47）、「Use concepts that people know.」（R-23）。
4. **画面と文言が減り、プライバシーは「外に送らない」と言い切れる**（性格語「確か」）。消えるものは下の「今の仕様への影響」に挙げた。
5. **性格語に合う。**
   - 紙の本の慣習である奥付を、そのまま入力に使う（紙の側）。通信の待ちがない（静か）。
   - 毎晩の道（D-1）には触れない。登録は1冊に1回で、数週に1回の作業［推測］。

使い勝手だけで比べれば、A（今のまま）がいちばん速い。それは変わらない。上の推奨は、「外部の API を使わない」という Takuma の条件の中での推奨。

## 案ごとの流れと手間

- 出発点は S-1 か S-6。カメラの許可は済んでいるものとする。
- 秒の置き方
  - 押す1回：0.7〜1秒
  - 本を取って裏返す：2〜3秒（I-2）
  - 裏表紙の側から奥付を開く：2〜4秒
  - かざして写す：2〜3秒
  - 読み取り：0.5〜1.5秒。Mac では1枚 0.25〜0.36秒だが、初回だけ 22.69秒かかった（I-1）
  - かな漢字で書名を打つ：8〜15秒、著者：5〜10秒
  - 国立国会図書館サーチの応答：p50 2.30秒、p90 7.18秒（I-3）

| 案 | 1冊の流れ | 1冊：押す回数／秒 | 10冊 | 読めないとき、手で直す道 | 使い勝手 |
|---|---|---|---|---|---|
| A 今のまま | 本を加える → バーコードを続けて読む → かざす（行に書名が出る）→ 1冊を本棚に加える | 3回／8〜14秒 | 40〜60秒。書誌は1件ずつあとから埋まる | 通信がなければ ISBN だけで加わる（pending）。0件なら notFound。どちらも、あとで本の画面の「直す」で直す | いちばん速い。代わりに、待つ・見つからない・ISBN を書名の代わりにする状態が、S-1、S-2、S-3、S-6、S-7、S-9、W-1、W-2 に広がる |
| B 奥付・自動 | 奥付から写す → 写す → 欄に自動で入る → 全部の欄を確かめる → 加える | 4回／10〜16秒（合っていれば） | 2〜3.5分 | 欄で直す。取り違え（書名の欄に発行所が入るなど）が、気づかれないまま残るおそれがある（R-51） | 速いが「確か」に反する。奥付の並びは出版社ごとに違う［推測］ |
| B 奥付・押して選ぶ | 奥付から写す → 写す → 書名の枠、著者の枠を押す → 欄で確かめる → 加える | 5回／12〜20秒 | 2.5〜4分 | 撮り直す、別の枠を押す、欄で直す、手で入れる。どれもその場でできる | 取り違えが起きない。撮る道と同じ型 |
| B 欄ごとにシステムの文字スキャン | S-8c の書名の欄 → スキャンのボタン → 書名の行だけを枠に入れる → 挿入 → 著者も同じ → 保存 | 9回／20〜30秒 | 3.5〜5分 | 欄で直す | 独自の部品が要らない（R-39）。ただ、字の小さい奥付で1行だけを枠に入れるのは難しく［推測］、手数も多い。日本語の表示名と VoiceOver での動きは見ていない |
| C 書誌をアプリに入れる | A と同じ（待ちなし、通信なし）。無い本は「アプリの中の書誌にありません」→ その場で B か D | 3回／5〜8秒。無い本は +12〜20秒 | 40〜60秒と、無い本の分 | その場で B か D | 速さは A と同じくらい。新しい本ほど無い。アプリの大きさと更新は tech-lead が見る |
| D ISBN と手入力 | バーコードで ISBN → 書名と著者を打つ → 保存 | 5〜6回と打つ時間／20〜35秒 | 4〜6分 | 打ち直す | 部品は今のまま。打つのがいちばん重い。奥付が書名と著者の2行になりやすく、D-2 が細る。バーコードを読んでも書名が出ないので、ほかのアプリに慣れた人は戸惑う［推測］ |
| E 表紙・押して選ぶ | 表紙から写す → 写す → 書名の枠、著者の枠を押す → 加える | 5回／10〜16秒（裏返さない分は速いが、帯の宣伝の字を避けるのに +1〜3秒） | 2〜3分 | B の押して選ぶ形と同じ | 飾った字体、縦組み、英字の題は読みにくい［推測］。出版社と年はほとんど取れない |
| **F-1（推す）** | B の押して選ぶ形と手で入れる道を、同じ所に置く | 5回／12〜20秒（当てが合えば 3〜4回／10〜16秒） | 2.5〜4分 | その場で撮り直す、枠を替える、欄で直す、手で入れる | 上の結論のとおり |
| F-2（次点） | C に F-1 を合わせる | 本がアプリの中の書誌にあれば C、無ければ F-1 | 40〜60秒と、無い本の分 | その場で F-1 | C が作れるときだけの選択肢 |

- **最初の1冊（F-1）**
  - S-1（本0冊）「本を加える」→ S-8「奥付から写す」→ システムの許可の確認 → 写す → 書名と著者を選ぶ → 加える → S-1 に今の本として出る。
  - 押す回数は6〜7回（許可の1回を含む）、約15〜25秒［推測］。
- **何冊も続けて加える（F-1）**
  - 確かめの所の2つ目のボタン「加えて次の本を写す」（.bordered）で、カメラに戻る形にする案。1冊ずつ保存するので、途中で閉じても失うものがない。今の決定 26（加えずに閉じるときの確認）は要らなくなる。
  - まとめて撮る道（背表紙の写真。I-1 の spike では合成の画像で 14/14 読めた）は、v1.1 の候補として残す。
- **読み取りが崩れたとき**
  - 撮る道と同じにする：読めた行が0なら案内の文と「撮り直す」「手で入れる」（AC-68 の型）、違う行は別の枠を押す（AC-66 の型）、崩れた字は欄で直す（AC-67 の型）。
  - 読み取りを待つ間も「手で入れる」を押せるようにする（AC-94 の型）。

## 奥付の体験の評価

| 性格語 | 合い方 |
|---|---|
| 静か | 合う。通信の待ちも「見つかりません」の知らせもない。ただ、カメラの画面で動く枠は落ち着かないので、写したら写真を止めてから選ばせる |
| 確か | 合う。手元の本そのものの字を、利用者が選ぶ。写真は残さず（AC-69 の型）、外に送らないと言い切れる。弱い所は読み違いで、小さい仮名や濁点が別の字になる例がある（「ッュ等小書き文字や、プブ等濁音・半濁音はほぼエラー」R-52）。欄を大きく見せ、その場で直せるようにして補う |
| まっすぐ | 弱い。1冊の手数が A より2回多い。どの画面も主操作を1つ（写す、加える）にして補う |
| 急かさない | 合う。自動では撮らず、利用者が「写す」を押す（HIG「Minimize use of time-boxed interface elements.」R-47）。1冊ずつ保存する |
| 紙の側 | いちばん合う。紙の本の慣習を、飾りではなく機能として借りる。奥付は 1722年の触書に始まり、出版法で載せることが決まった、日本の本の型（R-55） |

- **ポートフォリオの「10秒の瞬間」になるか：なりうる。ただし3つ目の差にはしない。**
  - 見せるのは D-2（読み終えた夜の奥付）の糸の始まりとしてにする。
  - 場面は、裏表紙の側から開く → かざして「写す」→ 枠に「書名」「著者」の札が付く →「加える」→ 本の画面に、同じ奥付の型（名前と値の2列。決定 33）で出る。約10〜15秒［推測］。
  - 「始まりの奥付と、終わりの奥付」として語れる。奥付を撮って登録すると説明するアプリは、今回の検索（日本の App Store、語「読書管理 表紙」）では見つからなかった（R-49。網羅はしていない）。
  - 見せる条件：本物の奥付で読み取りが安定すること（I-1 では未検証）。光る枠や動きなどの飾りは足さない（R-23「Don't mistake delight for decoration.」）。
- **気をつけること**
  - **結末が目に入るおそれ。** 奥付は本文が終わった後にある（R-55）。文庫は解説や広告のあとが多いが、単行本は本文の直後のこともある［推測］。案内の文で「裏表紙の側から開く」と伝える。Takuma が手元の小説5冊で確かめると早い。
  - **両手がふさがる。** 本を開いて押さえる手と、スマホを持つ手が要る。「写す」で写真を止めれば、本を置いてから落ち着いて選べる（capturePhoto、R-38）。
  - **夜の暗い部屋では読み取りが落ちる［推測］。** 案内は DataScanner が自分で出す（「guidance for the user」R-37）。
  - **年があいまい。** 奥付には発行、改版、刷の年が並ぶ（R-55「発行年月、版数、刷数」）。PRD の「出版年」は1つなので、どの年を入れるかを決める必要がある（未解決）。

## HIG と手本（出典つき）

### HIG と標準部品
- **主の部品は DataScannerViewController（R-36、R-37）。**
  - 「similar to the Live Text interface in the Camera app」と書かれている。映像、案内、枠の強調、押して選ぶ操作（`dataScanner(_:didTapOn:)`）をシステムが受け持つ。
  - 文字は読む順に並ぶ（「appear in the reading order」）。
  - 使えるのは A12 以上の端末。iOS 26 が入る機種なら、どれも当てはまる見込み［推測］。
  - 写真を止めるには `capturePhoto()` を使う（R-38）。縦組みの行は、iOS 26 の RecognizeDocumentsRequest が向き `topToBottom` で返した（R-42、I-1。合成の画像での結果）。
- **カメラのアプリの Live Text（日本語の名前は「テキスト認識表示」）に、利用者は慣れているか（R-43）。**
  - 慣れていそうなこと：黄色い枠は、カメラのアプリの既定の動きで見慣れている見込み［推測］。設定には「検出されたテキストを表示」をオフにする項目があり、日本語にも対応している（R-44）。
  - 手数：カメラのアプリで文字を取るには、ボタン → 長押し → つかみの点 → メニュー、の4手がいる（R-43）。アプリでは、DataScanner の押して選ぶ形で1手にする。
  - 「テキスト認識表示」という言葉は画面に出さない。
  - 使っている人の割合の数字は見つけていない（見ていない）。レシートのアプリのレビューに「同じiPhoneでレシートをカメラ撮影して文字認識したら、狂いなく読み取っています」（R-52）という声はある。
- **主にしない標準部品**
  - 欄ごとにシステムの文字スキャンを使う形（`captureTextFromCamera`、R-39）：手数が多い。
  - 止めた写真の Live Text（`ImageAnalysisInteraction`、R-40）：用途はコピー、翻訳、共有で、欄に振り分ける作りではない。
  - 書類スキャン（`VNDocumentCameraViewController`、R-41）：書類を1ページずつ撮って画像を返す部品で、奥付1ページには手数が多い。
- **許可と文言**
  - 許可は、押したときに求める（R-27）。
  - 理由の文は短い完全な文にする。「Aim for a brief, complete sentence … avoid passive voice, and include a period at the end.」（R-46）
- **当てについて：** 欄に当てを入れておくのは HIG の考えに合う。「prefill fields with reasonable default values, which can minimize decision making and speed data entry」（R-45）。ただし見える形で、外せるようにする。
- **アクセシビリティ：** 「Offer alternatives to gestures … more than one type of physical interaction」（R-47）。手で入れる道を同じ画面に置くのはこのため。
- **開けなかったページ：** HIG の Live Text のページ（JSON と HTML のどちらも 404）。

### 手本（良い点と悪い点）

| 例 | 良い点 | 悪い点 | 取り入れること |
|---|---|---|---|
| Goodreads（表紙を撮る。R-48） | 「Add a book in seconds by scanning the cover」 | 当てるのはサーバーのデータベース［推測］。重なりの不満「Duplicates books occasionally」 | 速さの当たり前は「数秒」 |
| 日本の読書アプリ（R-49） | 表紙（Libri）、背表紙をまとめて（Passim「AIが背表紙を読み取って一括登録」） | 評価は0〜3件で、質は分からない | まとめて撮る道は v1.1 の候補 |
| 名刺（R-50、R-51） | Eight、myBridge は「文字認識と人の手による正確なデータ化」 | 自動で欄に振り分ける形が、縦組みで外れる。「ほぼほぼ手打ちで打ち直すハメに」 | 欄は利用者が選ぶ。当てるなら見える形にする |
| レシート（R-52、R-53） | 「読み取り内容はあとから編集・追加できます」 | 「文字化け」「手入力必須」。小さい仮名と濁点の読み違い | 欄をその場で直せること。459,414件の評価を持つシンプル家計簿は「レシート読み取りで挫折した」人に向け、「すべてのデータは端末内に保存」と打ち出している。端末の中だけ、は売りになる |
| ワイン（Vivino。R-54） | 「ラベルを撮影するとすぐに」評価を出す | 「毎回違うワインを提案」。データベースに当てる形の失敗 | 奥付を写す形は、違う本を当てることがない |

## 今の仕様への影響

**画面**
- **S-8 本を加える**
  - 行を2つにする。先頭の行「奥付から写す」（記号 `text.viewfinder`［名前は要確認］）と「手で入れる」。
  - 下の文 `register.footer`（国立国会図書館に送る旨）は、端末の中で読む旨の文に替える。
  - S-8 をなくし、Form を中心にする案もある。仕様の段で決める。
- **S-8a バーコード、S-8b 書名で探す：なくす。** F-2 なら、S-8a はアプリの中の書誌を引く形にし、S-8b はアプリの中の書誌を探す形にする。どちらも通信なしと失敗の状態が要らない。
- **新しい S-8d 奥付を写す（写す前と写したあとの2つの状態）**
  - 部品は撮る道（S-3 の `mark.photo` と写真の確かめの画面）と同じにする。撮る道の仕様はまだ書いていないので、両方を一緒に書く。
  - 7つの状態
    - オフライン：なし（通信を使わない）
    - 権限を断られたとき：`camera.denied` と「設定を開く」。文から「書名で探す」を消す
    - 一部だけ読めたとき：読めた行だけ枠を付け、無い欄は打つ
- **S-8c 手で入れる：** 両方の道の確かめの画面にもなる。書名は必ず、著者は空でもよい（今のまま）。
- **S-1、S-2、S-3、S-6、S-7、S-9：** 書名の所の「ISBN 978…」、`book.pendingInfo`、`book.infoNotFound`、「書名と著者を入れる」の状態がなくなる。各画面の状態の表の「一部だけ読めたとき」が軽くなる。
- **S-7a 本を直す：** `book.edit.notFoundNote` がなくなる。
- **W-1、W-2：** 決定 66 と `widget.currentBookAsTitle` がなくなる。どの本にも書名がある。
- **奥付（S-7、S-9）**
  - 行は利用者が確かめた値になる。
  - 出版社は奥付の「発行所」の行から取れる見込み［推測］。レーベルは奥付に載るとは限らない（見ていない）。そのため「同じレーベル」の理由が弱まるおそれがある（pdm）。
- **S-10 設定：** 書誌の出どころ（`settings.dataSources` と CC BY のリンク）がなくなる。F-2 で国立国会図書館のデータを入れるなら残す。
- **変わる AC の目安（直すのは pdm）**
  - 外れる：書名で探す（AC-4〜AC-6）、通信と問い合わせ（AC-9〜AC-11、AC-113）、出どころのクレジット（AC-93）。
  - 中身が変わる：AC-2、AC-3（バーコードの流れ）、AC-12（カメラを断ったときの文）、AC-92（著者の取り出し。選んだ行の末尾の「著」「訳」を除く決まりとして使い直せる見込み）、AC-103（外に送るものはカードの共有だけになる）。

**文言（見当。日英）**
- 消す：`register.barcode`、`register.search`、`register.footer`、`scan.*`、`search.*`、`book.pendingInfo`、`book.infoNotFound`、`book.isbnAsTitle`、`book.edit.notFoundNote`、`widget.currentBookAsTitle`、`settings.dataSources*`
- 足す（キーの名前は仮）
  - `register.colophon`：奥付から写す ／ Scan the Colophon
  - `colophonScan.hint`：裏表紙の側から開くと、奥付があります。奥付のページを写してください。 ／ Open the book from the back cover to find the colophon, then point the camera at it.
  - `colophonScan.capture`：写す ／ Capture
  - `colophonScan.pickTitle`：書名の行を押してください。 ／ Tap the line with the title.
  - `colophonScan.pickAuthor`：著者の行を押してください。著者がなければ、そのまま進めます。 ／ Tap the line with the author's name, or continue without one.
  - `colophonScan.none`：文字を読み取れませんでした。明るい所で撮り直すか、手で入れてください。 ／ No text was found. Retake the photo in better light, or enter the details manually.
  - `colophonScan.retake`：撮り直す ／ Retake
  - `register.onDevice`：写真は残しません。文字の読み取りは、この iPhone の中で行います。 ／ Photos aren't saved. Text is read on this iPhone.
- 直す
  - `camera.denied`：「書名で探すか」を消す。
  - カメラの許可の理由（NSCameraUsageDescription）：「よむまは、本の奥付と読んだページの一行を写して、文字を読み取るためにカメラを使います。写真は残しません。」 ／ Yomuma uses the camera to read the colophon and a line from the page you're reading. Photos aren't saved.
- 英語は長くなるので、S-8d を Double-Length で確かめる画面に足す。

**トークン（見当）**
- 色は足さない（案A の白、黒、灰）。
- 写真の上の枠の線は、白と黒の2重にする。どんな写真の上でも 3:1 を取るため［推測。数字は仕様で出す］。
- 選んだ枠は、線の太さと札（「書名」「著者」）で示し、色だけにしない（B-5）。
- 余白は今の `space.*` のまま。
- 記号：`text.viewfinder`、`arrow.counterclockwise`（撮り直す）、`square.and.pencil`（今もある）。名前は SF Symbols のアプリで確かめる。
- 触覚は撮る道に合わせる（R-28）。

**アクセシビリティ**
- **VoiceOver**
  - 写す前：プレビューの読み上げは「カメラ。奥付を写しています。」。動く枠は読み上げに出さず、先に「写す」と「手で入れる」に届く順にする。
  - 写したあと：知らせ「12行を読みました。書名の行を選んでください。」を読み、焦点を1つ目の枠に移す。
  - 枠は読む順に並べる（縦組みなら右の列から）。読み上げは「1、こころ、ボタン」。選ぶと isSelected と値「書名」を読む。
  - 狙ってかざすのが難しい人のため、手で入れる道をいつも同じ画面に置く（R-47）。
- **大きい文字**（accessibility1 以上）：写真の上の枠をやめ、読めた行を List で縦に並べる。識別子は同じ。下端の「加える」は固定する（決定 59）。
- **Voice Control：** 枠に番号を見せる。
- **押せる範囲：** 枠は 44×44pt 以上に広げる。重なるときは List の形に替える［推測］。
- **動きを減らす設定：** 枠は出すだけで動かさない。
- **透明度を下げる設定：** 写真の上に素材を使わない。

## Takuma に決めてほしいこと

1. **登録の形：外部の API を使わない形にするなら、F-1「奥付から写して行を選ぶ」と「手で入れる」にするか**
   - 推奨：F-1。tech-lead がアプリの中の書誌（C）を作れると言ったときだけ、F-2（バーコード → アプリの中の書誌 → 無ければ奥付）。
   - いちばん強い反論：1冊の手間が約1.5倍、10冊では約3〜5倍［推測］。競合はどれもバーコードで書名が出る。日本語の奥付の読み取りは、本物ではまだ確かめていない。
   - 元に戻せるか：戻せる。v1.1 で A か C を足せる。ただし、書名のない本の状態（待つ、見つからない）を作り直す手間がかかる。
   - 見てほしいファイル：この報告、/Users/takumamatsuura/reading-app/docs/adr/0004-bibliographic-lookup.md、並べて出る tech-lead と pdm の報告、絵の下書き /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/biblio-alt-design/notes-and-sketches.md
2. **v1.0 で、積読をまとめて入れる速さをどこまで求めるか**
   - 推奨：v1.0 は1冊ずつ（奥付）で出す。続けて加えるボタンは置く。まとめて撮る道（背表紙の写真）は v1.1 の候補にする。
   - いちばん強い反論：次の1冊（3b）は積読が入っていないと働かない。最初に積読を10冊入れる人には、2.5〜4分は重い［推測］。
   - 元に戻せるか：戻せる。あとから道を足すだけ。
   - 見てほしいファイル：この報告の「案ごとの流れと手間」

## 変更したファイル
- リポジトリ：なし。
- スクラッチパッド（リポジトリの外）
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/biblio-alt-design/notes-and-sketches.md：秒の置き方、案ごとの表、推す形の画面の文字の図、奥付の糸の図
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/biblio-alt-design/scripts/：docc.py、html2txt.py、apps.py、rss.py（取り出し用）
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/biblio-alt-design/dl/：取ってきた JSON と HTML。抜き出した文は同じフォルダの apple-docs.txt、support-livetext.txt、feature-availability.txt、hig-more.txt

## 実行したコマンドと結果
確認日はすべて 2026-10-20。コマンドは `curl -s -o <名前> <URL>` と `python3 -I scripts/<名前>.py`。

**Apple の文書（DocC の JSON。どれも HTTP 200）**
- R-36：https://developer.apple.com/documentation/visionkit/datascannerviewcontroller
- R-37：https://developer.apple.com/documentation/visionkit/scanning-data-with-the-camera
- R-38：https://developer.apple.com/documentation/visionkit/datascannerviewcontroller/capturephoto()
- R-39：https://developer.apple.com/documentation/uikit/uiresponder/capturetextfromcamera(_:) と https://developer.apple.com/documentation/uikit/uiaction/capturetextfromcamera(responder:identifier:)
- R-40：https://developer.apple.com/documentation/visionkit/enabling-live-text-interactions-with-images と https://developer.apple.com/documentation/visionkit/imageanalysisinteraction
- R-41：https://developer.apple.com/documentation/visionkit/vndocumentcameraviewcontroller
- R-42：https://developer.apple.com/documentation/vision/recognizedocumentsrequest
- 読んだが報告では引いていない：supportedTextRecognitionLanguages、dataScanner(_:didTapOn:)、HIG Camera Control

**HIG（JSON。HTTP 200）**
- R-45：https://developer.apple.com/design/human-interface-guidelines/entering-data
- R-46：https://developer.apple.com/design/human-interface-guidelines/privacy
- R-47：https://developer.apple.com/design/human-interface-guidelines/accessibility
- 開けなかった：https://developer.apple.com/design/human-interface-guidelines/live-text （JSON も、WebFetch の HTML も 404）

**Apple サポートと機能の一覧（HTTP 200）**
- R-43：https://support.apple.com/ja-jp/guide/iphone/iphcf0b71b0e/ios と https://support.apple.com/en-us/guide/iphone/iphcf0b71b0e/ios
- R-44：https://www.apple.com/ios/feature-availability/ （Live Text の言語に「Japanese」がある）
- WebSearch（文字の欄にカメラで入れる操作の、Apple の公式ページ）：公式のページは見つからなかった。

**App Store の検索（itunes.apple.com/search）**
- R-48：term=Goodreads（us）、term=StoryGraph（us）
- R-49：term=読書管理 表紙（jp）
- R-50：term=名刺管理 Eight（jp）
- R-52、R-53：term=レシート 家計簿（jp）
- R-54：term=Vivino（jp）
- 結果がこの調べものの役に立たなかった：term=book cover scanner library（us。書類スキャンのアプリばかり）

**レビューの RSS（mostrecent、page=1。Goodreads だけ page=2 も）**
- R-51：id 1618387863（名刺マネージャ）
- R-52：id 1571273616（レシートスキャン）、id 1274359127（レシマル）
- R-54：id 414461255（Vivino）
- R-48：id 355833469（Goodreads）
- 当たりが少なく、報告には引かなかった：id 445850671（Zaim）、id 594145971（マネーフォワード ME）

**その他**
- R-55：https://ja.wikipedia.org/wiki/奥付 （WebFetch の要約を通して読んだ。原文はそのままの形では見ていない）

**リポジトリの中の資料**
- I-1：/Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-reselect-tech-lead.md（合成の背表紙の spike。本物の写真と、DataScanner の縦書きは未検証）
- I-2：/Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-integrate-designer.md（登録の秒の見積もり）
- I-3：/Users/takumamatsuura/reading-app/docs/adr/0004-bibliographic-lookup.md（応答の秒、出て14日以内の本の取れ方）
- I-4：/Users/takumamatsuura/reading-app/docs/prd/001-reading-session.md（AC-65〜AC-70、AC-94。撮る道の型）

## 未解決
- **奥付の「年」と「刷」**
  - 奥付には発行、改版、刷の年が並ぶ。PRD の「出版年」1つに、どれを入れるかを決める必要がある。
  - 刷（自分の一冊にしかない事実）を奥付に出す案もありうるが、PRD にないので足していない（pdm と Takuma）。
- **レーベル：** 奥付に載るかは見ていない。載らなければ「同じレーベル」の理由が弱まる（pdm）。
- **受賞の照合：** 写した書名と著者の字の揺れ（小さい仮名の読み違い。R-52）で、合わない側に倒れることが増えるおそれがある（pdm、tech-lead）。
- **当て（アプリが先に選ぶ行）を入れるか：** 本物の奥付20冊ほどで当たる率を見てから決める（tech-lead の spike）。
- **iPhone での読み取りの確かめ（tech-lead）**
  - DataScanner と RecognizeDocumentsRequest で、縦組みの奥付と漢数字の日付を読めるか。
  - 初回の遅さ（Mac では 22.69秒）が iPhone でどうなるか。
- **見ていないもの**
  - 欄ごとにシステムの文字スキャンを使うときの、日本語の表示名と VoiceOver での動き
  - Live Text の利用率の数字
  - どのアプリの画面も
  - 奥付にいつも ISBN の行があるか（あれば黙って残し、重なりの確かめに使う案）
  - 結末が目に入るか（実物の本で確かめていない）
- **仕様を直すときに決めること**
  - S-8 を残すか、Form を中心にするか。
  - 1冊ずつ保存にするなら、決定 26 を外すこと。
  - 撮る道（6）の画面と、部品を一緒に書くこと。
- **確かめの印：** 両方のテンプレートの最後の「確かめ」には、印を付けていない。この調べものは調査と仕様の文書を書かない仕事だったため。R-36〜R-55 を design/001-reading-session-research.md に写すのは、Takuma が決めてからにする。

## 記録（指揮役が保存するときに書き足す）
- 種類：調べもの（designer）
- 日付：2026-10-20
- 判定したモデル：opus（fable が使えないため）
- 指揮役の注：pdm の推す F1（バーコードで ISBN、書名はあとで）と、designer の推す F-1（奥付から写して行を選ぶ。バーコードと書名で探す道は外す）は、バーコードの扱いが分かれる。tech-lead の報告を待って、まとめで扱う
