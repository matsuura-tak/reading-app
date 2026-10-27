（指揮役の注）G1 の 7-1（設計メモの下書き、ADR 0001・0002、書誌の確かめの本の一覧）の、tech-lead の報告。7-2〜7-4 への申し送りと未解決を残すため保存した。判定ではない。報告の文はそのまま保存した。

## 変更したファイル
4ファイルとも新しく作りました。コミットはしていません。
- /Users/takumamatsuura/reading-app/docs/adr/features/001-reading-session.md（設計メモの下書き。型 A）
  - 書いた節：1、2、3、5、6、7、8、9。
  - 2 の対応表：芯の AC は85行。選択肢の AC 51件は、回す順ごとに7行。
  - 4 と 10 は、分かっている所だけ書き、「7-4 で埋める」としました。末尾の確かめ（A）はまだ印を付けていません。
- /Users/takumamatsuura/reading-app/docs/adr/0001-ios-foundation.md（ADR 0001、iOS の土台。型 B のすべての節。確かめ（B）は3つとも印あり）
- /Users/takumamatsuura/reading-app/docs/adr/0002-storage-and-sharing.md（ADR 0002、保存と共有。同上）
- /Users/takumamatsuura/reading-app/docs/adr/features/001-reading-session-ndl-check.md（書誌の確かめで問い合わせる本の一覧）
  - 既刊20件、新刊10件、出て14日以内の5件。どの行にも出どころの URL があります。
  - 頭に、合格の線（確かめの計画の 5 をそのまま写したもの）と、7-2 での問い合わせの形を書きました。
  - 「そろう」の数え方も先に決めて書きました。ISBN 1つに2件以上返ったら、最初の item で数えます。
  - 国立国会図書館サーチと openBD には、一度も問い合わせていません。

### 決めたこと
- **ADR 0001（iOS の土台）**
  - 最低 iOS 26.0、iPhone だけ。Swift 6 の言語モードで、警告は0件。外部のライブラリは入れません。
  - ローカルのパッケージは2つです。
    - ReadingCore：アプリと拡張で共有。actor 分離は Swift の既定（nonisolated）のまま。
    - ReadingStore：アプリだけ。`.defaultIsolation(MainActor.self)`。
  - ウィジェットの拡張は ReadingCore だけを使い、SwiftData を開きません。
  - 強制アップデートは v1 では入れません。サーバーがなく、App Store に問い合わせると AC-103（外に送るのは書誌の問い合わせだけ）に反するためです。
  - いちばん強い反論：iOS 26 で切ると、古い端末の人が入れられない。
    - 答え：仕様が iOS 26 の API を使っており、3週の枠で OS を2系統は確かめられません。
    - 見直す条件：入れられないという問い合わせが10件を超えたとき。
- **ADR 0002（保存と共有）**
  - 主の保存先は SwiftData です。`groupContainer: .none` と `cloudKitDatabase: .none` を必ず渡します。
    - Apple の文書では、既定の .automatic は「アプリの primary group container を使う」とあります。App Group を付けると、何も書かなければ主の保存先が App Group に移り、PRD 12 に反します。
  - ウィジェットとは、App Group の JSON の写し1つで分け合います。
  - 保護の等級は、主の保存先と写しの両方とも既定（completeUntilFirstUserAuthentication）にしました。前の判定の案どおりです。
    - ロック中に読めない等級は選んでいないので、PRD 18 の Q6 には触れません。Takuma に聞くことはありません。
  - 設定もストアに置き、App Store に出す版では UserDefaults を使いません。PrivacyInfo の required reason API は0件にします。
  - いちばん強い反論：Apple は利用者のデータに complete を勧めている。
    - 答え：Apple の文書の complete の勧めは「前面にいる間だけ使うファイル」に向けたものです。写しはロック中にウィジェットが読みます。守るものも、もともとロック画面に出る程度のものです。
    - 見直す条件：(5) と (ショートカット) の両方を v1.1 に回すと決まったら、complete の案を比べ直します。
- **お願い**：2本とも私が書いて、私が確かめ（B）に印を付けました。自分では合格にしないので、reviewer に反論を出してもらってください。
  - 特に見てほしいのは、ReadingStore を MainActor にしたこと（AC-101 の速さへの影響）と、等級を既定にしたことです。

## 実行したコマンドと結果
- **AC の行の数の照合**
  - `grep -cE '^- AC-[0-9]+：' docs/prd/001-reading-session.md` → `136`
  - `grep -cE '^\| AC-[0-9]+ \|' docs/adr/features/001-reading-session.md` → `85`
  - `python3 -I .../g1-7-1/py/verify.py` の出力：
    - `PRD AC: 136 | PRD core: 85 | PRD option: 51`
    - `memo core rows: 85 unique: 85 core==PRD core: True rows with empty cell: []`
    - `memo option ACs: 51 option==PRD option: True | union==all: True | overlap: []`
    - 1回目は選択肢の数え方の正規表現に誤りがあり、`58`、`overlap [1,3,…]` と出ました。原因は「AC-104」の中から「AC-10」を拾っていたことです。正規表現だけを直して再実行したのが上の出力で、設計メモは変えていません。
- **書誌の一覧の確かめ**（同じスクリプト）
  - `既刊20件 rows: 20 bad check digit: [] publishers: 10`
  - `新刊10件 rows: 10 bad check digit: [] publishers: 6`
  - `出て14日以内の5件 rows: 5 bad check digit: [] publishers: 5`
  - `all rows: 35 unique ISBN: 35`
