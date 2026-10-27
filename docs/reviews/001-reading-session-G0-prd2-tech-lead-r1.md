（指揮役の注）G0 の判定（tech-lead、r1）。対象は「夜の入口、本の出口」の v1 の PRD（docs/prd/001-reading-session.md、コミット ba9bbf6）。回数は裁定 7 で数え直した。裁定 9 のとおり2体に分けた（その1：実現性、非機能、費用、プライバシー、計測／その2：第1部の根拠と「G0 の前の確認」の全項目）。2つの報告の文はそのまま保存した。合わせた結果は FAIL（その1 が FAIL、その2 が PASS）。

# その1：実現性、非機能、費用、プライバシー、計測

FAIL

（tech-lead その1：実現性、非機能、費用、プライバシー、計測。対象は docs/prd/001-reading-session.md（ba9bbf6。HEAD は 8b1228f で、PRD の差分なし）と docs/prd/product.md の 6。範囲の外の第1部の根拠と「G0 の前の確認」はその2が見ます。）

結論：91件の AC は、サーバーなし、iOS 26、Apple の標準フレームワークと書誌の外部 API で作れます。作れない AC はありません。ただし、直さないと通さない点が5つあります。
- 名前のそろえ方が、AC-21 と実際の書誌の形の両方に合わない
- NDL サーチが求めるクレジットの表示がない
- 2週の枠に入らない見込み
- 計測の (c) に、審査ガイドライン 5.1.1(ii) の同意が要る
- 写真の読み取りの速さの線が、毎晩の使い方を測っていない

## 指摘

### 1. 名前のそろえ方が AC-21 と食い違い、実際の書誌の著者の形ではほとんど合わない
- 重さ：直さないと通さない（重大）
- 場所：11 の冒頭の名前のそろえ方（221行）。AC-21（377〜382行）。影響は AC-17〜AC-21、AC-78〜AC-80、AC-87（「同じ著者」）、奥付の著者の表示。
- 理由と証拠：
  - 決まりの (1) は NFKC にする。NFKC にすると「，」「．」「［」「］」は半角の「,」「.」「[」「]」に変わる。ところが (2) と (4) が挙げるのは全角の形だけなので、半角になった記号が残る。
  - 決まりを文字どおりに書いた /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-prd2-tech1/norm/norm.py の出力：
    - `NFKC: {'，': ',', '．': '.', '［': '[', '］': ']', ...}`
    - `differ | AC-21 J title (full-width comma): 'そして,バトンは渡された' vs 'そしてバトンは渡された'`。AC-21 の Then（合う）とぶつかる。
  - 実際の応答の著者の形は、前の spike で保存した応答から取った。ファイルは /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/shelf7/api/ にある。
    - openBD の summary.author は「太宰,治,1909-1948」。
    - NDL の dc:creator は「神林, 長平, 1953-」。
    - NDL の author は「伴名, 練, 1988-,伴名練 著」。
    - 決まりでそろえると、どれも `differ`（例：`'太宰,治,1909-1948' vs '太宰治'`）。
  - AC の Given は、H20 がきれいな著者（「夏目漱石」）を返す形だけを書いている。だから G3 は通るのに、本物のデータでは受賞も「同じ著者」もほぼ出ず、奥付には「太宰,治,1909-1948」が出る。
  - 間違って「合う」とする側の危険は小さいが、0ではない。「舟を編む―公式ガイドブック」は (3) で「舟を編む」になり、著者が同じなら受賞として出る（norm.py で `MATCH`）。
  - 合わない側の例：
    - 上下巻（「鹿の王 上」）
    - 全角の［上］
    - 旧字（髙と高）
- 直し方の案：
  - (4) に NFKC の後の形を足す。たとえば「NFKC の後に、Unicode の句読点と記号（一般カテゴリ P と S）と空白をすべて除く」。
  - 書誌から著者を取り出す決まりを 11 に足す。
    - 最初の著者だけを使う。
    - 生没年（数字とハイフン）を除く。
    - 「著」「作」「訳」「編」「文」「絵」などの役割の語を除く。
    - 「姓, 名」のカンマを除く。
  - H20 が「太宰, 治, 1909-1948」をそのまま返し、保存と奥付が「太宰治」になる AC を1つ足す。
  - 上下巻を「合わない」のままにするなら、そう書く。G3 の照合の20行に、合ってはいけない例（派生の本）を混ぜる。

### 2. 国立国会図書館サーチのクレジットの表示が、PRD のどこにもない
- 重さ：直さないと通さない（重大。利用の条件に反する）
- 場所：9（やること）、17（書誌と受賞のデータ、969〜972行）、11（該当する AC なし）
- 理由と証拠：
  - https://ndlsearch.ndl.go.jp/help/api（2026-10-18 に開いた）の 17-4 (2) に「本APIを利用するサイトやアプリケーションには、NDLサーチのAPIを用いていることを明記してください。」とある。
  - 同じ所に「当館以外の機関が提供するデータについて、当該機関のクレジットの表示が条件とされる場合があります」ともある。
  - openBD（https://openbd.jp/ 、同じ日）は次を求めている。
    - キャッシュする場合は「データの変更をできるだけ早く反映するように」すること。
    - 「削除要請があった場合には、速やかにそれに従う」こと。
  - `grep -nE 'クレジット|NDLサーチのAPI|出典の表示|帰属|CC BY' docs/prd/001-reading-session.md` で当たったのは、Wikipedia の CC BY-SA の行（971行）だけ。
- 直し方の案：
  - 9 に「当たり前：設定の画面に、書誌の出どころ（NDL サーチの API を使っていること、openBD）を出す」を足す。
  - AC を1つ足す（例：設定の画面に識別子 `settings.dataSources` が1つあり、文言に「国立国会図書館サーチ」を含む）。
  - 17 に次の2つを書く。
    - データプロバイダの条件（CC BY ならライセンスへのリンク）を G1 で確かめること。
    - 保存した書誌を直し続けるかを決めること（openBD の条項）。

### 3. 2週の枠に入らず、削る順の3つを削っても入らない見込み
- 重さ：直さないと通さない（重大。PRD の冒頭が G0 で判定するよう頼んでいる）
- 場所：冒頭の時間の枠（5行）
- 理由と証拠（すべて［推測］。前の見積もりは docs/reviews/001-reading-session-integrate-tech-lead.md の 301〜313行）：

| 中身 | 日 |
|---|---|
| 前の見積もり（土台、登録、一行、ウィジェットと予約した Live Activity、伏せて読む、受賞の照合と近さ） | 10 |
| 本と記録を直す・消す（AC-15、AC-16、AC-24〜AC-26） | 0.5〜1 |
| 読み終えのカード（AC-84、AC-85） | 0.5 |
| 設定の3つ、ポリシーのリンク、Live Activity を切ったときの表示（AC-34、AC-37、AC-38、AC-51、AC-88） | 0.5 |
| 入口の印と URL の振り分け（AC-40） | 0.5 |
| 読み終えた夜の画面の流れ（AC-77〜AC-83、AC-86、AC-87。前の見積もりの 6 は照合だけ） | 0.5 |
| つなぎ口 H1〜H28 をアプリの中に作る（時計、保存の失敗、ウィジェットと Live Activity の記録など。前の見積もりにない） | 2.5〜3.5 |
| 保存の失敗と戻し（AC-59、AC-60、AC-90、AC-91） | 0.5〜1 |
| 計測（Q2 の (c)。15のイベント、端末で求める値、送る順番待ち、指摘4 の同意） | 1〜1.5 |
| 日英の文言の組み込みと、AX5 の直し | 0.5〜1 |
| 合計 | 17〜20 |
| 削る順の3つで戻る分（受賞1、予約した Live Activity 1〜1.5、撮る道1.5〜2。受賞の一覧1〜1.5は pdm の分） | 約4〜5 |
| 3つとも削ったあと | 12〜16 |

  - .claude/rules/org.md に「書く役は同時に1体だけ」とある。G1（designer と tech-lead）、G2（verifier）、実装、G3 は並べられないので、枠はさらに狭い。
- 直し方の案：Takuma に1つ選んでもらい、冒頭に書く。
  - (A) 枠を3週にする。
  - (B) 削る順に、(4) 読み終えのカード、(5) 計測を v1.0 では (a) にして (c) を次の版にする、を足す。
  - (C) 本の出口（AC-77〜AC-87）を v1.1 に分ける。
  - 推しは (B)。毎晩の道と「当たり前」を残したまま、いちばん小さく戻せるため。

