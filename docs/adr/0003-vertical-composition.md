# ADR-0003: 縦書き組版・4つの見た目・読み終えカード描画・端末内 Vision OCR

- 日付：2026-10-25
- 状態：採用
- 関連する機能：`docs/prd/001-reading-session.md`（AC-24〜35、AC-53〜54、AC-65〜70、AC-84〜85、AC-94、AC-99〜102、AC-104〜111、AC-113、AC-127、AC-137〜138、AC-141〜142）、`design/001-reading-session.md`

## 背景

「よむま」は日本の紙の小説に馴染む「紙の側」の佇まいを核としつつ、ウィジェットの厳しいメモリ制約（30MB）、アクセシビリティ（VoiceOver 連続読み上げ、Dynamic Type AX5、コントラスト比 4.5:1 / 3:1）、および端末内完結の OCR（ページ撮影・スクリーンショット選択・表紙撮影・本棚の背表紙まとめ撮り・奥付撮影）と読み終えカード画像生成をすべて標準フレームワークだけで実現する必要がある。

## 考えた選択肢と比べた結果

| 領域 | 選択肢 | 良い点 | 悪い点 | 判断 |
|---|---|---|---|---|
| **1. 縦書き1行の描画（W-1、W-2、S-1、S-5）** | **A. SwiftUI `Canvas` / カスタム `Layout` で書記素クラスタ単位に座標配置し、約物・小書き仮名をテーブル変換する（採用）** | - `UIViewRepresentable` が使えない WidgetKit（W-1、W-2）と本体（S-1、S-5）で 100% 同じ純粋関数コード（`VerticalLineLayout`）を共有できる<br>- 最大 60 字×最大 3 列に限定されるため、計算コストが 0.2ms 未満<br>- VoiceOver ラベルと `accessibilityIdentifier` を外側の View に 1 つだけ付与できる（AC-28、AC-99） | - 縦中横やルビは扱えない（ただし対象は最大 60 字の「しおりの一行」のみであり不要） | **採用** |
| | B. `UITextView` / `NSTextLayoutManager` の縦書きモードを `UIViewRepresentable` で包む | - OS の縦書き組版を使える | - WidgetKit（W-1、W-2）では `UIViewRepresentable` が動作しないため、本体とウィジェットで別実装になる | 却下 |
| **2. 端末内 OCR（S-3c、S-7c、S-8b、S-8d）** | **A. `Vision` フレームワーク `VNRecognizeTextRequest`（Revision 3、`.accurate`、`["ja-JP", "en-US"]`）＋用途別クラスタリング（採用）** | - 完全オフライン・端末内メモリ完結で動作し、外部送信ゼロ（AC-69、AC-103）<br>- Release 構成で 1 枚あたり平均 0.5〜0.9 秒で完了し、AC-94（1.5 秒以内）を満たす<br>- 本棚の背表紙（S-8d）では `minimumTextHeightFraction = 0.005` を指定することで細い縦書き背表紙も漏れなく拾える（G0 提案 1） | - 縦書きページの列順序（右から左）とノンブル分離を後処理で整える必要がある（`ReadingCore` の純粋関数で実装・単体テスト可能） | **採用** |
| | B. クラウド OCR API または独自 CoreML モデルの同梱 | - 独自学習モデルを持てる | - クラウド API は AC-69・AC-103（外部通信ゼロ・画像外部送信ゼロ）に違反する。独自モデルはアプリサイズを肥大化させる | 却下 |
| **3. 読み終えカード画像（S-9）** | **A. SwiftUI `ImageRenderer`（`scale = 3.0`、360×450pt → 1080×1350px PNG）＋ `ShareLink`（採用）** | - 奥付の型（S-7 / S-9 と同じレイアウト）を宣言的 View から直接 1080×1350px の PNG `Data` に変換でき、しおりの一行やふりかえり文を含めない制約（AC-84、AC-127）を型レベルで保証できる | - なし | **採用** |

## 決めたこと

### 1. 縦書き 1 行組版エンジン（`ReadingCore.VerticalLineLayout`）

1. **入力文字列の正規化（AC-53、AC-54）**：
   - 改行（`\r\n`、`\n`、`\r`）とタブはすべて半角空白 `" "` に置換し、前後の空白を除去した上で、Swift の `Character`（書記素クラスタ）単位で先頭 60 文字に切り詰める。
