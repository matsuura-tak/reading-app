（指揮役の注）これは判定ではなく、収益とローカル AI を検討するための調べもの（tech-lead）の報告。担当は、ローカル AI の機能（前回のあらすじ、言葉の説明、読み上げ）と課金の仕組みが作れるか。spike は Mac（macOS 27）と合成のページで行った。前の体が利用量の上限で止まったので、同じ指示で呼び直した体の報告。報告の文はそのまま保存した。

# ローカル AI の機能と課金の仕組みが作れるか（tech-lead、呼び直し、2026-10-18）

## 結論
1. 撮ったページから端末の AI で「前回のあらすじ」を作るのは、今の品質では**難しい**。合成のページで試すと、出力36件中22件（61%）に本文と違う事実が入りました（例：「遥は遥の父の店を訪ねた」。正しくは美咲の父）。さらに42回中6回（14%）は答えが返りませんでした。日本語で決まった形で出させる方法（guided generation）は、出力が止まらなくなる不具合が多く、語の説明では20回中10回が止まりませんでした（1回65〜98秒）。
2. AI を使わずに、どの機種にも出せる機能のほうが筋がよいです。読みがなは CFStringTokenizer で20語すべて正解、意味は端末の辞書（UIReferenceLibraryViewController）、読み上げは AVSpeechSynthesizer で出せます。Personal Voice は日本語に対応していません。
3. Apple Intelligence が使える iPhone は、日本の iPhone 利用者の**約39〜52%**です（MMD研究所、2026年8月）。AI を課金の中心にすると、半分ほどの人は買っても使えません。
4. 課金は StoreKit 2 だけで、サーバーなしに作れます（負担 S〜M）。日本の手数料は Small Business Program なら 10%、Apple の決済に 5% が足されます。収益を得るなら国立国会図書館サーチの利用申請が先に要ります（費用と期間はページに書かれていません）。Google Books は、利用者からお金を取るアプリでは書面の許可なしに使えません。
5. iOS 27 では Private Cloud Compute（PCC）のモデル（枠32K）を呼べるようになりましたが、資格と entitlement が要り、この Mac では16回すべて失敗しました（**未検証**）。技術からの推奨：課金はどの機種でも動く価値に付け、AI は対応機種での上乗せにとどめ、v1 には入れない。

## 機能ごとの判定
負担の目安［推測］：S＝数日、M＝1〜2週、L＝2週より長いか、品質を詰めるのに何日かかるか読めない。

| 機能 | 判定 | 負担 | v1 に入れられるか | 主な根拠 |
|---|---|---|---|---|
| A1 前回のあらすじ（端末の Foundation Models で自由に書かせる） | 難しい | L | 入れない | 本文と違う事実が61%、答えが返らない14%（spike） |
| A2 前回の最後の数行（撮ったページの最後の2〜3文をそのまま出す。AI なし） | できる | S | 入れられる | 読み取った文の切り出しだけ。ルビの崩れは残る |
| A3 あらすじ（PCC、iOS 27 から） | 未検証 | M（＋資格の手続き） | 入れない | 資格と entitlement が要る。オフラインでは動かない。1日の上限あり。品質は測れていない |
| B1 読みがな（CFStringTokenizer） | できる | S | 入れられる | 20語中20語正解（spike。語だけで試した） |
| B2 意味（UIReferenceLibraryViewController） | できる | S | 入れられる | 端末の辞書の画面を出すだけで、文は取り出せない（公式） |
| B3 意味と読み（Foundation Models で作らせる） | 難しい | M | 入れない | 読みは20語中1語だけ正解。意味にも誤りがあり、半分は出力が止まらない |
| B4 NaturalLanguage | 難しい（使える機能がない） | - | - | 日本語は言語、文字の種類、語の区切りの3つだけ。語と文の埋め込みもない |
| C1 読み上げ（AVSpeechSynthesizer の日本語の声） | できる | S〜M | 入れられる | 標準の速さで492字/分（spike） |
| C2 撮ったページの読み上げ | 条件付き | M | 入れられる（ルビの読みがなを消す処理が要る） | 混じった読みがなまで声に出す。SSML の別の読み方の指定（sub alias）は効かない（spike） |
| C3 Personal Voice（日本語） | 難しい | - | 入れない | 対応言語は英語（米国）、中国語（中国本土）、スペイン語（メキシコ）だけ（公式） |
| D1 自動更新の定期課金と無料体験 | できる | M | 入れられる | 3.1.2(a)：続けて価値を出すこと、期間は7日以上、どの端末でも使えること |
| D2 買い切り（非消耗型） | できる | S | 入れられる | StoreKit 2 |
| D3 買い切りの試用（「XX-day Trial」） | 条件付き | M | 入れられる | 0円の非消耗型を使う。試用の期限はアプリが自分で数える（3.1.1） |
| D4 サーバーなしでの購入の確かめ | できる | S | 入れられる | VerificationResult が端末の中で署名を確かめる（公式） |
| D5 Family Sharing | できる | S | 入れられる | 最大5人。App Store Connect で品ごとに入れる（公式） |
| D6 返金 | できる | S | 入れられる | 返金や取り消しのあった品は currentEntitlements に出ない。アプリから返金を頼む画面も出せる（beginRefundRequest。SDK に宣言がある） |
| E1 国立国会図書館サーチ（収益あり） | 条件付き | S（手続きだけ） | 課金を始める前に申請する | 収益を得るなら申請が要る。費用と期間は書かれていない |
| E2 openBD（有料のアプリ） | 条件付き | S | 使い方次第 | 「本の販促・紹介目的に限り」使える。有料のアプリについての記述はない［推測で可］ |
| E3 Google Books（有料のアプリ） | 難しい | - | 入れない | 「You may not charge users any fee for the use of your application」 |

