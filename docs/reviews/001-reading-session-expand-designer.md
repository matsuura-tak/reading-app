（指揮役の注）Takuma の 2026-10-20 の問い直し（バーコードでの一括取得、デジタル書籍への対応、レコメンドのニーズ）への調べもののうち、designer の報告（体験と絵コンテ）。pdm と tech-lead も並べて調べている。判定ではない。報告の文はそのまま保存した。

# デジタル書籍、おすすめ、バーコードでの一括取得の体験（designer の調べものと発想）

2026-10-20 に調べました。実機、本物の本、Kindle や Apple Books の実際の画面は試していません。秒はすべて見積もりです［推測］。
- R-1〜R-35 は design/001-reading-session-research.md の番号です。
- R-36〜R-66 は前の2回の調べもの（biblio-alt-designer、rethink-designer）の番号です。
- R-67〜R-80 は今回新しく開いた出典です（5 に引用、URL、確認日をまとめました）。

## 0. 結論

**3つとも、1つの考えで解けます。「どの本でも、写して押す」**
- 紙の本は写真、電子書籍はスクリーンショットで写します。
- そのあとは、どちらも「止めた画像の行を押す」同じ部品で、加える、続きの一行、奥付をまかないます。
  - 本棚の写真 ⇔ 電子書籍のライブラリのスクショ
  - 開いたページを撮る ⇔ 止めた画面のスクショ
  - 最後のページの奥付 ⇔ 電子版の奥付のスクショ
- スクショだけを出す写真の一覧は、許可なしで開けます（R-71）。前の調べものの未解決「PhotosPicker が許可なしで使えるか」も、WWDC22 の「your app doesn't need to request any library access」で確かめました。

**推す形**
1. **電子書籍**
   - 文字の電子書籍を、紙と同じ道に載せます。
   - 足すのは3つだけです：本ごとの「電子書籍」の印、「どこ」の単位（ページ、位置No.、%）、スクショから行を押す道。
   - 同じ iPhone で読む夜は、Live Activity の「終える」1つで閉じます。
   - v1.1 に回す候補：共有シートと、読むアプリを開くこと。
2. **おすすめ**
   - 枠の名前は「次の1冊」のままにし、理由の行に本当の出どころを書きます。
   - 置き場所は3つです。
     - 読み終えた夜（S-9）
     - 今の本がない夜の S-1（積読だけ）
     - 読み終えた本の画面 S-7 の「この本のあとに」（本棚にない本を5冊まで。開いたときだけ）
   - 「これを読んだ人は」は、v2 で本当の人数を出せるときに、同じ行の理由として増やします。
3. **バーコード**
   - Takuma の問い「一括取得はやはり難しい？」への答え：画面の作りは難しくありません。難しいのはデータの側です（大きさ、更新、新刊の穴、出どころの表示）。tech-lead が調べています。
   - 書誌データを同梱するなら（案 C）、通信なしで前の S-8a と同じ速さ（10冊で40〜60秒）に戻せます。
   - 形は「1つのカメラで、バーコードも背も表紙も読む」です。道を選ぶ画面は戻しません。
   - 一覧にない本は、その行で写すか打ちます。名前のない本は加えません。
   - 同梱しないなら、案 G のままバーコードは使いません（通信なしでは番号しか出ないため。rethink の 2-6）。

**案 C（同梱）の有無で変わる所**
| | 案 C なし（案 G のまま） | 案 C あり |
|---|---|---|
| 紙の一括 | 本棚の写真、1冊ずつ写す（10冊で約1〜1.5分） | ＋バーコード（10冊で40〜60秒） |
| 名前を打つ | 打つだけ | 3〜5字で一覧から候補が出る（電子書籍にも効く） |
| 奥付 | 読み終えた夜に写す | ほぼ自動で入る。写すのは、足りない行があるときだけ（一覧にない本、電子書籍） |
| 本棚にない本のおすすめ | 受賞の一覧から（次の回、前の回） | ＋同じ著者の本、シリーズの次の巻 |
| 「同じレーベル」の理由 | 奥付を写した本だけ | 一覧にある本なら出る（rethink の反論3が消える） |
| 設定の「書誌の出どころ」 | 消す | 残す（CC BY） |

絵コンテの下書き（文字の図。15コマと手間の表）
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/expand-design/storyboard.md
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/expand-design/storyboard.html
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/expand-design/storyboard.png（1500×3600。下の方は余白）

---

## 1. デジタル書籍の体験

### 1-1 調べてわかった前提
- **日本の電子書籍の9割近くは漫画です。**
  - 2025年度は6,846億円。そのうちコミックが6,010億円（87.8%）、文字もの等（文芸、実用書、写真集など）が615億円です（R-75）。
  - 「続きの一行」は文字の本の形です。対象は文字の電子書籍にし、漫画を入れるかは Takuma に聞きます（4 の 4）。
