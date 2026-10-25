FAIL

## 指摘

1. 重大。場所は design/tokens.md:20、design/tokens.md:74、design/001-reading-session.md:412、:504（:427 も関係）。
   - 何が問題か：S2 の「追加」（book.save）と S5 の「保存」（session.finish.save）は、シートのツールバーの確定のボタンです。仕様はこれを「color.accent の文字 / color.background.grouped」の組として計算しています（7.01:1、8.08:1）。けれども HIG は、この位置の主な操作を .prominent にするよう求めています。その場合、システムはボタンの背景をアクセント色で塗り、既定のコントラストではラベルを白にします。ダークの既定では、白 / #C99671 = 2.60:1 です。17pt 以下の文字の 4.5:1 にも、操作部品の 3:1 にも届きません。
   - 根拠：
     - HIG Toolbars「Use the `.prominent` style for key actions such as Done or Submit. This separates and tints the action」
     - HIG Color（Liquid Glass color）「the system applies the app accent color to the background in prominent buttons — such as the Done button」。同じページの画像の説明では、既定のコントラストではライトもダークも Done のラベルが白で、コントラストを上げると黒になります。
     - HIG Buttons「use a prominent button style so the system can apply an accent color to the button's background」
     - WCAG 1.4.3 と 1.4.11、PRD 12（4.5:1。ダークもライトと同じ基準）
     - AC-2、AC-4、AC-9、AC-10、AC-12、AC-49、AC-50 の主な流れで毎回押すボタンです（NN/g の3で、主な流れの上なので重大）。
     - tokens.md:20 の「これ以外に使わない」も、システムがアプリのアクセントを付ける場所（目立つツールバーのボタン、alert の既定のボタン、カーソル）を数えていません。
   - 直す方向：S2 と S5 の確定のボタンの形（.prominent にするか）とラベルの色を仕様で決め、その組を3通りの表（tokens.md の 5、仕様の 9）に足します。案は次のとおりです。
     - (a) ラベルを color.text.onAccent にし、システムがそれを守ることを tech-lead が spike で確かめる。
     - (b) ダークの塗りを、白い文字で 4.5:1 以上になる暗さにする（相対輝度 0.183 以下。今の #C99671 は 0.354）。ただし、同じ色を黒い背景の上の文字（「読書中」「もう一度保存」）にも使うと、どちらも 4.5:1 を満たす幅は相対輝度 0.175〜0.183 しかありません。塗り用と文字用でトークンを分けるかを決めてください。
     - システムがアクセントを付けるほかの場所も表に足します。G3 では、ダークの S2 と S5 のスクリーンショットと contrast の監査で確かめます。

2. 重大。場所は design/tokens.md:17、:78、design/001-reading-session.md:178（D-24）、:199（D-45）、:209、:508、design/001-reading-session/screens.md:146、:219、:235-236。
   - 何が問題か：17pt 以下の文字に color.text.secondary（secondaryLabel）を使っているのに、コントラストを「システム色」「システムが保証する組」として計算していません。secondaryLabel の値 rgba(60,60,67,0.6) で計算すると次のとおりです。
     - ライトの既定：#FFFFFF の上で 3.44:1、#F2F2F7 の上で 3.29:1
     - コントラストを上げる設定（アルファ 173/255）：4.22:1 と 3.90:1
   - 4.5:1 に届かない文字：
     - S4 の「72ページから」（.subheadline。差1）
     - S4 の「一時停止中」（.subheadline）
     - S2 の book.add.titleLimit（.footnote）
     - S3 の記録の日付（.subheadline）
     - 欄の下のヒント（.footnote）。S5 の「入れずに保存もできます。」は、差1「挟む」の要の文です。
   - placeholderText（アルファ 0.3）は #FFFFFF の上で 1.74:1 です。S2 の題名が必須であることは、placeholder の「必須」でしか伝えていません。
   - 根拠：
     - PRD 12「文字と背景のコントラストは4.5:1以上」
     - HIG Accessibility の表（17pt までは 4.5:1）と「If your app doesn't provide this minimum contrast by default, ensure it at least provides a higher contrast color scheme when the system setting Increase Contrast is turned on」。システム色の既定が基準を満たすとは書いていません。
     - HIG Dark Mode「Using system-defined colors can help you achieve a good contrast ratio」。助けになる、であって保証ではありません。
     - WCAG 1.4.3。採点表 F の★は独自の色に限りません。
     - 値の出典は検索の抜粋で、ページは開けませんでした。ただし designer の側に計算がないので、比の値によらず、少なくとも★は未検証です。
   - 直す方向：17pt 以下で情報を持つ文字に使うシステム色の組を3通りで計算し、表に足します。4.5:1 に届かない組は、color.text.primary にして階層は大きさと太さで作る（B-4）か、3通りで 4.5:1 以上になる補いの文字のトークンを足します。一時停止中の経過（.largeTitle）は 3:1 の基準なので 3.44:1 で足りますが、表に書きます。「必須」「任意」は placeholder だけに頼らず、見出しか footer の文でも伝えます。

