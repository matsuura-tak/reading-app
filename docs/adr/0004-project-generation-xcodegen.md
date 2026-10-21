# ADR 0004：Xcode のプロジェクトは XcodeGen 2.46.0 の project.yml から CI で作る

- 状態：提案
- 書いた役：tech-lead　日付：2026-10-21（同日、G1 reviewer r1 の要修正5、6 と提案14、15 で改訂：版を 2.46.0 とチェックサムで固定し、受け入れテストの定義を ios/AcceptanceTests/target.yml に分けた）
- 関係する PRD、設計メモ、契約：docs/prd/001-reading-session.md（12、14、18 の P-9、P-10、P-12、P-14）、ADR 0001（entitlement）、ADR 0002、ADR 0005、CLAUDE.md（ビルドとテストのコマンド、構成）、contracts/dependencies.md（XcodeGen 2.46.0）、docs/adr/features/001-reading-session.md（11 の雛形の作り方）
- 元に戻す手間：中（project.yml から作ったプロジェクトを一度コミットすれば XcodeGen をやめられる。ただし以後は pbxproj を手で直すことになる）

## 背景
- この環境は Linux で、Mac と Xcode がない（docs/progress.md の 2026-10-21 の行）。ios-engineer はコードを書けるが、Xcode でプロジェクトを作れない。
- project.pbxproj は Xcode が書く形式で、ID の参照が多く、手で書くと壊しやすい（推測）。壊れても Linux では気づけない。
- 受け入れテストは ios/AcceptanceTests/ に置き、その中の設定だけで動く形にする（CLAUDE.md）。アプリ、単体テスト、受け入れテスト（UI テスト）の3つのターゲットが要る。
- テストのつなぎ口の URL scheme を Debug の Info.plist にだけ置きたい（ADR 0005）。構成ごとに Info.plist を分けられる作り方が要る。
- CI は GitHub Actions の macOS（macos-latest）で、app.json の commands を動かす（.github/ と app.json は Takuma だけが直せる）。G2 の依存の基準は「版が固定」。

## 決定
- ios/project.yml（XcodeGen の形式）をリポジトリに置き、CI で `xcodegen generate` してから xcodebuild でビルドとテストを行う。作った ios/Yomutoki.xcodeproj はコミットしない（.gitignore の `ios/Yomutoki.xcodeproj/` の行）。
- ターゲットは3つ：
  | ターゲット | XcodeGen の type | ソースの場所 | 定義を書くファイルと役 | Bundle ID（仮） |
  |---|---|---|---|---|
  | Yomutoki | application（iOS 17.0。ADR 0002） | ios/Yomutoki/ | ios/project.yml（ios-engineer） | com.example.yomutoki |
  | YomutokiTests | bundle.unit-test（ホストは Yomutoki） | ios/YomutokiTests/ | ios/project.yml（ios-engineer） | com.example.yomutoki.tests |
  | YomutokiAcceptanceTests | bundle.ui-testing（対象は Yomutoki） | ios/AcceptanceTests/ | ios/AcceptanceTests/target.yml（verifier） | com.example.yomutoki.acceptancetests |
