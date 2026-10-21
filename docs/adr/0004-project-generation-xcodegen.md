# ADR 0004：Xcode のプロジェクトは XcodeGen の project.yml から CI で作る

- 状態：提案
- 書いた役：tech-lead　日付：2026-10-21
- 関係する PRD、設計メモ、契約：docs/prd/001-reading-session.md（12、18 の P-9、P-10、P-12、P-14）、ADR 0002、ADR 0005、CLAUDE.md（ビルドとテストのコマンドは次の作業で書く）
- 元に戻す手間：中（project.yml から作ったプロジェクトを一度コミットすれば XcodeGen をやめられる。ただし以後は pbxproj を手で直すことになる）

## 背景
- この環境は Linux で、Mac と Xcode がない（docs/progress.md の 2026-10-21 の行）。ios-engineer はコードを書けるが、Xcode でプロジェクトを作れない。
- project.pbxproj は Xcode が書く形式で、ID の参照が多く、手で書くと壊しやすい（推測）。壊れても Linux では気づけない。
- 受け入れテストは ios/AcceptanceTests/ に置く（CLAUDE.md の構成）。アプリ、単体テスト、受け入れテスト（UI テスト）の3つのターゲットが要る。
- テストのつなぎ口の URL scheme を Debug の Info.plist にだけ置きたい（ADR 0005）。構成ごとに Info.plist を分けられる作り方が要る。
- CI は GitHub Actions の macOS（macos-latest）で、app.json の commands を動かす（.github/ と app.json は Takuma だけが直せる）。

## 決定
- ios/project.yml（XcodeGen の形式）をリポジトリに置き、CI で `xcodegen generate` してから xcodebuild でビルドとテストを行う。作った ios/Yomutoki.xcodeproj はコミットしない（.gitignore に足す。次の作業）。
- ターゲットは3つ：
  | ターゲット | XcodeGen の type | ソースの場所 | Bundle ID（仮） |
  |---|---|---|---|
  | Yomutoki | application（iOS 17.0。ADR 0002） | ios/Yomutoki/ | com.example.yomutoki |
  | YomutokiTests | bundle.unit-test（ホストは Yomutoki） | ios/YomutokiTests/ | com.example.yomutoki.tests |
  | YomutokiAcceptanceTests | bundle.ui-testing（対象は Yomutoki） | ios/AcceptanceTests/ | com.example.yomutoki.acceptancetests |
- Info.plist は構成ごとに分ける：Debug は ios/Yomutoki/Info-Debug.plist（テストの URL scheme を持つ）、Release は ios/Yomutoki/Info.plist（持たない）。XcodeGen の settings の configs で INFOPLIST_FILE を分ける（A107）。
- Bundle ID の前半は Takuma の決めること。仮の値 `com.example.yomutoki` を置き、Takuma の実機に入れる前（PRD 14 の1行目の7日間の前。内部の TestFlight か開発の署名）に替える。遅くとも G5 の前。Family Controls の申請（P-10）も本当の Bundle ID が要る。
- CI のシミュレーター向けのビルドは署名しない（CODE_SIGNING_ALLOWED=NO）ので、Team ID がなくても G2 まで進める。
- XcodeGen の入れ方は CI で `brew install xcodegen`（A106）。入った版を CI のログに出す（`xcodegen --version`）。

## 検討した案
| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| XcodeGen の project.yml（選んだ） | YAML で読める。差分が小さい。ターゲットの種類（bundle.unit-test、bundle.ui-testing）と構成ごとの設定がある（A107）。MIT ライセンス（A106） | 第三者の道具に CI が頼る。Homebrew の版を固定していない。Xcode 26 の新しい設定（既定の actor 分離など）を渡せるかは未確認 | － |
| Tuist | Swift でプロジェクトを書ける。キャッシュなどが多い | 道具が大きい。文書をこの環境から確かめていない（未確認） | 3ターゲットには大きすぎる |
| project.pbxproj を手で書く | 第三者の道具が要らない | 形式が Xcode の内部向けで、手で書くと壊しやすい（推測）。Linux で確かめられない | 壊れてもこの環境で気づけない |
| Swift Package だけ（Package.swift） | Linux でも読める。依存の宣言が標準 | iOS のアプリ（Info.plist、Asset Catalog、UI テストのターゲット）を Package.swift だけで作れるかは未確認 | アプリと UI テストのターゲットを作れる確証がない |
| Takuma が Mac の Xcode でプロジェクトを作ってコミットする | 標準の作り方 | Takuma が Mac を持っているかが未定（P-14）。以後の変更のたびに Takuma の手が要る | Takuma の手を待つと進まない |

