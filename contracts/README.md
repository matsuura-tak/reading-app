# contracts/（iOS とテストの境目の契約）

- 書いた役：tech-lead。ここを直せるのは tech-lead だけ。ios-engineer と verifier は読むだけで、足りないものは報告に書く。
- 001 にはサーバーがない（ADR 0001、ADR 0003）。HTTP の API 契約（OpenAPI）はないので、spectral と oasdiff は対象外。代わりに、テストのつなぎ口とデータの形を JSON Schema と表で決め、下のコマンドで確かめる。
- 契約は同じ版の中では足すだけにする。項目や enum の値を消す、名前や型や意味を変える、必須にする変更は、新しい ADR と版の上げ（seed の "version" など）を伴う。

## 中身
| ファイル | 中身 | 主に使う役 |
|---|---|---|
| contracts/data-model.md | SwiftData のモデル（Book、ReadingSession、ActiveReading）の項目、型、制約、計算する値、保存の操作、計測の印、個人情報と保存期間と消し方 | ios-engineer、verifier |
| contracts/test-hooks.md | テストのつなぎ口 T1〜T21（名前、型、例、使う AC、Release での扱い） | verifier、ios-engineer、reviewer |
| contracts/seed.schema.json | UITEST_SEED の JSON Schema（draft-07） | verifier、ios-engineer |
| contracts/seed.example.json | UITEST_SEED の例（AC-14、AC-18、AC-54、AC-55 のデータ） | verifier |
| contracts/examples/seed-ac15.json、seed-ac33.json | UITEST_SEED の例（AC-15 の週の境目、AC-33 の一時停止中） | verifier |
| contracts/telemetry.md | 計測の9イベント、区間の決め方、Swift の型の名前の案、テストの受け口の送り方 | ios-engineer、verifier |
| contracts/telemetry-events.schema.json | POST /events の本文（イベント1件）の JSON Schema | verifier、ios-engineer |
| contracts/telemetry-flushed.schema.json | POST /flushed の本文の JSON Schema | verifier |
| contracts/examples/telemetry-*.json、flushed.json | 上の2つの例（9イベントと送り終わり） | verifier、ios-engineer |
| contracts/tools/xcstrings_untranslated.py | String Catalog の ja と en のそろっていないキーを数える（AC-39、T14） | verifier |
| contracts/dependencies.md | 使ってよい依存ライブラリの表（001 は空） | 全員 |

## 確かめ方（リポジトリの根で動かす）
1. JSON Schema と例が合うこと（Linux で動く。Node が要る）：
   ```
   npx -y ajv-cli@5 validate -s contracts/seed.schema.json -d contracts/seed.example.json
   npx -y ajv-cli@5 validate -s contracts/seed.schema.json -d "contracts/examples/seed-*.json"
   npx -y ajv-cli@5 validate -s contracts/telemetry-events.schema.json -d "contracts/examples/telemetry-*.json"
   npx -y ajv-cli@5 validate -s contracts/telemetry-flushed.schema.json -d contracts/examples/flushed.json
   ```
   どの行も「valid」だけが出ること。
2. 互換性（足すだけ）：`git diff origin/main -- contracts/ | grep -cE '^-[^-]'` が 0。main に contracts/ の中身がなければ「新規」と書く。0 でなければ、消した行ごとに ADR と版の上げがあること。
3. 名前のずれ（ios/ ができてから）：次の出力が空であること。受け入れテストとアプリが使う UITEST_ の名前が、すべてこの契約にある。
   ```
   comm -23 <(grep -rhoE 'UITEST_[A-Z0-9_]+' ios/ | sort -u) <(grep -hoE 'UITEST_[A-Z0-9_]+' contracts/test-hooks.md | sort -u)
   ```
4. つなぎ口が Release に混ざらないこと（macOS の CI。ADR 0005）：
   ```
   grep -rlE 'UITEST_' ios --include='*.swift' | grep -vE '^ios/Yomutoki/Debug/UITestHooks\.swift$|^ios/AcceptanceTests/' | wc -l    # 0
   xcodebuild -project ios/Yomutoki.xcodeproj -scheme Yomutoki -configuration Release -sdk iphonesimulator -derivedDataPath build/release CODE_SIGNING_ALLOWED=NO build
   strings -a build/release/Build/Products/Release-iphonesimulator/Yomutoki.app/Yomutoki | grep -cE 'UITEST_|readingapp-uitest|-UITest|uitest\.clock'    # 0
   /usr/libexec/PlistBuddy -c 'Print :CFBundleURLTypes' build/release/Build/Products/Release-iphonesimulator/Yomutoki.app/Info.plist    # 「Does Not Exist」で失敗すること
   ```
   2行目から下は macOS でしか動かない（未確認。最初の CI の出力で確かめ、違えばこの節を直す）。
5. 文言の表（AC-39。Linux で動く）：`python3 -I contracts/tools/xcstrings_untranslated.py ios/Yomutoki/Resources/*.xcstrings` の最後の行が `untranslated_keys=0`。
6. 計測の名前のずれ：ios-engineer の単体テストで、TelemetryEvent の各 case を JSON にしたものが contracts/examples/telemetry-*.json と同じ名前とキーを持つことを確かめる（例のファイルをテストに入れる方法は ios-engineer が決める）。
