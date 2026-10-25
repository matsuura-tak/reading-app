FAIL

## 指摘
- 重大（関門の状態の問題で、designer が直すものはない）。根拠は docs/org/gates.md:11「未検証の項目が残っていれば通りません」と docs/templates/review-report.md の「未検証が1つでもあれば PASS にしない」。デザインには、今の構成で作れない所は見つからなかった（証拠1、2）。ただし次の2つが確かめられていない。(1) 証拠1で「未確認」とした基本の部品およそ20件の存在と対応 OS。新しい URL を開くのは指示どおり10件で止めた。(2) Mac がないため CI でしか確かめられない動き（証拠3の (a)(b)(c)(g)、要修正1の変換中の文字、AC-49 の閉じてから push する動き）。閉じ方は2つ。(1) は r2 で、1回の Bash で残りの URL をまとめて開けば閉じる。(2) は G0 の裁定と同じく、指揮役が「代わりの案付きで G2 の CI の出力で確かめる」と裁定すれば、tech-lead の判定を PASS にできる。
- 要修正 1：design/001-reading-session.md:145 と docs/prd/001-reading-session.md:157,163。PRD 10 は、題名の上限を変換中でまだ確定していない文字には当てないことを求めている。この「当てない」作りを確かめられていない。S2 の行は「標準から外れる所：なし」だが、SwiftUI の TextField に変換中の文字を知る手段があるかは未確認。手段がなければ UITextField を包み（UIViewRepresentable）、markedTextRange が nil のときだけ切ることになる。その場合は標準から外れる。直す方向：tech-lead が手順7で CI の spike を行い、ADR に残す。包むと決めたら、designer が S2 の行に「本来の部品、理由、Dynamic Type と VoiceOver の対応」を書く。作れなければ、pdm が PRD 10 を「保存のときに先頭の100字に切る」に緩める。
- 要修正 2：design/001-reading-session.md:516 の (e)。読み始め、一時停止、再開の保存に失敗したときの画面の動きと AC がない。PRD:553 の Save Failed の operation にも、この3つが入っていない。直す方向：pdm と designer が決める。tech-lead の推奨は、S2 と S5 と同じ形にすること。状態は変えず、その画面に error.saveFailed と再試行を出す。T5 に session_start、session_pause、session_resume を足し、Save Failed の値も同じだけ足す。いちばん強い反論：読書の始まりの操作が重く見える。
- 要修正 3：design/001-reading-session.md:281 と :234。iOS 26 では confirmationDialog がポップオーバーの形になり、「キャンセル」ボタンが出ないおそれがある（未確認）。出なければ、AC-38（PRD:390）の「消さない」の When（session.delete.cancel）が行えない。直す方向：designer が 6 の S6 の行に、「キャンセル」が出ないときの「消さない」操作（外側をタップ）を書く。どちらの形になるかは G2 の CI の出力で決め、pdm が AC-38 の When を1つの形にそろえる。
- 提案 1：docs/prd/001-reading-session.md:553。AC-54 の読み込みの失敗には、計測のイベントがない。Save Failed の operation に load を足すか、診断のイベントを足すかを pdm が決める。
- 提案 2：最低対応 OS、ADR の一覧、プロジェクトの作り方、CLAUDE.md のコマンドは、手順7で決める。

## 証拠
- 対象：HEAD 02a6952（デザイン仕様は e893621）。観点は docs/org/gates.md:39-52 の G1 のうち、tech-lead の「今の構成で作れる」と「契約に何が要るか」。
- 新しく開いた API（A56〜A65）：developer.apple.com の文書の JSON（https://developer.apple.com/tutorials/data/documentation/<パス>.json）の metadata.platforms で確かめた。2026-10-21、10件すべて取れた。
  - A56 NavigationStack iOS 16.0。参照に List、NavigationLink、NavigationPath、navigationDestination(for:destination:) があり、存在だけ確かめた
  - A57 LabeledContent iOS 16.0
  - A58 ViewThatFits iOS 16.0
  - A59 swipeActions(edge:allowsFullSwipe:content:) iOS 15.0
  - A60 interactiveDismissDisabled(_:) iOS 15.0
  - A61 accessibilityElement(children:) iOS 13.0
  - A62 AccessibilityNotification.Announcement iOS 17.0
  - A63 XCUIElement.swipeDown() Xcode 16.3+（XCUIAutomation）
  - A64 accessibilityIdentifier(_:) iOS 14.0。本文：「Use this value for testing. It isn't visible to the user.」
  - A65 safeAreaInset(edge:alignment:spacing:content:) iOS 15.0

