（指揮役の注）G1 の 7-4b（設計メモの仕上げ、ADR 0001 の直し、契約の仕上げ、CLAUDE.md、G1-3 の調べ）の、tech-lead の報告。reviewer に見てほしい所、Takuma に頼む中身、未解決を残すため保存した。判定ではない。報告の文はそのまま保存した。

## 変更したファイル
コミットはしていません。`git status --short` で私が変えたのは次の6つだけです（.agents/、.codex/、AGENTS.md は始める前から未追跡でした）。
- /Users/takumamatsuura/reading-app/docs/adr/features/001-reading-session.md（全体を書き直し。git diff は 240 行）
  - 2：表で変えた行は9つだけです（AC-4、9、10、11、113、93、100、101、102）。git diff で確かめました。
    - AC-4 は cnt=200 で1回とし、端末で並べ直すことを書きました。「（仮）」は外しました。
    - AC-4、AC-9〜11、AC-113 に H29 を足しました。
    - AC-100〜102 は「G3 は Perf、G4 は Release」としました（裁定 29）。
  - 3：契約3つへの矢印の対応、構成3つ、つなぎ口が Release に入らないこと（ADR 0005、test-hooks.md）を書きました。
  - 4：契約7つの表、spectral、oasdiff、JSON Schema の出力、互換の決まりを書きました。
  - 5：要素の対応は契約の対応表を指し、写しは widget-snapshot.schema.json を指すようにしました。知らない値の［推測］は外しました。
  - 6：速さの行（G3 は Perf、G4 は Release）と、書誌の問い合わせ（30秒、2 MB）を書きました。
  - 7：S、T、I、D、E の行を、決まった値と契約を指す形に直しました。
  - 8：G1-11 の表を書きました。
  - 9：外部の依存なし、とだけ書きました。
  - 10：ADR 0001〜0005 の未確認の表、G1-3、ほかの役への申し送りを書きました。
  - 確かめ（A）：9つすべてに印を付けました。
- /Users/takumamatsuura/reading-app/docs/adr/0001-ios-foundation.md
  - 拡張の nonisolated の［推測］を外し、7-3 のビルドのログを読み直した証拠を足しました。
  - 決定に「構成は Debug、Perf、Release の3つ」を足しました（理由は ADR 0005 を指します）。
  - G1-3 と未確認の項目を直しました。
- /Users/takumamatsuura/reading-app/contracts/.spectral.yaml（新規）：`extends: ["spectral:oas"]` と説明のコメントだけです。
- /Users/takumamatsuura/reading-app/contracts/entry-urls.md
  - 5：「launch のほかの出どころが0」に直しました。
  - 6：H28 は test-hooks.md の H28 を指すようにしました。
- /Users/takumamatsuura/reading-app/contracts/dependencies.md
  - 芯は外部のライブラリなし、と書きました。
  - 表に足りなかった列を足しました。
  - 「検査の道具（アプリの依存ではない）」の表を足しました：spectral 6.17.0、oasdiff 1.34.0、jsonschema 4.25.1。
- /Users/takumamatsuura/reading-app/CLAUDE.md（63行）
  - 概要を書きました。
  - iOS のコマンドは、どれも「未確認、形だけ」です。
  - 契約の検査のコマンドは、動かして確かめたものです。
  - 構成の表からバックエンドの2行を消しました。
  - 決まりを10行書きました。

## 実行したコマンドと結果
作業のメモは /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-4b/notes.md にあります。
- spectral v6.17.0（7-2 で置いた配布ファイル。sha256 の頭は cb7e1bd31d85a992）
  - `lint contracts/ndl-opensearch.yaml --ruleset contracts/.spectral.yaml` → `No results with a severity of 'error' found!`、exit 0
  - `--fail-severity hint` を付けても `No results with a severity of 'hint' or higher found!`、exit 0
  - ほかに出たのは、道具の知らせの punycode の DeprecationWarning だけです。
