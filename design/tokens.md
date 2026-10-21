# デザイントークン（アプリ全体）

- 書いた役：designer　日付：2026-10-21　最初に使う機能：001-reading-session（design/001-reading-session.md）
- 色、文字、余白は、この表の名前だけを使う。画面の仕様と実装に、色の値や文字の大きさを直接書かない。
- 色はシステムの色を先に使う。独自の色は「しおりの色」と、その上に載せる文字の色の2つだけ（HIG Color「Make sure all your app's colors work well in light, dark, and increased contrast contexts」https://developer.apple.com/design/human-interface-guidelines/color ）。
- 根拠の R 番号は design/001-reading-session-research.md の 8、B 番号は .claude/skills/craft-designer/SKILL.md の 1。

## 1. 色
名前は意味で付ける。独自の色は Asset Catalog の Color Set に、Any、Dark、High Contrast（Any と Dark）の4つの値を入れる。

| トークン | 意味と使う所 | ライト | ダーク | コントラストを上げる（ライト / ダーク） | 根拠 |
|---|---|---|---|---|---|
| color.background.screen | 読書中の画面の背景 | systemBackground | systemBackground | システムが切り替える | R-9「Prefer the system background colors.」 |
| color.background.grouped | ホーム、本の詳細、本の追加、読書を終えるの背景（List と Form の既定） | systemGroupedBackground | systemGroupedBackground | システムが切り替える | R-9 |
| color.background.row | リストとフォームの行の背景（既定） | secondarySystemGroupedBackground | secondarySystemGroupedBackground | システムが切り替える | R-9 |
| color.text.primary | 本文、題名、経過時間（読書中）、値 | label | label | システムが切り替える | R-12、HIG Color の Label |
| color.text.secondary | 補いの文（ヒント、日付、「72ページから」）、一時停止中の経過時間と状態 | secondaryLabel | secondaryLabel | システムが切り替える | R-12 |
| color.text.placeholder | 入力欄の空のときの文字（TextField の既定） | placeholderText | placeholderText | システムが切り替える | HIG Text fields |
| color.separator | 行の区切り（List の既定） | separator | separator | システムが切り替える | B-2（独自の線を引かない） |
| color.accent（しおりの色 / Bookmark） | アプリのアクセント。目立つ主操作の塗り（borderedProminent）、シートの確定のボタン、行の中の文字のボタン（「もう一度保存」）、読書中の状態の文字「読書中」、入力欄のカーソル。これ以外に使わない | #7A4427 | #C99671 | #5E3219 / #E3B994 | R-10「choosing your brand color as the app accent color can be an effective way」「In dark environments, colors appear bright and saturated.」、R-9「strive for a contrast ratio of 7:1」、B-5 |
| color.text.onAccent | color.accent で塗った面の上の文字 | #FFFFFF | #000000 | #FFFFFF / #000000 | R-9、R-11 |
| color.status.error | 入力の誤りと保存の失敗の印（記号 exclamationmark.triangle）だけに使う。文字には使わない | systemRed（HIG の値 255,56,60） | systemRed（255,66,69） | systemRed（233,21,45 / 255,97,101） | R-10「Avoid relying solely on color」、R-11 |
| color.fill.secondaryButton | 主操作でないボタン（一時停止、再開）の塗りと文字。ボタンの形は .bordered、tint は color.text.primary | システムが tint から作る塗り | 同じ | システムが切り替える | HIG Buttons「Use style — not size — to visually distinguish the preferred choice」、B-5 |