## いちばん強い反論と、それでも選んだ理由
- 反論：XcodeGen は Apple の道具ではない。Xcode 26 で入った設定（既定の actor 分離、String Catalog の扱い、新しいテストの仕組み）への追従が遅れると、CI のプロジェクトが Xcode で新規に作ったものと違う動きになり、原因が分かりにくい。Homebrew の版を固定していないので、ある日の更新で CI が落ちるおそれもある。
- それでも選んだ理由：XcodeGen は settings にどんなビルド設定でもそのまま書けるので、新しい設定は名前さえ分かれば渡せる（設定の名前そのものは未確認。CI の出力で確かめる）。版は CI のログに出し、落ちたら版を固定する（`mint install yonaskolb/xcodegen@<版>`。A106 の Mint）。Mac が手に入ったら、作ったプロジェクトをコミットして XcodeGen をやめる道も残る（見直す条件）。

## 結果
- これで楽になること：Linux でもプロジェクトの変更（ファイルの追加、ターゲットの設定）を YAML の差分で書いて見られる。Info.plist を構成ごとに分けられる。
- これで難しくなること、守り続けること：ソースのファイルを足したら、project.yml の sources の場所の下に置く（XcodeGen がフォルダを読む）。ビルドとテストのコマンドは `xcodegen generate` を先に動かす形にする（CLAUDE.md と app.json の commands。app.json は Takuma が書く。P-12）。作ったプロジェクトは .gitignore に入れる。
- 元に戻すときの手順と手間：CI で作った Yomutoki.xcodeproj を成果物として取り出してコミットし、project.yml を消す。手間は中（半日程度と推測。以後の変更は Xcode が要る）。

## 見直す条件
- XcodeGen の更新で CI が落ち、版の固定でも直らないことが2回あった。
- XcodeGen の最後のリリースから1年を超えた（2026-10-21 に見た CHANGELOG の最新の見出しは 2.46.0。日付は見ていない）。
- Takuma か作り手が Mac と Xcode を使えるようになった（P-14）。
- Xcode 26 の設定（SWIFT_DEFAULT_ACTOR_ISOLATION など）を project.yml から渡せないと CI の出力で分かった。

## 確かめたこと
- A106 XcodeGen の README（2026-10-21 に https://raw.githubusercontent.com/yonaskolb/XcodeGen/master/README.md を curl で取得。200）。「brew install xcodegen」「mint install yonaskolb/xcodegen」「xcodegen generate … will look for a project spec in the current directory called `project.yml`」「XcodeGen is licensed under the MIT license.」
- A107 XcodeGen の Project Spec（https://raw.githubusercontent.com/yonaskolb/XcodeGen/master/Docs/ProjectSpec.md、200）。ターゲットの種類に `bundle.ui-testing` と `bundle.unit-test` がある。settings に構成ごとの configs と INFOPLIST_FILE を書ける。deploymentTarget を書ける。scheme の testTargets がある。
- A108 XcodeGen の CHANGELOG（https://raw.githubusercontent.com/yonaskolb/XcodeGen/master/CHANGELOG.md、200）。最新の版の見出しは「## 2.46.0」。
- 開けなかったもの：Homebrew の formula（`curl https://formulae.brew.sh/api/formula/xcodegen.json` → 「CONNECT tunnel failed, response 403」）。CI で `brew install xcodegen` が通るかは未確認（CI の出力で確かめる）。
- A104 CFBundleURLTypes iOS 2.0（https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleurltypes 。本文「A list of URL schemes (http, ftp, and so on) supported by the app.」。2026-10-21 に JSON を取得）
- 未確認：Swift Package だけで iOS のアプリと UI テストを作れるか。Tuist の文書。CI の macos-latest の Xcode の版。
- spike：Mac がないので、していない。最初の CI の実行が spike を兼ねる（ios-engineer が出力を報告に貼る）。

## 確かめ（B）
- [x] 案が2つ以上あり、どの案にも悪い点が書いてある
- [x] 反論、悪い結果、見直す条件が空でない
- [x] 確かめたことに、URL かコマンドの出力がある
