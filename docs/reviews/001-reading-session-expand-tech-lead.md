（指揮役の注）Takuma の 2026-10-20 の問い直し（バーコードでの一括取得、デジタル書籍への対応、レコメンドのニーズ）への調べもののうち、tech-lead の報告（書誌データの同梱、電子書籍の技術、レコメンドのデータと spike）。pdm と designer も並べて調べた。判定ではない。報告の文はそのまま保存した。

（指揮役へ：保存先は docs/reviews/001-reading-session-expand-tech-lead.md を想定しています。これは判定ではなく、調べものと spike の報告です。）

# バーコードでの一括取得、デジタル書籍、レコメンドを外部 API なしで成り立たせる道（tech-lead の調べものと spike）

## 変更したファイル
- リポジトリのファイルは変えていません。コミットもしていません。
- 作業はすべて /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/expand-tech/ の中で行いました（以下 X/ と書きます）。
  - スクリプト：X/scripts/（probe.py、dl.py、analyze.py、gen.py、h2t.py、appledoc.py）
  - spike：X/spike/digi.swift（画面写しと e-ink の OCR、SQLite の速さ）、X/spike/fm.swift（Foundation Models に推薦を選ばせる）
  - 実行ファイル：X/bin/digi（Mac）、X/bin/digi_sim（iOS 26.0 シミュレーター）、X/bin/fm（Mac）
  - 記録：X/out/mac_ocr.log、X/out/sim_ocr.log、X/out/mac_sql.log、X/out/sim_sql.log、X/out/sim_sql2.log、X/out/fm_run1.log、X/out/probe2.tsv
  - 落としたもの：X/dl-oai/f*.gz（OAI-PMH の全件ファイル8本、合わせて 32.5 MB）、X/dl-ndl/（API の条件とデータプロバイダの一覧）、X/dl-apple/（Apple の文書の JSON）
  - 測るための DB：X/out/oai_sample.sqlite（本物の895件）、X/out/all3m.sqlite（300万行に増やしたもの、441 MB）、X/out/lit400k_fts.sqlite（40万行と FTS5 trigram、152 MB）
  - 画像：X/out/img/*.png（13枚。例：X/out/img/K1_kindle_light.png、X/out/img/E1_eink_page_photo.png）
- シミュレーターの端末 expand-tech-ios26（17A2746B-614C-4322-92BE-EBD4DEAC16C1）は自分で作り、使い終えたあと消しました（`simctl list devices | grep -c expand-tech` → 0）。
- 手数は47回です（上限は60回）。

---

## 1. バーコードでの一括取得を、通信なしで成り立たせる道（書誌データの同梱）

### 結論
**通信なしで作れます。** 国立国会図書館が作った書誌（CC BY）を、アプリの外で前もって SQLite にまとめ、端末に置きます。バーコードを読んだら、ISBN を端末の中で引きます（1冊あたり約0.3ミリ秒）。

**申請は要りません。** 条件は「出典の表示」「加工したことの表示」「NDL サーチの API で作ったことの明記」の3つです。どれも表示の条件で、申請ではありません（原文は下にあります）。

満たすべき条件は次の4つです。
1. **データ**
   - 最初に1回、OAI-PMH の全件ファイルを全部落とします（26,374本、約107 GB［推測：1本 4.06 MB × 本数］）。
   - そのあとは、毎週の JAPAN/MARC（申し込みなし、週 2〜7 MB）で差分を足します。
   - 全件の JAPAN/MARC（申し込みが要る）は使いません。
2. **大きさ**
   - ISBN の付いた日本の本の全部は約295万冊［推測。8本からの外挿］で、検索なしで約440〜490 MB です。
   - 文学（NDC 9）だけなら約40万冊、約65 MB です。
3. **配り方**：大きいので、Apple-Hosted Background Assets（iOS 26 以上。このアプリの最低の対応 OS は iOS 26.0 なので使えます）で、アプリとは別に配ります。データの版を変えるたびに App Review が要ります。
4. **見つからない本の扱い**：新刊は数週間遅れます［推測］。見つからない本は、v1.0 に入れると決まった「名前で迎える」（背か表紙を写して押す）と「あとで」に落とします。

### できること・できないこと
| 項目 | 判定 | 根拠 |
|---|---|---|
| 国立国会図書館の書誌を、営利のアプリで申請なしに使う | できる | provider の表で iss-ndl-opac、iss-ndl-opac-inprocess、iss-ndl-opac-national がどれも「CC BY」、記号は「○：利用申請は不要」 |
| OAI-PMH の全件ファイルを申請なしで落とす | できる | 全件ファイルは「APIのご利用について」の条件に従う。CC BY のデータは「利用申請・許諾は不要」 |
| 毎週の JAPAN/MARC（過去1年分）を申請なしで落とす | できる | 前の調べ（jnb_product、jnb の一覧で、申し込みが要るのは全件データだけ） |
| 新着書誌情報（作成中）をまとめて取る | 一部できる | 全件ファイルにも入りますが、40,000件中4件だけでした。OAI-PMH の ListRecords で set=iss-ndl-opac-inprocess を指定すれば期間で取れます（1回200件。API ですが CC BY なので申請不要） |
| ISBN を端末の中で引く速さ | できる | 300万行で中央値 0.25 ms（Mac）、0.34 ms（iOS 26 シミュレーター） |
| 書名で探す（FTS5 trigram） | 3字以上ならできる | iOS 26 シミュレーターの SQLite 3.51.0 に ENABLE_FTS5 があり、trigram で当たりました。2字以下（「歴史」「東京」）は0件なので、別の道が要ります |
| 起動を遅くしない | できる | DB を開くのに 0.3〜9.4 ms。最初に引くときに開けば、起動には効きません |
| 出たその週の新刊 | できない（遅れる） | JAPAN/MARC に入るのは作成が終わった書誌だけ。作成中の書誌は少数。そのうえに配る周期（毎月）と審査が重なります |
| データだけを、アプリの更新なしに替える | できる（審査あり） | asset pack の版はアプリの版と別に出せます。ただし審査が要ります |

### 大きさの測り（spike）
- **全件ファイルの中身**
  - 80本の頭の 24 KB を読みました。どのファイルにも、いろいろなデータプロバイダの書誌が混ざっています。そのため、日本の本だけを取るにも全部を落とす必要があります。
  - 8本（40,000件）を全部読みました。
    - 国立国会図書館の書誌（R100000002）は 6,853件で、そのうち ISBN があるものは 1,144件でした。
    - ISBN が 978-4 か 4- で始まる本は 895件（2.24%）でした。
    - 新着書誌情報は4件でした。
- **全体の見積もり**［推測。8本からの外挿で、±7%ほどぶれます］
  - 26,374本 × 5,000件 × 2.24% で、約295万冊（275万〜315万）です。
  - 内訳
    - NDC 9（文学）13.4%：約40万冊
    - 913（日本の小説）6.6%：約20万冊
    - NDC なし 26.1%
    - 2020年代 18.9%、2010年代 29.8%
- **1冊あたりの大きさ**（列は ISBN、書名、著者、出版社、シリーズ、巻、年、NDC。sqlite 3.54.0）
  - 本物の895件で測りました。164.8 B/冊、xz で 66 B/冊です。書名と著者の FTS5 trigram を付けると 572 B/冊（xz で 228）です。
  - 300万行に増やした DB は 441 MB（154 B/冊）でした。
  - 40万行に FTS を付けた DB は 152 MB（397 B/冊）でした。書名を水増ししたので trigram が重なり、本物より小さく出ています。

| 範囲 | 冊数［推測］ | 検索なし | 書名の検索あり | 配り方の目安 |
|---|---|---|---|---|
| 全部（ISBN のある日本の本） | 約295万 | 約440〜490 MB | 約1.2〜1.7 GB | asset pack |
| 2010年以降の全部 | 約144万 | 約220〜240 MB | 約570〜820 MB | asset pack |
| 文学（NDC 9）だけ | 約40万 | 約65 MB | 約160〜230 MB | アプリに同梱できる |
| 日本の小説（913）だけ | 約20万 | 約32 MB | 約80〜110 MB | アプリに同梱できる |

- **iPhone での容量と速さ**：iPhone では測っていません。App Store の上限（展開後 4 GB）には、どの範囲でも収まります。
- **速さ**（ファイルのキャッシュが温まった状態）

| 測ったもの | Mac | iOS 26 シミュレーター |
|---|---|---|
| ISBN を1,000回引く（300万行） | 中央値 0.25 ms、p99 0.61 ms | 中央値 0.34 ms、p99 3.0 ms |
| DB を開く | 0.6 ms | 0.3 ms（1回目の実行は 9.4 ms） |
| 書名の FTS5 trigram（10語） | 中央値 0.5 ms | 中央値 1.4 ms |

### 更新の3つの道
| 道 | 危険 | 手間 |
|---|---|---|
| アプリに同梱して、アプリの更新で替える | アプリが重くなる。新刊の遅れが、アプリを出す周期に縛られる | 小さい |
| 決まった場所から1ファイルを落とす | 利用者の情報は送らないが、IP と時刻は置き場所に届く。置き場所の運用が要る（サーバーなしの決定と少しぶつかる） | 中くらい |
| **Apple-Hosted Background Assets（推す）** | 版ごとに審査が要る。審査で asset pack に届かなかったという書き込みがある（未確認）。上限は1つのアプリの記録あたり合計 200 GB、200個 | 中くらい。最初の版はアプリと同じ申請に入れる |

### 手間と危険
- **手間**：+3.5〜6.0日［推測。単位は「1人の作り手の日」で、G1〜G3 を含む］。運用は毎月 0.25〜0.5日です。
  - 書誌データを作る道具（アプリの外で、Mac で動かす。サーバーではない）：全件ファイルの取り込み、dcndl の RDF の読み取り、絞り込み、SQLite づくり、JAPAN/MARC の差分。1.5〜2.5日
  - アプリの側：asset pack の受け取り、引く部品、出典の画面、データがまだ届いていないときの逃げ道。1.0〜1.5日
  - バーコードを続けて読み、結果を並べて一度に加える画面：0.5〜1.0日
  - ADR、PRD の直し、テストのつなぎ口（DB の差し替え）：0.5〜1.0日
- **危険**
  - 新刊の遅れ：買ったその週の本は、たいてい見つかりません［推測：2〜6週］。逃げ道は、名前で迎える道と「あとで」です。
  - 大きさ：全部を入れると約0.5 GB で、入れる前にためらわれるおそれがあります。
  - 審査：データの版を変えるたびに審査があります。
  - 最初の取り込みが約107 GB と重いことです［推測：15時間ほど］。
  - 著者の書き方：NDL の書き方（foaf:name の「姓, 名, 生年-」など）をそろえる手間があります。ラテン文字の著者（G1-13）が直るかは未確認です。
- **費用**：月0ドルの見込みです。asset pack の置き場所の料金は、どのページにも書かれていませんでした［推測：開発者の会費の中］。

### 開いた URL と原文
- **https://ndlsearch.ndl.go.jp/help/api**
  - 「(1) 営利企業・団体の方　営利目的でのご利用にあたるため、利用申請が必要です。ただし、データ提供機関があらかじめ利用目的を問わず利用を許諾しているデータについては、利用申請・許諾は不要です。」
  - 「(3) 継続的にアクセスを行われる方　継続的にアクセスを行われる場合、API利用実態の把握のために、事前の利用申請の要否にかかわらずNDLサーチAPI利用申請フォームよりご連絡先、ご利用内容等をお知らせいただけますようご協力をお願いします。」（協力のお願いで、許諾ではありません）
  - 「(2) クレジットの表示　本APIを利用するサイトやアプリケーションには、NDLサーチのAPIを用いていることを明記してください。」
- **https://ndlsearch.ndl.go.jp/help/api/provider**
  - 「○：利用申請は不要　△：利用申請が必要」
  - 「メタデータ利用条件欄にクリエイティブ・コモンズ・ライセンスの表示がある場合は、メタデータの二次利用について利用申請は不要です。各ライセンスの条件に従ってご利用ください。」
  - 表の行：国立国会図書館蔵書 iss-ndl-opac ○ ○ CC BY／国立国会図書館新着書誌情報 iss-ndl-opac-inprocess ○ ○ CC BY／国立国会図書館全国書誌情報 iss-ndl-opac-national ○ ○ CC BY
- **https://ndlsearch.ndl.go.jp/help/api/oai_pmh**（前の調べで落とした写しを読みました）
  - 「「国立国会図書館蔵書」（NDL新着書誌情報・全国書誌情報を含む）の書誌データをOAI-PMHで取得する場合、…setパラメータに iss-ndl-opac 、もしくは iss-ndl-opac-national 、 iss-ndl-opac-inprocess を指定します」
  - 「全件ファイルの利用に際しては、APIのご利用について をご確認の上、条件を守ってご利用ください。」
  - 「全件ファイルの更新頻度は月1回です。」
  - 「リクエストに対する1度の返戻は200件が上限です。」
- **https://www.ndl.go.jp/data/data_service/quickguide**（今回は開き直していません。前の調べの原文です）
  - 「営利・非営利の目的を問わず、どなたでも無償で利用することができます」
  - 「（出典記載例） 出典：…国立国会図書館書誌データ（○年○月○日に取得）」
  - 「編集・加工等して利用する場合は、上記出典の記載とは別に、編集・加工等を行ったことの記載もお願いいたします。…あたかも国立国会図書館が作成したかのような態様で公表・利用しないでください。」
- **アプリでの表示の案**［推測。法律の判断ではありません］
  - 設定の「このアプリについて」と、読み取った書誌の画面の下に、次の3つを書きます。
    - 「出典：国立国会図書館書誌データ（2026年11月1日に取得）」
    - 「このアプリが加工して作成」
    - 「国立国会図書館サーチの API（OAI-PMH の全件ファイル）を用いて作成」
  - これらは表示の条件で、申請ではありません。「継続的なアクセスの連絡」は協力のお願いなので、出すかは Takuma が決めることです。
- **https://developer.apple.com/help/app-store-connect/reference/apple-hosted-asset-pack-size-limits**
  - 「Asset pack total: 200 GB」「Asset pack count: 200」
  - 1つの asset pack あたりの上限は書かれていません。
- **https://developer.apple.com/help/app-store-connect/manage-asset-packs/overview-of-apple-hosted-asset-packs**
  - 「Users' devices automatically download these asset packs separately from your app build.」
  - 「you can also upload asset packs to App Store Connect separately from your app build.」
- **https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-apple-hosted-asset-packs**
  - 「Asset packs must be reviewed before they can be tested externally in TestFlight or made available for users on the App Store.」
  - 「After your app is approved, you can submit an asset pack version with or without an app version.」
  - 「Once an asset pack version is approved for the App Store, it'll automatically be available to all App Store users」
- **https://developer.apple.com/forums/thread/810659**、**https://developer.apple.com/forums/thread/804377**（検索の結果だけ）：上限を上げてほしいという話、審査で asset pack に届かないという書き込み。未確認です。

---

## 2. デジタル書籍への対応で、技術として何ができるか

### 結論
**他のアプリの蔵書と読書の位置は取れません。** Apple Books にも Kindle にも、公開の API は見つかりませんでした。

紙の芯のうち、そのまま成り立つもの、形を変えて成り立つもの、成り立たないものは次のとおりです。
- **成り立つもの**
  - ロック画面の一行：一行の取り方を変えます。スクリーンショットから行を押す、共有で受け取る、手で入れる、のどれかです。
  - Kindle の端末で読むとき：iPhone が空いているので、伏せて読む道がそのまま使えます。
- **形を変えて成り立つもの**
  - 同じ iPhone で読むとき：伏せられません。そこで、すでに v1.0 にある「読み始める」（App Intents）で始め、Kindle に切り替え、Live Activity の「終える」で終えます。
  - 自動にしたい人には、ショートカットのオートメーション（「App が開かれたとき／閉じられたとき」）を自分で設定してもらう道があります。
- **成り立たないもの**
  - アプリが勝手に「Kindle を開いた」と知ること。
  - Screen Time の API を使うこと：Apple への entitlement の申請が要り、利用時間のデータもアプリの外に出せません。

### できること・できないこと
| 項目 | 判定 | 根拠 |
|---|---|---|
| Apple Books の蔵書と位置を取る | できない（公開の API が見つからない） | Apple の文書に該当する framework がない。検索で出たのは非公式のものだけ |
| Kindle の蔵書と位置を取る | できない（公開の API がない） | 検索で出たのは、逆解析の非公式パッケージ（npm の kindle-api、swift-kindle）だけ。Amazon の規約に触れるおそれがあり、使わない |
| 共有シートから受け取る（Share Extension） | 部品はある。中身は未確認 | NSExtensionActivationRule は「The semantic data types that a Share or Action extension supports.」。Kindle や Apple Books が共有で何を渡すか（書名、URL、ハイライトの文）は、実機がないので未確認。Apple Books が抜粋に「書名と著者」を添えるという記憶は［推測］ |
| スクリーンショットから続きの一行 | できる（紙より楽） | spike：きれいな画面写しでは、一行が正しい1行として出たのがシミュレーターで 5/5、Mac で 4/5。紙の写真は1〜2字を読み違えた |
| 進みの数字（位置No.、%、43/212） | できる | spike：画面写しのすべてで読めた（Mac とシミュレーター） |
| 自動で「最後の列」を選ぶ | 確かでない | 最後の列が短い（「た。」「たのです。」）と、私の規則は別の列を選んだ（3/5 で失敗）。行を押す形が要る |
| Kindle の端末を iPhone のカメラで写す | 合成ではできる。反射は未確認 | spike：e-ink の写真に寄せた画像で 1.000。悪い画像では Mac 0.567（光の当たりで行が割れた）、シミュレーター 1.000 |
| iPad の画面を写す | 合成ではできる | K1 の写真に寄せた画像と悪い画像で、Mac 0.938（「電報」→「電」）、シミュレーター 1.000 |
| 同じ iPhone で始まりと終わりを取る | 一部できる | 「読み始める」インテントと Live Activity の「終える」（v1.0 の部品）。ショートカットの App のきっかけは、利用者が自分で設定する |
| 他のアプリが前に来たことを知る | できない | アプリは自分の状態（前か後ろか）しか知らない［推測：今回、文書は開いていない］ |
| Screen Time で他のアプリの利用時間を取る | 実質できない | 自分の端末も .individual で認可できる。ただし配るには entitlement の申請と Apple の審査が要る。報告の拡張はサンドボックスの中で動き、データを外に出せない |

### spike の結果（合成の画像。数字は「続きの一行と、いちばん近い OCR の行の一致の度合い」で、1.000 が完全一致）
| 画像 | Mac | iOS 26 シミュレーター | 自動で左端を選んだとき（Mac/シミュレーター） | 読めた数字 |
|---|---|---|---|---|
| K1 Kindle 風・白 | 1.000 | 1.000 | 1.000/1.000 | 位置No. 1234、23% |
| K2 Kindle 風・セピア（最後の列が5字） | 0.600 | 1.000 | 0.054/0.053 | 41% |
| K3 Kindle 風・黒 | 1.000 | 1.000 | 1.000/1.000 | 位置No. 2210、39% |
| K4 小さい字（最後の列が短い） | 1.000 | 1.000 | 0.102/0.102 | 43/212 |
| K5 横書き（最後の行が「た。」） | 1.000 | 1.000 | 0.000/0.000 | 43/212 |
| K1 を写した（iPad の画面を写す想定）・写真に寄せた | 0.938 | 1.000 | 同じ | 位置No. 1234 |
| K1 を写した・悪い | 0.938 | 1.000 | 同じ | 位置No. 1234 |
| E1 e-ink の画面 | 1.000 | 1.000 | 1.000/1.000 | 位置No. 812、12% |
| E1 を写した・写真に寄せた（光の当たりあり） | 1.000 | 1.000 | 同じ | 同じ |
| E1 を写した・悪い | 0.567 | 1.000 | 同じ | 同じ |
| P1 紙のページ（比べるため）・きれい | 1.000 | 1.000 | 同じ | ー |
| P1 紙・写真に寄せた | 0.947 | 0.974 | 同じ | ー |
| P1 紙・悪い | 0.947 | 0.974 | 同じ | ー |

- **時間**
  - Mac：最初の1回 26.19秒（しばらく使わなかったあと）、中央値 0.36秒
  - シミュレーター：最初の1回 9.22秒、中央値 2.72秒
- **読み方**
  - 画面写しには、カメラによる劣化がありません。そのため、紙を撮るより確かです。
  - ただし「最後の列を自動で選ぶ」は、短い列で崩れます。撮る道と同じく、行を押して選ぶ形にします。
- **上ぶれ**：合成の画像で、本物の Kindle や Apple Books の画面ではありません。字形、ルビ、段落の字下げ、余白の飾りは入れていません。画面写しを禁じる本やアプリがあるかは未確認です。

### 手間と危険
- **v1.0 に入れる部分**：+1.6〜3.0日［推測］
  - 進みの単位（ページ、%、位置No.）をデータとウィジェットに足す：0.75〜1.25日
  - PhotosPicker で画面写しを選び、撮る道の「行を押す」部品を使い回す：0.25〜0.5日
  - 本ごとの「電子で読む」の印、伏せる案内を出さない、Live Activity で終える流れ：0.5〜1.0日
  - ショートカットのオートメーションの案内の文：0.1〜0.25日
- **Share Extension**：+1.0〜2.0日。Kindle が何を共有するかを実機で確かめてから決めます。v1.1 を推します。
- **危険**
  - 開発者フォーラムに、iOS 26.6 で「App が閉じられたとき」がコントロールセンターを開いただけで動くという書き込みがあります（未確認）。読み終わりの記録が早く切れるおそれがあります。
  - Kindle の位置No. はページではありません。ページの差で出している「p.43 → p.61」の表示を、% か位置No. で読み替える必要があります。
  - 電子書籍にはバーコードがありません。書誌は、1 の書名の検索（3字以上）、画面写しの扉、手で入れる、のどれかで取ります。1 の同梱データに書名の索引を付けると、電子書籍を加える道がいちばん楽になります。

### 開いた URL と原文
- **https://developer.apple.com/documentation/familycontrols**（JSON）
  - 「Before submitting your app to the App Store, you must [request permission] to use the entitlement.」
  - 「Authorizing parental controls for an individual requires approval from the owner of the device.」
- **https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement**（JSON）
  - 「Before you distribute an app that uses Family Controls, your Apple Developer Account Holder must request permission to use the entitlement」
  - 「Apple reviews your app, and if it's approved, adds the entitlement to your developer account」
- **https://developer.apple.com/documentation/familycontrols/authorizationcenter/requestauthorization(for:)**（JSON）：「individuals can authenticate their own account.」
- **https://developer.apple.com/documentation/deviceactivity/deviceactivityreport**（JSON）
  - 「To protect the user's privacy, your extension runs in a sandbox.」
  - 「This sandbox prevents your extension from making network requests or moving sensitive content outside the extension's address space.」
- **https://developer.apple.com/forums/thread/818174**（検索の結果）：報告の拡張がデータを含むアプリに渡せないのは設計どおりか、という問いに DTS が「Yes」と答えた。
- **https://support.apple.com/en-gu/guide/shortcuts/apde31e9638b/ios**
  - 「Is Opened: Triggers your automation when you open or switch to the selected app.」
  - 「Is Closed: Triggers your automation when you close or switch from the selected app.」
  - 確かめずに動かせるか（Run Immediately）は、このページには書かれていません（未確認）。
- **https://developer.apple.com/forums/thread/841128**（検索の結果。未確認）：iOS 26.6 で「When App Is Closed」がコントロールセンターで動く。
- **https://developer.apple.com/documentation/bundleresources/information-property-list/nsextension/nsextensionattributes/nsextensionactivationrule**（JSON）：「The semantic data types that a Share or Action extension supports.」
- **検索で出た Kindle と Apple Books の非公式の道**（公式の API がない証拠として。使いません）
  - https://classic.yarnpkg.com/en/package/kindle-api
  - https://swiftpackageregistry.com/natikgadzhi/swift-kindle
  - https://www.marco.org/500743718
  - https://pypi.org/project/py-apple-books

---

## 3. レコメンドを、外部 API とサーバーなしでどこまで作れるか

### 結論
- **v1.0**：「事実の理由がある次の1冊」は、端末の中だけで作れます。1 の同梱データがあれば、積読の外の本も出せます。
  - 例：「この著者のほかの本」「次の巻」「同じ賞の別の回」。
- **Foundation Models には選ばせません。** spike では、規則より悪い結果でした。
  - 同じ作品の別の版を選んだのは 48回中5回でした。
  - 理由の種類がデータと合わなかったのは 48回中32回でした。
  - 自由な文では、事実を誤りました（『こころ』に「太宰治」と書いた）。
- **本当の「これを読んだ人は」は v2 です。** サーバーか CloudKit、同意、人数のしきい値、最初の利用者が要ります。

### できること（版ごと）
| 推薦 | 材料 | 同梱なし（今の計画） | 同梱あり | 版 |
|---|---|---|---|---|
| 積読から：同じ著者、同じ賞、同じレーベル | 利用者の本棚 | できる（AC-78〜AC-83） | できる。著者とレーベルが ISBN から埋まるので当たりやすい | v1.0 |
| 新しい本：同じ賞のすぐ後の回 | 受賞の一覧（手で作る） | できる | できる | v1.0 |
| この著者のほかの本（本棚にない） | 同梱データの著者 | できない | できる。著者があるのは895件中777件。NDL の書き方をそろえる手間がある | v1.0 か v1.1 |
| 次の巻 | 同梱データの書名と巻（dcndl:volume） | できない | 巻があるのは895件中259件。同じ書名の上下や1、2巻なら出せる | v1.0 か v1.1 |
| 同じレーベルの受賞作 | 受賞の一覧とレーベル | 積読の中だけ | できる | v1.1 |
| この著者の新しい本が出た | 毎月の同梱データ | できない | できる（遅れあり） | v1.1 |
| 同じ年の賞の候補に並んだ本［案］ | 候補の一覧（手で作る） | 一覧があればできる | 同じ | v1.1 の候補 |
| 同じ出版社の同じジャンル | NDC、C コード | 弱い（小説は 913.6 にまとまる） | 弱い | 推さない |
| これを読んだ人は（他人の記録） | 集めた記録 | できない | できない | v2 |

### Foundation Models の spike（候補10件から3件を選ばせる）
- **形**
  - @Generable で、番号（`.range(0...9)`）、理由の種類（`.anyOf` で5種）、20字以内のひとことを返させました。
  - 指示は「表にない事実は書かない」「読み終えた本の別の版は選ばない」です。
  - 場面は2つです。『蜜蜂と遠雷』を読み終えた（候補に『蜜蜂と遠雷 上』の文庫を罠として入れた）、『人間失格』を読み終えた（角川文庫版を罠として入れた）。
  - それぞれ候補の並びを8通りにし、greedy と sampling を交互に使いました。合わせて16回、48件を選ばせました。
- **結果（macOS 27.0.1、availability: available）**
  - 候補の外の番号は 0/48 でした。型で縛っているので出ません。
  - 同じ作品の別の版を選んだのは 5/48 でした（『蜜蜂と遠雷 上』。指示しても選んだ）。
  - 理由の種類がデータで裏付けられなかったのは 32/48 でした。例：『こころ』『走れメロス』に「シリーズの次」。
  - ひとことに、ほかの本の事実が入ったのは 3/48 でした。例：『こころ』に note=太宰治。
  - 規則の上位3冊と重なったのは 27/48 でした。
  - 並びを変えると選ぶ本が変わりました（greedy でも、候補の順に引きずられる）。
  - 時間は、中央値 2.13秒、最初の1回 6.76秒です。
- **読み方**
  - 選ぶ形にしても、外れた本は防げますが、間違った本と間違った理由は防げません。
  - 規則なら、事実の理由が必ず合い、同じ作品も除けます。
  - 使える機種は約4〜5割で、裁定 12（AI に文を作らせない）と裁定 17（AI の部分は無料）にも関わります。だから使わないことを推します。

### 本当の協調フィルタ（他人の記録）に要るもの（作らない前提の一覧）
- **集める場所**
  - 自前のサーバーか、CloudKit の公開データベースです。
  - CloudKit の公開データベースについて、Apple の文書は「readable by all users of the app, and users have write access to the records … they create」と書いています。書いた人の iCloud の記録に結び付くので、匿名にはなりません。上限は利用者の数に応じて変わり、正式な数字は公開されていません（DTS の答え）。
- **同意**：審査ガイドライン 5.1.1 の同意と取り消しが要ります。プライバシー表示（「データの収集なし」が崩れる）と、外部送信規律の扱いも見直しになります。
- **匿名にする仕組み**
  - 人数のしきい値が要ります（例：k 人以上が重なった組だけを出す）。
  - Apple が他社のアプリに差分プライバシーの集計や中継を提供しているという文書は、見つけられませんでした［推測：ない］。第三者の OHTTP の中継を使う道はありますが、調べていません。
- **最初の人数**：出した日は0人です。意味のある組が出るまで、数千人の日々の利用者が要る見込みです［推測］。
- **費用**：CloudKit なら小さいうちは0ドルの見込み［推測］。自前のサーバーなら月 5〜25ドル［推測］と、運用の手間です。
- **手間**：L です（前の integrate の判定と同じ）。

### 手間
- 同梱なし：+0日（今の計画のまま）。
- 同梱あり：「この著者のほかの本」「次の巻」で +1.0〜2.0日［推測］。NDL の著者の書き方をそろえる、巻を読み取る、並べ方の単体テスト、を含みます。
- Foundation Models：使わないので0日です。

### 開いた URL と原文
- **https://developer.apple.com/documentation/cloudkit/ckcontainer/publicclouddatabase**（JSON）
  - 「The contents of the public database are readable by all users of the app, and users have write access to the records, and other objects, they create.」
  - 「Data in the public database counts toward your app's iCloud storage quota.」
- **https://developer.apple.com/forums/thread/732433**、**https://developer.apple.com/forums/thread/715649**（検索の結果）：公開データベースの上限は利用者の数とともに増え、正式な文書はない（DTS）。

---

## 実行したコマンドと結果
（X/ は /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/expand-tech/ です。）

### 1. 書誌データの同梱
- `curl -s -L -A 'Mozilla/5.0' -o X/dl-ndl/api.html https://ndlsearch.ndl.go.jp/help/api` → `200 130657`
- `curl … -o X/dl-ndl/provider.html https://ndlsearch.ndl.go.jp/help/api/provider` → `200 405599`。`h2t.py` で文字にし、iss-ndl-opac の行（○ ○ CC BY）を確かめた。
- `python3 -I X/scripts/probe.py …/biblio-alt-tech/dl-ndl/xmlList.txt 80 X/out/probe2.tsv`（Range で頭の 24 KB）→ 80本すべてに、いろいろなプロバイダの setSpec が混ざっていた。
- `python3 -I X/scripts/dl.py … 1,3300,6600,9900,13200,16500,19800,23100` → 8本、3,984,140〜4,155,480 バイト、1本あたり 0.9〜4.1秒。
- `python3 -I X/scripts/analyze.py X/dl-oai X/out/oai_sample.sqlite`
  - `{'all': 40000, 'set_opac': 6849, 'ndl_record': 6853, 'ndl_with_isbn': 1144, 'ndl_isbn_jp': 895, 'has_series': 438, 'has_creator': 777, 'ndc9': 120, 'has_volume': 259, 'ndc913': 59, 'set_inprocess': 4, 'jp_not_book': 1}`
  - `years [('197x', 1), ('198x', 53), ('199x', 154), ('200x', 250), ('201x', 267), ('202x', 169), ('?', 1)]`
  - `sqlite rows 895 bytes/rec 164.8 xz bytes/rec 66.0`、`with fts5 trigram bytes/rec 572.1 xz 227.9`
- `python3 -I X/scripts/gen.py …` → `lit400k_fts.sqlite 400000 158916608 397.3 B/rec`、`all3m.sqlite 3000000 462020608 154.0 B/rec`
- `X/bin/digi sql X/out`（Mac、X/out/mac_sql.log）
  - `sqlite version 3.54.0 FTS5=true`
  - `all3m.sqlite open=0.0006s isbn lookups n=1000 hits=1000 first=0.00035s median=0.000254s p99=0.00061s`
  - `fts trigram 10 queries median=0.0005s max=0.0024s`
- シミュレーターでの実行
  - `xcrun --sdk iphonesimulator swiftc -O -swift-version 5 -target arm64-apple-ios26.0-simulator X/spike/digi.swift -o X/bin/digi_sim` → エラー0。
  - `xcrun simctl create expand-tech-ios26 com.apple.CoreSimulator.SimDeviceType.iPhone-17 com.apple.CoreSimulator.SimRuntime.iOS-26-0` → `17A2746B-614C-4322-92BE-EBD4DEAC16C1`。そのあと boot。
  - `xcrun simctl spawn 17A2746B-… X/bin/digi_sim sql X/out`（X/out/sim_sql.log、X/out/sim_sql2.log）
    - `sqlite version 3.51.0 FTS5=true FTS options: ["ENABLE_FTS3", "ENABLE_FTS3_PARENTHESIS", "ENABLE_FTS3_TOKENIZER", "ENABLE_FTS4", "ENABLE_FTS5"]`
    - `all3m.sqlite open=0.0003s isbn lookups n=1000 hits=1000 first=0.00083s median=0.000336s p99=0.00302s`（1回目の実行は open=0.0094s、first=0.01905s）
    - `q=こころ hits=20`、`q=日本の hits=20`、`q=歴史 hits=0`、`q=東京 hits=0`、`fts trigram 10 queries median=0.0014s max=0.0037s`
  - `xcrun simctl shutdown …; xcrun simctl delete …` → `deleted=0`
- `grep` で docs/adr/*.md を見た → `最低の対応 OS は iOS 26.0、端末は iPhone だけ`

### 2. デジタル書籍
- `swiftc -O -swift-version 5 X/spike/digi.swift -o X/bin/digi` → エラー0、警告0。
- `X/bin/digi gen X/out/img` → `generated 13`
- `X/bin/digi ocr X/out/img`（X/out/mac_ocr.log）→ 2 の表。`OCR secs first=26.19 median=0.36 max=26.19`
- `xcrun simctl spawn 17A2746B-… X/bin/digi_sim ocr X/out/img`（X/out/sim_ocr.log）→ 2 の表。`OCR secs first=9.22 median=2.72 max=9.22`
- `python3 -I X/scripts/appledoc.py X/dl-apple … familycontrols familycontrols/requesting-the-family-controls-entitlement 'familycontrols/authorizationcenter/requestauthorization(for:)' deviceactivity/deviceactivityreport deviceactivity` → 2 の原文。
- `python3 -I X/scripts/appledoc.py … nsextensionactivationrule cloudkit/ckcontainer/publicclouddatabase` → 2 と 3 の原文。

### 3. レコメンド
- `swiftc -O -swift-version 5 X/spike/fm.swift -o X/bin/fm` → エラー0、警告1（`GenerationOptions(sampling:)` が非推奨）。
- `X/bin/fm`（X/out/fm_run1.log）→ real 39.94秒。`availability: available`。`TOTAL picks=48 outOfRange=0 runsWithDup=0 sameWorkPicked=5 reasonKindNotSupportedByData=32 noteMentionsForeignFact=3 overlapWithRuleTop3=27/48 secs median=2.13 first=6.76 max=6.76`

### WebFetch と WebSearch
- WebFetch で開いたページ
  - apple-hosted-asset-pack-size-limits、overview-of-apple-hosted-asset-packs、submit-apple-hosted-asset-packs：開けた。
  - support.apple.com の shortcuts apde31e9638b：開けた。
  - requesting-the-family-controls-entitlement の HTML：本文が取れず、JSON で読み直した。
  - manage-asset-packs/submit-apple-hosted-asset-packs：404。
  - shortcuts の event-triggers ページ：App のきっかけが載っていなかった。
- WebSearch で探したもの：asset pack の上限、Shortcuts の App のきっかけ、Kindle と Apple Books の API、DeviceActivityReport のサンドボックス、CloudKit の公開データベースの上限。

### 読んだリポジトリのファイル
- docs/approvals/001-reading-session-G1-decisions.md（最後の2節）
- docs/reviews/001-reading-session-biblio-alt-tech-lead.md（1〜6、未解決）
- docs/reviews/001-reading-session-rethink-tech-lead.md（1、2）
- docs/reviews/001-reading-session-rethink-proposal.md
- docs/reviews/001-reading-session-integrate-tech-lead.md（「これを読んだ人は」とサーバーの行）
- docs/prd/001-reading-session.md（次の1冊の決まり、AC-78〜AC-83、電子書籍の行）、docs/prd/product.md（版の地図）
- docs/adr/（最低の対応 OS）
- 前の spike の材料：…/biblio-alt-tech/dl-ndl/xmlList.txt、oai_pmh.html.txt、…/rethink-tech/spike/main.swift（描く部品を写して使った）

---

## Takuma に決めてほしいこと
1. **バーコードでの一括取得を、国立国会図書館の書誌データを端末に置く形で v1.0 に戻しますか**
   - 推奨：戻します。
     - ISBN のある日本の本の全部（約295万冊、検索なしで約440〜490 MB）を、Apple-Hosted Background Assets で配ります。
     - 見つからない本（新刊など）は、名前で迎える道と「あとで」に落とします。
     - 通信は Apple からの asset pack の取得だけで、利用者の情報は送りません。申請は出しません。
   - いちばん強い反論
     - 約0.5 GB は読書アプリとして重く、入れる前にためらわれます。
     - 買ったその週の新刊は数週間見つかりません。
     - データを替えるたびに審査があります。
     - 手間は +3.5〜6.0日、運用は毎月 0.25〜0.5日です。
     - 軽い代わりの案は「文学（NDC 9）だけ、約65 MB、アプリに同梱」です。ただし漫画、実用書、ビジネス書はバーコードで出ません。
   - 元に戻せるか：はい。出す前なら設計の書き直しで済みます。出したあとに asset pack をやめるのは、名前で迎える道が残るので、足し引きで済みます。
   - 見てほしいもの：この報告の 1 の表と、X/out/mac_sql.log。
2. **デジタル書籍の対応をどこまで v1.0 に入れますか**
   - 推奨：v1.0 には次を入れます（+1.6〜3.0日）。
     - 本ごとの「電子で読む」の印。
     - 進みの単位（ページ、%、位置No.）。
     - 画面写しから一行を押す。
     - 「読み始める」と Live Activity の「終える」で始めて終える。
     - ショートカットのオートメーションの案内。
     - Kindle の端末で読むときは、今の「伏せる」をそのまま使います。
   - v1.1 に回すもの：Share Extension（Kindle が何を共有するかを実機で確かめてから）。
   - 使わないもの：Screen Time の API（entitlement の申請が要り、データも外に出せない）。
   - いちばん強い反論：同じ iPhone で読む人には「伏せて読む」という芯の体験がありません。自動で始めるには、利用者がショートカットを自分で設定する必要があり、iOS 26.6 での誤作動の報告もあります。
   - 元に戻せるか：はい。
3. **レコメンドの形**
   - 推奨
     - v1.0 は規則だけにします（積読から、同じ著者、同じ賞、同じレーベル。1 を入れるなら「この著者のほかの本」と「次の巻」も。+1.0〜2.0日）。
     - Foundation Models には選ばせません。
     - 名前は「これを読んだ人は」にしません。
     - 本当の「これを読んだ人は」は v2 で、上の一覧（サーバーか CloudKit、同意、しきい値、人数）がそろってから作ります。
   - いちばん強い反論：Takuma が言った「これを読んだ人は」は、v1.0 ではその意味では出ません。
   - 元に戻せるか：はい。
- 3つとも私の判断です。決める前に、reviewer に反論を出してもらってください。
- 3つを合わせると手間は +6.1〜11.0日［推測］になります。全体の見積もり（37.96〜53.85日）にどう収めるかは、pdm と指揮役のまとめに任せます。

## 未解決
- 295万冊は8本（40,000件）からの外挿で、±7%ほどぶれます。全部を落としていないので、本当の数と大きさは未確認です。
- 新刊の遅れ（買ってから何日で見つかるか）は［推測：2〜6週］です。JAPAN/MARC の作成日と出版日の差は測っていません。
- iPhone の実機での速さ（DB を開く時間、ISBN を引く時間、asset pack の取得）は測っていません。
- asset pack がアプリを入れるときに一緒に落ちるか（essential の扱い）は、文書を読めていないので未確認です。料金がかかるかも未確認です。
- 3M 行の DB を小さくする工夫（ISBN を整数にする、出版社を番号にする）で 300 MB を切れるかは試していません［推測］。
- 書名の頭から探す索引（B-tree の前方一致）の大きさと速さは未確認です。2字以下の書名の探し方も決まっていません。
- 新着書誌情報の中に、国立国会図書館以外が作ったデータが混ざるかは［推測：provider の表では CC BY］です。G1 で書誌の行ごとの出どころを確かめます。
- 「NDL サーチの API を用いていることを明記」が、ビルドの時にだけ API を使うアプリにも当たるかは［推測：当たる側に倒して表示する］です。
- Kindle と Apple Books が共有シートで何を渡すか、画面写しを禁じる本があるかは、実機がないので未確認です。
- e-ink の端末と iPad の画面の反射は未確認です（合成の画像だけ）。
- ショートカットのオートメーションが確かめなしに動くか（Run Immediately）は、Apple のページに書かれていないので未確認です。
- iOS 26.6 の「閉じられたとき」の誤作動は、フォーラムの書き込みだけで、未確認です。
- Apple が他社のアプリに匿名の集計の仕組みを出していないことは［推測］です。
- 見積もりはすべて［推測］です。

## 記録（指揮役が保存するときに書き足す）
- 種類：調べものと spike（tech-lead）
- 日付：2026-10-20
- spike の産物はリポジトリの外（scratchpad の expand-tech/）。落とした全件ファイル8本と、測るために作った SQLite はリポジトリに入れない
