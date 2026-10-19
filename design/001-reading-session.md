# デザイン仕様 001-reading-session：夜の入口、本の出口（v1）芯の画面

- 対象の PRD：docs/prd/001-reading-session.md（コミット 9f7c5d9。G0 承認済み）
- 調査：design/001-reading-session-research.md（コミット f8ed008。この仕様より先に書いた）
- 書いた役：designer　日付：2026-10-19。2026-10-20 に G1 の判定 r1 の指摘で直した（docs/reviews/001-reading-session-G1-design-reviewer-r1.md の指摘1〜17、docs/reviews/001-reading-session-G1-tech-lead-design-r1.md の要修正1〜3、提案1〜5、C の答え）。同じ日に、tech-lead の 7（docs/adr/0003-vertical-composition.md、docs/adr/0004-bibliographic-lookup.md、contracts/entry-urls.md、contracts/widget-snapshot.schema.json、contracts/test-hooks.md）の申し送りと、design-reviewer r2 の「見たが指摘にしないもの」を入れた（裁定 28。方向、範囲、AC は変えていない。決定 62〜65 を足した）。同じ日に、tech-lead の G1 の直し（コミット 6c46e54。reviewer r1 の要修正2。docs/reviews/001-reading-session-G1-7-fix1-tech-lead.md の申し送り）を受けて、書名のない今の本のウィジェットを決めた（決定 66。文言キー `widget.currentBookAsTitle` と `widget.spoken.noLine` を足した。AC は変えていない）
- 図とトークン：design/001-reading-session/screens.md（画面ごとの並びを文字で描いた図）、design/001-reading-session/tokens.md（色、文字、余白、触覚のトークン）
- 原則の番号 B-1〜B-6 は .claude/skills/craft-designer/SKILL.md にある。R-n は調査の 8 の発見の番号。
- 範囲：芯だけ（裁定 24。PRD 冒頭の進め方 (i)）。選択肢の画面は、芯の G1 で速さを測って v1.1 に回す所が決まってから、別に書く。
- 書き方の決まり
  - 識別子と文言キーは PRD のものをそのまま使う。PRD になく、この仕様で足したものは、6 と 7 に「足した」と書く。承認の後は、この仕様の 6 と 7 の表を正とする（PRD 11 の冒頭）。
  - 選択肢に属するものは「選択肢 (n)」と書き、置き場所だけを書く。(n) は PRD 冒頭の回す順の名前。
  - Takuma に確かめている所は「Takuma に確かめ中（推奨で進めた）」、実機の確かめや聞き取りを待つ所は「結果待ち」と書く。推測には［推測］と書く。2026-10-20 の直しの時点で、Takuma に確かめ中の所はない（0 の「決まったことと、結果待ち」）。
  - アプリの名前は「よむま」。英語の文では仮に Yomuma と書いた（英語の表示名は未定。10）。design/explore/integrated/ の探りの絵にある仮の名前は使わない（PRD 付記の G1-9。探りの README の頭に、古い名前だという注を足した）。

## 0. 範囲と、選択肢との境目

### 芯の画面（この仕様で描く）
| 番号 | 画面 | 出し方 |
|---|---|---|
| W-1 | ロック画面のウィジェット（accessoryRectangular） | 利用者がロック画面に置く |
| W-2 | 小のウィジェット（systemSmall。ホーム画面と StandBy） | 利用者が置く |
| S-1 | しおりの画面 | アプリの根（NavigationStack の根。タブなし） |
| S-2 | 読書中の画面 | S-1 の上の fullScreenCover |
| S-3 | しおりを挟む画面（道を選ぶ） | 終えたとき：S-2 と同じ全画面の中で入れ替える。読まずに挟むとき：S-1 のシート |
| S-3a | 一行を入れる | S-3 から押し出し |
| S-3b | ページだけ入れる | S-3 から押し出し |
| S-4 | 結果の画面 | 全画面の中で S-3 と入れ替える |
| S-5 | 置き方の案内 | S-1 のシート（1回だけ） |
| S-6 | 本棚 | S-1 から押し出し |
| S-7 | 本の画面 | S-6 から押し出し |
| S-7a | 本を直す | S-7 のシート。書誌が見つからない今の本は、S-1 の「書名と著者を入れる」から S-1 のシートでも開く（AC-10） |
| S-7b | 記録を直す | S-7 のシート |
| S-8 | 本を加える（道を選ぶ） | S-1 か S-6 のシート。S-9 の「本を加える」からは S-9 の上のシート |
| S-8a | バーコードを続けて読む | S-8 から押し出し |
| S-8b | 書名で探す | S-8 から押し出し |
| S-8c | 手で入れる（本） | S-8 から押し出し |
| S-9 | 読み終えた画面（奥付と次の1冊） | S-1 のシート |
| S-10 | 設定 | S-1 から押し出し |
| 部品 N | 知らせの帯 | S-1、S-2、S-4、S-7、S-8a、S-8b、S-9、S-10 の中（入れる画面の Form（S-3a、S-3b、S-7a、S-7b、S-8c）の保存の失敗は、帯でなく Form のいちばん上の行に出す。5） |

### 選択肢（今回は描かない。置き場所だけ）
| 回す順 | 中身 | 置き場所 |
|---|---|---|
| (課金) | 有料の見た目、見本 `store.preview`、購入のシート、購入の復元（AC-104〜AC-111） | S-10 の「情報」の節の上に節を1つ。回す所が決まってから書く |
| (3) | 読み終えのカード `finish.card.share`、ふりかえりの1行 `finish.reflection`（AC-84、AC-85、AC-127〜AC-129） | S-9。ふりかえりは奥付の上、カードは次の1冊の下。回す所が決まってから書く |
| (4) | 受賞 `colophon.award`、次の1冊の「同じ賞」の理由と新しい本の行 `next.addToShelf`（AC-19〜AC-21、AC-83、AC-112） | S-7 と S-9 の奥付の出版年の下と、S-9 の候補のいちばん下。回す所が決まってから書く |
| (5) | 予約した Live Activity、アプリの外からの「読み始める」と「終える」（AC-36〜AC-38、AC-41、AC-97、AC-98、AC-114〜AC-120、AC-130〜AC-132、AC-136） | ロック画面と Dynamic Island、Control、S-10 の「入口の時刻」の節と `settings.liveActivity.off`。回す所が決まってから書く |
| (ショートカット) | 「どこまで読んだ？」「続きを読む」（AC-121〜AC-124、AC-133〜AC-135） | 新しい画面は足さない（product.md 5 の守ること）。言い方、声の文、小窓は回す所が決まってから書く |
| (5) と (ショートカット) | オフラインのインテント、入口の一覧（AC-125、AC-126） | 上の2つと同じ |
| (6) | 撮って一行を取る道（AC-65〜AC-70、AC-94） | S-3 の `mark.photo` のボタンと、写真の確かめの画面。回す所が決まってから書く |

### 選択肢がないときの形（芯の画面が選択肢に触れる所）
- S-7 と S-9 の奥付：受賞の行を出さない。AC-17 と AC-77 は受賞の行を除いて判定する（PRD 11 の冒頭）。
- S-9 の次の1冊：理由は「同じ著者」「同じレーベル」「積読から」の3種類。新しい本の行はない（候補は積読だけ）。ふりかえりの1行とカードの節もない。
- S-3：道は3つ（一行を入れる、ページだけ入れる、あとで挟む）。
- S-10：入口の時刻の節と、Live Activity の言葉を出さない。「一行と書名を隠す」の説明はウィジェットのことだけを言う。購入の節もない。
- S-1：Live Activity の知らせや言葉を出さない。
- 選択肢を v1.0 に残すと決まったら、上の置き場所に足す。芯の画面の並びと識別子は変えない。

### 決まったことと、結果待ち
- Takuma が決めた（2026-10-19。docs/approvals/001-reading-session-G1-decisions.md）
  1. 見た目の方向：調査の案A「紙の版面」（白、黒、灰。アクセント色なし。本の言葉だけ明朝の縦書き。タブのない1画面）。
  2. S-1 の主操作のほかの2つのボタン（どこまで読んだかを入れる、読み終えた）を、主操作より目立たない形で画面に出しておく。理由は「読み終えた」が本の出口への唯一の扉だから。形は .bordered（灰の塗り。決定 4）。
- 結果待ち
  - Q-A（伏せた向き）と Takuma の実機の確かめ：伏せる案内の1行は、文を2つ用意した（7 の `bookmark.flipHint`）。どちらの結果でも S-1 の並びは同じ。PRD では伏せる道と「読み始める」は同じ重みの道で、目に見える主操作は「読み始める」。
  - 1b、2b、1c（撮る道を主にするか）：S-3 の主の道。結果が来るまでは「一行を入れる」を主に描いた。2b が届かなければ「ページだけ入れる」を主にする。入れ替えるのは並びと見た目の重みだけで、識別子と AC は変わらない。
  - 3b（次の1冊）：合格の形（AC-78〜AC-80）で描き、届かないときの差分（AC-87）を S-9 に書いた。
  - 3d（ウィジェットを置くか）：置き方の案内は1回だけの形で描いた。届かなければ案内を強める案を出す（PRD 6）。
  - ロック画面の vibrant の実際の色と字の太さ（G4-1）。

## 1. 画面の流れ

### 毎晩の道
1. W-1 ロック画面のウィジェット（か W-2 小のウィジェット、ホーム画面のアイコン）を押す → S-1 しおりの画面。`reading` のときは S-2。
2. S-1 で「読み始める」を押す。または、伏せる道がオンで、S-1 が前面、今の本があり、シートと知らせが出ていないときに、iPhone を伏せて1.0秒置く（触覚1回、読み上げ1回）→ S-2 読書中の画面。
3. S-2 で「終える」を押す（確認なし）。
   - 1分未満：S-1 に戻り、知らせ `session.tooShort`。
   - 端末の時刻が読み始めより前：S-1 に戻り、知らせ `session.invalidTime`。
   - 終わりの保存に失敗：S-2 のまま、知らせ `session.save.error`。
   - それ以外：記録を残して S-3 しおりを挟む画面（同じ全画面の中で入れ替える。S-2 には戻れない）。
4. S-3 で道を選ぶ。
   - 「一行を入れる」→ S-3a → 保存 → S-4。
   - 「ページだけ入れる」→ S-3b → 保存 → S-4。
   - 「あとで挟む」→ S-4（しおりは前のまま）。
   - 選択肢 (6)「撮る」→ 写真の確かめの画面 → S-4。
5. S-4 結果の画面で「閉じる」→ S-1。初めて一行を保存した晩だけ、S-1 に戻ったところで S-5 置き方の案内を出す。

### 読まずにしおりを挟む
- S-1「どこまで読んだかを入れる」→ S-3（シート。「あとで挟む」はなく、閉じるボタンがある）→ S-3a か S-3b → 保存 → シートが閉じて S-1（結果の画面は出ない。AC-64）。初めて一行を保存したときだけ S-5。

### 読み終えた夜
- S-1「読み終えた」（確認なし。間違えたら本棚の「この本を読む」で戻せる。AC-14）→ S-9 読み終えた画面（シート。奥付 → 次の1冊を1つのスクロールに）。
  - 「この本を読む」→ その本が今の本になり、シートが閉じて S-1。
  - 積読がない：「本を加える」→ S-8（S-9 の上のシート）。本を加えると S-8 と S-9 の両方が閉じて S-1 に戻り、加えた最初の1冊が今の本として出る（読み終えたあとは今の本がないため。PRD 11 の冒頭）。何も加えずに S-8 を閉じると、S-9（積読がないまま）に戻る。
  - 閉じる → S-1（今の本がないので `bookmark.noCurrent.message`）。

### 登録
- S-1（本が0冊のとき）の「本を加える」か、S-6 本棚の「＋」→ S-8 本を加える（シート）。
  - 「バーコードを続けて読む」→ カメラの許可が未決定ならシステムの確認 → S-8a →「n冊を本棚に加える」→ シートが閉じる。読んだ本が1冊以上ある間は、戻るボタンを隠し、シートを下に払って閉じる操作を止め、出る道は「閉じる」→ 確認だけにする（決定 26）。
    - 許可を断っている：S-8a に進まず、S-8 の中に `camera.denied` と「設定を開く」。「書名で探す」「手で入れる」は押せる。
  - 「書名で探す」→ S-8b → 行を選び「この本を加える」→ シートが閉じる。
  - 「手で入れる」→ S-8c → 保存 → シートが閉じる。
  - 加えた本は、今の本がなければ最初の1冊が今の本、ほかは積読（PRD 11 の冒頭）。シートが閉じた先は開いた画面（S-1 か S-6）。S-9 から開いたときは S-1（上の「読み終えた夜」）。
  - 加える保存に失敗：シートを閉じず、その画面に `common.save.error` を出す。読んだ本、選んだ行、入れた字は残し、もう一度押せる（AC-91。出す場所は 5）。

### 本棚と本
- S-1 のツールバー「本棚」→ S-6 → 行 → S-7 本の画面。
  - 「この本を読む」→ 今の本が替わり、S-1 に戻る（押し出した画面をすべて閉じる）。
  - 「直す」→ S-7a（シート）→ 保存 → S-7。
  - 記録の行 → S-7b（シート）→ 保存 → S-7。「この記録を消す」→ 確認（confirmationDialog）→ S-7。
  - 「この本を消す」→ 確認（confirmationDialog）→ S-6。

### 書誌が見つからない今の本
- S-1「書名と著者を入れる」`book.edit` → S-7a（S-1 のシート）→ 保存 → シートが閉じて、S-1 に入れた書名と著者が出る。取り消す → S-1（何も変えない）（AC-10）。

### 設定
- S-1 のツールバー「設定」→ S-10。プライバシーポリシーとライセンスのリンクは Safari で開く。

### 起動
- 保存先を読めた：`idle` なら S-1、`reading` なら S-2。
- 読めない：S-1 の中に `store.load.error` と「もう一度読み込む」だけ（AC-90）。
- アプリが動いているときに、ウィジェット（W-1、W-2）の入口の URL（contracts/entry-urls.md）が来たとき（決定 65）
  - シート、全画面の流れ（S-2、S-3、S-3a、S-3b、S-4）、確認のどれかが開いている：画面を何も変えない（入れた字、読んだ本、選んだ行、読み終えた画面をそのまま残す）。
  - どれも開いていない：押し出した画面（S-6、S-7、S-10）を動きなしで閉じて S-1 にする。
  - どちらでも、保存を変えず、知らせ、確認、alert を出さない。
- アプリの外の入口：選択肢 (5)、(ショートカット)。回す所が決まってから書く。

## 2. 受け入れ条件と画面の対応
芯の AC は画面と操作を書いた。選択肢の AC は「選択肢 (n)」と、置き場所を書いた。

