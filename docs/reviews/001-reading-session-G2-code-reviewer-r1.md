FAIL

## 指摘
FAIL の理由：重大な指摘は0件。ただし必要な確認のうち、コンパイル、xcodegen generate、ios_build（Release の strings と PlistBuddy）、ios_test（単体テストと受け入れテスト）を実行できていない。この環境には Mac も Xcode もなく、CI もまだ動かない（app.json の commands が空）。craft-reviewer 4 の「必要な確認を1つでも実行できなければ FAIL」に従った。r2 では CI が緑になった HEAD でこの未検証を埋める。

### 重大
なし。

### 要修正
1. 要修正（ADR 0005 と食い違う）：ios/Yomutoki/Screens/RootView.swift:121-129、FinishSessionView.swift:192-200。テストのつなぎ口（session.state.* の 1pt の要素 UITestMarker）を Debug/ の2ファイルの外にある画面のファイルから `#if DEBUG` で呼んでいる。引数 showsStateMarker が Release でも RootView.swift:79-84、ReadingView.swift:195-200、FinishSessionView.swift:7,17-20 を通る。`#if DEBUG` は PreviewSupport.swift:1 と各 Screens の #Preview にもある。根拠：ADR 0005:15、:38。実害：表示の要素とプレビューだけで、本番の答えを変える分岐はない。Release の strings の検査にも引っかからない。直す方向：S5 はシートで表示の階層が別なので根の UITestOverlay だけでは置けない。tech-lead が ADR 0005 と contracts/test-hooks.md の T8 に、この2か所の呼び出しとプレビューを例外として書き足すのが現実的。
2. 要修正（契約が実装より遅れている。直すのは tech-lead）：contracts/data-model.md:56 と LibraryStore.swift:453-467。契約は「ActiveReading の本を先頭」、実装は「前の本を先頭」（指揮役の決定、D-31）。r2 では契約の改訂が実装と同じ順かを最初に確かめる。（指揮役注：コミット f8ccf89 で契約は直っている）

### 提案
3. AddBookView.swift:163-178：二度押しの守りがない（design S2「保存の間は追加を無効」）。保存が通ったら立てる @State を disabled に足す。
4. BookDetailView.swift:307-314、:52-59：S6 の alert のボタンの中で S7 を立てている。版によって出ないことがある（推測。AC-43 は CI）。出なければ onChange で立てる。
5. ReadingView.swift:44-47、:214、RootView.swift:108-114：finishing を戻すときの S5 は S4 の onAppear で開く。AC-34 は CI で確かめる。
6. LibraryStore.swift:237-252、:269-276：finish() と中の discardTooShort()/beginFinish() が今の時刻を別々に読む。経過がちょうど60秒をまたぐと invalidState になり ReadingView.swift:87-91 が黙って捨てる。finish() で読んだ now を中に渡す。
7. ReadingView.swift:278：TimelineView(.periodic(from: active.startedAt)) の起点が AppClock の時刻で、刻みは端末の時刻。-UITest で時計を止めず UITEST_NOW が先のとき書き直しが起きない。起点を .now にする。
8. FinishSessionView.swift:129-154：S5 の欄は HStack で LabeledContent でなく、ViewThatFits もない（design 3、9）。G3 の Double-Length で design-reviewer が判断。
9. BookDetailView.swift:79-96：S3 の読み込み中の ProgressView をすぐ出している（D-39「1秒を超えたら」）。実害は小。
10. AppIcon.appiconset：画像が0件。G5 の前に要る。
11. Swift 6 の既定の分離：Route、FinishDraft、ReadingFailure、FinishFailure、各 Field に nonisolated がない。SE-0434 で通る見込みだが、合わせると CI で詰まる所が減る。
12. LibraryStoreTests.swift:355-374：ActiveReading 2件のテストがメモリの中の保存先。「ファイルが残る」（data-model.md:36）をファイルの保存先で1本足す。
13. 設計メモ:285 の「autosaveEnabled = false が1件」は実際は2件（Debug の SeedWriter）。tech-lead が「本番1件＋Debug 1件」に直す。