- **電子書籍の「どこ」はページとは限りません。**
  - Kindle は、紙の版に合わせたページ（対応する本だけ）と「位置」を出します（R-74）。ただしこれは2011年の英語の記事で、検索結果の要約で読みました。日本語の今の表示は見ていません。
  - 進み具合は % でも出ます（同じ要約）。
  - Apple Books のページは、文字の大きさで変わると考えています［推測］。
  - そこで、% をページに換算しません。本が出す数字を、そのままの単位で残します（性格語「確か」）。
- **Apple Books の引用の共有は米国だけです**（「Sharing book quotes is only available in the United States.」R-73）。日本では、この道に頼れません。
- **同じ iPhone で、ほかのアプリで読んでいるかを、アプリは知れません**［推測］。
  - 知るには Screen Time の API（Family Controls）が要り、PRD S-4 で承認の重さを理由に捨てています。
  - そのため、始めと終わりは人が押します。または、ショートカットのオートメーション「App：Is Opened / Is Closed」（R-70）を、利用者が自分で組みます。
- **Live Activity**
  - ボタンは1つが望ましく（「prefer limiting it to a single element」）、8時間までの用途です。終わったあとの要約は15〜30分でよい、とあります（R-67）。
  - LiveActivityIntent は、アプリを開かずに動きます（R-68）。
  - OpenURLIntent が開けるのは自分のアプリの universal link だけで、ほかのアプリは開けません（R-69）。Kindle を開けるのは、よむまが前にあるときに URL スキームを使う場合だけです。そのスキームは確かめていません［推測］。
- **Safari の共有の拡張は、開いているページで JS を走らせ、結果を受け取れます**（R-72）。書店のページの題を、よむまが通信せずに受け取れます。

### 1-2 推す形：読む場所ごと
| 読む場所 | 夜の道 | 続きの一行と「どこ」 | 加える |
|---|---|---|---|
| (a) Kindle 端末や iPad。iPhone はしおり役 | 紙と同じ。伏せる道も使える | 端末の画面を撮る（撮る道。e-ink は白黒で読みやすいと見込む［推測］）か打つ。単位は位置No. か % | スクショ（端末の画面を撮る）、打つ |
| (b) 同じ iPhone の Kindle や Apple Books | 一行を押す → S-1「読み始める」で計り始める → Kindle に移って読む → Live Activity の「終える」か、戻って S-2 の「終える」 | 止めた所でスクショを撮る → S-3「スクリーンショットから一行」→ 列を押す。画面の下の「位置No.」や % を読めたら先に入れる［推測］ | ライブラリか書店のページのスクショで、書名を押す（何冊でも）。打つ。共有（v1.1） |
| 紙 | 今のまま | 今のまま（単位はページ） | 案 G（＋案 C ならバーコード） |

(b) の細かい形
- **S-1**
  - 書名の下に「恩田陸・電子書籍」と出します。「どこ」は「34%」か「位置1234」です。
  - 伏せる案内は「ほかの端末で読むときは、iPhone を伏せて置いても始まります。」に替えます。
  - 「読み始める」は計り始めるだけです。読むアプリを開くのは v1.1 にします（URL スキームが確かめられたら）。
- **S-2**
  - 押せる要素は「終える」1つのままにします（AC-43）。
  - 電子書籍の本のときだけ、文を1行足します：「Kindle で読んでいます。止めるところでスクリーンショットを撮ると、一行を選べます。」
- **Live Activity**
  - 押せるのは「終える」1つです（R-67）。
  - 押すと、アプリを開かずに記録します（R-68）。そのあと15分だけ「12分 読みました」の要約に替わり、要約を押すと S-3 が開きます。押さなければ、しおりは前のままです（「あとで挟む」と同じ）。
  - 外から終えたときの扱いは PRD の (5) に従います。該当する AC は今回は読んでいません。
- **S-3**
  - 電子書籍の本のときは、主の道を「スクリーンショットから一行」（PhotosPicker の .screenshots、新しい順）にします。
  - ほかの道は「位置か%だけ入れる」「あとで挟む」です。
- **S-3b**：電子書籍の本だけ、単位の Picker（.segmented：ページ、位置No.、%）を出します。単位は本ごとに覚えます。
- **ウィジェット**：縦書きの明朝の一行はそのままです。ノンブルの位置に「34%」か「位置1234」を出します。
- **奥付**
  - 電子版にも奥付があると考えています［推測。実物は見ていない］。
  - 読み終えた夜は最後の画面をスクショし、「奥付を写して足す」→「写真から選ぶ」で取ります。
- **加えるときの印**：「電子書籍で読む」の Toggle を置きます。スクショから加えたときは先にオンにし、利用者が切り替えられます。S-7a でも直せます。

