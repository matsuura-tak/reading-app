# ADR 0004：書誌の問い合わせ（国立国会図書館サーチの OpenSearch に、国立国会図書館の CC BY の書誌2つだけで問い合わせる。openBD は使わない）

- 状態：提案
- 書いた役：tech-lead　日付：2026-10-20
- 関係する PRD、設計メモ、契約：docs/prd/001-reading-session.md（6 の「書誌」、10 の「書誌の出どころが変わる」、11 の冒頭の著者の決まりと問い合わせ直し、AC-2〜AC-6、AC-9〜AC-11、AC-92、AC-93、AC-103、AC-113、12、15、16、17、18 の Q5、付記の G1-5、G1-6、G1-12、G1-13）、docs/adr/features/001-reading-session.md（5、7）、docs/adr/features/001-reading-session-ndl-check.md（結果）、contracts/ndl-opensearch.yaml
- 元に戻す手間：中。送り先と送り方を変えるのは1〜2日［推測］。ただし、保存した本の書誌（書名、著者など）は v1.0 から端末に残るので、取り出し方を変えても前に加えた本は直らない（直すなら、問い合わせ直しの移行が要る）。

## 背景
- 決める必要があったこと
  - 登録（バーコードの ISBN、書名で探す）、順番待ち、見つからなかった本の問い合わせ直しで、どこに、どの形で、どう送るか。
  - 設定の画面に出すクレジットの文（G1-5）、プライバシー表示（G1-12）、ラテン文字の著者（G1-13）、openBD を使うか（G1-6）。
- 制約
  - v1 はサーバーなし。外に送るのは書誌の問い合わせだけ（AC-103）。
  - 課金しても利用申請を出さない前提なので、国立国会図書館が自分で作った CC BY の書誌だけを使う（裁定 14）。
  - 外部のライブラリは入れない（ADR 0001）。最低 iOS 26。3週の枠。
  - 国立国会図書館サーチの決まり（API のヘルプ 17-4）
    - (1)「APIをご利用いただく際は、多重アクセスが生じないようご対応をお願いいたします。」アクセス数の上限の数字は「お示しすることができません」とある。
    - (2)「本APIを利用するサイトやアプリケーションには、NDLサーチのAPIを用いていることを明記してください。」「クレジット表示には、API提供対象データプロバイダ一覧に記載されているデータプロバイダ及びそのデータ提供機関の名称を含めてください。」
- 確かめの結果（2026-10-20。docs/adr/features/001-reading-session-ndl-check.md の「結果」）
  - 30件中29件で、書名、著者、出版社がそろった（線は27件）。合格。
  - 出て14日以内の5件（記録だけ）は3件。

## 決定
国立国会図書館サーチの OpenSearch に、dpid を `iss-ndl-opac iss-ndl-opac-inprocess` に絞った GET だけを、ephemeral の URLSession で1件ずつ送る。openBD は v1.0 では使わない。細かい値は次の表のとおり（送る形と要素の対応は contracts/ndl-opensearch.yaml が正）。