### 4. 計測の (c) には審査ガイドライン 5.1.1(ii) の同意と取り消しが要るのに、PRD にない
- 重さ：直さないと通さない（重大。審査とプライバシー）
- 場所：15（908〜940行）、18 の Q2（985行）、product.md の 6 の (c)、AC-1（258行）
- 理由と証拠：
  - https://developer.apple.com/app-store/review/guidelines/（Last Updated: October 16, 2026。10-18 に開いた）の 5.1.1(ii) に、こうある。
    - 「Apps that collect user or usage data must secure user consent for the collection, even if such data is considered to be anonymous at the time of or immediately following collection.」
    - 「Apps must also provide the customer with an easily accessible and understandable way to withdraw consent.」
  - PRD には、同意を聞く場所も、取り消すスイッチもない。
  - AC-1 は、最初の起動で「アプリの alert は0個」「初めての案内の画面は0回」としているので、起動時に同意を聞く形もとれない。
  - 同意の前は送れない。そのため、App First Opened（I-1 と G-4 の分母）と、13 と 14 のすべての割合は「同意した人の中」の値になる。
- 直し方の案：(c) を選ぶなら、次を足す。
  - 同意を聞く場所（例：最初の記録の結果の画面のあとに、alert でなく画面の中で1回）。
  - 同意の前は何も送らないこと。
  - 設定の「使い方のデータを送る」のスイッチ（取り消し）。9 と AC に足す。
  - 13 と 14 の定義を「同意した人の中の割合」と書き直す。
  - App First Opened を「同意した時に、最初に開いた時刻からの値を付けて送る」形に変える。
  - プライバシーポリシーに書く。
  - (a) を選ぶなら、14 の注記どおりに置き換える。

### 5. 写真の読み取りの速さの線が「2回目以降」で、毎晩1回だけ撮る使い方の実際の待ちを測っていない
- 重さ：直さないと通さない（重大。1b と 2b で撮る道を主にするかを決める線）
- 場所：12 の速さの表（842行）、G4-12（829行）、10 のはまりやすい所（202行）
- 理由と証拠：
  - Mac（macOS 27.0.1、Apple M2 Pro）で、読み取りを新しいプロセスで2回続けて動かした。プログラムは /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-prd2-tech1/ocr/first.swift。
  - 出力は次のとおり。前の spike（同じ日の 09:12 ごろ）の初回は 38.25秒だった。
    - 1つ目のプロセス：`first=34.06s (6 obs) second=0.40s`
    - 直後の2つ目のプロセス：`first=0.53s (6 obs) second=0.37s`
  - 重い初回は、入れてから1回だけでなく、しばらく使わないとまた起きる。
  - 撮るのは1晩に1回なので、毎晩が「初回」になるおそれがある。iPhone での値は未計測。
- 直し方の案：
  - 12 と G4-12 の測る場面を「アプリを閉じて30分以上置いたあとの最初の1回」に変え、線を決める（例：5秒以内［推測］）。
  - 読み取りを待つ間も `mark.manual` と `mark.pageOnly` が押せる AC を足す。
  - 前もって準備を始める作り（「終える」を押した時点で読み取りの準備を始める）は G1 で決める。
  - 1b と 2b の分かれ道の条件に、この値を加える。
  - iPhone の値は、Q1 の試作で一緒に測れる（下の「Q1 の試作」）。

### 6. 予約した Live Activity：音なしにする選択肢がない。取り消しは未確認。読まなかった晩の一行が翌朝まで残る。失敗したときの AC がない
- 重さ：直すとよい（要修正）
- 場所：10 の Live Activity の知らせ（201行）、11 の予約の決まり（226行）、AC-36、AC-41、G4-6
- 理由と証拠：
  - 知らせの音：
    - SDK（iPhoneOS27.0.sdk の ActivityKit の arm64e-apple-ios.swiftinterface の 441〜445行）にある AlertSound は `default` と `named(_:)` だけ。
    - 文書（activity/request(...start:)）には「you must provide an AlertConfiguration. This makes sure that the system notifies people when your app starts the Live Activity.」とある。
    - 音を消すには、無音のファイルを `named` で渡すほかに道がない。それでも知らせの表示は残る見込み（未確認）。
  - 取り消し：
    - SDK に `ActivityState.pending`（`@available(iOS 26.0, *)`）と `end(_:dismissalPolicy:)` がある。取り消して入れ替えるコードは iOS 26 向けの typecheck を通った。
    - ただ、予約中の Live Activity を end で取り消せるとは、文書（displaying-live-data-with-live-activities）に書かれていない。だから未確認。
    - AC-36 の Then は H23 の記録だけを見るので、実機で取り消しが効かなくても G3 は通る。
  - 翌朝まで残る：
    - 8時間動き、そのあとロック画面に最長4時間残る（前の調べものの 5）。
    - 21:00 に始まって読まなかった晩は、翌朝9時ごろまで一行がロック画面に出る（6 の害）。
  - 失敗：
    - 文書に「starting a Live Activity may fail because a person's device may have reached its limit of active and scheduled Live Activities」とある。予約が失敗したときの AC がない。
- 直し方の案：
  - G1 の前に、シミュレーターで spike をする（予約 → `.pending` で出るか → end → 予約の時刻に出ないか。0.5日）。
  - G4-6 に「入れ替えた古い予約が、古い時刻に出ない」を足す。
  - 中身の staleDate を晩の境目（4:00）にし、古くなったら一行を出さない見え方にする。次にアプリが前に来たとき、前の晩の Live Activity を終わらせる。この2つを AC に足す。
  - 予約の失敗は alert を出さず、ウィジェットの道を続ける。これを「当たり前（エラー）」の AC として足す。

### 7. 12 に電池の行がない
- 重さ：直すとよい（要修正）
- 場所：12（835〜866行）。`grep -nE '電池|バッテリー|battery|UIBackgroundModes|バックグラウンド'` は0件。
- 理由：作りの上では電池への負担は小さい。読書は時刻の差で数え、後ろで動かない。向きの監視はしおりの画面の間だけ。ただ、それを数字と測り方で守る行がない。
- 直し方の案：次の3行を足す。
  - Info.plist に UIBackgroundModes がない（`plutil -p` で0件。G2 reviewer）。
  - しおりの画面のほかでは向きの監視が0（AC-47、AC-51 の flipMonitoring。G3）。
  - しおり、本、記録の保存1回につき、ウィジェットの再読み込みの要求は1回まで（H22。G3）。

### 8. 「allowsHitTesting(false) を0件」の決まりは、正しい使い方まで禁じる
- 重さ：直すとよい（提案）
- 場所：12 の速さの表の最後の行（846行）
- 理由：押せない飾りの重ね物（写真の列の枠、縦書きの重ね）は、下の操作を押せるようにするために allowsHitTesting(false) を使うのが普通の作り。数で0件を求めると、作り手が避けて書き、かえって押せない所が増えるおそれがある［推測］。
- 直し方の案：「動きの間に操作を止める目的の allowsHitTesting(false)、isUserInteractionEnabled = false は0件。飾りの重ね物に使うときは、その行に理由のコメント」と書き直す。

### 9. バックアップ：主の保存先を App Group に置くと、戻らない報告がある
- 重さ：直すとよい（要修正）
- 場所：12 のバックアップ（857行）、セキュリティとプライバシー（851行）
- 理由と証拠：
  - App Group の入れ物がバックアップに入るかを示す Apple の文書は、見つけられなかった（WebSearch、10-18）。
  - 開発者フォーラムに、戻したあと App Group のデータが戻らなかった報告がある（https://developer.apple.com/forums/thread/95343 ）。アプリの更新で入れ物が作り直された報告もある（https://developer.apple.com/forums/thread/821222 ）。どちらも公式の説明ではない。
- 直し方の案：
  - G1 の ADR で、主の保存先（SwiftData）はアプリの Application Support に置く。ウィジェットには小さな写し（今の本の書名、一行、ページ、隠す設定）だけを App Group に置く。
  - ウィジェットはロック中に写しを読むので、写しの保護の等級は「最初のロック解除まで」より強くしない。
  - G4 に「バックアップから戻して、本、記録、一行が戻る」を1行足す。

