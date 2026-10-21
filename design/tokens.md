# デザイントークン（アプリ全体）

- 書いた役：designer　日付：2026-10-21　最初に使う機能：001-reading-session（design/001-reading-session.md）
- 改訂：2026-10-21 G1 r1 の判定（docs/reviews/001-reading-session-G1-design-reviewer-r1.md の指摘1〜3）を受けて、アクセントを塗り用（color.accent.fill）と文字用（color.accent.text）に分け、塗り用のダークの値を替えた。17pt 以下の文字は color.text.primary だけにし、color.text.secondary は一時停止中の経過時間（.largeTitle）だけにした。placeholder を使わないことにした。5 のコントラストの表を、システムの色とシステムが描く部品の組まで広げた
- 改訂（G1 の契約の後）：2026-10-21 tech-lead r2 の提案2（docs/reviews/001-reading-session-G1-tech-lead-r2.md）を受けて、1 の代わりの値に、コントラストを上げる設定のダークでシステムが白いラベルを描いた場合の1組を足し、5 の A1 の注に数字を足した
- 色、文字、余白は、この表の名前だけを使う。画面の仕様と実装に、色の値や文字の大きさを直接書かない。
- 色はシステムの色を先に使う。独自の色は「しおりの色」の2つ（塗り用と文字用）と、その塗りの上に載せる文字の色の、あわせて3つだけ（HIG Color「Make sure all your app's colors work well in light, dark, and increased contrast contexts」https://developer.apple.com/design/human-interface-guidelines/color ）。
- 根拠の R 番号は design/001-reading-session-research.md の 8、B 番号は .claude/skills/craft-designer/SKILL.md の 1。

## 1. 色
名前は意味で付ける。独自の色は Asset Catalog の Color Set に、Any、Dark、High Contrast（Any と Dark）の4つの値を入れる。