## 1. 前回のあらすじ
### 前の体のファイルを使った
- 前の体の fm.log（`./spike fm` の出力。終わりに「23:15.92 total」）を使いました。fm の実行はやり直していません。spike.swift を読み、ログの形式がコードの出力の形と合うことを確かめました。本文と違う事実かどうかは、ログの自動の判定（ずれた語の数え上げ）を信じず、出力を1件ずつ読んで判定し直しました。
- 試し方：合成した小説のページ（約400字。ルビの読みがなの混入と誤字を入れた読み取り結果）を、1ページ、見開き、3ページ、事件の場面のページで渡し、2行のあらすじを作らせました。出させ方は3通りです。plain は自由な文、guided は決まった形（1行目と2行目）、grounded は先に本文から3文を引き写させてから2行を書かせる形です。それぞれ4回ずつ（1回は毎回同じ答えになる設定、3回はばらつく設定）。Mac、macOS 27 です。

### 本文と違う事実の割合（手で判定）
| 出させ方 | 答えが返った件数 | はっきりした誤り | 軽いずれ | 例 |
|---|---|---|---|---|
| plain | 15 | 12（80%） | 1 | 「翌朝、灯台守の家を訪ねた」（本当は日曜）、「犯人は金庫の番号を知っていた」（本文にない） |
| guided | 9 | 7（78%） | 2 | 「若い男の写真を見せた」（見せたのは老人）、「灯台守の家の住所があった」（本文にない） |
| grounded | 12 | 3（25%） | 3 | 誤りは減るが、本文の文をほぼ抜き書きするだけになる |
| 合計 | 36 | 22（61%） | 6 | 誤りがなかったのは8件（22%） |
- 読み取りの崩れ（「灯合守」「写貞館」）が、36件中18件の出力にそのまま出ました。
- 答えが返らなかったもの：42回中6回。出力が止まらず枠の4096トークンを超えたのが4回（どれも guided。60〜190秒かかって失敗）。普通の文なのに安全のための止め（ガードレール）が働いたのが2回です。同じ文を2回つなげて8ページ分にすると通ったので、止まるかどうかは毎回変わります。
- 今回足した試し（spike2 の cap）：出力のトークン数の上限（maximumResponseTokens: 120）を付けると、止まらない出力は2.4〜5.4秒で切れました。ただし6件中5件で、出力の文字列が「」}」のあとも閉じず、指示文の書き写しや「。。。」が続きました。本文と違う事実も残りました（「兄に相談」。本当は弟で、相談もしていない）。

