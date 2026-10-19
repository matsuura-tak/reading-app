# ADR 0002：保存と共有（主の保存先は App Group の外の SwiftData、ウィジェットとは App Group の JSON の写しで分け合う。保護の等級は両方とも既定）

- 状態：提案
- 書いた役：tech-lead　日付：2026-10-20
- 関係する PRD、設計メモ、契約：docs/prd/001-reading-session.md（12、10 の「主の保存先」、付記の G1-16 (a)、18 の Q6）、docs/adr/features/001-reading-session.md（5）、contracts/widget-snapshot.schema.json（7-3 で書く）
- 元に戻す手間：大（主の保存先の場所と形を変えるには、利用者の端末のデータの移行が要る）。保護の等級を変えるのは中（すでにあるファイルの等級を、起動のときに付け直す）。

## 背景
- 保存するもの：本、記録、読書中の1件、しおり（本ごとの一行とページ）、設定2つ、置き方の案内を見た印。サーバーとアカウントはない（PRD 10、12）。
- PRD 12 の決まり
  - 主の保存先はアプリの Application Support に置く。ウィジェットと分け合う App Group には、小さな写し（今の本の書名、一行、ページ、出さない設定）だけを置く。
  - 写しはロック中にウィジェットが読むので、保護の等級は「最初のロック解除まで」より強くしない。
  - App Group の入れ物はバックアップから戻らない報告があるので、主の保存先を App Group に置かない（G4-17 で確かめる）。
- 付記の G1-16 (a)：主の保存先と App Group の入れ物の保護の等級を、既定（completeUntilFirstUserAuthentication）にする ADR を書く。Apple は利用者のデータに complete を勧めているので、悪い結果と見直す条件を書く。ロック中に読めない等級にするなら、決める前に Takuma に聞く（18 の Q6）。
- 効く AC
  - 開き直しても残る、続きから数える：AC-53、AC-89
  - 保存と読み込みの失敗：AC-59、AC-60、AC-90、AC-91、AC-95
  - ウィジェット：AC-27〜AC-35、AC-102（中身を返すまで0.5秒以内）、AC-33（保存1回で再読み込み1回）
  - 速さ：AC-100、AC-101（本500冊・記録5,000件で1.0秒以内）
- 調べて分かったこと（下の「確かめたこと」）
  - iOS の既定の等級は「Complete until first user authentication」。最初のロック解除のあとは、端末が切れるか再起動するまで読める。
  - SwiftData の ModelConfiguration の groupContainer の既定（.automatic）は、「アプリの primary の group container を保存の根の場所に使う」。ウィジェットのために App Group の entitlement を付けると、何も書かなければ主の保存先が App Group に置かれる。PRD 12 に反する。

## 決定
- 主の保存先は SwiftData のストア1つ。`ModelConfiguration` に `groupContainer: .none` と `cloudKitDatabase: .none` を必ず渡し、App Group の外（Application Support の下）に置く。スキーマは最初から VersionedSchema（SchemaV1）で包み、SchemaMigrationPlan を付ける。
- ウィジェットとは、App Group の入れ物の JSON の写し1つで分け合う。書くのはアプリだけ、読むのは拡張だけ。保護の等級は、主の保存先も写しも既定（completeUntilFirstUserAuthentication）にする。ロック中に読めない等級は選ばないので、18 の Q6 には触れない。
- 設定と「置き方の案内を見た印」も同じ SwiftData のストアに置く。UserDefaults（`@AppStorage` を含む）は、App Store に出す版のコードでは使わない。

細かい決まり（作り手と verifier が使う）
1. ストアの場所
   - ストアの URL に App Group の入れ物の道（containerURL(forSecurityApplicationGroupIdentifier:) の値）が含まれないことを、単体テストで確かめる（ios-engineer）。
   - 既定の場所が Application Support の下になることは［推測］。上のテストで、実際の URL を出して確かめる。