| トークン | 意味と使う所 | ライト | ダーク | コントラストを上げる（ライト / ダーク） | 根拠 |
|---|---|---|---|---|---|
| color.background.screen | 読書中の画面の背景 | systemBackground | systemBackground | システムが切り替える | R-9「Prefer the system background colors.」 |
| color.background.grouped | ホーム、本の詳細、本の追加、読書を終えるの背景（List と Form の既定）。シート（本の追加、読書を終える）の中は、ダークでシステムが elevated の値に替える | systemGroupedBackground | systemGroupedBackground | システムが切り替える | R-9。HIG Dark Mode「the background color automatically changes from base to elevated when an interface is in the foreground, such as a popover or modal sheet」 |
| color.background.row | リストとフォームの行の背景（既定）。シートの中はダークで elevated の値 | secondarySystemGroupedBackground | secondarySystemGroupedBackground | システムが切り替える | R-9 |
| color.text.primary | 画面に出る文字のすべて（17pt 以下の文字はこれだけを使う）：本文、題名、経過時間（読書中）、値、ヒント、誤りの文、日付、「72ページから」、状態の文字（「読書中」「一時停止中」）、セクションの見出しと footer、LabeledContent の値、ContentUnavailableView の文、ProgressView のラベル、エラーの区画の文。List、Form、LabeledContent、ContentUnavailableView、ProgressView がシステムの既定で secondaryLabel にする所も、これに替える | label | label | システムが切り替える | R-11（17pt までは 4.5:1）、R-12、B-4（階層は色でなく大きさと太さで作る） |
| color.text.secondary | 一時停止中の経過時間（type.timer、.largeTitle の 34pt。18pt 以上の文字で、基準は 3:1）だけ。17pt 以下の文字には使わない | secondaryLabel | secondaryLabel | システムが切り替える | R-11。値と比は 5 の B2、B3 |
| color.text.placeholder | 001 では使わない。入力欄に placeholder を置かず、必須と任意は見出しと footer の文で伝える | placeholderText | placeholderText | システムが切り替える | R-11。値と比は 5 の B4（どの組も 4.5:1 に届かない） |
| color.separator | 行の区切り（List の既定） | separator | separator | システムが切り替える | B-2（独自の線を引かない） |
| color.accent.fill（しおりの色・塗り / Bookmark Fill） | 目立つボタン（.borderedProminent）の塗りだけ：S1、S3 の下端の主操作と、そこに出る error.retry、S1 の空の状態の「本を追加」と読み込みの失敗の「もう一度読み込む」、S4 の「終える」とその場所に出る error.retry「もう一度終える」、S2 と S5 の確定のボタン（「追加」「保存」）。文字には使わない | #7A4427 | #9F5833 | #5E3219 / #E3B994 | R-10「choosing your brand color as the app accent color can be an effective way」「In dark environments, colors appear bright and saturated.」、R-9「strive for a contrast ratio of 7:1」、R-11、B-5。HIG Color「the system applies the app accent color to the background in prominent buttons — such as the Done button」 |
| color.accent.text（しおりの色・文字 / Bookmark） | アプリの AccentColor（システムの tint）。システムが押せる文字と記号に付ける所だけ：ナビゲーションバーの文字のボタン（戻る、「キャンセル」、「編集」、「＋」。iOS の版によってはシステムが label の色で描く）、alert のボタン（S6、S7）、入力欄のカーソル。押せない文字（状態、見出し、文）には使わない | #7A4427 | #CF9D78 | #5E3219 / #E3B994 | R-10、R-9、R-11、B-5。HIG Buttons「a primary button uses an app's accent color」 |
| color.text.onAccent | color.accent.fill の塗りの上のラベル。アプリが .foregroundStyle で決め、システムの既定に任せない | #FFFFFF | #FFFFFF | #FFFFFF / #000000 | R-9、R-11。HIG Color の Liquid Glass color（既定のコントラストではラベルが白、コントラストを上げると黒の例） |
| color.status.error | 入力の誤りと保存の失敗の印（記号 exclamationmark.triangle）だけに使う。文字には使わない | systemRed（HIG の値 255,56,60） | systemRed（255,66,69） | systemRed（233,21,45 / 255,97,101） | R-10「Avoid relying solely on color」、R-11 |
| color.fill.secondaryButton | 主操作でないボタン（.bordered、tint は color.text.primary）の塗りと文字：S4 の一時停止と再開、その場所に出る error.retry（「もう一度一時停止」「もう一度再開」）、S2 と S5 のエラーの区画の error.retry、S5 のキーボードの上の「保存」、S3 の「読書に戻る」（別の本が読書中のとき） | システムが tint から作る塗り | 同じ | システムが切り替える | HIG Buttons「Use style — not size — to visually distinguish the preferred choice」、B-5 |

実装での当て方（tech-lead と ios-engineer へ）：
- Asset Catalog の AccentColor（アプリ全体の tint）には color.accent.text の4つの値を入れる。システムが自分で tint を付ける所（戻る、alert のボタン、カーソルなど）は、これで文字用の値になる。
- 目立つボタン（.borderedProminent）には、1つずつ .tint(color.accent.fill) と、ラベルに .foregroundStyle(color.text.onAccent) を付ける。付け忘れると、塗りが文字用の値（ダーク #CF9D78）になり、白い文字で 2.40:1 になる（5 の A1 の注）。
- .bordered のボタンには .tint(color.text.primary) を付ける。

しおりの色を栗色にした理由：
- 内容はほぼ無彩色（題名、数字、一覧）なので、アクセント1色でアプリを見分けられる（R-10）。iOS の既定の青のままにしない（調べた AI らしい既定の見た目を避ける。craft-designer の 4）。
- 赤（消す、エラー）、緑（成功の意味に読まれやすい）、青（既定の色）と重ならない色にし、1つの色が1つの意味になるようにする（B-5）。アクセントの意味は「押せる」の1つだけにする（状態の文字には使わない）。
- 寝る前の暗い部屋で使う（R-23）。暗い所では色が明るく鮮やかに見える（R-10）ので、彩度を抑えた色にした。紙のしおりの革や布の色は連想だけで、絵や質感は描かない（research 6 の差1、B-2）。