### 10. 最低の対応 OS は iOS 26 なのに、手元には iOS 27 のシミュレーターしかない
- 重さ：直すとよい（要修正）
- 場所：12 の速さの前書き（836行）、18 の Q7（990行）
- 理由と証拠：`xcrun simctl list runtimes` の出力は `iOS 27.0 (27.0 - 24A434)` だけ。予約した Live Activity と `.pending` は iOS 26 で入ったもので、26 と 27 で振る舞いが違うかは確かめられていない。
- 直し方の案：12 に「ウィジェット、Live Activity、伏せる道の G3 のテストは、iOS 26.x のシミュレーターでも動かす」と書く。iOS 26 のシミュレーターの入手は G1 で tech-lead が手順を CLAUDE.md に書き、動かして確かめる。

### 11. 計測の (c) の中身：自動で送られるデータ、費用、指標の定義の細かい所
- 重さ：直すとよい（要修正）
- 場所：15（909〜940行）、16 の費用（949行）
- 理由と証拠：
  - 推しは Aptabase（下の「Q2 の比べ」）。
  - https://aptabase.com/docs/apple-app-privacy（10-18）によると、IP から国と地域を求めて残す。そのため Location の Coarse Location を申告するよう求めている。IP そのものは残さない（「The IP address itself is never stored.」）。人を数えるのに、日ごとに変わるハッシュを使う。PRD の 15 には、このどちらもない。
  - 費用は https://aptabase.com/pricing（10-18 に開いた）で確かめた。
    - 「Up to 20,000 Free / 200,000 $10 / 1,000,000 $20」
    - 16 の「月20万件の枠で約10ドル」は合っている。無料の枠は月2万件で、全員が同意しても約280人分にあたる。
  - I-4 の分子（Bookmark Saved の photo か manual）に、AC-64 の読まずに挟む道が混ざる。
  - week は「端末の時刻」と書いてある（918行）。日曜の 1:00 に月曜を迎える晩は、晩の日付と週がずれる。
- 直し方の案：
  - 15 の表の下に「送り先のサービスが自分で足すデータ」を書く（Coarse Location、日ごとのハッシュ、OS と app の版）。
  - Bookmark Saved に after_reading（真偽）を足し、I-4 は真のものだけを数える。
  - week は「晩の日付の ISO 週」と書く。
  - G-4 は端末で1回だけ送る形にする。PRD が G1 に任せている所なので、決まりだけ先に書く。

### 12. AC-34 の名前と Then がずれている（「ロック中は隠す」なのに、いつも隠す）
- 重さ：直すとよい（提案）
- 場所：AC-34（457〜462行）、9 の隠す設定（162行）
- 理由：
  - Then は、ウィジェットのタイムラインそのものから一行と書名を除く形になっている。この形だとロックを外したあとも隠れ、ホーム画面の小のウィジェットでも隠れる。
  - ロック中だけ隠すなら、SwiftUI の `privacySensitive()` で隠す形になる（文書は「SwiftUI redacts views marked with this modifier when you apply the privacy redaction reason.」）。ただ、ロック画面でいつ隠されるかはこの判定で確かめられず、未確認。
- 直し方の案：pdm が「いつも隠す」か「ロック中だけ隠す」かを選び、名前か Then を合わせる。ロック中だけにするなら、G4-1 で見る。

### 13. VoiceOver のラベルは、縦書き用の字でなく、保存した一行から作る
- 重さ：直すとよい（提案）
- 場所：12 のアクセシビリティ（861行）、AC-28（421〜426行）、G4-13
- 理由：AC-28 は、描く字を U+FE11 などの縦書き用の字にすると決めている。描いた字のまま読み上げのラベルにすると、句読点が変わった字で読まれる［推測］。spike のコードでは、ラベルを保存した一行から作る形で typecheck を通した。
- 直し方の案：12 に「ウィジェットの読み上げのラベルは保存した一行と同じ文字列（H22 で読む）」を足す。

### 14. NDL サーチの営利の判定は、売り手が法人かどうかでも変わる
- 重さ：直すとよい（要修正。Takuma に聞く）
- 場所：16（945〜946行）、6 の事業性（97行）
- 理由と証拠：
  - https://ndlsearch.ndl.go.jp/help/api の 17-2 には、2つの書き方がある。
    - 「(1) 営利企業・団体の方：営利目的でのご利用にあたるため、利用申請が必要です」
    - 「(2) 個人・非営利団体等の方：データを利用することにより、収益を得ない場合は、営利目的にあたらないため、利用申請は不要です」
  - 無料で広告なしでも、売り手が法人なら申請が要る書き方になっている。データの出どころが目的を問わず許している場合は除く。
  - openBD の「本の販促・紹介目的に限り」は、自分の本の書誌を出し、次の1冊を紹介する使い方に当たる見込み［推測］。言い切れる文はない。
- 直し方の案：
  - 16 を「売り手が法人なら、課金がなくても申請が要る（データの出どころの条件しだい）」と直す。
  - 売り手が個人か法人かを Takuma に確かめる。
  - openBD は、NDL で埋まらないときの補いにする案と、問い合わせる案を G1 の ADR で比べる。

### 15. Mac と Vision Pro に出さないなら、App Store Connect で外す作業が要る
- 重さ：直すとよい（提案）
- 場所：18 の Q9（992行）
- 理由：iPhone のアプリは、何もしなければ Apple シリコンの Mac と visionOS でも配られる［私の知識。この判定では開いていない］。
- 直し方の案：G5 の確かめに「App Store Connect で Mac と Vision Pro での配布を外した」を足す。

## 証拠

### AC ごとの実現性（91件。`grep -cE '^- AC-[0-9]+：'` は 91）
判定の言葉：
- 作れる：Apple の標準フレームワークだけで作れる（今の構成。iOS のコードはまだない）
- 外部API：作れる。書誌の外部 API（NDL サーチ、openBD）を端末から直接呼ぶ。サーバーは要らない
- 未確認：シミュレーターとつなぎ口では作れるが、実機での振る舞いが確かめられていない
- PRD の直し：作れるが、PRD の決まりと AC が食い違う

| AC | 判定 | 根拠 |
|---|---|---|
| AC-1 | 作れる | カメラの許可は押したときに聞くので、最初の画面で許可の確認は出ない。G4-5 |
| AC-2、AC-3 | 外部API | DataScannerViewController の連続読み取り（ean13。typecheck を通った）。シミュレーターにはカメラがないので H21 が要る |
| AC-4、AC-5 | 外部API | NDL サーチの OpenSearch（前の調べもので HTTP 200）。ISBN ごとにまとめるのは端末でやる |
| AC-6 | 作れる | 通信の失敗の表示 |
| AC-7、AC-8 | 作れる | 書記素は Swift の Character で数える |
| AC-9〜AC-11 | 外部API | ISBN を先に保存する順番待ち。前に戻ったときに順に問い合わせる |
| AC-12 | 作れる | |
| AC-13〜AC-16 | 作れる | SwiftData。AC-14 と AC-16 はウィジェットの再読み込み（H22） |
| AC-17、AC-18 | 作れる（指摘1） | 著者を整える決まりが要る |
| AC-19、AC-20 | 作れる | |
| AC-21 | PRD の直し（指摘1） | 決まりどおりだと J が合わない（norm.py の出力） |
| AC-22〜AC-26 | 作れる | 晩の境目 4:00 とタイムゾーン（H6） |
| AC-27〜AC-30 | 作れる（実機での見え方は未確認） | 前の spike A で、SwiftUI だけで縦書きを組めた。禁則と縮め方はまだ書いておらず、手間は S。vibrant の描き方と大きい文字は G4-1 |
| AC-31、AC-32 | 作れる | |
| AC-33 | 作れる | アプリが前にあるときの再読み込みは予算に数えない（keeping-a-widget-up-to-date の「The widget's containing app is in the foreground.」）。10秒は G4-2 |
| AC-34 | 作れる（指摘12） | タイムラインで隠す形 |
| AC-35 | 作れる | systemSmall は StandBy に出る（HIG） |
| AC-36 | 未確認（指摘6） | `request(...alertConfiguration:start:)` は iOS 26 から（iOS 18 向けの typecheck でエラー）。予約中を end で取り消せるかは文書にない |
| AC-37、AC-38 | 作れる | areActivitiesEnabled |
| AC-39 | 作れる | |
| AC-40 | 作れる | 面ごとに widgetURL（WidgetKit の swiftinterface の 336行と617行。typecheck を通った）。H28 は XCUIApplication の `openURL:`（iOS 16.4 から。XCUIApplication.h の 63行） |
| AC-41 | 作れる（実機は G4-6） | アプリが前にあるときの update と end |
| AC-42、AC-43 | 作れる | |
| AC-44〜AC-51 | 作れる（実機は未確認：Q-A） | シミュレーターでは H15、H16、H18 で決まる。縦の固定がオンのときに faceDown が届くかは Q-A の① |
| AC-52、AC-53 | 作れる | 始まりの時刻を保存し、差で数える。後ろで動く仕組みは要らない |
| AC-54 | 作れる | |
| AC-55 | 作れる | os_signpost（H10） |
| AC-56〜AC-61 | 作れる | 保存の層に、失敗を差し込む口（H7）を作る |
| AC-62 | 作れる | |
| AC-63、AC-64 | 作れる | |
| AC-65〜AC-68 | 作れる（実機は未確認。指摘5） | Swift 版の Vision の RecognizeTextRequest（typecheck を通った）。本物の紙は 1b、iPhone での待ちは未計測 |
| AC-69 | 作れる | 撮った画像はメモリの中だけで扱う。UIImagePickerController が一時ファイルを書くかは未確認なので、撮り方は G1 で決める |
| AC-70〜AC-76 | 作れる | |
| AC-77〜AC-83 | 作れる（AC-78〜AC-80 は指摘1） | 並べ方は入力だけで決まる関数にでき、単体テストできる |
| AC-84、AC-85 | 作れる | ImageRenderer（typecheck を通った）。H24 のため、共有は自前のボタンと UIActivityViewController にする（ShareLink は押されたかを取れない［私の知識］） |
| AC-86、AC-87 | 作れる | |
| AC-88 | 作れる | URL は G5 までに決まる |
| AC-89 | 作れる | |
| AC-90、AC-91 | 作れる | H7 |