**ショートカットのオートメーション（v1.1 の案内の候補）**
- 「Kindle を開いたら読み始める」「閉じたら終える」は、利用者が自分で組めます（R-70）。v1.0 の App Intents があれば、作る物は案内の文だけです。
- いちばん強い反論は、「Is Closed」が「switch from」（ほかのアプリへ移ったとき）でも動くことです。LINE を一瞬見ただけで終わってしまいます。だから既定にはせず、案内にとどめます。

### 1-3 流れと手間（秒は［推測］）
| 場面 | 手順 | 押す回数 | 秒 |
|---|---|---|---|
| 1冊を加える（スクショ） | スクショ → 本を加える → 写真から選ぶ → 1枚 → 書名 →（著者）→ 加える | 5〜6 | 10〜15 |
| 5冊を加える（ライブラリのスクショ） | スクショ → 写真から選ぶ → 1枚 → 書名を5回 → 加える | 8 | 15〜25 |
| 1冊を加える（打つ。案 C の候補あり） | 3〜5字 → 候補 → 加える | 3＋字 | 6〜10 |
| 1冊を加える（共有。v1.1） | 書店のページで共有 → よむま → 確かめ → 加える | 3 | 4〜6 |
| (b) 始める | 一行を押す → 読み始める | 2 | 3〜5（Kindle へ自分で移るのに＋3） |
| (b) 終える | 終える → S-3 → スクショから一行 → 1枚 → 列 → 挟む | 5 | 8〜12（%だけなら4〜6、あとでなら1） |
| (a) | 紙と同じ（伏せるなら0操作） | ― | 紙と同じ |
| 読み終えた夜の奥付 | スクショ → 読み終えた → 奥付を写して足す → 写真から → 行 | 5 | 10〜15 |

### 1-4 「紙の側」との折り合い
- research の 5 では、「紙の側」は「紙の本の慣習（縦書き、しおり、奥付、明朝）を、組みの決まりとして借りる」ことでした。素材のことではありません。
- 日本語の文芸の電子書籍も、縦組みと奥付を持つと考えています［推測］。電子書籍は「紙の慣習の上にある本」として扱えます。変えるのは「どこ」の単位だけで、一行の縦書きと奥付の型はそのままです。
- 性格語の表の「意味しないこと」に「紙の本でないと使えないこと」を足す案です。
- ADA の Inclusivity：電子書籍は文字を大きくでき、目の弱い人の読書の道になります［推測。出典は開いていない］。対応する意味は大きいと考えます。

### 1-5 性格語との合い方
| 性格語 | どこに表れるか |
|---|---|
| 静か | Live Activity のボタンは「終える」1つ。要約は15分で消える。読むアプリの中に何も足さない |
| 確か | % をページに換算しない。単位をそのまま出す。スクショは残さない（AC-69 の型） |
| まっすぐ | 紙と同じ「写して押す」部品。電子だけの画面を作らない |
| 急かさない | 自動で始めて終えること（オートメーション）を既定にしない。しおりは「あとで」でよい |
| 紙の側 | 縦書きの一行、ノンブルの位置、電子版の奥付 |

### 1-6 v1.0 と v1.1 の分け方（推奨）
- **v1.0**（今ある部品の上に乗る）
  - 「電子書籍」の印と単位
  - スクショの道（加える、一行、奥付）。PhotosPicker の .screenshots
  - S-2 と S-1 の文
  - Live Activity の「終える」と要約（(5) の中）
- **v1.1**（新しい入口で、確かめが要る）
  - 共有の拡張（新しい target で、書店のページごとに題の形が違う）
  - 読むアプリを開くこと（URL スキームが未確認）
  - オートメーションの案内
- 理由：v1.0 はどの電子書籍アプリでも同じに動きます（スクショは OS の機能）。v1.1 の3つは、アプリごと・ページごとの違いに頼ります。

### 1-7 今の仕様と PRD への影響（見当）
- **PRD**
  - 10 の「電子書籍に合わせた作り：紙の本の体験に絞る」を外します（pdm）。
  - 「ページ」を「どこ（値と単位）」に広げます。効く所は、ウィジェットの AC（AC-29 の周り）、S-3b、S-4 の「p.43 → p.61」、Siri の答え（「34%です」）。
  - 加える AC の候補：電子の印、単位、スクショから一行、スクショから何冊も、Live Activity の要約。
- **画面**：W-1、W-2、S-1、S-2、S-3、S-3b、写す画面、S-7a、奥付を写す画面。
- **識別子の案**：`book.format.ebook`（Toggle）、`mark.unit`（Picker）、`mark.screenshot`（Button）、`reading.ebookNote`（Text）。
- **文言の案**
| キー | 日本語 | 英語 |
|---|---|---|
| `book.format.ebook` | 電子書籍で読む | Reading as an Ebook |
| `book.format.ebookShort` | 電子書籍 | Ebook |
| `mark.screenshot` | スクリーンショットから一行 | Pick a Line from a Screenshot |
| `mark.unitOnly` | 位置か%だけ入れる | Enter Location or % Only |
| `mark.unit.page` / `.location` / `.percent` | ページ / 位置No. / % | Page / Location / % |
| `reading.ebookNote` | 電子書籍で読んでいます。止めるところでスクリーンショットを撮ると、一行を選べます。 | You're reading an ebook. Take a screenshot where you stop to pick a line from it. |
| `bookmark.flipHint.ebook` | ほかの端末で読むときは、iPhone を伏せて置いても始まります。 | Reading on another device? Place iPhone face down to start. |
| `liveActivity.endedSummary` | %d分 読みました（複数形） | Read for %d min |