塗り用と文字用を分けた理由（G1 r1 の指摘1）：
- 目立つボタンは、システムが塗りにアクセントを使い、既定のコントラストではラベルを白で描く（HIG Color の Liquid Glass color の画像の説明）。前の版のダークの値 #C99671 は白い文字で 2.60:1 だった。
- 1つの色で「白い文字を載せる塗り」と「黒い背景の上の文字」の両方を 4.5:1 にできる幅は、相対輝度 0.175〜0.183 しかない（design-reviewer r1 の計算）。そこで塗り用と文字用を分けた。
- 塗り用のダーク #9F5833 は相対輝度 0.146（0.183 以下）。白い文字で 5.36:1、黒い背景（帯と読書中の画面）に対して形が 3.92:1、シートの背景 #1C1C1E に対して 3.17:1。白い文字の 7:1（R-9 の目標）を取ると形が黒い背景に対して 3:1 を切る（相対輝度 0.10 で両方がちょうど 7:1 と 3:1）ので、文字の 4.5:1 と形の 3:1 を両方満たす側を選んだ。
- 文字用のダーク #CF9D78 は、前の版の #C99671 より少し明るくした。alert や素材の背景がシステムの灰色4（#3A3A3C）まで明るくなっても 4.73:1 を保つため（#C99671 では 4.37:1）。
- コントラストを上げる設定：ライトは塗りを暗く（#5E3219）して白い文字 10.79:1、ダークは塗りを明るく（#E3B994）して黒い文字 11.63:1。どちらも形と背景の差も既定より大きくなる。ダークで黒い文字にしたのは、HIG Color の画像の説明（コントラストを上げると Done のラベルが黒）と同じ向きにするため。
- 代わりの値（G2 の CI で決める）：ツールバーの確定のボタンで、システムがアプリのラベルの色を使わず、コントラストを上げる設定のライトで黒いラベルを描いたときだけ、コントラストを上げる（ライト）の値を color.accent.fill #AD6137、color.text.onAccent #000000 に替える（黒 4.54:1、白 4.62:1 のどちらでも 4.5:1。形は #EBEBF0 に対して 3.89:1）。Asset Catalog の値を替えるだけで、コードは変えない。
- 代わりの値のダーク（G2 の CI で決める。tech-lead r2 の提案2）：ツールバーの確定のボタンで、システムがアプリのラベルの色を使わず、コントラストを上げる設定のダークで白いラベルを描いたとき（今の値では #FFFFFF / #E3B994 = 1.81:1）だけ、コントラストを上げる（ダーク）の値を color.accent.fill #AD6137、color.text.onAccent #FFFFFF に替える。式は 5 の冒頭のとおり（L = 0.2126R + 0.7152G + 0.0722B、比 = (明るい方の L + 0.05) / (暗い方の L + 0.05)）。
  - 満たす幅：白い文字で 4.5:1 以上は L ≤ 1.05 / 4.5 − 0.05 = 0.183。黒い背景（#000000、L = 0）に対して形が 3:1 以上は L ≥ 3 × 0.05 − 0.05 = 0.100。コントラストを上げる設定のシートの背景（#242426、L = 0.0178）に対して形が 3:1 以上は L ≥ 3 × 0.0678 − 0.05 = 0.153。システムが黒を描いても 4.5:1 を保つ（L ≥ 4.5 × 0.05 − 0.05 = 0.175）ため、0.175〜0.183 から選んだ。
  - 選んだ値：#AD6137（L = 0.1771。ライトの代わりの値と同じ色）。白い文字 (1 + 0.05) / (0.1771 + 0.05) = 4.62:1、黒い文字 (0.1771 + 0.05) / (0 + 0.05) = 4.54:1、形 / #000000（S1、S3 の帯と S4）= 4.54:1、形 / #242426（シートのバー）= (0.1771 + 0.05) / (0.0178 + 0.05) = 3.35:1。基準（文字 4.5:1、形 3:1）をすべて満たす。7:1（R-9 の目標）は形の 3:1 と両立しない（1 の「塗り用と文字用を分けた理由」と同じ）。
  - 替えたときの見え方：コントラストを上げる設定のダークだけ、塗りが既定のダーク（#9F5833、L = 0.146）より少し明るい栗色になり、ラベルは白のまま。Asset Catalog の High Contrast（Dark）の値は1か所なので、S1、S3、S4 の塗りのボタンも同じ値になる（どれも白い文字で 4.62:1、黒い背景に対して形 4.54:1）。ライトの代わりの値とは別々に替えてよい。コードは変えない。

