#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <map>
#include <tuple>
#include <sstream>
#include <random>
#include <stdexcept>

using Prefix = std::tuple<std::string, std::string>;
using Chain = std::map<Prefix, std::vector<std::string>>;

std::vector<std::string> split(const std::string& str) {
    std::vector<std::string> words;
    std::istringstream stream(str);
    std::string word;
    while (stream >> word) {
        words.push_back(word);
    }
    return words;
}

Chain build_chain(const std::vector<std::string>& words) {
    Chain chain;
    Prefix prefix = {"", ""};
    for (const auto& word : words) {
        chain[prefix].push_back(word);
        prefix = {std::get<1>(prefix), word};
    }
    return chain;
}

int main(int argc, char* argv[]) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <size_in_mb> <output_filename>" << std::endl;
        return 1;
    }

    long long size_in_mb;
    try {
        size_in_mb = std::stoll(argv[1]);
        if (size_in_mb <= 0) throw std::invalid_argument("Size must be positive");
    } catch (const std::exception& e) {
        std::cerr << "Error: Invalid size. Please enter a positive number." << std::endl;
        return 1;
    }
    const long long total_bytes_to_generate = size_in_mb * 1024 * 1024;
    
    const std::string output_filename = argv[2];

    std::ifstream input_file("a_tale_of_two_cities.txt");
    if (!input_file.is_open()) {
        std::cerr << "Error: Could not open a_tale_of_two_cities.txt" << std::endl;
        return 1;
    }
    std::stringstream text_stream;
    text_stream << input_file.rdbuf();
    std::vector<std::string> words = split(text_stream.str());
    Chain chain = build_chain(words);

    std::ofstream output_file(output_filename);
    if (!output_file.is_open()) {
        std::cerr << "Error: Could not open " << output_filename << " for writing." << std::endl;
        return 1;
    }

    Prefix initial_state = {"", ""};
    Prefix current_state = initial_state;

    std::ostringstream buffer;
    const size_t CHUNK_SIZE = 1 * 1024 * 1024; // 1 MB
    long long total_bytes_written = 0;

    std::random_device rd;
    std::mt19937 gen(rd());

    while (total_bytes_written < total_bytes_to_generate) {
        auto it = chain.find(current_state);
        if (it == chain.end() || it->second.empty()) {
            current_state = initial_state;
            it = chain.find(current_state);
            if (it == chain.end()) break;
        }

        const auto& suffixes = it->second;
        std::uniform_int_distribution<> distrib(0, suffixes.size() - 1);
        const std::string& word = suffixes[distrib(gen)];

        buffer << word << " ";
        current_state = {std::get<1>(current_state), word};

        if (buffer.tellp() >= CHUNK_SIZE) {
            output_file << buffer.str();
            total_bytes_written += buffer.tellp();
            buffer.str("");
            buffer.clear();
        }
    }

    std::string final_chunk = buffer.str();
    if (!final_chunk.empty()) {
        long long remaining_bytes = total_bytes_to_generate - total_bytes_written;
        if (final_chunk.length() > remaining_bytes) {
            output_file << final_chunk.substr(0, remaining_bytes);
        } else {
            output_file << final_chunk;
        }
    }

    return 0;
}
