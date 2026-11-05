# 001-reading-session Apple Intelligence の使い道：2体の調べもののまとめと推す案（指揮役）

- 日付：2026-10-18。Takuma の頼み「apple インテリジェンスとか上手いこと使えないのかな」への答え。
- 材料：2体の調べもの（判定ではない）
  - docs/reviews/001-reading-session-apple-intelligence-tech-lead.md（作れるか。ふりかえりの spike）
  - docs/reviews/001-reading-session-apple-intelligence-designer.md（体験のどこに入れるか。ADA）
- 前提：AI に文を作らせる機能は v1 に入れない（裁定 12）。抜き出しは確かめ 1d で決める。

## 結論
- **推す：App Intents（Apple Intelligence の土台）。2体とも1番に推した。**
  - 「読み始める」を、ロック画面の Control、Action ボタン、Siri から使える形。アプリを開かずに、ボタンが1つの Live Activity で読書が始まる（LiveActivityIntent）。
  - ショートカットで「どこまで読んだ？」に、アプリの記録と文の型で答える。
  - 全機種で動き、作り話は出ない。負担は S〜M（Live Activity があれば S）。
  - 毎晩の入口に直接効き、アプリを前に出す時間がほぼ0になる。ADA の Interaction と Inclusivity の両方に効く型。
  - 日本語の Siri AI が来たら、自由な言い方で使える土台になる（2026-10-18 の時点で、Siri AI は英語だけ）。
  - v1.0 の候補として、回す順の中に入れる（速さを測ってから決める）。「読み始める」は Live Activity と組なので、Live Activity を回すときは一緒に回す。
- **v1.1 の候補：Visual Intelligence。**
  - 本を写すと、本棚の本なら「61ページから」、ない本なら「積読に加える」を返す形。10秒で伝わる。
  - アプリに渡るのは、写した画像と英語の一般的なラベルだけ。本の照合（バーコード、表紙の書名）はアプリが Vision で行う。負担は M。
  - 対応機種だけで動き、日本語の環境でアプリの結果が出るかは未検証。毎晩の入口には効きが小さい。
- **入れない**
  - AI のふりかえり：spike で、使える文は自由文 0/10、差し込みの形も 0/10。AI なしの文の型で書く（全機種、S。読み終えのカードと同じ版）。
  - Image Playground：絵柄が「静か」と白黒の決まりに合わない（designer）。v1.1 でも急がない。
  - PCC：資格と entitlement が要る。通信が要り、使える量に上限があり、将来は有料。あらすじの品質が上がる証拠もない。v1.2 以降。
- **課金**：AI を使う部分は無料の側に置く（裁定 17）。

## いちばん強い反論
- App Intents は Apple Intelligence そのものではなく、その土台。ToRead も「ショートカットや背面タップで読書を開始・終了」を持つ（PRD の E-12）。
- 「Apple Intelligence を上手いこと使う」に、目に見える形では応えない。見せ場になる Visual Intelligence と Siri AI は、日本語と機種の条件がそろうまで待つことになる。
- Action ボタンとロック画面の Control は枠が少なく、設定する人は少ないかもしれない。

## Takuma に決めてほしいこと
1. **App Intents を v1.0 の候補にするか**
   - 推奨：する（回す順の中。速さを測ってから決める）。
   - いちばん強い反論：AC が増え、要る速さが上がる。分野の当たり前で、差になりにくい。
   - 元に戻せるか：戻せる。
2. **Visual Intelligence をどうするか**
   - 推奨：v1.1 の候補にする。日本語の環境と本の見分けを、実機で確かめてから。
   - いちばん強い反論：Apple Intelligence らしさがいちばん見える所が、v1.0 にない。
   - 元に戻せるか：戻せる。

## 決まったら
- pdm が PRD に入れる。App Intents を回す順に入れ、AC を足す。Visual Intelligence を v1.1 の候補に書く。ふりかえりの文の型を書く。AI の部分を無料にする決まりを書く。
- 足した AC は、verifier が狭く判定する（全体の3回目の判定にはしない）。

## 記録
- 種類：指揮役のまとめ（判定ではない）
- 日付：2026-10-18