使わない色：上の表にない色、グラデーション、影、半透明の独自の色。

## 2. 文字
書体はシステムの1つ（日本語はシステムの日本語書体、英語は SF Pro）。大きさは Dynamic Type の text style だけで指定し、ポイント数を書かない。Ultralight、Thin、Light は使わない（R-12）。1画面で使う段は4つまで（B-4。画面ごとの段は仕様の 8）。文字の色は、一時停止中の経過時間を除いて、すべて color.text.primary（1 の表）。階層は大きさと太さで作り、灰色の文字で作らない（B-4）。

| トークン | text style | 太さ | 等幅の数字 | 使う所 |
|---|---|---|---|---|
| type.timer | .largeTitle | 既定（Regular） | 使う（monospacedDigit） | 読書中の経過時間 reading.elapsed |
| type.navTitle | .largeTitle（システムの大きい見出し） | システムの既定 | 使わない | ホームの見出し「読書」 |
| type.bookHeading | .title2 | 強調（Bold。HIG の Emphasized weight） | 使わない | 本の詳細の先頭の題名 book.title |
| type.readingTitle | .title3 | 既定（Regular） | 使わない | 読書中の画面の題名 reading.title |
| type.primaryTitle | .headline | 既定（Semibold） | 使わない | ホームの主操作の1行目（題名）、エラーの区画の題（error.saveFailed） |
| type.body | .body | 既定 | 数字の値には使う | 行の文字、入力欄、値（60分、72、24%）、ボタン（システムの既定） |
| type.secondary | .subheadline | 既定 | 使わない | 主操作の2行目（72ページから読む）、「72ページから」、状態の文字、記録の日付。名前は「2番目の大きさ」の意味で、色は color.text.primary |
| type.note | .footnote | 既定 | 使わない | セクションの見出し（21冊、記録 3件、題名（必須））、入力の下のヒントと誤りの文、エラーの区画の文。色は color.text.primary |

## 3. 余白
4pt を元にした6段だけを使う（B-3）。List、Form、toolbar、sheet の中の余白はシステムの既定に任せ、ここで上書きしない。

| トークン | 値 | 使う所 |
|---|---|---|
| space.xxs | 4pt | 主操作の1行目と2行目の間、記号と文字の間 |
| space.xs | 8pt | 記録の行の中の分とページの間、下端の主操作の帯の上の余白、帯の中のエラーの文とボタンの間 |
| space.s | 12pt | 読書中の画面の、題名と「72ページから」の間、経過と状態の間 |
| space.m | 16pt | 画面の左右の余白（下端の主操作、読書中の画面のボタン）、2つのボタンの間、読書中の画面の状態の文字とエラーの区画の間 |
| space.l | 24pt | 読書中の画面の、題名のまとまりと経過のまとまりの間 |
| space.xl | 32pt | 読書中の画面の、経過のまとまりとボタンの間（最小値。残りは Spacer で広がる） |

## 4. 形と動きと素材
- 角丸：ボタン、行、シートはシステムの既定のまま。独自の角丸を作らない。
- 影、グラデーション、紙の質感、絵：使わない（B-2、research 7 で案B を選ばなかった理由）。
- 素材：Liquid Glass はシステムがナビゲーションバー、ツールバー（キーボードの上のツールバーを含む）、シートに付ける分だけ。内容の層（背景、行、下端の主操作の帯）には使わず、glassEffect を独自に付けない（R-13「Don't use Liquid Glass in the content layer.」）。
- 動き：画面の切り替えはシステムの push と sheet の動きだけ。経過時間の数字は、変わるときに動き（contentTransition の数字の動きなど）を付けない。独自の動きがないので、動きを減らす設定のときに変えるものはない（システムの切り替えはシステムが減らす）。