| AC | 画面 | 操作 |
|---|---|---|
| AC-1 | S-1（空） | 初めて開くと、S-1 に `bookmark.empty.message` と「本を加える」`bookmark.addBook` が出る。`bookmark.start`、許可の確認、案内の画面は出さない |
| AC-2 | S-1 → S-8 → S-8a → S-1 | `bookmark.addBook` →「バーコードを続けて読む」`register.barcode` → 読めた行 `scan.row.<ISBN>` →「1冊を本棚に加える」`scan.addToShelf` → S-1 の `bookmark.title` |
| AC-3 | S-8a | 続けて読む。本でないコードは何も出さず、同じ回に2度読んだ本は2度目を受けず、本棚にある本は知らせ `scan.duplicate`。新しい本ごとに触覚1回 → `scan.addToShelf` |
| AC-4 | S-8 → S-8b | 「書名で探す」`register.search` → `search.field` に入れて探す → ISBN ごとに1行の `search.row.<ISBN>` → 行を選ぶ →「この本を加える」`register.confirm` |
| AC-5 | S-8b（空） | ContentUnavailableView に `search.noResults` と「手で入れる」`register.manual` |
| AC-6 | S-8b（オフライン） | ContentUnavailableView に `search.offline` と `register.manual` |
| AC-7 | S-8 → S-8c | 「手で入れる」`register.manual` → `manual.title`、`manual.author` →「保存」`manual.save` |
| AC-8 | S-8c（エラー） | 欄のすぐ下に `book.title.invalid` か `book.author.invalid`。入れた字は消さない |
| AC-9 | S-8a → S-1、S-6、S-7 | 通信がなくても加わる。本棚の行、本の画面、今の本なら S-1 に `book.pendingInfo`（ISBN を含む）。前に戻ると書誌が埋まる |
| AC-10 | S-1、S-7 | `book.infoNotFound` と `book.edit`（S-1 は「書名と著者を入れる」、S-7 はツールバーの「直す」。どちらの画面も1つだけ）。押すと S-7a（S-1 からは S-1 のシート、S-7 からは S-7 のシート） |
| AC-11 | S-1、S-6、S-7 | 失敗のあいだ `book.pendingInfo`。alert を出さない |
| AC-113 | S-1、S-6、S-7、S-7a | 画面の操作はない（前に戻るたびに決まりで問い合わせ直す）。見つかるまで `book.infoNotFound`。S-7a の説明に「直すと問い合わせをやめる」と書く |
| AC-12 | S-8（権限） | `register.barcode` を押すと S-8a に進まず、バーコードの行の下に `camera.denied` と「設定を開く」`camera.openSettings`。`register.search` と `register.manual` は残る |
| AC-92 | S-7 | 奥付の `colophon.author` に、決まりで取り出した著者 |
| AC-13 | S-1 → S-6 | ツールバー「本棚」`toolbar.shelf` → 区分 `shelf.current`、`shelf.tsundoku`（加えた日の新しい順）、`shelf.finished` |
| AC-14 | S-6 → S-7 → S-1 | 行 → S-7 の「この本を読む」`book.readThis` → S-1 に戻り、その本の `bookmark.title` |
| AC-15 | S-7 → S-7a → S-7 | 「直す」`book.edit` → `book.edit.title`、`book.edit.author` →「保存」`book.edit.save` |
| AC-16 | S-7 → 確認 → S-6 | 「この本を消す」`book.delete` → confirmationDialog（`book.delete.confirm`。記録の件数を入れる）→「消す」`book.delete.confirmButton` |
| AC-17 | S-7 | 奥付 `book.colophon`：`colophon.title`、`colophon.author`、`colophon.publisher`（出版社とレーベル）、`colophon.year`。受賞の行は選択肢 (4) |
| AC-18 | S-7 | データのない行は出さない。「不明」「なし」と書かない |
| AC-19 | 選択肢 (4) | S-7、S-9 の奥付の受賞の行 |
| AC-20 | 選択肢 (4) | 同上 |
| AC-21 | 選択肢 (4) | 同上 |
| AC-22 | S-7 | 記録の行 `book.record.row.<id>`（晩の日付と分）、何晩 `book.nights`、合計 `book.total` |
| AC-23 | S-7（空） | `book.records.empty` |
| AC-24 | S-7 → S-7b | 記録の行を押す → `record.minutesField` →「保存」`record.save` |
| AC-25 | S-7b（エラー） | 欄のすぐ下に `record.minutes.invalid`。入れた字は消さない |
| AC-26 | S-7b → 確認 → S-7 | 「この記録を消す」`record.delete` → confirmationDialog →「消す」`record.delete.confirmButton` |
| AC-112 | 選択肢 (4) | 画面はない（受賞の一覧のデータ） |
| AC-27 | W-1 | 縦書きの一行（25字まで）と「p.61」。押すと S-1 |
| AC-28 | W-1 | 縦書き用の字、回す「ー」、行頭の禁則（追い出し） |
| AC-29 | W-1、S-1 | ウィジェットは縮め方の決まりで25字まで。S-1 の `bookmark.line` は全文 |
| AC-30 | W-1 | 日本語の字を含まない一行は横書き |
| AC-31 | W-1、W-2 | 一行なし：書名と「p.120」。ページもなし：書名だけ |
| AC-32 | W-1、W-2 | `widget.empty` |
| AC-33 | S-3a → S-4 → S-1、W-1 | 保存でウィジェットの再読み込みを1回。W-1 が新しい一行になる |
| AC-34 | S-10、W-1、W-2、S-1 | 「一行と書名を隠す」`settings.hideOnWidgets` をオン → ウィジェットは `widget.hidden` と「p.61」だけ。S-1 の `bookmark.line` はそのまま。Live Activity の部分は選択肢 (5) |
| AC-35 | W-2 | StandBy の小のウィジェットに縦書きの一行と「p.61」。押すと S-1 |
| AC-36 | 選択肢 (5) | ロック画面の Live Activity |
| AC-37 | 選択肢 (5) | S-10 の `settings.liveActivity.off` |
| AC-38 | 選択肢 (5) | S-10 の入口の時刻 `settings.entryTime` |
| AC-39 | S-1 | ホーム画面のアイコンから開くと S-1。`bookmark.line`、`bookmark.page`「p.61」、押せる `bookmark.start`。自動で出るシートと alert なし |
| AC-40 | W-1、W-2、S-1 | 入口ごとの URL で S-1 を開く（どの入口でも画面は同じ）。(3) の Live Activity の URL は選択肢 (5)。アプリが動いているときの画面は決定 65 |
| AC-41 | 選択肢 (5) | Live Activity の中身の更新 |
| AC-96 | S-3a → S-1 → S-5 → S-1 | 最初に一行を保存して S-1 に戻ったときに1回だけ `widgetGuide` →「閉じる」`widgetGuide.close` → S-1 |
| AC-97 | 選択肢 (5) | 画面に何も出さない（alert なし） |
| AC-98 | 選択肢 (5) | ロック画面の Live Activity |
| AC-130 | 選択肢 (5) | 画面の操作は S-1 と S-2 のまま |
| AC-99 | W-1、S-1 | 一行全体を1つの読み上げのラベルにする（9） |
| AC-42 | S-1 → S-2 | 「読み始める」1回。S-1 に文字の入力欄、ピッカー、セグメント、メニューを置かない |
| AC-43 | S-2 | 書名、始めた時刻、数え続けることの1行と、押せる要素は「終える」`reading.end` だけ。ナビゲーションバーなし |
| AC-44 | S-1 → S-2 | 伏せて1.0秒 → 触覚1回 → `reading`。起こすと S-2 |
| AC-45 | S-1 | 1.0秒たつ前に起こすと何も起きない（見た目も変えない） |
| AC-46 | S-1（空、今の本なし） | 伏せても始まらない。`bookmark.flipHint` を出さない |
| AC-47 | S-1 のほかの全画面、S-1 に知らせかシートが出ている間 | 伏せても始まらない。写真の確かめの画面は選択肢 (6) |
| AC-48 | S-2 | 起こしても、伏せ直しても読書は1つのまま。画面は変えない |
| AC-49 | S-1 → S-2 | 読み上げ `session.flipStarted.announcement` を1回 |
| AC-50 | S-1 | 「読み始める」の下に `bookmark.flipHint` を1つ |
| AC-51 | S-10 → S-1 | 「伏せて始める」`settings.flipToStart` をオフ（か使えない端末）→ S-1 に `bookmark.flipHint` を出さない。`bookmark.start` は押せる |
| AC-52 | S-2 | 画面の操作はない。S-2 の1行「伏せても、ロックしても、ほかのアプリを使っても数え続けます。」で伝える |
| AC-53 | S-2 | 開き直すと S-2 |
| AC-54 | S-2 | 画面を点けたままにしない（見た目の要素はない） |
| AC-55 | S-2 → S-3 | 「終える」1回。確認を挟まない |
| AC-56 | S-2 → S-1、S-3 | 59秒：S-1 に知らせ `session.tooShort`。60秒：S-3 |
| AC-57 | S-2 → S-3 → S-4 | 「あとで挟む」→ S-4 に知らせ `session.capped` |
| AC-58 | S-2 → S-1 | S-1 に知らせ `session.invalidTime` |
| AC-59 | S-1 | S-1 に知らせ `session.start.error`。S-1 のまま |
| AC-60 | S-2 | S-2 に知らせ `session.save.error`（閉じるボタンを付けない。押せるのは `reading.end` だけ） |
| AC-61 | S-1、S-2 | 2度目の押しは処理で受けない（見た目と押せる範囲は変えない） |
| AC-62 | W-1 → S-1 → S-2 → S-3 → S-3a → S-4 | 通信がなくても同じ。通信の状態を出さない |
| AC-114〜AC-120 | 選択肢 (5) | ロック画面、Control、Action ボタン、Siri |
| AC-131 | 選択肢 (5) | 同上 |
| AC-132 | 選択肢 (5) | 同上 |
| AC-136 | 選択肢 (5) | 同上 |
| AC-121〜AC-124 | 選択肢 (ショートカット) | 声と小窓 |
| AC-133〜AC-135 | 選択肢 (ショートカット) | 同上 |
| AC-125 | 選択肢 (5) と (ショートカット) | 同上 |
| AC-126 | 選択肢 (5) と (ショートカット) | 同上 |
| AC-63 | S-3 | 芯の道は「一行を入れる」`mark.manual`、「ページだけ入れる」`mark.pageOnly`、「あとで挟む」`mark.later`。`mark.photo` は選択肢 (6)（撮る道を回したら AC-63 は3つの道で判定。PRD 11 の冒頭） |
| AC-64 | S-1 → S-3（シート）→ S-3a → S-1 | 「どこまで読んだかを入れる」`bookmark.setMark` → `mark.manual` → `mark.lineField`、`mark.pageField` →「保存」`mark.save` → S-1。結果の画面は出さない |
| AC-65〜AC-70 | 選択肢 (6) | S-3 の `mark.photo` と写真の確かめの画面 |
| AC-71 | S-3 → S-3a | `mark.manual` → `mark.lineField`、`mark.pageField` → `mark.save` |
| AC-72 | S-3a（エラー） | 欄のすぐ下に `mark.line.invalid`。入れた字は消さない |
| AC-73 | S-3 → S-3b | `mark.pageOnly` → `mark.pageField` → `mark.save`。一行が消えることを欄の下に書いておく |
| AC-74 | S-3b（エラー） | 欄のすぐ下に `mark.page.invalid` |
| AC-75 | S-3 → S-4 | 「あとで挟む」`mark.later` → `result.summary` は「18分」だけ |
| AC-76 | S-4 → S-1 | `result.summary`「p.43 → p.61」「18分」→「閉じる」`result.close` で S-1 |
| AC-94 | 選択肢 (6) | S-3 の撮る道 |
| AC-95 | S-3a（エラー） | Form のいちばん上の行に `common.save.error`（記号 exclamationmark.circle）。欄の入力は残す（5 の S-3a と、AC-91 の行と同じ場所） |
| AC-77 | S-1 → S-9 | 「読み終えた」`bookmark.finish` → 奥付 `finish.colophon`。受賞の行は選択肢 (4) |
| AC-78 | S-9 | `next.candidate.<id>` を最大3つ、積読から並びの決まりの順に。新しい本 N は選択肢 (4)（受賞を回したら P、Q、R） |
| AC-79 | S-9 | 候補ごとに `next.reason` を1つ（「積読から・同じ著者」など）。「同じ賞」は選択肢 (4) |
| AC-80 | S-9 | 同じ並び。重ならない本は「積読から」だけ |
| AC-81 | S-9（空） | `next.empty.message` と「本を加える」`next.addBook`。押すと S-8（S-9 の上のシート）、加えると S-1 |
| AC-82 | S-9 → S-1 | 「この本を読む」`next.choose` → S-1 にその本の `bookmark.title` |
| AC-83 | 選択肢 (4) | S-9 の新しい本の行の「積読に加える」 |
| AC-84 | 選択肢 (3) | S-9 のカード |
| AC-85 | 選択肢 (3) | 同上 |
| AC-86 | S-1、S-2、S-3、S-3b、S-4 | 次の1冊と、自動で出るシートと alert を出さない |
| AC-87 | S-9（3b が届かなかったとき） | 候補は1つ（「積読から・同じ著者」か「積読から」）。差分は 5 の S-9 |
| AC-127〜AC-129 | 選択肢 (3) | S-9 のふりかえりの1行 |
| AC-88 | S-1 → S-10 | 「設定」`toolbar.settings` →「プライバシーポリシー」`settings.privacyPolicy`（Safari で開く） |
| AC-89 | S-1、S-6、S-7、S-10 | 画面で入れた本、記録、一行とページ、設定を、開き直しても同じ値で出す（S-1 の一行とページ、S-6 の置き場所、S-7 の記録、S-10 の2つの切り替え）。入口の時刻は選択肢 (5) |
| AC-90 | S-1（エラー） | `store.load.error` と「もう一度読み込む」`store.retry` だけ。`bookmark.start` と `bookmark.addBook` を出さない |
| AC-91 | S-3（シート）→ S-3a、S-7、S-7a、S-7b、S-8a〜S-8c、S-1 | 保存に失敗した操作の近くに `common.save.error`。値は操作の前のまま。入力欄の字は残す。出す場所は 5 のエラーの列（S-8a は一覧の上の帯、S-8b は「この本を加える」のすぐ上の帯、Form の画面はいちばん上の行、S-1 と S-7 は帯） |
| AC-93 | S-1 → S-10 | 「書誌の出どころ」`settings.dataSources`（ADR の文字列）と「ライセンス（CC BY 4.0）」`settings.dataSources.license`。S-1 と S-2 には置かない |
| AC-103 | 全画面（S-8 の説明の1行） | 外に送るのは書誌の問い合わせだけ。S-8 に「ISBN か書名を国立国会図書館サーチに送って探します」と書く。カードは選択肢 (3) |
| AC-100 | S-1 | 起動から S-1 を操作できるまで1.0秒。読み込みに0.3秒を超えたら形を先に出す（5） |
| AC-101 | S-6、S-7 | 一覧は List の遅延の描き方。読み込み中は形を先に出す |
| AC-102 | W-1、W-2 | 中身は写しの読み取りと組みだけ |
| AC-104〜AC-111 | 選択肢 (課金) | S-10 の購入の節と購入のシート |

## 3. 画面の仕事と主操作、標準部品
主操作は1画面に1つ。標準部品を先に使う。並び（上から下の順、縦の線、文字の段）は design/001-reading-session/screens.md に描いた。

| 画面 | 仕事（1文） | 主操作 | 使う標準部品 | 標準から外れる所（本来の部品、理由、対応） |
|---|---|---|---|---|
| W-1 ロック画面のウィジェット | 手に取った瞬間に、今の本の止めた一行とページを見せる | 押す（S-1 を開く。widgetURL） | WidgetKit の accessoryRectangular、Text、widgetURL、placeholder の redacted | 縦書きの一行：本来は Text（横書き）。SwiftUI に縦書きの指定がない［推測。PRD E-10 の spike A］ので、1字ずつ組む。組んだ字は読み上げから隠し、一行全体を1つのラベルにする（AC-99）。字の大きさは、枠に全部の字が入る固定の値で、Dynamic Type で大きくしない（大きくすると字が欠け、AC-29 と G4-1 に届かない）。大きい文字の人は、押して開いた S-1 で全文を大きく読める（PRD 12） |
| W-2 小のウィジェット | 同じ一行を、ホーム画面と、離れた所から見る StandBy で見せる | 押す（S-1 を開く） | WidgetKit の systemSmall、containerBackground、widgetURL | W-1 と同じ（縦書きの組み、固定の大きさ、1つのラベル） |
| S-1 しおりの画面 | 今夜どの本のどこから読むかを見せ、1回の操作で読み始めさせる | 読み始める `bookmark.start`（.borderedProminent、下端に固定して幅いっぱい） | NavigationStack（根）、toolbar の Button と SF Symbols、ScrollView、safeAreaInset、Text、Button（.borderedProminent と .bordered）、ContentUnavailableView、ViewThatFits、redacted | 縦書きの一行 `bookmark.line`：W-1 と同じ組み（本来は Text）。読み上げは1つのラベル。大きい文字（accessibility1 以上）と、縦に入らないときは横書きの Text に替える。知らせの帯は部品 N |
| S-2 読書中の画面 | 読んでいることと始めた時刻を伝え、終える道を1つだけ出す | 終える `reading.end`（.borderedProminent、下端に固定） | fullScreenCover、ScrollView、safeAreaInset、Text、Button | なし |
| S-3 しおりを挟む画面 | どこまで読んだかを残す道を選ばせる（残さない道も同じ画面に置く） | 主の道（結果待ち。今は「一行を入れる」`mark.manual`、.borderedProminent） | NavigationStack、Button（.borderedProminent、.bordered）、toolbar（シートのときだけ閉じる。Button(role: .close)） | なし |
| S-3a 一行を入れる | 止めた一行と、あればページを入れて保存する | 保存 `mark.save`（toolbar の Button(role: .confirm)） | Form、Section、TextField（axis: .vertical）、TextField（keyboardType .numberPad）、FocusState | なし |
| S-3b ページだけ入れる | 止めたページだけを入れて保存する | 保存 `mark.save` | Form、TextField（.numberPad）、FocusState、toolbar | なし |
| S-4 結果の画面 | 今夜の読書が残ったことを確かめて、S-1 へ戻す | 閉じる `result.close`（.borderedProminent、下端に固定） | ScrollView、safeAreaInset、Text、Button | なし |
| S-5 置き方の案内 | ロック画面に置くと何が出るかと置き方を、1回だけ伝える | 閉じる `widgetGuide.close`（.borderedProminent） | sheet（detents .medium と .large）、Text、Button | 見本：W-1 と同じ部品を実際の大きさ（172×76 pt）で描く（絵ではなく、利用者の一行がそのまま出る）。見本は読み上げで1つのラベル「ロック画面での見え方。」に一行を続ける |
| S-6 本棚 | 本を3つの置き場所に分けて見せ、本の画面へ進ませる | 行を押す（S-7 を開く。NavigationLink） | List（.insetGrouped）、Section、NavigationLink、toolbar（＋）、ContentUnavailableView、redacted | なし |
| S-7 本の画面 | 本の事実（奥付）と記録を見せ、今の本にする、直す、消すの入口を置く | この本を読む `book.readThis`（下端の .borderedProminent。今の本のときは出さず、「今読んでいる本です」の文字にする） | List（.insetGrouped）、Section、Grid、Divider、Button（role: .destructive）、toolbar、confirmationDialog、safeAreaInset、redacted | 消すボタンの文字：本来は role .destructive の赤い文字。赤い文字は .body で 4.5:1 に届かない（決定 58）ので、文字は本文の色にして、赤は記号 trash だけにする。role は残し、確認はシステムの confirmationDialog のまま。奥付：本来は LabeledContent の行。本の最後のページの型（名前と値の2列を罫線の間に）に寄せるため、Grid で名前と値をそろえる（D-2）。読み上げは行ごとに「名前、値」を1つのまとまりにし、大きい文字では名前の下に値を置く |
| S-7a 本を直す | 書名と著者を直して保存する | 保存 `book.edit.save`（Button(role: .confirm)） | sheet、NavigationStack、Form、TextField、toolbar（role: .cancel と .confirm） | なし |
| S-7b 記録を直す | 1つの記録の分数を直すか、記録を消す | 保存 `record.save` | sheet、Form、LabeledContent、TextField（.numberPad）、Button（role: .destructive）、confirmationDialog | 消すボタンの文字：S-7 と同じ（文字は本文の色、記号 trash だけ赤。決定 58） |
| S-8 本を加える | 本を加える3つの道を並べ、選ばせる | バーコードを続けて読む `register.barcode`（先頭の行） | sheet、NavigationStack、List、Button と Label（SF Symbols）、Button（.bordered。「設定を開く」）、toolbar（Button(role: .close)） | なし |
| S-8a バーコードを続けて読む | 手元の本を1冊ごとのボタンなしで続けて読み、まとめて本棚に加える | n冊を本棚に加える `scan.addToShelf`（下端の .borderedProminent） | VisionKit の DataScannerViewController（UIViewControllerRepresentable）、List、Button、safeAreaInset、sensoryFeedback、confirmationDialog、navigationBarBackButtonHidden と interactiveDismissDisabled（読んだ本が1冊以上の間） | なし（カメラの画面はシステムの部品） |
| S-8b 書名で探す | 書名で書誌を探し、1冊を選んで加える | この本を加える `register.confirm`（下端の .borderedProminent） | List、TextField、Button（.bordered と .borderedProminent）、safeAreaInset、ContentUnavailableView、redacted、ProgressView | 検索欄：本来は .searchable。テストの識別子 `search.field` を付けるためと、開いた時から欄に焦点を当てるため、List の上に TextField を置き、見た目は検索欄（虫めがねの記号、消すボタン、プレースホルダ）にそろえる。キーボードの改行の印は「検索」（submitLabel .search）。読み上げは accessibilityAddTraits(.isSearchField) で検索欄として読ませ、ラベルは「書名」。.searchable の欄には識別子を付けられないと tech-lead が確かめた（tech-lead r1 の C の問い2。SDK の searchable の宣言44個に識別子の引数がなく、spike でも検索欄の識別子は空だった）ので、TextField のままにする。消すボタンは字があるときだけ欄の右端に出し、記号 xmark.circle.fill（システムの検索欄と同じ形）、識別子 `search.clear`、読み上げ「入力を消す」、押せる範囲 44×44pt |
| S-8c 手で入れる（本） | 書名と著者を手で入れて本を加える | 保存 `manual.save`（Button(role: .confirm)） | Form、TextField、FocusState、toolbar | なし |
| S-9 読み終えた画面 | 読み終えた本の奥付を見せ、翌晩の本を積読から事実の理由つきで選ばせる | この本を読む `next.choose`（候補の行ごとに .bordered。どれも同じ重み） | sheet（.large）、NavigationStack、ScrollView、Grid、Divider、Button（.bordered）、ContentUnavailableView、toolbar（Button(role: .close)） | 奥付は S-7 と同じ。主操作のボタンが候補の数（最大3）だけある：同じ操作を本ごとに置く一覧の型で、操作の種類は1つ。どれかを目立たせると上の本へ急がせるので、3つとも .bordered にする（性格語「急かさない」） |
| S-10 設定 | 読み始めとロック画面の出し方を決め、ポリシーと書誌の出どころを見せる | 伏せて始めるの切り替え `settings.flipToStart`（先頭の行。設定を開く理由のいちばん多いもの［推測。PRD 14 の G-4］） | Form、Section、Toggle、Link（行の末尾に記号 arrow.up.forward）、Text | なし |
| 部品 N 知らせの帯 | 起きたことを問題の近くに残し、閉じるか次の操作まで出す | 閉じる `notice.close`（S-2 には置かない） | GroupBox、Label（SF Symbols）、Text、Button（.bordered の小さいボタン） | 本来は alert。毎回操作を止めず、問題の近くに残すため（HIG Alerts「Use alerts sparingly.」、R-26）、内容の層に置く。出たときに読み上げ（AccessibilityNotification.Announcement）を1回送る。時間で消さない（PRD 11 の冒頭） |

- どの画面にも置かないもの：タブバー、数のバッジ、連続日数、目標、グラフ、表紙の画像、おすすめ、購入の案内（芯）、祝う絵と紙吹雪、独自の動き。
- S-1 には、文字の入力欄、ピッカー、セグメント、メニューを置かない（AC-42）。ツールバーのボタンもメニューにしない。
- S-2 の押せる要素は `reading.end` の1つだけ（AC-43）。知らせの帯にも閉じるボタンを付けない。
- 押せる文字は、形で押せると分かるようにする（アクセント色を足さない案A なので、色では分けない。決定 4、47）。主操作は .borderedProminent、そのほかのボタンは .bordered（灰の塗り）、一覧の行は記号か「>」つき、ツールバーは記号、外へ開くリンクは末尾に記号 arrow.up.forward。枠のない文字のボタン（.borderless）は使わない。押せない文字は塗りも記号も持たない。
- ContentUnavailableView のボタンは、その状態の主操作なので .borderedProminent（2つあるときは2つ目を .bordered）。ContentUnavailableView を出す間は、その画面の下端の主操作を出さない。
- 下端の主操作（S-1、S-2、S-4、S-7、S-8a、S-8b）は下端に固定し（safeAreaInset）、上の内容だけを送る。AX5 でも主操作が画面の外に出ない（決定 59）。

## 4. 決定と根拠
根拠は調査の R 番号、原則は HIG の URL か B 番号。HIG の URL は、調査が読んだページ（R-18〜R-28）と、2026-10-19 にこの仕様のために開いたページ（buttons、sheets、alerts、action-sheets、toolbars、lists-and-tables、text-fields、search-fields、loading、toggles。どれも HTTP 200。報告に書く）。