### pdm から頼まれた確かめへの答え
- 予約した Live Activity の入れ替え：
  - API はある（`.pending` は iOS 26 から。`end` もある。typecheck を通った）。
  - 予約中を取り消せるかは、文書になく未確認（指摘6 の spike）。
  - 予約はいつも1件なので、同時の数の上限には当たりにくい。それでも、失敗したときの扱いは要る。
- 始まるときの知らせを音なしにできるか：API の選択肢は `default` と `named(_:)` だけ。無音のファイルを渡す道は未確認。知らせの表示は消せない見込み。G4-6 で記録する。
- WidgetCenter でロック画面のウィジェットを読めるか：
  - `WidgetCenter.shared.currentConfigurations()`（swiftinterface の 587行）が `WidgetInfo` の `kind` と `family` を返す。文書の要約は「Retrieves information about user-configured widgets.」。
  - iPhone の accessoryRectangular はロック画面の部品なので、`family == .accessoryRectangular` で widget_placed を作れる（typecheck を通った）。
  - 実機で置いたあとに真になるかは未確認。G4-1 に1行足すとよい。
  - アプリからウィジェットを自動で置く API はない見込み［私の知識］（10 の 200行）。
- URL で入口を見分けられるか：
  - 見分けられる。ロック画面の長方形、小、Live Activity のロック画面の表示、Dynamic Island に、それぞれ widgetURL を付けられる。
  - ホーム画面の小と StandBy の小は同じ URL になり、分けられない（PRD の small_widget の扱いと合う）。
  - ロック中に押すと、ロックを外してから開く。
  - ロック画面で一行が「見られた」ことを測る API はない見込み［私の知識］。product.md の 6 のとおり、押して開いたことで代えるのでよい。
- iPhone での写真の読み取りの初回：
  - 未計測。
  - Mac では、しばらく使わないあとの最初の1回が 34.06秒。直後の別のプロセスでは 0.53秒（指摘5）。
- 受賞の照合で違う本を「合う」と間違えないか：派生の本で間違える危険は小さいが残る。合わない側の問題と、AC-21 の食い違いの方が大きい（指摘1）。
- NDL の営利の申請、openBD の目的：指摘14。クレジットの表示は指摘2。
- 書誌の問い合わせはプライバシー表示の「収集」に当たるか：
  - 当たらない見込み［推測］。
  - Apple の定義（https://developer.apple.com/app-store/app-privacy-details/ 、10-18）は次のとおり。
    - 「"Collect" refers to transmitting data off the device in a way that allows you and/or your third-party partners to access it for a period longer than what is necessary to service the transmitted request in real time.」
    - 「"Third-party partners" refers to analytics tools, advertising networks, third-party SDKs, or other external vendors whose code you've added to your app.」
  - NDL と openBD は、こちらがコードを入れた相手ではない。開発者も中を読まない。
  - 「収集」に当たると決まった場合は、書名で探すのは「Search History」になる。
  - プライバシーポリシーには送り先を書く。G5 で reviewer が最後に決める。
- H19〜H28 は要るか、作れるか：

| # | 要るか | 作れるか、作り方 |
|---|---|---|
| H19 | 要る（シミュレーターにカメラがない） | 作れる。読み取りの部品を差し替えられる形にする |
| H20 | 要る | 作れる。書誌を取る部分を1か所にまとめ、差し替えと記録の口を付ける |
| H21 | 要る（DataScanner はシミュレーターで動かない［私の知識］） | 作れる |
| H22 | 要る | 作れる。縦書きの組みとタイムラインの中身を、ウィジェットとアプリで分け合うパッケージの関数にする。再読み込みは包んで数える。ImageRenderer では vibrant の描き方は再現されない |
| H23 | 要る | 作れる。ActivityKit の呼び出しを包んで記録する |
| H24 | 要る | 作れる。カードを作る関数が、描いた文字の一覧も返す形にし、共有は自前のボタンにする |
| H25 | 要る | 作れる |
| H26 | 要る | 作れる。許可の状態を読む部品を差し替える（シミュレーターはカメラの許可を外から変えられない見込み［私の知識］） |
| H27 | 要る | 作れる。保存領域のファイルを数え、写真ライブラリに書く API は使わない（grep で0件） |
| H28 | 要る | 作れる（XCUIApplication の `openURL:`、iOS 16.4 から） |

  - 契約の形は G1 で contracts/ に書く。

### Q2 の比べ（サーバーなしで測る形）と推し

| 案 | 測れるもの | 欠点 |
|---|---|---|
| (a) App Store Connect だけ | Day 1、7、28 の継続率とクラッシュ率（分析の共有に同意した人の分） | 2晩目の到達率、I-2〜I-4、G-1、G-3、G-4 は測れない（14 の注記） |
| (b) 利用者が自分で送る | 送った人の分だけ | 少なく偏り、判定に使えない［推測］ |
| (c) 外部の計測サービス（ID なし） | 15 の全指標（同意した人の中） | 指摘4 の同意、依存が1つ増える、申告、月0〜10ドル |
| (参考) CloudKit の公開データベースに書く | ー | 書くのに iCloud のアカウントが要り、利用者の記録 ID が付く［私の知識］。ID なしの方針に合わないので捨てる |

- 推し：(c) で、送り先は Aptabase。指摘4 の同意を足すことが条件。
  - 理由：Aptabase は「does not collect advertising identifiers, device identifiers or account identifiers」と書いている（docs/apple-app-privacy、10-18）。端末の ID を送らない 15 の方針に合う。
  - 比べた TelemetryDeck の SDK は「Telemetry Manager will create a user identifier for you user that is specific to app installation and device」（README、10-18）。入れ替えないと、続けて使う ID が送られる。料金のページは 404 で見られなかった。
- contracts/dependencies.md に入れるときの下書き（G1 で、解決してビルドしてから足す）：
  - 名前：aptabase-swift（https://github.com/aptabase/aptabase-swift ）
  - ライセンス：MIT（LICENSE と GitHub の API）
  - 最後の更新：2026-10-16（pushed_at）。星は46個で、使う人は少ない
  - Package.swift：swift-tools-version 5.7、`.iOS(.v13)`。Swift 6 のアプリから警告なしで使えるかは未確認
  - Apple の「よく使われる SDK」の一覧には載っていない（一覧のページを grep して0件）
  - プライバシーマニフェスト：あり（Sources/Aptabase/PrivacyInfo.xcprivacy。ProductInteraction、結び付かない、トラッキングでない、目的は Analytics）。ただし Aptabase の文書が申告を求める Coarse Location はマニフェストにない
  - 代わりの標準：URLSession で同じ受け口に直接送る
  - 外す手間：小さい（送る部分を1つの型に包む）