## 5. コントラスト
基準：17pt 以下の文字は 4.5:1 以上、18pt 以上か太字は 3:1 以上、記号と操作部品の形は 3:1 以上（R-11、PRD 12。ダークも同じ基準）。独自の色は 7:1 を目指す（R-9）。無効のボタンは基準の対象外（WCAG 1.4.3 の例外「part of an inactive user interface component」）。

計算の式（WCAG 2。design-reviewer の手引きのコマンドと同じ）：
- 各色の 0〜255 の値 v を c = v/255 にし、c ≤ 0.04045 なら c/12.92、それ以外は ((c+0.055)/1.055)^2.4 にする。相対輝度 L = 0.2126R + 0.7152G + 0.0722B。
- 比 = (明るい方の L + 0.05) / (暗い方の L + 0.05)。
- 半透明のシステム色（secondaryLabel、placeholderText）は、背景の上に重ねた色を先に作る：各チャンネルを round(α × 前景 + (1 − α) × 背景)、α = アルファ / 255。その色と背景で比を出す。

背景の値（どれも「抜粋」か「仮定」の印を付けた。HIG に背景色の値の表はない）：
- ライト：systemBackground と secondarySystemGroupedBackground は #FFFFFF。systemGroupedBackground は #F2F2F7（HIG Color の systemGray6 と同じ値と仮定）。コントラストを上げる設定では #EBEBF0（同じく仮定）。
- ダーク（push の画面＝base）：systemBackground と systemGroupedBackground は #000000、secondarySystemGroupedBackground は #1C1C1E。コントラストを上げる設定では行が #242426。
- ダーク（シートと alert＝elevated。HIG Dark Mode の base と elevated）：systemGroupedBackground は #1C1C1E、secondarySystemGroupedBackground は #2C2C2E。コントラストを上げる設定では #242426 と #363638。値は検索の抜粋（Flutter の CupertinoColors.secondarySystemGroupedBackground は UIKit の色と同じと書かれ、darkElevatedColor が 44,44,46、darkHighContrastElevatedColor が 54,54,56。https://api.flutter.dev/flutter/cupertino/CupertinoColors/secondarySystemGroupedBackground-constant.html 。ページは開けなかった）。#1C1C1E と #242426 は systemGray6 と同じ値と仮定。
- alert とナビゲーションバーの背景は素材で、値の表がない。下の A3 の「alert の見積もり」は、ライトをシステムの灰色5（#E5E5EA、コントラストを上げると #D8D8DC）、ダークをシステムの灰色4（#3A3A3C、コントラストを上げると #444446）まで明るくなったと見て、控えめに計算した（値は HIG Color の system gray の表）。

システムの文字の色の値（抜粋。検索で見た Flutter の CupertinoColors の定義で、UIKit の色と同じと書かれている。ページは開けなかった。design-reviewer r1 の証拠の値と同じ）：
- label：ライト #000000、ダーク #FFFFFF（コントラストを上げても同じ）。https://api.flutter.dev/flutter/cupertino/CupertinoColors/label-constant.html
- secondaryLabel：ライト rgba(60,60,67, 153/255)、ダーク rgba(235,235,245, 153/255)、コントラストを上げる設定はアルファ 173/255。https://api.flutter.dev/flutter/cupertino/CupertinoColors/secondaryLabel-constant.html
- placeholderText：ライト rgba(60,60,67, 76/255)、ダーク rgba(235,235,245, 76/255)、コントラストを上げる設定はアルファ 96/255。https://api.flutter.dev/flutter/cupertino/CupertinoColors/placeholderText-constant.html
- systemRed：HIG Color の System colors の表（開いて確認）。