しおりの色を栗色（ライト #7A4427、ダーク #C99671）にした理由：
- 内容はほぼ無彩色（題名、数字、一覧）なので、アクセント1色でアプリを見分けられる（R-10）。iOS の既定の青のままにしない（調べた AI らしい既定の見た目を避ける。craft-designer の 4）。
- 赤（消す、エラー）、緑（成功の意味に読まれやすい）、青（既定の色）と重ならない色にし、1つの色が1つの意味になるようにする（B-5）。
- 寝る前の暗い部屋で使う（R-23）。暗い所では色が明るく鮮やかに見える（R-10）ので、彩度を抑えた色にした。紙のしおりの革や布の色は連想だけで、絵や質感は描かない（research 6 の差1、B-2）。
- ダークの値は、黒い文字を載せて 7:1 を超え、背景の黒に対しても 7:1 を超える明るさにした（下の 5）。

使わない色：上の表にない色、グラデーション、影、半透明の独自の色。

## 2. 文字
書体はシステムの1つ（日本語はシステムの日本語書体、英語は SF Pro）。大きさは Dynamic Type の text style だけで指定し、ポイント数を書かない。Ultralight、Thin、Light は使わない（R-12）。1画面で使う段は4つまで（B-4。画面ごとの段は仕様の 8）。

| トークン | text style | 太さ | 等幅の数字 | 使う所 |
|---|---|---|---|---|
| type.timer | .largeTitle | 既定（Regular） | 使う（monospacedDigit） | 読書中の経過時間 reading.elapsed |
| type.navTitle | .largeTitle（システムの大きい見出し） | システムの既定 | 使わない | ホームの見出し「読書」 |
| type.bookHeading | .title2 | 強調（Bold。HIG の Emphasized weight） | 使わない | 本の詳細の先頭の題名 book.title |
| type.readingTitle | .title3 | 既定（Regular） | 使わない | 読書中の画面の題名 reading.title |
| type.primaryTitle | .headline | 既定（Semibold） | 使わない | ホームの主操作の1行目（題名） |
| type.body | .body | 既定 | 数字の値には使う | 行の文字、入力欄、値（60分、72、24%）、ボタン（システムの既定） |
| type.secondary | .subheadline | 既定 | 使わない | 主操作の2行目（72ページから読む）、「72ページから」、状態の文字、記録の日付 |
| type.note | .footnote | 既定 | 使わない | セクションの見出し（21冊、記録 3件）、入力の下のヒントと誤りの文 |

## 3. 余白
4pt を元にした6段だけを使う（B-3）。List、Form、toolbar、sheet の中の余白はシステムの既定に任せ、ここで上書きしない。

| トークン | 値 | 使う所 |
|---|---|---|
| space.xxs | 4pt | 主操作の1行目と2行目の間、記号と文字の間 |
| space.xs | 8pt | 記録の行の中の分とページの間、下端の主操作の帯の上の余白 |
| space.s | 12pt | 読書中の画面の、題名と「72ページから」の間、経過と状態の間 |
| space.m | 16pt | 画面の左右の余白（下端の主操作、読書中の画面のボタン）、2つのボタンの間 |
| space.l | 24pt | 読書中の画面の、題名のまとまりと経過のまとまりの間 |
| space.xl | 32pt | 読書中の画面の、経過のまとまりとボタンの間（最小値。残りは Spacer で広がる） |

## 4. 形と動きと素材
- 角丸：ボタン、行、シートはシステムの既定のまま。独自の角丸を作らない。
- 影、グラデーション、紙の質感、絵：使わない（B-2、research 7 で案B を選ばなかった理由）。
- 素材：Liquid Glass はシステムがナビゲーションバー、ツールバー、シートに付ける分だけ。内容の層（背景、行、下端の主操作の帯）には使わず、glassEffect を独自に付けない（R-13「Don't use Liquid Glass in the content layer.」）。
- 動き：画面の切り替えはシステムの push と sheet の動きだけ。経過時間の数字は、変わるときに動き（contentTransition の数字の動きなど）を付けない。独自の動きがないので、動きを減らす設定のときに変えるものはない（システムの切り替えはシステムが減らす）。

