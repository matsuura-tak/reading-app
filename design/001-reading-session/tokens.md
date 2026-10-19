# トークン 001-reading-session（芯の画面）

- 書いた役：designer　日付：2026-10-19。2026-10-20 に G1 の判定 r1 の指摘で直した（消す操作の色、systemRed の値、`color.action.tint` の使い方、`type.widget.message` の太さ、縦書きの置き換えの表と列の間、ウィジェットの余白とページの帯）
- 使う所：design/001-reading-session.md（8 見た目、9 コントラスト）
- design/ にはほかのトークンのファイルがないので、ここに置いた。アプリ全体のトークンにするときは、tech-lead と相談して design/ の直下に移す。
- 名前は意味で付ける（色の名前で付けない）。独自の色は、アセットカタログの1つの色に「ライト」「ダーク」「コントラストを上げる（ライト、ダーク）」の4つの見た目を入れる。
- 決まり：余白、色、文字はこの表のものだけを使う。書いていない値を画面で作らない。

## 色
| トークン | 使う所 | ライト | ダーク | コントラストを上げる（ライト / ダーク） | 種類 |
|---|---|---|---|---|---|
| `color.background.primary` | S-1、S-2、S-4 の地、W-2 の地（containerBackground） | systemBackground（#FFFFFF） | systemBackground（#000000） | システム | システム色 |
| `color.background.grouped` | List と Form の地（S-6〜S-10） | systemGroupedBackground（#F2F2F7） | systemGroupedBackground（#000000。シートの中は #1C1C1E） | システム（iOS 27.0 の実測：ライト #EBEBF0） | システム色 |
| `color.background.groupedRow` | List と Form の行の地 | secondarySystemGroupedBackground（#FFFFFF） | #1C1C1E（シートの中は #2C2C2E） | システム（iOS 27.0 の実測：ダーク #242426、シートの中 #363638） | システム色 |
| `color.text.primary` | 書名、一行、本文、値、消すボタンの文字 | label | label | システム | システム色 |
| `color.text.secondary` | 著者、補足、説明、日付、伏せる案内、Form と List の節の見出しと説明、外へ開く記号 arrow.up.forward、検索欄の記号（magnifyingglass、xmark.circle.fill）。ダークのシートの中の入れ子の地（tertiarySystemGroupedBackground、#3A3A3C）には置かない（3.96:1 で 4.5:1 に届かない） | #6C6C70 | #98989F | #48484A / #C7C7CC | 独自（システムの secondaryLabel はライトで 3.44:1 のため） |
| `color.action.primary.background` | 主操作（.borderedProminent）の地。ContentUnavailableView のボタンも同じ | #1C1C1E | #F2F2F7 | #000000 / #FFFFFF | 独自 |
| `color.action.primary.label` | 主操作の文字 | #FFFFFF | #000000 | #FFFFFF / #000000 | 独自 |
| `color.action.tint` | アプリの tint（AccentColor）：.bordered の文字と塗り、Link の文字、チェックの記号、ツールバーの記号。枠のない文字のボタンには使わない（押せることは形で見せる。仕様の 3 の下の決まり） | #1C1C1E | #F2F2F7 | #000000 / #FFFFFF | 独自（`color.action.primary.background` と同じ値） |
| `color.action.destructive` | 消す操作の記号 trash だけ（S-7「この本を消す」、S-7b「この記録を消す」）。文字には使わない（消すボタンの文字は `color.text.primary`） | systemRed（#FF383C） | systemRed（#FF4245） | #E9152D / #FF6165 | システム色 |
| `color.state.error` | エラーの記号（exclamationmark.circle）だけ。文字には使わない | systemRed（#FF383C） | systemRed（#FF4245） | #E9152D / #FF6165 | システム色 |
| `color.state.on` | Toggle のオン（`color.action.tint` を当てない） | systemGreen | systemGreen | システム | システム色 |
| `color.separator` | 奥付の上下の罫線（Divider） | separator | separator | システム | システム色 |
| `color.widget.foreground` | W-1、W-2 の字 | primary（ロック画面と暗い StandBy はシステムが色を抜くか赤で描く） | primary | システム | システム色 |

- systemRed の値は iOS 27.0 のシミュレーターの実測（tech-lead r1 の提案1。design-reviewer r1 の提案14 の HIG の今の値と同じ）。前の版の #FF3B30、#FF453A、#D70015、#FF6961 は iOS 26 より前の値だった。iOS 26 の値は G1-3 で、同じ測り方で測る。
- コントラストを上げる設定の地の値も iOS 27.0 の実測（tech-lead r1 の C の問い5）。
- 主操作の .borderedProminent には、tint（`color.action.primary.background`）と foregroundStyle（`color.action.primary.label`）を必ず付ける（付けないとダークで文字が地と同じ白になる。tech-lead r1 の B の S-1 の行の spike）。
- コントラスト比は design/001-reading-session.md の 9。
- 使わない色：アクセント色（青、橙など）、グラデーション、影の色、紙や革の質感の色。

