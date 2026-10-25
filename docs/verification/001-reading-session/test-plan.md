# テスト計画 001-reading-session：読書セッション（1冊の続きへ戻すしおりと静かな記録）

- 書いた役：verifier　日付：2026-10-26
- 実装のコードを見ずに書いた：はい
- 読んだファイル（PRD、design/、contracts/ だけ。読んだものを全部並べる）：
  - docs/prd/001-reading-session.md
  - docs/prd/001-reading-session-awards.md
  - design/001-reading-session.md
  - design/001-reading-session/screens.md
  - design/001-reading-session/tokens.md
  - contracts/test-hooks.md
  - contracts/entry-urls.md
  - contracts/dependencies.md
  - contracts/widget-snapshot.schema.json
  - contracts/hooks/hook-config.schema.json
  - contracts/hooks/h02-seed.schema.json
  - contracts/hooks/h13-store.schema.json
  - contracts/hooks/h17-state.schema.json
  - contracts/hooks/h20-ndl-stub.schema.json
  - contracts/hooks/h22-widget.schema.json
  - contracts/hooks/h29-outbound.schema.json

## 1. リスク
影響「大」の例：データが消える、数や金額が間違う、他人のデータが見える、起動で落ちる、主な流れが最後まで進まない。
影響「大」は、自動テスト、3章の行、6章の探索1本。影響「小」は代表のテスト1本。
| # | リスク | 影響（大中小） | 起きやすさ（大中小） | 関わる AC | 試す深さ |
|---|---|---|---|---|---|
| R1 | 読書時間の計測・晩の境界（4:00）・タイムゾーン変更・バックグラウンド・強制終了・終え忘れ上限（1440分）・端末時刻逆行で分数や晩の数が狂う、または記録が消える | 大 | 大 | AC-22, AC-24〜AC-26, AC-42, AC-43, AC-52, AC-53, AC-55〜AC-58, AC-61, AC-62, AC-85, AC-127〜AC-129, AC-136 | 自動テスト（境界値・状態遷移）、3章「バックグラウンドから復帰」「データがある」、6章の探索1本 |
| R2 | 端末を伏せて始める判定（1.0秒境界、しおり画面以外やシート表示中の誤作動、起こした後の再伏せ、設定オフ・非対応環境）で意図しない読書開始や二重開始が起きる | 大 | 大 | AC-44〜AC-51, AC-54, AC-144 | 自動テスト（境界値 0.9s/1.0s・デシジョンテーブル）、3章「データがある」、6章の探索1本 |
| R3 | しおり保存（ページ撮影 OCR・スクショ OCR・手入力・ページ/位置/％境界・保存失敗時の再試行）で一行や進み具合が壊れる、または撮影した画像ファイルが端末内に残る | 大 | 中 | AC-63〜AC-76, AC-94, AC-95, AC-113, AC-137, AC-138, AC-141, AC-142 | 自動テスト（同値分割・境界値・H27 画像残存0件検査）、3章「権限を断った」「容量不足、電話などの割り込み」、6章の探索1本 |
| R4 | ロック画面・StandBy ウィジェットおよび Live Activity で縦書き組版・禁則・26字以上の縮め方が崩れる、または「一行と書名を隠す」設定時にロック画面や Siri から書名・一行が漏れる | 大 | 中 | AC-27〜AC-41, AC-96〜AC-99, AC-120, AC-121, AC-123, AC-130, AC-143 | 自動テスト（境界値・デシジョンテーブル・ペアワイズ）、3章「大きい文字、ダークモード」「言語と地域（ja、en）」、6章の探索1本 |
| R5 | アプリ外からの App Intents（「読み始める」「終える」「どこまで読んだ？」「続きを読む」）とアプリ本体の状態・Live Activity 予約が競合し、二重開始や記録消失が起きる | 大 | 大 | AC-114〜AC-126, AC-131〜AC-136, AC-143, AC-144 | 自動テスト（状態遷移・デシジョンテーブル）、3章「オフライン、サーバーエラー」「バックグラウンドから復帰」、6章の探索1本 |
| R6 | 本・記録・しおり・設定の永続化と保存失敗（ディスク満杯・読込失敗・再起動）で既存データが破損・消失する、または外部へ意図しない HTTP 通信が発生する | 大 | 中 | AC-1, AC-6, AC-14〜AC-16, AC-59, AC-60, AC-89〜AC-91, AC-103, AC-139, AC-140 | 自動テスト（異常系注入 H7・再起動検証・H29 外部通信0件検証）、3章「初めて起動」「オフライン、サーバーエラー」「容量不足、電話などの割り込み」、6章の探索1本 |
| R7 | 端末内書誌 SQLite DB（Background Assets）の検索・未取得時のフォールバック・2段目 Cコード補完・NDL 著者名整形・受賞一覧照合で誤った書誌や受賞が入る | 中 | 中 | AC-2〜AC-12, AC-17〜AC-21, AC-92, AC-93, AC-112 | 自動テスト（同値分割・境界値・正規化ルール検証）、3章「オフライン、サーバーエラー」「権限を断った」 |
| R8 | 読了後の「次の1冊」「この本のあとに」の推薦順・端末内の重み付け（`chosen * 2 - skipped`）・共起テーブル（`count >= 10` かつ文学 NDC 9）の絞り込みが狂う、または人数が表示される | 中 | 中 | AC-77〜AC-84, AC-86, AC-87, AC-145〜AC-148 | 自動テスト（デシジョンテーブル・境界値 `count=9/10`）、3章「データがある」 |
| R9 | 買い切り課金「よむま＋」の購入・キャンセル・失敗・復元・決済不可・オフライン・返金時の見た目フォールバックが崩れる、または毎晩の道に課金案内が出る | 中 | 小 | AC-104〜AC-111 | 自動テスト（状態遷移・異常系注入 H30）、3章「オフライン、サーバーエラー」 |
| R10 | 本500冊・記録5,000件や端末内書誌 DB 検索・起動・ウィジェット生成・終える遷移で応答時間が基準（0.3秒 / 0.5秒 / 1.0秒）を超える | 小 | 中 | AC-55, AC-100〜AC-102, AC-114, AC-115, AC-149 | 代表の性能テスト（Perf 構成・5回平均計測 H10 / XCTApplicationLaunchMetric） |