- **アクセシビリティ**
  - 単位の Picker のラベルは「単位」にします。
  - Live Activity のボタンは「読書を終える」と読ませます。
  - スクショの列の選び方は、撮る道と同じ扱いです（列を読む順、操作「一行にする」、AX1 以上では一覧に替える）。

---

## 2. おすすめの見せ方

### 2-1 前提
- PRD 10 の決まり
  - 「これを読んだ人は」の名は、人数がそろうまで使いません。
  - 新しい本は最大1冊で、「積読に加える」まで。書店へのリンクと表紙の画像は出しません。
- 手本
  - Apple Books の For You は、いつでも開ける選んだ棚です（「Browse curated collections and get personalized recommendations.」R-76）。
  - 紙の本屋では、手書き風の POP が重宝されます（R-78）。本屋大賞は、書店員が「いちばん！売りたい本」を選びます（R-77）。図書館には読書相談があります（R-79）。
  - 共通するのは、「人が、理由を自分の言葉で書いている」ことです。サーバーのない v1 は人の代わりに、確かめられる事実を1行で書きます。これが「おすすめ」と呼んで恥ずかしくない最低の線だと考えます（性格語「確か」、Rams の honest R-35）。
- 「なぜこれを勧めるか」を利用者に説明することの研究の文は、見つけられませんでした（NN/g の該当記事は検索で出ず、arXiv 2103.08786 の要旨には該当の文がなかった）。根拠は R-35 と性格語に置きます。

### 2-2 推す形
- **名前**
  - 枠は「次の1冊」（S-9 と S-1）と「この本のあとに」（S-7）です。「おすすめ」「あなたへ」とは書きません。
  - 「おすすめらしさ」は、名前でなく3つで出します：理由の1行、本棚にない本を出すこと、出す時（読み終えた夜）。
- **置き場所**
  1. **S-9 読み終えた夜**
     - 今のまま、3冊まで。積読が先で、本棚にない本は最大1冊、いちばん下に置きます。
     - 案 C があれば、本棚にない本の出どころが増えます。順は、シリーズの次の巻 → 次の回の同じ賞 → 同じ著者の本（新しい順）の案です［推測］。
     - 見出しの下の文は「積読と、この本の先から選んでいます。」にします。
  2. **S-1 の今の本がない夜（新しい）**
     - S-9 で選ばずに閉じた翌晩に、積読だけで3冊まで、同じ行の形で出します。
     - 3b の失敗の形（読み終えた夜に次の本が決まらず、翌晩の入口が空になる）を防ぎます。
     - 今の本があるときは出しません（AC-86）。積読も0冊なら、今の ContentUnavailableView のままです。
  3. **S-7 読み終えた本の画面「この本のあとに」（新しい。開いたときだけ）**
     - 本棚にない本を5冊までで、「積読に加える」まで。「もっと見る」は置きません。
     - 案 C がなくても、受賞の一覧（AC-112）から「前の回」「次の回」の2冊までは出せます。
- **出さない所**：ウィジェット、Live Activity、通知、今の本があるときの S-1、本棚の上、読書中、しおりを挟む画面。
- **本棚にない本の見せ方**
  - 書名（.headline）、著者と出版年（.subheadline）、理由（.subheadline の2つ目の色）、「積読に加える」（.bordered）。
  - 表紙の画像は出しません。押したあとは、押せない文字の「積読にあります」に替えます。
- **理由の1行**（事実だけ。「・」でつなぎ、読み上げでは「、」にする）
| キー | 日本語 | 英語 |
|---|---|---|
| `next.reason.seriesNext` | シリーズの次の巻（%@） | Next in the Series (%@) |
| `next.reason.awardNext` | 次の回の%@（第%d回） | Next %@ Winner (No. %d) |
| `next.reason.awardPrev` | 前の回の%@（第%d回） | Previous %@ Winner (No. %d) |
| `next.reason.authorOther` | 同じ著者の本 | Also by This Author |
| `next.reason.sameAward` | 積読から・同じ賞（%@） | From Your Pile · Same Award (%@) |
| `after.header` | この本のあとに | After This Book |
| `after.subheader` | 同じ著者、シリーズ、同じ賞から。本棚にない本です。 | From the same author, series, or award. Not on your shelf. |
| `after.inPile` | 積読にあります | In Your Pile |
| `next.subheader.withNew` | 積読と、この本の先から選んでいます。 | Picked from your pile and books that follow this one. |
| `bookmark.noCurrent.next` | 積読から、次の1冊を選べます。 | Choose your next book from your pile. |
- **v2 での増やし方**
  - 同じ行の形のまま、理由の行に「この本を読み終えた34人のうち9人が、次に読んだ本」を足します。人数の線は v2 の PRD で決めます。
  - v1.x の友人なら「ゆうこさんが、この本の次に読んだ本」です（integrate-designer 3-2 の段2）。
  - 「これを読んだ人は」の言葉は、この理由の行と、S-7 の節の名前にだけ使います。
