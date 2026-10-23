# ADR 0002：最低の対応 OS は iOS 17.0、iPhone だけ。Xcode 26 と iOS 26 SDK、Swift 6 の言語モードでビルドする

- 状態：提案
- 書いた役：tech-lead　日付：2026-10-21（同日、G1 reviewer r1 の要修正3 で改訂：Xcode の版の検査をコマンドに入れ、iOS 17 の確かめを G4 の前の1回に書き直した）
- 関係する PRD、設計メモ、契約：docs/prd/001-reading-session.md（10 の iPad と Apple Watch はやらない、12 の速さの基準の機種）、docs/adr/features/001-reading-session.md（6、10）、ADR 0001、ADR 0004、CLAUDE.md（ios_build）
- 元に戻す手間：中（下げるのは、使っている API を置き換える手間。上げるのは、古い OS の利用者が更新を受け取れなくなるので公開後は実質戻せない）

## 背景
- 001 は SwiftData（A1 iOS 17.0）、@Observable（A10 iOS 17.0）、ContentUnavailableView（A11 iOS 17.0）、AccessibilityNotification.Announcement（A62 iOS 17.0）を使う。デザインの部品で最も新しいのは iOS 16.0（A83、A88。G1 tech-lead r2 の (1)）。
- App Store に上げるビルドは、2026-04-28 から Xcode 26 以降と iOS 26 の SDK で作る決まり（G0 tech-lead r2 で開いて確認：https://developer.apple.com/news/upcoming-requirements/ 「Since April 28, 2026 Apps uploaded to App Store Connect must be built with Xcode 26 or later using an SDK for iOS 26」）。
- この環境に Mac がない。ビルドとテストは GitHub Actions の macOS（ADR 0004）でだけ行う。CI の macos-latest に iOS 17 のシミュレーターの実行環境があるかは未確認。
- PRD 12 の起動2.0秒の基準の機種は「最低の対応 OS が動くいちばん遅い機種」で、この ADR で決めることになっている。

## 決定
- 最低の対応 OS は iOS 17.0。対象は iPhone だけ（TARGETED_DEVICE_FAMILY = 1）。
- ビルドは Xcode 26 系と iOS 26 SDK。ios_build の最初で `xcodebuild -version` を出し、続けて `xcodebuild -version | grep -qE '^Xcode (2[6-9]|[3-9][0-9])'` で大きな版が 26 以上でなければ終了コード1で落とす（CLAUDE.md の ios_build）。出力の1行目が「Xcode 26.0」の形であることは未確認で、違えば最初の CI の出力で直す。落ちたときの代わりは、`xcode-select` で 26 を選ぶ行をコマンドに足すこと（裁定の追記2 の (6)。app.json は Takuma）。
- Swift 6 の言語モード（SWIFT_VERSION = 6.0）。並行性の検査は言語モードどおり完全。アプリのターゲットの既定の actor 分離は MainActor。警告は0件（CI のログの `warning:` を数える）。
- 001 ではローカルの Swift パッケージを作らない（アプリ1つ、単体テスト1つ、受け入れテスト1つのターゲット。ADR 0004）。
- iOS 17 の確かめ：毎回の CI（ios_test）は iOS 26 のシミュレーターだけで動かす。ビルドは最低の OS を 17.0 にして毎回通すので、iOS 18 以降の API を `if #available` なしで使えばコンパイラが止める。iOS 17 での動きは、G4 の前に1回だけ、次のどちらかで確かめる。どちらにするかは G3 の後に指揮役が Takuma に聞く。
  - (a) Takuma の iOS 17 の実機（P-11 の端末が iOS 17 のとき）で、TestFlight の Release ビルドを使い、G4 の確認リスト（verifier が書く）を手で通す。受け入れテストを実機で動かすには Mac が要る（P-14）。
  - (b) iOS 17 のランタイムを入れた CI の手動の実行（workflow_dispatch。.github/ は Takuma だけが書く）で、受け入れテストを1回通す。

既定の actor 分離（ターゲットごと）：
| ターゲット | 既定の分離 | 理由 |
|---|---|---|
| Yomutoki（アプリ） | MainActor | 画面と保存の層（mainContext）はメインで動く。重い処理は 001 にない。必要になったら @concurrent か actor を使い、理由をコメントに書く |
| YomutokiTests（単体テスト） | 既定のまま（nonisolated）。メインのものを試すテストに @MainActor を付ける | テストの道具の既定に合わせる |
| YomutokiAcceptanceTests（受け入れテスト） | 既定のまま | verifier が決める。XCUIApplication の分離は未確認 |

## 検討した案
| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| iOS 17.0（選んだ） | SwiftData、@Observable、Announcement が使える。iOS 17 が動く端末を広く含む | #Index（A9 iOS 18.0）が使えない。iOS 17 と 26 の2つの見た目を確かめる。毎回の CI で iOS 17 を動かせない（ランタイムの有無が未確認） | － |
| iOS 18.0 | #Index と SwiftData の改善が使える | iOS 17 で止まった端末の利用者を落とす（割合は未確認） | 001 の量は #Index なしで足りる見込み。G3 で測ってから決める（ADR 0001 の見直す条件） |
| iOS 26.0 | 新しい API と見た目だけを相手にできる。試す OS が1つ | 対応する端末と利用者がいちばん少ない（未確認） | 利用者を減らす理由が 001 にない |
| iOS 16.0 | 対応が広い | SwiftData と @Observable がない。Core Data と ObservableObject で書くことになる | AC を満たす作りが重くなる |
| Swift 5 の言語モード＋並行性の警告 | 移行の手間が少ない | データ競合をコンパイラが止めない。警告を黙らせる癖がつく | 新しいアプリなので、最初から Swift 6 にする方が安い |