| # | 決定 | 根拠（R-n） | 原則（HIG の URL か B-n） |
|---|---|---|---|
| 1 | 見た目は案A「紙の版面」：白、黒、灰。アクセント色を使わず、色は意味（エラーの記号、消す操作の記号、Toggle のオン）にだけ使う。Takuma が決めた（2026-10-19。docs/approvals/001-reading-session-G1-decisions.md） | R-19、R-2、R-4、R-6、R-8、R-34 | B-5、https://developer.apple.com/design/human-interface-guidelines/color |
| 2 | アプリの根は S-1 の1画面。タブバーを置かず、本棚と設定はツールバーのボタンから押し出す | R-6、R-8、R-12 | B-1、B-2、https://developer.apple.com/design/human-interface-guidelines/toolbars |
| 3 | S-1 の主操作は「読み始める」1つ（.borderedProminent、下端に固定して幅いっぱい）。伏せる道は近道として、ボタンのすぐ下の1行で知らせる | R-1、R-29、R-24 | B-2、https://developer.apple.com/design/human-interface-guidelines/buttons |
| 4 | S-1 の「どこまで読んだかを入れる」「読み終えた」は、主操作の上に、.bordered（灰の塗りと tint の文字。文字は .subheadline）で横に並べて出しておく。塗りの形で押せると分かり（すぐ上の押せない「p.61」と見分けられる）、黒い塗りの .borderedProminent より目立たない。Takuma が決めた（2026-10-19。docs/approvals/001-reading-session-G1-decisions.md の「主操作より目立たない形で画面に出しておく」） | R-33、R-12、R-25 | B-2、https://developer.apple.com/design/human-interface-guidelines/buttons 、https://developer.apple.com/design/human-interface-guidelines/color |
| 5 | 本の言葉（一行）だけを明朝（ヒラギノ明朝 ProN）の縦書きにし、アプリの言葉はシステムの書体にする。書体が2つになるのは B-4 の例外で、本の文とアプリの文を見分けるため | R-13、R-15、R-30 | B-4、https://developer.apple.com/design/human-interface-guidelines/typography |
| 6 | 縦書きの組みは JLREQ に従う：句読点、括弧（かぎ、二重かぎ、丸、山、二重山、すみ付き、角、亀甲）、「…」「‥」、「―」は縦書き用の字、「ー」と「〜」は90度回す、小さい仮名はフォントの縦書き用の字形の位置（横書きの字形より右と上）、行頭の禁則は追い出し（前の列の最後の字を次の列へ送る。禁則の字は決定 62）。半角の印字できる字は全角に直してから表を当て、英数字は1字ずつ立てる（回す記号と、ずらす「，」「．」は決定 63）。列の間は字の大きさの 0.25 倍。置き換えの表は tokens.md、組みの手順と式は docs/adr/0003-vertical-composition.md | R-30 | B-6、https://developer.apple.com/design/human-interface-guidelines/typography |
| 7 | S-1 の一行は Dynamic Type で大きくなり、accessibility1 以上と、縦に入らないときは横書きに替える（縦書きの場所の大きさは決定 64） | R-24 | B-6、https://developer.apple.com/design/human-interface-guidelines/typography |
| 8 | ウィジェットの一行は、枠に全部の字が入る固定の大きさ（W-1 は 17pt、W-2 は 20pt から、入らなければ1pt ずつ下げ、下限 13pt）。入るかの式は ADR 0003（9 の計算）。Dynamic Type で大きくしない（大きい文字の人は S-1 で読む）。W-1 のページは列の下に置かず、左端の帯（「p.9999」が入る幅で固定。実測 43pt。ADR 0003）の下に置き、列は帯の右から組む（列の下に置くと 76pt の高さに入らない）。W-2 のページは列の下の左端に置き、列の場所とページの行の間は `space.4`（`space.8` にすると 148pt の枠で25字が 19pt から 18pt に下がる。9） | R-18、R-24、R-30 | https://developer.apple.com/design/human-interface-guidelines/widgets |
| 9 | ウィジェットに出すのは一行とページだけ。書名は読み上げのラベルにだけ入れる。押すと S-1（その本の続き）を開く（D-1。アプリが動いているときは決定 65） | R-18、R-14、R-15 | B-2、https://developer.apple.com/design/human-interface-guidelines/widgets |
| 10 | ウィジェットの一行は W6（vibrant で細らない太さ）。色を付けず primary の字だけにし、色はシステムに任せる | R-19、R-20 | https://developer.apple.com/design/human-interface-guidelines/widgets |
| 11 | StandBy は W-2 を同じ形で大きく見せる。絵と色を足さない | R-19 | https://developer.apple.com/design/human-interface-guidelines/widgets |
| 12 | 「一行と書名を隠す」がオンのときは、ウィジェットに「しおり」とページだけを出す。読み上げのラベルも同じ。アプリの中には出す | R-20、R-21 | https://developer.apple.com/design/human-interface-guidelines/live-activities 、https://developer.apple.com/design/human-interface-guidelines/controls |
| 13 | ウィジェットのギャラリーの見本は利用者の今の一行。なければ著作権の切れた『羅生門』の一行と「p.61」 | R-18 | https://developer.apple.com/design/human-interface-guidelines/widgets |
| 14 | S-2 は書名、「21:04 から数えています。」、数え続けることの1行、「終える」だけ。経過の秒と動く数字を出さない | R-2、R-11、R-12 | B-2、https://developer.apple.com/design/human-interface-guidelines/design-principles |
| 15 | 「終える」と「読み終えた」に確認を挟まない（1分未満は残さず、記録は直せて消せる。読み終えた本は本棚から戻せる）。調査は ToRead の「誤って『終了』を押しても読書を続けられ」を取り入れると書いたが、終えたあとの「続ける」の道は足さない。S-1 から1タップで読み始め直せ、記録が2件に分かれても何晩と合計は変わらず、記録は S-7b で直せて消せるので、誤りから戻れる。S-3 に4つ目の道を足すと、PRD にない操作になる | R-1、R-23 | https://developer.apple.com/design/human-interface-guidelines/alerts |
| 16 | S-3 の主の道は、結果待ちの間は「一行を入れる」（一行が D-1 の中身のため）。2b が届かなければ「ページだけ入れる」を主にする | R-18、R-13 | B-2、https://developer.apple.com/design/human-interface-guidelines/buttons |
| 17 | 「あとで挟む」は .bordered の小さいボタン（幅いっぱいにしない）で下に置き、「しおりは前のまま残ります。」を添える。塗りで押せると分かり、幅いっぱいの2つの道より目立たない | R-26、R-25 | B-2、https://developer.apple.com/design/human-interface-guidelines/writing |
| 18 | S-3a は一行の欄に焦点を当てて開く。ページは任意。前のページは欄の下の消えない説明（`color.text.secondary`）に「前のページは43です。空のまま保存すると、43のまま残ります。」と出し、プレースホルダは「例 61」の手がかりだけにする（プレースホルダの色は 4.5:1 に届かず、字を入れると消えて覚えておかせることになるため）。ページの欄が空なら、ページは変えない（PRD にない決まりを足さない形。撮る道（選択肢 (6)）でも前のページを黙って消さない）。前の値を欄に入れておかない | R-12、R-26、R-24、R-23 | https://developer.apple.com/design/human-interface-guidelines/text-fields 、https://developer.apple.com/design/human-interface-guidelines/accessibility |
| 19 | S-3b の欄の下に、一行が消えてロック画面には書名とページが出ることを書く | R-26、R-35 | https://developer.apple.com/design/human-interface-guidelines/writing |
| 20 | S-4 は「p.43 → p.61」「18分」と「記録しました。」だけ。祝う言葉、絵、触覚、音を出さない | R-4、R-12、R-31 | B-2、https://developer.apple.com/design/human-interface-guidelines/design-principles |
| 21 | 置き方の案内は、最初に一行を保存して S-1 に戻ったときに1回だけ、シートで、利用者の一行を実際の大きさの見本で見せる | R-18、R-27 | https://developer.apple.com/design/human-interface-guidelines/onboarding 、https://developer.apple.com/design/human-interface-guidelines/sheets |
| 22 | 初めて開いたときに案内の画面、サインイン、許可の確認を出さない。S-1 の空の状態から「本を加える」 | R-27、R-33 | https://developer.apple.com/design/human-interface-guidelines/onboarding |
| 23 | カメラの許可は「バーコードを続けて読む」を押したときにだけ求め、前に説明の画面を置かない。断られたら S-8 の中に、設定を開く道とほかの2つの道を出す | R-27、R-9 | https://developer.apple.com/design/human-interface-guidelines/privacy |
| 24 | 登録は3つの道を1つのシートの一覧に並べ、バーコードを先頭にする。1冊ごとの登録ボタンを置かない | R-8、R-10、R-5、R-7 | B-1、https://developer.apple.com/design/human-interface-guidelines/lists-and-tables |
| 25 | 読めた本は、新しい本ごとに触覚1回と一覧の行で知らせる。本棚にある本は文字の知らせ。本でないコードは何も出さない | R-28、R-5 | https://developer.apple.com/design/human-interface-guidelines/playing-haptics |
| 26 | 読んだ本が1冊以上あるのに S-8a を閉じるときは、確認を出す（読んだ本を加えずに捨てるため）。その間は戻るボタンを隠し（navigationBarBackButtonHidden。端からのスワイプも止まる）、シートを払って閉じる操作を止め（interactiveDismissDisabled）、出る道を「閉じる」→ 確認だけにする。閉じるの role は、0冊は .close、1冊以上は .cancel（.close は進めたものを失わない操作のため） | R-23 | https://developer.apple.com/design/human-interface-guidelines/action-sheets 、https://developer.apple.com/design/human-interface-guidelines/sheets |
| 27 | 書名で探す結果は ISBN ごとに1行で、書名、著者、出版社（レーベル）、出版年。並びは ADR 0004 の並べ直しのまま（書名が入れた書名と同じ → 入れた書名で始まる → ほか。同じ組の中は応答の順）で、画面では並べ替えず、並べ替えの操作も置かない（探した本が上に来る）。1回の問い合わせ（cnt=200）で返った分だけを出し、最大で約200行。結果の下と、0件、通信なし、失敗のときに「手で入れる」 | R-5、R-7、R-26 | https://developer.apple.com/design/human-interface-guidelines/search-fields |
| 28 | 空、エラー、オフラインの画面は ContentUnavailableView で、何が起きたかと次の一手のボタンを出す | R-33、R-26 | B-1、https://developer.apple.com/design/human-interface-guidelines/writing |
| 29 | 読み込みに0.3秒を超えたら形を先に出す（redacted の灰の帯）。読み込み中に「0冊」「0件」を出さない。2秒を超える通信の待ちには ProgressView を足す | R-33 | https://developer.apple.com/design/human-interface-guidelines/loading |
| 30 | 通信がなくてもバーコードで加えられる。本の行に「書誌を待っています（ISBN …）」と、いつ問い合わせ直すかを書く | R-5、R-26 | B-1、https://developer.apple.com/design/human-interface-guidelines/writing |
| 31 | 書誌が見つからない本は、S-7 と、今の本なら S-1 に「書名と著者を入れる」道を出す | R-5、R-7、R-9 | https://developer.apple.com/design/human-interface-guidelines/writing |
| 32 | 本棚は1つの List に3つの区分。並べ替え、タブ、表紙、グラフを置かない | R-8、R-9、R-12 | B-2、https://developer.apple.com/design/human-interface-guidelines/lists-and-tables |
| 33 | 奥付は本の最後のページの型（名前と値の2列を、上下の罫線の間に）。データのない行は出さず、「不明」と書かない（D-2） | R-15、R-23、R-35 | B-1、B-3 |
| 34 | 記録の行は晩の日付と分だけ。行を押すと直す・消すのシート。消す前に confirmationDialog | R-1、R-7、R-23 | https://developer.apple.com/design/human-interface-guidelines/action-sheets 、https://developer.apple.com/design/human-interface-guidelines/lists-and-tables |
| 35 | 本を消す確認の文に、一緒に消える記録の件数を入れる | R-23、R-26 | https://developer.apple.com/design/human-interface-guidelines/action-sheets |
| 36 | 「この本を読む」は S-7 の下端の主操作。押すと S-1 に戻り、その本の続きを出す | R-33、R-18 | B-1、https://developer.apple.com/design/human-interface-guidelines/buttons |
| 37 | 読み終えた画面は1つのスクロール（奥付 → 次の1冊）。祝う演出を置かず、毎晩の道には出さない（D-2） | R-4、R-6、R-9、R-23 | B-2、https://developer.apple.com/design/human-interface-guidelines/design-principles |
| 38 | 次の1冊は最大3冊で、「この本を読む」は3つとも同じ重み（.bordered）。理由は事実1行（「積読から・同じ著者」の形） | R-9、R-6、R-31、R-35 | B-2、B-5、https://developer.apple.com/design/human-interface-guidelines/writing |
| 39 | S-9 の下に、まだ読み終えていなかったときの戻し方を1行で書く | R-1、R-23 | https://developer.apple.com/design/human-interface-guidelines/writing |
| 40 | 設定は1つの Form（読み始め、ロック画面、情報の3節）。購入の節は課金を入れる版だけ | R-16、R-9 | B-1、https://developer.apple.com/design/human-interface-guidelines/toggles |
| 41 | プライバシーポリシーと書誌の出どころは S-10 の「情報」に置き、毎晩の画面に置かない | R-11、R-12 | B-2 |
| 42 | 書誌の出どころの文は ADR の文字列をそのまま出す（designer は文を作らない）。S-8 に、ISBN か書名を送って探すことを1行で書く | R-35 | B-1、https://developer.apple.com/design/human-interface-guidelines/privacy |
| 43 | 知らせは画面の中の帯で、閉じるか次の操作まで出し、時間で消さない。出たときに1回読み上げる。S-1 に知らせかシートが出ている間は伏せる道を止め、伏せる案内の1行を出さない | R-26、R-29 | https://developer.apple.com/design/human-interface-guidelines/alerts 、https://developer.apple.com/design/human-interface-guidelines/accessibility |
| 44 | エラーの文は、何が起きたかとどう直すかを書き、責めない。入力を消さない。字は本文の色で、記号（exclamationmark.circle）だけ赤 | R-26、R-24 | B-5、https://developer.apple.com/design/human-interface-guidelines/writing |
| 45 | 文言はです・ます、淡々、感嘆符と絵文字なし。ボタンは動詞。英語も同じ調子 | R-31、R-26、R-21 | https://developer.apple.com/design/human-interface-guidelines/writing |
| 46 | 2つ目の文字の色は独自の値（ライト #6C6C70、ダーク #98989F）。システムの secondaryLabel はライトで約 3.44:1 で、17pt 以下の 4.5:1 に届かない（9 の計算） | R-24、R-25 | https://developer.apple.com/design/human-interface-guidelines/accessibility 、https://developer.apple.com/design/human-interface-guidelines/color |
| 47 | 主操作の色は文字の色（ライトは黒地に白、ダークは白地に黒）。ToRead の淡い橙のような色の個性を足さない。押せる文字と押せない文字は同じ色なので、押せることは形（塗り、記号、>）で見せる（3 の下の決まり）。ダークの白い主操作は、灰（#AEAEB2。黒い文字と 9.50:1）に抑える案と比べて白のままにした。灰の塗りは押せない見た目と見分けにくく、白い面は主操作の1つ（画面の約5%）だけのため | R-25、R-2、R-19、R-24 | B-5、https://developer.apple.com/design/human-interface-guidelines/color 、https://developer.apple.com/design/human-interface-guidelines/buttons |
| 48 | Toggle のオンはシステムの緑のまま（アプリの tint を当てない） | R-25 | https://developer.apple.com/design/human-interface-guidelines/toggles |
| 49 | 触覚は、伏せて始まった時（start）とバーコードが読めた時（success）の2つだけ。どちらもシステムの型 | R-28 | https://developer.apple.com/design/human-interface-guidelines/playing-haptics |
| 50 | 動きはシステムの押し出しとシートだけ。独自の動きを作らず、動きのために操作を止めない | R-12、R-20 | B-2、https://developer.apple.com/design/human-interface-guidelines/accessibility |
| 51 | Liquid Glass はツールバーのボタンとシートなど、システムの操作の層だけ。一行、奥付、一覧の地には素材を使わない | R-25 | https://developer.apple.com/design/human-interface-guidelines/materials |
| 52 | 押せる範囲は 44×44 pt 以上。枠のない文字のボタンは使わず、.bordered の小さいボタン（`mark.later`、`notice.close`、結果の下の `register.manual`）と検索欄の消すボタンにも 44pt 以上の押せる範囲を付ける | R-24 | https://developer.apple.com/design/human-interface-guidelines/buttons |
| 53 | 一行の読み上げは全体を1つのラベル（縦書き用の字を使わず、保存した一行から作る）。「p.61」は「61ページ」と読ませる | R-24 | https://developer.apple.com/design/human-interface-guidelines/accessibility |
| 54 | 伏せる案内の1行は、Q-A の結果のどちらでも成り立つ2つの文を用意する（結果待ち） | R-29 | https://developer.apple.com/design/human-interface-guidelines/accessibility |
| 55 | シートの閉じる、取り消す、保存は、ツールバーの標準の記号のボタン（Button の role .close、.cancel、.confirm）にする。S-8a の閉じるは、読んだ本が1冊以上なら .cancel（決定 26） | R-23 | https://developer.apple.com/design/human-interface-guidelines/toolbars 、https://developer.apple.com/design/human-interface-guidelines/sheets |
| 56 | 日付、時刻、数は端末の言語の書式（Date.FormatStyle）。記録の行は「10/17」、晩の長い書き方は「10月17日の晩」。ページの数に桁の区切りを入れない | R-26 | https://developer.apple.com/design/human-interface-guidelines/writing |
| 57 | 時間は60分未満を「18分」、60分以上を「1時間25分」と書く（String Catalog の型） | R-26、R-31 | https://developer.apple.com/design/human-interface-guidelines/writing |
| 58 | 消す操作（この本を消す、この記録を消す）は role .destructive のまま、見える文字は本文の色にし、赤は記号 trash だけにする（systemRed の文字は .body で 3.57:1 で 4.5:1 に届かない。記号は 3:1 でよい） | R-24、R-23 | https://developer.apple.com/design/human-interface-guidelines/accessibility 、https://developer.apple.com/design/human-interface-guidelines/color |
| 59 | 下端の主操作（S-1、S-2、S-4、S-7、S-8a、S-8b）は下端に固定し（safeAreaInset）、上の内容だけを送る。AX5 で書名や一行が長くても、主操作が画面の外に出ない | R-24 | B-2、https://developer.apple.com/design/human-interface-guidelines/accessibility |
| 60 | 読み上げのラベルは見える文字から始める。見える文字と読み上げを変える押せる要素（記録の行）は、見える文字を accessibilityInputLabels に入れ、音声コントロールで見える文字のまま押せるようにする | R-24 | https://developer.apple.com/design/human-interface-guidelines/accessibility |
| 61 | S-2 の始めた時刻は、読み始めた晩が今の晩と違うとき（開き直した翌朝など）だけ、月日を足す（「10月17日 21:04 から数えています。」） | R-26 | https://developer.apple.com/design/human-interface-guidelines/writing |
| 62 | 行頭の禁則の字は、JLREQ の行頭禁則（3.1.7）の類を全部とる：終わり括弧（」 』 ） 〉 》 】 ］ 〕 ｝）、ハイフン（‐ ゠ – 〜 ～）、区切り約物（！ ？）、中点（・ ： ；）、句点（。 ．）、読点（、 ，）、繰返し記号（々 ゝ ゞ ヽ ヾ）、長音記号（ー）、小さい仮名（tokens.md の表の22字）。全角に直したあとの字と、縦書き用の字で見る（一覧は tokens.md）。JLREQ は「々」「ー」と小さい仮名を行頭に許すゆるい決まりも挙げるが、AC-28 が「ー」を禁則にしているので、同じ組の「々」と小さい仮名も禁則にそろえる。1列が4〜6字と短く、列の頭の「っ」や「！」は目立つ。追い出しが増えても字は欠けない：25字で送る字が5字まで（6列）なら、W-1 の2つの枠とも字の大きさは変わらない。6字以上（7列）になると、172×76 は 14pt に下がり、153×68 は 13pt で追い出しをせずに組む（ADR 0003 の手順 7。まれ）。W-2 の 148pt は、送りで列が増えると 19pt から 16pt に下がる（9） | R-30 | B-6、https://developer.apple.com/design/human-interface-guidelines/typography |
| 63 | 全角に直した記号の向きは、Unicode の縦書きの向き（UAX #50 のデータ VerticalOrientation.txt）に従う。立てる字（U）は立て、回す字（R）と、縦書き用の字形を使いなければ回す字（Tr）のうち表に縦書き用の字がないものは90度回し、縦書き用の字形を使いなければ立てる字（Tu）は立てるか、フォントの縦書き用の字形の位置へずらす。「：」「；」は90度回す（縦書き用の字形 U+FE13、FE14 がフォントにない。立てたままの「：」は縦書きの「‥」（︰）と同じ形になり見分けられない）。「－」「＝」「＜」「＞」「｛」「｝」「｜」「＿」も90度回す（立てたままの「－」は漢字の「一」、「＝」は「二」と同じ形になる）。「，」「．」は回さず、小さい仮名と同じ方法で、フォントの縦書き用の字形の位置（右上。「、」「。」と同じ所）へずらす。ほかの全角の記号（＃ ％ ＆ ＊ ＋ ／ ＠ など）と英数字は立てる | R-30 | B-6、https://developer.apple.com/design/human-interface-guidelines/typography |
| 64 | S-1 の縦書きの場所（ADR 0003 の A_w と A_h）は、幅＝画面の幅−32pt（左右の `space.16` の内側。393pt で 361pt）、高さ＝画面の高さ×0.4 の切り捨て（852pt で 340pt）。内側の余白、帯、ページの行はない（i＝B＝g＝R＝0。ページの「p.61」は場所の下）。列は場所の右上から組み、上にそろえる。字の大きさは `type.book.line` のまま下げず、60字が送りを含めて幅に入らないときと accessibility1 以上は横書き。高さを画面の4割にするのは、ふだんの文字の大きさで、書名から「読み始める」までを送らずに1画面に入れるため（28pt で1列12字、60字は5列。9 の計算） | R-24、R-30 | B-3、B-6、https://developer.apple.com/design/human-interface-guidelines/typography |
| 65 | アプリが動いているときに入口の URL（W-1、W-2）が来たら、シート、全画面の流れ（S-2、S-3、S-3a、S-3b、S-4）、確認（confirmationDialog）のどれかが開いていれば、画面を何も変えない（入れた字、読んだ本、選んだ行、1回だけの読み終えた画面を、利用者が閉じる前に消さない。`reading` のときは S-2 が前にある）。どれも開いていなければ、押し出した画面（S-6、S-7、S-10）を動きなしで閉じて S-1 にする（ウィジェットの中身の続きが出る所で、「読み始める」まで1タップ）。どちらでも保存を変えず、知らせ、確認、alert を出さない（contracts/entry-urls.md の 3）。入力の有無を画面ごとに見て閉じるかを決める案は、同じ押し方で結果が変わり、確かめも増えるので採らない | R-18、R-23、R-5 | B-1、https://developer.apple.com/design/human-interface-guidelines/sheets 、https://developer.apple.com/design/human-interface-guidelines/widgets |
| 66 | 書名のない今の本（ISBN で加え、書誌を待っているか見つからなかった本。写しに title がなく、ISBN も置けない。PRD 12、設計メモ 5）は、W-1、W-2 の書名の所を `widget.currentBookAsTitle`「今の本」にする。アプリの `book.isbnAsTitle` と同じ「書名の所に代わりの文を出す」型で、言葉は本棚の区分 `shelf.current` と `widget.empty` の「今の本」と同じ。見せ方：一行があれば変えない（一行とページ。状態 normal。書名はもともと見えない）。一行がなくページがあれば「今の本」と「p.120」（noLine）、ページもなければ「今の本」だけ（noLineNoPage）。「今の本」は書名と同じ字と場所に出す。読み上げは書名の所を「今の本」にして、同じ順と同じ書式にする（「今の本、61ページ。下人は、雨やみを待っていた。」「今の本。下人は、雨やみを待っていた。」「今の本、120ページ」「今の本」。9）。H22 の状態は増やさない（5、6）。写しは書誌の状態を持たない（PRD 12）ので、待っているか見つからなかったかは言わず、どちらにも正しい言葉だけを使う。選ばなかった案：書名の所を空ける（「p.120」だけでは何のページか分からず、一行もページもないと何も出ない。R-18 の「Sparse layouts can make the widget seem unnecessary」）、「書誌を待っています」（見つからなかった本では、アプリの `book.infoNotFound` と食い違う）、「書名なし」（本に書名がないように読め、正しくない）、`widget.hidden` の「しおり」（隠す設定と同じ見た目になり、設定を変えたかと迷わせる。H22 の状態も混ざる）、案内の文（文が増え、ページがあるときに合わない。書名のある本の AC-31 (2) の形ともそろわない） | R-18、R-23、R-26、R-35 | B-1、B-2、https://developer.apple.com/design/human-interface-guidelines/widgets 、https://developer.apple.com/design/human-interface-guidelines/accessibility |

