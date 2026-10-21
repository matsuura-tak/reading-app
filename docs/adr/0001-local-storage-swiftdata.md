# ADR 0001：記録は SwiftData で端末の中だけに置き、最初の版から VersionedSchema の V1 で包む

- 状態：提案
- 書いた役：tech-lead　日付：2026-10-21
- 関係する PRD、設計メモ、契約：docs/prd/001-reading-session.md（10、12、AC-8、AC-16、AC-18、AC-19、AC-29、AC-33〜AC-35、AC-42、AC-43、AC-54〜AC-61）、docs/adr/features/001-reading-session.md（次の作業で書く）、contracts/data-model.md、contracts/seed.schema.json
- 元に戻す手間：大（保存の形を変えると、利用者の端末の中のデータの移行が要る）

## 背景
- 001 が持つのは、本、記録、進行中の読書の3つだけ。アカウントもサーバーもない。iCloud の同期と書き出しはしない。端末のバックアップには入れる（PRD 10。iCloud のバックアップが除くのは tmp と Caches だけ：A31）。
- 強制終了、端末の再起動、保存の失敗で読書を失わない（AC-8、AC-18、AC-19、AC-33、AC-34）。画面の状態は保存が通ってから変える（PRD 10 の「読み始め、一時停止、再開の保存に失敗したとき」、AC-56〜AC-61）。読み込みに失敗しても保存先を消さず、別の保存先も作らない（AC-55、design の D-44）。
- 本500冊、記録10,000件で、ホームと本の詳細が1.0秒以内（PRD 12）。
- 最低の OS は iOS 17.0（ADR 0002）。#Index（A9）は iOS 18.0 からなので使えない。
- 形が変わることが見えている：002 の拡張（同じデータを読む見込み）、003 の読み終えた本と表紙。

## 決定
- SwiftData を使う。モデル（Book、ReadingSession、ActiveReading。項目は contracts/data-model.md）は最初から `SchemaV1: VersionedSchema`（版 1.0.0）で包み、stages が空の `SchemaMigrationPlan` を置く（A8）。
- 保存先は Application Support の中の1つのファイル（`Yomutoki/Library.store`）。ModelConfiguration に url を明示し、cloudKitDatabase は none にする（A7）。バックアップから除かない。ファイルの保護は OS の既定（完全保護ではない。下の表）。
- 1つの操作は1回の明示の save()（A3）にまとめ、失敗したら rollback()（A5）して、画面の状態を変えない。mainContext の自動保存（A4）は切る。画面は @Query（A2）でなく、保存の層が FetchDescriptor（A40）で読んだ値を @Observable（A10）で持つ（読み込みの失敗を画面に出すため。AC-54）。
- 計測の印（初めて開いた時刻など）は SwiftData に入れず、UserDefaults（A21）に置く（ADR 0003、contracts/data-model.md）。

## 検討した案
| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| SwiftData＋VersionedSchema（選んだ） | 標準。依存なし。@Observable と合う。版と移行の仕組みがある（A8）。ModelContainer の作成と save が throws で、失敗を画面に出せる（A102、A3） | #Index が iOS 18 から（A9）。iOS 17 の初期の版の不具合の有無は未確認。@Query の失敗の扱いは未確認なので、読み込みを自分で書く | － |
| Core Data | 長く使われている。失敗の扱いが文書にある | NSManagedObject を Swift 6 の並行性の中で扱う手間（未確認）。書く量が多い | 001 の小さなモデルに対して重い |
| Codable の JSON を1ファイルに丸ごと書く | いちばん単純。Linux で単体テストできる | 操作のたびに全体（10,000件で数百KB〜1MB と推測）を書き直す。途中で落ちたときの扱いと移行を自作 | PRD 12 の量と、操作ごとの保存の回数に合わない（推測） |
| SQLite を直接（GRDB などの第三者の依存） | 速さ、索引、移行を細かく決められる | 第三者の依存が増える（dependencies.md と ADR が要る）。プライバシーマニフェストの確認 | 標準で足りる間は依存を足さない |
| SwiftData を VersionedSchema で包まない | 書く量が少し減る | 2版目で包み直すときに、最初の版のストアをどう識別するかが未確認 | 後から包むより、最初から包む方が安い |

ファイルの保護の段：
| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| OS の既定（最初の解除まで保護。選んだ） | 画面が消えた後や、OS が先に起動しておく場合（prewarm。未確認）でも読み書きできる | 端末を最初に解除した後は、鍵がかかっていてもファイルが読める | － |
| 完全保護（.complete。A32） | 鍵がかかっている間はファイルが読めない | 鍵がかかった間にアプリが読み込むと失敗し、AC-54 の読み込みの失敗が利用者に見えるおそれ（推測） | 中身は題名と読書の時刻と長さで、口座や健康の情報ではない。誤った読み込みの失敗を出す害の方が大きいと判断した |

