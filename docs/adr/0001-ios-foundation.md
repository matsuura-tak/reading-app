# ADR 0001：iOS の土台（最低 iOS 26、Swift 6、ローカルの Swift パッケージ2つ、v1 は強制アップデートなし）

- 状態：提案
- 書いた役：tech-lead　日付：2026-10-20（7-1 で書き、7-4b で拡張の分離の［推測］を外し、構成の行を足した）
- 関係する PRD、設計メモ、契約：docs/prd/001-reading-session.md、docs/adr/features/001-reading-session.md、contracts/（設計メモの 4 の表）
- 元に戻す手間：大（最低の OS を下げると、iOS 26 の API を使う画面と、確かめる OS の組を作り直す）。パッケージの分け方を変えるのは中。最低の OS を上げるのは小。

## 背景
- 作るのは iPhone のアプリと、ウィジェットの拡張（W-1 ロック画面、W-2 小のウィジェット）。サーバーはない（PRD 10）。v1 の範囲は芯の AC 85件（裁定 24）。
- App Store の条件（2026-10-20 に公式ページで確かめた。下の「確かめたこと」）
  - 2026-04-28 から、Xcode 26 以降と iOS 26 の SDK でビルドしたものだけを受け付ける。
  - 2026-09-09 から、最低の対応 OS は iOS 13 以上。
- 仕様（design/001-reading-session.md）は iOS 26 の API を前提にしている：Button の role .close と .confirm、ラベルなしの init(role:action:)。G1 のデザインの判定（docs/reviews/001-reading-session-G1-tech-lead-design-r1.md の G）で、iOS 26.0 を対象にした typecheck は exit 0、iOS 18.0 を対象にすると exit 1 だった。
- PRD 12 は、G3 を iOS 27 のシミュレーターで測り、ウィジェットと伏せる道のテストは iOS 26.x でも動かす前提。最低の機種の値は G4-15 で、iOS 26 が動くいちばん古い機種で測る。
- この機械：Xcode 27.1（27A9275）、Apple Swift 6.4。シミュレーターの runtime は iOS 27.0 だけ。iOS 26.x を入れるかは G1-3 で Takuma が決める（手順と大きさは設計メモの 10。ダウンロードはしていない）。
- 時間の枠：芯だけでも 1.3〜1.8倍の速さが要る（PRD の冒頭）。土台は、作り手が迷わない最小の形にする。
- アプリとウィジェットの拡張は、縦書きの組みと描画を同じものにしなければならない（AC-27〜AC-31、AC-99、H22 は、アプリの中で同じ部品を描いて確かめる）。

## 決定
- 最低の対応 OS は iOS 26.0、端末は iPhone だけ。ビルドは Xcode 26 以降と iOS 26 以降の SDK（この機械は Xcode 27.1）。外部のライブラリは入れず、Apple のフレームワークだけを使う。
- Swift 6 の言語モード（並行性の検査は完全）で、警告は0件（SWIFT_TREAT_WARNINGS_AS_ERRORS=YES）。`@unchecked Sendable`、`nonisolated(unsafe)`、`@preconcurrency` は使わない。使うなら、その行のコメントに理由を書く（G2 で reviewer が grep する）。
- 作りは、アプリのターゲット、ウィジェットの拡張のターゲット、ローカルの Swift パッケージ2つ（ReadingCore、ReadingStore。名前は仮）。依存は一方向。強制アップデートは v1 では入れない。
- ビルドの構成は3つ。Debug（手元の開発と受け入れテスト）、Perf（Release を写し、コンパイルの条件 `UITEST_HOOKS` だけを足す。速さの AC を G3 で測る）、Release（TestFlight と App Store）。Perf を置く理由、ほかの案、G2 での確かめ方は ADR 0005。