- oasdiff
  - brew、go、node はありません。GitHub の公式リリース v1.34.0 の darwin_all を scratchpad に落としました。sha256 34f5713d…7952 は checksums.txt と一致しました。
  - `git show origin/main:contracts/ndl-opensearch.yaml` は exit 128 でした。origin/main の contracts/ は .gitkeep と dependencies.md だけなので、「新規」です。
  - 空の基準（`openapi: 3.1.0`、`paths: {}`）と比べました。
    - `oasdiff breaking --fail-on ERR` → `No breaking changes to report, but the specs are different.`、exit 0
    - `changelog` → `1 changes: 0 error, 0 warning, 1 info [endpoint-added] GET /api/opensearch`
  - 空振りしていないかの確かめ：逆向きでは `1 error [api-path-removed-without-deprecation]` で exit 1、同じ契約どうしでは `No changes detected` でした。
- JSON Schema
  - 新しい venv（Python 3.9.6）に `pip install 'jsonschema==4.25.1'` を入れ、CLAUDE.md に書いた1行のコマンドを動かしました → `schemas 8 examples 16 OK`、exit 0。
  - required の項目がない例を持つスキーマを渡すと、ValidationError で落ちました。
  - 7-4a の check.py をもう一度動かしました：metaschema 8/8 OK、例 16/16 OK、契約に合わない形は17通りすべて弾かれ、NG は0件でした。
- 照合
  - PRD の AC 136件と、設計メモの 2（芯 85＋選択肢の範囲 51）は、数も番号の組も一致しました（欠け []、余り []）。
  - 7-4a の xcheck.py：H29 が `uses=6 doc=6` になり、つなぎ口はすべて一致しました。
  - 「7-4 で」「（仮）」「［推測。7-」は、設計メモに残っていません（0件）。
- G1-3 の調べ（ダウンロードはしていません）
  - `xcrun simctl list runtimes` は iOS 27.0 と visionOS 27.0 だけです。iOS 27.0 はディスクで 8.07 GB です。空きは 322 GiB です。
  - Apple の文書 https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components を JSON で読みました。`-downloadPlatform`、`-buildVersion <osversion>`、`-exportPath`、`-importPlatform` があり、Apple silicon の Mac では arm64 の版を落とします。
  - 配布の一覧 https://devimages-cdn.apple.com/downloads/xcode/simulators/index2.dvtdownloadableindex を読みました。
  - `xcrun simctl runtime` に delete があります。
- G1-11：https://developer.apple.com/documentation/analytics-reports を JSON で読みました。
  - Apple は Analytics Report Request を作るまでレポートを作りません。
  - できたレポートは35日で消えます。過去の分をまとめて取れるのは月に1回です。
- 7-3 のビルドのログ（build-ni.log）
  - `BUILD SUCCEEDED` は1回です。
  - warning の行2つは、どちらも道具の知らせです。
  - `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated` があります。
  - TimelineProvider は spike/Widget/SpikeWidget.swift にあります。

## Takuma に頼む app.json の commands の案
ios/ がまだないので、名前（<>）が決まらず、どれも動かせていません。<> のまま入れると CI が落ちます。だから、ios/ を作る最初の PR で名前が決まってから入れるよう勧めます。決まったら tech-lead が CLAUDE.md を直し、最終の文字列を出します。
- ios_build：`xcodebuild -project ios/<プロジェクト>.xcodeproj -scheme <アプリのスキーム> -configuration Debug -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build`
- ios_test：`xcodebuild test -project ios/<プロジェクト>.xcodeproj -scheme <アプリのスキーム> -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' -skip-testing:<受け入れテストのターゲット>/FirstLaunchTests`
- backend_test：空のまま（サーバーがありません）。
- 任意の頼みが2つあります。
  - paths.acceptance_tests の backend/tests/acceptance/ を外すこと。
  - 契約の検査（spectral、oasdiff、jsonschema）を CI に入れること。.github/ の変更が要ります。

