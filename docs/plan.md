---
title: "Proposta de Projeto: Análise Comparativa de Algoritmos de Compressão de Arquivos"
author: "Lucas Soller, Lucas Nogueira"
date: "August 31, 2025"
geometry: 
  - margin=1cm
  - top=1cm
  - left=2cm
  - right=2cm
  - bottom=2cm
---

# Proposta de Projeto: Análise Comparativa de Algoritmos de Compressão de Arquivos

## 1. Descrição do Objeto Computacional

O objeto de estudo deste trabalho são os **algoritmos de compressão de arquivos**, especificamente os implementados pelas ferramentas **gzip**, **bzip2**, **xz** e **zstd**. Cada uma dessas ferramentas utiliza um algoritmo diferente para reduzir o tamanho de arquivos, com o objetivo de economizar espaço de armazenamento e otimizar a transferência de dados.

* **gzip**: Baseado no algoritmo DEFLATE, é amplamente utilizado e conhecido por sua alta velocidade de compressão e descompressão, mas oferece uma taxa de compressão moderada.
* **bzip2**: Utiliza o algoritmo Burrows-Wheeler, o que o torna mais lento que o gzip, mas geralmente alcança taxas de compressão superiores.
* **xz**: Baseado no algoritmo LZMA2, oferece as maiores taxas de compressão entre os quatro, mas com um tempo de processamento significativamente mais longo, tanto para compressão quanto para descompressão.
* **zstd** (Zstandard): Desenvolvido pelo Facebook, busca um equilíbrio entre alta velocidade (comparável ao gzip) e excelente taxa de compressão (competindo com xz), sendo uma opção moderna e eficiente.

---

## 2. Escolha do Método de Análise

O método de análise escolhido é a **medição em ambiente real**. Este método se justifica por permitir a obtenção de dados concretos e reprodutíveis do desempenho de cada algoritmo em condições operacionais típicas. A análise não será uma simulação, mas a execução direta dos compressores em um sistema operacional de desktop/servidor padrão, utilizando arquivos de dados variados para garantir a generalidade dos resultados.

* **Ambiente de Medição**: Para garantir a reprodutibilidade e isolamento dos testes, usaremos **Docker**. Isso permite que o ambiente de execução seja o mesmo, independentemente da máquina em que o projeto for executado, eliminando variações causadas por diferentes sistemas operacionais ou versões de pacotes.
* **Ferramentas**:
    * **time**: Ferramenta de linha de comando para medir o tempo de execução de um comando, incluindo tempo real, tempo de usuário e tempo de sistema.
    * **`perf` (Linux Performance Events)**: Ferramenta avançada para profiling de desempenho que permite coletar dados detalhados sobre a atividade da CPU, como *cache misses*, instruções executadas e eventos de agendamento do kernel. Usaremos `perf stat` para obter estatísticas resumidas e `perf record` seguido de `perf report` para analisar o comportamento dos algoritmos em nível de código.
    * **Comando `du -sh`**: Para obter o tamanho dos arquivos antes e depois da compressão.
    * **Scripts em Bash**: Para automatizar a execução de múltiplas rodadas de testes e a coleta de dados, garantindo a consistência dos experimentos.
    * **`iostat`**: Ferramenta para monitorar a atividade de E/S do sistema (leitura/escrita em disco). Essencial para entender o impacto dos algoritmos nos discos, já que a compressão é uma tarefa intensiva em I/O.
    * **`vmstat`**: Ferramenta para monitorar a memória virtual. Útil para entender o uso de memória (principalmente de *swap*) durante a compressão e descompressão de arquivos grandes.

---

## 3. Justificativa da Escolha