2. 保存の単位
   - 1つの操作の変更（例：読書を終えるときの「記録を足す」と「読書中の1件を消す」）は、1回の save にまとめる。
   - save に失敗したら rollback し、画面の値を操作の前に戻す（AC-60、AC-91、AC-95）。
   - 読書中の1件は、保存に成功してから画面を `reading` に変える（AC-59）。だから強制終了のあとも続きから数えられる（AC-53）。
3. 読み込みの失敗（AC-90）：ModelContainer を作れないか、最初の読み込みが失敗したら、S-1 に `store.load.error` と `store.retry` だけを出す。ストアを消したり作り直したりしない（データを守る）。
4. 写し
   - 置き場所：App Group の入れ物の中の1ファイル（例：widget-snapshot.json）。形と版は contracts/widget-snapshot.schema.json（7-3）で決める。
   - 中身：版、今の本（書名、一行の全文、ページ）、一行と書名を出さない設定、見た目の id。縮める（AC-29）のは描くときに ReadingCore が行う。
   - 書く時：主の保存先の save が成功したあと。今の本、一行、ページ、出さない設定のどれかが変わったときだけ書く。
   - 書き方：`Data.write(to:options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])`。
   - 書いたあと、ウィジェットの再読み込みの要求を1回だけ出す（AC-33、PRD 12 の電池）。種類ごとに分けて呼ぶと2回に数えうるので、1回の呼び出しで2つの種類を新しくする形にする［推測。H22 の数え方は 7-4 で決める］。
   - 起動のたびに、主の保存先から写しを作り直す。App Group の入れ物がバックアップから戻らなかったときと、写しの版を上げたときのため。
5. 保護の等級
   - Data Protection の entitlement（com.apple.developer.default-data-protection）は付けない。等級を指定せずに作ったファイルには、iOS が既定の等級を付ける。
   - 写しは書くたびに上の options で等級を明示する（既定と同じ値。拡張がロック中に読むことを、コードに残すため）。
6. PrivacyInfo.xcprivacy（アプリと拡張の両方に置く）
   - NSPrivacyTracking は false。
   - NSPrivacyAccessedAPITypes は0件にする。App Store に出す版のコードは、UserDefaults、systemUptime と mach_absolute_time、ファイルの日時（creationDate、modificationDate など）、空き容量の API を呼ばない。
   - 時計は壁時計（Date）だけを使う。読書の分は、読み始めの日時との差で数える（PRD 12。時刻が戻ったときは AC-58）。
   - 使うと決めたら、Apple の一覧で分類と理由のコードを確かめ（コードは未確認）、この ADR を直す。
   - G2 で reviewer が `grep -rnE 'UserDefaults|@AppStorage|systemUptime|mach_absolute_time|creationDate|modificationDate|volumeAvailableCapacity' ios/` で見る。テストの構成でだけ入るつなぎ口（ADR 0005）は数えない。
   - 集めるデータ（NSPrivacyCollectedDataTypes）と、書誌の問い合わせが「収集」に当たるか（G1-12）は ADR 0004（7-2）で決める。
7. 消し方
   - 本を消すと、その本の記録も一緒に消える（cascade。AC-16）。
   - 今の本がなくなったら、写しの今の本を空にする（AC-16、AC-32）。
   - アプリを消すと、主の保存先と写しの両方が消える［App Group の入れ物を使うアプリが1つだけのとき。推測］。
8. 移行
   - App Store に出す前は SchemaV1 を直してよい。
   - 出したあとは、モデルを変えるたびに SchemaV2 以降と MigrationStage を足す。前の版のストアの見本を開くテストを verifier に頼む（設計メモの 5）。

