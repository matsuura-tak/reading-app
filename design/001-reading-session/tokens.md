# トークン 001-reading-session（芯の画面）

- 書いた役：designer　日付：2026-10-19
- 使う所：design/001-reading-session.md（8 見た目、9 コントラスト）
- design/ にはほかのトークンのファイルがないので、ここに置いた。アプリ全体のトークンにするときは、tech-lead と相談して design/ の直下に移す。
- 名前は意味で付ける（色の名前で付けない）。独自の色は、アセットカタログの1つの色に「ライト」「ダーク」「コントラストを上げる（ライト、ダーク）」の4つの見た目を入れる。
- 決まり：余白、色、文字はこの表のものだけを使う。書いていない値を画面で作らない。

## 色
| トークン | 使う所 | ライト | ダーク | コントラストを上げる（ライト / ダーク） | 種類 |
|---|---|---|---|---|---|
| `color.background.primary` | S-1、S-2、S-4 の地、W-2 の地（containerBackground） | systemBackground（#FFFFFF） | systemBackground（#000000） | システム | システム色 |
| `color.background.grouped` | List と Form の地（S-6〜S-10） | systemGroupedBackground（#F2F2F7） | systemGroupedBackground（#000000。シートの中は #1C1C1E） | システム | システム色 |
| `color.background.groupedRow` | List と Form の行の地 | secondarySystemGroupedBackground（#FFFFFF） | #1C1C1E（シートの中は #2C2C2E） | システム | システム色 |
| `color.text.primary` | 書名、一行、本文、値 | label | label | システム | システム色 |
| `color.text.secondary` | 著者、補足、説明、日付、伏せる案内 | #6C6C70 | #98989F | #48484A / #C7C7CC | 独自（システムの secondaryLabel はライトで 3.44:1 のため） |
| `color.action.primary.background` | 主操作（.borderedProminent）の地 | #1C1C1E | #F2F2F7 | #000000 / #FFFFFF | 独自 |
| `color.action.primary.label` | 主操作の文字 | #FFFFFF | #000000 | #FFFFFF / #000000 | 独自 |
| `color.action.tint` | アプリの tint（AccentColor）：文字のボタン、.bordered、リンク、チェックの記号、ツールバーの記号 | #1C1C1E | #F2F2F7 | #000000 / #FFFFFF | 独自（`color.action.primary.background` と同じ値） |
| `color.state.error` | エラーの記号（exclamationmark.circle）だけ。文字には使わない | systemRed（#FF3B30） | systemRed（#FF453A） | #D70015 / #FF6961 | システム色 |
| `color.state.on` | Toggle のオン（`color.action.tint` を当てない） | systemGreen | systemGreen | システム | システム色 |
| `color.separator` | 奥付の上下の罫線（Divider） | separator | separator | システム | システム色 |
| `color.widget.foreground` | W-1、W-2 の字 | primary（ロック画面と暗い StandBy はシステムが色を抜くか赤で描く） | primary | システム | システム色 |

- コントラスト比は design/001-reading-session.md の 9。
- 使わない色：アクセント色（青、橙など）、グラデーション、影の色、紙や革の質感の色。

## 文字
| トークン | 書体と text style | 太さ | 大きさ | 使う所 |
|---|---|---|---|---|
| `type.book.line` | ヒラギノ明朝 ProN（HiraMinProN-W3）。Font.custom(_:size:relativeTo: .title) | W3 | 28pt を基準に Dynamic Type で拡大縮小 | S-1 の一行（縦書き。accessibility1 以上は横書き） |
| `type.book.line.widget` | ヒラギノ明朝 ProN（HiraMinProN-W6）。Font.custom(_:fixedSize:) | W6 | 固定。W-1 は 17pt、W-2 は 20pt から、枠に全部の字が入るまで1pt ずつ下げる。下限 13pt | W-1、W-2、S-5 の見本の一行 |
| `type.widget.page` | システム .caption2 の書体を固定の大きさで | Semibold | W-1 は 12pt、W-2 は 13pt（固定） | ウィジェットの「p.61」、「しおり」 |
| `type.widget.message` | システム .caption を固定の大きさで | Regular | 12pt（入らなければ 0.8 倍まで） | `widget.empty`、`widget.unavailable` |
| `type.screen.title` | .largeTitle（ナビゲーションの大きい題）| 既定（Bold） | Dynamic Type | S-9 の見出し |
| `type.title` | .title | Regular | Dynamic Type | S-4 のまとめ（monospacedDigit） |
| `type.title.emphasis` | .title2 | Bold | Dynamic Type | S-2 の書名、S-3 の問い |
| `type.book.title` | .headline | 既定（Semibold） | Dynamic Type | S-1、S-4 の書名、S-9 の候補の書名、主操作の文字 |
| `type.body` | .body | Regular | Dynamic Type | 行、値、S-2 の時刻 |
| `type.secondary` | .subheadline | Regular | Dynamic Type | 著者、ページ、文字のボタン、理由の1行、奥付の名前 |
| `type.note` | .footnote | Regular | Dynamic Type | 伏せる案内、説明、戻し方の1行 |

- 本の言葉（一行）だけを明朝にし、アプリの言葉はシステムの書体にする（決定 5。B-4 の例外）。
- Ultralight、Thin、Light は使わない。数字は monospacedDigit。
- 縦書きの組み（決定 6）：句読点「、」「。」とかぎ括弧「「」「」」は縦書き用の字（U+FE11、U+FE12、U+FE41、U+FE42）、「ー」は90度回す、小さい仮名は字の枠の右上、行頭の禁則は追い出し。列は右から左。1列の字数は W-1 で4字、W-2 で5〜6字を目安に、全部の字が入ることを先にする。

## 余白
| トークン | 値 | 使う所 |
|---|---|---|
| `space.4` | 4pt | 行の中の書名と補足の間 |
| `space.8` | 8pt | 記号と文字の間、知らせの帯の内側の上下 |
| `space.12` | 12pt | 並んだボタンの間、知らせの帯の内側の左右 |
| `space.16` | 16pt | 画面の左右の余白、下端の主操作の下（safe area の内側）、W-2 の内側、奥付の罫線と行の間 |
| `space.24` | 24pt | まとまりの間（S-1 の一行とボタンの間、S-9 の奥付と次の1冊の間） |
| `space.32` | 32pt | S-1 の書名と一行の間、S-2 と S-4 の上の余白 |

- W-1 は内側の余白を足さない（枠そのものがロック画面の余白に合っている［推測。G4-1 で見る］）。

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
