"""String Catalog（.xcstrings）で、ja と en のそろっていないキーを数える（AC-39、contracts/test-hooks.md の T14）。

使い方：python3 -I contracts/tools/xcstrings_untranslated.py <ファイル.xcstrings> [...]
数え方：
- shouldTranslate が false のキーは数えない。
- 元の言語（sourceLanguage。001 は ja）：localizations にその言語の値があり、すべての stringUnit の value が空でないこと。state は見ない。
- そのほかの言語（en）：localizations にその言語があり、variations（plural など）と substitutions の中を含むすべての stringUnit の state が "translated" であること。needs_review、new、stale は数える。
- 1つでも満たさない言語があるキーを1件と数える。標準出力の最後の行は untranslated_keys=<件数>。0件なら終了コード0、1件以上なら1。
"""
import json
import sys

LANGS = ("ja", "en")


def string_units(node):
    if isinstance(node, dict):
        for key, value in node.items():
            if key == "stringUnit" and isinstance(value, dict):
                yield value
            else:
                yield from string_units(value)
    elif isinstance(node, list):
        for value in node:
            yield from string_units(value)


def problems(catalog):
    source = catalog.get("sourceLanguage", "ja")
    found = []
    for key, entry in sorted(catalog.get("strings", {}).items()):
        if entry.get("shouldTranslate") is False:
            continue
        localizations = entry.get("localizations", {})
        for lang in LANGS:
            units = list(string_units(localizations.get(lang, {})))
            if not units:
                found.append((key, lang, "missing"))
            elif lang == source:
                if any(not unit.get("value") for unit in units):
                    found.append((key, lang, "empty value"))
            elif any(unit.get("state") != "translated" for unit in units):
                found.append((key, lang, "not translated"))
    return found


def main(paths):
    bad_keys = set()
    for path in paths:
        with open(path, encoding="utf-8") as handle:
            catalog = json.load(handle)
        for key, lang, reason in problems(catalog):
            print(f"{path}\t{key}\t{lang}\t{reason}")
            bad_keys.add((path, key))
    print(f"untranslated_keys={len(bad_keys)}")
    return 1 if bad_keys else 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: xcstrings_untranslated.py <file.xcstrings> [...]", file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1:]))