## 2. 受け入れ条件とテストの対応
すべての AC に1つ以上のテストを付ける。名前に AC 番号を入れる（AC-3 なら test_AC3_<結果>）。AC のないテストは作らない。
技法：同値分割と境界値、状態遷移、デシジョンテーブル、ペアワイズ、代表の1例。
確かめる結果は具体的な値で書く（「保存される」ではなく「再起動の後も一覧に1件あり、題名が『買い物』」）。要素があるかだけにしない。
| AC | リスク | 技法 | 試す値（境界、遷移、ルールの列） | 種類（API / 画面） | ファイル::テストの名前 | 確かめる結果（具体的な値） |
|---|---|---|---|---|---|---|
| AC-1 | R6 | 代表の1例 | 端末初期化（H14）、本0冊、カメラ未決定（H26） | 画面 | FirstLaunchTests.swift::test_AC1_初回起動で空のしおり画面が出て許可ダイアログが出ない | `bookmark.empty.message` と `bookmark.addBook` が各1個、`bookmark.start` が0個、OS/アプリの alert が0個 |
| AC-2 | R7 | 状態遷移 | 本0冊→バーコード I1（9784101000015）読取→追加 | 画面 | RegistrationAcceptanceTests.swift::test_AC2_バーコードで最初の1冊を加えると今の本になる | `scan.row.9784101000015` に「こころ」「夏目漱石」「新潮社」「新潮文庫」が入り、追加後 H13 で本1冊・`status=current`、`bookmark.title` が「こころ」、H29 外部通信0件 |
| AC-3 | R7 | デシジョンテーブル | 既存 I1(`current`)、連続読取：I2(レーベル空)+Cコード `1920193006001`、I2重複、I1既存重複、I3、非図書 JAN `4901234567894` | 画面 | RegistrationAcceptanceTests.swift::test_AC3_バーコード連続読取で重複と非図書を除きCコードで文庫を補う | `scan.row` が I2・I3 の2行、I2 のレーベル候補に「文庫」、H17 `haptic=2`、`notice=scan.duplicate:1`、追加後 H13 で全3冊（I2・I3 が `tsundoku`、A が `current`） |
| AC-4 | R7 | 代表の1例 | 手入力「人間失格」→H20 候補3件（I4, I5, I6）から I5 を選択して保存 | 画面 | RegistrationAcceptanceTests.swift::test_AC4_手入力欄で端末内書誌DBの候補から選んで保存できる | `search.row` が上から I4・I5・I6 の3件（I6 はレーベルなし）、I5 選択保存後 H13 で本1冊・ISBN `9784040000053`・出版社「KADOKAWA」・レーベル「角川文庫」・出版年 `1989`・`status=current` |
| AC-5 | R7 | 同値分割と境界値 | H20 で「あいうえおかきくけこ」が0件→そのまま `manual.save` | 画面 | RegistrationAcceptanceTests.swift::test_AC5_書誌DBの候補が0件でもそのまま手入力で保存できる | 保存前に `search.row` が0個・`search.noResults` が1個・alert 0個、保存後 H13 で書名「あいうえおかきくけこ」・`status=current` の本1冊 |
| AC-6 | R6 | デシジョンテーブル | 通信なし（H8 `-uitest-offline`）＋H20 に I1 あり→バーコード I1 読取・追加 | 画面 | RegistrationAcceptanceTests.swift::test_AC6_機内モードでも端末内書誌DBでバーコード登録が動く | `scan.row.9784101000015` に即座に「こころ」が入り、保存後 H13 で本1冊（`current`）、alert・エラー0個、H29 外部通信0件 |
| AC-7 | R7 | 同値分割と境界値 | 既存 A(`current`)、書名「 羅生門　」（前後半角/全角空白）、著者「芥川龍之介」を候補未選択で保存 | 画面 | RegistrationAcceptanceTests.swift::test_AC7_候補を選ばずに前後空白を除いて積読に保存できる | H13 で本2冊、新刊の書名「羅生門」・著者「芥川龍之介」・ISBN空・出版社空・`status=tsundoku`、A は `current`、再起動後も同じ |
| AC-8 | R7 | 同値分割と境界値 | (1)書名空 (2)全角空白のみ (3)絵文字込み101字 (4)書名100字+著者101字 (5)書名100字+著者100字 (6)書名「羅生門」+著者空 | 画面 | RegistrationAcceptanceTests.swift::test_AC8_手入力の書名と著者の文字数境界を検証する | (1)〜(3)は `book.title.invalid` 1個で本0冊、(4)は `book.author.invalid` 1個で本0冊、(5)(6)は保存され H13 で本1冊（(6)は著者空） |
| AC-9 | R7 | デシジョンテーブル | H20 `status=notDownloaded`→バーコード I1 読取→`scan.row.editTitle` に「こころ」入力→追加 | 画面 | RegistrationAcceptanceTests.swift::test_AC9_書誌DB未取得時にその場で書名を入れて追加できる | `scan.dbNotReady`・`scan.row.captureCover`・`scan.row.editTitle` が各1個・alert 0個、追加後 H13 で書名「こころ」・ISBN I1・`status=current`、H29 通信0件 |
| AC-10 | R7 | デシジョンテーブル | H20 にない I4 を読取→`scan.row.editTitle` に「青を売る」入力→追加 | 画面 | RegistrationAcceptanceTests.swift::test_AC10_書誌DBにないISBNをその場で書名入力して追加できる | `scan.notFound`・`scan.row.captureCover`・`scan.row.editTitle` が各1個、追加後 H13 で書名「青を売る」・ISBN I4・`status=current`、H29 通信0件 |
| AC-11 | R7 | デシジョンテーブル | H20 にない `9784003101018`（出版者記号 `00`）＋Cコード `1920193006001`（形態 `1`）読取→書名「こころ」入力 | 画面 | RegistrationAcceptanceTests.swift::test_AC11_未収録ISBNとCコードから岩波書店と文庫を補完する | 行の候補および保存後 H13 で書名「こころ」・出版社「岩波書店」・レーベル「文庫」・ISBN `9784003101018` |
| AC-12 | R7 | デシジョンテーブル | カメラ拒否（H26 `denied`）→`register.barcode` 押下 | 画面 | RegistrationAcceptanceTests.swift::test_AC12_カメラ拒否時に設定とスクショと手入力の導線が出る | カメラ画面は出ず、`camera.denied`・`camera.openSettings`・`register.screenshot`・`register.manual` が各1個、H13 で本0冊 |
| AC-13 | R6 | 代表の1例 | 本5冊：A(`current`), B(10/10 `tsundoku`), C(10/12 `tsundoku`), D(10/14 `tsundoku`), E(`finished`) | 画面 | ShelfAndBookAcceptanceTests.swift::test_AC13_本棚の3区分と積読の新しい順の並びを検証する | `shelf.current` に A 1件、`shelf.tsundoku` に上から D・C・B の3件、`shelf.finished` に E 1件 |
| AC-14 | R6 | 状態遷移 | A(`current`, 一行・p.61)→積読 B を `book.readThis`→読了 E を `book.readThis` | 画面 | ShelfAndBookAcceptanceTests.swift::test_AC14_積読や読了の本を今の本に切り替えられる | 1回目で B が `current`・A が `tsundoku`（A の一行と p.61 保持、H22 は B の書名のみ）、2回目で E が `current`・B が `tsundoku` |
| AC-15 | R6 | 代表の1例 | 本 A（「こころ」「漱石」、記録20分・30分）を `book.edit` で「こゝろ」「夏目漱石」に編集 | 画面 | ShelfAndBookAcceptanceTests.swift::test_AC15_本の書名と著者を直しても記録が保たれる | 本棚と奥付が「こゝろ」「夏目漱石」、H13 で記録2件（20分・30分、合計50分）が保持され再起動後も同じ |
| AC-16 | R6 | 状態遷移 | A(`current`, 記録3件)と B(`tsundoku`, 記録1件)→A を `book.delete` し確認で消す→再起動 | 画面 | ShelfAndBookAcceptanceTests.swift::test_AC16_今の本を消すと記録も消え今の本なしになる | `book.delete.confirm` に「3」を含み、削除後 H13 で B 1冊・記録1件のみ、S-1 に `bookmark.noCurrent.message`、H22 が `widget.empty`、再起動後も同じ |
| AC-17 | R7 | デシジョンテーブル | 本 A（レーベルなし、直木賞・本屋大賞該当）と本 B（新潮社・新潮文庫、受賞なし）の奥付表示 | 画面 | ShelfAndBookAcceptanceTests.swift::test_AC17_本の画面の奥付5行と出版社レーベル受賞が出る | A の `book.colophon` に書名・著者・出版社・出版年・`colophon.award`（「第156回 直木三十五賞」「2017年 本屋大賞」）、B は「新潮社（新潮文庫）」で `colophon.award` 0個 |
| AC-18 | R7 | 同値分割と境界値 | 本 F（書名「無題の本」のみ、著者・出版社・出版年・受賞なし）を開く | 画面 | ShelfAndBookAcceptanceTests.swift::test_AC18_奥付でデータのない行や不明の文字を出さない | `book.colophon` 内は `colophon.title` 1行のみ、「不明」「なし」「受賞なし」の文字が0個 |
| AC-19 | R7 | 同値分割と境界値 | 本 G（書名「コンビニ人間」、著者「村田 沙耶香」半角空白あり）と H25 受賞一覧の照合 | 画面 | ShelfAndBookAcceptanceTests.swift::test_AC19_書名と著者の両方が一致するとき受賞が出る | `colophon.award` が1個出て「第155回 芥川龍之介賞」を含む |
| AC-20 | R7 | 同値分割と境界値 | H(著者違い)、I(書名一部)、L(「鹿の王 上」巻数違い)、M(「コンビニ人間―創作ノート」派生) | 画面 | ShelfAndBookAcceptanceTests.swift::test_AC20_片方不一致や派生本には受賞を出さない | H・I・L・M いずれも `colophon.award` が0個、「受賞なし」「なし」の文字も0個 |
| AC-21 | R7 | 同値分割と境界値 | J(全角カンマ+著者空白)、K(「（文春文庫）」つき)、K2(「［新装版］」つき) | 画面 | ShelfAndBookAcceptanceTests.swift::test_AC21_記号や括弧の違いを正規化して受賞を照合する | J・K・K2 すべてで `colophon.award` が1個出て「2019年 本屋大賞」を含む |
| AC-22 | R1 | 同値分割と境界値 | 5件の記録（21:00, 00:40, 21:30, 03:59, 04:00 開始、Asia/Tokyo）を (1)Asia/Tokyo (2)America/Los_Angeles で表示 | 画面 | ShelfAndBookAcceptanceTests.swift::test_AC22_4時境目の晩の日付とタイムゾーン変更不変を検証する | (1)(2)とも `book.record.row` が5件で上から「10/17、10分」「10/16、10分」「10/16、30分」「10/15、15分」「10/14、20分」、合計「85分」と「4晩」 |
| AC-23 | R1 | 同値分割と境界値 | 記録0件の本 B の画面を開く | 画面 | ShelfAndBookAcceptanceTests.swift::test_AC23_記録がない本の画面に空の案内が出る | `book.records.empty` が1個、`book.record.row` が0個 |
| AC-24 | R1 | 代表の1例 | 記録2件（20分、45分）のうち45分を30分に編集して保存 | 画面 | ShelfAndBookAcceptanceTests.swift::test_AC24_記録の分数を直すと合計分数が更新される | H13 と画面で該当記録が30分、合計50分、件数2件のまま、再起動後も同じ |
| AC-25 | R1 | 同値分割と境界値 | 分数に (1)0 (2)1441 (3)空 (4)「１２」 (5)1 (6)1440 (7)12.5 を入力 | 画面 | ShelfAndBookAcceptanceTests.swift::test_AC25_記録の分数の入力境界値を検証する | (1)〜(3)(7)は `record.minutes.invalid` が1個出て45分のまま、(4)は12分・(5)は1分・(6)は1440分で保存される |
| AC-26 | R1 | 状態遷移 | 記録2件（20分、45分）から45分の記録を削除 | 画面 | ShelfAndBookAcceptanceTests.swift::test_AC26_記録を消すと件数と合計と晩数が減る | H13 と画面で記録1件（20分）、合計20分、1晩、再起動後も同じ |
| AC-27 | R4 | 同値分割と境界値 | 本 A（「羅生門」、一行14字、p.61）を W-1 最小枠 `153x68` と最大枠 `172x76` で H22 読出 | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC27_ロック画面ウィジェットに縦書きの一行とページが出る | 両枠とも縦書き14字すべて（欠け0字）と「p.61」が入り、URL が `yomuma://open?entry=lock_widget`、画像を添付保存 |
| AC-28 | R4 | 同値分割と境界値 | (1)句読点 (2)かぎ括弧 (3)長音「ー」 (4)〜(6)行頭禁則位置 L+1 字目に「、」「」」「ー」 | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC28_縦書きの字形置換と行頭禁則処理を検証する | U+FE11/FE12/FE41/FE42 置換、「ー」90度回転、右から左の列配置、全列の先頭に禁則文字が0個、全文字欠けなし |
| AC-29 | R4 | 同値分割と境界値 | (1)25字 (2)31字・18字目「、」 (3)31字・10字目「、」のみ (4)31字・13字目「、」 (5)31字・12字目「、」 (6)31字・8字目「、」20字目「。」 | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC29_26字以上の一行の句読点位置による縮め方を検証する | W-1 は (1)25字 (2)18字 (3)24字+「…」 (4)13字 (5)24字+「…」 (6)20字、S-1 の `bookmark.line` はすべて全文表示 |
| AC-30 | R4 | 同値分割と境界値 | 日本語を含まない一行「It was raining.」 | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC30_欧文のみの一行は横書き1行で出る | H22 で縦列分割せず横書き1行で「It was raining.」が出る |
| AC-31 | R4 | デシジョンテーブル | 本 B（「檸檬」、一行なし）：(1)ページ120あり (2)ページなし | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC31_一行がないときは書名とページをウィジェットに出す | W-1・W-2 とも (1)は「檸檬」と「p.120」、(2)は「檸檬」のみ、どちらも一行は0字 |
| AC-32 | R4 | 同値分割と境界値 | (1)本0冊 (2)積読・読了のみで `current` 0冊 | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC32_今の本がないときはウィジェットに空の文言が出る | W-1・W-2 とも `widget.empty` の文言のみが入る |
| AC-33 | R4 | 状態遷移 | 読書終了→`mark.manual` で新しい一行と p.61 を保存→S-1 に戻る | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC33_しおり保存でウィジェットが1回だけ再読み込みされる | 保存から S-1 復帰までの H22 再読み込み要求が1回、中身が「下人の行方は、誰も知らない。」と「p.61」に更新 |
| AC-34 | R4 | デシジョンテーブル | `settings.hideOnWidgets=true` で W-1、W-2、予約 Live Activity、VoiceOver ラベル、S-1 を確認 | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC34_隠す設定オンでウィジェットとLiveActivityから書名と一行を隠す | W-1・W-2・Live Activity・読み上げラベルのすべてに「羅生門」と一行が入らず `widget.hidden`（「しおり」）と「p.61」のみ、S-1 には一行が出る |
| AC-35 | R4 | 同値分割と境界値 | W-2（`systemSmall`）を最小枠 `148x148` と最大枠 `170x170` で H22 読出 | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC35_StandBy用の小ウィジェットに縦書きの一行とページが出る | 両枠とも14字すべて（欠け0字）と「p.61」、URL が `yomuma://open?entry=small_widget`、画像を添付保存 |
| AC-36 | R4 | 状態遷移 | 入口 21:00、(1)22:00 開始→22:30 保存 (2)翌 00:00 開始→00:30 保存（4:00 前の同晩） | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC36_しおり保存で翌晩21時のLiveActivityが1件予約される | 起動時要求0件、保存後に既存予約取消1件＋新規予約1件（どちらも開始 `2026-10-19 21:00`、中身は新しい一行と「p.61」） |
| AC-37 | R4 | デシジョンテーブル | H23 `areActivitiesEnabled=false` で読書・しおり保存、設定画面を開く | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC37_LiveActivityオフ時は予約要求を出さず設定に案内を出す | H23 予約要求0件、alert 0個、H22 は新しい一行と「p.61」、S-10 に `settings.liveActivity.off` が1個 |
| AC-38 | R4 | 同値分割と境界値 | `settings.entryTime` を `22:45` に変更して読書・しおり保存 | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC38_夜の入口の時刻を15分刻みで変えると予約時刻が変わる | 選べる分が 00/15/30/45 の4種のみ、H23 の予約1件の開始時刻が `2026-10-19 22:45` |
| AC-39 | R4 | 代表の1例 | 予約0件の晩にアイコンから通常起動 | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC39_予約がない晩でもアイコン起動でしおり画面が開き伏せ監視がオンになる | S-1 に一行と「p.61」が出て `bookmark.start` が有効、H17 `flipMonitoring=on`、自動シート・alert 0個 |
| AC-40 | R4 | デシジョンテーブル | 起動元 (1)`lock_widget` (2)`small_widget` (3)`live_activity` (4)アイコン (5)URL起動後バックグラウンド経由 (6)299秒後開始 (7)301秒後開始 | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC40_入口のURLと300秒境界で記録の入口の印が決まる | H17 `entry` が (1)`lock_widget` (2)`small_widget` (3)`live_activity` (4)`app` (5)`app` (6)`lock_widget` (7)`app` |
| AC-41 | R4 | 状態遷移 | 予約 Live Activity 表示中（`started`）→`bookmark.start`→600秒後終了→p.61 保存 | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC41_表示中の予約LiveActivityが読書中から結果表示へ遷移する | 開始時に `reading` 更新要求1件（書名と開始時刻、`liveActivity.end` 1個、一行と p.43 なし）、保存時に終了要求1件（「10分」「p.61」） |
| AC-42 | R1 | 代表の1例 | 本 A、`idle`→起動して `bookmark.start` を1回タップ | 画面 | ReadingSessionAcceptanceTests.swift::test_AC42_起動から1タップで確認や入力なしに読み始められる | `reading` になるまでのタップ1回、入力欄・alert・シート・ピッカー・セグメント・メニューすべて0個 |
| AC-43 | R1 | 代表の1例 | `bookmark.start` で読書中画面（S-2）へ遷移 | 画面 | ReadingSessionAcceptanceTests.swift::test_AC43_読書中の画面は押せる要素が終えるの1つだけになる | H9 `state=reading`、A の書名表示、押せる要素は `reading.end` の1個のみ（タブバー・ナビバー0個） |
| AC-44 | R2 | 状態遷移 | S-1 前面・`idle`→H15 `faceDown`＋H16 で 1.0秒経過 | 画面 | ReadingSessionAcceptanceTests.swift::test_AC44_しおり画面で伏せて1秒たつと触覚が1回鳴り読み始める | H9 `state=reading`、H17 `startedBy=flip`、`haptic=1`、S-2 に A の書名と `reading.end` 1個 |
| AC-45 | R2 | 同値分割と境界値 | H15 `faceDown`→0.9秒で `portrait` に起こす→さらに 2.0秒進める | 画面 | ReadingSessionAcceptanceTests.swift::test_AC45_伏せて1秒未満で起こすと読み始めない | H9 `state=idle` のまま、H17 `haptic=0`、記録件数変化なし |
| AC-46 | R2 | デシジョンテーブル | (1)本0冊 (2)積読のみで `current` 0冊→S-1 で伏せて 2.0秒経過 | 画面 | ReadingSessionAcceptanceTests.swift::test_AC46_今の本がないときは伏せの監視がオフで始まらない | 両方とも `state=idle`、`haptic=0`、`flipMonitoring=off`、(1)は `bookmark.empty.message`、(2)は `bookmark.noCurrent.message` |
| AC-47 | R2 | デシジョンテーブル | 本棚、本の画面、登録各画面、しおり入力、OCR確認、結果、読了、設定、`session.tooShort` 表示中、起動前から伏せ状態 | 画面 | ReadingSessionAcceptanceTests.swift::test_AC47_しおり画面以外や知らせ表示中は伏せても始まらない | すべての場面で状態と画面が変わらず、`haptic=0`、しおり画面以外では `flipMonitoring=off` |
| AC-48 | R2 | 状態遷移 | 伏せて開始→180秒後に起こす→10秒後に再伏せ→420秒後に起こして終了・`mark.later` | 画面 | ReadingSessionAcceptanceTests.swift::test_AC48_読書中に起こしても止まらず伏せ直しても二重に始まらない | 途中も `state=reading` 継続、終了後 H13 に記録1件（10分＝610秒）、H17 `haptic=1`（開始時の1回のみ） |
| AC-49 | R2 | 代表の1例 | S-1 で伏せて 1.0秒経過 | 画面 | ReadingSessionAcceptanceTests.swift::test_AC49_伏せて読み始めたときにVoiceOver読み上げが1回出る | H17 `announce=session.flipStarted.announcement:1`（A の書名を含む文） |
| AC-50 | R2 | 代表の1例 | 紙の本 A（`current`）、伏せる道オンで S-1 を開く | 画面 | ReadingSessionAcceptanceTests.swift::test_AC50_しおり画面に伏せて始める案内の1行が出る | S-1 に `bookmark.flipHint` の要素がちょうど1個ある |
| AC-51 | R2 | デシジョンテーブル | (1)`settings.flipToStart` をオフにして再起動 (2)H18 `-uitest-flip-unavailable`→S-1 で伏せて 2.0秒経過 | 画面 | ReadingSessionAcceptanceTests.swift::test_AC51_伏せる設定オフまたは非対応環境では伏せても始まらない | 両方とも `state=idle`、`haptic=0`、`bookmark.flipHint` 0個、`flipMonitoring=off`、`bookmark.start` が有効 |
| AC-52 | R1 | 状態遷移 | `bookmark.start`→ホームへ移動し背面で H5 を 600秒進める→復帰して終了・`mark.later` | 画面 | ReadingSessionAcceptanceTests.swift::test_AC52_バックグラウンドの間も開始時刻からの差で時間を数える | H13 で A の記録が1件・10分で保存され、再起動後も同じ |
| AC-53 | R1 | 状態遷移 | 読み始めて 300秒経過→強制終了→開始から 600秒後の時刻（H4）で再起動→終了・`mark.later` | 画面 | ReadingSessionAcceptanceTests.swift::test_AC53_読書中に強制終了しても再起動後に続きから数える | 再起動直後に `state=reading` で S-2（A の書名）が出て、終了後 H13 に記録1件・10分が残る |
| AC-54 | R2 | デシジョンテーブル | (1)`bookmark.start` 開始 (2)伏せて開始→各直後と 60秒経過後を H9/H17 で確認 | 画面 | ReadingSessionAcceptanceTests.swift::test_AC54_読書中も自動ロック無効化と近接センサー監視を使わない | 直後・60秒後とも `idleTimerDisabled=false` かつ `proximity=false` |
| AC-55 | R1 | 同値分割と境界値 | 読み始めて 120秒後→`reading.end` を1回タップ（Perf 構成で5回計測） | 画面 | ReadingSessionAcceptanceTests.swift::test_AC55_終える1タップで確認なしに500ミリ秒以内にしおり画面が出る | alert・シート0個で S-3 が開き、H10 `endToMark` が5回とも 500ms 以下 |
| AC-56 | R1 | 同値分割と境界値 | 既存記録1件（20分）、(1)経過 59秒で終了 (2)経過 60秒で終了 | 画面 | ReadingSessionAcceptanceTests.swift::test_AC56_59秒は記録せず60秒ちょうどから1分として記録する | 59秒は記録1件（合計20分）のまま `session.tooShort` 1個が出て S-1 に戻る。60秒は S-3 が出て記録2件（新規1分、合計21分） |
| AC-57 | R1 | 同値分割と境界値 | 経過 (1)86,400秒 (2)86,459秒 (3)86,460秒 (4)108,000秒（30時間）で終了・`mark.later` | 画面 | ReadingSessionAcceptanceTests.swift::test_AC57_24時間超は1440分で止めて上限の知らせを出す | (1)(2)は1440分で `session.capped` 0個、(3)(4)は1440分で `session.capped` が1個出る |
| AC-58 | R1 | 状態遷移 | `21:00` に読み始めて強制終了→端末時刻を `20:30`（H4）に戻して再起動し終了 | 画面 | ReadingSessionAcceptanceTests.swift::test_AC58_端末時刻が開始より前に戻ったときは記録せず知らせを出す | 記録件数は増えず、`session.invalidTime` が1個出て `state=idle` の S-1 に戻り、S-3 は出ない |
| AC-59 | R6 | デシジョンテーブル | H7 `session.start:1` で (1)`bookmark.start` 押下 (2)伏せて 1.0秒経過 | 画面 | ReadingSessionAcceptanceTests.swift::test_AC59_読み始めの保存失敗時はidleのままエラーを出す | (1)(2)とも `session.start.error` が1個出て `state=idle` のまま S-1 に残り、`haptic=0`、記録件数不変 |
| AC-60 | R6 | 状態遷移 | 900秒経過、H7 `session.end:2`→終了(1回目失敗)→+300秒で終了(2回目失敗)→+300秒で終了(3回目成功) | 画面 | ReadingSessionAcceptanceTests.swift::test_AC60_終わりの保存失敗時は読書中を保ち再試行で合算保存される | 1・2回目は `session.save.error` 1個で `state=reading`（`reading.end` のみ）、3回目で S-3 が出て記録1件・25分（1500秒） |
| AC-61 | R1 | 状態遷移 | (1)`bookmark.start` を 0.3秒以内に2回押下 (2)`reading.end` を 0.3秒以内に2回押下 | 画面 | ReadingSessionAcceptanceTests.swift::test_AC61_開始と終了の二度押しで記録や画面が重複しない | (1)(2)とも S-2・S-3 は1つだけで、H13 の記録は1件（2分）のみ |
| AC-62 | R1 | 状態遷移 | H8 通信なし→`lock_widget` URL 起動（H28）→開始→120秒後終了→`mark.manual` で一行と p.61 保存 | 画面 | ReadingSessionAcceptanceTests.swift::test_AC62_オフラインでもウィジェット起動からしおり保存まで完走する | 記録1件（2分）、H13 と H22 が新しい一行と「p.61」に更新、alert 0個、`error` を含む要素0個 |
| AC-63 | R3 | 代表の1例 | 1,080秒読んで `reading.end` を押下し S-3 を開く | 画面 | BookmarkAcceptanceTests.swift::test_AC63_しおりを挟む画面に5つの道がすべて押せる状態で出る | `mark.photo`・`mark.screenshot`・`mark.manual`・`mark.pageOnly`・`mark.later` が各1個で全て `isEnabled == true` |
| AC-64 | R3 | 状態遷移 | `idle`・記録0件の S-1 で `bookmark.setMark`→`mark.manual` で一行と p.12 を保存 | 画面 | BookmarkAcceptanceTests.swift::test_AC64_読まずにしおりだけを挟むと記録を増やさず更新される | S-1 の `bookmark.line` に「下人は、雨やみを待っていた。」・`bookmark.page` に「p.12」、H13 記録0件、`state=idle`、S-4 は出ず H22 も同値 |
| AC-65 | R3 | 状態遷移 | H19 で縦6列（c6「ほかには誰もいない。」）注入→`mark.photo`→`mark.pageField` に 61→`mark.save` | 画面 | BookmarkAcceptanceTests.swift::test_AC65_ページ写真OCRで一番左の列が初期選択され保存できる | `mark.ocr.column.1`〜`6` が出て `column.6` が選択状態、`mark.lineField` が「ほかには誰もいない。」、保存後 H13 が同文と p.61 で S-4 表示 |
| AC-66 | R3 | 状態遷移 | AC-65 の撮影後→`mark.ocr.column.3`（文字 X）をタップ→`mark.save` | 画面 | BookmarkAcceptanceTests.swift::test_AC66_OCR結果の別の列を選び直して保存できる | `mark.lineField` が X に替わり選択列が c3 のみになり、保存後 H13 の一行が X になる |
| AC-67 | R3 | 代表の1例 | H19 で c6「羅生際の下で雨やみを待っていた。」→`mark.lineField` で「際」を「門」に修正→保存 | 画面 | BookmarkAcceptanceTests.swift::test_AC67_OCRの誤字を入力欄で手直しして保存できる | 保存後 H13 の一行が「羅生門の下で雨やみを待っていた。」になり「羅生際」が残らない |
| AC-68 | R3 | 同値分割と境界値 | H19 で列0件を返す→`mark.photo` 押下 | 画面 | BookmarkAcceptanceTests.swift::test_AC68_文字が1行も読み取れないときに撮り直しと手入力が出る | `mark.ocr.none`・`mark.retake`・`mark.manual` が各1個出て、H13 の一行とページは変更前のまま |
| AC-69 | R3 | デシジョンテーブル | H19 で撮影後 (1)`mark.save` で保存 (2)保存せず `mark.later`→H27 と H13 を検査 | 画面 | BookmarkAcceptanceTests.swift::test_AC69_撮影したページ画像と未選択列の文字を一切残さない | (1)(2)とも H27 `savedImageFileCount=0`・`photoLibraryWriteCount=0`、H13 に未選択列 c1〜c5 の文字が0件 |
| AC-70 | R3 | デシジョンテーブル | カメラ拒否（H26 `denied`）→S-3 で `mark.photo` 押下 | 画面 | BookmarkAcceptanceTests.swift::test_AC70_しおり撮影でカメラ拒否時にスクショと手入力の導線が出る | カメラは開かず `camera.denied`・`camera.openSettings`・`mark.screenshot`・`mark.manual`・`mark.pageOnly` が各1個、前のしおり維持 |
| AC-71 | R3 | 同値分割と境界値 | `mark.manual` で前後に全角空白つきの「　下人の行方は、誰も知らない。　」とページ 61 を保存 | 画面 | BookmarkAcceptanceTests.swift::test_AC71_手入力の一行の前後空白を除いて保存する | H13 の一行が「下人の行方は、誰も知らない。」、ページが 61、再起動後も同じ |
| AC-72 | R3 | 同値分割と境界値 | `mark.manual` で一行に (1)空 (2)全角空白のみ (3)61字 (4)60字ちょうど を入力 | 画面 | BookmarkAcceptanceTests.swift::test_AC72_一行の1字から60字までの境界値を検証する | (1)〜(3)は `mark.line.invalid` 1個が出て前のしおりのまま、(4)は60字で保存される |
| AC-73 | R3 | 状態遷移 | 一行と p.43 がある本 A で `mark.pageOnly` に 61 を入れて保存 | 画面 | BookmarkAcceptanceTests.swift::test_AC73_ページ数だけ入れると一行が空になりウィジェットも書名とページになる | H13 でページ 61・一行が空、H22 が書名と「p.61」のみで一行0字 |
| AC-74 | R3 | 同値分割と境界値 | `mark.pageOnly` に (1)0 (2)10000 (3)空 (4)「６１」 (5)1 (6)9999 (7)61.5 を入力 | 画面 | BookmarkAcceptanceTests.swift::test_AC74_ページ番号の1から9999までの境界値と全角数字を検証する | (1)〜(3)(7)は `mark.page.invalid` 1個で p.43 のまま、(4)は61・(5)は1・(6)は9999で保存される |
| AC-75 | R3 | 状態遷移 | 1,080秒読んで終了→`mark.later` を押下 | 画面 | BookmarkAcceptanceTests.swift::test_AC75_あとでを選ぶと前のしおりを保ち結果画面に分数だけが出る | H13 で記録1件（18分）・一行と p.43 は前のまま、S-4 の `result.summary` は「18分」のみでページ表記を含まない |
| AC-76 | R3 | デシジョンテーブル | 1,080秒読書後 `mark.pageOnly` で 61 保存：(1)前回 p.43 あり (2)前回ページなし→`result.close` | 画面 | BookmarkAcceptanceTests.swift::test_AC76_結果画面に前回ページからの遷移と分数が出て1タップで閉じる | `result.summary` が (1)「p.43 → p.61　18分」 (2)「p.61　18分」、`result.close` 1タップで S-1 に戻る |
| AC-77 | R8 | 状態遷移 | 本 A（記録3晩・65分）で S-1 の `bookmark.finish` を押下 | 画面 | FinishAndRecommendationAcceptanceTests.swift::test_AC77_読み終えたボタンで読了になり奥付5行と奥付撮影ボタンが出る | H13 で A が `status=finished`・`current` 0冊、S-9 の `finish.colophon` に5行と `colophon.capture` 1個が出る |
| AC-78 | R8 | デシジョンテーブル | 読了 A（恩田陸・直木賞156回）、積読 P(同著者)・Q(同賞160回)・R・S、H25 未所有 N(同賞157回) | 画面 | FinishAndRecommendationAcceptanceTests.swift::test_AC78_次の1冊に積読の関連本2冊と未所有の関連本1冊が順に並ぶ | `next.candidate` が3件で上から P、Q、N の順 |
| AC-79 | R8 | 代表の1例 | AC-78 の S-9 で各候補の `next.reason` を確認 | 画面 | FinishAndRecommendationAcceptanceTests.swift::test_AC79_次の1冊の各候補に事実1行の理由が出る | P に「積読から・同じ著者」、Q に「積読から・同じ賞（直木三十五賞）」、N に「同じ賞（第157回 直木三十五賞）」 |
| AC-80 | R8 | デシジョンテーブル | 未所有の候補が0件、積読に P(同著者)・R・S(重なりなし) の3冊 | 画面 | FinishAndRecommendationAcceptanceTests.swift::test_AC80_未所有の候補がないときは積読から最大3冊を出す | `next.candidate` が上から P（「積読から・同じ著者」）、R（「積読から」）、S（「積読から」）の3件 |
| AC-81 | R8 | 同値分割と境界値 | 積読0冊かつ H20・H25 にも関連候補0件で `bookmark.finish` | 画面 | FinishAndRecommendationAcceptanceTests.swift::test_AC81_積読も未所有の候補もないときは本を加える案内が出る | `next.candidate` が0個、`next.empty.message` と `next.addBook` が各1個出る |
| AC-82 | R8 | 状態遷移 | S-9 で積読候補 P の `next.choose` を押下 | 画面 | FinishAndRecommendationAcceptanceTests.swift::test_AC82_次の1冊で積読の本を選ぶと今の本になりウィジェットも更新される | H13 で P が `status=current`、S-1 の `bookmark.title` が P、H22 が P の書名のみ（一行なし） |
| AC-83 | R8 | 状態遷移 | S-9 で H25 由来の未所有候補 N（「月の満ち欠け」「佐藤正午」）の `next.addToShelf` を押下 | 画面 | FinishAndRecommendationAcceptanceTests.swift::test_AC83_受賞一覧から出た未所有の本を積読に加えられる | H13 で本が1冊増え（「月の満ち欠け」「佐藤正午」、`status=tsundoku`、`current` は0冊のまま）、行の `next.addToShelf` が0個になる |
| AC-84 | R8 | 代表の1例 | S-9（「蜜蜂と遠雷」「恩田陸」、3晩、65分、一行あり）で `finish.card.share` を押下 | 画面 | FinishAndRecommendationAcceptanceTests.swift::test_AC84_読み終えのカード画像に書名著者晩数分数だけを描き一行を含めない | H24 で PNG 画像1件、`renderedTexts` に「蜜蜂と遠雷」「恩田陸」「3晩」「65分」を含み、`containsSavedLine=false`・`containsPhoto=false` |
| AC-85 | R1 | 同値分割と境界値 | 記録3件：10/15 23:30(20分)、10/16 00:40(15分・同晩)、10/16 21:00(30分)→カード共有 | 画面 | FinishAndRecommendationAcceptanceTests.swift::test_AC85_読み終えのカードの晩数を4時境目のユニーク晩数で数える | H24 の描画文字列に「2晩」と「65分」が入る |
| AC-86 | R8 | 代表の1例 | 今の本 A と積読3冊がある状態で S-1→S-2→S-3→S-4 を順に遷移 | 画面 | FinishAndRecommendationAcceptanceTests.swift::test_AC86_今の本がある毎晩の道には次の1冊の候補を出さない | S-1〜S-4 のどの画面でも `next.candidate` と `bookmark.noCurrent.next` が0個、自動シート・alert 0個 |
| AC-87 | R8 | デシジョンテーブル | 読了 A（「鹿の王 1」上橋菜穂子）、積読 P（「獣の奏者」）、H20 に未所有 U1（「鹿の王 2」次巻）と U2（「狐笛のかなた」同著者） | 画面 | FinishAndRecommendationAcceptanceTests.swift::test_AC87_端末内書誌DBからシリーズの次の巻と同じ著者の本を推薦し書誌つきで積読に加える | `next.candidate` が P・U1（「シリーズの次の巻」）・U2（「同じ著者の本」）、U1 の `next.addToShelf` で出版社「KADOKAWA」・レーベル「角川文庫」・2019・ISBN `9784041026000` つきで `tsundoku` 追加 |
| AC-88 | R6 | 代表の1例 | S-10 を開き `settings.privacyPolicy` を押下 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC88_設定画面からプライバシーポリシーのURLを開く | S-10 に `settings.privacyPolicy` が1個あり、押下で H31 `openedURLs` に Info.plist の URL が1件記録される |
| AC-89 | R6 | 状態遷移 | 画面操作のみで本3冊（A `current`・一行・p.61、B `tsundoku`、E `finished`）、記録3件、設定3項目を変更→強制終了・再起動 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC89_画面操作で入れた本と記録としおりと設定が再起動後もすべて残る | 再起動後の画面と H13 で3冊の書名・状態、A の一行・p.61、記録3件の日付・分数、設定3つ（`false`, `true`, `22:45`）がすべて一致 |
| AC-90 | R6 | 状態遷移 | 本2冊・記録3件、H7 `store.load:1` で起動→強制終了し失敗なしで再起動 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC90_起動時の保存先読込失敗でエラーを出し再起動で元のデータが戻る | 1回目は `store.load.error` 1個で `bookmark.start`・`bookmark.addBook` が0個、2回目は本2冊と記録3件が元の値で出る |
| AC-91 | R6 | デシジョンテーブル | H7 で (1)`book.add` (2)`book.update` (3)`book.delete` (4)`book.status` (5)`record.update` (6)`record.delete` (7)`mark.save` を各1回失敗させる | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC91_7種類の保存失敗時にエラーが出て変更前のデータが保たれる | 7通りすべてで `common.save.error` が1個出て、H13 と再起動後の本の数・書名・状態・しおり・記録件数と分数が操作前のまま |
| AC-92 | R7 | 同値分割と境界値 | H20 の NDL 生データ6種（複数 creator、生没年、名「文」、名「周作」、肩書「ピアニスト」、author 要素「監修」）をバーコード登録 | 画面 | RegistrationAcceptanceTests.swift::test_AC92_NDL書誌の著者名から生没年や役割語や2人目以降を除いて整形する | H13 と `colophon.author` が I1「伴名練」・I2「遠藤周作」・I3「幸田文」・I4「坂崎かおる」・I5「渡邊朋子」・I6「中林くみこ」になる |
| AC-93 | R7 | ペアワイズ | 日本語・英語構成で S-10 の `settings.dataSources` と `settings.dataSources.license`、S-1・S-2 を確認 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC93_設定画面にNDLの3条件とCCBYリンクが出てしおり画面と読書中画面には出ない | 日英とも3条件＋DB版＋共起注記を含み、リンク押下で H31 に `https://creativecommons.org/licenses/by/4.0/` 始まりが1件、S-1・S-2 には要素0個 |
| AC-94 | R3 | 状態遷移 | H19 `hold=true` で `mark.photo` 撮影→OCR 返却前に (1)`mark.manual` (2)`mark.pageOnly` を押して入力→`yomuma.uitest.ocr.release` 送信 | 画面 | BookmarkAcceptanceTests.swift::test_AC94_OCR待ちの間も1秒以内に手入力やページ入力に移り後から結果が返っても上書きされない | 押下から入力欄表示まで H10 `markWait` が 1,000ms 以内、OCR 返却後も入力画面と入力値（「下人の」/「61」）が保たれ `mark.ocr.column` は0個 |
| AC-95 | R3 | 状態遷移 | 1,080秒読書後、H7 `mark.save:1` で `mark.manual` 保存(1回目失敗)→もう一度 `mark.save`(2回目成功) | 画面 | BookmarkAcceptanceTests.swift::test_AC95_読後のしおり保存失敗時も記録は残り入力値を保ったまま再保存できる | 1回目は `common.save.error` 1個で入力欄に値が残り H13 で記録1件（18分）・前のしおり維持、2回目で S-4 が出て新しいしおりに更新・記録は1件のまま |
| AC-96 | R4 | 状態遷移 | `widgetGuideShown=false` で初回の一行保存→`widgetGuide` を閉じる→2回目の保存→再起動して3回目の保存 | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC96_ウィジェットの置き方案内は最初の1回だけ出る | 1回目保存後に `widgetGuide` が1回（H17 `notice=widgetGuide:1`）出て、2回目と再起動後の保存では0回 |
| AC-97 | R4 | 状態遷移 | H23 で次の予約要求1回失敗→読書・しおり保存→アプリを背面にして前面に戻す | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC97_LiveActivity予約失敗時はアラートを出さず次回前面復帰時に予約し直す | 保存時は alert 0個で S-4 と H22 更新が完了し、前面復帰時に予約要求1件が出て `2026-10-19 21:00` の予約1件になる |
| AC-98 | R4 | 状態遷移 | `2026-10-19 20:00` 起動で予約作成→H23 で `started` に遷移→読まずに `2026-10-20 07:00`（H5）に前面復帰 | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC98_読まなかった晩のLiveActivityは翌朝前面復帰で終了し今夜分を予約する | 初回予約の `staleDate` が `2026-10-20 04:00`、翌朝7時復帰時に前夜分の終了要求1件と `2026-10-20 21:00` の新規予約1件が出る |
| AC-99 | R4 | 代表の1例 | 本 A（「羅生門」、一行、p.61）で W-1（H22）と S-1 の `bookmark.line` の VoiceOver ラベルを確認 | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC99_ウィジェットとしおり画面のVoiceOverラベルに縦書き用字形が含まれない | W-1 のまとまり数が1個で「羅生門」「61ページ」と元の文字列を含み U+FE11〜FE42 を含まない、`bookmark.line` も元の文字列と一致 |
| AC-100 | R10 | 代表の1例 | 本3冊・記録10件（H2）、Perf 構成で `XCTApplicationLaunchMetric(waitUntilResponsive: true)` を5回計測 | 画面 | PerformanceTests.swift::test_AC100_本3冊記録10件での起動から操作可能までの平均が1秒以内 | 5回の平均起動時間が 1.0秒（1,000ms）以内 |
| AC-101 | R10 | 同値分割と境界値 | 本500冊・記録5,000件（`-uitest-seed-preset perf500`、本 A に1,000件）、Perf 構成で本棚と A の本の画面を各5回開く | 画面 | PerformanceTests.swift::test_AC101_本500冊記録5000件での本棚と本の画面の表示平均が1秒以内 | H10 `shelfOpen` と `bookOpen` の5回平均がどちらも 1.0秒（1,000ms）以内 |
| AC-102 | R10 | 代表の1例 | 本 A（一行25字、p.61）、Perf 構成で W-1（`accessoryRectangular`）と W-2（`systemSmall`）を各5回生成 | 画面 | PerformanceTests.swift::test_AC102_ウィジェット2種類のタイムライン生成平均が500ミリ秒以内 | H22 の生成時間の5回平均がどちらも 0.5秒（500ms）以内 |
| AC-103 | R6 | デシジョンテーブル | バーコード登録(AC-2)、書名候補登録(AC-4)、読まずにしおり(AC-64)、読書と保存、読了とカード共有(AC-84)を連続実行 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC103_登録から読了カード共有まで外部HTTP通信が0件である | H29 `hook.outbound` の `requests` が空配列（0件） |
| AC-104 | R9 | 代表の1例 | 未購入（H30）で S-1→S-2→S-3→S-4→S-9 を順に開き下端までスクロール | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC104_未購入でも毎晩の道と読み終えた画面に課金案内が出ない | 全画面で購入シートと `store.` で始まる要素が0個、自動シート・alert も0個 |
| AC-105 | R9 | 状態遷移 | 未購入（H30）で S-10→`settings.appearance`→鍵つき見た目（`kinari`）をタップ→`store.close` | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC105_鍵つき見た目を押すと見本と購入シートが出て閉じると標準に戻る | `store.preview` の値が `kinari`、品名・説明・価格・`store.buy`・`store.restore`・`store.close` が各1個、閉じると H13 `appearanceID=default` |
| AC-106 | R9 | 状態遷移 | AC-105 の購入シートで H30 購入成功→`store.buy`→`kinari` 選択→強制終了・再起動 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC106_購入すると見た目を選べてウィジェットと再起動後にも反映される | H13 `isPlusPurchased=true`・`appearanceID=kinari`、H22 の見た目も `kinari`、再起動後も同じで鍵つき行が0個 |
| AC-107 | R9 | デシジョンテーブル | 購入シートで `store.buy`：(1)H30 `userCancelled` (2)H30 購入エラー | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC107_購入の取りやめとエラー時に未購入と標準の見た目が保たれる | (1)はシートが残り知らせ0個、(2)は `store.purchase.error` 1個、どちらも `isPlusPurchased=false`・`appearanceID=default` |
| AC-108 | R9 | デシジョンテーブル | 未購入状態で S-10 の `settings.restorePurchases` を押下：(1)H30 に購入履歴あり (2)購入履歴なし | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC108_購入の復元で履歴の有無に応じた結果と文言が出る | (1)は `isPlusPurchased=true` になり `store.restore.done` 1個、(2)は `false` のままで `store.restore.none` 1個 |
| AC-109 | R9 | デシジョンテーブル | H30 `canMakePayments=false` で `settings.appearance` の鍵つき見た目をタップ | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC109_決済不可の端末では購入ボタンを出さず案内を出す | `store.buy` が0個、`store.unavailable` が1個出て、`appearanceID=default` のまま他の設定は変更可能 |
| AC-110 | R9 | デシジョンテーブル | H8 通信なし＋H30 商品取得失敗で鍵つき見た目をタップ→S-1 に戻る | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC110_オフラインで商品を読めないときは案内を出し読書は妨げない | `store.offline` が1個・`store.buy` 0個・alert 0個、S-1 に戻ると `bookmark.start` が有効 |
| AC-111 | R9 | 状態遷移 | 購入済み・有料見た目 `kinari` 選択中→`yomuma.uitest.storekit.refund` 送信→背面から前面に復帰 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC111_購入が返金されると前面復帰時に標準の見た目へ戻る | H13 `isPlusPurchased=false`・`appearanceID=default`、H22 も `default` に戻り、本・記録・一行は不変 |
| AC-112 | R7 | 代表の1例 | H25 `hook.awards` で同梱の受賞一覧を読み、`docs/prd/001-reading-session-awards.md` の全行と比較 | API | ShelfAndBookAcceptanceTests.swift::test_AC112_同梱の受賞一覧データが仕様書の表と全行一致する | 行数が一致し、全行で `award`・`sessionOrYear`・`title`・`author` の4項目が完全一致 |
| AC-113 | R3 | 状態遷移 | 奥付が空の本 A で `colophon.capture`→H19 奥付行注入→確認欄から `colophon.save` | 画面 | ShelfAndBookAcceptanceTests.swift::test_AC113_奥付を1枚撮って著者出版社レーベル出版年ISBNを補完し画像を残さない | 確認欄と保存後 H13 に「坂崎かおる」「祥伝社」「祥伝社文庫」「2024」`9784396350017` が入り、H27 画像ファイル0個 |
| AC-114 | R5 | 状態遷移 | プロセスなし・`idle`・`22:00`→H32 `StartReadingIntent` 実行→前面に出し 1,800秒後終了・`mark.later` | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC114_読み始めるインテントでアプリを開かず読書とLiveActivityが始まる | `opensApp=false`、声 `intent.start.started`、`state=reading`、H23 即時開始1件（書名「羅生門」・22:00・一行とp.61なし・`liveActivity.end` 1個・ラベル `liveActivity.end.label`・staleDate 翌04:00）、H10 `intentStartRequest` 5回とも 500ms 以下、終了後 30分・`entry=intent_start` |
| AC-115 | R5 | デシジョンテーブル | (1)アプリで開始後にインテント (2)インテント2連続 (3)予約表示中にインテント (4)20:30 予約待機中にインテント (5)S-1 前面中にインテント | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC115_どの状態から読み始めるインテントを動かしても二重に始まらない | 全ケースで読書1件・記録1件、H23 要求は (1)(2)0件・声 `intent.start.alreadyReading`、(3)更新1件、(4)取消1件+開始1件、(5)開始1件かつ H10 `intentStartForeground` 1,000ms 以下 |
| AC-116 | R5 | デシジョンテーブル | インテント開始後 `EndReadingFromActivityIntent`：(1)1,800秒後・前面可 (2)1,800秒後・`canContinueInForeground=false`→+3,600秒後起動 (3)50秒後 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC116_LiveActivityの終えるで動いた時刻で記録し場面に応じて画面を出す | 全ケースで H23 終了要求1件、(1)は前面 S-3→30分・10/18・`intent_start`、(2)は前面要求せず 30分で確定し後で開くと S-1、(3)は記録増えず `session.tooShort` |
| AC-117 | R5 | デシジョンテーブル | (1)本0冊 (2)積読のみで `current` 0冊→H32 `StartReadingIntent` 実行 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC117_今の本がないときに読み始めるインテントはアプリを開いて空状態を見せる | 両方とも前面 S-1 で `state=idle`・H23 要求0件、(1)は `bookmark.empty.message`、(2)は `bookmark.noCurrent.message` |
| AC-118 | R5 | デシジョンテーブル | H23 `areActivitiesEnabled=false` で `StartReadingIntent`：(1)前面可 (2)`canContinueInForeground=false` | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC118_LiveActivityオフ時の読み始めるインテントは読書を開始し前面可ならS2を出す | 両方とも `state=reading`・H23 要求0件・alert 0個、(1)は即 S-2 表示で終了後 2分・`intent_start`、(2)は後で開くと開始時刻を保った S-2 表示 |
| AC-119 | R5 | 状態遷移 | H7 `session.start:1` で H32 `StartReadingIntent` 実行→アプリを前面に出す | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC119_読み始めるインテントで保存失敗時はエラーを返しLiveActivityを出さない | 結果がエラーで声 `session.start.error`、`state=idle`、インテント由来の H23 要求0件、前面 S-1 で `bookmark.start` が有効 |
| AC-120 | R4 | デシジョンテーブル | `settings.hideOnWidgets=true` で H32 `StartReadingIntent` 実行 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC120_隠す設定オンのとき読み始めるインテントのLiveActivityに書名を出さない | H23 の開始要求に「羅生門」と一行が入らず、`widget.hidden`（「しおり」）と開始時刻 22:00 と `liveActivity.end` 1個が入る |
| AC-121 | R4 | 代表の1例 | 本 A（「羅生門」、一行、p.61）で H32 `WhereStoppedIntent` 実行 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC121_どこまで読んだインテントは認証なしでページだけ答え一行と書名を出さない | `opensApp=false`、`authenticationPolicy=alwaysAllowed`、声と小窓が `intent.whereStopped.page`（「61ページからです。」）と一致し一行・「羅生門」・アプリ名を含まない |
| AC-122 | R5 | デシジョンテーブル | `WhereStoppedIntent`：(1)一行もページもなし (2)積読のみで `current` 0冊 (3)本0冊 (4)一行あり・ページなし | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC122_どこまで読んだインテントでページや今の本がないときの応答を検証する | (1)(4)は `intent.whereStopped.noPage`（(4)に一行を含まない）、(2)(3)は `intent.whereStopped.noCurrent`、すべて `opensApp=false` |
| AC-123 | R4 | デシジョンテーブル | `settings.hideOnWidgets=true` で H32 `WhereStoppedIntent` 実行 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC123_隠す設定オンでもどこまで読んだインテントはページを答え書名と一行を出さない | `alwaysAllowed`・`opensApp=false`、声と小窓が「61ページからです。」で一行と「羅生門」を含まない |
| AC-124 | R5 | 状態遷移 | H32 `ContinueReadingIntent` 実行→S-1 表示から 120秒後に `bookmark.start`→120秒後終了・`mark.later` | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC124_続きを読むインテントはしおり画面を開き始まった読書にintent_openを付ける | 前面 S-1 に一行と「p.61」が出て `flipMonitoring=on`・シート/alert 0個、残った記録の H17 `entry=intent_open` |
| AC-125 | R5 | 状態遷移 | H8 通信なし→`WhereStoppedIntent`→`StartReadingIntent`→120秒後 `EndReadingFromActivityIntent`→`mark.manual` 保存 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC125_オフラインでも外からの3つのインテントとしおり保存がすべて動く | 声が p.43 の文、H23 開始1件・終了1件、記録1件（2分）、H13 と H22 が新しい一行と p.61 に更新、alert・エラー要素0個 |
| AC-126 | R5 | ペアワイズ | 日本語・英語構成で H32 `registeredShortcuts` と `registeredControls` を確認 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC126_AppShortcuts3種とControl1種の登録内容と言い方を検証する | Shortcuts 3種すべてに `${applicationName}` が入り直後に「で」が続く日本語フレーズが0件、Control 1種が `kind=button`・`StartReadingIntent`・`control.startReading` |
| AC-127 | R1 | 同値分割と境界値 | 7件（6晩、合計142分、10/15 21:00 18分＋10/16 01:30 20分＝10/15 の晩 38分が最長）で `bookmark.finish`→カード共有 | 画面 | FinishAndRecommendationAcceptanceTests.swift::test_AC127_読み終えのふりかえり1行に晩数と合計時間と最長の晩が出てカードには載らない | S-9 の `finish.reflection` が `finish.reflection.multi`（「6晩」「142分（2時間22分）」「10月15日」「38分」）と一致し、H24 カード画像には「10月15日」「38分」が入らない |
| AC-128 | R1 | 同値分割と境界値 | (1)10/15 30分の1晩のみ (2)10/13 30分・10/14 10分・10/15 30分（最長30分が同点で2晩） | 画面 | FinishAndRecommendationAcceptanceTests.swift::test_AC128_ふりかえり1行の1晩のみの文言と同点最長晩の新しい日付選択を検証する | (1)は `finish.reflection.single`（「1晩」「30分」、日付なし）、(2)は `finish.reflection.multi`（「3晩」「70分（1時間10分）」、新しい「10月15日」「30分」） |
| AC-129 | R1 | 同値分割と境界値 | 記録0件の本 A で `bookmark.finish` を押下 | 画面 | FinishAndRecommendationAcceptanceTests.swift::test_AC129_記録が0件の本を読み終えたときはふりかえり1行を出さない | S-9 に `finish.reflection` が0個、`finish.colophon` は表示され、alert 0個 |
| AC-130 | R4 | 状態遷移 | `20:30`（今夜 21:00 予約あり）で `bookmark.start`：(1)背面復帰を挟み `21:05`（35分）で終了 (2)50秒（1分未満）で終了 | 画面 | WidgetAndActivityAcceptanceTests.swift::test_AC130_入口時刻前の読書開始で今夜の予約を取り消し終了時に予約を見直す | 開始時に予約取消1件・読書中の前面復帰では要求0件、(1)終了時は 35分記録＋翌 `10-19 21:00` 予約1件、(2)50秒終了時は `session.tooShort`＋今夜 `10-18 21:00` 予約1件が戻る |
| AC-131 | R5 | 状態遷移 | H23 で次の即時開始要求1回失敗→H32 `StartReadingIntent` 実行→120秒後 `reading.end` で終了 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC131_読み始めるインテントでLiveActivity要求が失敗したらアプリを開いて読書を続ける | `opensApp=true`・エラー文言なし・alert 0個で前面 S-2（`state=reading`）になり、終了後記録1件（2分）・`entry=intent_start` |
| AC-132 | R5 | 状態遷移 | インテント開始から 1,800秒後、H7 `session.end:1` で `EndReadingFromActivityIntent` 実行→+300秒後に S-2 の `reading.end` で終了 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC132_LiveActivityの終えるで保存失敗時は読書を消さずS2にエラーを出す | 失敗時は `state=reading` 維持・H23 終了要求0件・前面 S-2 に `session.save.error` 1個、300秒後の `reading.end` で 35分の記録1件と H23 終了要求1件 |
| AC-133 | R5 | 状態遷移 | H7 `store.load:1` で H32 `WhereStoppedIntent` 実行 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC133_どこまで読んだインテントで読込失敗時はエラー文言だけを返し書名やページを出さない | `opensApp=false`、声が `intent.whereStopped.error` と一致し、声と小窓に「61」・一行・「羅生門」を含まない |
| AC-134 | R5 | 状態遷移 | `22:00` に読み始めて 600秒後に背面へ→H32 `ContinueReadingIntent` 実行 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC134_読書中に続きを読むインテントを動かすと読書中の画面を出す | 前面に S-2（A の書名、`reading.end` 1個）が出て、`state=reading`・開始時刻 `22:00`・記録件数が保たれる |
| AC-135 | R5 | デシジョンテーブル | (1)積読のみで `current` 0冊 (2)本0冊→H32 `ContinueReadingIntent` 実行 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC135_今の本がないときに続きを読むインテントはしおり画面の空状態を出す | 前面 S-1 で `state=idle`、(1)は `bookmark.noCurrent.message`、(2)は `bookmark.empty.message` が出る |
| AC-136 | R5 | 状態遷移 | `22:00` インテント開始→翌 `04:30` 前面確認→`06:00` に H23 `dismissedBySystem`（8時間上限終了）→`07:00` 前面確認し終了 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC136_4時をまたぎLiveActivityが8時間上限で消えても読書は続き全分数が記録される | 04:30・07:00 とも `state=reading`（開始 22:00）、途中 H23 要求0件、終了後 H13 に記録1件・540分・晩 `10/18` |
| AC-137 | R3 | 状態遷移 | H19 で表紙3行（r1「新潮文庫」、r2「こころ」、r3「夏目漱石」）：(1)`register.cover` (2)`register.screenshot` で r2→r3 タップ・保存 | 画面 | RegistrationAcceptanceTests.swift::test_AC137_表紙写真とスクリーンショットから2タップで書名と著者を選んで登録できる | (1)(2)とも 1タップ目で書名「こころ」・2タップ目で著者「夏目漱石」が欄に入り、保存後 H13 で本1冊（`current`）、H27 画像ファイル0個 |
| AC-138 | R3 | デシジョンテーブル | 既存 A(`current`)、H19 背表紙4行から「こころ」(H20複数件)・「人間失格」(0件)・「羅生門」(H20で1件完全一致)の3行を選択・追加 | 画面 | RegistrationAcceptanceTests.swift::test_AC138_本棚の1枚の写真から複数の背表紙を選んで一括で積読に加え1件一致の書誌を補う | H13 で全4冊（選んだ3冊が `tsundoku`）、「羅生門」に「芥川龍之介」「新潮社」ISBN I3 が自動補完、「こころ」は書名のみ、H27 画像ファイル0個 |
| AC-139 | R6 | 状態遷移 | 本0冊で `register.later`→即 `reading`→1,200秒後終了し p.45 保存→S-1 と `bookmark.addBook` を確認 | 画面 | RegistrationAcceptanceTests.swift::test_AC139_書名をあとでにして今すぐ読み始められ名無しの本は1冊に制限される | `isTitlePending=true` で即 `state=reading`、S-2・S-1・H22・H23 の書名位置が `widget.currentBookAsTitle`（「今の本」）、保存後記録1件（20分・p.45）と `bookmark.setBookTitle` 1個、S-8 に2冊目の `register.later` は0個 |
| AC-140 | R6 | 状態遷移 | AC-139 の名無しの今の本（記録20分・p.45）で S-1 の `bookmark.setBookTitle`→バーコード I1（「こころ」）読取・保存 | 画面 | RegistrationAcceptanceTests.swift::test_AC140_名無しの今の本に後からバーコードで書名と奥付を入れると記録を保って更新される | H13 で本は1冊のまま `isTitlePending=false`・書名「こころ」・著者「夏目漱石」・新潮社・新潮文庫・2004・I1、記録20分と p.45 維持、H22 も「こころ」で `bookmark.setBookTitle` 0個 |
| AC-141 | R3 | 同値分割と境界値 | 電子書籍 A（`isEbook=true`、18分読書）：(1)`location` 1200→1450 (2)`percent` 34→52 (3)境界値 `location` 0/1000000、`percent` -1/101/0/100 | 画面 | BookmarkAcceptanceTests.swift::test_AC141_電子書籍の位置番号とパーセントのしおり保存と境界値を検証する | (1)S-4「位置1200 → 位置1450　18分」・S-1/H22「位置1450」、(2)S-4「34% → 52%　18分」・S-1/H22「52%」、(3)範囲外4つは `mark.page.invalid` 1個、0と100は「0%」「100%」で保存 |
| AC-142 | R3 | 状態遷移 | カメラ拒否（H26 `denied`）、H19 縦4列（c4「下人の行方は、誰も知らない。」）→`mark.screenshot`→p.61 保存 | 画面 | BookmarkAcceptanceTests.swift::test_AC142_カメラ拒否でもスクリーンショットから一行を選んで保存でき画像を残さない | 許可 alert 0個、`mark.ocr.column.4` が初期選択され、保存後 H13 が該当一行と p.61 に更新、H27 画像ファイル0個 |
| AC-143 | R4 | 同値分割と境界値 | 電子書籍 A（`idle`）で `WhereStoppedIntent`：(1)`location=1450` (2)`percent=52` | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC143_電子書籍の位置番号とパーセントに応じてどこまで読んだインテントが答える | 声と小窓が (1)`intent.whereStopped.location`（「位置1450からです。」）、(2)`intent.whereStopped.percent`（「52パーセントからです。」）と一致し一行と書名を含まない |
| AC-144 | R2 | 状態遷移 | 電子書籍 A（`isEbook=true`）で S-1 表示→`bookmark.start` で S-2 表示→600秒後に Live Activity の `liveActivity.end` で終了 | 画面 | SettingsStoreIntentsAcceptanceTests.swift::test_AC144_電子書籍のしおり画面と読書中画面に専用案内が出てLiveActivityから終えられる | S-1 に `bookmark.flipHint.ebook` が1個、S-2 に `reading.ebookNote` が1個出て、`liveActivity.end` 終了後に記録1件（10分）が残る |
| AC-145 | R8 | 状態遷移 | `current` 0冊、直近読了 A（恩田陸）、積読4冊（R, S, P[恩田陸], T）で S-1 を開く→1番目 P の `bookmark.noCurrent.choose` を押下 | 画面 | FinishAndRecommendationAcceptanceTests.swift::test_AC145_今の本が0冊で積読があるときしおり画面に最大3冊出て1タップで今の本になる | S-1 に `bookmark.noCurrent.message` と候補3件（上から P, R, S）が出て、P を押すと H13 で P が `current` になり S-1 に P の `bookmark.title` と `bookmark.start` が出る |
| AC-146 | R8 | デシジョンテーブル | 読了 A（恩田陸・直木賞156回）、H20 同著者3冊（U1〜U3）、H25 同賞3冊（N1〜N3）→S-7 を開き U1 の `after.addToShelf` を押下 | 画面 | FinishAndRecommendationAcceptanceTests.swift::test_AC146_読み終えた本の詳細画面にこの本のあとにが最大5冊出てその場で積読に加えられる | `after.header` の下に `after.candidate` が上限5件（理由が偏らず選出）、U1 押下で H20 書誌つきで `tsundoku` に加わりボタンが `after.added` に替わる |
| AC-147 | R8 | デシジョンテーブル | H2 で重み `sameAward`（`chosen=3, skipped=0`, score +6）、`sameAuthor`（`chosen=0, skipped=3`, score -3）→`bookmark.finish` | 画面 | FinishAndRecommendationAcceptanceTests.swift::test_AC147_端末内の重み付けでよく選ぶ理由の候補が既定の順より上に繰り上がる | `next.candidate` の1番目が N1（理由「同じ賞」）、2番目が U1（理由「同じ著者の本」）に入れ替わる |
| AC-148 | R8 | 同値分割と境界値 | H20 共起テーブル：I1 から (1)I2（NDC `913.6`, `count=12`） (2)I3（NDC `913.6`, `count=9`） (3)I4（NDC `336`, `count=25`）→`bookmark.finish` | 画面 | FinishAndRecommendationAcceptanceTests.swift::test_AC148_共起テーブルから文学NDC9かつ10人以上の本だけを人数を出さずに推薦する | `rec.reason.readers`（「この本を読み終えた人が、次に読んだ本」）で出るのが I2（「夜のピクニック」）1冊のみで、I3・I4 は0個、画面に「12」「12人」の数字が入らない |
| AC-149 | R10 | 同値分割と境界値 | H20 有効・Perf 構成で (1)H21 バーコード I1 注入から `scan.row` 表示まで5回 (2)`manual.title` に「人間失格」入力から `search.row` 表示まで5回 | 画面 | PerformanceTests.swift::test_AC149_端末内書誌DBのISBN検索と書名検索の5回平均が300ミリ秒以内 | H10 `barcodeLookup` と `titleSearch` の5回平均がどちらも 0.3秒（300ms）以内 |