## いちばん強い反論と、それでも選んだ理由
- 反論：iOS 17 と iOS 26 では見た目（iOS 26 のツールバーと Liquid Glass）が大きく違う。対応の幅を広げると、design-reviewer の G3 のスクリーンショットと、色の当て方の確かめ（裁定の D-46、D-48、D-53）が2通りになり、Mac のない環境では手が足りない。しかも毎回の CI で iOS 17 を動かせないので、iOS 17 だけの不具合は G4 の前まで見つからない。iOS 26 だけにすれば1通りで済む。
- それでも選んだ理由：001 の売りは「読む時間の記録」で、新しい見た目の API に頼る画面はない。G3 の採点と AC の受け入れテストは iOS 26 のシミュレーターで行い、iOS 17 は G4 の前に1回だけ確かめて手間を抑える（決定の最後の項目）。iOS 17 で崩れが多ければ、そのときに最低の OS を上げる判断をする（見直す条件）。001 は内部の TestFlight までなので、公開前に上げても利用者を落とさない。

## 結果
- これで楽になること：標準の新しい API（SwiftData、@Observable）だけで書ける。Swift 6 の検査でデータ競合をビルドで止められる。Xcode の版の違いを CI がその場で落とす。
- これで難しくなること、守り続けること：iOS 17 だけの不具合を見つけるのが G4 の前の1回まで遅れる。iOS 18 以降の API を使うときは `if #available` で分けるか、この ADR を置き換える。Xcode の版が上がるたびに警告0件を保つ。G4 の前に iOS 17 を確かめる場所（実機か CI）を用意する（指揮役が G3 の後に Takuma に聞く）。
- 元に戻すときの手順と手間：上げるのは IPHONEOS_DEPLOYMENT_TARGET を変えるだけ（公開後は利用者を落とすので Takuma の判断）。下げるのは使っている API の置き換えで、手間は中から大。

## 見直す条件
- G4 の前の iOS 17 の1回の確かめで、iOS 17 だけで落ちる受け入れテストか見た目の崩れが3件を超えた（最低の OS を 18 か 26 に上げるかを Takuma に聞く）。
- G4 の前までに、iOS 17 で確かめる場所（iOS 17 の実機、iOS 17 のランタイムを入れた CI）が1つも用意できない（同じく Takuma に聞く。確かめずに出すなら、その危険を承認に書く）。
- CI の macos-latest に iOS 17 のランタイムがあると ios_test のログ（`xcrun simctl list devices available`）で分かった（そのときは ios_test に iOS 17 の受け入れテストの1回を足すかを決め直す。CI の時間の上限と一緒に）。
- 公開後に App Store Connect の OS の版の割合で、iOS 17 の利用者が5%未満になった（そのとき iOS 18 か 26 に上げる）。
- App Store の決まりで、より新しい Xcode か SDK が求められた（https://developer.apple.com/news/upcoming-requirements/ を G4 の前にもう一度開く）。
- 002 で拡張か、ほかのターゲットとコードを分ける必要が出た（ローカルの Swift パッケージを作るか決める。3つまで）。

## 確かめたこと
- A1 SwiftData iOS 17.0+、A10 Observation iOS 17.0+、A11 ContentUnavailableView iOS 17.0+、A9 #Index iOS 18.0+（docs/reviews/001-reading-session-G0-tech-lead-r1.md:31-41）
- A62 AccessibilityNotification.Announcement iOS 17.0、A83 alert iOS 16.0、A88 NavigationPath iOS 16.0（docs/reviews/001-reading-session-G1-tech-lead-r1.md と -r2.md の (1)）
- https://developer.apple.com/news/upcoming-requirements/ （G0 tech-lead r2 で開き直して確認。上の引用）
- 版の検査の grep をこの環境で試した（`printf 'Xcode 26.0\nBuild version 17A324\n' | grep -qE '^Xcode (2[6-9]|[3-9][0-9])'` → 0、`printf 'Xcode 16.4\n…'` → 1。出力は設計メモの 4）
- 未確認：
  - PRD 12 の基準の機種。iOS 17 が動くいちばん遅い iPhone は iPhone XS と XR（A12 Bionic）と推測するが、Apple の対応機種のページ（support.apple.com）はこの環境から開けない（2026-10-21 に curl で 403）。Takuma の端末（PRD 18 の P-11）が分かってから設計メモで決める。
  - CI の macos-latest にある Xcode の版（ios_build の版の検査で分かる。裁定の追記2 の (6)）。iOS 17 のシミュレーターの実行環境の有無（ios_test のログで分かる）。`xcodebuild -version` の1行目の形。
  - Xcode 26 のビルド設定の名前 SWIFT_DEFAULT_ACTOR_ISOLATION と、XcodeGen の project.yml からそれを渡せるか（ADR 0004 と同じく CI の出力で確かめる。裁定の追記2 の (8)）。swift.org はこの環境から開けない（403）。
  - XCUIApplication の actor 分離。
- spike：Mac がないので、していない。

## 確かめ（B）
- [x] 案が2つ以上あり、どの案にも悪い点が書いてある
- [x] 反論、悪い結果、見直す条件が空でない
- [x] 確かめたことに、URL かコマンドの出力がある