## 5. コントラスト
計算は WCAG 2 の相対輝度の式（design-reviewer の手引き craft-design-reviewer の「使うコマンド」と同じ式）を python3 で計算した。背景の値は次のとおり。HIG に背景色の値の表はないので、systemGroupedBackground（ライト）と secondarySystemGroupedBackground（ダーク）は、HIG Color の表の systemGray6 と同じ値として計算した（ライト #F2F2F7、ダーク #1C1C1E、コントラストを上げるはライト #EBEBF0、ダーク #242426）。systemBackground と secondarySystemGroupedBackground（ライト）は #FFFFFF、systemBackground と systemGroupedBackground（ダーク）は #000000。systemRed の値は HIG Color の System colors の表（2026-10-21 に開いて確認）。

基準：17pt 以下の文字は 4.5:1 以上、18pt 以上か太字は 3:1 以上、記号と操作部品の枠は 3:1 以上（R-11）。独自の色は 7:1 を目指す（R-9）。

| 前景と背景の組 | ライト | ダーク | コントラストを上げる（ライト / ダーク） | 基準 | 結果 |
|---|---|---|---|---|---|
| color.text.onAccent の文字 / color.accent の塗り（主操作の文字。2行目は .subheadline の Regular） | #FFFFFF / #7A4427 = 7.83:1 | #000000 / #C99671 = 8.08:1 | #FFFFFF / #5E3219 = 10.79:1、#000000 / #E3B994 = 11.63:1 | 4.5:1 | 満たす（7:1 も満たす） |
| color.accent の文字 / color.background.screen（「読書中」） | #7A4427 / #FFFFFF = 7.83:1 | #C99671 / #000000 = 8.08:1 | #5E3219 / #FFFFFF = 10.79:1、#E3B994 / #000000 = 11.63:1 | 4.5:1 | 満たす |
| color.accent の塗り / color.background.grouped（下端の主操作の形の枠。シートの確定ボタンの文字） | #7A4427 / #F2F2F7 = 7.01:1 | #C99671 / #000000 = 8.08:1 | #5E3219 / #EBEBF0 = 9.08:1、#E3B994 / #000000 = 11.63:1 | 3:1（枠）、4.5:1（文字） | 満たす |
| color.accent の文字 / color.background.row（行の中の「もう一度保存」） | #7A4427 / #FFFFFF = 7.83:1 | #C99671 / #1C1C1E = 6.55:1 | #5E3219 / #FFFFFF = 10.79:1、#E3B994 / #242426 = 8.58:1 | 4.5:1 | 満たす |
| color.status.error の記号 / color.background.grouped（入力の下の誤りの印） | #FF383C / #F2F2F7 = 3.20:1 | #FF4245 / #000000 = 6.12:1 | #E9152D / #EBEBF0 = 3.83:1、#FF6165 / #000000 = 7.15:1 | 3:1（記号） | 満たす（ライトは余裕が小さい。文字は color.text.primary で、記号だけに色を使う） |
| color.status.error の記号 / color.background.row（保存の失敗の印） | #FF383C / #FFFFFF = 3.57:1 | #FF4245 / #1C1C1E = 4.96:1 | #E9152D / #FFFFFF = 4.56:1、#FF6165 / #242426 = 5.28:1 | 3:1（記号） | 満たす |
| color.text.primary、color.text.secondary、color.text.placeholder と各背景 | システム色 | システム色 | システム色 | — | システムが保証する組 |
| color.fill.secondaryButton（一時停止、再開） | システム色 | システム色 | システム色 | — | システムが tint から作る |

計算に使ったコマンド（1組ずつ。値を入れ替えて確かめられる）：
`python3 -c "import sys;L=lambda h:sum(w*(c/12.92 if c<=0.04045 else ((c+0.055)/1.055)**2.4) for w,c in zip((0.2126,0.7152,0.0722),(int(h.lstrip('#')[i:i+2],16)/255 for i in (0,2,4))));a,b=sorted(map(L,sys.argv[1:3]));print(round((b+0.05)/(a+0.05),2))" FFFFFF 7A4427`（7.83 と出る）