## 3. 試す状態
全行で「自動」「G4 の人」「範囲外」のどれかを選ぶ。範囲外には理由を書く。空欄は不可。
| 状態 | 選んだもの | 作り方 | どのテストで、または理由 |
|---|---|---|---|
| 初めて起動 | 自動 | `xcrun simctl erase` で端末を初期化して起動（H14）または `-uitest-reset`（H1） | `FirstLaunchTests.swift::test_AC1_初回起動で空のしおり画面が出て許可ダイアログが出ない` |
| データがある | 自動 | 環境変数 `UITEST_SEED`（H2）または `-uitest-seed-preset perf500` で決まった本・記録・設定・推薦重みを投入 | AC-3, AC-7, AC-13〜AC-64, AC-75〜AC-91, AC-93, AC-95〜AC-102, AC-104, AC-113〜AC-125, AC-127〜AC-136, AC-138, AC-140〜AC-148 の各テスト |
| 前の版からの更新（版を飛ばす更新も） | 範囲外 | 前のタグのビルドでデータを作り、上から入れる | 001-reading-session が最初の機能（v1.0 初回リリース）であり、前の版のタグが存在しないため |
| オフライン、サーバーエラー（500、タイムアウト） | 自動 | 起動引数 `-uitest-offline` または Darwin 通知 `yomuma.uitest.offline`（H8）、および H20 `status=notDownloaded`、H30 商品取得失敗 | `test_AC6_機内モードでも端末内書誌DBでバーコード登録が動く`、`test_AC9_書誌DB未取得時にその場で書名を入れて追加できる`、`test_AC62_オフラインでもウィジェット起動からしおり保存まで完走する`、`test_AC110_オフラインで商品を読めないときは案内を出し読書は妨げない`、`test_AC125_オフラインでも外からの3つのインテントとしおり保存がすべて動く` |
| 権限を断った（その場で、あとから設定で） | 自動 | カメラ許可差し替え `-uitest-camera denied`（H26）、Live Activity オフ `UITEST_LIVE_ACTIVITY` `areActivitiesEnabled=false`（H23）、決済不可 `canMakePayments=false`（H30） | `test_AC12_カメラ拒否時に設定とスクショと手入力の導線が出る`、`test_AC37_LiveActivityオフ時は予約要求を出さず設定に案内を出す`、`test_AC70_しおり撮影でカメラ拒否時にスクショと手入力の導線が出る`、`test_AC109_決済不可の端末では購入ボタンを出さず案内を出す`、`test_AC118_LiveActivityオフ時の読み始めるインテントは読書を開始し前面可ならS2を出す`、`test_AC142_カメラ拒否でもスクリーンショットから一行を選んで保存でき画像を残さない` |
| バックグラウンドから復帰 | 自動 | `XCUIDevice.shared.press(.home)` の後に H5 で時計を進め `app.activate()` で復帰 | `test_AC40_入口のURLと300秒境界で記録の入口の印が決まる`、`test_AC52_バックグラウンドの間も開始時刻からの差で時間を数える`、`test_AC97_LiveActivity予約失敗時はアラートを出さず次回前面復帰時に予約し直す`、`test_AC98_読まなかった晩のLiveActivityは翌朝前面復帰で終了し今夜分を予約する`、`test_AC111_購入が返金されると前面復帰時に標準の見た目へ戻る`、`test_AC130_入口時刻前の読書開始で今夜の予約を取り消し終了時に予約を見直す`、`test_AC136_4時をまたぎLiveActivityが8時間上限で消えても読書は続き全分数が記録される` |
| 言語と地域（ja、en） | 自動 | `AcceptanceTests.xctestplan` の構成（Japanese `ja` / `ja_JP`、English `en` / `en_US`）と `-uitest-timezone`（H6） | `test_AC22_4時境目の晩の日付とタイムゾーン変更不変を検証する`、`test_AC93_設定画面にNDLの3条件とCCBYリンクが出てしおり画面と読書中画面には出ない`、`test_AC126_AppShortcuts3種とControl1種の登録内容と言い方を検証する`、および G3 での ja/en 両構成実行 |
| 大きい文字、ダークモード | 自動 | `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge`（AX5）と `xcrun simctl ui booted appearance dark` | G3 の全画面スクリーンショット採取（`<画面>_<状態>_<light\|dark\|ax5\|en>.png`）および `performAccessibilityAudit()` 検査 |
| 容量不足、電話などの割り込み | 自動 | `-uitest-fail-save <対象>:<回数>:disk_full`（H7）による保存・読込失敗注入 | `test_AC59_読み始めの保存失敗時はidleのままエラーを出す`、`test_AC60_終わりの保存失敗時は読書中を保ち再試行で合算保存される`、`test_AC90_起動時の保存先読込失敗でエラーを出し再起動で元のデータが戻る`、`test_AC91_7種類の保存失敗時にエラーが出て変更前のデータが保たれる`、`test_AC95_読後のしおり保存失敗時も記録は残り入力値を保ったまま再保存できる`、`test_AC119_読み始めるインテントで保存失敗時はエラーを返しLiveActivityを出さない`、`test_AC132_LiveActivityの終えるで保存失敗時は読書を消さずS2にエラーを出す`、`test_AC133_どこまで読んだインテントで読込失敗時はエラー文言だけを返し書名やページを出さない` |