## 証拠
- 対象：BASE 477226f...HEAD fd586ac。観点はコード（G2）r1、静的な読みだけ。43ファイル（ios/Yomutoki/ の Swift 21本は全体、plist・xcassets・xcstrings・project.yml・Unit.xctestplan は全体、単体テストは名前・分離・アサーションの数（LibraryStoreTests の一部は全体）、ios/ の外の4件は別の役の文書）。
- 表1 AC 対応表：AC-1〜AC-67 のすべてに実装の場所（ファイル:行）があり、静的な読みで Then を満たす作り。CI で確かめるもの：AC-4、18、34、38、43、48、49（(g)、D-60、(b)、連続の alert）。AC-39 だけ実際に動かして PASS。範囲の外の変更は ios/ の中にない。
- 表2 craft-reviewer の検査：受け入れテストと設定の変更は Unit.xctestplan の1件（ios-engineer の分。ID は md5 と一致）。skip の類8件はすべて SwiftUI の .disabled。アサーション +273/−0。テスト中だけ答えを変える分岐なし（置き場所は要修正1）。テストの入力値の本番の分岐0。ADR 0004 の grep は include の1行だけ。依存0件。秘密情報0。AI の API 0。TODO 0。try!/as!/@unchecked/nonisolated(unsafe) 0。fatalError 3件（Debug の契約どおり）。try? は Debug と Preview だけ。空の catch 0（意図した catch 2件はコメント付き）。設計メモ 11 の grep：階層の形0、autosaveEnabled 2件、Date() は AppClock と Debug だけ、URLSession は Debug だけ、BGTask 等0、NSAllowsArbitraryLoads 0、privacy: .public 1件（操作の名前だけ）、UITEST_ は Debug の2ファイルだけ、色の直書き0。
- 表3 契約と ADR：データモデルは一致（book を Optional で持つのは SwiftData の関係のため。本のない ActiveReading は失敗）。save は1回、rollback、autosave 切、2件以上/知らない state は失敗、題名は形B。つなぎ口の13の名前は一致、fatalError、RESET/SEED、UITEST_FAIL、起動の順、Release の plist に CFBundleURLTypes なし。計測の9イベント・プロパティ・区間は一致、Started/Discarded/Finished は保存が通ったときだけ、Save Failed は失敗ごと、Week Reached 週1回、Restored 起動ごと、本番は端末の中で数えるだけ。ADR 0001〜0004 は合う（SWIFT_DEFAULT_ACTOR_ISOLATION の名前は未確認）。PrivacyInfo は CA92.1 で、理由の文を開いて照合。
- 表4 デザイン：design 6 の73の名前のうち直書きで出ない6件は説明がつく（session.state.* は組み立て、alert の題と本文3件は識別子を付けられない）。コードにあって design にないもの0。String Catalog 75キー＝design 76−book.add.titleLimit（D-57 で正しい）。ja・en の値は全キーで一致。L10n.swift の期待はシステムの文字を除いてすべてある。画面の文字の直書き0。色の4値は tokens.md と一致。D-46〜D-60 はコードの上で満たす（外れは提案3、8、9）。AX5、VoiceOver、動きを減らす設定は design 9 のとおり。
- 表5 Swift 6 と SwiftData：nonisolated の @Model（SE-0449）、既定の MainActor（設定名未確認）、Sendable は問題なし、値の型の分離は提案11、OSAllocatedUnfairLock は問題なし、TimelineView は提案7、onDismiss の push と開き直しは CI、rollback 後の状態は単体テストが確かめる、単体テストの分離は nonisolated の型だけ。
- 実行したコマンド：xcstrings_untranslated.py → 0、exit 0。ac39 → PASS。make contracts-check → exit 0。grep は表2。照合スクリプト（xcstrings と design 7、design 6 と識別子）。md5（YomutokiTests 98117485E2CCBF36B7C54EF6、YomutokiAcceptanceTests DC1C774817D8D1F9A3D54A52）。seed.schema.json の必須の項目と SeedParser の一致。Asset Catalog の値。`gh pr list` → 403。
- 開いた URL（2026-10-21）：describing-use-of-required-reason-api（本文は取れず、.json は概要）、nsprivacyaccessedapitypereasons.json（CA92.1 の文を照合）、string/init(localized:defaultvalue:…) の .json（iOS 15.0。locale の説明「The locale to use when localizing interpolated values, such as numbers.」）。
- 未検証：コンパイル、警告0件、xcodegen generate、ios_build、ios_test（単体273アサーション、受け入れ82本、ac18）。裁定の (a)〜(g)、D-46、D-48、D-53、D-60、AC-34、AC-43、AC-49。rollback がメモリの @Model を戻すか。PrivacyInfo と InfoPlist.xcstrings がバンドルに入るか。String(format:) と stringsdict の複数形。単体テストの中身の一部。受け入れテストは判定の対象外。

## 記録（指揮役）
- 関門：G2（ios-engineer の変更：実装）
- 判定した役：reviewer（model: opus。fable が上限のため）
- 回：r1（静的な読み。コンパイルと CI は未検証）
- 対象：BASE 477226f...HEAD fd586ac
- 日付：2026-10-21
- 指揮役の扱い：要修正1は tech-lead が ADR 0005 と T8 に例外を書く。要修正2は f8ccf89 で済み。提案3、6、7、9、11、12 は ios-engineer に直させる。提案4、5、8 は CI と G3 で見る。提案10 は G5 の前。提案13 は tech-lead。r2 は CI（Takuma の app.json）の後。