### 証拠1：3章の部品が SwiftUI の標準部品で作れるか
| 部品 | 画面 | 根拠 | iOS | 判定 |
|---|---|---|---|---|
| NavigationStack、push、S4 から S3 への置き換え（path） | S1〜S5 | A56 | 16.0 | 作れる（path の OS は未確認） |
| List（insetGrouped）、Section、NavigationLink | S1、S3 | A56 の参照（存在だけ） | 未確認 | 作れる見込み |
| LabeledContent | S1、S3、S5 | A57 | 16.0 | 作れる |
| ContentUnavailableView | S1 | A11 | 17.0 | 作れる |
| toolbar、ToolbarItem（.cancellationAction、.confirmationAction） | S1、S2、S5 | 開いていない | 未確認 | 未確認 |
| Button（.borderedProminent、.bordered）、controlSize(.large) | S1、S3、S4 | 開いていない | 未確認 | 未確認 |
| safeAreaInset(edge: .bottom) | S1、S3 | A65 | 15.0 | 作れる |
| redacted(reason: .placeholder)、ProgressView | S1、S3 | 開いていない | 未確認 | 未確認 |
| sheet / interactiveDismissDisabled | S2、S5 | 開いていない / A60 | 未確認 / 15.0 | 一部未確認 |
| Form、TextField、keyboardType(.numberPad) | S2、S5 | 開いていない | 未確認 | 未確認 |
| FocusState | S2、S5 | A12 | 15.0 | 作れる |
| confirmationDialog、ButtonRole.cancel | S2、S6 | A17、A45 | 16.0、15.0 | 作れる（「キャンセル」が出るかは要修正3） |
| EditButton、onDelete / swipeActions | S3 | 開いていない / A59 | 未確認 / 15.0 | 一部未確認 |
| alert | S7 | 開いていない | 未確認 | 未確認 |
| accessibilityAddTraits(.isHeader)、navigationTitle の inline | S3 | 開いていない | 未確認 | 未確認 |
| TimelineView、Text の monospacedDigit | S4 | A13 / 開いていない | 15.0 / 未確認 | 一部未確認 |
| DynamicTypeSize.isAccessibilitySize、ViewThatFits、ScrollView | S4 ほか | A20、A58 / 開いていない | 15.0、16.0 / 未確認 | 一部未確認 |
| accessibilityElement(.contain)、accessibilityIdentifier、Announcement、accessibilityLabel | 全画面 | A61、A64、A62、A20 | 13.0、14.0、17.0、14.0 | 作れる |

「標準から外れる所」の見積もり：
- S1 と S3 の主操作（safeAreaInset の中の標準の Button）：手間は低い。Dynamic Type と VoiceOver の作り直しはない。AX サイズのときは isAccessibilitySize で分けて、List の先頭の行に移す。理由は書いてある。
- S3 の題名（List の行に .title2 と isHeader、ナビゲーションバーは inline）：手間は低い。作り直しはない。
- S5 の分の数字の欄（標準の TextField）：手間は低い。作り直しはない。
- S2（「なし」と書いてある）：変換中の文字を扱うために UIKit を包むと、標準から外れる（要修正1）。
- S4、S6、S7：外れる所はない。
- 作れないものは見つからなかった。最低の OS は SwiftData と A62 のため iOS 17 以上（手順7で決める）。