2. **列割りと折り返し規則（AC-24〜33、AC-100）**：
   - **W-1（`.accessoryRectangular`）**：1 列あたり最大 20 字、最大 3 列（右から左へ列を進める）。フォントは `HiraMinProN-W6`（1〜2 列は 17pt、3 列は 15pt 固定、列間 4pt）。
   - **W-2（`.systemSmall`）**：1 列あたり最大 15 字、最大 3 列（右から左）。フォントは `HiraMinProN-W6`（1〜2 列は 20pt、3 列は 19pt 固定、列間 6pt）。
   - **S-1（`bookmark.line`）**：1 列あたり最大 20 字、最大 3 列（右から左）。基準 28pt（Dynamic Type `.title` に追従、列間 12pt）。フォントは見た目（`appearanceID`）に応じて `HiraMinProN-W3`（`default`）、`ShipporiMinchoB1-Regular`（`kinari` / `sumi`）、`KleeOne-Regular`（`shu`）を切り替える。
   - **行頭禁則**：列の先頭に来る句読点（`、。，．`）および閉じ括弧（`」』）】〕`）は前の列の末尾にぶら下げる。
   - **横書きへの自動フォールバック（AC-28、AC-100）**：S-1 において `@Environment(\.dynamicTypeSize).isAccessibilitySize == true`（`accessibility1` 以上）のとき、または拡大後の列幅合計が利用可能横幅を超えるときは、自動的に標準の横書き `Text`（左揃え・複数行折り返し）に切り替える。
3. **縦書きグリフ変換・回転**：
   - 長音符 `ー`、波ダッシュ `〜` / `～`、三点リーダ `…`、二点リーダ `‥`、ダッシュ `―` / `–` / `-`、括弧類 `「」『』（）〔〕【】〈〉《》` は 90 度時計回り回転（および中心補正）で描画する。
   - 句読点 `、。，．` はセル右上象限（`dx: +0.32em, dy: -0.32em`）、小書き仮名 `っゃゅょぁぃぅぇぉッャュョァィゥェォ` は右上寄り（`dx: +0.10em, dy: -0.08em`）に配置する。
4. **進み具合の表記（AC-24、AC-141）**：
   - `progressUnit == .page`：`p.<page>`（例：`p.61`）
   - `progressUnit == .location`：日本語 `位置<location>`／英語 `Loc <location>`（例：`位置1450`）
   - `progressUnit == .percent`：`<percent>%`（例：`52%`）
   - 値がないときは場所の表示自体を出さない（`nil`）。
5. **VoiceOver とプライバシーマスク（AC-28、AC-34、AC-99、AC-139）**：
   - 縦書き View 全体に `.accessibilityElement(children: .ignore)` を付け、1 つの連続した文字列として読み上げる。
   - `hideOnWidgets == true` のとき、W-1・W-2・W-3 には書名も一行も描画せず、`widget.hidden`（「しおり」／「Bookmark」）と場所（または経過時間）だけを描画する（AC-34、AC-41、AC-120）。
   - `isTitlePending == true`（あとで登録）のとき、書名の位置には `widget.currentBookAsTitle`（「今の本」／「Reading Now」）を出す（AC-139）。

### 2. 4つの見た目（`AppearanceID`）と「よむま＋」（AC-104〜111）

- `AppearanceID` は `default`（標準：白と黒）、`kinari`（生成り）、`sumi`（墨）、`shu`（朱）の 4 種類とする。
- 各見た目のライト／ダーク／ハイコントラスト（`colorSchemeContrast == .increased`）の HEX 値とコントラスト比は `design/001-reading-session/tokens.md` の定義をそのまま `ReadingCore.ThemeTokens` に定数化する（すべての文字が 4.5:1 以上、主操作の塗りと枠が 3:1 以上）。
- `kinari`・`sumi`・`shu` は StoreKit 2 の非消耗型（買い切り）商品 `yomuma.plus`（基準価格 ¥980）の購入または復元が完了しているとき（`isPlusPurchased == true`）のみ適用できる。未購入時は S-10a で `store.preview` の見本表示と購入シートを表示する（AC-105〜110）。
- 毎晩の導線（S-1〜S-5）および読み終えの画面（S-9）には課金バナーやアップセルを一切出さない（AC-104）。

### 3. 読み終えカードの画像描画（AC-84、AC-85、AC-127）

- S-9 の「読み終えのカードを共有」（`finish.card.share`）を押したとき、`FinishCardView`（360×450pt、`scale = 3.0` で **1080×1350px** の不透明 PNG）を `ImageRenderer` でレンダリングする。
- **カードに含める項目**：書名、および値が存在する奥付項目（著者、出版社・レーベル、出版年、受賞歴、読了日、読書期間・晩数・合計分数）のみ。現在選択中の `appearanceID` の色トークンとフォントを適用する。
- **カードに絶対に含めない項目（AC-84、AC-127）**：
  - 保存した本の一行（`lastLine`）：著作権保護のため `FinishCardView` のイニシャライザ自体に `lastLine` を渡さない。
  - ふりかえりの 1 行文（`finish.reflection`）：画面 S-9 上にのみ表示し、共有カード画像には描かない（AC-127）。