| # | 決めること | 決めた値 | 根拠 |
|---|---|---|---|
| 1 | 送り先 | `https://ndlsearch.ndl.go.jp/api/opensearch` だけ。AC-103 と G4-20 の「書誌の出どころのホスト」は `ndlsearch.ndl.go.jp` | 契約 |
| 2 | dpid | `iss-ndl-opac iss-ndl-opac-inprocess`（URL では空白を `%20`）。iss-ndl-opac-national は入れない。ほかの提供元も入れない | データプロバイダ一覧：iss-ndl-opac は新着書誌情報を「含まない」ので2つ要る。iss-ndl-opac-national は iss-ndl-opac の「うち」で、足しても増えない |
| 3 | ISBN で引く形 | `dpid=…&isbn=<13桁>`。cnt は付けない。ISBN（10桁は13桁に直した値）が問い合わせた ISBN と同じ最初の item を使う。なければ「見つからない」 | 35件すべてが0件か1件だった。「最初の item」でも「一致する最初の item」でも29件で同じ |
| 4 | 書名で探す形と件数 | `dpid=…&title=<書名>&cnt=200` を1回。ページ送りはしない。端末で、ISBN のない item を除き、同じ ISBN の2つ目から後ろを除き、並べ直す（そろえた書名が、そろえた入れた書名と同じ → それで始まる → ほか。同じ組の中は応答の順のまま）。そろえ方は PRD の 11 の冒頭の「名前のそろえ方」。書名の「+」は `%2B` にして送る | 仕様書の表 4-1 に並べ替えの引数はない。応答は書名の読みの順（ア→タ）だった。cnt=50 では「人間失格」の新潮文庫が入らない（264件中175番目）。cnt=200 は5.70秒、635,702 バイトで入る。cnt=500 は24.63秒。URLComponents は「+」をそのまま送る（相手が「+」を空白と読むかは未確認） |
| 5 | 要素の対応 | 契約の 200 の応答の対応表。書名は dc:title に dcndl:volume を足す（例「マーブル館殺人事件 上」）。著者は PRD の 11 の冒頭の決まり（AC-92）。出版社は dc:publisher の1つ目。レーベルは dcndl:seriesTitle の「 ; 」より前。出版年は dcterms:issued の頭の4桁。書名と著者は100字を超えたら101字目から後ろを捨てる | 実際の応答。13桁の本の ISBN の要素に10桁の値（「4-10-100605-9」）が入っていた。PRD の 11 の冒頭は「鹿の王 上」の形の書名を前提にしている |
| 6 | 同時に送る数 | 1件。前の応答か失敗を待ってから次を送る。わざと間を空けることはしない | 17-4 (1) |
| 7 | 待ちの打ち切り | `timeoutIntervalForRequest` と `timeoutIntervalForResource` を、どちらも30秒 | 2026-10-20 の76件で p50 2.30秒、p90 7.18秒、最大14.83秒。dpid なしの1件は20秒で答えがなかった。最大の約2倍にした |
| 8 | 応答の大きさの上限 | 2 MB。超えたら読むのをやめて「失敗」 | ISBN の形の最大は14,396 バイト。cnt=200 は635,702 バイト |
| 9 | キャッシュとクッキー | `URLSessionConfiguration.ephemeral` に、`urlCache = nil`、`httpCookieStorage = nil`、`httpShouldSetCookies = false`、`requestCachePolicy = .reloadIgnoringLocalCacheData`。ヘッダーに ID を足さない | 応答に `Cache-Control: max-age=54294〜60581, public` が付いていた。既定の構成では、探した ISBN と書名がディスクのキャッシュに残りうる。Set-Cookie は一度も来なかったが、来ても残さない |
| 10 | XML の読み方 | Foundation の XMLParser。`shouldResolveExternalEntities = false` をコードで明示する | ADR 0001（外部ライブラリなし）。既定値に頼らない |
| 11 | 通信のコードの場所 | ReadingStore の中の1つのファイル（名前は仮で NDLOpenSearchClient.swift）だけ。AC-103 の G2 の grep（`URLSession|NWConnection|CFStream|WKWebView|URLRequest`）の当たりは、このファイルだけにする | ADR 0001 の表で、書誌の問い合わせは ReadingStore が持つ |
| 12 | 「見つからない」と「失敗」 | HTTP 200 で、使う item がない → 見つからない（AC-10、notFound）。通信の失敗、30秒の打ち切り、200 以外、2 MB 超え、XML として読めない → 失敗（AC-11、pending のまま） | 仕様書「引数（パラメータ）誤りの場合には検索結果ゼロ件となる」。だから URL の形を単体テストで固定する |
| 13 | 問い合わせ直し | 下の「問い合わせ直しの決まり」 | PRD の 11 の冒頭 |
| 14 | openBD | v1.0 では使わない。AC は足さない | 下の検討した案の B |
| 15 | クレジットの文（G1-5） | 下の「クレジットの文」 | 17-4 (2)、CC BY 4.0 |
| 16 | 「収集」に当たるか（G1-12） | 当たらない。App Store のプライバシーの答えは「データの収集なし」。PrivacyInfo.xcprivacy は、NSPrivacyTracking を false、NSPrivacyTrackingDomains を空、NSPrivacyCollectedDataTypes を空の配列、NSPrivacyAccessedAPITypes は ADR 0002 のとおり0件。最後に決めるのは G5 の reviewer | 下の「収集に当たるか」 |
| 17 | ラテン文字の著者（G1-13） | 推奨は C（author 要素の責任表示から、表紙と同じ形の名前を取る）。PRD の決まりを変えるので、pdm と designer が決めるまでは A（PRD のまま）で作る | 下の「ラテン文字の著者」 |