- プライバシーの申告（(c) で Aptabase のとき）：
  - Usage Data の Product Interaction（結び付かない、トラッキングでない、目的は分析）
  - Location の Coarse Location（同じ）
  - Save Failed を送るなら、Diagnostics の Other Diagnostic Data

### 15 のイベントの区分と、ID を送らずに測れるか
- 区分：
  - Save Failed のほかの14件を「使用状況データ（製品の操作）」、Save Failed を「診断（その他）」とするのは、Apple の分類（Product Interaction の説明「app launches, taps, clicks, ... or other information about how the user interacts with the app」）に合う。
  - 送り先のサービスが自分で足すデータが表にない（指摘11）。
- ID なしで測れるか：
  - 測れる。割合は、端末で求めた真偽と回数の数え合わせで出せる。
  - ただし次の点がある。
    - 同意した人の中の値になる（指摘4）。
    - I-4 の分子が混ざる、week の決め方、G-4 の重複（指摘11）。
    - Night Summarized は次に開かれない晩が抜ける（PRD も認めている。929行）。

### 非機能（12）の見立て
- 速さ：
  - 起動1.0秒、「終える」から0.5秒、本500冊と記録5,000件で1.0秒、ウィジェット0.5秒は、どれも測り方があり、作りで届く見込み［推測］。
  - 読み取りは指摘5。
- オフライン：毎晩の道は通信を使わない作りで満たせる。書名で探すことだけが通信を要る。
- バックアップ：指摘9。
- 電池：指摘7。
- アクセシビリティ：
  - ロック画面のウィジェットの縦書きは、字の大きさを枠に入るように決める作りになる（spike：14字で22pt、24字で17pt）。大きい文字の設定でも、枠より大きくはできない［推測］。
  - そのため、大きい文字の人には、押して開いたアプリの中の `bookmark.line`（AC-29）で全文を出すことが代わりになる。大きい文字のときに字が欠けないかは G4-1 で見る。
  - VoiceOver は指摘13。

### 審査と権限で気になる点
| 項目 | 見立て |
|---|---|
| 許可 | カメラだけ（NSCameraUsageDescription。バーコードと撮る道で、押したときに聞く）。通知、位置、写真ライブラリ、モーション（UIDevice の向き）は要らない（前の調べもの flip-research の 22行） |
| entitlement と Info.plist | App Group（ウィジェットと分け合う）、NSSupportsLiveActivities、ウィジェットの拡張 |
| 後ろでの実行 | 使わない。2.5.4 にかからない |
| 外への送信 | 書誌（ISBN、書名）を NDL と openBD に送る。(c) なら計測のサービスにも送る。外部の AI には送らない |
| 4.3(b) | 中くらいの危険（"simple timers" を名指し）。17 の審査メモで違いを見せる案は妥当 |
| 5.1.1(i) | AC-88 で満たす |
| 5.1.1(ii) | (c) なら同意と取り消しが要る（指摘4） |
| 2.5.14 | 本文は「Apps must request explicit user consent and provide a clear visual and/or audible indication when recording, logging, or otherwise making a record of user activity. This includes any use of the device camera, microphone, screen recordings, or other user inputs.」。伏せて始まる道は、触覚、読み上げ、読書中の画面で知らせ（AC-44、AC-49）、設定で切れる（AC-51）。カメラは OS の許可と映像が出る。危険は低い見込み［推測］。審査メモに一言添えるとよい |
| 2.3 | ロック画面の大きさ（172×76 pt）で見せる決まりは 10 と 17 にある |
| 5.2.1 | 賞の名前は事実を示すだけに使う（17）。商標は Takuma に確かめてもらう |
| 1.2、5.1.1(v)、4.8 | かからない（友人もアカウントもない） |
| 著作権 | 一行を自分のロック画面に出すのは私的使用の見込みで、端末の外に出さない。カードに本の文を載せない（AC-84）。どちらも妥当［推測。法務の確認は Takuma を通す］。ストアのスクリーンショットと審査の手順では、例文に著作権の切れた文（羅生門など）を使うとよい |
| PrivacyInfo.xcprivacy | 理由の申告が要る API を使うなら、その申告が要る。たとえば App Group の UserDefaults や、起動からの時間（systemUptime、mach_absolute_time）［私の知識。分類の名前は文書の JSON に出ず、このページでは確かめられなかった：https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api ］。Date を使うだけなら要らない。G1 の ADR で決める |

### 月の費用（利用者1,000人あたり）
- サーバー：0ドル。
- 書誌 API：0ドル（NDL は個人で収益なしなら申請不要。openBD は無料）。
- 計測：
  - (a) か (b) なら0ドル。
  - (c) で Aptabase なら、月2万件までは0ドル、20万件までは月10ドル。
  - 1,000人が全員同意して月7万件［PRD の推測］なら、月10ドル。
  - 根拠：https://aptabase.com/pricing 、https://ndlsearch.ndl.go.jp/help/api 、https://openbd.jp/（どれも 2026-10-18）。
- Apple Developer Program の年会費は固定費なので入れていない。

### 18 の技術の問い
- Q1（実機の確かめの時期）：(a) を推す。
  - 試作のつくり：
    - 形：テキストだけで作れる Swift Playgrounds の App の形（.swiftpm）か、小さな Xcode のプロジェクト。リポジトリの外のスクラッチパッドに置き、Takuma が自分の Mac の Xcode で、自分の iPhone に入れる。
    - 中身1：いまの UIDevice の向きと、CoreMotion の重力の z を大きく出す。
    - 中身2：faceDown が1.0秒続いたら触覚を1回出し、時刻を記録する。UIDevice と CoreMotion を別々に数える。①と、届かなかったときの代わり（前の調べものでは、CoreMotion の許可は「決まらない」）を一度に見るため。
    - 中身3：縦の固定のオンとオフを記録するスイッチ。アプリからは読めない見込み［私の知識］なので、手で押す。
    - 中身4：②の許可のダイアログが出たかを押して記録する。
    - 中身5：③の5回を区切って数える。
    - 中身6：結果のテキストを共有シートで送る。保存も送信もしない。
    - 足すとよいもの：写真を1枚撮り、読み取りの1回目と2回目の秒数を出すボタン（指摘5 の値）。カメラの許可が1回出るので、①〜③のあとに押す。
  - 手間［推測］：
    - tech-lead が書いて、シミュレーターで動くまで2〜3時間。
    - Takuma は、初回の署名と Developer Mode のオン（再起動を含む）で約15分。①〜③で約10分。読み取りの時間を足すなら約5分。
    - TestFlight で配る形は、App Store Connect にアプリを登録する手間が増えるので推さない。
- Q2：上の比べ。条件つきで (c)。
- Q7：(a) iOS 26.0 を推す。
  - iOS 18 向けにすると、`.pending` と `request(...start:)` がエラーになった（spike）。
  - https://developer.apple.com/support/app-store/（2026-06-07 の計測。10-18 に開いた）では、全 iPhone の79%、この4年に出た iPhone の86%が iOS 26。PRD の「約21%」はこれと合う（100−79）。
- Q9：(a) を推す。外す作業は指摘15。
- Q10：(a) を推す。iOS 26 が動くいちばん古い機種は、この判定では確かめていない。G4 の前に Apple の対応機種の表で決める。

### 未確認と、確かめ方
| 項目 | 確かめ方 |
|---|---|
| 予約中の Live Activity を取り消して入れ替えられるか（AC-36） | G1 の前に、シミュレーターで spike（指摘6）。そのあと G4-6 |
| 知らせを音なしにできるか | G4-6 で記録する（API に選択肢はない） |
| widget_placed が実機で真になるか | G4-1 に1行足す |
| iPhone での読み取りの、その晩の最初の1回の秒数 | Q1 の試作に足すか、G4-12（指摘5） |
| 縦の固定のときの faceDown | Q1（Takuma） |
| App Group の入れ物のバックアップ | G1 の ADR で避ける作りにし、G4 で戻す確かめをする（指摘9） |
| privacySensitive がロック画面でいつ隠すか | AC-34 の意味を決めてから G4-1（指摘12） |
| aptabase-swift を Swift 6 のアプリで解決してビルドできるか | G1 で、dependencies.md に足す前に行う |
| 売り手が個人か法人か（NDL の申請） | Takuma に聞く（指摘14） |
| 2週の枠をどうするか | Takuma に聞く（指摘3） |