### A. 独自の色の組
| 組（前景 / 背景）と使う所 | ライト | ダーク | コントラストを上げる（ライト / ダーク） | 基準 | 結果 |
|---|---|---|---|---|---|
| A1 color.text.onAccent / color.accent.fill：S1、S3 の主操作の文字（2行目は .subheadline の Regular）、S1、S3 の error.retry、S1 の「本を追加」「もう一度読み込む」、S4 の「終える」と「もう一度終える」、S2 と S5 の確定のボタン「追加」「保存」 | #FFFFFF / #7A4427 = 7.83:1 | #FFFFFF / #9F5833 = 5.36:1 | #FFFFFF / #5E3219 = 10.79:1、#000000 / #E3B994 = 11.63:1 | 4.5:1 | 満たす（ダークは 7:1 の目標に届かない。理由は 1 の「塗り用と文字用を分けた理由」） |
| A1 の注：システムが既定でラベルを白にし、アプリの色を使わなかった場合 | #FFFFFF / #7A4427 = 7.83:1 | #FFFFFF / #9F5833 = 5.36:1 | 白なら 10.79:1 / 1.81:1。黒なら 1.95:1 / 11.63:1 | 4.5:1 | 既定のライトとダークは満たす。コントラストを上げる設定はアプリの色が使われることを G2 の CI のスクリーンショットで確かめ、ライトで黒が描かれたら 1 の代わりの値（#000000 / #AD6137 = 4.54:1）に替える。ダークで白が描かれたら（今の値では #FFFFFF / #E3B994 = 1.81:1）、1 の代わりの値のダーク（#FFFFFF / #AD6137 = 4.62:1。形は #AD6137 / #000000 = 4.54:1、#AD6137 / #242426 = 3.35:1。#AD6137 の L = 0.1771、#242426 の L = 0.0178 を、この節の冒頭の式に入れた値）に替える。なお .tint(color.accent.fill) を付け忘れると、塗りが AccentColor（文字用）の値になり、ダークで #FFFFFF / #CF9D78 = 2.40:1 で満たさない（1 の「実装での当て方」）。G2 の CI のダークのスクリーンショットで確かめる |
| A2 color.accent.fill の形 / 置かれる背景：S1、S3 の帯（grouped）、S4（screen）、S2 と S5 のシートのバー | #7A4427 / #F2F2F7 = 7.01:1、#7A4427 / #FFFFFF = 7.83:1 | #9F5833 / #000000 = 3.92:1、#9F5833 / #1C1C1E = 3.17:1 | #5E3219 / #EBEBF0 = 9.08:1、#5E3219 / #FFFFFF = 10.79:1 / #E3B994 / #000000 = 11.63:1、#E3B994 / #242426 = 8.58:1 | 3:1（形） | 満たす |
| A3 color.accent.text / 背景：ナビゲーションバーの文字のボタン（戻る、キャンセル、編集、＋）、S2 と S5 の確定のボタンが文字で描かれる版 | #7A4427 / #FFFFFF = 7.83:1、#7A4427 / #F2F2F7 = 7.01:1 | #CF9D78 / #000000 = 8.75:1、#CF9D78 / #1C1C1E = 7.09:1、#CF9D78 / #2C2C2E = 5.80:1 | #5E3219 / #FFFFFF = 10.79:1、#5E3219 / #EBEBF0 = 9.08:1 / #E3B994 / #000000 = 11.63:1、#E3B994 / #242426 = 8.58:1、#E3B994 / #363638 = 6.68:1 | 4.5:1 | 満たす |
| A3 の alert の見積もり：S6 の「キャンセル」「記録を消す」、S7 の「OK」 | #7A4427 / #E5E5EA = 6.23:1 | #CF9D78 / #3A3A3C = 4.73:1 | #5E3219 / #D8D8DC = 7.59:1 / #E3B994 / #444446 = 5.38:1 | 4.5:1 | 満たす（見積もり。G3 のスクリーンショットで測る） |
| A4 カーソル（color.accent.text）/ 入力欄の行 | #7A4427 / #FFFFFF = 7.83:1 | #CF9D78 / #2C2C2E = 5.80:1 | #5E3219 / #FFFFFF = 10.79:1 / #E3B994 / #363638 = 6.68:1 | 3:1（形） | 満たす |
| A5 color.status.error の記号 / color.background.grouped（S2、S5 の欄の下、S1、S3 の帯） | #FF383C / #F2F2F7 = 3.20:1 | #FF4245 / #000000 = 6.12:1、シート #FF4245 / #1C1C1E = 4.96:1 | #E9152D / #EBEBF0 = 3.83:1 / #FF6165 / #000000 = 7.15:1、シート #FF6165 / #242426 = 5.28:1 | 3:1（記号） | 満たす（ライトは余裕が小さい。意味は文でも伝える） |
| A6 color.status.error の記号 / color.background.row と screen（S2、S5 のエラーの区画、S4 のエラーの区画） | #FF383C / #FFFFFF = 3.57:1 | #FF4245 / #000000 = 6.12:1（S4）、シートの行 #FF4245 / #2C2C2E = 4.06:1 | #E9152D / #FFFFFF = 4.56:1 / #FF6165 / #000000 = 7.15:1、シートの行 #FF6165 / #363638 = 4.11:1 | 3:1（記号） | 満たす |