- **識別子の案**：`bookmark.next.candidate.<id>`、`after.candidate.<key>`、`after.reason`、`after.addToShelf`、`after.inPile`。
- **AX5**：行の中で横に並べたボタンを、文の下に移します。

### 2-3 流れと手間
| 場面 | 操作 | 押す回数 |
|---|---|---|
| 読み終えた夜に積読の本を選ぶ | S-9「この本を読む」 | 1 |
| 本棚にない本を積読に加える | S-9 か S-7 の「積読に加える」 | 1 |
| 翌晩に選ぶ（S-9 を閉じたとき） | ウィジェット → S-1「この本を読む」 | 2 |
| 読み終えた本からたどる | 本棚 → 本 → 下へ送る → 積読に加える | 3 |

### 2-4 性格語との合い方
- 急かさない：出すのは読み終えた夜と、自分で開いた本の画面だけです。本棚にない本は S-9 で1冊、S-7 で5冊が上限です。
- 確か：理由は事実1行で、出どころを書きます。人数のない「これを読んだ人は」は使いません。
- 紙の側：本屋の POP、司書の読書相談の型です。表紙でなく文字で見せます。
- 静か：バッジ、新着の印、通知はありません。

### 2-5 今の仕様と PRD への影響（見当）
- **PRD 10 の「新しい本を何冊も勧めること」**：S-7 の、開いたときの5冊だけを緩めます（pdm が書き、Takuma が決める）。
- **足す AC の候補**：S-1 の今の本がない夜の候補、S-7 の節、新しい理由の種類（シリーズの次の巻、同じ著者の本、前と次の回の同じ賞）。
- **データ**（tech-lead）：案 C で、シリーズと巻、著者の同じさ（同じ名前の別人）をどこまで取れるか。
- **画面**：S-9 の見出しの下の文、S-1 の今の本がないときの形（ContentUnavailableView から、候補の行と「本棚から選ぶ」へ）、S-7 に節を1つ。

---

## 3. バーコードでの一括取得（案 C があるとき）

### 3-1 推す形
- **1つのカメラで、バーコード（978、979 の EAN-13）も、背と表紙の字も読みます。**
  - DataScanner は、字（URL）と QR コードを1つで読む例を出しています（R-80）。
  - 道を選ぶ画面（前の S-8）は戻しません。向けたものを読むだけです。
- バーコードを読むと、行に書名、著者、レーベルがすぐ出ます。触覚は1回で、同じ ISBN は1回だけです。2段目のコードは使いません。
- **一覧にない本**
  - 行に「一覧にない本です（2026年9月までの本が入っています）」と出し、その行だけに「表紙を写す」「名前を打つ」（.bordered）を置きます。
  - 「見つかりません」でなく、何が入っているかを正直に書きます。
- **名前のない本は加えません**（「あとで」は今の本だけ、という決定を守る）。
  - 加えるボタンは「3冊を積読に加える」で、名前のある本だけを数えます。
  - 名前のない本を残して閉じるときは confirmationDialog を出します（「名前のない1冊は加えません。」／3冊を加えて閉じる／名前を入れる／キャンセル）。
- **加えるときに書誌がそろう**ので、「奥付で送る」は「足りない行があるときだけ写す」に縮みます。読み終えた画面の奥付は、一覧の値で埋まります。
- **名前を打つ欄**に、一覧からの候補を出します（3〜5字）。紙の古い本にも電子書籍にも効きます。
- **本棚の写真で押した書名**：一覧と書名がそのまま一致するときだけ、「一覧にある本：『…』（レーベル）」を候補として出す案です［推測］。自動では当てません。違う本を当てる心配があるので、未解決に置きます。
- **設定**：「書誌の出どころ」（CC BY）と、データの日付を出します。

### 3-2 使い分け
| 道 | 合う場面 |
|---|---|
| バーコード（案 C） | 手元に積んだ本、買ってきた本、帯で表紙が読みにくい本、背の細い本。版まで確か |
| 本棚の写真1枚 | 棚に並んだまま（抜かない）の何冊も。背が読める本 |
| 1冊ずつ写す（案 G） | バーコードのない古い本、一覧にない新刊 |
| スクショ | 電子書籍 |
| 打つ（候補つき） | 手元にない本、図書館の本、どれも読めないとき |