## 5. 画面ごとの状態
空とエラーには「何が起きたか」と「次の一手のボタン」を書いた。読み込み中は、0.3秒を超えたら形を先に出し（redacted）、空の状態を先に出さない。知らせ（部品 N）は閉じるか次の操作まで出したまま。

| 画面 | 通常 | 空 | 読み込み中 | エラー | オフライン | 権限を断られたとき | 一部だけ読めたとき |
|---|---|---|---|---|---|---|---|
| W-1 | 縦書きの一行（25字まで）を帯の右から組み、左端の帯の下に「p.61」 | 今の本なし（本0冊も）：`widget.empty`。一行なし：書名と「p.120」。ページもなし：書名だけ。一行あり・ページなし：一行だけ（帯は空けたまま、列の位置は変えない。読み上げは書名と一行） | placeholder は一行の形の灰の帯（redacted）。本の文を出さない | 写しを読めない（バックアップから戻した直後など）：`widget.unavailable`「よむまを開くと、ここに続きの一行が出ます。」。押すと S-1 | なし（通信を使わない） | なし（許可を使わない）。「一行と書名を隠す」がオン：「しおり」と「p.61」だけ（AC-34） | 26字以上の一行：縮め方で25字まで（AC-29）。書名のない今の本（書誌を待っているか見つからなかった。写しに title がない。決定 66）：一行があれば変わらない（一行とページ。状態 normal）。一行がなければ、書名の所に `widget.currentBookAsTitle`「今の本」と「p.120」（noLine）、ページもなければ「今の本」だけ（noLineNoPage）。ISBN は出さない（写しにない。PRD 12）。読み上げは 6。一行が日本語の字を含まない：横書き |
| W-2 | 縦書きの一行と「p.61」（W-1 より大きい。列は上にそろえ、ページは列の下の左端。間は `space.4`） | W-1 と同じ（一行あり・ページなしは一行だけ） | W-1 と同じ | W-1 と同じ | なし（通信を使わない） | なし（許可を使わない）。隠す設定は W-1 と同じ | W-1 と同じ。暗い所の StandBy はシステムが赤の単色で描く |
| S-1 | 書名、著者、縦書きの一行（全文）、「p.61」、「どこまで読んだかを入れる」「読み終えた」（.bordered）、下端に固定した「読み始める」、伏せる案内の1行 | 本0冊：ContentUnavailableView（`bookmark.empty.title`、`bookmark.empty.message`、「本を加える」）。今の本なし：同（`bookmark.noCurrent.title`、`bookmark.noCurrent.message`、「本棚から選ぶ」）。どちらも「読み始める」と伏せる案内なし。一行もページもない：書名の下に `bookmark.noMark.message`（次の一手は「どこまで読んだかを入れる」）。一行あり・ページなし：一行を出し、ページの行（`bookmark.page`）を出さない。一行なし・ページあり：縦書きの所を詰め、著者の下に「p.61」 | 起動して保存先を読む間、0.3秒を超えたら書名と一行の形の灰の帯。空の状態を先に出さない | 保存先を読めない：ContentUnavailableView（`store.load.error.title`、`store.load.error`、「もう一度読み込む」）だけで、ツールバーは「設定」だけ。読み始めの保存の失敗：知らせ `session.start.error`。読み終えたの保存の失敗：知らせ `common.save.error`（S-9 を開かない） | なし（毎晩の道は通信を使わない。AC-62。通信の状態を出さない） | なし（許可を使わない）。結果待ち：Q-A で伏せる道に許可が要ると分かったら、PRD のやり直しに従う | 今の本の書誌を待っている：書名の所に「ISBN 9784101000015」、下に `book.pendingInfo`。見つからない：`book.infoNotFound` と「書名と著者を入れる」`book.edit`（.bordered。押すと S-7a を S-1 のシートで開く） |
| S-2 | 書名、「21:04 から数えています。」（読み始めた晩が今の晩と違うときは「10月17日 21:04 から数えています。」）、数え続けることの1行、下端に固定した「終える」 | なし（今の本がないと読み始められない。AC-46） | なし（端末の中だけ。開き直したときは S-1 と同じ読み込みのあとに出す） | 終わりの保存の失敗：「終える」の上に知らせ `session.save.error`（閉じるボタンなし。もう一度「終える」を押せる。AC-60） | なし（通信を使わない） | なし（許可を使わない） | 書名がない本（書誌を待っている）：書名の代わりに「ISBN 978…」 |
| S-3 | 書名、問い「どこまで読みましたか。」、主の道、2つ目の道、「あとで挟む」と「しおりは前のまま残ります。」 | 前のしおりがない：「あとで挟む」の下の文を `mark.later.note.empty`「しおりは空のままです。」に替える。読まずに挟むシートでは「あとで挟む」はない | なし（記録は「終える」で保存済み。AC-55 の0.5秒） | なし（この画面は保存しない。保存は S-3a、S-3b） | なし（通信を使わない） | なし（芯の道は許可を使わない。撮る道の断られたとき（AC-70）は選択肢 (6) で書く） | なし（出すのは今の本の書名と前のしおりだけ。書名がなければ「ISBN 978…」） |
| S-3a | 一行の欄（焦点、キーボードが上がる）、ページの欄（プレースホルダ「例 61」）とその下の消えない説明「前のページは43です。空のまま保存すると、43のまま残ります。」、保存 | 欄は空で始まる。一行が空のまま保存を押すと `mark.line.invalid`（保存のボタンは押せるままにする）。ページの欄が空なら、ページは変えない（前のページがなければページなしのまま。説明は「空のままでも保存できます。」） | 保存の間は保存のボタンを1回しか受けない。0.5秒を超えたら保存のボタンの所に ProgressView | 入力の誤り：欄のすぐ下に `mark.line.invalid`、`mark.page.invalid`。保存の失敗：Form のいちばん上の行に `common.save.error`（記号 exclamationmark.circle）、入れた字は残す（AC-95）。次に保存を押すまで出したまま | なし（通信を使わない） | なし（許可を使わない） | なし（入れる画面。読み込むのは前のページだけで、開く前に読み終えている） |
| S-3b | ページの欄（焦点、数字のキーボード、プレースホルダ「例 61」）、その下の消えない説明「前のページは43です。」と、一行が消えることの説明、保存 | 空のまま保存を押すと `mark.page.invalid`（AC-74）。前のページがない：「前のページは…」の説明を出さない | S-3a と同じ | 入力の誤り：`mark.page.invalid`。保存の失敗：Form のいちばん上の行に `common.save.error`、入れた字は残す | なし（通信を使わない） | なし（許可を使わない） | なし（入れる画面。読み込むのは前のページだけで、開く前に読み終えている） |
| S-4 | 書名、`result.summary`（「p.43 → p.61」「18分」）、「記録しました。」、下端に固定した「閉じる」 | 「あとで挟む」と、ページを入れずに一行だけ保存した晩：`result.summary` は「18分」だけ（ページは変わっていない）。前のページがない：「p.61」と「18分」 | なし（保存は前の画面で終わっている） | なし（保存の失敗は S-2 と S-3a で出す） | なし（通信を使わない） | なし（許可を使わない） | 1440分で止めた：summary の下に知らせ `session.capped` |
| S-5 | 見出し、説明、利用者の一行の見本（172×76 pt）、閉じる | なし（一行を保存したあとにだけ出る） | なし（見本の一行は、S-1 で読み込み済みのものを使う） | なし（この画面の操作は閉じるだけで、保存の結果を画面に出さない） | なし（通信を使わない） | なし（許可を使わない） | 「一行と書名を隠す」がオン：見本も「しおり」とページの形（設定どおりに見せる）。ページなし：見本も一行だけ |
| S-6 | 今の本、積読（加えた日の新しい順）、読み終えた（読み終えた日時の新しい順。日時は置き場所を「読み終えた」にしたときに入れ、ほかへ移したら消す） | 本0冊：ContentUnavailableView（`shelf.empty.title`、`shelf.empty.message`、「本を加える」）。本のない区分は出さない | 0.3秒を超えたら行の形の灰の帯を5行 | 読めない：ContentUnavailableView（`shelf.load.error`、「もう一度読み込む」） | なし（本棚は端末の中。書誌を待つ本は行に `book.pendingInfo`） | なし（許可を使わない） | 書誌を待つ本、見つからない本：行の書名の所に「ISBN 978…」、下に `book.pendingInfo` か `book.infoNotFound` |
| S-7 | 奥付、記録（何晩、合計、行）、この本を消す（文字は本文の色、記号 trash だけ赤）、下端に固定した「この本を読む」、ツールバーの直す | 記録0件：記録の節に `book.records.empty`。奥付はデータのある行だけ（書名1行だけのこともある。AC-18） | 0.3秒を超えたら記録の行の形の灰の帯（1,000件でも1.0秒以内。AC-101） | 読めない：ContentUnavailableView（`book.load.error`、「もう一度読み込む」）。今の本にする・消す・読み終えるの保存の失敗：画面の上に知らせ `common.save.error` | なし（書誌を待つ本は奥付の下に `book.pendingInfo`） | なし（許可を使わない） | 書名がない：奥付の1行目を「ISBN 978…」にし、下に `book.pendingInfo` か `book.infoNotFound` |
| S-7a | 書名、著者の欄（今の値が入っている）、取り消す、保存 | 書誌が見つからなかった本：欄は空で、説明 `book.edit.notFoundNote` | 保存の間は保存を1回しか受けない | `book.title.invalid`、`book.author.invalid`（欄のすぐ下）、`common.save.error`（Form のいちばん上の行）。入れた字は残す | なし（通信を使わない。手で直すと問い合わせ直しをやめる） | なし（許可を使わない） | なし（入れる画面。今の値をそのまま欄に入れる） |
| S-7b | 晩の日付（読むだけ）、分の欄、保存、この記録を消す（文字は本文の色、記号 trash だけ赤） | なし（記録の行から開くので、記録はいつもある） | S-7a と同じ | `record.minutes.invalid`、`common.save.error`（Form のいちばん上の行）。入れた字は残す | なし（通信を使わない） | なし（許可を使わない） | なし（入れる画面。開いた記録の値をそのまま出す） |
| S-8 | 3つの行（バーコードを続けて読む、書名で探す、手で入れる）、送るものの説明 | なし（いつも3つの道） | なし（決まった3つの行で、読み込むものがない。カメラの許可の状態はすぐ分かる） | バーコードを読めない端末：バーコードの行を押せなくし、下に `register.scanUnavailable` | なし（バーコードは通信なしでも加えられる。書名で探すは S-8b で出す） | カメラを断った：バーコードの行の下に `camera.denied` と「設定を開く」（.bordered。AC-12）。制限されている：`camera.restricted`（設定を開くボタンなし） | なし（3つの行はいつも全部出す。押せない行には、エラーと権限の列の理由の文を添える） |
| S-8a | 上にカメラ、下に読めた本の一覧（読んだ順）、下端に固定した「n冊を本棚に加える」。読んだ本が1冊以上の間は、戻るボタンを隠し、シートを払って閉じる操作を止め、出る道は閉じる（role .cancel）→ 確認だけ（決定 26） | まだ読んでいない：一覧の所に `scan.hint`。加えるボタンは押せない（0冊）。戻る、端からのスワイプ、シートを払う操作、閉じる（role .close）で、確認なしに出られる | 読めた行は ISBN と灰の帯（書誌を探している） | 書誌の問い合わせの失敗：行に `book.pendingInfo`（加えられる）。見つからない：行に `scan.row.notFound`。本棚に加える保存の失敗（AC-91 の本を加える）：一覧の上（カメラのすぐ下）に知らせ `common.save.error`。読んだ本の一覧は残し、シートは閉じない。「n冊を本棚に加える」はもう一度押せる | 行に `book.pendingInfo`（加えられる。AC-9） | 断っているときはこの画面に来ない（S-8 に残る）。読む途中で許可を外された：S-8 に戻って `camera.denied` | 本棚にある本：知らせ `scan.duplicate`。同じ回に2度読んだ本と本でないコード：何も出さない |
| S-8b | 検索欄（字があるときは消すボタン `search.clear`）、結果の行（書名、著者、出版社（レーベル）、出版年。1回の問い合わせ（cnt=200）で返った分だけで、続きを読み込まない。最大で約200行。並びは決定 27）、結果の下に「手で入れる」（.bordered）、下端に固定した「この本を加える」（選ぶまで押せない） | 入れる前：`search.prompt`。0件：ContentUnavailableView（`search.noResults.title`、`search.noResults`、「手で入れる」）。結果の行がない間は「この本を加える」を出さない | 行の形の灰の帯3行。2秒を超えたら ProgressView を足す（cnt=200 の1回は実測 5.70秒。30秒で打ち切り、エラーの列の `search.error` にする。ADR 0004） | 書誌のサービスの失敗：ContentUnavailableView（`search.error.title`、`search.error`、「もう一度探す」、「手で入れる」）。この本を加える保存の失敗（AC-91 の本を加える）：「この本を加える」のすぐ上に知らせ `common.save.error`。探した字と選んだ行は残し、シートは閉じない。もう一度押せる | ContentUnavailableView（`search.offline.title`、`search.offline`、「手で入れる」）（AC-6） | なし（許可を使わない） | ISBN のない結果は出さない。同じ ISBN は1行。レーベルのない本は出版社だけ。著者のない本は著者の行を出さない |
| S-8c | 書名、著者の欄、保存 | 欄は空で始まる。空のまま保存を押すと `book.title.invalid` | 保存の間は保存を1回しか受けない | `book.title.invalid`、`book.author.invalid`（欄のすぐ下）、`common.save.error`（Form のいちばん上の行。AC-91 の本を加える）。入れた字は残し、シートは閉じない | なし（手で入れる道は通信を使わない） | なし（許可を使わない） | なし（入れる画面。読み込むものがない） |
| S-9 | 見出し「読み終えました」、奥付、次の1冊（最大3冊、理由1行、この本を読む）、戻し方の1行 | 積読0冊：ContentUnavailableView（`next.empty.title`、`next.empty.message`、「本を加える」）（AC-81）。押すと S-8（S-9 の上のシート）。加えると S-8 と S-9 が閉じて、S-1 に加えた本が出る | 0.3秒を超えたら候補の行の形の灰の帯 | 選んだ本を今の本にする保存の失敗：画面の上に知らせ `common.save.error`、S-9 のまま | なし（候補は端末の中の本だけ） | なし（許可を使わない） | 書誌を待つ候補：書名の所に「ISBN 978…」、理由は「積読から」。奥付はデータのある行だけ |
| S-10 | 読み始め（伏せて始める）、ロック画面（一行と書名を隠す）、情報（プライバシーポリシー、書誌の出どころ、ライセンス。Link の行は末尾に arrow.up.forward） | なし（いつも同じ行） | なし（設定は端末の中） | 設定の保存の失敗：切り替えを前の値に戻し、節の下に `common.save.error` | なし（リンクは Safari が開き、開けないときは Safari が知らせる） | なし（許可を使わない。カメラの許可はシステムの設定で扱う） | 伏せる道を使えない端末（H18）：「伏せて始める」を押せなくし、下に `settings.flipToStart.unavailable` |
| 部品 N | 記号、文、閉じる（.bordered の小さいボタン） | なし（部品なので、置いた画面の状態に従う） | なし（部品なので、置いた画面の状態に従う） | エラーの知らせは記号 exclamationmark.circle（赤）、ほかは info.circle（本文の色） | なし（部品なので、置いた画面の状態に従う） | なし（部品なので、置いた画面の状態に従う） | なし（部品なので、置いた画面の状態に従う） |