## 4. テストのつなぎ口と接続先
テストが状態を作るために使うもの。contracts/ にないものは、tech-lead への依頼として報告の「未解決」に書く。
（注：H3 は H2 の `activeSession` に統合されたため欠番、H11 は v1.0 で外部への計測送信を行わないため欠番。残り30個はすべて `contracts/test-hooks.md` 第2章に定義済みで、未解決は0件）
| 何（初期化、データの投入、接続先、時刻の固定） | 名前（launch argument、環境変数、API） | contracts/ の場所 |
|---|---|---|
| H1 データの初期化 | 起動引数 `-uitest-reset` | `contracts/test-hooks.md` 2章 H1 |
| H2 データの投入（本・記録・設定・推薦重み・読書中状態） | 環境変数 `UITEST_SEED` / 起動引数 `-uitest-seed-preset perf500` | `contracts/test-hooks.md` 2章 H2、`contracts/hooks/h02-seed.schema.json` |
| H4 時刻の固定 | 起動引数 `-uitest-now <RFC 3339>` | `contracts/test-hooks.md` 2章 H4 |
| H5 時刻を進める | Darwin 通知 `yomuma.uitest.clock` | `contracts/test-hooks.md` 2章 H5 |
| H6 タイムゾーンの固定 | 起動引数 `-uitest-timezone <IANA名>` | `contracts/test-hooks.md` 2章 H6 |
| H7 保存・読込の失敗を起こす | 起動引数 `-uitest-fail-save <対象>:<回数>[:<種類>]` | `contracts/test-hooks.md` 2章 H7 |
| H8 通信なし（機内モード模擬） | 起動引数 `-uitest-offline` / Darwin 通知 `yomuma.uitest.offline` | `contracts/test-hooks.md` 2章 H8 |
| H9 状態（`idle`/`reading`・自動ロック・近接）を読む | 要素 `hook.state` | `contracts/test-hooks.md` 2章 H9、`contracts/hooks/h17-state.schema.json` |
| H10 区間の時間を測る・読む | 要素 `hook.state` の `lat.<区間>` / `prevLat.<区間>` / `-uitest-readouts off` | `contracts/test-hooks.md` 2章 H10、`contracts/hooks/h17-state.schema.json` |
| H12 文言キーと識別子の対応 | `Localizable.xcstrings` と同一キーの `accessibilityIdentifier` | `contracts/test-hooks.md` 2章 H12、`design/001-reading-session.md` 6・7章 |
| H13 保存先の全項目と写しを読む | 要素 `hook.store` | `contracts/test-hooks.md` 2章 H13、`contracts/hooks/h13-store.schema.json` |
| H14 初めて起動した端末を作る | `xcrun simctl erase <端末>`（専用実行） | `contracts/test-hooks.md` 2章 H14 |
| H15 伏せた向きを起こす | `XCUIDevice.shared.orientation = .faceDown` / `.portrait` | `contracts/test-hooks.md` 2章 H15 |
| H16 伏せの待ちの時計（1.0秒判定） | H4 + H5 連動 | `contracts/test-hooks.md` 2章 H16 |
| H17 合図（触覚・読み上げ・知らせ）と監視状態を読む | 要素 `hook.state` | `contracts/test-hooks.md` 2章 H17、`contracts/hooks/h17-state.schema.json` |
| H18 伏せの検知を使えない状態のまね | 起動引数 `-uitest-flip-unavailable` | `contracts/test-hooks.md` 2章 H18 |
| H19 写真・スクショの OCR 結果差し替えと保留 | 環境変数 `UITEST_OCR` / Darwin 通知 `yomuma.uitest.ocr.release` | `contracts/test-hooks.md` 2章 H19、`contracts/hooks/hook-config.schema.json` |
| H20 端末内書誌 SQLite DB と共起テーブルの差し替え | 環境変数 `UITEST_NDL_STUB` | `contracts/test-hooks.md` 2章 H20、`contracts/hooks/h20-ndl-stub.schema.json` |
| H21 バーコード（ISBN・2段目 Cコード）読取の差し替え | 起動引数 `-uitest-barcode-fake` / Darwin 通知 `yomuma.uitest.barcode` | `contracts/test-hooks.md` 2章 H21 |
| H22 ウィジェットの中身・組版・画像の読み出し | 起動引数 `-uitest-widget`・`-uitest-widget-show` / 環境変数 `UITEST_WIDGET_SNAPSHOT` / 要素 `hook.widget` | `contracts/test-hooks.md` 2章 H22、`contracts/hooks/h22-widget.schema.json` |
| H23 Live Activity の要求記録と状態遷移差し替え | 環境変数 `UITEST_LIVE_ACTIVITY` / Darwin 通知 `yomuma.uitest.liveactivity.transition` / 要素 `hook.liveActivity` | `contracts/test-hooks.md` 2章 H23、`contracts/hooks/hook-config.schema.json` |
| H24 共有シートに渡した読み終えカード画像の検査 | 要素 `hook.shareCard` | `contracts/test-hooks.md` 2章 H24、`contracts/hooks/hook-config.schema.json` |
| H25 受賞の一覧の差し替えと読み出し | 環境変数 `UITEST_AWARDS` / 要素 `hook.awards` | `contracts/test-hooks.md` 2章 H25、`contracts/hooks/hook-config.schema.json` |
| H26 カメラの許可の状態の差し替え | 起動引数 `-uitest-camera <状態>[:<答え>]` | `contracts/test-hooks.md` 2章 H26 |
| H27 保存領域・App Group の画像ファイル数と写真書込回数の検査 | 要素 `hook.mediaAudit` | `contracts/test-hooks.md` 2章 H27、`contracts/hooks/hook-config.schema.json` |
| H28 入口の URL で起動する | `app.open(URL(string: "yomuma://open?entry=...")!)` | `contracts/test-hooks.md` 2章 H28、`contracts/entry-urls.md` |
| H29 アプリが出した外部 HTTP 通信要求の記録（0件検証） | 要素 `hook.outbound` の `requests` | `contracts/test-hooks.md` 2章 H29、`contracts/hooks/h29-outbound.schema.json` |
| H30 StoreKit 2 の差し替えと返金通知 | 環境変数 `UITEST_STOREKIT` / Darwin 通知 `yomuma.uitest.storekit.refund` / 要素 `hook.storekit` | `contracts/test-hooks.md` 2章 H30、`contracts/hooks/hook-config.schema.json` |
| H31 アプリが開いた外部 URL の記録 | 要素 `hook.outbound` の `openedURLs` / 起動引数 `-uitest-openurl passthrough` | `contracts/test-hooks.md` 2章 H31、`contracts/hooks/h29-outbound.schema.json` |
| H32 アプリの外からのインテント（App Intents）の駆動と検査 | 環境変数 `UITEST_INTENT` / 起動引数 `-uitest-run-intent` / Darwin 通知 `yomuma.uitest.intent.run` / 要素 `hook.intents` | `contracts/test-hooks.md` 2章 H32、`contracts/hooks/hook-config.schema.json` |