A escolha deste objeto de estudo e método de análise se baseia na vivência do grupo e na relevância prática do tema. A compressão de arquivos é uma tarefa rotineira no ambiente de desenvolvimento de software, administração de sistemas e ciência de dados. Compreender os *trade-offs* entre os diferentes algoritmos é crucial para tomar decisões informadas sobre qual ferramenta utilizar em cenários específicos, como backup de dados, distribuição de pacotes de software ou otimização de largura de banda em redes. A **facilidade de reprodução** e a **clareza dos resultados visuais** (gráficos de comparação) tornam este projeto ideal para uma primeira etapa, onde a experiência prática com medição e análise de dados é o foco principal.

---

## 4. Definição das Métricas a Serem Analisadas

As métricas a serem coletadas para cada teste são:

* **Tempo de Compressão**: O tempo total (real) que cada ferramenta leva para compactar um arquivo.
* **Tempo de Descompressão**: O tempo que cada ferramenta leva para descompactar o arquivo gerado.
* **Taxa de Compressão**: Calculada pela fórmula **(Tamanho final do arquivo comprimido / Tamanho inicial do arquivo) * 100**. Esta métrica indica a eficiência de cada algoritmo na redução do tamanho do arquivo.
* **Uso de CPU**: A porcentagem de uso da CPU durante os processos de compressão e descompressão.
* **Uso de Memória**: A quantidade de memória RAM utilizada por cada processo.
* **Atividade de I/O**: A taxa de leitura/escrita em disco durante a execução dos compressores.
* **Eventos de Hardware (com `perf`)**: Dados detalhados de baixo nível, como ciclos de CPU, *cache misses* (leitura/escrita na memória cache) e número de instruções executadas. Essas métricas fornecerão uma visão profunda da eficiência de cada algoritmo no nível do hardware. 

---

## 5. Preparação dos Dados de Teste

Para garantir a aleatoriedade e generalidade dos resultados, os arquivos de teste **não serão fixos**, mas **gerados aleatoriamente**. Isso evita que os resultados sejam enviesados por um tipo de arquivo específico (por exemplo, um arquivo de texto com muitas repetições). Utilizaremos ferramentas como `/dev/urandom` e `dd` para criar arquivos de tamanhos variados e com conteúdo imprevisível. Este método garante que os testes simulem a compressão de dados "reais", sem padrões pré-existentes que possam favorecer ou prejudicar um algoritmo específico.

---

## 6. Cronograma Detalhado

Este cronograma alinha as atividades com as datas de entrega do projeto.

| Período | Atividade | Entregas e Marcos |
| :--- | :--- | :--- |
| **01/09 a 07/09** | **Preparação e Configuração** | **Início do projeto.** Criar a imagem Docker com todas as ferramentas necessárias (compressores, `perf`, `iostat`, etc.). Desenvolver os scripts para a geração de arquivos aleatórios de tamanhos variados. |
| **08/09 a 17/09** | **Desenvolvimento dos Scripts de Teste** | Criar scripts em Bash para automatizar a medição de tempo, tamanho, uso de CPU, memória e I/O. O script deve compactar, descompactar e registrar os dados de cada ferramenta para cada arquivo de teste, incluindo comandos `perf` para a coleta de dados detalhados. |
| **18/09 a 30/09** | **Execução e Coleta de Dados** | Executar os scripts de teste dentro do contêiner Docker. Realizar múltiplas rodadas de medição para cada combinação de compressor e tipo de arquivo. Coletar e organizar os dados brutos em arquivos CSV. |
| **01/10 a 07/10** | **Análise Parcial e Apresentação** | **Apresentação Parcial (08/10).** Processar os dados coletados (usando Python, por exemplo). Elaborar tabelas e gráficos preliminares para mostrar os resultados iniciais da análise. Preparar slides para a apresentação parcial do trabalho, destacando o uso do `perf` na análise. |
| **08/10 a 20/10** | **Análise Final e Redação do Relatório** | Finalizar a análise de dados. Escrever a seção de resultados e discussão, interpretando as métricas e comparando os *trade-offs* entre os compressores. |
| **21/10 a 27/10** | **Revisão e Conclusão** | Revisar e refinar todo o relatório. Escrever a conclusão do trabalho e adicionar quaisquer detalhes finais. |