### 証拠2：AC-47〜AC-55 の実現性
| AC | 使う API | 難しさ | 懸念 |
|---|---|---|---|
| AC-47 | sheet(item:)（開くたびに新しい入力）、A3、T3、T17 | 低 | 入力の下書きは S5 の @State にだけ持つ。やめたら、進行中の読書の「終えた時刻」と「分の初めの値」を消す |
| AC-48 | sheet（S5 には A60 を付けない）、A63、A3、T3 | 中 | 「キャンセル」と下へのスワイプを1つの関数に通す。onDismiss は保存の後にも呼ばれるので、そこを「やめた」として扱わない。終えた時刻からやめた時刻までは「止めていた合計」に足す（AC-48 の 10:00 と AC-47 の 15 がこれを求めている） |
| AC-49 | A56（path に追加した本を積む）、A3、A65 | 低〜中 | sheet を閉じる更新と push を同じ更新で行ったときに、push が落ちないかは未確認（G2 の CI）。start_source の after_add は path の値に持たせる |
| AC-50 | A56（同じ本の S3 があればそこまで戻り、なければ S4 を S3 に置き換える）、A3、A5 | 中 | 記録を足すことと進行中の読書を消すことを、1回の save にまとめる。S4 の onDisappear で状態を変えない |
| AC-51 | A56、A62、T3 | 低 | 知らせは S3 の path の値に持たせ、その S3 にだけ出す。アラートは使わない |
| AC-52 | A2、条件分岐 | 低 | finishing のままでは S3 に行けない（S5 がモーダル）。AC の手順どおり |
| AC-53 | A17、A60（入力があるとき）、A45 | 低 | 本は保存するまで ModelContext に入れない。入れると、自動の保存（A4）で本が増えるおそれがある |
| AC-54 | A11、明示の fetch（A40）、ModelContainer の作成（未確認）、T5 の load | 中 | @Query（A2）では失敗を画面に出せない見込み（未確認）。起動の読み込みを、読み込み中、読めた、失敗の3つの状態で持つ。失敗のときは進行中の読書も読まないので、S4 と S5 は積まない |
| AC-55 | 同上、T5 の load:1 | 中 | 失敗しても保存先を消さず、メモリの保存先にも切り替えない（D-44）。T2 のデータの投入は、失敗を起こすより前に行う。再試行で読めたら、起動と同じ分かれ方をする |

### 証拠3：designer の7つの問い（design/001-reading-session.md:516）への答え
- (a) 未確認（G2 で CI の出力で確かめる）。作り：.accessibilityElement(children: .contain) を先に付け、.accessibilityIdentifier を後に付ける（A61、A64）。sheet の中は根の modifier の外に出るので、S5 には別に付ける（6 のとおり）。子の識別子を上書きしてしまう場合の代わり：-UITest のときだけ、1pt の要素に識別子を付ける。
- (b) 未確認（G2 で CI の出力で確かめる）。識別子が付かなければ、7 の文字で探す（design:234）。編集モードの「削除」はシステムの文字で、String Catalog では決められない。iOS 26 で「キャンセル」が出るかは要修正3。
- (c) 未確認。XCUITest で VoiceOver のアクションの一覧を読めるかも未確認なので、G4 で人が実機で確かめる。出ないときの代わり：行の3つの子それぞれに accessibilityAction(named:) で「削除」を付ける（API は未確認）。「編集」からも消せるので、消す道は残る。
- (d) 作れる。label は String Catalog のキー（reading.elapsed.ms など）に、分と秒の整数を渡して作る（A30、A46）。DateComponentsFormatter（A19、A44）は使わない。これで G0 r2 の AC-40 の懸念（「12分30秒」に空白が入るか）が消える。
- (e) つなぎ口は T5 に load を足す（下の UITEST_FAIL="load:1"）。読み込みの失敗は実際に起こりうる：移行の失敗（A8）、ディスクの空きがない、保護されたファイル（A32）。ModelContainer の作成と fetch が throws であることは、今回ページを開いていない（未確認。手順7のビルドで確かめる）。保存先を消さないことと、別の保存先を作らないことは、証拠2の AC-55 のとおり。
- (f) 数え方は Swift の String.count（Character＝拡張書記素クラスタ）を使い、prefix(100) で切る（今回ページは開いていない。未確認。単体テストで確かめる）。book.add.titleLimit を出す条件にも同じ数え方を使う。変換中の文字に当てない作りは未確認（要修正1）。
- (g) できる見込み。A63 の swipeDown() を、S5 のナビゲーションバーに対して行う（欄の上でスワイプすると、スクロールやキーボードを閉じる動きになるおそれがある）。実際に閉じるかは未確認（G2 で CI の出力で確かめる）。S5 には A60 を付けない。

