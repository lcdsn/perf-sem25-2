#!/usr/bin/env python3
"""
Generate statistics table (mean ± std) for compression algorithms.
Uses all file sizes (1-25 MB) from Phase 3 benchmark results.
"""

import csv
import sys
from collections import defaultdict
from math import sqrt

def main():
    # Find the CSV file
    csv_file = "output/2025-11-20_17-48-37/benchmark_results_2025-11-20_20-48-41_fixed.csv"

    if len(sys.argv) > 1:
        csv_file = sys.argv[1]

    # Data structure: algorithm -> metric -> list of values
    data = defaultdict(lambda: defaultdict(list))

    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            algo = row['algorithm']

            # Compression time (ms)
            comp_time = float(row['compression_task_clock_ms'])
            data[algo]['comp_time'].append(comp_time)

            # Decompression time (ms)
            decomp_time = float(row['decompression_task_clock_ms'])
            data[algo]['decomp_time'].append(decomp_time)

            # Compression ratio (%)
            original = float(row['original_size_bytes'])
            compressed = float(row['compressed_size_bytes'])
            ratio = (compressed / original) * 100
            data[algo]['ratio'].append(ratio)

    # Calculate mean and std for each algorithm
    def mean(values):
        return sum(values) / len(values)

    def std(values):
        m = mean(values)
        variance = sum((x - m) ** 2 for x in values) / len(values)
        return sqrt(variance)

    # Print results
    print("\n" + "=" * 80)
    print("STATISTICS TABLE - All file sizes (1-25 MB)")
    print("=" * 80)

    print(f"\n{'Algorithm':<10} {'Samples':<8} {'Comp (ms)':<18} {'Decomp (ms)':<18} {'Ratio (%)':<18}")
    print("-" * 80)

    for algo in ['gzip', 'bzip2', 'xz', 'zstd']:
        n = len(data[algo]['comp_time'])

        comp_mean = mean(data[algo]['comp_time'])
        comp_std = std(data[algo]['comp_time'])

        decomp_mean = mean(data[algo]['decomp_time'])
        decomp_std = std(data[algo]['decomp_time'])

        ratio_mean = mean(data[algo]['ratio'])
        ratio_std = std(data[algo]['ratio'])

        print(f"{algo:<10} {n:<8} {comp_mean:>7.0f} ± {comp_std:<7.0f} {decomp_mean:>7.0f} ± {decomp_std:<7.0f} {ratio_mean:>6.2f} ± {ratio_std:<6.2f}")

    print("-" * 80)

    # LaTeX format
    print("\n" + "=" * 80)
    print("LaTeX TABLE FORMAT")
    print("=" * 80)
    print("""
\\begin{table}[h]
  \\centering
  \\caption{Valores médios e desvio padrão para arquivos de 1--25MB (75 amostras por algoritmo).}
  \\label{tab:valores}
  \\begin{tabular}{lccc}
    \\toprule
    \\textbf{Algoritmo} & \\textbf{Compressão (ms)} & \\textbf{Descompressão (ms)} & \\textbf{Taxa (\\%)} \\\\
    \\midrule""")

    for algo in ['gzip', 'bzip2', 'xz', 'zstd']:
        comp_mean = mean(data[algo]['comp_time'])
        comp_std = std(data[algo]['comp_time'])
        decomp_mean = mean(data[algo]['decomp_time'])
        decomp_std = std(data[algo]['decomp_time'])
        ratio_mean = mean(data[algo]['ratio'])
        ratio_std = std(data[algo]['ratio'])

        print(f"    {algo} & {comp_mean:.0f} $\\pm$ {comp_std:.0f} & {decomp_mean:.0f} $\\pm$ {decomp_std:.0f} & {ratio_mean:.2f} $\\pm$ {ratio_std:.2f} \\\\")

    print("""    \\bottomrule
  \\end{tabular}
\\end{table}
""")

    # Markdown format
    print("=" * 80)
    print("MARKDOWN TABLE FORMAT")
    print("=" * 80)
    print("""
| Algoritmo | Comp. (ms) | Decomp. (ms) | Taxa (%) |
|-----------|------------|--------------|----------|""")

    for algo in ['gzip', 'bzip2', 'xz', 'zstd']:
        comp_mean = mean(data[algo]['comp_time'])
        comp_std = std(data[algo]['comp_time'])
        decomp_mean = mean(data[algo]['decomp_time'])
        decomp_std = std(data[algo]['decomp_time'])
        ratio_mean = mean(data[algo]['ratio'])
        ratio_std = std(data[algo]['ratio'])

        print(f"| {algo} | {comp_mean:.0f} ± {comp_std:.0f} | {decomp_mean:.0f} ± {decomp_std:.0f} | {ratio_mean:.2f} ± {ratio_std:.2f} |")

if __name__ == "__main__":
    main()