- **spike**（リポジトリの外：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-1/spike/pkg）
  - 中身：swift-tools-version 6.2、iOS 26 対象、`.defaultIsolation(MainActor.self)`、VersionedSchema、SchemaMigrationPlan、`groupContainer: .none`、`.completeFileProtectionUntilFirstUserAuthentication` の書き込み、`@concurrent`。
  - `xcodebuild -scheme SpikePkg-Package -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build` → `** BUILD SUCCEEDED **`
  - 分離が効いているかの確かめ：nonisolated の関数から MainActor のメソッドを呼ぶファイルを足すと、exit 65 で `error: call to main actor-isolated instance method 'add(title:)' in a synchronous nonisolated context`。確かめたあと、そのファイルは消しました。
  - `xcodebuild -version` → Xcode 27.1。`swift --version` → Apple Swift 6.4。
- **開いたページ**
  - 公式ページ：https://developer.apple.com/news/upcoming-requirements/ 、encrypting-your-app-s-files、modelconfiguration/groupcontainer-swift.struct/automatic、com.apple.developer.default-data-protection、versionedschema、schemamigrationplan（JSON で取得）。原文は ADR に引用しました。
  - 出版社のページ：一覧の「記録」の節にあるとおりです。
- **後片付け**：シミュレーターの端末は作っていません（`xcrun simctl list devices | grep -c g1-7-1` → 0）。
- **git status**：新しいのは docs/adr/0001-ios-foundation.md、docs/adr/0002-storage-and-sharing.md、docs/adr/features/ だけです。
- **作業のメモ**：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-1/notes.md
- **手数**：45回目で作業を終え、この報告を出しています。未着手の項目はありません。

### 7-2〜7-4 への申し送り
- **7-2**
  - 一覧の35件を、ファイルに書いた形で 2026-10-20 に問い合わせます。その日にできなければ、新刊の窓が動くので指揮役に返します。
  - ADR 0004 で決めること：dpid、cnt=50、問い合わせ直しの細かい決まり、クレジットの文（G1-5）、送ることが「収集」に当たるか（G1-12）、ラテン文字の著者（G1-13）、openBD を使うか。
  - 推測のまま置いたもの：待ちの打ち切り15秒、クッキーとキャッシュを残さない構成、応答の長さの上限。
  - 契約：contracts/ndl-opensearch.yaml。operationId は `ndlOpenSearch`（仮）にしてあります。
- **7-3**
  - 縦書きの spike：拡張の既定の分離を nonisolated にして書けるか、ロック中に写しを読めるか、置き換えの表に字を足すか（design-reviewer r2 の 2 の〈〉《》【】［］〔〕‥：）。
  - ADR 0003。
  - widget-snapshot.schema.json（項目は設計メモの 5）と entry-urls.md（URL では保存を変えない）。
- **7-4**
  - つなぎ口の契約。足すもの：
    - 読み終えた日時（finishedAt）を H2 と H13 で扱う形
    - `search.clear` と `mark.page.previous`
    - 再読み込みの数え方
  - ADR 0005（G1-10 を含む）、dependencies.md の1行、CLAUDE.md、G1-3、G1-11。
  - 設計メモの 4 と 10、確かめ（A）。

## 未解決
1. **pdm と designer に確かめてほしいこと**：積読の並び（AC-13 の「加えた日」）に使う日時です。
   - 今の本を替えると、前の本は積読に移ります（AC-14）。並びに使うのが、元の「加えた日時」か「積読に移した日時」かが PRD と仕様にありません。
   - 下書きでは「積読に移した日時」で並べる案にしました（設計メモの 5）。
2. **新刊10件は6社です**（幻冬舎、東京創元社、河出書房新社、講談社が2件ずつ、白水社と岩波書店が1件ずつ）。
   - 確かめの計画の「出版社10社の新刊の案内」は例として書かれているので、この形でよいかを指揮役が判断してください。
   - 岩波書店の1件は、トップページの本の並びから取りました。新刊の欄かは確かめていません。
3. **既刊の20番（中公文庫、2026-09-18）は、予定の日の32日前に出た本です。** 既刊の定義を「出て29日以上たった本」にしたので入れました。
4. **推測のまま置いたもの**
   - 拡張の既定の分離を nonisolated にすること（7-3 で確かめる）
   - ストアの既定の場所が Application Support の下になること（単体テストで確かめる）
   - 2つのウィジェットの再読み込みを1回の呼び出しにすること（7-4 で verifier と決める）
   - 知らない enum の値の読み方
5. **未確認のまま置いたもの**
   - required reason API の理由のコード（今は使わないので申告しない）
   - iOS 26 が動く端末の一覧と、動かない端末の利用者の割合
   - ロック中に拡張が写しを読めること（G4-1）
6. **G1-11**（App Store Connect の値が出ないときの代わりの出し方）は、案を1行書いただけです（7-4）。

## 記録（指揮役が保存するときに書き足す）
- 種類：作り手（tech-lead）の報告（判定ではない）
- 書いた物：docs/adr/0001-ios-foundation.md、docs/adr/0002-storage-and-sharing.md、docs/adr/features/001-reading-session.md、docs/adr/features/001-reading-session-ndl-check.md（コミット 48263ef）
- 日付：2026-10-20
- 指揮役の判断
  - 新刊10件が6社：確かめの計画で出版社10社以上を求めるのは既刊20件だけで、新刊の「10社の案内」は例なので、認める。
  - 既刊の20番（予定の日の32日前に出た本）：新刊の窓（15〜28日前）の外なので、既刊として認める。
  - 積読の並びに使う日時（AC-13）：PRD の読み方の問いなので、G2 の前に pdm に確かめさせる（ほかの小さな食い違いと一緒に）。
- 書誌の本の一覧は、問い合わせの前にこのコミットに入った