### 3-3 流れと手間（秒は［推測］）
| 場面 | 押す回数 | 秒 |
|---|---|---|
| 10冊。全部一覧にある | 2 | 40〜60 |
| 10冊。2冊が一覧にない | 6〜8 | 55〜90 |
| 本棚の写真で10冊 | 12 | 30〜60 |
| 1冊ずつ写して10冊（案 G） | 30〜40 | 60〜90 |
| 前の国立国会図書館の形（使わない） | ― | 40〜60 |

### 3-4 7つの状態（写す画面のバーコードの分）
- **通常**：映像と、読めた行の一覧。
- **空**：「本の裏のバーコードか、背か表紙を写してください。」
- **読み込み中**：一覧の準備中（初めての起動など。届け方は tech-lead）。行は ISBN で出し、準備ができたら名前を入れます。読むのは止めません。
- **エラー**
  - 保存に失敗したら知らせを出し、行は残します（AC-91 の型）。
  - 一覧が壊れているときは、どの行も一覧にない本として扱います。
- **オフライン**：なし（通信しない）。一覧をダウンロードで届けるなら、「本の一覧はまだありません。名前を写すか打って加えられます。」
- **権限を断られたとき**：`camera.denied`、「設定を開く」「写真から選ぶ」「名前を打つ」。
- **一部だけ**：一覧にない行だけ、その場で名前を入れます。

### 3-5 性格語との合い方
- まっすぐ：道を選ばず、向けるだけです。
- 確か：版まで分かります。一覧にない理由を、日付つきで言います。名前のない本を作りません。
- 急かさない：一覧にない本は、加えずに閉じられます。
- 紙の側：本の裏のバーコードと、背の字の両方が、本そのものの印です。

### 3-6 今の仕様と PRD への影響（見当）
- 案 G の「本を写す」画面に、バーコードの行を足します。AC-3 の型（続けて読み、1冊ごとのボタンなし）を、通信なしで戻します。
- 「名前を打つ」に候補を足します。AC-4〜AC-6（書名で探す）の一部が、通信なしで戻ります。
- 奥付を写す場面が狭まります。設定の出どころの節が残ります（rethink の 4-5 の「S-10 から消す」を取り消す）。
- 決定 26（閉じるときの確認）は、名前のない本が残るときだけの確認に替えます。

---

## 4. Takuma に決めてほしいこと

1. **電子書籍の範囲と、v1.0 と v1.1 の分け方**
   - 推奨
     - 文字の電子書籍を、v1.0 で紙と同じ道に載せる：電子の印、位置と %、スクショで加える・一行・奥付、Live Activity の「終える」と要約。
     - 共有シート、読むアプリを開くこと、オートメーションの案内は v1.1。
   - いちばん強い反論
     - Takuma は「全部 v1.0」と決めました。書店のページから共有して加えるのは、ほかのアプリでも当たり前かもしれません［推測。確かめていない］。
     - 同じ iPhone で読む人は、終える前にスクショを撮る手間が要ります。
   - 元に戻せるか：はい。v1.1 の3つは、今の部品に足すだけです。
   - 見てほしいファイル：この報告の 1、絵コンテの A と B。
2. **おすすめの置き場所と名前**
   - 推奨
     - 名前は「次の1冊」のままにする。置き場所は S-9（3冊。本棚にない本は1冊）、S-1 の今の本がない夜（積読だけ3冊）、S-7 の「この本のあとに」（本棚にない本を5冊。開いたときだけ）。
     - 「これを読んだ人は」は、v2 で人数があるときの理由の行として足す。
   - いちばん強い反論
     - Takuma の言う「おすすめ」より控えめです。
     - S-7 の5冊は、PRD 10 の「新しい本を何冊も勧めない」を緩め、積読を増やす向きに働きます（E-7）。
   - 元に戻せるか：はい。S-7 の節を外せば、今の PRD に戻ります。
   - 見てほしいファイル：この報告の 2、絵コンテの C。
3. **案 C（書誌データの同梱）が入るときの登録**
   - 推奨
     - 1つのカメラでバーコードも背も読む（道を選ぶ画面を戻さない）。
     - 一覧にない本は、その行で写すか打つ。名前のない本は加えない。名前を打つ欄に候補を出す。奥付を写すのは足りないときだけ。
   - いちばん強い反論
     - 「見つからない」（新刊の穴）が戻ります。
     - 出どころの表示も戻ります。
     - 「奥付を自分の一冊から写す」という読み終えた夜の瞬間が薄れます。
   - 元に戻せるか：はい。案 C を採らなければ案 G のままです。
   - 見てほしいファイル：この報告の 3、絵コンテの D。データの判断は tech-lead の報告。
