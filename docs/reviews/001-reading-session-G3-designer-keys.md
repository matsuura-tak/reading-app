# 001-reading-session G3 文言キーと字の大きさの直し（designer）：指揮役の記録

- 日付：2026-11-02。BASE 73d124c。
- designer は60手の上限で止まり、報告を返さなかった。この文書は、指揮役が差分（design/001-reading-session.md +86/−、screens.md、tokens.md）を読んでまとめた記録で、designer の報告ではない。

## 差分から読み取れる直し
- 決定 82〜86 を足した。
  - 82：読書時間はどこでも分のまま（`duration.minutes`。「85分」「1440分」）。時間に直すのは `finish.reflection.multi` の括弧の中だけ。PRD の AC-22「合計 85分」、AC-57、AC-127 に合わせた。決まり 57 も直した。
  - 83：時刻（S-2 の `reading.startedAt`、W-3 の `liveActivity.readingSince`）はシステムの短い時刻の書式を `%@` に入れ、手で「22時0分」と組まない。
  - 84：インテントの声の文（`intent.start.noCurrent`「今の本がありません。よむまを開きます。」、`intent.end.completed`「読書を終えました。」、`session.start.error`）は1〜2文の事実だけ。書名・一行・分数・場所を入れない。Siri から動くので「押して」ではなく「試して」。
  - 85：推薦の理由は、軸（共起・次の巻・同じ著者・同じ賞・同じレーベル）と「積読にある本か」の組ごとに1つのキー（`next.reason.*`、`rec.reason.*`）。コードで「積読から・」をつながない。名前が空の軸は使わない。
  - 86：W-1・W-2 とその見本（S-5、S-10a）の固定の字の大きさについて、監査の「Dynamic Type font sizes are unsupported」を例外として受け入れる（指揮役の裁定。理由は 9章）。
- 7章に足したキー：`intent.start.noCurrent`、`intent.end.completed`、`result.summary.{pages,locations,percents}.first`、`result.summary.spoken`、`result.summary.first.spoken`、`liveActivity.readingSince`（「%@ から読書中」／"Reading since %@"）、`liveActivity.ended.summary`、`liveActivity.ended.spoken`、`duration.*.spoken`、`duration.hours`、`common.loading`、`next.reason.readers`、`next.reason.nextVolume`、`rec.reason.sameLabel`、`book.total` など。
- 7章で文を直したキー：`session.start.error`（「…もう一度「読み始める」を試してください。」）。見直して値を変えなかったキー：`session.tooShort`、`session.save.error`、`common.save.error`、`colophon.capture`（en "Scan Colophon"）。
- 6章：W-3・S-2・S-4・S-7 の読み上げを直した。S-4 は `result.summary.spoken`（「p.」を「ページ」に置き換えて作らない）。
- screens.md：W-3 の終えた直後を `liveActivity.ended.summary`、S-4 の前の場所なしを `result.summary.*.first`、`result.summary` に仮の値（「15分」など）を入れない、S-7 の「合計 85分」。
- tokens.md：`type.book.line.widget.rectangular` と `.small` を契約「H22 の組み方」の値にそろえた（14字は 17pt・1列4字×4列、かな25字は 172×76 で 15pt・153×68 で 13pt、L＝5。W-2 は 20pt／19pt）。

## 指揮役の確かめ
- 古い値（「1列5字×5列＝25字」の 17pt、「1列6字×5列」）は tokens.md に残っていない。
- 「1時間25分」は、直した経緯を書いた所にしか残っていない。
- 推薦の理由のキー（`next.reason.*` 6個、`rec.reason.*` 5個）が7章の表にそろっている。

## 指揮役の裁定
- designer の直しを、このまま受け入れる（報告はないが、頼んだ1〜5の項目が差分にそろっている）。
- 決定 82（分のまま）は PRD の AC に合うので受け入れる。S-7 の「合計 85分」が読みにくいなら PRD 側の判断になる、という designer の注記は、完成後の Takuma の確認で伝える。
- 次は ios-engineer の8体目が、String Catalog とコードを design/ 7 にそろえる。`session.start.error` の文が変わったので、受け入れテストが全文を比べていれば verifier r3 が直す。