### B. システムの色を文字に使う組（値は上の抜粋）
| 組（前景 / 背景）と使う所 | ライト | ダーク | コントラストを上げる（ライト / ダーク） | 基準 | 結果 |
|---|---|---|---|---|---|
| B1 color.text.primary（label）/ 各背景：17pt 以下の文字のすべて（ヒント、日付、「72ページから」、状態の文字、見出しと footer、LabeledContent の値、エラーの区画の文） | #000000 / #FFFFFF = 21.00:1、#000000 / #F2F2F7 = 18.82:1 | #FFFFFF / #000000 = 21.00:1、#FFFFFF / #1C1C1E = 17.01:1、#FFFFFF / #2C2C2E = 13.94:1 | #000000 / #EBEBF0 = 17.67:1 / #FFFFFF / #363638 = 12.06:1 | 4.5:1 | 満たす |
| B2 color.text.secondary（secondaryLabel）/ 各背景：17pt 以下の文字（前の版で使っていた所：S4 の「72ページから」と「一時停止中」、S2 の題名の上限の知らせ、S3 の記録の日付、欄の下のヒント） | #8A8A8E / #FFFFFF = 3.44:1、#85858B / #F2F2F7 = 3.29:1 | #8D8D93 / #000000 = 6.36:1、#98989F / #1C1C1E = 5.94:1、#9F9FA5 / #2C2C2E = 5.29:1 | #7B7B7F / #FFFFFF = 4.22:1、#74747B / #EBEBF0 = 3.90:1 / #9F9FA6 / #000000 = 7.98:1、#ABABB2 / #242426 = 6.79:1、#B1B1B8 / #363638 = 5.66:1 | 4.5:1 | 満たさない（ライトとコントラストを上げるライト）。だから 17pt 以下の文字には使わず、すべて B1 に替えた |
| B3 color.text.secondary（secondaryLabel）/ color.background.screen：S4 の一時停止中の経過時間（type.timer、.largeTitle 34pt） | #8A8A8E / #FFFFFF = 3.44:1 | #8D8D93 / #000000 = 6.36:1 | #7B7B7F / #FFFFFF = 4.22:1 / #9F9FA6 / #000000 = 7.98:1 | 3:1（18pt 以上） | 満たす |
| B4 color.text.placeholder（placeholderText）/ 入力欄の行：前の版の「必須」「任意」 | #C5C5C7 / #FFFFFF = 1.72:1 | シートの行 #656569 / #2C2C2E = 2.40:1 | #B6B6B8 / #FFFFFF = 2.02:1 / シートの行 #7A7A7F / #363638 = 2.82:1 | 4.5:1 | 満たさない。だから placeholder を置かない。必須と任意は見出し（S2）と footer の文（S5）で伝える |
| B5 .bordered のラベル（color.text.primary）/ その塗り（color.fill.secondaryButton。値の表がないので、システムの灰色4まで濃くなったと見て控えめに計算） | #000000 / #D1D1D6 = 13.80:1 | #FFFFFF / #3A3A3C = 11.35:1 | #000000 / #BCBCC0 = 11.09:1 / #FFFFFF / #444446 = 9.72:1 | 4.5:1 | 満たす（見積もり） |