- 受け入れテストのターゲット YomutokiAcceptanceTests と、スキーム Yomutoki の test の受け入れテストのテスト計画（Acceptance.xctestplan）の定義は ios/AcceptanceTests/target.yml に置き、ios/project.yml から `include: [AcceptanceTests/target.yml]` で読む（A107 の Include。「They will be merged in order and then the current spec will be merged on top.」。辞書は合わさり、配列は後ろに足される）。`:REPLACE` は project.yml にも target.yml にも使わない（project.yml の側から受け入れテストの定義を丸ごと置き換えられないようにするため）。target.yml の中のパスは target.yml からの相対（Include の relativePaths の既定）。
- Info.plist は構成ごとに分ける：Debug は ios/Yomutoki/Info-Debug.plist（テストの URL scheme を持つ）、Release は ios/Yomutoki/Info.plist（持たない）。XcodeGen の settings の configs で INFOPLIST_FILE を分ける（A107）。
- アプリのターゲットの entitlements は project.yml の entitlements（path `Yomutoki/Yomutoki.entitlements`、properties に `com.apple.developer.default-data-protection: NSFileProtectionComplete`）で書く（ADR 0001。A107「If defined this will generate and write a `.entitlements` file, and use it by setting `CODE_SIGN_ENTITLEMENTS` build setting for every configuration.」）。
- Bundle ID の前半は Takuma の決めること。仮の値 `com.example.yomutoki` を置き、Takuma の実機に入れる前に替える。遅くとも G5 の前。Takuma が実機で使う7日間（PRD 14 の1行目）は、内部の TestFlight に上げた Release ビルドで使う（Debug の開発の署名で入れない。利用者と同じ最適化で、つなぎ口が入っていないビルドで使うため。G1 reviewer r1 の提案15）。Family Controls の申請（P-10）も本当の Bundle ID が要る。App ID には Data Protection の機能も要る（ADR 0001）。
- CI のシミュレーター向けのビルドは署名しない（CODE_SIGNING_ALLOWED=NO）ので、Team ID がなくても G2 まで進める。
- XcodeGen は 2.46.0 に固定する。GitHub Releases の xcodegen.zip を取り、SHA-256 を確かめてから、展開したまま動かす（A112）。リポジトリの直下で：
  `mkdir -p build/tools && curl -fsSL -o build/tools/xcodegen-2.46.0.zip https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.zip && echo '4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806  build/tools/xcodegen-2.46.0.zip' | shasum -a 256 -c - && rm -rf build/tools/xcodegen && unzip -q build/tools/xcodegen-2.46.0.zip -d build/tools && build/tools/xcodegen/bin/xcodegen --version`
  その後 `cd ios && ../build/tools/xcodegen/bin/xcodegen generate`。CLAUDE.md の ios_build と ios_test の頭はこの形。build/ は .gitignore の `/build/` でコミットしない。版を上げるときは、版とチェックサムを ADR 0004（この行）、contracts/dependencies.md、CLAUDE.md、Makefile の4か所で一緒に直す（`grep -rn '2.46.0' CLAUDE.md Makefile contracts/ docs/adr/` でそろっていることを見る）。

XcodeGen の入れ方：
| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| GitHub Releases の zip を版とチェックサムで（選んだ） | 版と中身が固定される（SHA-256 を CI が確かめる）。作り直さないので速い。zip の中は x86_64 と arm64 の両方の Mac の実行ファイル（A112） | 版を上げるたびにチェックサムを手で写す。zip を展開したまま動かして SettingPresets を見つけるかは未確認 | － |
| `brew install xcodegen` | 1行で入る | 版が固定されない（その日の最新）。Homebrew の formula はこの環境から開けない（403） | G2 の「版が固定」に合わない |
| `brew install mint` の後 `mint run yonaskolb/xcodegen@2.46.0 xcodegen generate`（A106 の Mint） | タグで版を固定できる | Mint そのものは brew の最新で固定されない（未確認）。CI のたびにソースから作るので遅い（推測）。チェックサムがない | zip の方が固定が強く、速い。zip が取れなくなったときの代わりにする |

## 検討した案
| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| XcodeGen の project.yml（選んだ） | YAML で読める。差分が小さい。ターゲットの種類（bundle.unit-test、bundle.ui-testing）と構成ごとの設定、include がある（A107）。MIT ライセンス（A106） | 第三者の道具に CI が頼る。版を上げる手間（4か所）。Xcode 26 の新しい設定（既定の actor 分離など）を渡せるかは未確認 | － |
| Tuist | Swift でプロジェクトを書ける。キャッシュなどが多い | 道具が大きい。文書をこの環境から確かめていない（未確認） | 3ターゲットには大きすぎる |
| project.pbxproj を手で書く | 第三者の道具が要らない | 形式が Xcode の内部向けで、手で書くと壊しやすい（推測）。Linux で確かめられない | 壊れてもこの環境で気づけない |
| Swift Package だけ（Package.swift） | Linux でも読める。依存の宣言が標準 | iOS のアプリ（Info.plist、Asset Catalog、UI テストのターゲット）を Package.swift だけで作れるかは未確認 | アプリと UI テストのターゲットを作れる確証がない |
| Takuma が Mac の Xcode でプロジェクトを作ってコミットする | 標準の作り方 | Takuma が Mac を持っているかが未定（P-14）。以後の変更のたびに Takuma の手が要る | Takuma の手を待つと進まない |

