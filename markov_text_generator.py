import random
import sys

text = """
    Show your flowcharts and conceal your tables and I will be
    mystified. Show your tables and your flowcharts will be
    obvious.
"""


def read_file(fn: text) -> list[str]:
    text = None
    with open(fn, "r") as f:
        buff = f.read()
        text = buff.split()
    return text


def build_chain(text: str) -> list:
    chain = {}
    cur_state = ["", ""]
    for word in text:
        chain.setdefault(tuple(cur_state), []).append(word)
        cur_state[0], cur_state[1] = cur_state[1], word

    chain.setdefault(tuple(cur_state), []).append(word)

    return chain


def write_file(text: str):
    with open("output.txt", "w") as f:
        f.write(text)


def main():
    try:
        size_str = sys.argv[1]
        size_in_mb = int(size_str) * 1024 * 1024
        if size_in_mb <= 0:
            print(
                "Error: Please enter a positive number for the size.", file=sys.stderr
            )
            sys.exit(1)
    except (IndexError, ValueError):
        print("Usage: python your_script_name.py <size_in_mb>", file=sys.stderr)
        sys.exit(1)

    text = read_file("a_tale_of_two_cities.txt")
    chain = build_chain(text)

    initial_state: list[str] = ["", ""]
    cur_state: list[str] = initial_state.copy()

    text = []
    while len(text) < size_in_mb:
        lookup_key = tuple(cur_state)
        suffixes = chain.get(lookup_key)

        if not suffixes:
            cur_state = initial_state.copy()
            suffixes = chain.get(tuple(cur_state))
            if not suffixes:
                break

        word = random.choice(suffixes)
        text.append(word)
        cur_state = [cur_state[1], word]

    write_file(" ".join(text))


if __name__ == "__main__":
    main()