4. **「デジタル書籍」に、漫画とオーディオブックを入れるか**
   - 推奨：入れない（文字の本だけ）。漫画には「続きの一行」がなく、オーディオブックには「一行」も「伏せる」もありません。
   - いちばん強い反論：日本の電子書籍の87.8%は漫画です（R-75）。Takuma の「メイン」が漫画を含むなら、対象の層が変わります。
   - 元に戻せるか：はい。

---

## 5. 手本と出典（確認日はすべて 2026-10-20）
| R | 種類 | 引用 | 出典 | 取り入れること |
|---|---|---|---|---|
| R-67 | HIG | 「If you offer interactivity, prefer limiting it to a single element」「don't exceed eight hours」「In most cases, 15 to 30 minutes is adequate.」「Offer an App Shortcut that starts your Live Activity.」 | https://developer.apple.com/design/human-interface-guidelines/live-activities | 「終える」1つ、15分の要約 |
| R-68 | Apple | 「the system launches your app process without opening the app, performs the intent」 | https://developer.apple.com/documentation/appintents/liveactivityintent | アプリを開かずに終える |
| R-69 | Apple | 「This app intent uses your app's existing universal link support」「You can also place the app intent on a button in an interactive widget or Live Activity.」 | https://developer.apple.com/documentation/appintents/openurlintent | 外の部品から Kindle は開けない |
| R-70 | Apple サポート | 「Is Opened: Triggers your automation when you open or switch to the selected app.」「Is Closed: Triggers your automation when you close or switch from the selected app.」 | https://support.apple.com/guide/shortcuts/setting-triggers-apde31e9638b/ios | オートメーションは案内だけ（v1.1） |
| R-71 | Apple | PHPickerFilter.screenshots「A filter that represents screenshots.」。WWDC22「The picker runs out of process, so your app doesn't need to request any library access to use it.」 | https://developer.apple.com/documentation/photosui/phpickerfilter-swift.struct 、https://developer.apple.com/videos/play/wwdc2022/10023/ | スクショの道は許可なし |
| R-72 | Apple | 「In Share extensions … you can give users access to web content by asking Safari to run a JavaScript file and return the results to the extension.」 | https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html | 共有で題を受け取る（v1.1） |
| R-73 | Apple サポート | 「Sharing book quotes is only available in the United States.」「A quote can include up to 200 words.」 | https://support.apple.com/guide/books/ibks3b8c08a0/mac | 引用の共有に頼らない |
| R-74 | 記事（2011） | 「The Kindle apps will now display both page numbers, based on a certain print edition of the book, and the old standard Kindle "locations"」（検索の要約で読んだ。ページは開いていない） | https://www.macworld.com/article/210714/kindle-app-real-pages.html | 単位を3つ持つ |
| R-75 | 市場 | 「2025年度の電子書籍市場規模は、前年度比2.1%増の6846億円」「市場の87.8%を占めるコミックが…6010億円、文字もの等（文芸・実用書・写真集等）が…615億円」 | https://prtimes.jp/main/html/rd/p/000007525.000005875.html | 対象は文字の本。漫画は Takuma に聞く |
| R-76 | Apple | 「Browse curated collections and get personalized recommendations.」「The For You collection is a curated list of audiobooks, ebooks, authors, and a Weekly Top 5」 | https://www.apple.com/apple-books/ | いつでも開ける棚にはしない |
| R-77 | 紙の慣習 | 本屋大賞「全国書店員が選んだ いちばん！ 売りたい本」、書店員は本と読者を「最もよく知る立場」 | https://ja.wikipedia.org/wiki/本屋大賞 | 理由を言葉で書く |
| R-78 | 紙の慣習 | 「手書き風POPが重宝される業態は、…書店、CDショップなどが挙げられる。」 | https://ja.wikipedia.org/wiki/POP広告 | 理由の1行は POP の役 |
| R-79 | 図書館 | 「日本でも読書相談は館外貸出の一環かレファレンスかが議論される」 | https://ja.wikipedia.org/wiki/レファレンスサービス | 頼まれたら出す（S-7 は開いたときだけ） |
| R-80 | Apple | 「pass the custom types as the recognizedDataTypes parameter … create a data scanner that only recognizes URLs and QR codes.」 | https://developer.apple.com/documentation/visionkit/scanning-data-with-the-camera | 1つのカメラで字もバーコードも |

前から使っているもの：R-8 と R-10（ブクログと読書メーターの連続読み取り）、R-23、R-35、R-36、R-49、R-51、R-56〜R-58、integrate-designer の 3-2。

---

## 変更したファイル
- リポジトリ：なし。
- スクラッチパッド（リポジトリの外）
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/expand-design/storyboard.md：絵コンテの下書き。A 電子書籍の夜（7コマ）、B 電子書籍を加える（3）、C 次の1冊とおすすめ（4）、D バーコード（2）、手間の表。
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/expand-design/storyboard.html：上の md を HTML にしたもの。
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/expand-design/storyboard.png：HTML を headless Chrome で写したもの（544,473 バイト）。
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/expand-design/scripts/：docc.py と html2txt.py（前の調べものから写した）、md2html.py（新しく書いた）。
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/expand-design/dl/：落とした Apple の文書の JSON と HTML。