## 検討した案
| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| A App Group の外の SwiftData と、App Group の JSON の写し。等級は既定（採用） | バックアップから主の保存先が戻る。拡張は小さなファイルを読むだけで速い（AC-102）。拡張が SwiftData の移行に関わらない。ロック中もアプリと拡張が読み書きできる | 写しと主の保存先の2か所を合わせ続ける手間。.automatic のままだと App Group に置かれる落とし穴がある（必ず .none を渡す）。ロックした端末を手にした人に対して、complete より守りが弱い | — |
| B SwiftData のストアを App Group に置き、拡張も同じストアを読む | 写しが要らない。二重に持たない | App Group の入れ物はバックアップから戻らない報告がある（PRD 12）。拡張が SwiftData を開くので、拡張のメモリ（上限は未確認）と、アプリより古いスキーマで開く移行の時を考える手間が増える。ロック中にストア全体が拡張から読める | PRD 12 が、主の保存先を App Group に置かないと決めている |
| C 主の保存先を complete か completeUnlessOpen にし、写しだけ既定にする | Apple の勧め（利用者のデータに complete）に近い。端末がロックされると、主の保存先は読めない | ロックの約10秒後から主の保存先が読めなくなる。後ろに回った直後の保存（SwiftData の自動の保存を含む）が失敗しうるので、ロックとロック解除の知らせでストアを閉じて開き直す作りが要る。芯だけなら成り立つ見込み［推測］だが、(5) と (ショートカット) を残すと、ロック中の「読み始める」の保存と「どこまで読んだ？」の読み込みが崩れ、18 の Q6 に触れる | 回す所が決まる前に選ぶと、(5) か (ショートカット) を残したときに作り直しになる。Takuma の決定（ロック中もページを答える）と食い違いうる |
| D 主の保存先を自前の JSON ファイル（Codable）にする | 依存が増えない。移行を自分の手で書ける。中身が読みやすい | 本500冊・記録5,000件で、保存のたびに全体を書くと遅い［推測］。部分の更新、壊れたときの扱い、移行の仕組みを自分で作る | SwiftData で足りる。作る手間を増やさない |
| E 設定を UserDefaults（`@AppStorage`）に置く | 書くのがいちばん簡単 | 保存と読み込みの失敗（AC-90、AC-91）の扱いが2系統になる。H2 と H13 の口も2か所になる。required reason API の申告が要る | 1か所にまとめる方が、テストの口と失敗の扱いが単純 |

## いちばん強い反論と、それでも選んだ理由
- 反論：「主の保存先には本と記録のすべてがある。Apple は利用者のデータに complete を勧めている。既定の等級では、最初のロック解除のあと、ロックした端末を手にした人が OS の穴や調べる道具でファイルを取り出せれば、書名と一行と読書の時刻を読める。」（PRD 18 の Q6 の反論と同じ）
- それでも選んだ理由
  - Apple の文書も、complete を「前面にいる間だけ使うファイル」に勧めている（「Assign the complete protection level to files that your app accesses only when it is in the foreground.」）。写しはロック中にウィジェットが読むので、この条件に当たらない。主の保存先も、(5) と (ショートカット) を残せば、ロック中に読み書きする。
  - 守るものは、書名、著者、一行、読書の日時と分。ロック画面のウィジェットには、出さない設定がオフなら一行と書名がもともと出ている（AC-27、AC-34）。complete にして増える守りは、取り出しの道を持つ相手に対してだけ。
  - 最初のロック解除の前（再起動のあと）は、既定の等級でも読めない。
  - complete にすると、ロックとロック解除のたびにストアを閉じて開き直す作りが要り、保存に失敗する道が増える。3週の枠でその手間と危険を払うより、見直す条件をはっきりさせる方を選んだ。

## 結果
- これで楽になること
  - 保存先が1つ、移行の道も1つ。H2（入れる）と H13（読む）の口も1か所。
  - 拡張は小さな JSON を読むだけなので、0.5秒以内（AC-102）に入れやすい。
  - App Group が戻らなくても、起動のときに写しを作り直すので、ウィジェットは次の起動で直る（G4-17）。
- これで難しくなること、守り続けること
  - 写しを書く所を1か所（ReadingStore の保存の後ろ）にまとめ、書き忘れを防ぐ。今の本、一行、ページ、出さない設定を変える AC（AC-14、AC-16、AC-33、AC-34、AC-64、AC-73、AC-82）は H22 で写しを読んで確かめる。
  - `groupContainer: .none` を外さない（外すと主の保存先が App Group に移る）。上のストアの場所のテストで守る。
  - スキーマを変えるたびに、版と MigrationStage と前の版を開くテストを足す。
  - 申告を0件に保つため、UserDefaults ほかの API をコードに入れない。
