#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <map>
#include <tuple>
#include <sstream>
#include <random>
#include <stdexcept>

// Prefix é uma dupla de strings (palavra anterior e a anterior da anterior)
// Usado como chave da cadeia de Markov.
using Prefix = std::tuple<std::string, std::string>;

// A cadeia é um mapa: Prefixo → lista de possíveis palavras seguintes
using Chain = std::map<Prefix, std::vector<std::string>>;

// -----------------------------------------------------------------------------
// Função que divide um texto em palavras usando whitespace como separador.
// -----------------------------------------------------------------------------
std::vector<std::string> split(const std::string& str) {
    std::vector<std::string> words;
    std::istringstream stream(str);
    std::string word;

    while (stream >> word) {  
        words.push_back(word);
    }

    return words;
}

// -----------------------------------------------------------------------------
// Constrói a cadeia de Markov de ordem 2.
// Para cada par de palavras consecutivas, registra qual palavra pode vir depois.
// -----------------------------------------------------------------------------
Chain build_chain(const std::vector<std::string>& words) {
    Chain chain;

    // Começa com prefixo vazio ("", "")
    Prefix prefix = {"", ""};

    // Percorre todas as palavras do texto
    for (const auto& word : words) {
        // Associa o prefixo atual ao próximo possível sufixo
        chain[prefix].push_back(word);

        // Atualiza o prefixo (remove a mais antiga e adiciona a palavra nova)
        prefix = {std::get<1>(prefix), word};
    }

    return chain;
}

int main(int argc, char* argv[]) {

    // Verifica se o usuário passou 2 argumentos: tamanho em MB e nome do arquivo
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <size_in_mb> <output_filename>" << std::endl;
        return 1;
    }

    // -------------------------------------------------------------------------
    // 1. Converte argumento de tamanho para número
    // -------------------------------------------------------------------------
    long long size_in_mb;
    try {
        size_in_mb = std::stoll(argv[1]);  // converte string para inteiro de 64 bits
        if (size_in_mb <= 0) throw std::invalid_argument("Size must be positive");
    } catch (const std::exception& e) {
        std::cerr << "Error: Invalid size. Please enter a positive number." << std::endl;
        return 1;
    }

    // Total de bytes a gerar
    const long long total_bytes_to_generate = size_in_mb * 1024 * 1024;
    const std::string output_filename = argv[2];

    // -------------------------------------------------------------------------
    // 2. Carrega texto original (Charles Dickens – A Tale of Two Cities)
    // -------------------------------------------------------------------------
    std::ifstream input_file("a_tale_of_two_cities.txt");
    if (!input_file.is_open()) {
        std::cerr << "Error: Could not open a_tale_of_two_cities.txt" << std::endl;
        return 1;
    }

    // Lê todo o arquivo para um stringstream
    std::stringstream text_stream;
    text_stream << input_file.rdbuf();

    // Separa o texto em palavras
    std::vector<std::string> words = split(text_stream.str());

    // Constrói a cadeia de Markov
    Chain chain = build_chain(words);

    // -------------------------------------------------------------------------
    // 3. Abre arquivo de saída
    // -------------------------------------------------------------------------
    std::ofstream output_file(output_filename);
    if (!output_file.is_open()) {
        std::cerr << "Error: Could not open " << output_filename << " for writing." << std::endl;
        return 1;
    }

    // Prefixo inicial ("", "")
    Prefix initial_state = {"", ""};
    Prefix current_state = initial_state;

    // Usado para acumular texto antes de escrever no disco
    std::ostringstream buffer;

    // Escreve em chunks de 1 MB para não explodir memória
    const size_t CHUNK_SIZE = 1 * 1024 * 1024;

    long long total_bytes_written = 0;

    // Inicializa gerador de números aleatórios
    std::random_device rd;
    std::mt19937 gen(rd());

    // -------------------------------------------------------------------------
    // 4. Loop principal de geração do texto até atingir o tamanho desejado
    // -------------------------------------------------------------------------
    while (total_bytes_written < total_bytes_to_generate) {

        // Obtém as palavras possíveis que seguem o prefixo atual
        auto it = chain.find(current_state);

        // Se não houver continuação válida, volta ao início
        if (it == chain.end() || it->second.empty()) {
            current_state = initial_state;
            it = chain.find(current_state);
            if (it == chain.end()) break;  // caso extremo
        }

        // Lista de palavras possíveis após o prefixo
        const auto& suffixes = it->second;

        // Escolhe uma palavra aleatória entre as possíveis
        std::uniform_int_distribution<> distrib(0, suffixes.size() - 1);
        const std::string& word = suffixes[distrib(gen)];

        // Escreve palavra no buffer
        buffer << word << " ";

        // Atualiza prefixo para o próximo
        current_state = {std::get<1>(current_state), word};

        // Se buffer atingiu 1MB, escreve no arquivo
        if (buffer.tellp() >= CHUNK_SIZE) {
            output_file << buffer.str();
            total_bytes_written += buffer.tellp();
            buffer.str("");
            buffer.clear();
        }
    }

    // -------------------------------------------------------------------------
    // 5. Escreve o último pedaço (resto do buffer)
    // -------------------------------------------------------------------------
    std::string final_chunk = buffer.str();

    if (!final_chunk.empty()) {
        long long remaining_bytes = total_bytes_to_generate - total_bytes_written;

        if (final_chunk.length() > remaining_bytes) {
            // Corta caso tenha ultrapassado o tamanho desejado
            output_file << final_chunk.substr(0, remaining_bytes);
        } else {
            output_file << final_chunk;
        }
    }

    return 0;
}