### 問い合わせ直しの決まり
- 送る時
  - 登録の直後と、アプリが前に来たとき（scenePhase が active になったとき）。
  - 通信がない（NWPathMonitor の status が satisfied でない）なら送らず、本は pending のまま（AC-9）。
- 順
  - pending の本を addedAt の古い順に。そのあと、問い合わせ直す notFound の本を addedAt の古い順に。1件ずつ（表の 6）。
- 失敗したら
  - その回は残りを送らない（止まっている相手に続けて送らないため）。
  - 本は pending（notFound の本は notFound）のまま。次にアプリが前に来たときに、また送る。同じ回の中では送り直さない。
- lastLookupAt は、HTTP 200 の応答を読めたとき（見つかった、見つからない）だけ書く。失敗では書かない。
- notFound の本は PRD のとおり。手で直していない、前の問い合わせから24時間以上、加えてから1,080時間（45日）以内なら、前に来たときに1回（AC-113）。
- 見つかった本（found）は問い合わせ直さない。
  - 新着書誌情報は「未完成の書誌であるため、後に修正される場合がある」が、v1.0 は最初に取った値を残す。利用者は手で直せる。

### クレジットの文（G1-5。文言キー `settings.dataSources`。designer が文言表に写す）
- 日本語の構成
  > 書誌（書名、著者、出版社など）は、国立国会図書館サーチ（NDLサーチ）の API を用いて取得しています。書誌のデータは、NDLサーチの API から取得した「国立国会図書館蔵書」と「国立国会図書館新着書誌情報」（データ提供機関：国立国会図書館）に由来します。著者名などは、このアプリで表示用に整えています。ライセンスは、クリエイティブ・コモンズ 表示 4.0 国際 パブリック・ライセンス（CC BY 4.0）です。
- 英語の構成（日本語の正式名も括弧で出す。データプロバイダ一覧の正は日本語の版で、英語の版の名前と両方で照らせるようにするため）
  > Book details (title, author, publisher, and so on) are retrieved using the NDL Search API (National Diet Library Search). The bibliographic data derives from “National Diet Library Catalog” (国立国会図書館蔵書) and “NDL newly acquired bibliographic data” (国立国会図書館新着書誌情報), provided by the National Diet Library, Japan (国立国会図書館), via the NDL Search API. Author names and other fields are formatted for display by this app. License: Creative Commons Attribution 4.0 International (CC BY 4.0).
- `settings.dataSources.license` で開く URL
  - 日本語の構成は `https://creativecommons.org/licenses/by/4.0/deed.ja`、英語の構成は `https://creativecommons.org/licenses/by/4.0/`。
  - どちらも AC-93 の「`https://creativecommons.org/licenses/by/4.0/` で始まる」を満たす。