| 単位 | 中身 | 使う側 | 既定の actor 分離 | 書く場所 |
|---|---|---|---|---|
| ReadingCore（ローカルのパッケージ） | 値の型と計算：縦書きの組み、縮め方（AC-29）、晩と分、ISBN のチェックの数字、著者の取り出し（AC-92）、名前のそろえ方、入口の URL、ウィジェットの写しの型と読み書き。W-1 と W-2 の描画の View | アプリ、ウィジェットの拡張 | nonisolated（Swift の既定のまま）。値の型は Sendable にする。View は SwiftUI の View の宣言によって MainActor になる | Package.swift に分離の設定を書かない。`swiftLanguageModes: [.v6]` は書く |
| ReadingStore（ローカルのパッケージ） | SwiftData のモデル（VersionedSchema）、保存と読み込み、書誌の問い合わせ（URLSession と XMLParser）、ウィジェットの写しを書く側。時計、通信の部品、保存の前の確かめ、再読み込み、外の URL を開く部品は init で受け取る（つなぎ口のコードはここに書かない。ADR 0005） | アプリだけ | MainActor | Package.swift の swiftSettings に `.defaultIsolation(MainActor.self)`。通信と XML の読みは `@concurrent` の関数で main の外に出す |
| アプリのターゲット | 画面（S-1〜S-10、部品 N）、App の入口、入口の URL を受ける所。テストのつなぎ口は `UITestHooks/` の下だけで、Debug と Perf だけに入る（ADR 0005） | — | MainActor | ビルド設定の Default Actor Isolation を MainActor（Xcode 26 以降の新しいアプリの既定） |
| ウィジェットの拡張のターゲット | Widget の宣言と TimelineProvider。写しを読み、ReadingCore で組んで描く | — | nonisolated（7-3 の spike のビルドで確かめた。下の「確かめたこと」） | ビルド設定の Default Actor Isolation を nonisolated |

- 依存の向き：アプリ → ReadingStore → ReadingCore、アプリ → ReadingCore、拡張 → ReadingCore。拡張は ReadingStore を使わない（SwiftData を開かない。写しだけを読む。ADR 0002）。
- ローカルのパッケージは Xcode のビルド設定を受け継がない。だから言語モードと分離は Package.swift に書く（spike で確かめた形。下）。
- Mac（Designed for iPhone）と Vision Pro には配らない。App Store Connect で外す（PRD 10。G5 の前）。

## 検討した案
| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| A 最低 iOS 26、Swift 6、パッケージ2つ（採用） | 仕様の iOS 26 の API をそのまま使える。確かめる OS が 26 と 27 の2つで済む。拡張と分け合う所だけをパッケージにするので、境目がはっきりする | iOS 26 が動かない端末の人は入れられない（割合は未確認）。この機械に iOS 26 の runtime がない（G1-3）。ReadingStore を MainActor にしたので、重い読み込みが main に乗りうる（AC-101 で測る） | — |
| B 最低 iOS 18 | 入れられる端末が広がる | role .close と .confirm、ラベルなしの init(role:action:) が使えない（typecheck で exit 1）。画面ごとに `if #available` の分岐が要り、G3 と G4 で見た目を2通り確かめる。SwiftData の OS ごとの振る舞いの差も試す | 3週の枠（1.3〜1.8倍の速さが要る）に入らない。仕様を直す手間も要る |
| C パッケージを作らない（共有のファイルを、アプリと拡張の両方のターゲットに入れる） | いちばん単純。Package.swift が要らない | 同じファイルが2つのターゲットで別にビルドされ、単体テストの置き場所が分かれる。拡張に SwiftData のコードが入っても気づきにくい。ターゲットごとの分離の設定が、同じファイルに別々に効く | 「拡張は写しと組みだけを使う」を、ビルドの境目で守らせたい（AC-27〜AC-31、AC-99、AC-102） |
| D パッケージ3つ（Core、Store、UI） | 画面もビルドの単位が分かれる | 画面だけのパッケージを使うのはアプリ1つで、分ける利点が小さい。アクセシビリティの識別子と環境の値をパッケージの境目でまたがせる手間が増える | 3つ目を足す理由が今はない（見直す条件に書いた） |
| E 強制アップデートを v1.0 から入れる（App Store の版を外から調べる） | 古い版を止められる | アプリの版を送る相手（こちらのサーバー）がない。App Store に問い合わせると、外への通信が書誌の問い合わせのほかに増え、AC-103 に反する | AC-103。サーバーがない v1 では、止めるべき古い API もない |