- 元に戻すときの手順と手間
  - 主の保存先の等級を強くする：起動のときにストアのファイルに等級を付け直し、ロックの知らせでストアを閉じる作りを足す。中（1〜2日［推測］。G4 で確かめ直す）。
  - 主の保存先を App Group に移す：ストアの移動の移行と、バックアップからの戻りを確かめ直す。大。

## 見直す条件
- (iii) で (5) と (ショートカット) の両方を v1.1 に回すと決まった：ロック中に主の保存先を読み書きする理由がほぼなくなるので、案 C を比べ直す。
- G4-17 で、主の保存先がバックアップから戻らなかった。または写しを作り直してもウィジェットが直らなかった。
- G4-21 か G4-22 で、ロック中の保存か読み込みが、既定の等級で失敗した。
- 守るものが増える機能を足すと決めた：晩ごとのしおり（しおり帳）、iCloud の同期、アカウント。
- AC-101 か AC-102 が Release で線を超えた。
- Apple が、既定の等級や、WidgetKit がロック中にファイルを読む扱いを変えた。

## 確かめたこと
- 保護の等級（2026-10-20 に https://developer.apple.com/tutorials/data/documentation/uikit/encrypting-your-app-s-files.json を開いた。ページは https://developer.apple.com/documentation/uikit/encrypting-your-app-s-files ）
  - 「If you do not specify a protection level when creating a file, iOS applies the default protection level automatically.」
  - 「Complete until first user authentication. (Default) The file is inaccessible until the first time the user unlocks the device. After the first unlocking of the device, the file remains accessible until the device shuts down or reboots.」
  - 「Assign the complete protection level to files that your app accesses only when it is in the foreground.」
- SwiftData の置き場所（https://developer.apple.com/documentation/swiftdata/modelconfiguration/groupcontainer-swift.struct/automatic 。同じく JSON で開いた）：「Tells SwiftData to use the app’s primary group container as the root location for the persistent storage.」（iOS 17.0 から）
- Data Protection の entitlement（https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.default-data-protection ）：「The level of data protection for sensitive user data when an app accesses it on a device. To add this entitlement to your app, enable the Data Protection capability in Xcode.」
- VersionedSchema（https://developer.apple.com/documentation/swiftdata/versionedschema ）：「An interface for describing a specific version of a schema, including the models it contains.」。SchemaMigrationPlan（https://developer.apple.com/documentation/swiftdata/schemamigrationplan ）：「An interface for describing the evolution of a schema and how to migrate between specific versions.」
- spike（ADR 0001 と同じ。リポジトリの外）：`ModelConfiguration(schema: Schema(versionedSchema: SchemaV1.self), isStoredInMemoryOnly:, groupContainer: .none, cloudKitDatabase: .none)`、`ModelContainer(for:migrationPlan:configurations:)`、`Data.write(to:options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])` を含むパッケージを、iOS 26 を対象に `xcodebuild ... SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build` → `** BUILD SUCCEEDED **`。
- 前の判定：docs/reviews/001-reading-session-G1-tech-lead-design-r1.md の H（completeUntilFirstUserAuthentication の原文「After the user unlocks the device for the first time, your app can access the file and continue to access it even if the user subsequently locks the device.」）。
- 未確認
  - ウィジェットの拡張が、ロック中（最初のロック解除のあと）に写しを読めること。7-3 の spike と G4-1 で見る。
  - 既定の設定のときのストアの実際の場所（Application Support の下か）。上のストアの場所のテストで確かめる。
  - required reason API の分類と理由のコード。今は使わないので申告しない。
  - アプリを消したときに App Group の入れ物も消えること。G4-17 の前後で記録する。

## 確かめ（B）
- [x] 案が2つ以上あり、どの案にも悪い点が書いてある
- [x] 反論、悪い結果、見直す条件が空でない
- [x] 確かめたことに、URL かコマンドの出力がある