### 4. 端末内 Vision OCR パイプラインと画像非保持（AC-65〜70、AC-94、AC-113、AC-137〜138、AC-142）

すべての文字認識は `VNRecognizeTextRequest`（Revision 3、`recognitionLevel = .accurate`、`recognitionLanguages = ["ja-JP", "en-US"]`、`usesLanguageCorrection = true`）をバックグラウンド Task で実行し、**1.5 秒以内**（AC-94）に結果を返す。

| 画面・用途 | 入力経路 | 認識パラメータと後処理アルゴリズム |
|---|---|---|
| **S-3c ページの1行とページ番号（AC-65〜68、AC-142）** | カメラ（`mark.photo`）または `PhotosPicker(matching: .screenshots)`（`mark.screenshot`） | 1. 画面上下端（正規化座標 `y > 0.88` または `y < 0.12`）にある `1...9999` の単独数字（または `p.61` / `- 61 -`）をノンブルとして分離し、最大値を `mark.pageField` の初期値に入れる（AC-68）。<br>2. 残りのテキスト矩形を縦書き列（X 中心座標の近接クラスタ）または横書き行としてグループ化し、**右の列から左の列へ**（横書きは上から下へ）1 始まりの番号を振って `mark.ocr.column.1`〜`<n>` として返す（AC-65）。<br>3. 選んだ列の文字列は改行を空白に正規化し 60 字以内に切り詰めて `mark.lineField` に入れる（AC-66）。認識文字が 0 件のときは `mark.ocr.empty` と `mark.retake` / `mark.manualFallback` を出す（AC-67）。 |
| **S-8b 表紙・背表紙・スクショから書名と著者（AC-137）** | カメラ（`register.cover`）または `PhotosPicker`（`register.screenshot`） | 認識した行を面積・位置順に `cover.ocr.line.1`〜`<n>` として枠表示する。1 タップ目（`cover.selectTitle`）で `manual.title`、2 タップ目（`cover.selectAuthor`）で `manual.author` に入れ、`cover.save` で保存する。 |
| **S-8d 本棚・積読の複数冊背表紙（AC-138、G0 提案 1）** | カメラ（`register.bookshelf`） | **`request.minimumTextHeightFraction = 0.005`**（既定の約 `1/32` から引き下げ）を指定し、本棚全体の写真に写った細い背表紙の文字列も漏れなく検出する（G0 提案 1）。背表紙ごとのクラスタ枠をタップするたびに `bookshelf.row.<n>` を追加し、端末内書誌 DB（`CatalogDatabase`）で書名完全一致が **1 件**のときは著者・出版社・ISBN を自動補完し、0 件または複数件のときは読み取った書名のみで追加する（AC-138）。 |
| **S-7c 奥付の撮影と補完（AC-113）** | カメラ（`colophon.capture`） | 認識した全行から正規表現で `colophon.author`（「著者」「著」の直後）、`colophon.publisher`（「発行所」「発行」の直後）、`colophon.label`（「文庫」「新書」「叢書」「レーベル」）、`colophon.year`（`(19\|20)\d{2}` 年）、`colophon.isbn`（`97[89][0-9\- ]{10,14}` を正規化した 13 桁）を抽出し、確認フォームの初期値に入れる。 |

- **画像の即時破棄とゼロ保存（AC-69、AC-113、AC-137、AC-138、AC-142）**：
  - カメラフレームおよび `PhotosPickerItem.loadTransferable(type: Data.self)` で取得した画像データは、メモリ上の `UIImage` / `CGImage` としてのみ保持し、`FileManager` によるファイル書き出しも `UIImageWriteToSavedPhotosAlbum` / `PHPhotoLibrary` への保存も一切行わない。
  - 確認画面（S-3c、S-7c、S-8b、S-8d）を閉じた瞬間にメモリ上の画像参照を `nil` にして解放する。H27 でアプリコンテナ・App Group・一時ディレクトリ内の画像ファイル数と写真ライブラリ書き込み回数がともに `0` であることを検証する。

## 引き受けること

- 写真上の読み取り枠（`mark.ocr.column.<n>`、`cover.ocr.line.<n>`）は、どんな背景写真の上でも視認できるよう黒（`#000000`）と白（`#FFFFFF`）の 2 重線（コントラスト比 21:1、任意の背景輝度に対して最小 4.58:1 以上）で描画し、Dynamic Type `accessibility1` 以上では画像の下に標準の `List` でも同じ識別子の行を並べる（`design/001-reading-session.md` 9 節）。