## いちばん強い反論と、それでも選んだ理由
- 反論：「最低 iOS 26 は狭い。読書の道具は年配の人も使い、古い端末のままの人がいる。iOS 18 で切れば、もっと多くの人が入れられる。」
- それでも選んだ理由
  - 仕様が iOS 26 の API を使っており、iOS 18 に下げると画面の作りと確かめ方が2通りになる。3週の枠でその手間を払えない。
  - iOS 26 が動かない端末の人の割合は、まだ測れていない（未確認）。公開後の問い合わせの数で見直す（見直す条件）。
  - 最低の OS を後で下げるのは手間が大きいが、できなくはない（画面ごとの分岐を足す）。上げる方向は小さい。
- 2つ目の反論：「ReadingStore を MainActor にすると、本500冊・記録5,000件の読み込みで画面が止まる。」
  - 答え：AC-101（1.0秒以内。G3 は Perf、G4 は Release。裁定 29）と、反応の目標（250ms 以上の hang 0件。設計メモの 6）で測る。超えたら、読み込みを `@ModelActor` の actor に移す（この ADR を直す）。最初から actor にすると、ModelContext を画面と分け合う手間が増える。

## 結果
- これで楽になること
  - 画面の作りは iOS 26 の標準の部品だけで済む（G1 のデザインの判定の B）。
  - 拡張に入るのは ReadingCore だけなので、拡張が SwiftData を開くことがビルドの形で起きない。
  - 並行性の誤りがコンパイルで落ちる（spike で、MainActor のメソッドを nonisolated の関数から呼ぶとビルドが落ちることを確かめた）。
- これで難しくなること、守り続けること
  - iOS 26.x のシミュレーターがこの機械にない。入れる手順と大きさは確かめた（設計メモの 10）。入れるかは Takuma が決め、入れなければ iOS 26 での確かめは G4 の実機だけにする（PRD の G1-3）。
  - 警告0件を保つ。Swift と Xcode を上げるたびに、警告が増えていないかを CI で見る。
  - ReadingCore の値の型は Sendable に保つ。拡張とアプリのどちらからでも呼べる形にする。
  - Package.swift の `swiftLanguageModes` と `defaultIsolation` を、パッケージを足すたびに書く。
  - 構成を3つ保つ。Perf のバンドル ID、App Group、entitlements は Release と同じにする（ADR 0005）。
- 元に戻すときの手順と手間
  - 最低 OS を下げる：iOS 26 の API の箇所ごとに `if #available` を足し、G3 を2つの OS で回す。大。
  - パッケージを1つにまとめる、または3つに分ける：ファイルの移動と import の直し。中（1〜2日［推測］）。
  - 拡張の分離を MainActor に変える：ビルド設定の1行と、TimelineProvider の書き方の直し。小［推測］。

## 見直す条件
- 公開後、iOS 26 未満の端末で入れられないという問い合わせが10件を超えた［線は推測］。
- Apple が SDK や最低 OS の条件を上げた（毎年の発表。https://developer.apple.com/news/upcoming-requirements/ を G5 の前に読み直す）。
- AC-100 か AC-101 が線を超えた（G3 の Perf か G4 の Release）、または Instruments の Hangs で 250ms 以上の hang が出た：ReadingStore の読み込みを `@ModelActor` に移す。
- 画面のコードが増え、アプリのターゲットのビルドが手元で1分を超えた［線は推測］：画面のパッケージ（3つ目）を考える。
- サーバーを持つ版（友人など）を作ると決めた：その API の最初の版より前に、強制アップデート（アプリが版を送り、サーバーが動かせる最低の版を返す）を入れる。この ADR を置き換える。
- 外部のライブラリが要るものが出た：contracts/dependencies.md と新しい ADR で決める。

## 確かめたこと
- App Store の条件（2026-10-20 に `curl -s https://developer.apple.com/news/upcoming-requirements/` で開き、タグを除いて読んだ）
  - 「Since April 28, 2026 Apps uploaded to App Store Connect must be built with Xcode 26 or later using an SDK for iOS 26, iPadOS 26, tvOS 26, visionOS 26, or watchOS 26.」
  - 「Since September 9, 2026 iOS and iPadOS apps uploaded to App Store Connect must target iOS 13 or later.」