## 文字
| トークン | 書体と text style | 太さ | 大きさ | 使う所 |
|---|---|---|---|---|
| `type.book.line` | ヒラギノ明朝 ProN（HiraMinProN-W3）。Font.custom(_:size:relativeTo: .title) | W3 | 28pt を基準に Dynamic Type で拡大縮小 | S-1 の一行（縦書き。accessibility1 以上は横書き） |
| `type.book.line.widget` | ヒラギノ明朝 ProN（HiraMinProN-W6）。Font.custom(_:fixedSize:) | W6 | 固定。W-1 は 17pt、W-2 は 20pt から、枠に全部の字が入るまで1pt ずつ下げる。下限 13pt（入るかの式は tech-lead が縦書きの ADR に書く） | W-1、W-2、S-5 の見本の一行 |
| `type.book.line.columnGap` | 縦書きの列と列の間（文字の組みの値。余白のトークンではない） | ー | 字の大きさの 0.25 倍（17pt なら 4.25pt、28pt なら 7pt） | W-1、W-2、S-1、S-5 の縦書き |
| `type.widget.page` | システム .caption2 の書体を固定の大きさで | Semibold | W-1 は 12pt、W-2 は 13pt（固定） | ウィジェットの「p.61」、「しおり」 |
| `type.widget.message` | システム .caption を固定の大きさで | Semibold（vibrant でも細らない太さ。PRD 12。ページと同じ太さ） | 12pt（入らなければ 0.8 倍まで） | `widget.empty`、`widget.unavailable` |
| `type.screen.title` | .largeTitle（ナビゲーションの大きい題）| 既定（Bold） | Dynamic Type | S-9 の見出し |
| `type.title` | .title | Regular | Dynamic Type | S-4 のまとめ（monospacedDigit） |
| `type.title.emphasis` | .title2 | Bold | Dynamic Type | S-2 の書名、S-3 の問い |
| `type.book.title` | .headline | 既定（Semibold） | Dynamic Type | S-1、S-4 の書名、S-9 の候補の書名、主操作の文字 |
| `type.body` | .body | Regular | Dynamic Type | 行、値、S-2 の時刻、消すボタンの文字 |
| `type.secondary` | .subheadline | Regular | Dynamic Type | 著者、ページ、S-1 の2つの .bordered のボタンの文字、理由の1行、奥付の名前 |
| `type.note` | .footnote | Regular | Dynamic Type | 伏せる案内、説明、戻し方の1行 |

- 本の言葉（一行）だけを明朝にし、アプリの言葉はシステムの書体にする（決定 5。B-4 の例外）。
- Ultralight、Thin、Light は使わない。数字は monospacedDigit。

## 縦書きの組み（決定 6、8）
- 1字を 1em 四方の升目に置き、列は右から左へ並べる（tech-lead r1 の C の注3 の方針）。
- 1列の字数は、内側の高さを字の大きさで割った整数（W-1 は 17pt で4字、W-2 は5〜6字が目安）。全部の字が入ることを先にする。
- 列の間は `type.book.line.columnGap`（字の大きさの 0.25 倍）。和字は升目の中に左右の空きがあるので、見える列の間はこれより広い［推測。縦書きの ADR の spike と G4-1 で見る］。0.5 倍にすると、W-1 のいちばん小さい枠（153×68pt）で追い出しで列が1つ増えた25字は、帯を38pt と見て 13pt（余り 0.5pt）、40pt と見ると入らず、帯の幅の見積もりの誤差で入らなくなる。0.25 倍なら 13pt（余り 14.75pt）（帯 40pt）で入るので、0.25 倍にした（仕様の 9 の計算）。
- 行頭の禁則は追い出し（前の列の最後の字を次の列へ送る）。
- W-1 のページの帯：左端に置く。幅は `type.widget.page` で「p.9999」を描いた幅で固定（約38〜40pt［推測。縦書きの ADR の spike で測る］）。ページの桁が変わっても列は動かない。ページは帯の下（ノンブルの位置）。帯と列の間は `space.4`。列は帯の右から組む。
- W-2 は帯を置かず、ページを列の下の左端に置く（内側 116pt 四方に25字が 19pt で入る。tech-lead r1 の要修正1）。
- 入るかを決める式（1列の字数、列の数、帯の幅を引いた内側の幅）と、1pt ずつ下げる手順は、tech-lead が縦書きの ADR に書く。

### 字の置き換え
組みの結果には、元の字と出す字の両方を持たせる。AC-28 の字のそろいと AC-99 の読み上げは、元の字で比べる。