### 長い文字、0件、とても多いとき、取り消せない操作
- 長い書名（100字まで）：S-1 と S-6 は2行まで出して末尾を「…」。読み上げは全文。S-7 の奥付と S-7a は全文。AX のサイズでは行数の上限を外す。
- 長い一行（60字まで）：S-1 は全文（縦で入らなければ横書き）。ウィジェットは縮め方で25字まで。
- 長い著者（100字まで）：S-1 は1行で末尾「…」、奥付は全文。
- 0件：本0冊（S-1、S-6）、記録0件（S-7）、積読0冊（S-9）、検索0件（S-8b）は上の表のとおり。どれも「0」の数を見出しにしない。
- とても多いとき：本500冊、1冊に記録1,000件でも、S-6 と S-7 は List の遅延の描き方で1.0秒以内（AC-101）。S-8a で読んだ本が多いときは、一覧の最後の行（いま読んだ本）が見える所まで送る。S-8b は1回の問い合わせ（cnt=200。ADR 0004）で返った分だけを出し、続きを読み込まない。ISBN のない結果と、同じ ISBN の2つ目からを除くので、最大で約200行（7-2 で「人間失格」は ISBN のある結果が110件）。List の遅延の描き方で出す。並びは決定 27 で、探した書名と同じ書名と、それで始まる書名が上に来る。結果の下の「手で入れる」が遠いときは、戻って S-8 の「手で入れる」でも入れられる（2タップ）。
- 取り消せない操作の確認（confirmationDialog）：本を消す（記録の件数を文に入れる）、記録を消す、読んだ本を加えずに S-8a を閉じる（読んだ本がある間は、戻る、端からのスワイプ、シートを払う操作を止め、閉じるからだけにする。決定 26）。押し間違いを本棚から戻せる「読み終えた」と、記録を直せる「終える」には確認を挟まない（決定 15）。

### S-9 の、3b が届かなかったときの差分（AC-87）
- 候補は1冊だけ。理由は2種類（「積読から・同じ著者」、同じ著者がなければ積読に加えた日がいちばん新しい本を「積読から」）。
- 見出し「次の1冊」と下の説明の文 `next.subheader` はそのまま。ボタンは同じ「この本を読む」。積読がないときは AC-81 と同じ空の状態。

## 6. 要素と識別子
PRD の識別子はそのまま使った。PRD にないものは「足した」と書いた。一覧の行は `<名前>.<id か ISBN>` の形（PRD 11 の冒頭）。行の中の要素（`next.reason`、`next.choose`）は、行の中で探す。文を出す要素（知らせ、誤り、空の文）は、識別子を文言キーと同じ名前にした（足した。テストが文の要素を探しやすいため）。VoiceOver のラベルを書いていない行は、見えている文がそのままラベル。

| 画面 | 要素 | accessibilityIdentifier | VoiceOver のラベル |
|---|---|---|---|
| W-1、W-2 | ウィジェット全体（読み上げは1つのまとまり） | `widget.rectangular`、`widget.small`（足した。H22 で読む名前） | 「羅生門、61ページ。下人は、雨やみを待っていた。」（書名、ページ、一行。縦書き用の字は使わない。AC-99）。ページなし「羅生門。下人は、雨やみを待っていた。」。隠すとき「しおり、61ページ」。今の本なし：`widget.empty` の文。写しを読めない：`widget.unavailable` の文（contracts/widget-snapshot.schema.json の読む側の決まり）。一行なし「檸檬、120ページ」（`widget.spoken.noLine`）、ページもなし「檸檬」。書名のない今の本（決定 66）は書名の所を「今の本」にする：「今の本、61ページ。下人は、雨やみを待っていた。」、ページなし「今の本。下人は、雨やみを待っていた。」、一行なし「今の本、120ページ」、どちらもなし「今の本」。書名から始める理由は 9 の読み上げ順 |
| W-1、W-2 | 一行、ページ、書名（読み上げからは隠し、全体のラベルに入れる） | `widget.line`、`widget.page`、`widget.title`（足した。H22 で読む名前。書名のない今の本で一行がないときは、`widget.title` に `widget.currentBookAsTitle` の文が出る。決定 66） | （全体のラベルに入る） |
| S-1 | ツールバーの本棚 | `toolbar.shelf` | 「本棚」 |
| S-1 | ツールバーの設定 | `toolbar.settings` | 「設定」 |
| S-1 | 書名 | `bookmark.title` | 書名（見出しの印 isHeader） |
| S-1 | 著者 | `bookmark.author`（足した） | 著者 |
| S-1 | 一行 | `bookmark.line` | 保存した一行そのもの（AC-99） |
| S-1 | ページ | `bookmark.page` | 「61ページ」（表示は「p.61」。テストは値 61 で比べる） |
| S-1 | どこまで読んだかを入れる | `bookmark.setMark` | 「どこまで読んだかを入れる」 |
| S-1 | 読み終えた | `bookmark.finish` | 「読み終えた」。ヒント「奥付と次の1冊を出します。」 |
| S-1 | 読み始める | `bookmark.start` | 「読み始める」 |
| S-1 | 伏せる案内の1行 | `bookmark.flipHint` | 文のとおり |
| S-1 | 本0冊の文 | `bookmark.empty.message` | 文のとおり |
| S-1 | 本を加える | `bookmark.addBook` | 「本を加える」 |
| S-1 | 今の本なしの文 | `bookmark.noCurrent.message` | 文のとおり |
| S-1 | 本棚から選ぶ | `bookmark.openShelf`（足した） | 「本棚から選ぶ」 |
| S-1 | しおりなしの文 | `bookmark.noMark.message`（足した） | 文のとおり |
| S-1、S-6、S-7、S-9 | 書誌を待つ文 | `book.pendingInfo` | 文のとおり（ISBN は数字を1つずつでなく続けて読む） |
| S-1、S-6、S-7 | 書誌が見つからない文 | `book.infoNotFound` | 文のとおり |
| S-1 | 書名と著者を入れる（見つからないときだけ） | `book.edit` | 「書名と著者を入れる」 |
| S-1 | 読み込めない文 | `store.load.error` | 文のとおり |
| S-1 | もう一度読み込む | `store.retry`（足した） | 「もう一度読み込む」 |
| 部品 N | 知らせの帯 | `notice`（足した）。文の要素は文言キーと同じ名前（例 `session.tooShort`） | 文のとおり（記号は読まない） |
| 部品 N | 閉じる | `notice.close`（足した） | 「閉じる」（見える文字のまま）。ヒント「知らせを閉じます。」 |
| S-2 | 書名 | `reading.title`（足した） | 書名 |
| S-2 | 始めた時刻 | `reading.startedAt`（足した） | 「21時4分から数えています。」（時刻は端末の言語で読む。読み始めた晩が今の晩と違うときは「10月17日 21時4分から数えています。」） |
| S-2 | 数え続けることの1行 | `reading.note`（足した） | 文のとおり |
| S-2 | 終える | `reading.end` | 「終える」 |
| S-3 | 問い | `mark.question`（足した） | 文のとおり（見出しの印） |
| S-3 | 一行を入れる | `mark.manual` | 「一行を入れる」 |
| S-3 | ページだけ入れる | `mark.pageOnly` | 「ページだけ入れる」 |
| S-3 | あとで挟む | `mark.later` | 「あとで挟む」。ヒント「しおりは前のまま残ります。」 |
| S-3 | 閉じる（読まずに挟むシートのときだけ） | `mark.cancel`（足した） | 「閉じる」 |
| S-3 | 撮る | `mark.photo` | 選択肢 (6) |
| S-3a | 一行の欄 | `mark.lineField` | 「一行」 |
| S-3a、S-3b | ページの欄 | `mark.pageField` | 「ページ」 |
| S-3a、S-3b | 前のページの説明（前のページがあるときだけ。消えない文） | `mark.page.previous`（足した） | 文のとおり（「前のページは43です。…」） |
| S-3a、S-3b | 保存 | `mark.save` | 「保存」 |
| S-3a、S-3b | 誤りの文 | `mark.line.invalid`、`mark.page.invalid` | 文のとおり。出たときに読み上げを1回 |
| S-3a ほか | 保存の失敗の文 | `common.save.error` | 文のとおり。出たときに読み上げを1回 |
| S-4 | 書名 | `result.title`（足した） | 書名 |
| S-4 | まとめ | `result.summary` | 「43ページから61ページ、18分」。前のページなし「61ページ、18分」。あとで挟む「18分」 |
| S-4 | 記録しました | `result.saved`（足した） | 文のとおり |
| S-4 | 閉じる | `result.close`（足した） | 「閉じる」 |
| S-5 | 案内のシート | `widgetGuide` | 見出し「ロック画面に置く」 |
| S-5 | 見本 | `widgetGuide.preview`（足した） | 「ロック画面での見え方。」に続けて、W-1 と同じラベル |
| S-5 | 閉じる | `widgetGuide.close`（足した） | 「閉じる」 |
| S-6 | 区分 | `shelf.current`、`shelf.tsundoku`、`shelf.finished` | 区分の見出し（「今の本」「積読」「読み終えた」） |
| S-6 | 本の行 | `shelf.row.<本の id>`（足した） | 「書名、著者」 |
| S-6 | 本を加える（ツールバー） | `shelf.addBook`（足した） | 「本を加える」 |
| S-6 | 本0冊のときの本を加える | `shelf.empty.addBook`（足した） | 「本を加える」 |
| S-6 | 読み込めない、もう一度 | `shelf.load.error`、`shelf.retry`（足した） | 文のとおり、「もう一度読み込む」 |
| S-7、S-9 | 奥付 | `book.colophon`（S-7）、`finish.colophon`（S-9） | 「奥付」 |
| S-7、S-9 | 奥付の行 | `colophon.title`、`colophon.author`、`colophon.publisher`、`colophon.year` | 行ごとに「名前、値」（例「出版社、新潮社、新潮文庫」） |
| S-7、S-9 | 受賞の行 | `colophon.award` | 選択肢 (4) |
| S-7 | 何晩、合計 | `book.nights`、`book.total`（足した） | 「4晩」「合計1時間25分」 |
| S-7 | 記録の行 | `book.record.row.<記録の id>` | 「10月17日の晩、10分」。見える文字「10/17」を accessibilityInputLabels に入れる（音声コントロールで見える文字のまま押せる。決定 60） |
| S-7 | 記録なしの文 | `book.records.empty` | 文のとおり |
| S-7 | この本を読む | `book.readThis` | 「この本を読む」 |
| S-7 | 今読んでいる本です | `book.isCurrent`（足した） | 文のとおり |
| S-7 | 直す（ツールバー） | `book.edit` | 「直す」 |
| S-7 | この本を消す | `book.delete` | 「この本を消す」 |
| S-7 | 確認の「消す」 | `book.delete.confirmButton`（足した） | 「消す」 |
| S-7 | 読み込めない、もう一度 | `book.load.error`、`book.retry`（足した） | 文のとおり、「もう一度読み込む」 |
| S-7a | 書名の欄、著者の欄 | `book.edit.title`、`book.edit.author`（足した） | 「書名」「著者」 |
| S-7a | 保存、取り消す | `book.edit.save`、`book.edit.cancel`（足した） | 「保存」「取り消す」 |
| S-7b | 晩 | `record.night`（足した） | 「10月16日の晩」 |
| S-7b | 分の欄 | `record.minutesField`（足した） | 「分」 |
| S-7b | 保存、取り消す | `record.save`、`record.cancel`（足した） | 「保存」「取り消す」 |
| S-7b | この記録を消す | `record.delete`（足した） | 「この記録を消す」 |
| S-7b | 確認の「消す」 | `record.delete.confirmButton`（足した） | 「消す」 |
| S-7b | 誤りの文 | `record.minutes.invalid` | 文のとおり |
| S-8 | バーコードを続けて読む | `register.barcode` | 「バーコードを続けて読む」 |
| S-8 | 書名で探す | `register.search` | 「書名で探す」 |
| S-8、S-8b | 手で入れる | `register.manual` | 「手で入れる」 |
| S-8 | 閉じる | `register.cancel`（足した） | 「閉じる」 |
| S-8 | 許可がない文 | `camera.denied` | 文のとおり |
| S-8 | 設定を開く | `camera.openSettings` | 「設定を開く」 |
| S-8 | 制限の文、読めない端末の文 | `camera.restricted`、`register.scanUnavailable`（足した） | 文のとおり |
| S-8a | カメラ | `scan.camera`（足した） | 「カメラ。本の裏のバーコードを写してください。」 |
| S-8a | 読めた本の行 | `scan.row.<ISBN>` | 「書名、著者、出版社」。書誌を待つ間は「ISBN 9784101000015、書誌を探しています」 |
| S-8a | 本棚にある本の知らせ | `scan.duplicate` | 文のとおり |
| S-8a | n冊を本棚に加える | `scan.addToShelf` | 「2冊を本棚に加える」 |
| S-8a | 閉じる | `scan.cancel`（足した） | 「閉じる」（role は0冊で .close、1冊以上で .cancel。決定 26） |
| S-8a | 確認の「加えずに閉じる」 | `scan.discard.confirmButton`（足した） | 「加えずに閉じる」 |
| S-8b | 検索欄 | `search.field` | 「書名」（検索欄の印 isSearchField） |
| S-8b | 消すボタン（字があるときだけ。記号 xmark.circle.fill） | `search.clear`（足した） | 「入力を消す」 |
| S-8b | 結果の行 | `search.row.<ISBN>` | 「書名、著者、出版社、レーベル、出版年」。選んだ行は状態「選択中」（isSelected。色だけで示さない） |
| S-8b | この本を加える | `register.confirm` | 「この本を加える」 |
| S-8b | 0件、通信なし、失敗の文 | `search.noResults`、`search.offline`、`search.error`（`search.error` は足した） | 文のとおり |
| S-8b | もう一度探す | `search.retry`（足した） | 「もう一度探す」 |
| S-8c | 書名の欄、著者の欄 | `manual.title`、`manual.author` | 「書名」「著者」 |
| S-8c | 保存、取り消す | `manual.save`、`manual.cancel`（`manual.cancel` は足した） | 「保存」「取り消す」 |
| S-8c、S-7a | 誤りの文 | `book.title.invalid`、`book.author.invalid` | 文のとおり |
| S-9 | 見出し | `finish.title`（足した） | 「読み終えました」（見出しの印） |
| S-9 | 候補の行 | `next.candidate.<本の id>` | 「書名、著者。積読から、同じ著者。」（行の中の要素を1つのまとまりにし、ボタンは別） |
| S-9 | 理由の1行（行の中） | `next.reason` | 「積読から、同じ著者」（「・」は読まない） |
| S-9 | この本を読む（行の中） | `next.choose` | 「この本を読む、（書名）」 |
| S-9 | 積読なしの文 | `next.empty.message` | 文のとおり |
| S-9 | 本を加える | `next.addBook` | 「本を加える」 |
| S-9 | 戻し方の1行 | `finish.undoNote`（足した） | 文のとおり |
| S-9 | 閉じる | `finish.close`（足した） | 「閉じる」 |
| S-9 | ふりかえりの1行、カード | `finish.reflection`、`finish.card.share` | 選択肢 (3) |
| S-9 | 新しい本の行の積読に加える | `next.addToShelf` | 選択肢 (4) |
| S-10 | 伏せて始める | `settings.flipToStart` | 「伏せて始める」と、オンかオフ（Toggle の値） |
| S-10 | 使えない端末の文 | `settings.flipToStart.unavailable`（足した） | 文のとおり |
| S-10 | 一行と書名を隠す | `settings.hideOnWidgets` | 「一行と書名を隠す」と、オンかオフ |
| S-10 | プライバシーポリシー | `settings.privacyPolicy` | 「プライバシーポリシー、Safari で開きます」（末尾の記号 arrow.up.forward は読まない） |
| S-10 | 書誌の出どころ | `settings.dataSources` | 見出し「書誌の出どころ」（`settings.dataSources.header`）と文を1つのまとまりにして読む（文は 7。ADR 0004 の文） |
| S-10 | ライセンス | `settings.dataSources.license` | 「ライセンス、CC BY 4.0、Safari で開きます」 |
| S-10 | 入口の時刻、Live Activity が切れている文 | `settings.entryTime`、`settings.liveActivity.off` | 選択肢 (5) |

## 7. 文言
- 調子：です・ます、淡々。感嘆符、絵文字、冗談を使わない。ほめない、祝わない。ボタンは動詞（英語は動詞で始める）。エラーは何が起きたかとどう直すかを書き、責めない（調査の 5、R-26、R-31）。
- 文字列をつなげない。書名、ISBN、数、時刻は書式の引数で入れる（%@、%lld）。英語の数は String Catalog の複数形（one と other）を使う。日本語の文は横書きの禁則をシステムに任せ、文の途中で手で改行しない。
- 日付と時刻は Date.FormatStyle（記録の行は月と日の数字、晩は「10月17日」、時刻は端末の 12時間・24時間の設定に従う）。ページの数と年には桁の区切りを入れない。
- 英語のアプリの名前は仮に Yomuma と書いた（10）。PRD の文言キーは「PRD」、この仕様で足したものは「足した」。