- 照らした条件
  - 17-4 (2) の「NDLサーチのAPIを用いていることを明記」：1文目。
  - 同じく「データプロバイダ及びそのデータ提供機関の名称」：一覧の表の名前のとおり（日本語：国立国会図書館蔵書、国立国会図書館新着書誌情報、データ提供機関は国立国会図書館。英語：National Diet Library Catalog、NDL newly acquired bibliographic data）。
  - 17-4 の表示例の形（「…国立国会図書館サーチのAPIから取得した[△△デジタルアーカイブ]（[データ提供機関]が運営）に由来します。 ライセンスは クリエイティブ・コモンズ 表示 4.0 国際 パブリック・ライセンス です。」）に合わせた。
  - CC BY 4.0 の 3(a)(1)(B)「indicate if You modified the Licensed Material」：3文目（著者の取り出し、書名に巻を足すこと）。
  - openBD を使わないので「openBD」は入れない（AC-93）。

### 収集に当たるか（G1-12）
- Apple の定義
  - "“Collect” refers to transmitting data off the device in a way that allows you and/or your third-party partners to access it for a period longer than what is necessary to service the transmitted request in real time."
  - "“Third-party partners” refers to analytics tools, advertising networks, third-party SDKs, or other external vendors whose code you’ve added to your app."
- 当てはめ
  - 開発者はサーバーを持たず、国立国会図書館サーチの記録を読めない。
  - 国立国会図書館のコードはアプリに入れていない。アプリの URLSession で GET を送るだけ。
  - 送るのは ISBN か書名だけ。ID、クッキーを送らず、キャッシュも残さない（表の 9）。
  - だから「開発者か third-party partners が、要求に答えるのに要る時間より長く読める形で送る」に当たらない。
- PRD の 15 の表の「Book Info Requested」の行は、この決定で「収集に当たらない」に確定してよい［G5 で reviewer が確かめる］。

### ラテン文字の著者（G1-13）
| 案 | 実際の応答で出た値 | 良い点 | 悪い点 |
|---|---|---|---|
| A PRD のまま（(5) で半角空白を挟む） | Horowitz Anthony、Kiyosaki Robert T、Donati Alba、Rees Laurence、Fitzgerald Francis Scott | 決まりも AC-92 も今のまま | 姓が先のラテン文字で、表紙（アンソニー・ホロヴィッツ）と違う。35件中5件（14%）に当たった |
| B ラテン文字なら2つの部分を入れ替える | Anthony Horowitz、Robert T Kiyosaki | 決まりが短い | 表紙のカタカナとやはり違う。PRD と AC-92 を直す手間は C と同じ |
| C ラテン文字なら、author 要素の責任表示の最初の部分を使う（推奨） | アンソニー・ホロヴィッツ、ロバート・キヨサキ、アルバ・ドナーティ、ローレンス・リース、スコット・フィッツジェラルド | 表紙と同じ形。5件すべてで取れた | 決まりが長くなる。PRD の 11 の冒頭を pdm が直し、AC-92 に行を verifier が足す |
- C の決まり（案）
  - (1)〜(5) で取り出した値に、かなも漢字もないときだけ使う。
  - author 要素が「dc:creator の値を出てきた順に「,」でつないだもの」と「,」で始まるなら、その残りを「,」で区切った最初の部分に (2)〜(5) を当てる。
  - 結果にかなか漢字があればそれを使う。なければ A の値を使う。
  - 例：dc:creator「Horowitz, Anthony, 1955-」「山田, 蘭, 1964-」、author「Horowitz, Anthony, 1955-,山田, 蘭, 1964-,アンソニー・ホロヴィッツ 著,山田蘭 訳」→ 残り「アンソニー・ホロヴィッツ 著,山田蘭 訳」→「アンソニー・ホロヴィッツ」。
- カタカナの著者（例「ペク, スンヨン」→「ペクスンヨン」）は、国立国会図書館の責任表示も「ペクスンヨン 著」なので、どの案でも変えない。