3. 要修正。場所は design/tokens.md:20、design/001-reading-session.md:209、:412、:436、:505、design/001-reading-session/screens.md:126、:222。
   - 何が問題か：color.accent を、押せる文字のボタン「もう一度保存」（error.retry）と、押せない状態の文字「読書中」（reading.state）の両方に使っています。
   - 根拠：HIG Color「Avoid using the same color to mean different things ... if you use your brand color to indicate that a borderless button is interactive, using the same or similar color to stylize noninteractive text is confusing.」。Nielsen 4（一貫性）。調査の差2（design/001-reading-session-research.md:129「アクセント色は主操作にだけ使う」）とも食い違います。
   - 直す方向：アクセントの意味を1つにします。たとえば「読書中」を color.text.primary にする（状態は文字とボタンの「一時停止」で伝わる）か、「もう一度保存」を .bordered のボタンにします。8 と 9 の表も合わせます。

4. 要修正。場所は design/001-reading-session.md:206（S1）、:208（S3）、:209（S4）、:515-516（10 の 1 と 2(e)）。
   - 何が問題か：読み始め（S1、S3 の主操作）、一時停止、再開の保存に失敗したときに、何を出すか、文言のキー、次にできる操作が決まっていません。保存されていない読書は、強制終了すると AC-8 と AC-33 の復元が効かず、利用者は気づかないまま失います。
   - 根拠：Nielsen 9（エラーからの回復）と 1（状態の見える化）。HIG Design principles「Provide clear feedback」「Recovering from the unexpected shouldn't cost people their time or work.」。採点表 E の「状態ごとに、表示する内容、文言のキー、次にできる操作」。
   - 直す方向：S1、S3、S4 のエラーの列に、この失敗のときの表示、ja と en のキー、次の操作を仮でも決めます。AC を足すことは、指揮役を通して pdm に渡します。

5. 要修正。場所は design/001-reading-session.md:274、:366、:111、design/001-reading-session/screens.md:169-171。
   - 何が問題か：記録の行の「32ページ」は、その読書で進んだページ数（AC-9 の「読んだページ」）です。けれども同じ「%lldページ」の形を、ページ番号の意味でも使っています（:374「%lldページから」、:384「前回は%lldページでした」）。そのため行の表示は「32ページまで読んだ」とも読めます。読み返しの記録は「0ページ」と出ます。VoiceOver も「30分」「32ページ」と続けて読むだけです。
   - 根拠：Nielsen 2（実世界との一致）と 4（一貫性）。PRD の AC-9 と AC-29 の言葉は「読んだページ」です。
   - 直す方向：量であることが文字で分かる形にします（例：「32ページ進んだ」、en「32 pages read」）。テストが読む値（label か value）の決まりも 6 に書きます。

6. 提案。design/001-reading-session.md:148、:165（D-11）、design/001-reading-session/screens.md:259。S5 の主操作「保存」は右上にあります。調査の S-3（片手で本にしおりを挟みながら入れる。research:34）と D-8 の理由（片手の親指で届く場所）に照らすと、いちばん届きにくい位置です。数字のキーボードには確定のキーもありません。標準の ToolbarItemPlacement.keyboard でキーボードの上に「保存」を足すか、右上でよい理由を書いてください。

7. 提案。design/001-reading-session.md:494。「英語が2倍を超える文言」として5つだけを挙げていますが、文字数で数えると67キーのうち33キーが2倍を超えます（例：action.continue 3.2倍、action.resume 3.0倍、session.finish.page.label 2.4倍）。S5 の LabeledContent の項目名（「Current Page」「Minutes Read」）は欄と横に並びますが、Double-Length で確かめる画面（:490-493）に入っていません。

8. 提案。design/001-reading-session.md:162（D-8）。根拠の R-23 と R-24 は、どちらも抜粋だけです。調査の決まり（research:7「抜粋だけの R は、それ1つで決定を支えない」）に合いません。開いて確かめた R か PRD と組にしてください。