## 5. 動かすコマンドと設定
受け入れテストは、受け入れテストのフォルダの中の設定だけで動かす（作り手の conftest.py やスキームに左右されないため）。
- iOS：`make ios-test`（`.claude/org/app.json` の `commands.ios_test` と同じ。内部で `ios/AcceptanceTests/AcceptanceTests.xctestplan` を指定して `xcodebuild test` を動かす。実行順はランダム `random`、Automatic Screen Capture はオン `.keepAlways`、再試行なし）
- バックエンド：なし（このアプリはサーバーを持たず端末内で完結するため、`paths.backend` は未使用）
- 判定の実行では再試行を付けない（`-retry-tests-on-failure` を付けない）。
- 揺れの確認：iOS は `-test-iterations 5 -run-tests-until-failure` を付けて、影響「大」の AC のテストと一度でも落ちたテストを5回連続で動かす。

## 6. 探索のチャーター
影響「大」のリスクごとに1本。G3 で行い、結果は verification.md の8章に書く。
| リスク | チャーター（<対象> を <手段や条件> で探り、<知りたいこと> を見つける） | 区切り（30分か40操作） |
|---|---|---|
| R1 | 読書時間と晩の計算（S-1〜S-4、S-7、S-9）を、4:00 前後の連続読書・バックグラウンド移行・強制終了・タイムゾーン変更・記録編集と削除を組み合わせる操作で探り、合計分数・何晩・ふりかえり1行の食い違いを見つける | 30分または40操作 |
| R2 | 伏せて始める動作（S-1、S-2、各シート）を、0.9秒/1.0秒の連続反転・シート開閉直後の伏せ・電子書籍モード・設定オンオフ切り替えで探り、誤開始や `flipMonitoring` の切り忘れを見つける | 30分または40操作 |
| R3 | しおり保存と OCR（S-3、S-3a〜S-3c、S-7c、S-8b、S-8d）を、OCR 待ち中の別導線遷移・カメラ拒否時のスクショ選択・単位（ページ/位置/％）切り替え・キャンセル連打で探り、入力値の消失や一時画像ファイルの残存を見つける | 30分または40操作 |
| R4 | ウィジェットと Live Activity（W-1〜W-3、S-1、S-10）を、25字/26字/禁則文字・欧文混在・`hideOnWidgets` 切り替え・夜の入口時刻変更で探り、文字欠けやロック画面への書名・一行の漏洩を見つける | 30分または40操作 |
| R5 | App Intents（`StartReadingIntent`、`EndReadingFromActivityIntent`、`WhereStoppedIntent`、`ContinueReadingIntent`）を、アプリ前面中・背面中・予約 Live Activity 表示中・保存失敗注入下で交互に呼び出して探り、二重セッションや状態の不整合を見つける | 30分または40操作 |
| R6 | 本と記録の永続化（S-1、S-6〜S-10）を、`register.later`（名無しの今の本）からの書名後付け・本の削除・H7 保存失敗後の再試行・機内モード切り替えで探り、データ破損や外部通信の発生を見つける | 30分または40操作 |

