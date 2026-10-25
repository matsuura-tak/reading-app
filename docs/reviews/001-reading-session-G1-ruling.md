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

## 追記2（2026-10-21、reviewer r1 の重大1と要修正4）
### 裁定1の一覧に足す項目（G2 の最初の CI の出力で確かめ、ios-engineer が結果と代わりの案を報告に書く）
- (1) XcodeGen を入れた出力とビルドの出力（設計メモの確かめ（A）の9）。
- (2) D-60 の、スワイプで閉じたシートを同じ値で開き直す動き。代わり：開き直せなければ、やめる保存の失敗のときだけシートを閉じないようにする（AC-48 の見え方は変わらない）。
- (3) シミュレーターの名前。代わり：`xcrun simctl list devices available` の出力から決め、CLAUDE.md と app.json の値を直す（app.json は Takuma）。
- (4) 手で書いた .xctestplan が -testPlan で動くか。代わり：Xcode の形に合わせて書き直す。
- (5) CODE_SIGNING_ALLOWED=NO で UI テストが動くか。代わり：シミュレーター向けの自動署名を許す設定に変える。
- (6) macos-latest の Xcode が 26 か。代わり：`xcode-select` で 26 を選ぶ行をコマンドに足す（app.json は Takuma）。
- (7) T2 の環境変数の長さ、T16 の open で出る確認、T4 の -AppleLocale、T20 の signpost。代わり：長さは T21（ファイルから読む）、open の確認は URL でなく launchEnvironment の再起動、-AppleLocale は UITEST_LOCALE の環境変数を tech-lead が足す、signpost は AC-5 の値の確かめだけに留める。
- (8) ビルドの設定の名前。代わり：CI の出力のエラーから正しい名前に直す。
- (9) シミュレーターのアプリから localhost の受け口に届くか。代わり：tech-lead が契約に足す（-UITest のときだけ、送ったイベントを並べた要素を accessibilityValue で出し、XCUITest が読む）。
- (10) contracts/README.md の4の macOS のコマンド。
### 要修正4（実装の途中の CI が赤になる期間）
- 実装の変更は、ios-engineer が「できた」と報告した時点の HEAD を1つの変更として G2 に出す。その HEAD で CI が緑であることを求める。途中の push（雛形だけ、AC の一部だけ）は G2 に出さず、赤でもよい。雛形だけの変更を別に G2 に出すことはしない。
- 受け入れテストを先に入れる verifier の変更は gates.md:55 の例外のとおり（スタックの CI は落ちるのが正しい）。
- この裁定は元に戻せる（CI の運用の決めごと）。

## 追記3（2026-10-21、tech-lead の r1 反映で新しく生まれた項目）
裁定1の一覧に足す（G2 の最初の CI の出力で確かめ、ios-engineer が結果と代わりの案を報告に書く）：
- (i) XcodeGen の zip を展開したまま動かして SettingPresets を見つけられるか。`xcodegen --version` の出力の形。代わり：install.sh で写してから動かす、または Mint。
- (ii) XcodeGen の include の合わせ方（testPlans の配列、相対パス）と、target.yml がないときに generate が落ちるか。代わり：relativePaths を false にする。
- (iii) `xcodebuild -version` の1行目の形。代わり：grep を出力に合わせて直す（app.json は Takuma）。
- (iv) uitest.telemetry.log の accessibilityValue の長さの上限。代わり：最後の n 件だけにする。
- (v) TestFlight のビルドに Data Protection の entitlement が入るか、実機で効くか、.complete のファイルが iCloud バックアップに入るか。G4 の前に Mac で確かめる。入らなければ ADR 0001 を開き直す。

## 追記4（2026-10-21、ios-engineer 13b の報告から）
裁定1の一覧に足す（G2 の最初の CI で確かめ、ios-engineer が結果と代わりの案を報告に書く。設計メモ 10 の2つめの表と同じ4点）：
- ContentUnavailableView の中の Text に付けた識別子が残るか（AC-1、AC-54）。代わり：VStack で組み直す。
- String(localized:defaultValue:locale:) で分、冊、件に桁区切りが付くか。代わり：数を先に文字にし、複数形は数の引数で選ぶ。
- 起動時に finishing を戻すとき、S4 の push と同時に S5 を開けるか（AC-34）。代わり：S4 の onAppear の次の描き直しで開く。
- XcodeGen で en が knownRegions に入り、InfoPlist.xcstrings で表示名が地域ごとに替わるか。代わり：project.yml の localizations を明示する。