## 検討した案
### 書誌の出どころ
| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| A 国立国会図書館サーチの OpenSearch、dpid 2つ（採用） | CC BY なので課金しても申請が要らない（裁定 14）。30件中29件。送り先が1つ。ISBN は完全一致 | 出て14日以内の本は5件中3件。書名で探すと、並びが読みの順で、録音資料なども混ざる。引数の誤りが0件に見える | — |
| B A に openBD を補いとして足す | NDL になかった3件（出て14日以内の2件と、岩波書店の1件）を、openBD は3件とも返した（1件は出版社が空） | 送り先が2つになる（AC-103、G4-20、プライバシーポリシー）。「本の販促・紹介目的に限り」と有料のアプリの関係が未確認。著者が空白区切りで役割の語がなく（例「ヴァレンティーナ・ゴッタルディ ダニオ・ミゼロッキ マチェイ・ミフノ 森敦子 国立科学博物館」）、AC-92 の決まりが使えないので AC を足す要がある。キャッシュの条項（変更の反映、削除の要請）を守る仕組みが要る | 線を NDL だけで満たした。足りない新刊は AC-113 の問い合わせ直しで埋まる見込み［推測］。条項の確かめと AC の追加が3週の枠に合わない |
| C dpid を付けずに NDL サーチ全体を引く | NDL になかった3件は、どれもほかの提供元にあった（2件は出版情報登録センター（JPRO）） | CC BY でない書誌が混ざり、課金するなら利用申請が要る | 裁定 14 に反する |
| D SRU（CQL）に替える | 書名の完全一致や並べ替えで引ける見込み［推測］ | 応答の形が別で、契約とテストを作り直す。並べ替えと完全一致は確かめていない（未確認） | 7-2 で確かめていない。見直す条件に回す |

### 書名で探す件数
| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| E cnt=50 を1回（design r1 の推奨） | 159,572 バイトと軽い | 並びが読みの順で、「人間失格」の新潮文庫が入らない（50件中、ISBN のある21件はどれも別の本） | AC-4 の目的（探した本を選べる）に届かない |
| F cnt=200 を1回（採用） | 新潮文庫が入る（175番目）。端末で並べ直せば上に来る | 5.70秒、635,702 バイト。200件を超える書名では、読みの順で後ろの本が入らない | — |
| G cnt=500 を1回 | 264件すべて | 24.63秒、761,549 バイト | 遅い |

### 収集に当たるか
| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| 当たらない（採用） | 「データの収集なし」と出せる。PRD の 15 の見込みと同じ | 審査で問われたら、答えを直す手間がある | — |
| 当たるとして「検索履歴」（ユーザーに結び付かない、トラッキングなし）を申告する | 慎重で、問われにくい［推測］ | 表示が実際（だれも記録を読めない）と合わない。「データの収集なし」でなくなる | Apple の定義に当たらない |

## いちばん強い反論と、それでも選んだ理由
- 反論1：「出て14日以内の本は、5件中2件が CC BY の書誌になかった。新刊を買ったその夜に登録する人は多く［推測］、最初の体験で『見つからない』が出る。openBD か JPRO を足せば埋まる。」
  - 線は「15〜28日前に出た本」で決めてあり、そこは10件中9件（うち6件は新着書誌情報から）。
  - 新着書誌情報は「当館納入後約4日で取得可能」。見つからない本は、手で入れられ（AC-7）、24時間ごとに45日まで問い合わせ直す（AC-113）。
  - JPRO を足すと CC BY の外になり、課金するなら申請が要る。openBD を足すと、条項の確かめと AC の追加が要る。
  - だから v1.0 は A のまま。G4-10（10冊中9冊）に届かなければ見直す。
- 反論2：「国立国会図書館サーチは、送られた ISBN、書名、IP アドレスを記録しているかもしれない。送り先を選んだのは開発者なので、『other external vendors』に当たると読む審査員もいる。」
  - 定義の vendors には「whose code you’ve added to your app」がかかっていて、このアプリには入れていない。開発者も記録を読めない。
  - 審査で問われたら、「検索履歴」（ユーザーに結び付かない、アプリの機能のため、トラッキングなし）の申告に切り替える。

## 結果
- これで楽になること
  - サーバー、利用申請、外部のライブラリが要らない。送り先は1つで、AC-103 と G4-20 が単純になる。
  - プライバシー表示を「データの収集なし」で出せる見込み。