### 時間と枠
- 時間（Mac。大きく外れた値を除いた中央値）：plain 1.5〜2.0秒、guided 2.2〜3.2秒、grounded 3.4〜5.7秒。最初の1回は1.6秒でした。原因の分からない外れ値が42回中2回ありました（177秒、629秒）。iPhone では測っていません（**未検証**）。
- 枠：tokenCount で測ると、この合成の文は1字あたり0.65〜0.71トークンでした。読み取ったページは1枚約290トークン、指示文が140、決まった形の定義が98〜156トークンです。出力に150トークン残すと、400字のページで約12枚、詰まった文庫のページ（約600字）で約8枚が入ります。実際に8ページ分（2224トークン）は3.7秒で通りました。PCC の枠は32,768トークンです（spike で値を読んだ）。

### 判定
- A1 は難しいです。本を読む人に向けて事実を言い切る機能としては、誤りが多すぎます。作るなら、上限（maximumResponseTokens）、時間切れ、出力の検査（長さ、指示文が混じっていないか）、AI なしの代わりの表示、が全部要ります。
- 1ページだけのあらすじは、最後の数行をそのまま出す A2 とあまり変わりません。A2 は AI なしで作れて、全機種で動きます。
- 端末のモデルの能力に `vision`（画像を受け取る）が載っていました（`guidedGeneration`、`toolCalling` と並んで）。ページの写真を直接渡す形は試していません（**未検証**）。

## 2. 言葉の説明（spike2 の word）
- 読みがな：CFStringTokenizer で読みのローマ字を取り、ひらがなに変えると、20語すべて正解でした（躊躇、所以、出納（すいとう）、恵山岬（えさんみさき）、湊（みなと）など）。CoreFoundation の API で、オフラインで全機種に使えます。ただし語を1つずつ渡して試しただけで、文の中での読みと、iPhone での結果は**未検証**です。
- 意味：UIReferenceLibraryViewController は端末の辞書の画面を出すだけで、定義の文は取り出せません。公式に「単語の一覧、単体の辞書アプリ、内容の再配布には使わない」とあります（https://developer.apple.com/documentation/uikit/uireferencelibraryviewcontroller 、2026-10-18）。`dictionaryHasDefinition(forTerm:)` で、定義があるかを先に確かめられます。Mac の辞書（DCS。macOS だけの API）には20語中19語の定義がありました（なかったのは固有名詞の恵山岬だけ）。iPhone に初めから日本語の辞書が入っているかは**未検証**です。
- Foundation Models：読みは20語中1語だけ正解（「黄昏＝きょうごん」「出納＝しゅつなお」など）。意味にも誤りがありました（「躊躇＝手を使わずに考えること」）。20回中10回は出力が止まらず、枠を超えて失敗しました。出力に内部の記号（`<<|model_response|>`）が混じった件もありました。
- NaturalLanguage：日本語で使えるのは言語、文字の種類、語の区切りの3つだけで、読みも品詞もありません。日本語の語と文の埋め込みもありませんでした（どちらも false）。
- 推奨：語をタップすると CFStringTokenizer の読みがなを出し、「辞書で見る」で UIReferenceLibraryViewController を開く形です。どちらも S、AI は要りません。

## 3. 端末の中の読み上げ（spike2 の tts）
- 声：この Mac の日本語の声は、Kyoko（compact）と Eloquence の8声で、どれも標準の品質でした。高品質の日本語の声を利用者が端末に入れているかどうかで、聞きやすさが変わります。アプリは `AVSpeechSynthesisVoice.speechVoices()` で入っている声の中からいちばん品質の高いものを選べます。アプリから声を入れさせることはできません［推測］。
- 速さ：378字を標準の速さ（0.5）で46.1秒、つまり492字/分でした。0.6 にすると29.3秒（774字/分）です。600字のページは標準の速さで約73秒です。
- 縦書き：読み上げるのは読み取った文なので、紙面の向きは関係ありません。読む順番が正しいかは、Vision の読み取りしだいです（Vision が縦書きを読めることは確かめ済み）。
- ルビ：「躊ちゅう躇ちょした。」は1.51秒、きれいな「躊躇した。」は0.93秒でした。読み取りに混じった読みがなまで声に出します。SSML の `<sub alias>` で読み方を指定しても、長さは0.99秒のまま変わらず、効きませんでした。読み上げる前に文を直す処理が要ります。漢字のすぐ隣のかなが、その漢字の CFStringTokenizer の読みと同じなら消す、という規則が考えられます［推測、M］。読み違えた漢字（写貞館）は直せません。
- Personal Voice：日本語はありません（https://www.apple.com/ios/feature-availability/ 、2026-10-18。英語（米国）、中国語（中国本土）、スペイン語（メキシコ）だけ）。許可を求める API は iOS 17 からあります。
- 私的使用と審査：自分で撮ったページを、自分の端末の中だけで読み上げるのは、私的使用（著作権法30条）の範囲と見ています［推測］。音声のファイルに書き出したり、人に送ったりできる形にすると、公衆送信のおそれがあります。音声は書き出せない形にします。審査でも、アプリが本の中身を配らない限り、問題になりにくいと見ています［推測］。

