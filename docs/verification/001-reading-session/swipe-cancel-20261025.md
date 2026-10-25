FAIL

## 指摘

PRD AC-64/65、design D-60/6(d)/10の8、test-hooks T5/T16に基づくS5下スワイプ経路を恒久回帰2本へ追加し、未修正HEAD `facb3240f839359e3a471503b0d802e8f5201ced`で各1回実行した。2本とも、reading 600秒から既存ボタンAC64/65と同じ経路でS5を開き、入力直後の72ページ/10分およびfinishing（readingなし）の事前assertを通過した。同じ1回の下スワイプとT16の60秒経過の後、所定の保存失敗区画 `error.saveFailed` が存在せず失敗した。これは入力事前条件やコンパイルの失敗ではない。

AC65も再試行の前提となる保存失敗区画の検査で停止したため、今回の実行だけで再試行ボタン押下後の動作は判定しない。72/10がスワイプ後に保持されるかを含め、その後のassertも未到達。新規PNG/treeは実行添付として取得済みだが、本レポート作成時点では未閲覧なので画像による断定はしない。

## 証拠

- [実行生ログ](evidence/swipe-cancel-20261025/red.log)、[コマンドと結果metadata](evidence/swipe-cancel-20261025/execution.json)、[Xcode生成の中断後summary](evidence/swipe-cancel-20261025/interrupted-summary.json)：対象2本、成功0、失敗2、skip0、expected failure0。AC64 50.394秒、AC65 48.425秒。本体は12:11:45 JSTに終了。
- 両方の失敗文は `Failed to get matching snapshot: No matches found ... error.saveFailed ...`。期待する区画がないため既存Wait.labelで停止した。入力直後のassertからこの検査までの順序は[実行ソースの写し](evidence/swipe-cancel-20261025/FinishInputAcceptanceTests-red.swift.txt)と生ログに残る。
- [最終整合性](evidence/swipe-cancel-20261025/final-integrity.json)、[61ファイルのbefore/current/HEAD照合](evidence/swipe-cancel-20261025/unchanged-files-current.json)：追加対象以外の追跡ios 61ファイルすべて不変。既存FinishInputクラスの本文も追加前の末尾まで不変。製品コードは開かず変更していない。
- [中断直前bundle保存manifest](evidence/swipe-cancel-20261025/partial-bundle-preserved.json)と`red-before-interrupt.log`を保存。未完成原本は `/private/tmp/reading-app-swipe-cancel-pre-interrupt-20261025.xcresult`（726ファイル）。手で修復していない。
- Xcodeが中断後に書いたbundle `/private/tmp/reading-app-swipe-cancel-red-20261025.xcresult` から公式exportで127添付を `/private/tmp/reading-app-swipe-cancel-red-attachments-20261025/` へ取得した。[export記録](evidence/swipe-cancel-20261025/export.log)。閲覧・repo内への画像整理は未実施。

## 変更したファイル

- `ios/AcceptanceTests/Tests/FinishInputAcceptanceTests.swift`：AC64下スワイプ、AC65下スワイプ再試行の2メソッド、共通の操作とPNG/tree添付helper（66行追加）。既存ボタン経路/設定/期待値は維持。
- `docs/verification/001-reading-session/test-plan.md`：実装前に仕様根拠と具体的期待値を固定し、通常82本×ja/en=164およびAC18別2本へ予定件数を更新。
- 本レポートと `evidence/swipe-cancel-20261025/`：原本、実行metadata、hash。

## 実行したコマンドと結果

正確な引数は `execution.json`。Acceptanceのja_JPに対して新規2メソッドだけを `-only-testing` で指定し、専用B18、並列NO、署名NOで1回実行した。本体は2失敗/skip0。固定sleep、skip、expected failure、テスト実行再試行は追加していない。AC65で定義するアプリの再試行操作はテスト内に保持したが、今回その操作へ到達していない。

本体終了後、専用B18対象のsimctl diagnose子process待ちで5分以上進展がなかった。原本を保存した上で親の指示に従い自分のxcodebuildへSIGINT、PPID/argvで今回の子processと確認した診断processだけへSIGTERMを送った。CLI終了は75、末尾は `TEST INTERRUPTED`。通常のテスト失敗終了65とは扱わず、2本の赤と後処理中断を分ける。中断後Xcode生成summaryは2失敗を保持している。最初のsummary取得失敗（Info.plist未生成、終了64）も `summary-read.log/.exit` に保持した。

summaryに `Invalid frame dimension (negative or non-finite).` のRuntime Warningが2件。生ログのその他警告も削除していない。実行中のpower記録で拾ったSleep/Wake文字列4件はpower assertionで、実際のsleep/wakeイベントは確認されていない。自分のB18はShutdown確認済み。他sim/global serviceへ停止操作はしていない。

## 未解決

- 製品修正は未実施。追加テスト2本は赤のまま、親の修正担当への引継ぎ待ち。
- 添付127点はtmpへ取得済みだが未閲覧。スワイプ後72/10、finishing、誤り文の詳細画像評価とrepo内PNG/tree整理は未実施。未到達assertを通過扱いにしない。
- 修正後HEADの再検証、英語、全件実行、反復安定性は今回の範囲外で未実施。既存G3 FAIL・23監査finding等は変更していない。
- 後処理は中断した。完成した通常終了bundleを取得したとは扱わない。commit/pushはしていない。