### 読んだファイル
- /Users/takumamatsuura/reading-app/docs/prd/001-reading-session.md（全1,008行）
- /Users/takumamatsuura/reading-app/docs/prd/product.md（6）
- /Users/takumamatsuura/reading-app/.claude/agents/tech-lead.md
- /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-G0-ruling.md
- /Users/takumamatsuura/reading-app/docs/approvals/001-reading-session-G0-Q8.md（60〜135行）
- /Users/takumamatsuura/reading-app/docs/org/gates.md（20〜60行）
- /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-validation-plan.md
- /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-integrate-proposal.md
- /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-integrate-tech-lead.md
- /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-G0-tech-lead-flip-research.md（grep）
- /Users/takumamatsuura/reading-app/contracts/dependencies.md（表は空）
- /Users/takumamatsuura/reading-app/CLAUDE.md
- /Users/takumamatsuura/reading-app/.claude/rules/org.md

### 実行したコマンドと結果
- `git rev-parse HEAD`：8b1228f4f8eb6c43432b02d3d2c73e1982463c28。`wc -l` で PRD は1,008行。
- `xcodebuild -version`：Xcode 27.0（27A266a）。iphoneos と simulator の SDK は 27.0。`xcrun simctl list runtimes`：iOS 27.0 だけ。
- ActivityKit と WidgetKit の swiftinterface を grep した。
  - AlertSound は `default` と `named(_:)` だけ（441〜445行）。
  - `case pending` に `@available(iOS 26.0, *)`（380〜385行）。
  - `request(...alertConfiguration:..., start:)`（68行）。
  - `currentConfigurations()`（587行）。WidgetInfo の `family` と `kind`。
  - `widgetURL`（336行、617行）。
  - XCUIApplication.h の 63行：`openURL:` は `ios(16.4)` から。
- `xcrun --sdk iphoneos swiftc -typecheck -target arm64-apple-ios26.0 -swift-version 6 -parse-as-library ApiCheck.swift`：エラーの出力なし。
  - 同じファイルを `-target arm64-apple-ios18.0` にすると、`'pending' is only available in iOS 26.0 or newer`、`'request(attributes:content:pushType:style:alertConfiguration:start:)' is only available in iOS 26.0 or newer`。
- `python3 -I norm.py`：指摘1 の出力。
- `first`（読み取りの時間）を2回：`first=34.06s (6 obs) second=0.40s` と `first=0.53s (6 obs) second=0.37s`（macOS 27.0.1、Apple M2 Pro）。
- `fetch.py`：telemetrydeck.com/pricing/ だけが 404 で、ほかの18件は 200。
- 規約と文書の引用は、`ctx.py` で取り込んだ本文を grep して取った（上の各指摘の引用）。
- `grep -cE '^- AC-[0-9]+：'`：91。
- `grep -nE '電池|バッテリー|battery|UIBackgroundModes|バックグラウンド'`：0件。
- `grep -nE 'クレジット|NDLサーチのAPI|出典の表示|帰属|CC BY'`：971行だけ。
- aptabase-swift：LICENSE は MIT。Package.swift は `swift-tools-version: 5.7` と `.iOS(.v13)`。PrivacyInfo.xcprivacy は ProductInteraction で、結び付かず、トラッキングでない。GitHub の API は `pushed_at 2026-10-16`、`archived False`、`stargazers 46`。
- ガードに1回止められた。書き先に変数があったため。回り道はせず、パスをそのまま書いて実行し直した。
- リポジトリのファイルは書いていない。

### 開いた URL（どれも 2026-10-18）
- https://openbd.jp/
- https://ndlsearch.ndl.go.jp/help/api
- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/app-store/app-privacy-details/
- https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- https://developer.apple.com/support/third-party-SDK-requirements/
- https://developer.apple.com/support/app-store/
- https://developer.apple.com/documentation/activitykit/activity/request(attributes:content:pushtype:style:alertconfiguration:start:)
- https://developer.apple.com/documentation/activitykit/alertconfiguration
- https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities
- https://developer.apple.com/documentation/widgetkit/widgetcenter/currentconfigurations()
- https://developer.apple.com/documentation/swiftui/view/privacysensitive(_:)
- https://developer.apple.com/documentation/widgetkit/creating-accessory-widgets-and-watch-complications
- https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date
- https://aptabase.com/pricing
- https://aptabase.com/docs/apple-app-privacy
- https://github.com/aptabase/aptabase-swift（README、LICENSE、Package.swift、PrivacyInfo.xcprivacy、API）
- https://raw.githubusercontent.com/TelemetryDeck/SwiftSDK/main/README.md
- https://telemetrydeck.com/pricing/（404）
- WebSearch の結果：https://developer.apple.com/forums/thread/95343 、https://developer.apple.com/forums/thread/821222 、https://developer.apple.com/documentation/xcode/configuring-app-groups

### 作業用のファイル（リポジトリの外。どれも消してかまいません）
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-prd2-tech1/spike/ApiCheck.swift
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-prd2-tech1/norm/norm.py
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-prd2-tech1/ocr/first.swift
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-prd2-tech1/ocr/first
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-prd2-tech1/tools/fetch.py
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-prd2-tech1/tools/ctx.py
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-prd2-tech1/dl/（取り込んだ文書19件）

### reviewer に反論を頼みたい判断
- Q2 で (c)（Aptabase）を推したこと。
- 主の保存先を App Group に置かない方針（指摘9）。
- 指摘3 の見積もり（すべて［推測］）。
- 指摘5 を重大にしたこと（iPhone での値は未計測で、Mac の値から推した）。

---

# その2：第1部の根拠と「G0 の前の確認」

PASS

範囲はその2（第1部の 1〜8、13、14、16、18 の Q3〜Q6 と Q8、「G0 の前の確認」12項目、product.md 全体）です。対象のコミットは ba9bbf60eb8d17b48b4f01ecbc6f231bb96abb6e で、HEAD 8b1228f との差分に docs/prd/ の変更はありません。

## 指摘
「直さないと通さない」（重大）は0件です。以下の13件はすべて「直すとよい」です。

1. 直すとよい（要修正）｜docs/prd/001-reading-session.md:32-33、:61
   - 問題：E-9 の後半（縦書きを SwiftUI で組めた）と E-10（合成ページの spike で 4/4）は、リポジトリの中の spike の結果です。公開情報ではなく URL もありませんが、印は［公開情報］になっています。4つの力（:61）も「［公開情報 E-10］」と引いています。
   - 根拠：docs/reviews/001-reading-session-integrate-tech-lead.md の 5（spike B）。印の決まり（:8）。
   - 直し方：spike の部分を分けて［推測。spike の出力は integrate-tech-lead.md の 5。本物の紙は未検証］とし、［公開情報］は Apple の文書の部分だけに残す。

2. 直すとよい（要修正）｜docs/prd/001-reading-session.md:878、docs/prd/product.md:86
   - 問題：G-1 の目標「30秒以内」に印がありません。ほかの目標にはすべて［推測］があります。
   - 根拠：出典の docs/reviews/001-reading-session-integrate-designer.md:381 は「（例：真ん中の値で30秒以内［推測］）」です。
   - 直し方：どちらのファイルでも［推測］を付ける。

3. 直すとよい（提案）｜docs/prd/001-reading-session.md:6、:874、:875-877、docs/prd/product.md:82
   - 問題：I-2 は、冒頭（:6）と product.md の 6 では「入力指標」なのに、13 では「主」です。また「主の判定には使わず」の注は I-1 にしかなく、同じ入力の I-3 と I-4 には付いていません。
   - 直し方：13 の I-2 を「主（この機能の主。product.md では入力指標）」と書く。13 の表の下に「入力の行は仮説の合否に使わない」と1行足す。

4. 直すとよい（要修正）｜docs/prd/001-reading-session.md:34（E-11）、:97（6 の事業性）、:945（16）
   - 問題：国立国会図書館サーチの条件のうち、「(1) 営利企業・団体の方 営利目的でのご利用にあたるため、利用申請が必要です」が抜けています（データ提供機関が利用目的を問わず許諾しているデータは除く）。PRD は「経済的な対価を受け取ると営利」の場合（(2) 個人の方の条件）だけを書いています。そのため、6 の「v1 では失敗しない」は、出す名義が個人であることを黙って前提にしています。
   - 根拠：https://ndlsearch.ndl.go.jp/help/api の 17-2（2026-10-18 に curl で取得）。
   - 直し方：E-11 と 16 に (1) と (2) の違いを足す。6 の事業性の行に「出す名義（個人か法人か）」を前提として書き、名義は Takuma に確かめる。どの提供機関のデータを使うかは tech-lead が G1 で確かめる。

