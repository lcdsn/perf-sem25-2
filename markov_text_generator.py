import random
import sys

# Este texto é só um exemplo, mas o programa não usa essa variável.
text = """
    Show your flowcharts and conceal your tables and I will be
    mystified. Show your tables and your flowcharts will be
    obvious.
"""


def read_file(fn: text) -> list[str]:
    # Lê o arquivo de entrada e retorna uma lista de palavras.
    text = None
    with open(fn, "r") as f:
        buff = f.read()
        text = buff.split()   # divide em palavras removendo espaços e quebras de linha
    return text


def build_chain(text: str) -> list:
    # Constrói a cadeia de Markov usando prefixo de 2 palavras.
    chain = {}
    cur_state = ["", ""]     # estado inicial: duas strings vazias

    for word in text:
        # Adiciona 'word' como possível continuação do prefixo atual.
        chain.setdefault(tuple(cur_state), []).append(word)

        # Atualiza o prefixo: desloca a janela de 2 palavras
        cur_state[0], cur_state[1] = cur_state[1], word

    # IMPORTANTE: este último append é redundante e usa 'word' fora do loop
    # Ainda adiciona um estado final que pode ser inútil ou incorreto
    chain.setdefault(tuple(cur_state), []).append(word)

    return chain


def write_file(text: str):
    # Escreve o texto gerado no arquivo de saída
    with open("output.txt", "w") as f:
        f.write(text)


def main():
    # Lê argumento da linha de comando: tamanho do arquivo em MB
    try:
        size_str = sys.argv[1]
        size_in_mb = int(size_str) * 1024 * 1024  # converte MB para bytes
        if size_in_mb <= 0:
            print("Error: Please enter a positive number for the size.", file=sys.stderr)
            sys.exit(1)
    except (IndexError, ValueError):
        # Nenhum argumento ou inválido
        print("Usage: python your_script_name.py <size_in_mb>", file=sys.stderr)
        sys.exit(1)

    # Lê o texto base
    text = read_file("a_tale_of_two_cities.txt")

    # Cria a cadeia de Markov
    chain = build_chain(text)

    # Estado inicial
    initial_state: list[str] = ["", ""]
    cur_state: list[str] = initial_state.copy()

    # Aqui armazenaremos as palavras geradas
    text = []

    # Loop até atingir o tamanho desejado
    while len(text) < size_in_mb:
        lookup_key = tuple(cur_state)
        suffixes = chain.get(lookup_key)

        # Se o estado não existe na cadeia, reinicia para o estado inicial
        if not suffixes:
            cur_state = initial_state.copy()
            suffixes = chain.get(tuple(cur_state))
            if not suffixes:
                break  # Se nem o estado inicial existe, aborta

        # Escolhe aleatoriamente a próxima palavra possível
        word = random.choice(suffixes)

        # Adiciona ao texto final
        text.append(word)

        # Atualiza estado (prefixo)
        cur_state = [cur_state[1], word]

    # Escreve tudo em um arquivo
    write_file(" ".join(text))


if __name__ == "__main__":
    main()