## 4. 対応機種の割合
- 対応機種は、iPhone 16 以降、iPhone 15 Pro、15 Pro Max、iPhone Air です。日本語に対応しています。モデルに最大8GB（17 Pro と Air は最大14GB）の容量を使います（https://support.apple.com/ja-jp/121115 、2026-09-15 公開、2026-10-18 に開いた）。
- 日本の割合：MMD研究所「2026年8月スマートフォンOSシェア調査」（2026-09-17 公開、4万人、https://mmdlabo.jp/investigation/detail_2567.html 、2026-10-18）によると、iPhone をメインに使う人（n=15,877）のうち、「iPhone 16」の系列が21.8%、「iPhone 17」の系列が17.3%、「iPhone 15」の系列が12.4%です。Pro は分けて集計されていません。
  - 計算すると、使えるのは iPhone 利用者の**39.1%〜51.5%**です。15 の系列のうち Pro が何割かが分からないので、幅があります。iOS の割合は45.6%なので、スマホを持つ人全体では約18〜23%です。
  - 世界では、対応 iPhone の出荷が累計4.5億台を超えました（2026年第1四半期まで。https://counterpointresearch.com/jp/insights/apple-has-shipped-over-450-million-apple-intelligence-capable-iphones 、2026-06-08）。
- 対応機種でも、Apple Intelligence が切られている、言語の設定が合わない、モデルのダウンロードがまだ、といった理由で使えないことがあります。アプリには、使えない状態と理由が返ってきます。
- 使えない人への道：
  - 中心の機能（ロック画面の続きの一行、伏せて読む、奥付、次の1冊）を AI なしで成り立たせる。
  - あらすじの代わりに A2（最後の数行）か、本人の一言のメモを出す。
  - 読みがな、辞書、読み上げは全機種で出す。
  - 外のサーバーの AI に送るのは勧めません。費用がかかり、5.1.2(i) の明示の許可が要り、本の文を外に送る著作権の心配があり、「端末の中の AI」とも言えなくなります。
  - PCC も対応機種でしか使えないので、使えない人への道にはなりません。

