# 指揮役の裁定 001-reading-session G1（Mac がないため CI でしか確かめられない動き）

- 日付：2026-10-21
- 対象：docs/reviews/001-reading-session-G1-tech-lead-r1.md の重大1件（未検証の扱い）
- 根拠：docs/org/gates.md:35（G0 の「未確認」には spike の出力か Takuma への質問がある、の読み方）、docs/reviews/001-reading-session-G0-ruling.md（同じ環境の制約）、.claude/rules/org.md（元に戻せる作業だけを進める）

## 裁定
1. この環境に Mac と Xcode がないため、次の動きは G1 では「未検証（G2 の CI の出力で確かめる）」として記録し、G1 を止める理由にしない。各項目には tech-lead r1 の証拠3の代わりの案がある。
   - (a) 根の入れ物の識別子 session.state.* が XCUITest から見えること（代わり：-UITest のときだけ 1pt の要素に識別子を付ける）
   - (b) confirmationDialog、alert、編集モードのボタンに識別子が付くこと（代わり：7章の文字で探す）
   - (c) .contain の行の VoiceOver のアクションに「削除」が出ること（代わり：accessibilityAction(named:)。G4 で人が確かめる）
   - (g) S5 を swipeDown() で閉じられること（代わり：ナビゲーションバーに対して行う）
   - 題名の上限を変換中の文字に当てない作り（代わり：UITextField を包む。作れなければ保存のときに先頭の100字に切る。PRD 10 をその形に直す）
   - AC-49 の sheet を閉じてから push する動き、AC-54 の @Query と ModelContainer の失敗の扱い
   - iOS 26 の confirmationDialog に「キャンセル」が出るか（代わり：外側をタップ。AC-38 の When は CI の出力で1つにそろえる）
2. 基本の部品およそ20件の存在と対応 OS は、tech-lead が r2 で1回の Bash でまとめて開いて閉じる（環境の制約ではないので、裁定の対象にしない）。
3. ios-engineer は、実装の最初の push の後に CI の出力でこれらを確かめ、結果（出た / 出ない、代わりの案を使ったか）を報告に書く。reviewer（コード）はそれを確かめる。確かめられなかったものが G3 まで残れば、G3 は通さない。
4. これらは元に戻せる判断で、Takuma にしかできない操作には関わらない。

## いちばん強い反論と、それでも進める理由
- 反論：識別子が見えないことが実装の後に分かると、受け入れテストと実装の両方を直すことになり、手戻りが大きい。
- それでも進める理由：どの項目にも代わりの案があり、どちらの作りでも PRD の AC は変わらない。確かめる手段（CI の macOS）は実装の最初の push で手に入る。待つ理由がない。

## 追記（2026-10-21、tech-lead r2 の要修正1）
裁定1の一覧に次の3つを足す。どれも Mac がないため G2 の CI の出力（スクリーンショット）で確かめ、ios-engineer が結果と使った代わりの案を報告に書く。
- D-46：ツールバーの .borderedProminent に付けた .tint(color.accent.fill) と .foregroundStyle(color.text.onAccent) を iOS 26 のツールバーが使うか。代わり（2段）：ラベルの色だけ無視されたら Asset Catalog の代わりの値（design/tokens.md）に替える。塗りも無視されたら確定のボタンを .confirmationAction の文字のボタンに戻す（AccentColor = color.accent.text）。
- D-48：List、Form、LabeledContent、ContentUnavailableView、ProgressView が既定で付ける secondaryLabel を、中の Text の .foregroundStyle（Color の値）で替えられるか。代わり：その所だけ標準の Text の並びにし、.accessibilityElement(children: .combine) でまとめる。
- D-53：ToolbarItemPlacement.keyboard が .numberPad のキーボードとシートの中で出るか。代わり：(a) safeAreaInset(edge: .bottom) に .bordered の「保存」、(b) D-53 をやめる（結び付いた AC はない）。