### 証拠4：contracts/ に要るもの（手順7で書く）
- 形の案：Markdown と JSON にする。
  - contracts/test-hooks.md：表の列は T-n、名前、型、例、使う AC、Release での扱い。
  - contracts/telemetry-events.schema.json と telemetry.md。
  - contracts/data-model.md。
  - contracts/seed.schema.json。
  - Swift の protocol の宣言は contracts/ に置かない。置くと ios-engineer が直せず、シンボリックリンクの仕組みも要る。機械の確かめは下の方法で足りる。
- spectral と oasdiff：対象外。HTTP の契約（OpenAPI）がない。代わりに次で確かめる。
  - JSON Schema の形式：ajv-cli で確かめる（未確認。手順7で動かす）。
  - 互換性：`git diff origin/main -- contracts/ | grep -cE '^-[^-]'` が0であること（足すだけ）。データは SwiftData の移行テストで確かめる。
  - 名前のずれ：`grep -rhoE 'UITEST_[A-Z_]+' ios/AcceptanceTests | sort -u` の結果が、契約にある名前の中に収まること。
  - Release に混ざらないこと：Release の実行ファイルに `strings` をかけ、`grep -c UITEST_` が0であること（macOS の CI）。
- つなぎ口の名前の案：Debug のときだけ働かせる。launchArguments に -UITest があるときだけ、UITEST_* を読む（A22）。
  - T1：UITEST_RESET=1
  - T2 と T17：UITEST_SEED=<JSON>。項目は books、sessions、active、flags。時刻は UITEST_TIME_ZONE の壁時計の時刻で書く。環境変数の長さの上限は未確認。
  - T3：UITEST_NOW=ISO8601
  - T16（動いている間に進める、止める、戻す）：URL `readingapp-uitest://clock?advance=300|freeze=1|set=…` を XCUIApplication.open で送り（A23、A55）、onOpenURL で受ける（A16）。URL scheme は Debug の Info.plist にだけ書く。open で確認のダイアログが出ないか、裏にいる間の時計の扱いは未確認。
  - T4：-AppleLanguages と -AppleLocale（未確認）と UITEST_FIRST_WEEKDAY=1|2
  - T15：UITEST_TIME_ZONE=Asia/Tokyo
  - T5：UITEST_FAIL="load:1,book_add:2"（`*` なら毎回失敗）。操作は load、book_add、session_finish、session_delete。要修正2で決まれば session_start、session_pause、session_resume も足す。
  - T6、T7、T13、T19：UITEST_TELEMETRY_URL=http://localhost:<port>。イベントごとにすぐ POST /events する。待ち行列が空になったら POST /flushed {"sent":n} を送る（T13）。UITEST_TELEMETRY_TIMEOUT=30。届かない先は localhost の聞いていないポート。SDK を使う場合、SDK そのものが送る中身はこの形では確かめられない（G0 r2 の未検証と同じ）。
  - T8、T9、T10、T18：design/ の 6 と 7 を正とし、契約には写さず参照する。
  - T11、T12：アプリ側のつなぎ口は要らない（権限は使わない）。
  - T14：String Catalog のパスと数え方は、手順7で決める。
  - T20：os_signpost（カテゴリ perf、名前 FirstElapsedShown）。読み始める操作で始め、経過を最初に出したところで終える。A50 で測る。signpost はテストのつなぎ口ではないので、Release に残してよい。
  - Release で働かせない作り：UITEST_ を読むコードは1つのファイルの `#if DEBUG` の中に置く。