| キー | 日本語 | 英語 | 使う場所 |
|---|---|---|---|
| `bookmark.navTitle` | しおり | Bookmark | S-1 の題（小さく中央）。足した |
| `toolbar.shelf` | 本棚 | Bookshelf | S-1 のツールバー（記号 books.vertical と読み上げ）。PRD |
| `toolbar.settings` | 設定 | Settings | S-1 のツールバー（記号 gearshape と読み上げ）。PRD |
| `bookmark.start` | 読み始める | Start Reading | S-1 の主操作。PRD |
| `bookmark.setMark` | どこまで読んだかを入れる | Mark Your Place | S-1。PRD |
| `bookmark.finish` | 読み終えた | Mark as Finished | S-1。PRD |
| `bookmark.finish.hint` | 奥付と次の1冊を出します。 | Shows the colophon and your next book. | S-1 の読み上げのヒント。足した |
| `bookmark.flipHint`（案1） | この画面で iPhone を伏せて置いても、読み始めます。 | You can also start by placing iPhone face down on this screen. | S-1。Q-A で縦の固定に関わらず届いたとき（結果待ち）。PRD |
| `bookmark.flipHint`（案2） | この画面で iPhone を伏せて置いても、読み始めます（画面縦向きのロックがオフのとき）。 | You can also start by placing iPhone face down on this screen (when Portrait Orientation Lock is off). | S-1。縦の固定がオンだと届かず、ほかの取り方もないとき（結果待ち） |
| `bookmark.empty.title` | まだ本がありません | No Books Yet | S-1 の空。足した |
| `bookmark.empty.message` | 読んでいる紙の本を1冊加えると、ここに続きの一行が出ます。 | Add a paper book you're reading, and the line where you stopped will appear here. | S-1 の空。PRD |
| `bookmark.addBook` | 本を加える | Add a Book | S-1 の空。PRD |
| `bookmark.noCurrent.title` | 今の本がありません | No Current Book | S-1。足した |
| `bookmark.noCurrent.message` | 本棚から、次に読む1冊を選んでください。 | Choose the next book to read from your bookshelf. | S-1。PRD |
| `bookmark.openShelf` | 本棚から選ぶ | Choose from Bookshelf | S-1。足した |
| `bookmark.noMark.message` | どこまで読んだかを入れると、ここに続きの一行が出ます。 | Mark your place, and the line will appear here. | S-1（一行もページもないとき）。足した |
| `page.short` | p.%lld | p.%lld | S-1、S-4、W-1、W-2。足した |
| `page.spoken` | %lldページ | page %lld | ページの読み上げ。足した |
| `book.isbnAsTitle` | ISBN %@ | ISBN %@ | 書名がない本の書名の所。足した |
| `book.pendingInfo` | 書誌を待っています（ISBN %@）。アプリを開いたときに、もう一度問い合わせます。 | Waiting for book details (ISBN %@). Yomuma will check again when you open it. | S-1、S-6、S-7、S-8a、S-9。PRD |
| `book.infoNotFound` | 書誌が見つかりませんでした。書名と著者を入れてください。日を置いて、もう一度問い合わせます。 | No book details were found. Enter the title and author. Yomuma will check again in a day. | S-1、S-6、S-7。PRD |
| `book.edit.fromBookmark` | 書名と著者を入れる | Enter Title and Author | S-1 の `book.edit`。足した |
| `store.load.error.title` | 記録を読み込めませんでした | Couldn't Load Your Books | S-1。足した |
| `store.load.error` | もう一度読み込んでください。続くときは、アプリを終了して開き直してください。 | Try loading again. If it keeps happening, quit Yomuma and open it again. | S-1。PRD |
| `store.retry` | もう一度読み込む | Try Again | S-1。足した |
| `notice.close` | 閉じる | Dismiss | 部品 N（読み上げのラベルは見える文字のまま）。足した |
| `notice.close.hint` | 知らせを閉じます。 | Dismisses the notice. | 部品 N の閉じるの読み上げのヒント。足した |
| `session.tooShort` | 1分未満の読書は記録に残しません。 | Sessions shorter than 1 minute aren't saved. | S-1 の知らせ。PRD |
| `session.invalidTime` | 端末の時刻が読み始めより前になっていたので、この読書は記録に残しませんでした。「設定」で日付と時刻を確かめてから、もう一度読み始めてください。 | This session wasn't saved because the device's time was set earlier than when you started. Check the date and time in Settings, then start again. | S-1 の知らせ。PRD のキー（直し方の文を足した） |
| `session.start.error` | 読み始めを保存できませんでした。もう一度「読み始める」を押してください。 | Couldn't start the session. Tap Start Reading again. | S-1 の知らせ。PRD |
| `common.save.error` | 保存できませんでした。変更は反映されていません。もう一度試してください。 | Couldn't save. Nothing was changed. Please try again. | 保存した画面の知らせか、欄の上。PRD |
| `session.flipStarted.announcement` | 「%@」を読み始めました。 | Started reading %@. | 伏せて始まったときの読み上げ。PRD |
| `reading.startedAt` | %@ から数えています。 | Counting since %@. | S-2（%@ は時刻。読み始めた晩が今の晩と違うときは月日と時刻。どちらも Date.FormatStyle で作る）。足した |
| `reading.note` | 伏せても、ロックしても、ほかのアプリを使っても数え続けます。 | Keeps counting while iPhone is face down, locked, or in another app. | S-2。足した |
| `reading.end` | 終える | End Reading | S-2 の主操作。PRD |
| `session.save.error` | 終わりを保存できませんでした。読書は続いています。もう一度「終える」を押してください。 | Couldn't save the end of this session. It's still running. Tap End Reading again. | S-2 の知らせ。PRD |
| `mark.navTitle` | しおりを挟む | Mark Your Place | S-3 の題。足した |
| `mark.question` | どこまで読みましたか。 | Where did you stop? | S-3。足した |
| `mark.manual` | 一行を入れる | Enter the Line | S-3。PRD の識別子の文 |
| `mark.pageOnly` | ページだけ入れる | Enter Page Only | S-3。PRD の識別子の文 |
| `mark.later` | あとで挟む | Mark Later | S-3。PRD の識別子の文 |
| `mark.later.note` | しおりは前のまま残ります。 | Your bookmark stays where it was. | S-3。足した |
| `mark.later.note.empty` | しおりは空のままです。 | Your bookmark stays empty. | S-3。足した |
| `mark.cancel` | 閉じる | Close | S-3 のシート（記号 xmark）。足した |
| `mark.line.label` | 一行 | Line | S-3a。足した |
| `mark.line.placeholder` | 止めた行を、本のとおりに | Type the line as printed | S-3a。足した |
| `mark.line.footer` | 1〜60字。ロック画面には25字まで出ます。 | 1–60 characters. Up to 25 appear on the Lock Screen. | S-3a。足した |
| `mark.page.label` | ページ | Page | S-3a、S-3b。足した |
| `mark.page.placeholder` | 例 61 | e.g. 61 | S-3a、S-3b のプレースホルダ（いつも。なくても困らない手がかりだけ。決定 18）。足した |
| `mark.page.footer.keep` | 前のページは%1$lldです。空のまま保存すると、%1$lldのまま残ります。 | Previous page: %1$lld. If you leave this blank, it stays at %1$lld. | S-3a の欄の下の消えない説明（前のページがあるとき。識別子 `mark.page.previous`）。足した |
| `mark.page.footer.optional` | 空のままでも保存できます。 | You can leave this blank. | S-3a の欄の下（前のページがないとき）。足した |
| `mark.page.previous` | 前のページは%lldです。 | Previous page: %lld. | S-3b の欄の下の消えない説明（前のページがあるとき。識別子 `mark.page.previous`）。足した |
| `mark.pageOnly.footer` | 保存すると一行は消え、ロック画面には書名とページが出ます。 | Saving clears the line. The Lock Screen will show the title and page. | S-3b。足した |
| `mark.save` | 保存 | Save | S-3a、S-3b（記号 checkmark と読み上げ）。PRD の識別子の文 |
| `mark.line.invalid` | 一行は1〜60字で入れてください。 | Enter a line of 1 to 60 characters. | S-3a。PRD |
| `mark.page.invalid` | ページは1〜9999の数字で入れてください。 | Enter a page number from 1 to 9999. | S-3a、S-3b。PRD |
| `result.summary.pages` | p.%1$lld → p.%2$lld | p.%1$lld → p.%2$lld | S-4 の1行目。足した |
| `result.summary.spoken.pages` | %1$lldページから%2$lldページ、%3$@ | Page %1$lld to page %2$lld, %3$@ | S-4 の読み上げ。足した |
| `result.saved` | 記録しました。 | Session saved. | S-4。足した |
| `result.close` | 閉じる | Done | S-4 の主操作。足した |
| `session.capped` | 24時間で数えるのを止めました。分数は、本の画面の記録で直せます。 | Counting stopped at 24 hours. You can edit the minutes in the book's reading log. | S-4 の知らせ。PRD |
| `widgetGuide.title` | ロック画面に置く | Add to Your Lock Screen | S-5。足した |
| `widgetGuide.body` | ロック画面を長押しして「カスタマイズ」を選び、時計の下の枠に「よむま」を加えると、iPhone を手に取るたびに、この一行が出ます。 | Touch and hold the Lock Screen, tap Customize, and add Yomuma below the clock. This line will appear each time you pick up iPhone. | S-5。足した。iOS 26 の手順の言葉は G4 で実機と照らす［推測］ |
| `widgetGuide.preview.label` | ロック画面での見え方。 | How it looks on the Lock Screen. | S-5 の見本の読み上げ。足した |
| `widgetGuide.close` | 閉じる | Done | S-5 の主操作。足した |
| `widget.displayName` | 続きの一行 | Where You Stopped | ウィジェットのギャラリーの名前。足した |
| `widget.description` | 今の本の、止めた一行とページを出します。 | Shows the line and page where you stopped in your current book. | ウィジェットのギャラリーの説明。足した |
| `widget.empty` | 今の本を選ぶと、ここに続きの一行が出ます。 | Choose a book in Yomuma to see your place here. | W-1、W-2。PRD |
| `widget.hidden` | しおり | Bookmark | W-1、W-2（隠す設定のとき、ページと一緒に）。PRD |
| `widget.unavailable` | よむまを開くと、ここに続きの一行が出ます。 | Open Yomuma to show your place here. | W-1、W-2（写しを読めないとき。読み上げのラベルも同じ文。contracts/widget-snapshot.schema.json）。足した |
| `widget.spoken` | %1$@、%2$@。%3$@ | %1$@, %2$@. %3$@ | W-1、W-2 の読み上げ（書名、ページ、一行）。足した |
| `widget.spoken.noPage` | %1$@。%2$@ | %1$@. %2$@ | W-1、W-2 の読み上げ（ページなし：書名、一行）。足した |
| `widget.spoken.noLine` | %1$@、%2$@ | %1$@, %2$@ | W-1、W-2 の読み上げ（一行なし：書名か `widget.currentBookAsTitle` か `widget.hidden` の文と、`page.spoken`。例「檸檬、120ページ」「今の本、120ページ」「しおり、61ページ」）。足した |
| `widget.currentBookAsTitle` | 今の本 | Reading Now | W-1、W-2 の書名の所と読み上げの書名の所（書名のない今の本。写しに ISBN がないので `book.isbnAsTitle` を使えない。決定 66）。`shelf.current` と同じ言葉。足した |
| `shelf.navTitle` | 本棚 | Bookshelf | S-6 の題。足した |
| `shelf.current` | 今の本 | Reading Now | S-6 の区分。PRD の識別子の文 |
| `shelf.tsundoku` | 積読 | To Read | S-6 の区分。PRD の識別子の文 |
| `shelf.finished` | 読み終えた | Finished | S-6 の区分。PRD の識別子の文 |
| `shelf.addBook` | 本を加える | Add a Book | S-6 のツールバー（記号 plus と読み上げ）、空のボタン。足した |
| `shelf.empty.title` | 本棚に本がありません | No Books on Your Bookshelf | S-6。足した |
| `shelf.empty.message` | 読んでいる本と、積んである本を加えてください。 | Add the book you're reading and the ones waiting in your pile. | S-6。足した |
| `shelf.load.error` | 本棚を読み込めませんでした。もう一度読み込んでください。 | Couldn't load your bookshelf. Try loading again. | S-6。足した |
| `shelf.retry` / `book.retry` | もう一度読み込む | Try Again | S-6、S-7。足した |
| `colophon.header` | 奥付 | Colophon | S-7、S-9。足した |
| `colophon.title.label` | 書名 | Title | 奥付。足した |
| `colophon.author.label` | 著者 | Author | 奥付。足した |
| `colophon.publisher.label` | 出版社 | Publisher | 奥付。足した |
| `colophon.publisher.withLabel` | %1$@（%2$@） | %1$@ (%2$@) | 奥付（出版社とレーベル）。足した |
| `colophon.year.label` | 出版年 | Published | 奥付。足した |
| `colophon.year.value` | %lld年 | %lld | 奥付（桁の区切りなし）。足した |
| `book.records.header` | 記録 | Reading Log | S-7。足した |
| `book.nights` | %lld晩 | one: %lld night / other: %lld nights | S-7。足した |
| `book.total` | 合計 %@ | Total %@ | S-7。足した |
| `book.records.empty` | まだ記録がありません。読み始めて終えると、ここに残ります。 | No sessions yet. They appear here after you start and end reading. | S-7。PRD |
| `book.record.spoken` | %1$@の晩、%2$@ | Night of %1$@, %2$@ | S-7 の記録の行の読み上げ。足した |
| `book.readThis` | この本を読む | Read This Book | S-7 の主操作。PRD の識別子の文 |
| `book.isCurrent` | 今読んでいる本です。 | You're reading this book. | S-7。足した |
| `book.edit` | 直す | Edit | S-7 のツールバー。PRD の識別子の文 |
| `book.delete` | この本を消す | Delete This Book | S-7。PRD の識別子の文 |
| `book.delete.confirm` | 「%1$@」と、この本の記録%2$lld件を消します。元に戻せません。 | one: Delete “%1$@” and its %2$lld session? This can't be undone. / other: Delete “%1$@” and its %2$lld sessions? This can't be undone. | S-7 の確認（記録が1件以上）。PRD |
| `book.delete.confirm.noRecords` | 「%@」を消します。元に戻せません。 | Delete “%@”? This can't be undone. | S-7 の確認（記録0件）。足した |
| `book.delete.confirmButton` / `record.delete.confirmButton` | 消す | Delete | 確認の破壊のボタン。足した |
| `book.load.error` | この本を読み込めませんでした。もう一度読み込んでください。 | Couldn't load this book. Try loading again. | S-7。足した |
| `book.edit.navTitle` | 本を直す | Edit Book | S-7a。足した |
| `book.edit.title` / `manual.title` | 書名 | Title | S-7a、S-8c。足した（manual は PRD の識別子の文） |
| `book.edit.author` / `manual.author` | 著者 | Author | S-7a、S-8c。同上 |
| `book.edit.footer` / `manual.footer` | 書名は1〜100字、著者は100字まで（空でもかまいません）。 | Title: 1–100 characters. Author: up to 100 (optional). | S-7a、S-8c。足した |
| `book.edit.notFoundNote` | 書名か著者を入れると、日を置いた問い合わせはやめます。 | Once you enter a title or author, Yomuma stops checking for details. | S-7a（書誌が見つからなかった本）。足した |
| `book.edit.save` / `manual.save` / `record.save` | 保存 | Save | S-7a、S-8c、S-7b（記号 checkmark と読み上げ）。足した |
| `book.edit.cancel` / `manual.cancel` / `record.cancel` | 取り消す | Cancel | S-7a、S-8c、S-7b（記号 xmark と読み上げ）。足した |
| `book.title.invalid` | 書名は1〜100字で入れてください。 | Enter a title of 1 to 100 characters. | S-7a、S-8c。PRD |
| `book.author.invalid` | 著者は100字までで入れてください。 | Enter an author name of up to 100 characters. | S-7a、S-8c。PRD |
| `record.navTitle` | 記録を直す | Edit Session | S-7b。足した |
| `record.night` | %@の晩 | Night of %@ | S-7b。足した |
| `record.minutes.label` | 分 | Minutes | S-7b。足した |
| `record.minutes.footer` | 1〜1440分 | 1 to 1,440 minutes | S-7b。足した |
| `record.delete` | この記録を消す | Delete This Session | S-7b。足した |
| `record.delete.confirm` | この記録（%@）を消します。元に戻せません。 | Delete this session (%@)? This can't be undone. | S-7b の確認。足した |
| `record.minutes.invalid` | 分は1〜1440の数字で入れてください。 | Enter minutes from 1 to 1,440. | S-7b。PRD |
| `register.navTitle` | 本を加える | Add a Book | S-8。足した |
| `register.barcode` | バーコードを続けて読む | Scan Barcodes | S-8（記号 barcode.viewfinder）。PRD の識別子の文 |
| `register.search` | 書名で探す | Search by Title | S-8（記号 magnifyingglass）。PRD の識別子の文 |
| `register.manual` | 手で入れる | Enter Manually | S-8（記号 square.and.pencil）、S-8b。PRD の識別子の文 |
| `register.footer` | 本の情報は、ISBN か書名を国立国会図書館サーチに送って探します。 | To find book details, Yomuma sends the ISBN or title to NDL Search, run by the National Diet Library. | S-8 の下。足した |
| `register.cancel` / `scan.cancel` / `finish.close` | 閉じる | Close | シートの閉じる（記号 xmark と読み上げ）。足した |
| `camera.denied` | カメラの使用が許可されていません。設定で許可するか、書名で探すか、手で入れてください。 | Camera access is off. Allow it in Settings, or search by title or enter the book manually. | S-8。PRD |
| `camera.openSettings` | 設定を開く | Open Settings | S-8。PRD の識別子の文 |
| `camera.restricted` | この iPhone ではカメラが制限されています。書名で探すか、手で入れてください。 | The camera is restricted on this iPhone. Search by title or enter the book manually. | S-8。足した |
| `register.scanUnavailable` | この端末ではバーコードを読めません。書名で探すか、手で入れてください。 | This device can't scan barcodes. Search by title or enter the book manually. | S-8。足した |
| `scan.navTitle` | バーコードを続けて読む | Scan Barcodes | S-8a。足した |
| `scan.hint` | 本の裏のバーコードを写してください。続けて読めます。 | Point the camera at the barcode on the back of a book. You can scan one after another. | S-8a。足した |
| `scan.row.loading` | 書誌を探しています | Looking up details | S-8a の行。足した |
| `scan.row.notFound` | 書誌が見つかりませんでした。加えたあとで直せます。 | No details were found. You can edit them after adding. | S-8a の行。足した |
| `scan.duplicate` | 「%@」はもう本棚にあります。 | “%@” is already on your bookshelf. | S-8a の知らせ。PRD |
| `scan.duplicate.isbn` | この本（ISBN %@）はもう本棚にあります。 | This book (ISBN %@) is already on your bookshelf. | S-8a の知らせ（書名のない本）。足した |
| `scan.addToShelf` | %lld冊を本棚に加える | one: Add %lld Book to Bookshelf / other: Add %lld Books to Bookshelf | S-8a の主操作。PRD の識別子の文 |
| `scan.addToShelf.none` | 本棚に加える | Add to Bookshelf | S-8a（0冊。押せない）。足した |
| `scan.discard.confirm` | 読んだ%lld冊を加えずに閉じます。 | one: Close without adding %lld scanned book? / other: Close without adding %lld scanned books? | S-8a の確認。足した |
| `scan.discard.confirmButton` | 加えずに閉じる | Close Without Adding | S-8a の確認。足した |
| `search.navTitle` | 書名で探す | Search by Title | S-8b。足した |
| `search.field.placeholder` | 書名 | Title | S-8b。足した |
| `search.clear` | 入力を消す | Clear Text | S-8b の消すボタンの読み上げ（記号 xmark.circle.fill）。足した |
| `search.prompt` | 書名を入れて探します。 | Enter a title to search. | S-8b。足した |
| `search.noResults.title` | 見つかりませんでした | No Results | S-8b。足した |
| `search.noResults` | 「%@」に合う本はありませんでした。手で入れられます。 | No books matched “%@”. You can enter it manually. | S-8b。PRD |
| `search.offline.title` | 通信できません | You're Offline | S-8b。足した |
| `search.offline` | 書名で探すには通信が要ります。通信が戻ってから探すか、手で入れてください。 | Searching by title needs an internet connection. Try again when you're online, or enter the book manually. | S-8b。PRD |
| `search.error.title` | 探せませんでした | Couldn't Search | S-8b。足した |
| `search.error` | 書誌のサービスから答えがありませんでした。もう一度探すか、手で入れてください。 | The book catalog didn't respond. Try again, or enter the book manually. | S-8b。足した |
| `search.retry` | もう一度探す | Try Again | S-8b。足した |
| `search.footer` | 目当ての本がないときは、手で入れられます。 | Don't see your book? You can enter it manually. | S-8b の結果の下。足した |
| `register.confirm` | この本を加える | Add This Book | S-8b の主操作。PRD の識別子の文 |
| `manual.navTitle` | 手で入れる | Enter Manually | S-8c。足した |
| `finish.title` | 読み終えました | Finished | S-9 の見出し。足した |
| `next.header` | 次の1冊 | Your Next Book | S-9。足した |
| `next.subheader` | 積読から選んでいます。 | Picked from your to-read pile. | S-9。足した |
| `next.reason.tsundoku` | 積読から | From your pile | S-9 の `next.reason`。PRD の理由の言葉 |
| `next.reason.sameAuthor` | 積読から・同じ著者 | From your pile · Same author | S-9 の `next.reason`。PRD の理由の言葉、つなぎ方は足した |
| `next.reason.sameLabel` | 積読から・同じレーベル（%@） | From your pile · Same imprint (%@) | S-9 の `next.reason`。同上 |
| `next.choose` | この本を読む | Read This Book | S-9 の候補の行。PRD の識別子の文 |
| `next.empty.title` | 積読がありません | Your Pile Is Empty | S-9。足した |
| `next.empty.message` | 積読の本がありません。次に読む本を加えてください。 | There are no books in your pile. Add the book you'll read next. | S-9。PRD |
| `next.addBook` | 本を加える | Add a Book | S-9。PRD の識別子の文 |
| `finish.undoNote` | まだ読み終えていなかったときは、本棚でこの本を開き、「この本を読む」を押すと戻せます。 | Not finished after all? Open this book in your bookshelf and tap Read This Book. | S-9 のいちばん下。足した |
| `settings.navTitle` | 設定 | Settings | S-10。足した |
| `settings.section.start` | 読み始め | Starting a Session | S-10。足した |
| `settings.flipToStart` | 伏せて始める | Start When Face Down | S-10。PRD の識別子の文 |
| `settings.flipToStart.footer` | しおりの画面で iPhone を伏せて置くと、読書が始まります。オフにすると、「読み始める」ボタンだけで始めます。 | Placing iPhone face down on the bookmark screen starts a session. When this is off, use the Start Reading button. | S-10。足した |
| `settings.flipToStart.unavailable` | この端末では、伏せて始める道を使えません。 | Starting face down isn't available on this device. | S-10。足した |
| `settings.section.lockScreen` | ロック画面 | Lock Screen | S-10。足した |
| `settings.hideOnWidgets` | 一行と書名を隠す | Hide Line and Title | S-10。PRD の識別子の文 |
| `settings.hideOnWidgets.footer` | ロック画面とホーム画面のウィジェットに、一行と書名を出さず、「しおり」とページだけを出します。アプリの中には出ます。 | Widgets on the Lock Screen and Home Screen show only “Bookmark” and the page. The line and title still appear in the app. | S-10。足した（(5) を残すときは Live Activity も言う） |
| `settings.section.info` | 情報 | About | S-10。足した |
| `settings.privacyPolicy` | プライバシーポリシー | Privacy Policy | S-10。PRD の識別子の文 |
| `settings.dataSources.header` | 書誌の出どころ | Book Data | S-10。足した |
| `settings.dataSources` | 書誌（書名、著者、出版社など）は、国立国会図書館サーチ（NDLサーチ）の API を用いて取得しています。書誌のデータは、NDLサーチの API から取得した「国立国会図書館蔵書」と「国立国会図書館新着書誌情報」（データ提供機関：国立国会図書館）に由来します。著者名などは、このアプリで表示用に整えています。ライセンスは、クリエイティブ・コモンズ 表示 4.0 国際 パブリック・ライセンス（CC BY 4.0）です。 | Book details (title, author, publisher, and so on) are retrieved using the NDL Search API (National Diet Library Search). The bibliographic data derives from “National Diet Library Catalog” (国立国会図書館蔵書) and “NDL newly acquired bibliographic data” (国立国会図書館新着書誌情報), provided by the National Diet Library, Japan (国立国会図書館), via the NDL Search API. Author names and other fields are formatted for display by this app. License: Creative Commons Attribution 4.0 International (CC BY 4.0). | S-10 の情報の節（`settings.dataSources.header` の下。.footnote、`color.text.secondary`、行数の上限なし）。PRD。docs/adr/0004-bibliographic-lookup.md の「クレジットの文」をそのまま写した（designer は文を作らない。G1-5 は決着）。名前を変えるときは ADR 0004 を先に直す |
| `settings.dataSources.license` | ライセンス（CC BY 4.0） | License (CC BY 4.0) | S-10 の Link。PRD の識別子の文。開く先は、日本語の構成で https://creativecommons.org/licenses/by/4.0/deed.ja 、英語の構成で https://creativecommons.org/licenses/by/4.0/ （ADR 0004。どちらも AC-93 の始まりを満たす） |
| `duration.minutes` | %lld分 | %lld min | 60分未満の時間。足した |
| `duration.hoursMinutes` | %1$lld時間%2$lld分 | %1$lld hr %2$lld min | 60分以上（分が0なら `duration.hours`）。足した |
| `duration.hours` | %lld時間 | %lld hr | 足した |