- これで難しくなること、守り続けること
  - dpid の2つを変えない。変えると CC BY の外の書誌が混ざりうる。
  - 引数の誤りは0件に見えるので、送る URL の形を単体テストで固定する。公開の前（G4）に、このときの問い合わせのスクリプト（scratchpad の g1-7-2/py/ndl.py）と同じ形で、3件以上を本番に問い合わせて1件以上返ることを見る。
  - クレジットの文の名前を、データプロバイダ一覧の名前に合わせ続ける。
  - 新着書誌情報の書誌が後で直っても、アプリの本は直らない。
  - 書名で探すと、関わりの薄い本も最大200件並ぶ（ISBN のある分だけ）。
- 元に戻すときの手順と手間
  - 送り先を足す（openBD など）：ホストを AC-103、G4-20、プライバシーポリシー、クレジットの文に足し、著者の取り出しの AC を足す。2〜3日［推測］。
  - 保存した本の書誌は前の決まりのまま残る。直すなら、found の本も問い合わせ直す移行を足す。

## 見直す条件
- G4-10 で、10冊中9冊に書名、著者、出版社が埋まらない回が1回でもある。
- 公開のあと、「本が見つからない」という問い合わせが1か月に5件を超える［推測の線］。
- 国立国会図書館サーチの仕様書の版が第1.5版（2026-09-25）から上がった、または、データプロバイダ一覧で2つの書誌の利用条件が CC BY でなくなった。G4 の前に一覧と仕様書を開いて確かめる。
- G4 の実機で、30秒の打ち切りによる失敗が10回の問い合わせのうち2回以上ある。
- App Review がデータの収集を問うた（反論2の切り替え）。
- G3 で design-reviewer か verifier が「書名で探しても、探した本が出ない」と判定した。案 D（SRU）の spike を行う。
- openBD の条項が変わった。または、18 の Q5 で書誌の出どころを変えると決まった。

## 確かめたこと
- 開いたページ（2026-10-20）
  - https://ndlsearch.ndl.go.jp/help/api ：17-4 (1) と (2) の原文（上の「背景」に引用）。17-4 の表示例「本サービスで提供するのメタデータの一部は、国立国会図書館サーチのAPIから取得した[△△デジタルアーカイブ]（[データ提供機関]が運営）に由来します。 ライセンスは クリエイティブ・コモンズ 表示 4.0 国際 パブリック・ライセンス です。」
  - https://ndlsearch.ndl.go.jp/help/api/provider ：表の行「R100000002／国立国会図書館蔵書／国立国会図書館／iss-ndl-opac／CC BY (1)」「R100000002／国立国会図書館新着書誌情報／国立国会図書館／iss-ndl-opac-inprocess／CC BY (1)」「R100000002／国立国会図書館全国書誌情報／国立国会図書館／iss-ndl-opac-national／CC BY (1)」。注 (1)「国立国会図書館が作成し提供する書誌データの二次利用条件 クリエイティブ・コモンズ 表示 4.0 国際 パブリックライセンス（CC BY）と互換性がある。」iss-ndl-opac の説明「次のデータプロバイダのメタデータは含まない。 国立国会図書館新着書誌情報（iss-ndl-opac-inprocess）」。新着書誌情報の説明「当館納入後約4日で取得可能。未完成の書誌であるため、後に修正される場合がある。」全国書誌情報の説明「国立国会図書館蔵書（iss-ndl-opac）のうち、作成が完了した全国書誌データ…が対象。」
  - https://ndlsearch.ndl.go.jp/en/help/api/provider ：表の行「National Diet Library Catalog／iss-ndl-opac」「NDL newly acquired bibliographic data／iss-ndl-opac-inprocess」。
  - https://ndlsearch.ndl.go.jp/file/help/api/specifications/ndlsearch_api_20260925.pdf （外部提供インタフェース仕様書 第1.5版。PDFKit で文字を取り出して読んだ）：表 4-1 の cnt「出力レコード上限値（省略時は200 とする）」、isbn「10 桁または13 桁で入力した場合は、10 桁、13 桁の両方に変換して完全一致検索を行う。」注「dpid と mediatype に関しては OR 検索、他は AND 検索となる。dpid のみ指定した検索はできない。」「引数（パラメータ）誤りの場合には検索結果ゼロ件となる。」(4)「デフォルトの返戻件数は200 件で、一度に取得できる最大件数は 500 件である。」並べ替えの引数は表 4-1 にない。
  - https://developer.apple.com/app-store/app-privacy-details/ ：「Collect」と「Third-party partners」の定義（上に引用）。"Data that is processed only on device is not “collected” and does not need to be disclosed in your answers."
  - https://developer.apple.com/documentation/foundation/urlsessionconfiguration/ephemeral ："the corresponding session object doesn’t store caches, credential stores, or any session-related data to disk. Instead, session-related data is stored in RAM."
  - https://developer.apple.com/documentation/foundation/urlsessionconfiguration/timeoutintervalforrequest ："how long (in seconds) a task should wait for additional data to arrive before giving up." timeoutintervalforresource："how long (in seconds) to wait for an entire resource to transfer before giving up."
  - https://developer.apple.com/documentation/bundleresources/privacy-manifest-files ：キーの名前 NSPrivacyTracking、NSPrivacyTrackingDomains、NSPrivacyCollectedDataTypes、NSPrivacyAccessedAPITypes。
  - https://creativecommons.org/licenses/by/4.0/legalcode.en ：3(a)(1)(B)「indicate if You modified the Licensed Material and retain an indication of any previous modifications」。