## 7. 画面で確かめるもの
自動のテストで確かめにくいもの。G3 でスクリーンショットを docs/verification/001-reading-session/evidence/ に撮る。あわせて G4 で Takuma が実機で確かめる G4-1〜G4-22 の一覧を示す。
| AC | 手順 | 撮るスクリーンショットのファイル名（AC3_オフライン.png の形） |
|---|---|---|
| AC-1 | 初回起動（本0冊）で S-1 を表示し、ライト・ダーク・AX5・英語の4通りで撮る | `S1_empty_light.png`、`S1_empty_dark.png`、`S1_empty_ax5.png`、`S1_empty_en.png` |
| AC-27, AC-28, AC-29 | `-uitest-widget-show accessoryRectangular:153x68` と `172x76` で縦書き一行と禁則・縮め方を表示して撮る | `AC27_W1_153x68.png`、`AC27_W1_172x76.png`、`AC28_W1_kinsoku.png`、`AC29_W1_truncated.png` |
| AC-34 | `settings.hideOnWidgets=true` の W-1・W-2 と S-1 を表示して撮る | `AC34_W1_hidden.png`、`AC34_S1_visible.png` |
| AC-35 | `-uitest-widget-show systemSmall:148x148` と `170x170` を表示して撮る | `AC35_W2_148x148.png`、`AC35_W2_170x170.png` |
| AC-43, AC-144 | S-2（読書中の画面：紙の本・電子書籍）をライト・ダーク・AX5・英語で撮る | `S2_reading_light.png`、`S2_reading_dark.png`、`S2_reading_ax5.png`、`S2_reading_en.png`、`AC144_S2_ebook.png` |
| AC-63, AC-65, AC-141 | S-3（5つの道）、S-3c（縦書き列の枠選択）、S-3a/S-3b（位置・％入力）と S-4（結果画面）を撮る | `S3_choices_light.png`、`AC65_S3c_ocr.png`、`AC141_S4_location.png`、`S4_result_light.png` |
| AC-13, AC-17, AC-146 | S-6（本棚3区分）と S-7（奥付・記録・「この本のあとに」）をライト・ダーク・AX5・英語で撮る | `S6_shelf_light.png`、`S6_shelf_dark.png`、`S7_book_light.png`、`AC146_S7_after.png` |
| AC-77, AC-78, AC-84, AC-127 | S-9（読み終えた画面：ふりかえり1行・奥付・次の1冊）と共有カード画像を撮る | `S9_finish_light.png`、`S9_finish_dark.png`、`AC84_finish_card.png` |
| AC-88, AC-93, AC-105, AC-106 | S-10（設定・NDL 出典）と S-10a（見た目見本 `store.preview`・購入シート・生成り/墨/朱）を撮る | `S10_settings_light.png`、`AC93_S10_dataSources.png`、`AC105_S10a_preview.png`、`AC106_S1_kinari.png` |
| G4-1〜G4-22（実機確認） | PRD 11章末尾の表（G4-1 ロック画面ウィジェット、G4-2 5秒以内ロック反映、G4-3 StandBy、G4-4 機内モード連続登録、G4-5 カメラ拒否とスクショ導線、G4-6 翌晩の予約 Live Activity、G4-7 机・ベッド・膝での伏せ開始、G4-8 ロック中計測、G4-9 端末再起動後計測、G4-10 手元の本10冊バーコード・表紙・本棚・奥付撮影、G4-11 自動ロック消灯、G4-12 文庫本5枚 OCR 速度、G4-13 VoiceOver 読み上げ、G4-14 誤開始回数記録、G4-15 最古対応機種での速度60fps録画計測、G4-16 LINE カード共有、G4-17 iCloud バックアップ復元、G4-18 ウィジェット/Live Activity タップ遷移、G4-19 Sandbox 購入と復元、G4-20 App プライバシーレポート外部通信0件、G4-21 ロック中の Control/Action ボタン/Siri「読み始める」と「終える」、G4-22 ロック中の Siri「どこまで読んだ？」「続きを読む」）を Release ビルドの実機で行う | `docs/verification/001-reading-session/evidence/g4/` 配下の実機スクリーンショットおよび60fps録画 |

