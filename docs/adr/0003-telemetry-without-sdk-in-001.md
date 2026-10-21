# ADR 0003：001 では計測の第三者の SDK を入れず、イベントの型と送り先の protocol だけを作る

- 状態：提案
- 書いた役：tech-lead　日付：2026-10-21
- 関係する PRD、設計メモ、契約：docs/prd/001-reading-session.md（12 のオフラインとプライバシー、13、15、18 の P-7 と P-13、AC-20、AC-23、AC-24）、docs/prd/product.md の 11（計測の代わりの案）、contracts/telemetry.md、contracts/telemetry-events.schema.json、contracts/test-hooks.md（T6、T7、T13、T19）
- 元に戻す手間：小（SDK を足すのは送り先の実装を1つ足すだけ。イベントの型は変えない）

## 背景
- PRD 15 の9イベント（App First Opened、Book Added、Reading Session Started、Reading Session Finished、Reading Session Restored、Reading Session Discarded、Reading Week Reached、Save Failed、Load Failed）と、そのプロパティ（区間と true / false）を作る。題名とページの生の値は送らない（AC-23）。
- 送り先の第一候補は TelemetryDeck（P-7）。ただし PRD 12 と product.md 11 は「G1 までに無料枠と端末 ID の扱いを確かめられなければ、001 は差し替え口だけを持ち、第三者の SDK は入れない。SDK は 003 で決め直す」と決めている。
- この環境から telemetrydeck.com と TelemetryDeck の GitHub は開けない（2026-10-21 に telemetrydeck.com/pricing を curl して 403。G0 tech-lead r2 で api.github.com も 403）。だから、新しいアカウントの無料枠（P-13）、SDK が自分で送る項目と端末ごとの ID、送り先の URL を受け口に向けられるか（T6）、送れないときに貯めるか捨てるか、SDK のプライバシーマニフェスト（A33）を、どれも確かめられない。
- 001 は単独で App Store に出さず、内部の TestFlight まで（PRD 10、18 の 1）。PRD 13 の KPI の判定日は v1.0（2027-01-31 目標）の後。PRD 14 の1行目（Takuma の7日間で終えた読書が3回未満）は、端末の中の記録（本の詳細の記録の一覧）で数えられ、計測は要らない。

## 決定
- 001 では第三者の SDK を入れない。`TelemetryEvent`（PRD 15 の9イベント。プロパティは区間の enum と Bool だけ）の型と、`TelemetrySink` の protocol を作る。形は contracts/telemetry.md。
- 本番の送り先は「端末の中で数えるだけ」の実装（UserDefaults にイベント名ごとの回数を足す。ネットワークに出ない）。
- テストの送り先は Debug ビルドで -UITest のときだけ働く HTTP の実装で、localhost の受け口に POST する（contracts/telemetry.md、contracts/test-hooks.md の T6）。送れなかったイベントは貯めずに捨てる（PRD 12 のオフラインの行の「未定」を、001 では「捨てる」に決める）。
- SDK を入れるか（TelemetryDeck か別のものか）は 003 の G1 で決め直す。そのとき AC-23 の確かめを SDK の送る本文で行い直す。

## 検討した案
| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| A：型と protocol だけ。本番は端末の中で数える（選んだ） | 依存なし。外に何も出ないので、001 のプライバシー表記は「データを集めない」にできる見込み。AC-23、AC-24 はテストの送り先で確かめられる | 001 の内部の TestFlight の間、実際の使われ方の数字が手に入らない。SDK を入れたときに SDK が足す項目の確かめが 003 に残る | － |
| B：TelemetryDeck の SDK を今入れる | 内部の TestFlight から数字が取れる。P-7 の第一候補 | 無料枠、端末ごとの ID、送り先の差し替え、送れないときの動き、プライバシーマニフェストが、どれも未確認。dependencies.md に書く「解決とビルドの出力」が作れない（Mac がない） | 確かめられないまま入れると、プライバシー表記を誤るおそれがある（PRD 15 の最後の行） |
| C：自分のサーバーに送る | 送る中身と保存を全部決められる | 001 にはバックエンドがない。サーバー代、運用、プライバシーポリシーが増える | 001 の範囲と費用に合わない |
| D：計測の型も作らず、003 でまとめて入れる | 001 の作業がいちばん少ない | AC-23 と AC-24 の受け入れテストが作れない。003 で全部の呼び出し元に手を入れる | AC を満たせない |
| E：App Store Connect の分析だけ | 追加の作業なし | 独自のイベントがないので、North Star と I-1 が測れない（PRD 13） | KPI が測れない |

