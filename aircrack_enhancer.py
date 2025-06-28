#!/usr/bin/env python3
import argparse
import itertools
import random
import sys

LEET_MAP = {
    'a': ['4', '@', '^', 'à', 'æ'],
    'b': ['8', 'ß'],
    'c': ['(', '<', '¢'],
    'e': ['3', '€'],
    'g': ['9', '6'],
    'h': ['#'],
    'i': ['1', '!', '|', 'ï'],
    'l': ['1', '|', '£'],
    'o': ['0', '()', '*'],
    's': ['5', '$', '§'],
    't': ['7', '+'],
    'z': ['2'],
    'x': ['%'],
    'q': ['9']
}

SUFFIXES = [
    '123', '1234', '12345',
    '!', '@', '#', '$', '!!',
    '2023', '2024', '2025',
    '1!', '12', '!@#', '321',
    '007', '911', '666', '420', '69',
    'abc', 'xyz', 'qwe', 'asd',
    'pass', 'pwd', 'pw',
    'love', 'hate', 'god', 'life',
    'CAN', 'USA', 'ONT', 'TO',
    '!', '!1', '1!', '!!'
]

PREFIXES = [
    '!', '@', '#', '$', '2024', '2025', 'VIP', 'the', 'mr', 'ms', 'dr'
]

MAX_LEET_REPLACEMENTS = 3


def load_words(file):
    with open(file, 'r', encoding='utf-8') as f:
        return [line.strip() for line in f if line.strip()]


def toggle_case(word):
    return ''.join(
        ch.upper() if ch.islower() and random.random() < 0.5 else ch.lower()
        if ch.isupper() and random.random() < 0.5 else ch
        for ch in word
    )


def leetspeak_variants(word):
    positions = []
    for ch in word:
        lower = ch.lower()
        positions.append([ch] + LEET_MAP.get(lower, []))

    replace_positions = [i for i, chars in enumerate(positions) if len(chars) > 1]
    if len(replace_positions) > MAX_LEET_REPLACEMENTS:
        replace_positions = random.sample(replace_positions, MAX_LEET_REPLACEMENTS)

    def gen_replacements():
        for combo in itertools.product(*[
            positions[i] if i not in replace_positions else positions[i][1:]
            for i in range(len(positions))
        ]):
            yield ''.join(combo)

    variants = set([word])
    variants.update(gen_replacements())
    return variants


def apply_suffixes(words):
    for word in words:
        for suffix in SUFFIXES:
            yield word + suffix


def apply_prefixes(words):
    for word in words:
        for prefix in PREFIXES:
            yield prefix + word


def generate_variants(words, do_leet, do_suffix, do_prefix, do_toggle, limit=None):
    seen = set()
    count = 0

    for base in words:
        variants = {base}

        if do_leet:
            new_set = set()
            for w in variants:
                new_set.update(leetspeak_variants(w))
            variants = new_set

        if do_toggle:
            variants.update(toggle_case(w) for w in list(variants))

        if do_prefix:
            variants.update(apply_prefixes(list(variants)))

        if do_suffix:
            variants.update(apply_suffixes(list(variants)))

        for v in variants:
            if v not in seen:
                yield v
                seen.add(v)
                count += 1
                if limit and count >= limit:
                    return


def main():
    parser = argparse.ArgumentParser(description="Pipe-enhanced wordlist generator for aircrack-ng.")
    parser.add_argument("-i", "--input", required=True, help="Input wordlist")
    parser.add_argument("--leet", action="store_true", help="Enable leetspeak substitutions")
    parser.add_argument("--suffix", action="store_true", help="Append common suffixes")
    parser.add_argument("--prefix", action="store_true", help="Prepend common prefixes")
    parser.add_argument("--toggle", action="store_true", help="Toggle case randomly")
    parser.add_argument("--max", type=int, default=0, help="Optional max number of variants")

    args = parser.parse_args()

    words = load_words(args.input)

    try:
        for variant in generate_variants(
            words,
            do_leet=args.leet,
            do_suffix=args.suffix,
            do_prefix=args.prefix,
            do_toggle=args.toggle,
            limit=args.max if args.max > 0 else None
        ):
            print(variant)
    except BrokenPipeError:
        # Happens when piped to aircrack-ng and user stops execution
        sys.exit(0)


if __name__ == "__main__":
    main()