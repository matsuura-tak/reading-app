# 001-reading-session G3 豆腐と文言の移行（ios-engineer 9体目、途中）：指揮役の記録

- 日付：2026-11-02。BASE 1b5d441。9体目は100手の上限で止まり、報告を返さなかった。この文書は指揮役が作業の木と scratchpad/r9b を読んでまとめた記録。
- 作業の木の変更（コミットしていない）：ios/ の15ファイル、+3562/−321。
  - ThemeTokens.swift：`BookTextFormat`（`colophon.publisher.withLabel`、`colophon.year.value`、`book.nights`、`finish.reflection.*`、`duration.hoursMinutes`）と、`japaneseTextTypesetting()`（`typesettingLanguage(ja)`）を足した。
  - ReadingApp.swift：画面の根に `.japaneseTextTypesetting()`。
  - コードのコメントに書かれた見立て：端末の言語が英語だけのとき、システムの書体の置き換えは漢字・かなを中国語の書体（PingFang SC）へ回す。組みの言語を日本語にすると、ヒラギノ角ゴになる。
  - Localizable.xcstrings：444キー、ja/en の欠け0（指揮役が数えた）。`AppL10n.pick` は残り25か所（BookRegistration 2、BookmarkHome 2、BookmarkMarkFlow 3、SessionResultAndGuide 1、SettingsAndStore 7、ShelfAndBookDetail 8、ノート 2）。
- 指揮役の確かめ
  - scratchpad/r9b/new1_S1_en.png（英語の設定の S-1）：日本語の書名「羅生門」、著者、縦書きの一行が正しく描けている。ボタンは英語。
  - `make ios-build`（指揮役が動かした。ログ scratchpad/r9b/orch-build.log）：**失敗**。`FinishNightView.swift:40:41: error: value of type 'ReadingDataStore' has no member 'buildFinishReflection'`。作業の途中で止まっている。
  - S-9 の豆腐（□）が直ったかは、まだ撮っていない。
- 指揮役の裁定：ビルドが通らないのでコミットしない。10体目が、この作業の木から続ける。