## 5. 課金の技術
- 品の種類：自動更新の定期課金（無料体験は、初めての人向けの割引の仕組みで付ける。資格は `isEligibleForIntroOffer` で分かる）、買い切り、買い切りの試用（3.1.1：「Non-Consumable IAP item at Price Tier 0 that follows the naming convention: "XX-day Trial."」。始める前に、期間、試用が終わると使えなくなるもの、あとでかかる料金を見せる）。
- サーバーなしでの確かめ：StoreKit が Transaction、RenewalInfo、AppTransaction の署名を自動で確かめ、VerificationResult で結果を返します（https://developer.apple.com/documentation/storekit/verificationresult 、2026-10-18）。起動のときに `Transaction.currentEntitlements` を読み、`Transaction.updates` で変化を受け取れば、サーバーは要りません。App Store Server API は「自分のサーバーから呼ぶ」もので（https://developer.apple.com/documentation/appstoreserverapi 、2026-10-18）、要るのは、他の場所でも権利を確かめたいとき、Web で売るとき、サーバーで集計したいときです［推測］。サーバーの費用は0円です。
- Family Sharing：定期課金と買い切りを、最大5人の家族と分け合えます。開発者が App Store Connect で入れます。家族は自分の取引を持ちます（https://developer.apple.com/documentation/storekit/supporting-family-sharing-in-your-app 、2026-10-18）。家族から外れたときも `revocationDate` に日付が入ります。一度入れたら切れないかは**未検証**です。
- 返金：返金や取り消しのあった品は currentEntitlements に出ません（https://developer.apple.com/documentation/storekit/transaction/currententitlements 、2026-10-18）。アプリから返金を頼む画面は `beginRefundRequest(in:)` と `beginRefundRequest(for:in:)` で出せます。iPhoneOS27.0 の SDK の StoreKit に宣言があることを確かめました。文書の JSON は取れませんでした。
- 審査の決まり：3.1.2(a)「the subscription period must last at least seven days and be available across all of the user's devices」、続けて価値を出すこと。3.1.2(c)：申し込みの前に、値段で何が得られるかを示し、Schedule 2 の項目を見せること。SubscriptionStoreView（iOS 17 から）を使うと、名前、説明、値段が自動で出ます。
- プライバシー：「Data that is processed only on device is not "collected"」「You are not responsible for disclosing data collected by Apple」（https://developer.apple.com/app-store/app-privacy-details/ 、2026-10-18）。購入の情報を端末の外に送らなければ、「購入履歴」の開示は要りません。計測のイベントに購入を入れて送るなら、開示が要ります。
- 日本の手数料（https://developer.apple.com/support/app-distribution-in-japan/ 、2026-10-18）：Small Business Program の加入者と、定期課金の2年目以降は10%、それ以外は21%です。Apple の決済を使うと5%が足され、どちらも客の払う額に対してかかります。iOS 26.2 以降が対象です。Small Business Program は申し込みが要ります（PCC を使うときの条件でもあります）。
- 個人の名義では、販売者として本名が表示される見込みです［推測］。特定商取引法の表記が要るかは**未検証**です。

## 6. 国立国会図書館サーチの利用申請と、代わりの書誌の出どころ
- 国立国会図書館サーチ（https://ndlsearch.ndl.go.jp/help/api 、2026-10-18）：広告を含め、収益を得るなら「営利目的にあたるため、利用申請が必要です」。申請のフォームは https://form2.ndl.go.jp/form/pub/ndl07/api です。**費用と期間はページに書かれていません**。データの提供元がどんな目的でも使ってよいとしている場合は、申請は要りません（提供元ごとの一覧 /help/api/provider は開いていない。**未検証**）。表示の決まりとして「NDLサーチのAPIを用いていることを明記してください」とあります。
- openBD（https://openbd.jp/ 、2026-10-18）：「本の販促・紹介目的に限り使用できます。個人・団体・企業を問いません」。データを勝手に変えない、削除を求められたら従う、キャッシュは変更をできるだけ早く反映する、という決まりがあります。有料のアプリについての記述はありません。本を紹介する表示なら目的に合うと見ています［推測］。openBD への確認は**未検証**です。
- Google Books（https://developers.google.com/books/terms 、最終更新 2012-04-25、2026-10-18 に開いた）：「You may not charge users any fee for the use of your application」。別の契約か、書面の許可があれば別です。定期課金や有料のダウンロードはこれに当たります。アプリ内課金も当たると見ています［推測］。

## 7. 実機の確かめの試作に、ローカル AI の確かめを足す案
- 試作の中身（リポジトリの外で作る。前に計画した伏せる向きの確かめ ①〜③ と同じアプリにまとめる）：
  1. カメラ → Vision（日本語、縦書き）→ 読み取った文と、かかった時間（しばらく使わなかったあとの1回目と、続けての2回目）
  2. 「最後の数行」（A2）と、Foundation Models のあらすじ（plain と、上限付きの guided）を並べて出す。Takuma が出力ごとに「合っている／違う事実がある」を押す
  3. 語をタップすると読みがな（CFStringTokenizer）と辞書の画面
  4. ルビを除いた文の読み上げ（入っている中でいちばん品質の高い声）
  5. Foundation Models と PCC が使えるかの表示
  - 記録は端末の中の JSON に残し、ファイルのアプリで渡します。ネットには送りません。PCC は entitlement がないと試せないので、試作には入れません。