## いちばん強い反論と、それでも選んだ理由
- 反論：保存の失敗を確かめる受け入れテスト（AC-19、AC-35、AC-42、AC-43、AC-54〜AC-61）は、つなぎ口 UITEST_FAIL（contracts/test-hooks.md の T5）で作った失敗で、SQLite の本物の失敗（ディスクの空きがない、移行の失敗）の動きは確かめられない。本物の失敗で SwiftData がメモリの中のモデルをどう残すかは未確認で、rollback の後に画面とディスクがずれるおそれがある。
- それでも選んだ理由：作った失敗は save() と fetch の直前（保存の層の境目）で投げるので、失敗の後の画面の動きは本物と同じ道を通る。メモリとディスクのずれは「失敗したら rollback して保存の層から読み直す」を決まりにして減らす。本物の失敗の動きは、ios-engineer が単体テストで、書き込めない場所の url を渡した ModelContainer で確かめる（未確認。G2）。

## 結果
- これで楽になること：第三者の依存がない。モデルの版と移行の仕組みが最初からある。保存が1操作1回なので、失敗したときに「状態は前のまま」を守りやすい。
- これで難しくなること、守り続けること：モデルを変えるたびに SchemaV2 と MigrationStage を足し、前の版のストアを開くテストを足す（002 の AC で前の版からの更新を確かめる。PRD 12）。自動保存を切ったので、save の呼び忘れは単体テストで見つける。@Query を使わないので、保存の後に画面の値を読み直す処理を保存の層に持つ。
- 元に戻すときの手順と手間：保存の層（1つの型）の中だけを差し替え、古いストアを読んで新しい形に書く移行を1版の間持つ。手間は大（3〜5日と推測。移行のテストを含む）。

## 見直す条件
- G3 の XCTClockMetric（PRD 12）で、本500冊と記録10,000件のホームか本の詳細が1.0秒を超えた。そのときは本に合計の秒と件数を持たせる V2（足すだけの移行）か、最低の OS を iOS 18 に上げて #Index を使う。
- PRD が iCloud の同期か書き出しを求めた。
- 002 の拡張が同じデータを読む必要が出た（保存先を App Group のコンテナへ移す移行が要る）。
- 公開後に、保存の失敗が読書を終えた1,000回あたり1回以上になった（PRD 13 のガードレール）。

## 確かめたこと
- 公式ドキュメント（G0、G1 の tech-lead の報告で開いた。docs/reviews/001-reading-session-G0-tech-lead-r1.md:31-64、-r2.md:41-56、docs/reviews/001-reading-session-G1-tech-lead-r2.md の (1)）：
  - A1 SwiftData iOS 17.0+ https://developer.apple.com/documentation/swiftdata
  - A2 Query iOS 17.0+ https://developer.apple.com/documentation/swiftdata/query
  - A3 ModelContext.save()（throws）https://developer.apple.com/documentation/swiftdata/modelcontext/save()
  - A4 autosaveEnabled。本文「SwiftData automatically sets this property to true for the model container's mainContext.」https://developer.apple.com/documentation/swiftdata/modelcontext/autosaveenabled
  - A5 rollback() https://developer.apple.com/documentation/swiftdata/modelcontext/rollback()
  - A7 ModelConfiguration（url、allowsSave、cloudKitDatabase）https://developer.apple.com/documentation/swiftdata/modelconfiguration
  - A8 VersionedSchema、SchemaMigrationPlan https://developer.apple.com/documentation/swiftdata/versionedschema https://developer.apple.com/documentation/swiftdata/schemamigrationplan
  - A9 #Index iOS 18.0+ https://developer.apple.com/documentation/swiftdata/index(_:)-74ia2
  - A10 Observation iOS 17.0+ https://developer.apple.com/documentation/observation
  - A21 UserDefaults https://developer.apple.com/documentation/foundation/userdefaults
  - A31 iCloud のバックアップ https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup
  - A32 ファイルの暗号化 https://developer.apple.com/documentation/uikit/encrypting-your-app-s-files
  - A40 FetchDescriptor、A41 ModelContext.delete(_:) https://developer.apple.com/documentation/swiftdata/fetchdescriptor
  - A102 ModelContainer.init(for:migrationPlan:configurations:) iOS 17.0、宣言に throws
- 未確認（確かめる役と時期）：iOS 17.0〜17.x の SwiftData の不具合の有無。@Query の読み込みの失敗の扱い（裁定の対象。使わないので影響は小さい）。prewarm の起動で保護されたファイルが読めない場合があるか。本物の save の失敗の後のメモリの状態（ios-engineer の単体テスト、G2）。10,000件の読み込みの時間（verifier、G3 の XCTClockMetric）。
- spike：Mac がないので、していない。

## 確かめ（B）
- [x] 案が2つ以上あり、どの案にも悪い点が書いてある
- [x] 反論、悪い結果、見直す条件が空でない
- [x] 確かめたことに、URL かコマンドの出力がある