## 実行したコマンドと結果
- **読んだリポジトリのファイル**
  - docs/approvals/001-reading-session-G1-decisions.md（全文）
  - docs/reviews/001-reading-session-rethink-proposal.md、biblio-alt-proposal.md（全文）
  - rethink-designer.md（1〜7）、integrate-designer.md（3、4）
  - design/001-reading-session.md（0〜3、5 の S-1 と S-9、6 と 7 の next の行）、design/001-reading-session/screens.md（S-9、S-10）
  - design/001-reading-session-research.md（2、5、6、R の一覧）
  - docs/prd/001-reading-session.md（5、9、10、AC-77〜AC-87）、docs/prd/product.md（5 の版の地図）
  - apple-intelligence-designer.md と G0-Q8.md は、見出しだけ見て本文は読んでいない。
- **開けた URL**
  - curl で HTTP 200：LiveActivityIntent、OpenURLIntent、HIG Live Activities、DataScannerViewController、Scanning data with the camera（いずれも JSON）、PHPickerFilter（.md）、WWDC22 10023、App Extension Programming Guide、Shortcuts の Setting triggers。
  - WebFetch：apple.com/apple-books、Apple Books サポート（Mac）、prtimes の電子書籍市場の発表、arXiv 2103.08786（使える文はなく、使わなかった）。
  - 日本語版 Wikipedia の API：本屋大賞、POP広告、レファレンスサービス、文庫本（「巻末の目録」の記述は見つからず、使わなかった）。
- **開けなかった URL**
  - developer.apple.com/documentation/photosui/phpickerfilter/screenshots（WebFetch で 404）
  - 同じ物の JSON（photosui と photokit の2通り）と phpickerfilter.json（どれも 404）。.md の形で確かめ直した。
  - support.apple.com の event-triggers のページ（App のきっかけの記述なし）
  - create-a-new-personal-automation（curl で 301。追わなかった）
- **WebSearch（8回）**
  - 次の4つは答えが見つからなかった：Kindle の共有で何が渡るか、Apple Books の「Because you read」、NN/g のおすすめの説明、PHPickerFilter の文。
  - Kindle の位置No. は、2011年の英語の記事の要約だけだった。
  - ショートカットの App のきっかけは見つかった。電子書籍市場は prtimes を見つけた。
- **ガード**：書き先のパスに $ を入れたため、2回止められた。パスをそのまま書いて実行し直した。回り道はしていない。
- **絵コンテ**：headless Chrome で PNG にした（Chrome のログに task_policy_set の警告が出たが、画像はできた）。

## 未解決
- **見ていないもの**（どれも実機の確かめが要る。tech-lead）
  - Kindle の iOS アプリの共有で渡るもの
  - Kindle と Apple Books の URL スキーム
  - Kindle の iOS アプリでスクショが撮れるか（DRM で黒くならないか）
  - 日本語の Kindle の「位置No.」と % の今の表示
  - 日本の Apple Books でコピーしたときの引用の文
  - 書店のページの題の形
  - 電子版の奥付の実物
  - e-ink の画面の写真の読み取り
  - スクショの下の数字を読めるか
  - 一覧（案 C）の届け方（同梱か、ダウンロードか）
- **PRD との食い違い**（pdm）
  - 10 の「電子書籍に合わせた作り」と「新しい本を何冊も勧めること」。
  - 「ページ」の欄を「どこ（値と単位）」に広げる。ウィジェット、S-4、Siri の答えの AC に効く。
- **AC-43**：S-2 に「Kindle を開く」ボタンは置けません。開くなら「読み始める」と同時に自動で開くことになり、それは v1.1 の候補です。
- **外から終えたときのしおり**：PRD の (5) の扱いを、今回は読んでいません。
- **著作権**：電子書籍のスクショから一行を取ることは、紙の撮る道と同じ扱い（画像を残さない）でよいか［推測。reviewer］。
- **案 C のデータ**（tech-lead）：シリーズと巻、著者が同じかどうかを取れるか。本棚の写真の書名を一覧と照らす線をどこに引くか。
- **PRD にない提案**（pdm と Takuma が決める）：オートメーションの案内、一覧にある著者の新刊を読み終えた夜に出す案（未検討）。
- **テンプレートの「確かめ」**：印は付けていません。調査と仕様の文書を書かない仕事だったためです。R-67〜R-80 は、Takuma が決めてから design/001-reading-session-research.md に写します。

## 記録（指揮役が保存するときに書き足す）
- 種類：調べものと発想（designer）
- 日付：2026-10-20
- 判定したモデル：opus（fable が使えないとした最初の知らせに従っている）
- 絵コンテの下書き（リポジトリの外）：scratchpad の expand-design/storyboard.png