- Takuma の手間［推測］：約30分。Xcode からケーブルで入れる（iPhone で開発者モードを入れる）。自分の本3冊（1冊はルビのある本）から2ページずつ撮り、写真ごとにボタンを4つ押し、あらすじ6件に印を付け、1ページを聞きます。伏せる向きの確かめ①〜③（10分）が別に要ります。
- Takuma の iPhone の機種はリポジトリに書かれていません（docs/ を grep して見つからず）。Apple Intelligence のない機種のときの代わり：
  1. AI 以外（読み取り、読みがな、辞書、読み上げ、伏せる向き）は、iOS 26 以上の iPhone ならそのまま試せます。
  2. あらすじの品質は Mac で測れます（今回の数字も Mac）。同じモデルかどうかは［推測］です。
  3. iPhone での時間は、確かめの計画にある身近な5人から対応機種を借りて測る。いちばん古い対応機種は iPhone 15 Pro で、「速さは古い機種で測る」という決定にも合います。
  4. 対応機種を買うかは Takuma が決めることです。

## 8. 審査の論点
- AI の開示：審査ガイドラインに、端末の中の AI で作った文を開示せよという節はありません（https://developer.apple.com/app-store/review/guidelines/ 、2026-10-18。読めたのは 5.2.5 まで）。
  - 5.1.2(i)「You must clearly disclose where personal data will be shared with third parties, including with third-party AI, and obtain explicit permission before doing so.」は、外への送信がなければ当たりません。PCC がこの「third-party AI」に入るかは**未検証**です。
  - 1.2 に「AI content creation apps」とありますが、作った文を人に公開しないなら、投稿の仕組みに求められる決まりは当たらないと見ています［推測］。
- Foundation Models の使い方の決まり（https://developer.apple.com/apple-intelligence/acceptable-use-requirements-for-the-foundation-models-framework/ 、2026-10-18）：他人の知的財産権の侵害、安全の止めの迂回、AI 製を示す透かしの除去が禁止です。AI の出力に印を付ける義務はありません。
- 作った文の扱い［推奨］：「AI がページの文から作った要約です。違うことがあります」と書く。読み終えのカードなど人に見せるものには載せない（要約は翻案にあたるおそれがあり、人に送れば公衆送信のおそれ［推測］）。端末の中に置き、消せるようにする。
- 4.3(b)：「Don't submit apps that are indistinguishable from what's already widely available.」。読書の記録や AI の要約のアプリは多いので、AI の要約だけでは違いになりません［推測］。審査メモと最初の画面で、このアプリならではの形（夜の入口、本の出口）を示します。審査が Apple Intelligence のない機種で行われることもあるので、AI が使えないときも機能が欠けて見えない作りにします（2.1 の完成度での却下を避けるため［推測］）。
- PCC の条件（https://developer.apple.com/private-cloud-compute/ 、2026-10-18）：
  - Small Business Program に入っていること、初回のダウンロードが200万未満であること、PCC の entitlement が割り当てられていること。
  - 今はクラウドの API の費用はかかりませんが、脚注に「Expanded access to such features will be available for a fee in the future」とあります。
  - 200万を超えたら、6か月以内に別の手段へ移る必要があります。
  - 1日の上限は利用者ごとで、数字は書かれていません。上限に近づいたら iCloud+ への案内を出す仕組みが用意されています（https://developer.apple.com/documentation/foundationmodels/adding-server-side-intelligence-with-private-cloud-compute 、2026-10-18 に JSON で読んだ）。

## 変更したファイル
- リポジトリのファイルは変えていません。
- 作業用のファイル（どれもリポジトリの外）：
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-tech/notes.md（新規。分かったことを順に書き足した）
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-tech/spike2.swift（前の体の spike.swift を写し、cap と pcc の試しを足した）
  - 同じフォルダの spike2（ビルドしたもの）、word.log、cap.log、pcc.log、tts.log
  - 同じフォルダの dl/ と dl2/（Apple の文書の JSON）
- 前の体の spike.swift、spike、fm.log は変えていません。

## 実行したコマンドと結果
spike の手数は10回の枠のうち5回（ビルド1回、実行4回）です。
- `cat .../ai-tech/fm.log`：前の体の結果を読み、手で判定し直した（1 の表）
- FoundationModels の宣言（MacOSX27.0.sdk の swiftinterface）を grep：
  - `GenerationOptions(samplingMode:temperature:maximumResponseTokens:)` がある（`sampling:` は deprecated）
  - `PrivateCloudComputeLanguageModel` は `@available(iOS 27.0, macOS 27.0, ...)`。使える状態、上限の使い方、上限に達したときのエラー（quotaLimitReached）がある