- 道具の版
  - `xcodebuild -version` → `Xcode 27.1`
  - `swift --version` → `Apple Swift version 6.4 (swiftlang-6.4.0.34.1 clang-2100.3.34.1)`
- iOS 26 の API：docs/reviews/001-reading-session-G1-tech-lead-design-r1.md の G の 2（`swiftc -typecheck -target arm64-apple-ios26.0-simulator` → exit 0。`-target arm64-apple-ios18.0-simulator` → exit 1、「'close' is only available in iOS 26.0 or newer」ほか）。
- spike（リポジトリの外。/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-1/spike/pkg）
  - Package.swift：`// swift-tools-version: 6.2`、`platforms: [.iOS(.v26)]`、`swiftLanguageModes: [.v6]`、ターゲット ReadingCore（設定なし）と ReadingStore（`swiftSettings: [.defaultIsolation(MainActor.self)]`、ReadingCore に依存）。
  - ReadingStore の中身：VersionedSchema の中の `@Model` 2つ、SchemaMigrationPlan（stages は空）、`ModelConfiguration(schema:isStoredInMemoryOnly:groupContainer: .none, cloudKitDatabase: .none)`、`ModelContainer(for:migrationPlan:configurations:)`、`@concurrent` の関数。ReadingCore の中身：Codable で Sendable の写しの型と、`Data.write(to:options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])`。
  - `xcodebuild -scheme SpikePkg-Package -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build` → exit 0、`** BUILD SUCCEEDED **`、error と warning の行は0。
  - 分離が効いているかの確かめ：ReadingStore に `nonisolated func probeCallsMainActorMethod(_ box: StoreBox) throws { try box.add(title: "x") }` を足して同じビルド → exit 65、`** BUILD FAILED **`、`error: call to main actor-isolated instance method 'add(title:)' in a synchronous nonisolated context`。確かめたあと、このファイルは消した。
  - 1回目の確かめは Sendable な let を読む形で、分離の外からも読めるのでビルドが通った（確かめにならなかった）。上の2回目で確かめ直した。
- 拡張の分離（7-3 の spike。リポジトリの外の /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-3/。docs/reviews/001-reading-session-G1-7-3-tech-lead.md）
  - 作り：アプリ（Default Actor Isolation は MainActor）、ウィジェットの拡張（nonisolated）、ローカルのパッケージ1つ。拡張に Widget と TimelineProvider を置いた。
  - `xcodebuild -project Spike.xcodeproj -scheme SpikeApp -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath ../dd ARCHS=arm64 SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build` → exit 0、`** BUILD SUCCEEDED **`。
  - 7-4b で build-ni.log を読み直した：`BUILD SUCCEEDED` が1つ。warning の行は2つで、どちらも道具の知らせ（`not stripping binary because it is signed` と `appintentsmetadataprocessor … Metadata extraction skipped`）。コンパイラーの警告は0件。プロジェクトの設定は `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated` が1つ（拡張）、`MainActor` が3つ。
  - SDK の宣言：TimelineProvider の `getSnapshot` と `getTimeline` の completion は `@escaping @Sendable` で、`@preconcurrency` が付く。どの actor にも属さない。
  - `xcrun simctl spawn <端末> pluginkit -mAvvv -p com.apple.widgetkit-extension` に拡張が出た（システムに登録された）。
- 未確認
  - iOS 26 が動く端末の一覧と、動かない端末の利用者の割合。
  - iOS 26.x のシミュレーターの runtime：入れていない（G1-3。入れるかは Takuma）。手順は Apple の文書 https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components 、大きさは Apple silicon 用で 7.99〜8.52 GB（設計メモの 10）。
  - Perf の構成で、ローカルのパッケージが -O で組まれるか（ADR 0005。ios/ を作る最初の PR）。
  - 拡張を MainActor にした変種で、その設定が拡張のコンパイルに渡ったか（採らない案なので、これ以上確かめない）。

## 確かめ（B）
- [x] 案が2つ以上あり、どの案にも悪い点が書いてある
- [x] 反論、悪い結果、見直す条件が空でない
- [x] 確かめたことに、URL かコマンドの出力がある
