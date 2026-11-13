#!/usr/bin/env python3
"""Validate the bundled offline bank without network access or API credentials."""
from collections import Counter
from pathlib import Path
from urllib.parse import urlparse
import argparse
import json
import re


def validate(path: Path, expected: int = 1000) -> dict:
    words = json.loads(path.read_text(encoding="utf-8"))
    assert isinstance(words, list) and len(words) == expected, f"Expected {expected} cards"
    ids, headwords = set(), set()
    pairs = 0
    for index, word in enumerate(words, 1):
        label = f"Card {index}: {word.get('word', '?')}"
        for field in ["id", "word", "partOfSpeech", "phonetic", "register", "definition", "translation", "explanation", "usage"]:
            assert isinstance(word.get(field), str) and word[field].strip(), f"{label}: missing {field}"
        assert re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", word["id"]), f"{label}: invalid deep-link identifier"
        assert word["id"] not in ids, f"{label}: duplicate identifier"
        ids.add(word["id"])
        normalized = word["word"].casefold().strip()
        assert normalized not in headwords, f"{label}: duplicate headword"
        headwords.add(normalized)
        assert word["partOfSpeech"] in {"noun", "verb", "adjective", "adverb", "phrase"}, label
        assert word["register"] in {"standard", "informal", "slang"}, label
        assert word["phonetic"].startswith("/") and word["phonetic"].endswith("/"), f"{label}: IPA delimiters"
        assert re.search(r"[а-яё]", word["translation"], re.I), f"{label}: missing Russian translation"
        assert re.search(r"[а-яё]", word["explanation"], re.I), f"{label}: missing Russian explanation"
        assert re.search(r"[а-яё]", word["usage"], re.I), f"{label}: missing usage note"
        assert isinstance(word.get("synonyms"), list) and all(isinstance(s, str) and s.strip() for s in word["synonyms"]), label
        examples = word.get("examples")
        assert isinstance(examples, list) and len(examples) == 2, f"{label}: expected two example pairs"
        assert len({e["english"].casefold().strip() for e in examples}) == 2, f"{label}: repeated example"
        for example in examples:
            assert isinstance(example.get("english"), str) and re.search(r"[a-z]", example["english"], re.I), label
            assert isinstance(example.get("russian"), str) and re.search(r"[а-яё]", example["russian"], re.I), label
            if "sourceURL" in example:
                assert "translationSourceURL" in example, f"{label}: missing translation attribution"
                for field in ["sourceURL", "translationSourceURL"]:
                    url = urlparse(example[field])
                    assert url.scheme == "https" and url.hostname == "tatoeba.org", f"{label}: invalid attribution URL"
                    assert re.fullmatch(r"/en/sentences/show/\d+", url.path), label
            pairs += 1
        if "sourceURL" in word:
            assert word.get("source"), f"{label}: missing source label"
            assert urlparse(word["sourceURL"]).scheme == "https", label
    return {"cards": len(words), "distinctHeadwords": len(headwords), "examplePairs": pairs,
            "registers": dict(Counter(w["register"] for w in words))}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", type=Path, nargs="?", default=Path(__file__).resolve().parents[1] / "Shared/words.json")
    parser.add_argument("--expected", type=int, default=1000)
    args = parser.parse_args()
    print("PASS: " + json.dumps(validate(args.path, args.expected), ensure_ascii=False))