| 元の字 | 出す字 | 出し方 |
|---|---|---|
| 、 | ︑（U+FE11） | 縦書き用の字 |
| 。 | ︒（U+FE12） | 縦書き用の字 |
| 「 」 | ﹁ ﹂（U+FE41、U+FE42） | 縦書き用の字 |
| 『 』 | ﹃ ﹄（U+FE43、U+FE44） | 縦書き用の字（r1 で足した） |
| （ ） | ︵ ︶（U+FE35、U+FE36） | 縦書き用の字（r1 で足した） |
| …（U+2026） | ︙（U+FE19） | 縦書き用の字（r1 で足した。ウィジェットの縮め方で付く「…」も同じ） |
| ―（U+2015）、—（U+2014） | ︱（U+FE31） | 縦書き用の字（r1 で足した） |
| ー（U+30FC）、〜（U+301C）、～（U+FF5E） | 同じ字 | 90度回す（「〜」「～」は r1 で足した） |
| ぁ ぃ ぅ ぇ ぉ っ ゃ ゅ ょ ゎ、ァ ィ ゥ ェ ォ ッ ャ ュ ョ ヮ ヵ ヶ | 同じ字 | 字の枠の右上に寄せる |
| ！ ？ ・ | 同じ字 | そのまま立てる（r1 で書き足した） |
| 半角の英字と数字（例 iPhone、3章） | 全角の字（ｉＰｈｏｎｅ、３章） | 全角に直して1字ずつ立てる（r1 で足した） |
| 半角の「!」「?」 | ！ ？ | 全角に直して立てる（r1 で足した） |
| ほかの字 | 同じ字 | そのまま立てる |

- 半角の英数字を全角に直して立てる理由：JLREQ は、欧文を縦書きに入れる形として、1字ずつ立てる形（ふつうは単独の英数字や大文字の略語。全角の字で組む）、90度回す形（ふつうは英語の語や文）、縦中横（ふつうは2桁の数字）の3つを挙げている（R-30 と同じ文書の §2.3.2。2026-10-20 に開いた）。この組みは1字ずつの升目で、1列が4〜6字と短い。回した語は列をまたぐと読めず、縦中横は升目の幅を変えるので、語の長さに関わらず全角に直して立てる形に1つにそろえた。字の数（書記素）は変わらないので、ウィジェットの縮め方（25字）の数え方も変わらない。
- 縦書き用の字形（U+FE11、FE12、FE19、FE31、FE35、FE36、FE41〜FE44）は、ヒラギノ明朝 ProN の W3 と W6 の両方にあると tech-lead が iOS 27.0 で確かめた（tech-lead r1 の要修正2）。小さい仮名を手でずらすか、フォントの縦書きの置き換えを使うかは、縦書きの ADR の spike で決める（見た目はどちらも右上）。
- この表は tech-lead が縦書きの ADR に写す。見た目を変えるときは designer がこの表を直す。

## 余白
| トークン | 値 | 使う所 |
|---|---|---|
| `space.4` | 4pt | 行の中の書名と補足の間、W-1 のページの帯と列の間 |
| `space.8` | 8pt | 記号と文字の間、知らせの帯の内側の上下 |
| `space.12` | 12pt | 並んだボタンの間、知らせの帯の内側の左右 |
| `space.16` | 16pt | 画面の左右の余白、下端の主操作の下（safe area の内側）、W-2 の内側、奥付の罫線と行の間 |
| `space.24` | 24pt | まとまりの間（S-1 の一行とボタンの間、S-9 の奥付と次の1冊の間） |
| `space.32` | 32pt | S-1 の書名と一行の間、S-2 と S-4 の上の余白 |

- ウィジェットはシステムの既定の余白を切る（contentMarginsDisabled）。W-1 は内側の余白 0（枠そのものがロック画面の余白に合っている［推測。G4-1 で見る］）、W-2 は `space.16` を自分で付ける。アプリの中の描画（H22、S-5 の見本）と本物のウィジェットで、組みの計算を同じにするため（tech-lead r1 の提案5）。

## 角、影、素材、動き
- 角：システムの既定（ボタン、シート、List）。独自の角丸は作らない。
- 影：使わない。
- 素材：ツールバーのボタンとシートはシステム（Liquid Glass）。内容の層（一行、奥付、一覧の地）には素材を使わない（R-25）。
- 動き：システムの押し出しとシートだけ。独自の動きは作らない。動きのために操作を止めない（PRD 12）。

## 触覚
| トークン | 型 | 出す時 | 回数 |
|---|---|---|---|
| `haptic.flipStart` | SensoryFeedback.start | 伏せて1.0秒たち、`reading` になったとき | 1回（AC-44） |
| `haptic.scanRead` | SensoryFeedback.success | S-8a で新しい本を1冊読めたとき（重なりと本でないコードでは出さない） | 1冊に1回（AC-3） |

- ほかの場面（保存、終える、読み終えた、エラー）では触覚を出さない。