受け入れテストの定義の置き場所：
| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| ios/AcceptanceTests/target.yml を include（選んだ） | 受け入れテストのターゲットとテスト計画を verifier のフォルダに置ける（CLAUDE.md の「受け入れテストのフォルダの中の設定だけで動く」）。ios-engineer の project.yml の変更で受け入れテストの定義が変わりにくい | 合わさった結果は xcodegen generate の後でしか見えない。project.yml の側で同じスキームやターゲットに書き足せば、まだ影響できる（G2 で読む）。target.yml がないうちは generate が落ちる（推測） | － |
| 全部を ios/project.yml に書く | 1ファイルで読める | 受け入れテストを動かす設定が ios-engineer のファイルに入り、テストを弱める変更を G2 で探す対象から漏れやすい（G1 reviewer r1 の要修正6） | 役の境目と合わない |

## いちばん強い反論と、それでも選んだ理由
- 反論：XcodeGen は Apple の道具ではない。Xcode 26 で入った設定（既定の actor 分離、String Catalog の扱い、新しいテストの仕組み）への追従が遅れると、CI のプロジェクトが Xcode で新規に作ったものと違う動きになり、原因が分かりにくい。版を 2.46.0 に固定したので、追従は版を上げるまで入らない。
- それでも選んだ理由：XcodeGen は settings にどんなビルド設定でもそのまま書けるので、新しい設定は名前さえ分かれば渡せる（設定の名前そのものは未確認。CI の出力で確かめる。裁定の追記2 の (8)）。版はチェックサムで固定し、上げるのは CI が落ちたときか見直す条件のときだけにする。Mac が手に入ったら、作ったプロジェクトをコミットして XcodeGen をやめる道も残る（見直す条件）。

## 結果
- これで楽になること：Linux でもプロジェクトの変更（ファイルの追加、ターゲットの設定）を YAML の差分で書いて見られる。Info.plist を構成ごとに分けられる。CI の XcodeGen がいつも同じ中身になる。
- これで難しくなること、守り続けること：
  - ios/project.yml はテストの設定として扱う（スキーム、ビルドの設定、Info.plist の分け方、entitlements、include の行がテストの動きを変えるため）。G2 の reviewer は project.yml の差分を全部読む。受け入れテストのターゲットとテスト計画の定義は ios/AcceptanceTests/target.yml（verifier）にあり、project.yml で `:REPLACE` を使う変更、include の行を消す変更、YomutokiAcceptanceTests か Acceptance.xctestplan に触れる行を足す変更は、G2 で理由を確かめる（`grep -nE 'REPLACE|AcceptanceTests|Acceptance\.xctestplan' ios/project.yml` の行が include の1行だけであること）。
  - target.yml を verifier が書くまで、xcodegen generate は落ちる見込み（include の先がない。推測）。雛形だけの変更は G2 に出さない（裁定の追記2 の要修正4）ので、止める理由にしない。
  - ソースのファイルを足したら、project.yml の sources の場所の下に置く（XcodeGen がフォルダを読む）。ビルドとテストのコマンドは xcodegen generate を先に動かす形にする（CLAUDE.md と app.json の commands。app.json は Takuma が書く。P-12）。作ったプロジェクトは .gitignore に入れる。
- 元に戻すときの手順と手間：CI で作った Yomutoki.xcodeproj を成果物として取り出してコミットし、project.yml と target.yml を消す。手間は中（半日程度と推測。以後の変更は Xcode が要る）。