9. 提案。design/001-reading-session.md:157（D-3）、:172（D-18）、:144-150。S5 は、入れた値があっても下へのスワイプで確認なしに閉じます。これは HIG Sheets の「If people have unsaved changes in the sheet when they begin swiping to dismiss it, use an action sheet to let them confirm their action.」から外れます（D-18 では S2 にこの文を引いています）。理由（AC-46、AC-48）は 1 と 5 にあるので、3 の逸脱の欄にも書いてください。

10. 提案。design/001-reading-session.md:99、:187（D-33）。別の本が読書中のとき、S3 は理由の文で「その読書を終える」と言いますが、その読書へ行く手段がこの画面にありません（Nielsen 3、7）。

11. 提案。design/001-reading-session.md:334-335。英語のボタン「Back to Reading」「Back to Paused Reading」は動詞で始まっていません（HIG Buttons「consider starting the label with a verb」）。例：「Return to Reading」。

## 採点表

| カテゴリ | 点 | ★と項目の結果 | 証拠 |
|---|---|---|---|
| A 根拠 | 2 | ★ 調査が先：満たす。★ 決定表：満たす。★ 意味のある狙い：満たす | 調査 f8ae3e8（2026-10-21 14:59:31）は仕様 1a24ca0（15:33:10）より前で、その後は変えていない。R は28件で、URL か確認日のない R は0件。競合3件（Bookly、Bookmory、Apple ブックの読書目標）に URL、良い点、悪い点がある。手本は Crouton。D-1〜D-45 の45行すべてに、調査に実在する R-n と HIG の URL か B-n がある（照合で問題0行、comm の出力は空）。ターゲットを「仮説」と書いている（research:28）。性格語は4語で、意味しないことがある（research:90-95）。仕様で表れる場所は spec:429-433、差をつける点は spec:434-436、方向性の2案は research:139-148 |
| B HIG と標準部品 | 2 | ★ 標準部品：満たす。★ 逸脱の表：満たす。Liquid Glass：満たす | spec:144-150。逸脱は S1 と S3 の主操作の置き場所、S3 の題名、S5 の数字の欄で、本来の部品、理由、対応がある。D-29、tokens:62。grep で glassEffect は0件 |
| C バウハウス | 1 | ★ B-1、B-2：満たす。文字：満たす。色：満たさない（指摘3）。余白：満たす | 3 の表で全画面に仕事1文と主操作1つがある。grep で gradient と shadow は0件。各画面の文字の段は4つ以内で書体は1つ（spec:413-418）。余白は tokens:47-57 |
| D 使いやすさ | 2 | Nielsen の重大な違反：なし。取り消せない操作：S6 で確かめる。エラーの文言：何が起きたかと次の一手がある | 下の画面ごとの表。error.saveFailed.*、error.loadFailed.message |
| E 状態 | 1 | ★ 7つの状態：満たす。状態ごとの内容、キー、次の操作：一部足りない（指摘4）。長い文字、0件、大量：満たす | S1〜S7 の7行×8列で空欄は0。spec:214-218 |
| F アクセシビリティ | 0 | ★ コントラスト：満たさない（指摘1、2）。★ 44×44pt：仕様の上では満たす。★ アイコンだけの操作のラベル：満たす。そのほか：満たす | designer の24組は私の計算と一致した。表にない組が 2.60、3.44、3.29、4.22、3.90、1.74:1。44pt は D-43、spec:495 で、実測は G3。「＋」のラベル「本を追加」（spec:239）、trash のラベル「削除」（:275）。AX5 の並びは spec:463-469、色だけで伝えない工夫は :470-474、飾りの記号と動きは :476 と :489 |
| G 一貫性 | 2 | トークンだけを使う：満たす。同じ働きは同じ部品：満たす | hex が出るのはトークンの定義とコントラストの証拠だけ。新しいトークンの理由は tokens:25-29 |
| H 文言 | 1 | 日英がそろう：満たす。英語が2倍を超える文言の確かめ：おおむね満たす（提案7）。VoiceOver のラベルが見える文字で始まる：満たす。「32ページ」：要修正（指摘5） | 7章の67キーで ja か en が空のものは0件。S1 の主操作のラベルは題名から始まる |

合計は 11/16 点です。F の★（コントラスト）を満たさず、F が0点で、13点未満、重大は2件です。合否の線を満たしません。