## いちばん強い反論と、それでも選んだ理由
- 反論：001 の内部の TestFlight は、計測の実地の試しができる唯一の機会。ここで SDK を入れなければ、v1.0（2027-01-31 目標）の直前の 003 で初めて本番の送信を試すことになり、無料枠の超過、端末ごとの ID、プライバシー表記の誤りが公開の直前に見つかる。
- それでも選んだ理由：確かめる手段（SDK の文書とソース、料金のページ）がこの環境にないことは変わらず、入れても中身を確かめられない。イベントの型、区間の計算、送るきっかけ（いつ何を1回送るか）は 001 で作って受け入れテストで固めるので、003 で足すのは送り先の実装1つと、その送る本文の確かめだけになる。003 の G1 の前に、Takuma に TelemetryDeck の料金の表と SDK の README を貼ってもらう（P-13）か、接続の許可をもらう。

## 結果
- これで楽になること：001 は外に何も送らないので、ATS の例外、Local Network の許可、SDK のプライバシーマニフェストが要らない。テストの受け口は Debug の localhost だけ（A48。localhost は既定で許される）。
- これで難しくなること、守り続けること：イベント名とプロパティ名は TelemetryEvent の型の中の1か所でだけ作る。String や Int の生の値を関連値に持たせない（題名とページを型の上で渡せなくする）。UserDefaults は required reason API なので、PrivacyInfo.xcprivacy に理由を書く（A33。理由のコードは未確認。ios-engineer が A33 のページで選び、reviewer が G4 で照合）。
- 元に戻すときの手順と手間：SDK を入れるときは、TelemetrySink の実装を1つ足し、組み立ての場所で差し替える。dependencies.md と新しい ADR を足し、PRD 15 の最後の行とプライバシー表記を直す。手間は小（1日程度と推測。SDK の確かめを除く）。

## 見直す条件
- 003 の G1（SDK を入れるかを決め直す。この ADR を置き換える）。
- TelemetryDeck の料金の表と SDK の文書を確かめる手段ができた（Takuma が貼る、接続が許される）。
- 001 を内部の TestFlight より外に配ることになった（PRD 18 の 1 を変えた）。
- 端末の中で数えた回数を、利用者に見せるか外に出す必要が出た。

## 確かめたこと
- A21 UserDefaults https://developer.apple.com/documentation/foundation/userdefaults
- A33 プライバシーマニフェストと required reason API https://developer.apple.com/documentation/bundleresources/privacy-manifest-files https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- A47 NWListener iOS 12.0+（受け口をテストの側に立てる見込み）、A48 NSAllowsLocalNetworking の本文「In iOS 17, iPadOS 17, and macOS 14, ATS no longer allows connections to IP addresses by default.」、A49 TN3179「The simulator doesn't support local network privacy.」（docs/reviews/001-reading-session-G0-tech-lead-r2.md:48-50）
- Apple のプライバシー表記の分け方 https://developer.apple.com/app-store/app-privacy-details/ （G0 tech-lead r1 で開いて確認）
- 開けなかったもの：`curl -sS -m 20 https://telemetrydeck.com/pricing/` → 「CONNECT tunnel failed, response 403」（2026-10-21）。TelemetryDeck の SDK の README と API は未確認。
- 未確認：URLSession で localhost の受け口にシミュレーターのアプリから実際に届くか（G2 の CI で verifier の受け入れテストが確かめる。裁定の追記2 の (9)）。届かなければ、送ったイベントを並べた要素 uitest.telemetry.log の accessibilityValue を XCUITest が読む形（contracts/test-hooks.md の T22。2026-10-21 に G1 reviewer r1 の重大1 で足した）に替える。

## 確かめ（B）
- [x] 案が2つ以上あり、どの案にも悪い点が書いてある
- [x] 反論、悪い結果、見直す条件が空でない
- [x] 確かめたことに、URL かコマンドの出力がある