5. 直すとよい（要修正）｜docs/prd/001-reading-session.md:124
   - 問題：8 は「サーバーなしで月0ドル」と言い切っています。一方、16（:949）は「(c) なら計測のサービスの分だけ」としていて、Q2 の推奨は (c) です。Aptabase の料金ページでは、月200,000件の枠が $10（20,000件までは無料）で、16 の見込み（1,000人で月7万件）は $10 の枠に入ります。
   - 直し方：8 を「自前のサーバーなし。月の費用は Q2 が (a)(b) なら0ドル、(c) なら利用者1,000人あたり約10ドル」とする。

6. 直すとよい（要修正）｜docs/prd/001-reading-session.md:15（1 の紹介文）
   - 問題1：「読んだ本の名前と一行は端末の外に出ません」とありますが、読み終えのカード（AC-84）には書名と著者が描かれ、利用者が LINE などに送ります。17（:961）の「『何も外に送らない』とは書かない」とも合いません。
   - 問題2：紹介文は6文で、ひな形の「3〜5文」を超えています。また「代替より何がどれだけ速いか、楽か、安いかを数字で」（docs/templates/prd.md:14）の比べる数字がありません。約4秒は絶対の値で、ToRead には速さで勝てないと書いています。
   - 直し方：「自分で送る読み終えのカードのほかは」と足す。紙のしおりや ToRead と比べた数字（例：手に取った画面で続きが見えるまでの操作の数）を1つ入れ、5文以内に縮める。

7. 直すとよい（提案）｜docs/prd/001-reading-session.md:27（E-4）
   - 問題：分母は RSS と完全に合います（148、298、78）。分子は、拾った語の一覧が「など」で終わっているため再現できません（integrate-demand-pdm.md:198）。
   - 私が数えた結果：挙げてある5語では 20/148（14%）、44/298（15%）、16/78（21%）。「読み込」「検索」を足すと 38（26%）、90（30%）、26（33%）。PRD の 20%、19%、27% はこの間に入るので、ありうる値です。
   - 直し方：数えた語と数え方を全部書く。

8. 直すとよい（提案）｜docs/prd/001-reading-session.md:24、:68、:70、:126、docs/prd/product.md:11
   - 問題1：43.6% の選択肢の原文は「情報機器（携帯電話、スマートフォン、タブレット、パソコン、ゲーム機等）で時間が取られる」です（文化庁 PDF）。PRD の「携帯電話、スマートフォンなどで時間が取られる」は nippon.com の書き方です。O-1 の「夜」「SNS や動画」は調査にない言葉です。
   - 問題2：3.6% は平成25年度の値です。同じ年度の「情報機器」は 26.3% でした。O-3 と 8 では、令和5年度の 43.6% と年度をまたいで比べています。E-2 は年度を明かしていますが、比べている所には書いていません。
   - 直し方：比べる所に「（H25）」と書くか、同じ年度どうし（26.3% と 3.6%）で比べる。夜や SNS への読み替えには［推測］を付ける。

9. 直すとよい（提案）｜docs/prd/001-reading-session.md:989（Q6）、docs/prd/product.md:98
   - 問題：「JP の検索で同じ名前は0件」に印と URL がありません。中身は正しいことを確かめました（iTunes Search API で resultCount=0）。
   - 直し方：［公開情報 https://itunes.apple.com/search?term=しおりどき&country=jp&entity=software 、2026-10-18］を足す。

10. 直すとよい（提案）｜docs/prd/product.md:105-106
    - 問題：「本」は入れていないと書いていますが、キーワードの「次に読む本」に本が入っています。バイト数は UTF-8 で 97 バイト（37字）で、上限の内です。
    - 直し方：書き方を直すか、語を差し替える。

11. 直すとよい（提案）｜docs/prd/001-reading-session.md:44
    - 問題：ビブリアの価格が「見ていない」になっています。lookup API では「無料」です。ひな形では、埋められない所は「未定（理由）」と書きます。
    - 直し方：「無料（App 内課金は未確認）」とする。

12. 直すとよい（提案）｜docs/prd/001-reading-session.md:112
    - 問題：計画は 1b と 2b の「届かなければ」を別々に決めています（1b は手入力とページ数だけを主、2b はページ数だけを主）。両方届かなかったときの「ページ数だけが主」は、pdm の読み方です。合格の線そのものは動いていません。
    - 直し方：指揮役が validation-plan に1行足して確かめるか、PRD に「pdm の読み方」と書く。

13. 直すとよい（提案）｜docs/prd/001-reading-session.md:124、docs/prd/product.md:54
    - 問題：「本の一行を出すアプリは見た範囲にない」の出典（reselect-pdm-core.md の 4-3）は「［公開情報。上位だけ見た］」です。PRD と product.md では「上位だけ」の断りが落ちていて、product.md:54 のこの文には印もありません。
    - 直し方：「（上位だけ見た）」と印を残す。

## 証拠
- 実行したコマンドと結果（作業用のファイルはすべて /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-prd2-tech2/ に置いた。リポジトリには何も書いていない）
  - `grep -cE '^- AC-[0-9]+：' docs/prd/001-reading-session.md` → 91。Given、When、Then、確かめ方、効く機会の行も `grep -cE '^  - <欄>：'` で各91。
  - awk で AC ごとの効く機会を抜き出した（kiku.tsv）→ 当たり前 29、O-1 29、O-3 13、O-5 10、O-4 6、O-6 4。AC の番号は 1〜91 で、欠けも重なりもない。
  - `grep -nE '適切|すばやく|なるべく|十分に|スムーズ|快適'` → 0件。
  - `curl -Z` と URL グロブで RSS を取得（page=1〜10。JP の9本と US の Goodreads で100ファイル）。lookup（JP と US）と search（しおりどき）も取得。
  - `python3 -I scripts/check.py dl` → 引用22件がすべて「OK」（文があり、日付と星が一致）。ToRead と読書なびは RSS のレビューが0件。星3以下の数はブクログ 148、読書メーター 298、ビブリア 78、Goodreads 153。search の結果は resultCount=0。キーワードは 97 バイト。
  - `python3 -I scripts/check2.py dl` → 説明文の引用10件のうち9件がある。ToRead の「ショートカットや背面タップで…」だけは説明文になく、製品ページの WebFetch で見つけた。nippon.com と PR TIMES の数字はすべてあった。
  - `swift scripts/pdftext.swift <pdf>`（PDFKit）で文化庁の PDF 2本とクロス・マーケティングの PDF の文字を取り出し、grep した。
    - r5.txt:596-597 → 43.6%、38.9%
    - r5.txt:608 → 20〜40代で6割台
    - h25.txt → 3.6%。読書量が減ったと答えた 65.1% が対象で、同じ年度の「情報機器」は 26.3%
    - crossm.txt:344-347 → 図4「本の選び方 TOP12」、n=532、32.0／12.8／11.8／10.2
  - `python3 -I scripts/check3.py dl` → E-9、E-11、E-14 と 17 の引用（審査ガイドラインの "simple timers"、"meaningfully different…"、Last Updated: October 16, 2026、5.1.1(i)、ActivityKit の "The system starts the Live Activity…"、HIG の 172x76 と "Provide useful information…"、openBD の2つの文、国立国会図書館の「経済的な対価」）がすべてある。国立国会図書館の (1) 営利企業の条項も見つけた（指摘4）。
  - E-4 の分子を再現しようとした python → 指摘7 の数字。
  - 製品ページを curl して grep → mekuru は月¥580／年¥5,800、Bookmory は月¥380／年¥3,400 と「入力に手間が掛かりすぎる」2025/07/26。lookup で Reads 176、ブックミー 283。
  - 本文の URL 20件を `curl -w '%{http_code}'` で開いた → すべて 200。