## 証拠

- 対象：design/001-reading-session.md（e893621）、design/001-reading-session-research.md（f8ae3e8）、design/tokens.md（1a24ca0）、design/001-reading-session/screens.md（e893621）、docs/prd/001-reading-session.md（AC-1〜AC-55）。git status は空。作り手の報告は指示書の入力になかったので読んでいません。

- 観点の表1：AC ごとの流れ（1周目）。どれも仕様 2 の行で、AC-n の行は spec:(82+n) です。
  - 55件すべてたどれました。
  - 注記：
    - AC-16、AC-38、AC-43 は、システムの部品に識別子が付くかが仕様の 10 の 2(b) で未解決です。
    - AC-17、AC-27、AC-52 の finishing は、承認の記録の裁定どおり S5 のキャンセルを通ります。
    - AC-9、AC-29 の文言は指摘5を見てください。
    - AC-2、AC-4、AC-9、AC-10、AC-12、AC-49、AC-50 の確定のボタンは指摘1を見てください。
    - AC-4 のタップは library.addBook、book.save、book.startReading の3回です。
  - 行き止まりはありません（S1 の読み込みの失敗は「もう一度読み込む」だけで、D-44 の意図どおり）。戻れない所もありません。確認のない取り消せない操作もありません。

- 観点の表2：画面ごとの Nielsen（5 はエラーの予防、9 はエラーからの回復）

  | 画面 | 5 と 9 |
  |---|---|
  | S1 | 5：間違えて読み始めても、60秒未満なら記録しない。読み込みの失敗のときは「＋」を出さない（D-44）。9：読み込みの失敗の文言と「もう一度読み込む」がある。読み始めの保存の失敗は決まっていない（指摘4） |
  | S2 | 5：入力が無効なら「追加」を押せない。打つたびに確かめる。入力があるときは確認してから閉じる。二度押しを防ぐ。9：保存の失敗は区画と「もう一度保存」で、入力は残る |
  | S3 | 5：S6 で確かめる。別の本が読書中なら主操作を無効にして理由を出す。9：S7。読み始めの保存の失敗は決まっていない（指摘4）。ほかに 2、4 は指摘5、3 は提案10 |
  | S4 | 5：2つのボタンは同じ大きさで、間は 16pt。間違えて「終える」を押しても S5 のキャンセルで戻れる。9：時計が戻っても負にしない（AC-41）。一時停止と再開の保存の失敗は決まっていない（指摘4） |
  | S5 | 5：打つたびに確かめ、範囲の外なら「保存」を押せない。分は経過の分数で初めから入る。二重の保存を防ぐ。9：保存の失敗は区画と「もう一度保存」で、値は残る。キャンセルで読書に戻れる |
  | S6 | 5：削除の確認で、引く分数と元に戻せないことを書く。9：失敗したら S7 |
  | S7 | 5：該当なし（知らせだけ）。9：記録が残っていることと、次の一手を書いている |

- 読んだファイル：
  - .claude/agents/design-reviewer.md、.claude/skills/craft-designer/SKILL.md、docs/org/gates.md
  - docs/approvals/001-reading-session-G0.md、docs/prd/001-reading-session.md
  - design/001-reading-session-research.md、design/001-reading-session.md、design/tokens.md、design/001-reading-session/screens.md
  - docs/templates/review-report.md、design-spec.md、design-research.md