### 許可を求める理由の文と、求める時
- 求める許可はカメラだけ（PRD 9）。求めるのは、S-8 で「バーコードを続けて読む」を初めて押したとき（許可が未決定のとき）だけ。前に説明の画面を置かず、システムの確認をすぐ出す（R-27）。最初の起動では求めない（AC-1）。
- NSCameraUsageDescription（InfoPlist の String Catalog）
  - 芯（撮る道なし）：日本語「本の裏のバーコードを読み取って本を加えるために、カメラを使います。写真は保存しません。」、英語「Yomuma uses the camera to scan the barcode on the back of a book so you can add it. No photos are saved.」
  - 選択肢 (6) を残すとき：日本語「本の裏のバーコードと、止めたページの一行を読み取るために、カメラを使います。写真は保存しません。」、英語「Yomuma uses the camera to scan book barcodes and to read the line on the page where you stopped. No photos are saved.」
- 断られたとき：S-8 に `camera.denied` と「設定を開く」（UIApplication.openSettingsURLString）。書名で探す、手で入れるは押せる（AC-12）。
- 伏せる道は許可を使わない（PRD 12）。Q-A で許可のダイアログが出ると分かったら、PRD のやり直しに従う（結果待ち）。

## 8. 見た目
- 使うトークン（値と使い方の全部は design/001-reading-session/tokens.md）
  - 色：`color.background.primary`（systemBackground）、`color.background.grouped`（systemGroupedBackground）、`color.background.groupedRow`（secondarySystemGroupedBackground）、`color.text.primary`（label）、`color.text.secondary`（独自）、`color.action.primary.background` と `color.action.primary.label`（独自）、`color.action.tint`（独自。AccentColor）、`color.state.error`（systemRed。エラーの記号だけ）、`color.action.destructive`（systemRed。消す操作の記号 trash だけ）、`color.state.on`（systemGreen。Toggle の既定）、`color.separator`（separator。奥付の罫線）。
  - 文字：`type.book.line`（ヒラギノ明朝 ProN W3。28pt を .title に合わせて Dynamic Type で拡大縮小）、`type.book.line.widget`（ヒラギノ明朝 ProN W6。固定。W-1 は 17pt、W-2 は 20pt から下げる）、ほかはシステムの text style（.largeTitle、.title、.title2、.headline、.body、.subheadline、.footnote、.caption2）。Ultralight、Thin、Light は使わない。
  - 余白：`space.4`、`space.8`、`space.12`、`space.16`、`space.24`、`space.32` だけ。画面の左右 16、まとまりの間 24、書名と一行の間 32、並んだボタンの間 12、下端の主操作の下 16（safe area の内側）、W-1 の内側 0 と W-2 の内側 16（どちらもシステムの既定の余白を切り（contentMarginsDisabled）、自分で付ける。アプリの中の描画（H22、S-5）と組みの計算をそろえるため。R-18）、W-1 のページの帯と列の間 4、W-2 の列の場所とページの行の間 4。縦書きの列の間は字の大きさの 0.25 倍（`type.book.line.columnGap`。余白のトークンでなく文字の組みの値）。
- 画面ごとの文字の段（B-4。3段を目安に4段まで）
  - S-1：一行（`type.book.line`）、書名（.headline）、著者・ページ・2つの .bordered のボタンの文字（.subheadline）、伏せる案内（.footnote）の4段。主操作の文字は .headline（書名と同じ段）。
  - S-2：書名（.title2 Bold）、始めた時刻（.body）、数え続ける1行（.subheadline）の3段。ボタンの文字は .headline。
  - S-3：問い（.title2 Bold）、書名と説明（.subheadline / .footnote）、ボタン（.headline）の3段。
  - S-4：まとめ（.title、数字は monospacedDigit）、書名（.headline）、「記録しました。」（.subheadline）の3段。
  - S-6、S-7、S-7a、S-7b、S-8、S-8a〜S-8c、S-10：List と Form の既定（行 .body、補足 .subheadline、節の見出しと説明はシステムの既定の大きさ）。節の見出しと説明の色は `color.text.secondary` を当てる（システムの既定の secondaryLabel は 4.5:1 に届かないため。9）。奥付は名前 .subheadline、値 .body。
  - S-9：見出し（.largeTitle。ナビゲーションの大きい題）、奥付（.subheadline / .body）、候補の書名（.headline）、理由と戻し方（.subheadline / .footnote）の4段。
  - W-1：一行（固定の明朝）とページ（.caption2 Semibold、12pt 固定）の2段。W-2：一行とページ（13pt 固定）の2段。
- 新しく足すトークン（意味の名前と、ライト、ダーク、コントラストを上げる設定の値。比は 9）
  - `color.text.secondary`：ライト #6C6C70、ダーク #98989F、コントラストを上げる ライト #48484A / ダーク #C7C7CC。
  - `color.action.primary.background`：ライト #1C1C1E、ダーク #F2F2F7、コントラストを上げる ライト #000000 / ダーク #FFFFFF。
  - `color.action.primary.label`：ライト #FFFFFF、ダーク #000000、コントラストを上げる ライト #FFFFFF / ダーク #000000。
  - `color.action.tint`：`color.action.primary.background` と同じ値（.bordered の文字と塗り、Link の文字、チェックの記号、ツールバーの記号）。枠のない文字のボタンには使わない（押せることは形で見せる。3 の下の決まり）。Toggle には当てない（決定 48）。
  - `color.action.destructive`：systemRed。消す操作の記号 trash だけ（決定 58）。
  - `type.book.line.columnGap`：縦書きの列の間。字の大きさの 0.25 倍（決定 6）。
  - 主操作の .borderedProminent には tint と foregroundStyle を必ず付ける（付けないとダークで文字が地と同じ白になる。tech-lead r1 の B の S-1 の行）。
- 使う SF Symbols の名前（文字と同じ太さと大きさ。塗りの記号は、検索欄の消すボタンのほかは使わない。アプリのアイコンとロゴには使わない）
  - books.vertical（本棚、今の本なしの空）、gearshape（設定）、plus（本を加える）、barcode.viewfinder（バーコードを続けて読む）、magnifyingglass（書名で探す、検索欄）、square.and.pencil（手で入れる）、book.closed（本0冊の空）、exclamationmark.triangle（読み込めない）、exclamationmark.circle（エラーの知らせと欄の誤り）、info.circle（知らせ）、wifi.slash（通信なし）、camera（カメラの許可がない）、checkmark（選んだ行）、trash（この本を消す、この記録を消す。記号だけ赤）、arrow.up.forward（外へ開くリンクの行の末尾）、xmark.circle.fill（検索欄の消すボタン。システムの検索欄と同じ形にそろえるため、塗りの記号はここだけ）。シートの閉じる、取り消す、保存はシステムが描く記号（Button の role .close、.cancel、.confirm）。
- 性格語が表れている場所（語ごとに画面と要素）
  - 静か：S-2 は押せるものが「終える」1つで、動く数字がない。S-4 に祝う言葉、絵、触覚、音がない。S-1 に数のバッジ、連続日数、通知がない。触覚は2種類だけ。色は白、黒、灰で、意味のあるとき（エラーの記号、Toggle）だけ色を使う。
  - 確か：S-2「伏せても、ロックしても、ほかのアプリを使っても数え続けます。」、S-3a「前のページは43です。空のまま保存すると、43のまま残ります。」、S-4「記録しました。」と「p.43 → p.61」、S-3「しおりは前のまま残ります。」、S-3b「保存すると一行は消え…」、奥付はデータのある行だけ、次の1冊の理由は事実1行、S-8「ISBN か書名を国立国会図書館サーチに送って探します。」、`common.save.error`「変更は反映されていません。」、本を消す確認に記録の件数。
  - まっすぐ：どの画面も主操作は1つで、ボタンは動詞（読み始める、終える、この本を読む）。S-1 から1タップで読書（AC-42）。初めての案内の画面と、許可の前の説明の画面を挟まない。
  - 急かさない：S-1 に読まなかった晩の数、目標、連続日数を出さない。次の1冊は S-9 にだけ出し、3つのボタンを同じ重みにする。置き方の案内は1回だけ。知らせを時間で消さない。「読み終えた」を押し間違えても戻せる（S-9 の1行）。
  - 紙の側：明朝の縦書きの一行（W-1、W-2、S-1、S-5）。ページを「p.61」と書き、ウィジェットではノンブルの位置（左下）に置く。「しおりを挟む」「しおり」（S-3、隠す設定の W-1）。奥付の型（S-7、S-9）。伏せて置いて始める（S-1）。
- ターゲット（仮説）が表れている場所（調査の 2）
  - 夜、手がスマホに伸びた1〜2秒：W-1 に操作0回で自分の本の一行（D-1）。押せば S-1 で1タップ。
  - 暗い部屋：ダークの値を先に決めた（tokens.md）。S-2 と S-4 の地は黒にする。白いのは主操作のボタン1つ（361×50pt。画面の約5%）だけ。灰に抑える案は比べて採らなかった（決定 47）。暗い StandBy はシステムの赤。
  - 片手、伏せられない人：「読み始める」は下端の親指の届く所にあり、伏せる道と同じ重みの道。伏せる道は S-10 で切れる（R-29）。
  - 老眼、大きい文字：S-1 の一行は Dynamic Type で大きくなり、AX のサイズでは横書き（9）。
  - SNS に疲れた人：公開の面、数、勧めを置かない（R-11）。
- 差をつける点が表れている場所
  - D-1 手に取った瞬間の「続き」：W-1（主）、W-2（StandBy で大きく）、S-1 の一行、S-5 の見本（自分の一行を実際の大きさで）。差は見た目でなく中身（自分が昨夜止めた一行）なので、ウィジェットのギャラリーの見本も利用者の一行にする（決定 13）。
  - D-2 読み終えた夜だけの「奥付と次の1冊」：S-9（奥付 → 次の1冊、祝う演出なし、毎晩の道に出さない。AC-86）。S-7 の奥付も同じ型。
- 参考にした HIG のページ（URL）
  - 調査で読んだもの：https://developer.apple.com/design/human-interface-guidelines/widgets 、https://developer.apple.com/design/human-interface-guidelines/live-activities 、https://developer.apple.com/design/human-interface-guidelines/controls 、https://developer.apple.com/design/human-interface-guidelines/design-principles 、https://developer.apple.com/design/human-interface-guidelines/accessibility 、https://developer.apple.com/design/human-interface-guidelines/typography 、https://developer.apple.com/design/human-interface-guidelines/materials 、https://developer.apple.com/design/human-interface-guidelines/color 、https://developer.apple.com/design/human-interface-guidelines/dark-mode 、https://developer.apple.com/design/human-interface-guidelines/writing 、https://developer.apple.com/design/human-interface-guidelines/privacy 、https://developer.apple.com/design/human-interface-guidelines/onboarding 、https://developer.apple.com/design/human-interface-guidelines/playing-haptics
  - この仕様のために 2026-10-19 に開いたもの（tutorials/data の JSON。どれも HTTP 200）：https://developer.apple.com/design/human-interface-guidelines/buttons （「use a button that has a prominent visual style for the most likely action in a view」「a hit region of at least 44x44 pt」）、https://developer.apple.com/design/human-interface-guidelines/sheets （「The Cancel (or Close) button dismisses a sheet without saving any changes.」）、https://developer.apple.com/design/human-interface-guidelines/alerts （「Avoid displaying alerts for common, undoable actions, even when they're destructive.」「Use alerts sparingly.」）、https://developer.apple.com/design/human-interface-guidelines/action-sheets （SwiftUI では confirmation dialog）、https://developer.apple.com/design/human-interface-guidelines/toolbars （「Prefer the standard symbols for each, and don't use a text label that says Back or Close.」）、https://developer.apple.com/design/human-interface-guidelines/lists-and-tables 、https://developer.apple.com/design/human-interface-guidelines/text-fields （「show the appropriate keyboard type」）、https://developer.apple.com/design/human-interface-guidelines/search-fields 、https://developer.apple.com/design/human-interface-guidelines/loading （「Show something as soon as possible.」）、https://developer.apple.com/design/human-interface-guidelines/toggles （「The default green color tends to work well in most cases」）

## 9. アクセシビリティ
- いちばん大きい文字（AX5）で並びを変える場所
  - S-1：一行を横書きにする（accessibility1 以上。縦に入らないときも）。「どこまで読んだかを入れる」「読み終えた」の横並びを縦並びにする（どちらも幅いっぱいの .bordered）。書名と著者の行数の上限を外す。「読み始める」は下端に固定したまま幅いっぱいで、文字が2行になってよい。上の内容（書名、著者、一行、ページ、2つのボタン）だけを縦に送る。伏せる案内は、AX のサイズでは送る側のいちばん下に移す（固定する所を主操作だけにして、送る所を広く残すため）。ツールバーの記号は、長押しでシステムの大きな表示（Large Content Viewer）を出す。
  - S-2、S-3、S-4：もともと縦並び。文字は折り返し、切らない。S-4 の「p.43 → p.61」は2行に分かれてよい（1つの要素のまま）。S-2 の「終える」と S-4 の「閉じる」は下端に固定し、上の文だけを送る。
  - S-6、S-8、S-8b：行の書名と補足は縦に並ぶ（List の既定）。行数の上限を外す。
  - S-7、S-9 の奥付：名前と値の2列をやめ、名前の下に値を置く。
  - S-9：候補の行の「この本を読む」を、書名と理由の下に回す（幅いっぱい）。
  - S-8a：カメラの領域を画面の高さの3分の1にし、一覧に場所を回す。加えるボタンは下端に固定する。
  - S-8b：「この本を加える」は下端に固定する。結果の下の「手で入れる」は文の下に回す。
  - S-3a、S-3b、S-7a、S-7b、S-8c、S-10：Form の既定（ラベルと欄、説明は折り返す）。
  - W-1、W-2：大きくしない（固定。決定 8）。大きい文字の人は、押して開いた S-1 で全文を読む（PRD 12）。
- 色だけで区別していないか
  - 選んだ行（S-8b）：チェックの記号と、読み上げの状態「選択中」。
  - エラー：記号の形（exclamationmark.circle）と文で伝える。赤は記号の色だけで、文は本文の色。
  - Toggle：つまみの位置と、読み上げのオン・オフ。
  - 押せないボタン（S-8a の0冊のとき、使えない端末の行）：システムの押せない見た目と、読み上げの「利用できません」。説明の文も添える。
  - 押せる文字と押せない文字：押せる文字は、塗り（.borderedProminent、.bordered）、記号、「>」のどれかの形を持つ。押せない文字（著者、ページ、説明、書誌の出どころ）はどれも持たない（決定 4、47）。.bordered の塗りと地の比は 3:1 に届かない（9）が、ボタンの文字が動詞で押せる物だと分かるので、塗りの比は求めない（WCAG 1.4.11 の理解文書：「the button's text is sufficient to indicate the presence of the control.」https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html 。2026-10-20 に開いた）。ダークの黒い地では、塗りと地の比が 1.4:1 に届かない（下の表の参考の行）。G3 でダークの S-1 のスクリーンショットを見るときに、「どこまで読んだかを入れる」「読み終えた」が押せる形に見えるかを、第一印象で確かめる（design-reviewer r2 の参考6）。見えにくければ G3 の指摘として直す。
  - 消す操作：文字（「この本を消す」）と記号 trash の形で伝える。赤は記号だけ。
- 動きを減らす設定、透明度を下げる設定のとき
  - 独自の動きはない。画面の出入りはシステムの押し出しとシートで、動きを減らす設定ではシステムが溶ける切り替えにする。伏せて始まったことは、触覚、読み上げ、起こしたときの S-2 の3つで伝え、動きに頼らない（PRD 12）。
  - ツールバーとシートの Liquid Glass は、透明度を下げる設定でシステムが不透明にする。内容の層（一行、奥付、一覧）は素材を使わないので変わらない。
  - 触覚は、iPhone の設定でシステムの触覚を切ると出ない（R-28「Make haptics optional.」）。触覚だけで伝えることはない。
- VoiceOver の読み上げ順
  - W-1、W-2：1つのまとまり（書名、ページ、一行）。一行があるときは書名が見えないが、ラベルは書名から始める（決定 60 の「見える文字から始める」の例外）。AC-99 はラベルに書名を入れることを求め（順は決めていない）、一行だけではどの本の続きかが分からないので、本 → 場所 → 一行の順にする。見える一行とページの値はラベルにすべて入るので、WCAG 2.5.3 の「見える文字を含む」は満たす（design-reviewer r2 の参考3）。一行がない形（書名と「p.120」）と隠す形（「しおり、61ページ」）は、見える文字から始まる（書式は `widget.spoken.noLine`）。書名のない今の本（決定 66）は、書名の所を `widget.currentBookAsTitle`「今の本」にして、同じ順と同じ書式で読む（「今の本、61ページ。下人は、雨やみを待っていた。」。一行がないときは見える「今の本」と「p.120」から始まる）。どの本の続きかは「今の本」で伝わり、ISBN は写しにないので読まない。
  - S-1：本棚、設定（ツールバー）→（知らせ）→ 書名 → 著者 → 一行 → ページ → どこまで読んだかを入れる → 読み終えた → 読み始める → 伏せる案内（AX のサイズでは、読み終えた → 伏せる案内 → 読み始める）。空の状態は、題 → 文 → ボタン。
  - S-2：書名 → 始めた時刻 → 数え続ける1行 →（知らせ）→ 終える。
  - S-3：問い → 書名 → 主の道 → 2つ目の道 → あとで挟む（ヒント「しおりは前のまま残ります。」）→（シートのとき）閉じる。
  - S-3a：一行の欄 → その説明 →（誤り）→ ページの欄 → その説明 →（誤り）→ 保存。S-3b も同じ並び。
  - S-4：書名 → まとめ → 記録しました →（知らせ）→ 閉じる。
  - S-5：見出し → 説明 → 見本 → 閉じる。
  - S-6：今の本 → 積読 → 読み終えた（区分の見出し、行の順）→ 本を加える（ツールバー）。
  - S-7：奥付（行ごと）→（書誌を待つ文）→ 記録の見出し（何晩、合計）→ 記録の行 → この本を消す → この本を読む → 直す（ツールバー）。
  - S-8：バーコードを続けて読む →（許可の文、設定を開く）→ 書名で探す → 手で入れる → 送るものの説明 → 閉じる。
  - S-8a：カメラ（説明つき）→（知らせ）→ 読めた行 → n冊を本棚に加える → 閉じる（読んだ本が1冊以上の間は戻るボタンがない。決定 26）。読めた本が増えたら「（書名）を読みました」を1回読み上げる。
  - S-8b：検索欄 →（字があるとき）入力を消す → 結果の行 → 結果の下の文と手で入れる →（知らせ）→ この本を加える。
  - S-9：見出し → 奥付 → 次の1冊の見出しと説明 → 候補ごとに（書名、著者、理由のまとまり → この本を読む）→ 戻し方 → 閉じる。
  - S-10：読み始めの見出し → 伏せて始める → 説明 → ロック画面の見出し → 一行と書名を隠す → 説明 → 情報の見出し → プライバシーポリシー（リンク）→ 書誌の出どころ → ライセンス（リンク）。外へ開く記号は読まない。
  - 読み上げを送る時：伏せて始まったとき（`session.flipStarted.announcement` を1回）、知らせと誤りが出たとき（1回ずつ）。