## G1-3 の手順と大きさ
- 手順
  1. `xcodebuild -downloadPlatform iOS -buildVersion 26.5`
  2. 落とすのと入れるのを分けるなら、`-exportPath <外>` で dmg を落とし、`xcodebuild -importPlatform <dmg>` で入れます。
  3. `xcrun simctl list runtimes` で入ったことを確かめます。
  4. 要らなくなったら `xcrun simctl runtime delete <id>` で消します。
- 大きさ（Apple silicon 用）
  - 26.5（23F77）は 8.52 GB です（universal は 10.60 GB）。
  - 26.0（23A343）は 7.99 GB です。
  - 26.x の正式版は 7.99〜8.52 GB です。入れたあとのディスクもほぼ同じです。
- 推奨は 26.5 の1つです［推測：iOS 27 に上げられない端末の人は、26 の最後の版にいる見込み］。
  - 反論：26.0〜26.4 だけにある不具合を見落とします。
- 未確認：Xcode 27.1 が 26.x の runtime を受け付けるか、iPhone 17 の型を 26.x で作れるか。
- 入れないなら、iOS 26 は G4 の実機だけで確かめます。

## reviewer に特に見てほしい所
私が書いて私が印を付けたので、合格にはしていません。反論をお願いします。
1. 設計メモ 8 の G1-11：R-1 の代わり（購入の件数 ÷ 最初のダウンロード数）を撤退の判定に使う点。「売上は分析の共有の同意に左右されない」は［推測］です。
2. 確かめ（A）の印の付け方
   - 1：選択肢の51件を、裁定 24 により範囲の行で数えたこと。
   - 3：problem+json は対象外としたこと。HTTP 200 のほかの応答には例がないこと。
3. ADR 0001 の拡張の分離：7-3 の spike（アプリの外のプロジェクト）の証拠で足りるか。Perf を ADR 0001 の決定に足したこと。
4. 設計メモ 5：置き場所と書誌の状態の知らない値は「起きない」とした理屈。
5. 道具を npx や brew でなく、GitHub の配布ファイルで動かしたこと。spectral の sha256 は 7-2 の記録で、公開されている値とは照らしていません。

## 未解決
1. 積読の並びに使う日時（AC-13）。pdm と designer が決めることです。
2. G1-13（ラテン文字の著者。推奨は案 C）を誰が決めるか。
3. 書名で探す結果の並べ直し（AC-4）を AC にするか。pdm と verifier に聞きます。
4. PRD 12 に、裁定 29 の読み方を pdm が書き足すこと。
5. G1-3：入れるか、どの版にするかを Takuma が決めます。
6. app.json の commands：ios/ の名前が決まるまで入れられません。
7. Analytics Report Request を公開の前に作ること。Takuma のアカウントの操作で、G5 の前が目安です。
8. App Store Connect の少人数の値を出さない線（5未満など）は、Apple の文書で確かめていません。
9. ADR 0001〜0005 の未確認は、設計メモ 10 の表のとおりです。主に、ios/ を作る最初の PR、G3、G4 で確かめます。
10. designer への申し送り（7-3 の6点、`settings.dataSources` の文、`widget.unavailable` の文）。
11. spectral の npx の道は、node がないので確かめていません。
12. 未着手：なし（手数は42回）。

## 記録（指揮役が保存するときに書き足す）
- 種類：作り手（tech-lead）の報告（判定ではない）
- 書いた物：docs/adr/features/001-reading-session.md、docs/adr/0001-ios-foundation.md、contracts/.spectral.yaml、contracts/entry-urls.md、contracts/dependencies.md、CLAUDE.md（コミット 05c2a39）
- 日付：2026-10-20
- これで G1 の 7（裁定 27、28 の4回）が終わった。次は /feature の 8（reviewer、観点は設計）