- 開いた URL（すべて 2026-10-18）
  - App Store の製品ページ：ToRead（WebFetch。評価3件で、レビューの本文は出ていない）、ブクログ、ビブリア、Goodreads（US）、mekuru、読書なび、読書メーター、Bookmory
  - itunes.apple.com：RSS、lookup、search
  - 調査の出典：https://www.nippon.com/ja/japan-data/h02135/ 、bunka.go.jp の PDF（94111701_02、92701201_06）、cross-m.co.jp の news_release_20251008.pdf、prtimes.jp の 000000012.000027516
  - 書誌：openbd.jp（トップと news/20230725）、ndlsearch.ndl.go.jp/help/api
  - Apple：developer.apple.com の審査ガイドライン、HIG の widgets と ActivityKit（JSON）、peer-group-benchmarks、design/awards
  - その他：booklog.jp/item/1/4344030036、aptabase.com/pricing
- 読んだファイル
  - docs/prd/001-reading-session.md：1〜272 行と 866〜1008 行。AC は grep と awk で抜き出した
  - docs/prd/product.md
  - docs/org/gates.md
  - docs/templates/prd.md と review-report.md
  - docs/reviews/ の次のもの
    - 001-reading-session-G0-ruling.md
    - 001-reading-session-integrate-proposal.md
    - 001-reading-session-validation-plan.md
    - 001-reading-session-integrate-demand-pdm.md（5-1 ほか）、integrate-tech-lead.md（:145、:301-313）、reselect-pdm-core.md（4-3）、integrate-pdm.md、integrate-designer.md の該当箇所
  - docs/approvals/001-reading-session-G0-Q8.md の最後の2節
- 観点4：pdm が「判断の分かれる所」とした2つ（どちらも通してよい）
  - 13 の種類に「入力」を足したこと：通してよい。
    - 関門が求めるのは「ガードレールが1つ以上、主の指標が見かけの指標でない」ことです。G-1〜G-4 があり、主は2晩目の到達率と I-2 なので満たしています。
    - 入力の行は、product.md の 6 で決めた原因を探すための指標です。合否を決める行を増やしていません。
    - ラベルが二通りになっている点は指摘3。
  - 9 の「当たり前」の2行（:162-163）が O-n を持たないこと：通してよい。
    - プライバシーポリシーへのリンクは、裁定 5（5.1.1(i)）と同じものです。
    - ロック中に隠す設定は、PRD の決まり（:245）と裁定 5 の「権限（許可とデータの扱い）」に当たり、理由も 6 の害（:98）と 4 の不安（:61、:63）に書いてあります。
    - 対応する AC-34 と AC-88 も「当たり前（権限：…）」です。ひな形 :86 も、当たり前の品質の AC を残すことを認めています。
    - 無理に O-n を付けると作り話になります。
- 「G0 の前の確認」12項目（印を信じずに確かめた）

| # | 項目 | 結果 | 証拠 |
|---|---|---|---|
| 1 | 3 にアプリ3件以上と代替1つ以上。アプリの行に URL と、引用か「不満の記録なし」 | 満たす | アプリ6件（:43-48）、代替3つ（:49-51）。4件の引用は RSS にあり、日付と星も合った。ToRead と読書なびは RSS でレビュー0件、評価は3件と0件なので「不満の記録なし」は正しい |
| 2 | 根拠のすべてに印。［推測］だけで支えた結論がない。出典の URL が3つ以上 | 満たす（指摘 1、2、9、13） | E-1〜E-15 の全行に印がある（:24-38）。URL は10以上。推奨の芯（O-1）は E-1 で支え、E-1 は原典で確かめた。S-6 は 3b と AC-87 で受けている |
| 3 | Job が1つで、画面名と機能名がない | 満たす | :19-20 |
| 4 | 機会と解決案が3つ以上で、選んだ理由と捨てた理由がある | 満たす | O-1〜O-6（:68-73）、S-1〜S-10（:78-87）、理由（:74 と表の3列目） |
| 5 | 6 の全行、7 の5行、結び付けた先 | 満たす | 6 は6行×6列（:94-99）、7 は5行（:117-121）。第1部と 10 が指す AC の番号38個を題名と照らし、すべて合った |
| 6 | 8 に推奨、いちばん強い反論、作らない場合 | 満たす（指摘5） | :124、:126、:127 |
| 7 | 9 の全行に Kano と効く機会。無関心と逆効果がない | 満たす | 27行（:137-163）。2行の「なし（理由）」は観点4のとおり |
| 8 | 10 のやらないことに理由 | 満たす | 14項目（:182-195）、すべてに理由がある |
| 9 | 全 AC に Given、When、Then、確かめ方、効く機会。測れない言葉がない | 満たす | 各91件、測れない言葉は0件。「当たり前」29件は、どれも空、エラー、オフライン、権限の AC |
| 10 | 13 にガードレール。主が見かけの指標でない。全行に基準値の出典と判定日 | 満たす（指摘 2、3） | :873-881 |
| 11 | 14 の全行に数値、日付、取る行動、判定する役（pdm 以外） | 満たす | 8行（:892-899）。日付は公開日（:888）から数える。判定する役は指揮役か verifier |
| 12 | 15 の全イベントにプライバシー表示の区分 | 満たす | 15件（:913-927）。区分が正しいかは、その1の範囲 |

- 観点5：決定が正しく写っているか
  - 範囲（サーバーなし。友人と本当の「これを読んだ人は」は後の版。今夜の量は v1.x）：合っている。9（:137-178）、10（:182-188）、S-7（:84）、product.md:71-72。費用の書き方は指摘5。
  - 名前は「次の1冊」。「これを読んだ人は」を使わない：合っている。
    - :158 と AC-78〜AC-87 は「次の1冊」を使っている。
    - 「これを読んだ人は」が出るのは :84、:126、:178、:183 で、どれも外したものの説明。画面の文言にはない。
  - 積読が先：合っている（:223-224。新しい本は最大1冊でいつも最後。S-6、AC-78）。
  - 受賞は3賞：合っている（:144、Q3）。
  - 削る順：合っている。:5 の (1) 受賞 (2) Live Activity (3) 撮る道は、proposal 3-1 と integrate-tech-lead.md:313 と同じ順。
  - 1b〜3c の合格の線：動いていない。validation-plan.md:37-40 と PRD :105-108 の合格の線、合格なら、届かなければは文言まで同じ。組み合わせの読み方は指摘12。
  - 読み終えのカードの既定は本の文なし：合っている（:159、S-9、AC-84 の Then「一行の字は0字」、Q4 の (a)、:968）。
  - 裁定 2〜5 と 8、確かめの追加（LINE の7晩は足さない。:980）：合っている。
- 18 の問い（私の範囲）
  - Q3：約380行は出典（integrate-tech-lead.md:145）でも［推測］で、書き写しは合っている。書き先の docs/prd/ は pdm の範囲。
  - Q4：Takuma の決定の注と合っている。
  - Q5：16 と合っている（国立国会図書館の条件は指摘4）。
  - Q6：中身を確かめた（指摘9）。
  - Q8：合格の線を先に決めている。聞くのは過去の行動。新しく足す問いは1つだけ。
- 数字を出典と照らした結果（どれも一致）
  - nippon.com：69.1%、62.6%、3,559人、43.6%、38.9%
  - 文化庁：20〜40代の6割台、3.6%（平成25年度）
  - クロス・マーケティング：32.0、12.8、11.8、10.2、n=532
  - PR TIMES：79%、N=2,104
  - 評価の数
    - ブクログ 28,261、ビブリア 11,934、読書メーター 7,190
    - mekuru 370（4.69、公開 2026-08-12）、ToRead 3、読書なび 0
    - Goodreads US 758,792、JP 1,450
    - Shelfie 10、FLIP 790
    - Offshelf：US 4件、JP は lookup に出ない
    - 10-15 と 10-16 に調べた値（Bookmory、Forest、ベア）は、日数で説明できる幅の差
  - E-4 の分母、各社の価格、Aptabase の $10
- 未検証
  - 判定に要る項目：なし。
  - 標本の外で照らさなかったもの（判定には使っていない）
    - product.md の案 B「よむま」の検索上位5件
    - booklog.jp の item の引用
    - FLIP とベアの US の RSS の引用
    - E-4 の分子（再現できない。指摘7）

## 記録（指揮役が保存するときに書き足す）
- 種類：G0 の判定（tech-lead、2体）。結果：FAIL
  - その1：FAIL（直さないと通さない5件、直すとよい10件）
  - その2：PASS（直すとよい13件）
- 対象：docs/prd/001-reading-session.md と docs/prd/product.md。BASE=ba9bbf60eb8d17b48b4f01ecbc6f231bb96abb6e
- 日付：2026-10-18