- `xcrun swiftc -O -parse-as-library -o .../spike2 .../spike2.swift`（Swift 6.4）：ビルドできた。警告は spike の中の NSLock の使い方だけ
- `spike2 word`（11分48秒）：読みがなは CFStringTokenizer が20/20、Foundation Models が1/20（10件は枠を超えて失敗）、Mac の辞書は19/20 で定義あり。NaturalLanguage の日本語の埋め込みは語も文もなし
- `spike2 cap`（24.7秒）：上限120トークンで、止まらない出力は2.4〜5.4秒で切れる。6件中5件は文字列が閉じず、余計な文が続く。端末のモデルの能力は guidedGeneration、toolCalling、vision
- `spike2 pcc`（0.49秒）：使える状態は available、上限には遠い、枠は32768。16回すべて24〜39msで `LanguageModelError -1`（中身は `ModelManagerError Code=1046`）
- `spike2 tts`（8.3秒）：日本語の声は9つで、どれも標準の品質。492字/分（0.6 で774字/分）。sub alias は効かない。ルビの混じった文は1.51秒、きれいな文は0.93秒
- `curl` で Apple の文書の JSON（tutorials/data）を取った：PCC の記事と型、VerificationResult、currentEntitlements、Family Sharing、revocationDate、SubscriptionStoreView、App Store Server API、Personal Voice の許可、UIReferenceLibraryViewController。beginRefundRequest と SSML の文書の JSON は取れなかった
- iPhoneOS27.0.sdk の StoreKit の宣言を grep：`beginRefundRequest` 2件、`familyShared`、`revocationDate`、`currentEntitlements`、`updates`、`isEligibleForIntroOffer` がある
- `grep -rn iPhone docs/approvals docs/progress.md`：Takuma の iPhone の機種は書かれていない
- 開いた URL（どれも 2026-10-18）：上の本文の各節に書いたもの。二次の情報として、PCC の条件を探す検索で wwdcnotes と daringfireball の記事、日本の割合を探す途中で selectra.jp の記事が出たが、根拠には公式のページと MMD研究所の元のページだけを使った

## 未検証
- iPhone（iOS 26 と 27）での Foundation Models の時間と品質。今回の数字はどれも Mac です。
- 日本語の guided generation で出力が止まらない不具合が、iPhone でも起きるか、OS の更新で直るか。
- PCC の品質と時間。entitlement がないため16回すべて失敗し、`ModelManagerError 1046` の意味は確かめていません（entitlement がないためと見る［推測］）。
- 端末のモデルに画像（ページの写真）を直接渡す形（能力の一覧には vision がある）。
- CFStringTokenizer の読みがなが、文の中の語でも、iOS でも正しいか（語だけを Mac で試した）。
- iPhone に高品質の日本語の声があるか、その速さ。ルビの読みがなを消す規則が効くか。iPhone に初めから日本語の辞書が入っているか。
- Family Sharing を一度入れたら切れないか。個人の名義での販売者の表示。特定商取引法の表記が要るか。
- 国立国会図書館サーチの申請の費用と期間（ページに書かれていない）。提供元ごとの条件の一覧。
- openBD の「販促・紹介目的」に有料のアプリが入るか。
- 5.1.2(i) の「third-party AI」に PCC が入るか。年齢区分の質問に AI についての項目があるか。審査が Apple Intelligence のない機種で行われるか。
- 審査ガイドラインの 5.2.5 より後ろ（ページの最後の約1.4万字は読んでいない）。
- 著作権の解釈（30条の私的使用、翻案、口述）は、法律の専門家に確かめていません［推測］。
- 大きな判断なので、この報告にはレビュアーの反論をもらってください（特に「AI を v1 に入れない」「課金はどの機種でも動く価値に付ける」の2点）。

## 記録（指揮役が保存するときに書き足す）
- 種類：収益とローカル AI を検討するための調べもの（tech-lead）。PASS / FAIL なし
- 対象：Takuma の返事（2026-10-18。docs/approvals/001-reading-session-G0-Q8.md の最後の節）。BASE=53394fd
- 日付：2026-10-18