## 見直す条件
- XcodeGen 2.46.0 で Xcode 26 の設定かプロジェクトの形式が作れないと CI の出力で分かり、版を上げても直らない。
- zip が取れなくなった（404）か、チェックサムが合わなくなった（CI を止めて理由を調べる。差し替えなら Mint の案に替える）。
- XcodeGen の次の版が 2027-07-16 までに出ない（2.46.0 の zip の中のファイルの日付は 2026-07-16。保守が止まった疑い）。
- Takuma か作り手が Mac と Xcode を使えるようになった（P-14）。
- Xcode 26 の設定（SWIFT_DEFAULT_ACTOR_ISOLATION など）を project.yml から渡せないと CI の出力で分かった。
- include の合わせ方（スキームの testPlans の配列、target.yml からの相対のパス）が思ったとおりに動かないと CI の出力で分かった（そのときは include の relativePaths を false にし、パスを ios/ からに書き直す）。

## 確かめたこと
- A106 XcodeGen の README（2026-10-21。タグ 2.46.0 の https://raw.githubusercontent.com/yonaskolb/XcodeGen/2.46.0/README.md を curl で取得）。83行目「mint install yonaskolb/xcodegen」、97行目「brew install xcodegen」。前の作業で master の README から「xcodegen generate … will look for a project spec in the current directory called `project.yml`」「XcodeGen is licensed under the MIT license.」。README に zip の入れ方は書いていない。
- A107 XcodeGen の Project Spec（https://raw.githubusercontent.com/yonaskolb/XcodeGen/master/Docs/ProjectSpec.md、200。2026-10-21 に取得した写しを読んだ）。`bundle.ui-testing` と `bundle.unit-test`。settings の configs と INFOPLIST_FILE。deploymentTarget。scheme の testTargets と testPlans。Include の節「They will be merged in order and then the current spec will be merged on top.」「if existing value and new value are both an array then add the new value to the end of the array」「If you wish to replace a whole value … then just affix `:REPLACE` to the key」、Include Object の relativePaths「Dictates whether the included spec specifies paths relative to itself (the default) or the root spec file.」。entitlements「If defined this will generate and write a `.entitlements` file, and use it by setting `CODE_SIGN_ENTITLEMENTS` build setting for every configuration.」。
- A108 XcodeGen の CHANGELOG（https://raw.githubusercontent.com/yonaskolb/XcodeGen/master/CHANGELOG.md、200）。最新の版の見出しは「## 2.46.0」。
- A112 2.46.0 の zip（2026-10-21 に https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.zip を curl -L で取得）：4,278,764 バイト、SHA-256 `4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806`（sha256sum）。中身（python3 -m zipfile -l）：xcodegen/bin/xcodegen（14,229,032 バイト。file の出力「Mach-O universal binary with 2 architectures: x86_64、arm64」）、xcodegen/share/xcodegen/SettingPresets、xcodegen/install.sh（bin と share を PREFIX に写すだけ）、LICENSE。ファイルの日付は 2026-07-16。この環境は Linux なので動かしていない。
- 開けなかったもの：Homebrew の formula（`curl https://formulae.brew.sh/api/formula/xcodegen.json` → 「CONNECT tunnel failed, response 403」）。brew は使わないことにした。
- A104 CFBundleURLTypes iOS 2.0（https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleurltypes 。本文「A list of URL schemes (http, ftp, and so on) supported by the app.」。2026-10-21 に JSON を取得）
- 未確認：zip を展開したまま bin/xcodegen を動かして SettingPresets を見つけるか（install.sh が bin と share を同じ親に写すので、展開したままでも同じ並びと推測。だめなら `build/tools/xcodegen/install.sh build/tools/prefix` で写してから動かす）。`xcodegen --version` の出力の形。include の先がないときに generate が落ちるか。Swift Package だけで iOS のアプリと UI テストを作れるか。Tuist の文書。CI の macos-latest の Xcode の版。`brew install mint` が通るか（使わない案）。
- spike：Mac がないので、していない。最初の CI の実行が spike を兼ねる（ios-engineer が出力を報告に貼る。裁定の追記2 の (1)）。

## 確かめ（B）
- [x] 案が2つ以上あり、どの案にも悪い点が書いてある
- [x] 反論、悪い結果、見直す条件が空でない
- [x] 確かめたことに、URL かコマンドの出力がある