- 英語が長くなったとき（疑似言語 Double-Length で確かめる画面）
  - S-1（主操作、文字のボタン2つ、伏せる案内）、S-3（3つの道のボタン）、S-4、S-8（3つの行と説明）、S-8a（加えるボタン。例「Add 12 Books to Bookshelf」）、S-9（理由の1行とボタン）、S-10（Toggle の文と説明）、W-1 と W-2（`widget.empty` と `widget.unavailable`。書名のない今の本の `widget.currentBookAsTitle` は書名の所の決まり（2行まで）で見る。決定 66）。
  - ボタンの文字は折り返して切らない。横並びは入らなければ縦並びにする（ViewThatFits）。ウィジェットの案内の文は、入らなければ字を 0.8 倍まで小さくし、それでも入らなければ末尾を「…」にする（一行の字の決まりとは別。一行は縮め方の決まりで出す）。
- 押せる範囲：どの押せる要素も 44×44 pt 以上。S-1 の2つの .bordered（`bookmark.setMark`、`bookmark.finish`）と、.bordered の小さいボタン（`mark.later`、`notice.close`、結果の下の `register.manual`）は高さを 44pt 以上にする。検索欄の消すボタン `search.clear` は、記号の外まで 44×44pt を押せる範囲にする。ツールバーのボタンと List の行はシステムの既定（44pt 以上）。ウィジェットは全体が押せる範囲。

コントラスト（独自の色を使う組ごと。システム色だけの組は「システム色」と書いた。値は WCAG の相対輝度の式で計算した。計算のスクリプトと出力は報告に書く）
基準は、17pt 以下の文字が 4.5:1 以上、18pt 以上か太字の文字とアイコンや操作部品の枠が 3:1 以上。

| 前景（文字、アイコン、枠）と背景の組 | ライト | ダーク | コントラストを上げる |
|---|---|---|---|
| `color.text.primary`（label）と、どの背景も | システム色 | システム色 | システム色 |
| `color.text.secondary` と `color.background.primary`（#FFFFFF / #000000） | 5.23:1（#6C6C70） | 7.33:1（#98989F） | ライト 9.12:1（#48484A）、ダーク 12.47:1（#C7C7CC） |
| `color.text.secondary` と Form と List の地（ライト #F2F2F7、ダーク #1C1C1E） | 4.69:1 | 5.94:1 | ライト 7.68:1（地 #EBEBF0）、ダーク 9.20:1（地 #242426）。地はどちらも iOS 27.0 の実測（tech-lead r1。iOS 26 は G1-3） |
| `color.text.secondary` とシートの中の行の地（ダーク #2C2C2E） | ー（ライトの行の地は #FFFFFF で 5.23:1） | 4.86:1 | ダーク 7.16:1（地 #363638。iOS 27.0 の実測） |
| `color.text.secondary` とシートの中の入れ子の地（ダーク #3A3A3C） | ー | 3.96:1 で届かないので、この地には置かない（tokens.md） | ー |
| `color.text.secondary` の記号（arrow.up.forward、検索欄の magnifyingglass と xmark.circle.fill）と行の地（記号なので 3:1） | 5.23:1（#FFFFFF） | 5.94:1（#1C1C1E）、4.86:1（シートの行 #2C2C2E） | ライト 9.12:1（#FFFFFF）、ダーク 9.20:1（#242426）、7.16:1（#363638） |
| `color.action.primary.label` と `color.action.primary.background`（主操作の文字） | 17.01:1 | 18.82:1 | 21.00:1（ライト、ダークとも） |
| `color.action.primary.background` と画面の地（主操作の形） | 17.01:1 | 18.82:1 | 21.00:1（ライト、ダークとも） |
| `color.action.tint`（Link の文字）と行の地 | 17.01:1（#FFFFFF） | 15.25:1（#1C1C1E）、12.49:1（シートの行 #2C2C2E） | ライト 21.00:1（#000000 と #FFFFFF）。ダーク 15.49:1（#FFFFFF と #242426）、12.06:1（#363638） |
| .bordered の文字と塗り（塗りは tint の15%と想定［推測］。かっこは20%） | 白の地 12.52:1（11.21:1）、群の地 11.28:1（10.12:1） | 黒の地 13.85:1（11.75:1）、行の地 #1C1C1E 9.84:1（8.33:1）、シートの行 #2C2C2E 7.96:1（6.81:1） | ライト 14.84:1（13.08:1）、ダーク 9.59:1（8.07:1。行の地 #242426） |
| 参考：.bordered の塗りと地（押せることは文字で分かるので、比は求めない。WCAG 1.4.11） | 1.36:1（15%）、1.52:1（20%） | 1.36〜1.57:1（15%）、1.60〜1.83:1（20%） | 1.41〜1.62:1（15%）、1.61〜1.92:1（20%） |
| `color.state.error`（systemRed）の記号と地（記号なので 3:1） | 3.57:1（#FF383C と #FFFFFF）、3.20:1（#F2F2F7） | 6.12:1（#FF4245 と #000000）、4.96:1（#1C1C1E）、4.06:1（#2C2C2E） | ライト 4.56:1（#E9152D と #FFFFFF）、3.83:1（#EBEBF0）。ダーク 7.15:1（#FF6165 と #000000）、5.28:1（#242426）、4.11:1（#363638） |
| `color.action.destructive`（systemRed）の記号 trash と行の地（S-7 は List の行、S-7b はシートの行。記号なので 3:1） | 3.57:1（#FFFFFF） | S-7 4.96:1（#1C1C1E）、S-7b 4.06:1（#2C2C2E） | ライト 4.56:1（#FFFFFF）。ダーク S-7 5.28:1（#242426）、S-7b 4.11:1（#363638） |
| 消すボタンの文字（`color.text.primary`。label）と行の地 | システム色 | システム色 | システム色 |
| ウィジェットの字（ロック画面、暗い StandBy） | システム色（vibrant でシステムが描く。G4-1 で見る） | システム色 | システム色 |
| 参考：システムの secondaryLabel（使わない理由。節の見出しと説明にも当てない） | 3.44:1（#FFFFFF の上。#F2F2F7 の上は 3.30:1）で 4.5:1 に届かない | 6.36:1 | ー |
| 参考：systemRed を文字に使うと | 3.57:1（#FF383C と #FFFFFF）で 4.5:1 に届かないので、文字には使わない（消すボタンの文字も本文の色。決定 58） | 4.06:1（S-7b のシートの行）で届かない | ライトの 4.56:1 は届くが、ふだんの設定で届かないので使わない |
| 参考：プレースホルダ（システムの placeholderText） | 1.73:1 | 2.48:1（#1C1C1E）、2.41:1（#2C2C2E） | ー。4.5:1 に届かないので、プレースホルダには、なくても困らない手がかりだけを書く（決定 18） |
| 参考：ダークの主操作を灰 #AEAEB2 に抑える案（採らない。決定 47） | ー | 黒い文字と 9.50:1、画面の地 #000000 と 9.50:1 | ー |

ウィジェットの組みが入るかの計算（ADR 0003 の式。字は25字。帯 B は実測の 43pt（「p.9999」を 12pt Semibold、等幅の数字で描いた幅）、帯と列の間 g は 4pt。W-2 は内側 i が 16pt、ページの行 R が 20pt（13pt の行の高さ 15.67pt を切り上げた 16pt と `space.4`）。列の数は25÷1列の字数の切り上げで、追い出しで列が増えた形も見た。値は入る最大の字の大きさと、横の余り。計算のスクリプトの出力は報告に書いた）
- 列の間 0.25 倍の W-1：172×76 は 15pt（余り 35.0pt）、列が1つ増えても 15pt（余り 16.25pt）、2つ増えると 14pt（余り 6.0pt）。153×68 は 13pt（余り 28.0pt）、列が1つ増えても 13pt（余り 11.75pt）、2つ増えると 13pt で入らず、追い出しをせずに組む（ADR 0003 の手順 7）。ADR 0003 の値と同じ。前の版で推測した帯 38〜40pt より広いので余りは小さくなったが、字の大きさは変わらない。
- 列の間 0.25 倍の W-2：170pt は 20pt（余り 18.0pt）、列が1つ増えると 19pt（余り 0.25pt）。148pt は 19pt（余り 2.0pt）、列が1つ増えると 16pt（余り 0pt）。ページの行の間を `space.8`（R＝24pt）にすると 148pt は 18pt に下がるので、`space.4` にした（決定 8）。
- 列の間 0.5 倍（比べた案）：153×68 で列が1つ増えた形は 13pt で入らない（110.5pt＞106pt）。172×76 も列が1つ増えると 14pt に下がる。だから 0.25 倍のままにする（tokens.md）。
- S-1（決定 64）：393×852pt は幅 361pt、高さ 340pt で、1列の字数は 25pt で13字、28pt で12字、34pt（accessibility1 の手前の最大）で10字。60字はどれも6列以内で、幅に入る列は 34pt でも8列まで。375×667pt は高さ 266pt で、34pt は1列7字の9列が8列までに入らないので横書き。

## 10. 決まっていないこと
- Takuma が決めた（2026-10-19。docs/approvals/001-reading-session-G1-decisions.md）：見た目の方向（案A）と、S-1 の主操作のほかの2つのボタンを画面に出しておくこと。この仕様の形のまま（決定 1、4。0 の「決まったことと、結果待ち」）。
- 結果待ち：Q-A と実機の確かめ（`bookmark.flipHint` の文）、1b・2b・1c（S-3 の主の道）、3b（S-9 の次の1冊。差分は 5）、3d（置き方の案内を強めるか）、G4-1（ロック画面の vibrant の太さと色）。
- tech-lead の答え（tech-lead r1 の C）を入れたものと、残り
  - `settings.dataSources` の文字列：ADR 0004 の「クレジットの文」に差し替えた（7。G1-5 は決着）。ライセンスの Link の開く先は、言語の構成ごとに ADR 0004 のとおり。
  - S-8b の検索欄：.searchable の欄には識別子を付けられないので、TextField のまま（問い2。決着）。
  - 縦書きの組み：ADR 0003 で決まった（1字ずつ 1em の升目、列は右から左、Text を置いて描く。小さい仮名と回す字は、フォントの縦書き用の字形の位置へ字ごとにずらす。帯は実測 43pt）。2026-10-20 の直しで、置き換えの表に 7-3 の字を写し（tokens.md）、禁則の字（決定 62）、回す記号（決定 63）、W-2 の列とページの間（決定 8）、S-1 の縦書きの場所（決定 64）を決めた。
  - W-1 と W-2 の余白：既定の余白を切り、W-1 は 0、W-2 は 16pt（提案5 のとおり。tokens.md）。
  - S-6 の「読み終えた」の並び：読み終えた日時を持つ（問い4）。H2 で入れ H13 で読む形は、つなぎ口の契約に tech-lead が足す。
  - コントラストを上げる設定の地：iOS 27.0 の実測に替えた（問い5。9）。systemRed の値も iOS 27.0 の実測に替えた（提案1）。iOS 26 の値は G1-3 で測る。
  - S-8b の件数：ADR 0004 で cnt=200 を1回（ページ送りなし）に決まった。最大で約200行。並びは ADR 0004 の並べ直しのままで、決定 27 と 5 に書いた。
  - Button の role .close と .confirm：iOS 26.0 から使える（問い7。決着）。S-8a の閉じるは、読んだ本が1冊以上なら .cancel（提案4。決定 26）。
- pdm に伝えること
  - 英語の表示名（この仕様は仮に Yomuma）。
  - PRD 17 の審査メモの言葉（「手で入れる」で一行を入れる）を、この仕様の文（「どこまで読んだかを入れる」→「一行を入れる」）に合わせる（G5 の掲載文と審査メモで）。
  - S-3a でページの欄を空のまま保存すると、ページは変えない（前の版の「空にする」を、r1 の指摘6 で、PRD にない決まりを足さない形に替えた。前のページは欄の下に消えない文で出すので、新しい一行と前のページの組み合わせになることは保存の前に分かる）。この決まりを AC にするかは pdm と verifier が決める（AC にしなくても PRD の AC とはぶつからない。AC-67 の撮る道でも前のページが残る）。
  - G1-13（ラテン文字の著者が「Fox Susan」と出る）：designer の推奨は、このままにする（表示の決まりを変えると AC-92 と取り出しの決まりを直すことになる）。英語の利用者に向けて直すなら、後の版で pdm が決まりを直す。
  - 書名で探す結果の並べ直し（決定 27）を AC にするかは、pdm と verifier が決める（7-2 の未解決2。画面は ADR 0004 の並びをそのまま出すだけで、AC-4 の期待とはぶつからない）。
- verifier に伝えること
  - 6 の「足した」識別子。知らせの帯は `notice` で、文の要素の識別子は文言キーと同じ名前。r1 の直しで `search.clear` と `mark.page.previous` を足し、文言キー `mark.page.placeholder.previous` をやめた。
  - S-8a で読んだ本が1冊以上の間は、戻るボタンがなく、シートを払って閉じられない。出る道は `scan.cancel` → `scan.discard.confirmButton` だけ。
  - S-3a でページの欄を空のまま保存すると、ページは変えない（上の pdm の項）。
  - `bookmark.page` と `result.summary` は、表示（「p.61」）と読み上げのラベル（「61ページ」）が違う。テストは値で比べる。
  - S-1 に知らせかシートが出ている間は、伏せる道を止め、`bookmark.flipHint` を出さない（AC-47 の「`session.tooShort` の知らせ」の場面）。AC-50 は知らせのない S-1 で見る。
  - 選択肢に申し送られた G1-7（古くなった Live Activity）、G1-8（有料の見た目の id と見本）、G1-15（App Intents の名前と言い方）は、回す所が決まってからの選択肢の仕様で決める。
  - 行頭の禁則の字を JLREQ の類に広げた（決定 62、tokens.md）。AC-28 の L を出す一行（かなだけの25字）と (4)〜(6) の一行では、L＋1 字目のほかに、広げた字（小さい仮名、「々」「・」「！」「？」など）を列の頭に来うる所へ置かない（置くと追い出しが増え、字の大きさか L が変わる）。W-2 の 148pt では、送りがあると 19pt から 16pt に下がる。
  - アプリが動いているときに入口の URL が来たときの画面は決定 65（AC にはない。AC-40 のテストはプロセスのない起動のまま）。
  - 書名のない今の本のウィジェット（決定 66）：H22 の `texts` の `widget.title` は「今の本」（一行がないとき）。読み上げのラベルは 6 の例のとおり。状態は normal、noLine、noLineNoPage のまま。
  - G3 で、ダークの S-1 のスクリーンショットを残す（.bordered の2つのボタンが押せる形に見えるかを design-reviewer が見る。9）。
- tech-lead に伝えること（2026-10-20 の直しで決めたことの写し先）
  - ADR 0003：置き換えの表（7-3 の字に加えて、「：」「；」「－」「＝」「＜」「＞」「｛」「｝」「｜」「＿」を回し、「，」「．」をずらす。決定 63。ADR の「：」の行（そのまま立てる）は回すに替える）、行頭の禁則の字（決定 62）、W-2 の R＝20pt（16pt と `space.4`。決定 8）、S-1 の A_w と A_h（決定 64）。
  - contracts/entry-urls.md の 3 の「決まっていないこと」：決定 65。
  - contracts/hooks/h22-widget.schema.json の例の `widget.unavailable` の文（仮の文字）は、7 の文に替えられる。
  - 書名のない今の本のウィジェット（決定 66。tech-lead の G1 の直しの申し送りの 1〜3 の答え）：H22 の状態の enum は足さない（一行があれば normal、一行がなくページがあれば noLine、どちらもなければ noLineNoPage）。一行がないときは `texts` の `widget.title` に `widget.currentBookAsTitle` の文が入る。読み上げのラベルは書名の所を同じ文にする（6）。写し先：contracts/widget-snapshot.schema.json の description の [出し方] と [読み上げのラベル] の「未決」、contracts/test-hooks.md の H22 の「書名のない今の本」、設計メモ 5 の「見せ方」と 10 の申し送り。
- 調査に足りない所（この仕様では新しい R を作らなかった）
  - この仕様のために HIG の10ページを開き、原則の欄にだけ使った（8）。R にはしていない。
  - r1 の直しのために、2026-10-20 に WCAG 1.4.11 の理解文書（https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html 。9 の .bordered の塗り）と、JLREQ の §2.3.2（R-30 と同じ文書 https://www.w3.org/TR/jlreq/ 。tokens.md の半角の英数字）を開き、根拠の文に使った。R にはしていない。JLREQ の縦書きの行間の目安は、開いた範囲（先頭の約10万字）に見つからず、見ていない。
  - 2026-10-20 の 7 の申し送りの直しのために、Unicode の VerticalOrientation.txt（UAX #50 のデータ。Unicode 18.0.0。https://www.unicode.org/Public/UCD/latest/ucd/VerticalOrientation.txt 。HTTP 200）と、JLREQ の 3.1.7 行頭禁則（R-30 と同じ https://www.w3.org/TR/jlreq/ 。HTTP 200）を開き、決定 62、63 の根拠の文に使った。VerticalOrientation.txt は R にしていない（調査は変えない範囲のため）。
  - S-1 の主操作のほかのボタンを、競合が毎晩の画面にいくつ置いているかの数えは、調査にない（画面写真で見られた範囲だけ）。

## 確かめ（提出前に designer が印を付ける。design-reviewer はこれを信じずに確かめる）
芯の範囲で印を付けた。選択肢の画面は、回す所が決まってから別の仕様で確かめる。
- [x] 調査が先にあり、決定表のすべての行に R-n と原則がある（R-n は調査に実在する）（調査はコミット f8ed008。決定 66行（2026-10-20 に 62〜66 を足した）。R 番号の照合は報告に書く）
- [x] 全画面に、仕事、主操作1つ、使う標準部品がある（芯の 19 画面と部品 N。S-9 の主操作は候補ごとに同じ操作。3）
- [x] 全画面の7つの状態が埋まっている（該当しない所は「なし」と理由。理由のない「なし」は0。数えたコマンドは報告）
- [x] 押せる範囲が 44x44pt 以上。コントラストが基準を満たし、独自の色の組に数字が3通りある（コントラストを上げる設定の地と systemRed は iOS 27.0 の実測。iOS 26 の値は G1-3。.bordered の塗りの濃さは想定［推測］）
- [x] AX5 での並びと、VoiceOver の読み上げ順が書いてある
- [x] 性格語と差をつける点が、画面のどこに表れているか書いてある
- [x] 文言が日英そろい、テストで使う要素に accessibilityIdentifier がある（`settings.dataSources` は ADR 0004 の文に差し替えた。`widget.unavailable` は 7 にある。7 の申し送りの直しで識別子と文言キーは足していない。書名のない今の本の直しで、文言キー `widget.currentBookAsTitle` と `widget.spoken.noLine` を日英で足した。識別子は足していない）