- 実行したコマンドと結果：
  - `git log --diff-filter=A --format='%h %ci %s' -- design/001-reading-session-research.md design/001-reading-session.md` の出力：
    ```
    1a24ca0 2026-10-21 15:33:10 +0000 …仕様
    f8ae3e8 2026-10-21 14:59:31 +0000 …調査
    ```
    調査のファイルの履歴は f8ae3e8 の1件だけです。
  - `grep -cE '^\| R-[0-9]+' …research.md` → 28。URL か確認日のない R → 0。
  - `comm -23 <(grep -oh 'R-[0-9]\+' design/001-reading-session.md | sort -u) <(… research …)` → 空（tokens.md に対しても空）。
  - python3 -c で決定表を照合：45行、R の欠け0、原則の欠け0。抜粋だけの R に頼る行は D-8 の1つ。
  - python3 -c で AC の対応表を照合：55行で、欠けも余りもなし。PRD の Then に出る識別子38個は、すべて仕様にある。
  - python3 -c で状態の表を照合：S1〜S7 がそれぞれ8列で、空欄なし。
  - 英日の長さの比：2倍を超えるキーは67のうち33。
  - コントラスト（手引きと同じ WCAG の式。確かめに 8E8E93/FFFFFF → 3.26）。designer の24組はすべて一致しました。
    - onAccent / accent：7.83、8.08、HC 10.79、11.63
    - accent / screen：7.83、8.08、10.79、11.63
    - accent / grouped：7.01、8.08、9.08、11.63
    - accent / row：7.83、6.55、10.79、8.58
    - error / grouped：3.20、6.12、3.83、7.15
    - error / row：3.57、4.96、4.56、5.28
  - 表にない組：
    - FFFFFF / C99671 = 2.60
    - FFFFFF / E3B994 = 1.81
    - secondaryLabel（ライト）：#8A8A8E/#FFFFFF = 3.44、#85858B/#F2F2F7 = 3.29。コントラストを上げる設定：#7B7B7F/#FFFFFF = 4.22、#74747B/#EBEBF0 = 3.90。ダーク：#8D8D93/#000000 = 6.36、#98989F/#1C1C1E = 5.94
    - placeholderText：#C4C4C7/#FFFFFF = 1.74
    - 相対輝度：#C99671 = 0.354。白い文字で 4.5:1 になる上限は 0.1833、黒い背景の上の文字で 4.5:1 になる下限は 0.175。

- 開いた URL（2026-10-21）：
  - https://developer.apple.com/design/human-interface-guidelines/color.md （systemRed と systemGray6 の値が designer の値と一致。Liquid Glass color の節）
  - https://developer.apple.com/design/human-interface-guidelines/dark-mode.md
  - https://developer.apple.com/design/human-interface-guidelines/accessibility.md
  - https://developer.apple.com/design/human-interface-guidelines/sheets.md
  - https://developer.apple.com/design/human-interface-guidelines/toolbars.md
  - https://developer.apple.com/design/human-interface-guidelines/buttons.md
  - https://developer.apple.com/design/human-interface-guidelines/typography.md
  - https://developer.apple.com/design/human-interface-guidelines/design-principles.md
  - https://developer.apple.com/design/human-interface-guidelines/materials.md
  - https://developer.apple.com/design/human-interface-guidelines/alerts.md
  - https://developer.apple.com/design/human-interface-guidelines/entering-data.md
  - https://developer.apple.com/news/?id=9x75y43e （Crouton の記事。2024-11-04。R-3 の引用4つがある）
  - https://developer.apple.com/design/awards/ （2026 年の賞。R-5 の引用がある）
  - 調査の R-1、R-3、R-5、R-9〜R-13 と、決定表が引く HIG の文は、開いたページにありました。
  - 開けなかったもの（ENOTFOUND）：https://getbookly.com/ 、https://apps.apple.com/us/app/bookly-book-tracker/id1085047737 、WebKit と Flutter のページ。
  - 検索：「UIColor secondaryLabel light mode value rgba(60, 60, 67, 0.6) contrast ratio WCAG」。抜粋に出たページ：WebKit の apple-system-control-colors-expected.txt、Flutter の CupertinoColors.secondaryLabel。

- 未検証：
  1. secondaryLabel と placeholderText の正確な値。抜粋だけで、Apple の開けるページに値の表がありません。指摘2の比はこの値によります。ただし★を満たさないという結論は、designer の側に計算がないことで決まります。
  2. 独自のアクセント色でも、iOS が .prominent の確定のボタンのラベルを既定で白にするか。根拠は HIG Color の画像の説明です。tech-lead の spike か G3 で確かめます。
  3. systemGroupedBackground と secondarySystemGroupedBackground の値。designer は systemGray6 と同じ値と仮定しており、その値で計算し直しました。
  4. 競合のページの中身（R-14〜R-28）。ネットワークの方針で開けませんでした。調査は、見ていないものを「見ていない」と正直に書いています。
  5. 44×44pt、AX5、VoiceOver の実際の画面。Mac がないので、仕様の文で見ました。G3 で確かめます。

## 記録（指揮役）
- 関門：G1
- 判定した役：design-reviewer
- 回：r1
- 対象：design/001-reading-session.md、design/tokens.md、design/001-reading-session/screens.md（コミット e893621）、design/001-reading-session-research.md（f8ae3e8）
- 日付：2026-10-21
- 指揮役の扱い：重大2件と要修正3件を designer に直させ、r2 を回す。指摘4（読み始め・一時停止・再開の保存の失敗）の AC は pdm に足させる。