## 8. 赤の証拠（実装の前に落ちたこと）
- ログ：`docs/verification/001-reading-session/evidence/red.log`
- 実行したコマンドと終了コード：`make ios-test`（終了コード：`1`）
- 落ちた理由（1行。「機能がまだない」ことを示す。例：識別子 save_button が見つからない、404）：`ERROR: ios/ReadingApp.xcodeproj does not exist yet`（機能がまだない）

## 9. 範囲の外
- 前の版からのデータ移行・マイグレーション：この機能（`001-reading-session`）がアプリの最初の機能（v1.0 初回リリース）であり、前の版のビルドや旧スキーマが存在しないため範囲外とする。
- サーバー API の受け入れテスト（`backend/tests/acceptance/`）：このアプリはサーバーやアカウントを持たず、書誌検索（Background Assets の端末内 SQLite DB）を含めすべて iPhone 端末内で完結するため（PRD 11章・AC-103）。
- 実機の物理センサー・ロック画面描画・Siri 音声認識・StoreKit Sandbox・App プライバシーレポートの実機挙動：シミュレーターでは決まらないため、7章および PRD 11章の G4-1〜G4-22 として G4 で Takuma が実機で検証する。

## 確かめ（提出前に verifier が印を付ける。reviewer はこれを信じずに確かめる）
- [x] 読んだファイルが PRD、design/、contracts/ だけで、冒頭に全部並んでいる。
- [x] PRD のすべての AC 番号が、2章とテストの名前にある。AC のないテストがない。
- [x] 2章の全行に、技法、試す値、具体的な値の結果がある。「正しく」「適切に」だけの結果がない。
- [x] 影響「大」のリスクのすべてに、自動テスト、3章の行、6章のチャーターがある。
- [x] 3章の9行すべてに選んだものがあり、範囲外には理由がある。
- [x] 4章のつなぎ口がすべて contracts/ にあるか、「未解決」に依頼として書いた。
- [x] 受け入れテストのフォルダで、sleep、skip、xfail、XCTExpectFailure、retry、@testable import が0件（grep のコマンドと件数を報告に書いた）。
- [x] 8章の赤の証拠があり、落ちた理由が書き間違いではなく「機能がまだない」こと。