- 動かしたもの（リポジトリの外：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-2/）
  - `python3 -I py/ndl.py query <一覧> <作業のフォルダ>`：2026-10-20 01:48:57〜01:55:05 に76件を1件ずつ。数えた形の35件はすべて HTTP 200。結果は一覧のファイルの「結果」。
  - 引数の誤りの3件（cnt=abc、知らない dpid、dpid だけ）：どれも HTTP 200、`openSearch:totalResults` 0。
  - 書名で探す（人間失格）：cnt=50 は264件中50件（図書39、録音資料9、映像資料2）、ISBN のある item 21件、新潮文庫なし。cnt=200 は5.70秒、ISBN のある item 110件、新潮文庫は175番目。cnt=500 は24.63秒、264件。
  - spectral：`spectral-macos-arm64 lint contracts/ndl-opensearch.yaml --ruleset <scratchpad>/spectral/.spectral.yaml --fail-severity hint`（v6.17.0。ルールは `extends: ["spectral:oas"]`）→ `No results with a severity of 'hint' or higher found!`、exit 0。既定の重さの線でも `No results with a severity of 'error' found!`、exit 0。
  - 契約の XML の例3つは、Python の ElementTree で読めた（`xml examples well-formed: 3`）。
- 未確認
  - HTTP 200 のほかの応答の形（仕様書になく、問い合わせでも出なかった）。
  - dpid で絞ったとき、item の値に、同定でまとめたほかの提供元の値が入ることがないか。仕様書の 2 (6) に「同一と見なした資料について同定を行ったメタデータを検索の対象」とある。返った item の link はすべて R100000002 で、ほかの提供元は rdfs:seeAlso の URL にだけ出た。
  - 相手が「+」を空白と読むか（表の 4。`%2B` にして避ける）。
  - Swift での作り（ephemeral の構成、XMLParser、NWPathMonitor）は spike をしていない。G2 の前に ios-engineer の単体テストで確かめる。
  - 案 D（SRU）の並べ替えと完全一致。

## 確かめ（B）
- [x] 案が2つ以上あり、どの案にも悪い点が書いてある
- [x] 反論、悪い結果、見直す条件が空でない
- [x] 確かめたことに、URL かコマンドの出力がある