- 計測のイベントの型：`enum TelemetryEvent: Sendable` に、PRD 15 の8イベントを case として置く。関連値は Bool と区間の enum だけにする（例：BookCountBucket(count:)、DurationBucket、PagesBucket、StartSource、SaveOperation）。String と Int の関連値を持たないので、題名やページの生の値はコンパイルの段階で渡せない。イベント名とプロパティ名は、この型の中の1か所でだけ作る。送り先は `protocol TelemetrySink: Sendable { func send(_ event: TelemetryEvent) async }`。実装は本番と、テストの HTTP の2つなので、protocol にする理由がある。
- 保存のモデル（SwiftData。最初から VersionedSchema の V1 で包む。A8）：
  - Book：id、title（100字まで、整えた後の値）、totalPages Int?、addedAt。
  - ReadingSession：id、book、startedAt、durationSeconds、page Int?、savedAt。
  - ActiveReading（0件か1件）：book、state（reading / paused / finishing の文字）、startedAt、pausedAt?、pausedTotalSeconds、finishedAt?、minutesInitial?。同じ保存先に置くので、読み込みに失敗したときは一緒に読めない。そのため AC-54 の「S4 を積まない」と合う。
  - 最後のページを、記録から出すか、本に持たせるかは手順7で決める。
  - 計測の印は UserDefaults（A21、A33）に置く。
  - 保存の操作の案：load、addBook、startReading、pause、resume、beginFinish、cancelFinish、finishSession、discardTooShort、deleteSession。
- 時計と暦の差し替え：`struct AppClock: Sendable { var now: @Sendable () -> Date }` と、Calendar の値（firstWeekday、timeZone、locale。A18、A43）を環境に入れる。名前を Clock にすると Swift 標準の Clock とぶつかるおそれがある（未確認）。

### 読んだファイル、実行したコマンド、開いた URL
- 読んだファイル：design/001-reading-session.md（1〜6、9、10）、docs/prd/001-reading-session.md（10 の題名の行、11 の AC-47〜55、15 のイベントの表）、docs/reviews/001-reading-session-G0-tech-lead-r2.md（1 と 7）、-r1.md:30-64（A1〜A34）、docs/reviews/001-reading-session-G0-verifier-r2.md:123-136 と -r1.md:141-152（T1〜T12）、docs/org/gates.md:6-15,39-52、docs/templates/review-report.md
- 実行したコマンド：curl で A56〜A65 の JSON を取り、jq で platforms を読んだ。10件すべて取れた。A56、A61、A64、A59 は本文も読んだ。`git log --oneline -3` → HEAD は 02a6952。
- spike：Mac がないので、していない。

### 未検証
- 証拠1で「未確認」とした基本の部品の対応 OS。r2 で開く URL：toolbar、toolbaritemplacement、borderedprominent、controlsize、redacted、progressview、sheet、form、textfield、keyboardtype、editbutton、ondelete、alert、accessibilityaddtraits、navigationbartitledisplaymode、monospaceddigit、scrollview、navigationpath。
- 証拠3の (a)(b)(c)(e)(f)(g) と、要修正1、要修正3、AC-49 の push、AC-54 の @Query と ModelContainer。
- G0 r2 の 7(b) に残っているもの（TelemetryDeck、AC-18 の CI、AC-21 の SpringBoard）。

## 記録（指揮役）
- 関門：G1（手順6、構成の判定）
- 判定した役：tech-lead
- 回：r1
- 対象：design/001-reading-session.md、design/tokens.md、design/001-reading-session/screens.md（コミット e893621）、docs/prd/001-reading-session.md（AC-47〜AC-55）
- 日付：2026-10-21
- 指揮役の扱い：重大は未検証の扱いの問題。docs/reviews/001-reading-session-G1-ruling.md に裁定を書く。要修正1〜3は pdm と designer に直させ、r2 を回す。
