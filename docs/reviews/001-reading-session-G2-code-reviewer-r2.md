PASS

## 指摘

重大・要修正なし。前回の提案だった空のApp Iconは未対応だが、前回どおりG5前の提案として扱い、今回のG2コード判定には数えない。

## 前回の指摘の追跡

| 前回の指摘 | 結果 | 証拠 |
|---|---|---|
| UITestMarker・showsStateMarkerとADR 0005の不一致 | 解消 | 固定HEADの製品コードで両識別子は0件。ADR 0005は例外を取り下げ、テスト用機能はDebugの2ファイルに集約。 |
| 本の一覧順とデータモデル契約の不一致 | 解消 | `contracts/data-model.md:55–61`と`LibraryStore.swift:467–478`は、ともに「前の本」を先頭にする。 |
| 二度押し、60秒境界、TimelineView、ファイル保存先の検査 | 解消 | `AddBookView.swift`の`didSave`、`LibraryStore.swift:237–276`の同一時刻、`ReadingView.swift:278`の`.now`、`LibraryStoreTests.swift:355–441,498–542`を確認。 |

## 証拠

対象は`0e2c062...6442fe2e5b1ad1f4956123c938076c6da462b874`のG2コード。独立reviewerは**gpt-6-sol**。作り手のモデルは未確認。固定HEADの`ios/Yomutoki/`、`ios/YomutokiTests/`、`ios/project.yml`、`.gitignore`、`Makefile`、`CLAUDE.md`を全体まで確認した。関連するPRD、データモデル・計測・テスト用機能の契約、ADR 0005、デザインの識別子・文言、75件のString Catalogも照合した。受け入れテスト23ファイルの正式な内容判定とG3の画面判定は別担当の範囲。

AC対応は次のとおり。各`test_AC番号_*`は固定HEADの受け入れテストに存在し、AC-18・39以外はCIの日本語・英語各80件に含まれる。単体テストがある境界は括弧内に示す。

| AC | 実装 | テスト・結果 |
|---|---|---|
| 1–4、31、42、49、53 | `HomeView`、`AddBookView`、`AppRouter`、`LibraryStore.addBook`、`TitleRules`、`NumberInput` | 各`test_AC*`成功。題名・数値境界は`ReadingRulesTests`、`DisplayRulesTests`、`LibraryStoreTests`。 |
| 5、17、25–27、52、56–57 | `HomeView`、`BookDetailView`、`LibraryStore.previousBookID/startReading`、`PerfSignpost` | 各`test_AC*`成功。前の本、一覧順、保存失敗後の時刻は`LibraryStoreTests`。 |
| 6–8、33–34、40–41、58–63、66–67 | `ReadingView/ReadingModel`、`RootView.restore`、`LibraryStore.pause/resume/finish`、`ReadingMath` | 各`test_AC*`成功。時刻・60秒境界・rollbackは`ReadingRulesTests`、`LibraryStoreTests`。 |
| 9–13、19、29–30、32、35、45–48、50、64–65 | `FinishSessionView`、`ReadingModel`、`LibraryStore.finishSession/cancelFinish/discardTooShort` | 各`test_AC*`成功。AC-35はファイル保存先を開き直す単体テストも成功。 |
| 14–16、28、36–38、43–44、51 | `BookDetailView`、`HomeView`、`LibraryStore`の集計・削除、`ReadingMath.week/pagesRead` | 各`test_AC*`成功。集計、週境界、削除失敗は`LibraryStoreTests`、`ReadingRulesTests`。 |
| 18、54–55 | `SchemaV1`、`LibraryContainer`、`LibraryStore.load/retryLoad`、読み込み失敗画面 | AC-18専用計画の再起動前後2件成功。AC-54/55は両言語成功。ファイルを残す読み込み失敗は`LibraryStoreTests`。 |
| 20、23–24 | `TelemetryEvent/Recorder/Sink`、DebugのHTTP送り先、端末内の計数 | 各`test_AC*`成功。イベントの契約JSON・区間・週1回は`TelemetryTests`。 |
| 21–22 | 権限を求めないplistと画面、冊数制限・課金導線を持たない追加処理 | 各`test_AC*`成功。 |
| 39 | `Localizable.xcstrings`、`InfoPlist.xcstrings`、AC-39スクリプト | 固定HEADと作業木の対象4ファイルに差分がないことを確認し、独立実行で`untranslated_keys=0`、終了0。75キーすべてにja/enがある。 |

弱体化検査では`.claude/`・`.github/`差分0、依存lockfile差分0。単体テストのアサーションは追加328・削除0。全テストを対象にした検索では追加466・削除0。skip語の一致は文書とUIの`.disabled`で、テストの追加スキップはない。通常のAcceptance計画で除外するAC-18の2本は専用計画で選択される。テスト値「坊っちゃん」「こころ」「72」の製品コード中の一致はPreviewに限られ、テスト中だけ結果を変える条件分岐は見つからない。製品コードに`try!`、`as!`、`@unchecked Sendable`、`nonisolated(unsafe)`、TODO/FIXME、外部AI APIのURL、ATS全許可はない。秘密情報パターンと`.env`追跡ファイルも0件。`git diff --check`は終了0。

[CI run 39895904848](https://github.com/matsuura-tak/reading-app/actions/runs/39895904848)の完全ログを直接確認した。生の改行で数えた行番号は、Debug/Releaseビルド成功が**1148/1715行**、単体69件が**2759行**、受け入れテストen_US・ja_JP各80件・失敗0・スキップ0が**18244–18246行**、AC-18再起動前後の`passed 2 of 2`が**18471行**。CIはPRのマージ用コミット`be59372`で固定HEAD `6442fe2`をmain `0e2c062`へ統合して実行。Releaseの`CFBundleURLTypes`不在は1717行で確認した。Release文字列検査とファイル保護検査は`make ios-build`の連結コマンドに入り、その成功で通過を確認した。Swiftコンパイラ警告は0件、既知のAppIntentsメタデータ警告は5件。

未検証：**このG2コード判定範囲にはなし**。独立したXcode・シミュレーターの再実行は親担当と競合するため行わず、手引きが認める固定HEADのCI完全ログを証拠とした。PR全体のG2/G3合格やマージ可否は判定していない。

## 記録（指揮役）

- 関門：G2、iOS実装・単体・ビルド設定のコード観点のみ。
- 判定した役：reviewer、固定モデルgpt-6-sol、独立した文脈。途中の利用上限後、同じr2を再開して残りの確認を完了した。
- 対象：main `0e2c062`...HEAD `6442fe2`。未コミットの使い捨てG3ハーネスは対象外。
- 日付：2026-10-23。
- このPASSはテスト観点の判定とG3全体の代わりにはしない。文書・画面の証拠を理由なく合格にまとめない。