### C. システムの部品が自分で描く色（アプリは色を指定しない）
| 組と使う所 | ライト | ダーク | コントラストを上げる（ライト / ダーク） | 基準 | 結果と扱い |
|---|---|---|---|---|---|
| C1 白い記号 / systemRed の塗り：S3 の行のスワイプの削除（trash。スワイプのボタンは記号だけを出し、文字はラベルとして読み上げる）、編集モードの赤い丸 | #FFFFFF / #FF383C = 3.57:1 | #FFFFFF / #FF4245 = 3.43:1 | #FFFFFF / #E9152D = 4.56:1 / #FFFFFF / #FF6165 = 2.94:1 | 3:1（記号） | コントラストを上げるダークで届かない。システムの destructive の見た目（HIG Buttons「a destructive button uses the system red color」）で、アプリは色を変えない。同じ操作は、色に頼らない道（VoiceOver などのアクション「削除」）でも行える。扱いは仕様の 10 と報告の「未解決」 |
| C2 白い文字 / systemRed の塗り：S3 の編集モードで赤い丸を押した後に出る「削除」 | #FFFFFF / #FF383C = 3.57:1 | #FFFFFF / #FF4245 = 3.43:1 | #FFFFFF / #E9152D = 4.56:1 / #FFFFFF / #FF6165 = 2.94:1 | 4.5:1（17pt） | コントラストを上げるライトだけ満たす。扱いは C1 と同じ |
| C3 S2 の確認のダイアログ（confirmationDialog）の題、S6 と S7 の alert の題と本文 | システムが描く（値は見ていない） | 同じ | 同じ | 4.5:1 | G3 のスクリーンショットで測る |
| C4 無効のボタン（S2、S5 の無効の確定のボタン、S3 の無効の主操作） | システムの無効の見た目 | 同じ | 同じ | 対象外 | 無効であることは、すぐ近くの文（book.start.busy、誤りの文）でも伝える |
| C5 systemRed の文字 / ダイアログの背景：S2 の確認のダイアログの「追加せずに閉じる」（destructive）。背景の値の表がないので、白、grouped、elevated の行で見積もる | #FF383C / #FFFFFF = 3.57:1、#FF383C / #F2F2F7 = 3.20:1 | #FF4245 / #2C2C2E = 4.06:1 | #E9152D / #FFFFFF = 4.56:1、#E9152D / #EBEBF0 = 3.83:1 / #FF6165 / #363638 = 4.11:1 | 18pt 以上なら 3:1、17pt 以下なら 4.5:1 | 文字の大きさは iOS の版で変わり、見ていない。18pt 以上なら満たし、17pt 以下なら届かない。G3 で測る。扱いは C1 と同じ |

計算に使ったコマンド（値を入れ替えて確かめられる）：
- 2色の比：`python3 -c "import sys;L=lambda h:sum(w*(c/12.92 if c<=0.04045 else ((c+0.055)/1.055)**2.4) for w,c in zip((0.2126,0.7152,0.0722),(int(h.lstrip('#')[i:i+2],16)/255 for i in (0,2,4))));a,b=sorted(map(L,sys.argv[1:3]));print(round((b+0.05)/(a+0.05),2))" FFFFFF 9F5833`（5.36 と出る）
- 半透明の色を背景に重ねる：`python3 -c "import sys;f=[int(x) for x in sys.argv[1].split(',')];b=sys.argv[2];a=f[3]/255;print('%02X%02X%02X'%tuple(round(x*a+int(b[i:i+2],16)*(1-a)) for x,i in zip(f[:3],(0,2,4))))" 60,60,67,153 FFFFFF`（8A8A8E と出る。続けて上のコマンドに 8A8A8E FFFFFF を渡すと 3.44）
