# Анализ графа связей между друзьями в вконтакте

Основные результаты представлены в презентации. С кодом можно ознакомиться в ноутбуке.<br>
Анализ включал в себя следующие пункты:
### 1. Network Summary
    - Type of the graph. Size (number of nodes) and order (number of edges)
    - Node/Edge attributes
    - Diameter, radius
    - Clustering Coefficient (global, average local, histogram of locals)
    - Average path length (+histogram)
    - Degree distribution
### 2. Structural Analysis
    - Degree/Closeness/Betweenness/Katz centralities. Top nodes interpretation
    - Page-Rank. Correlation comparison of centralities and prestige. Comparison of top nodes.
    - Node structural equivalence/similarity.
    - Assortative Mixing according to node attributes.
    - The closest random graph model similar to social network (Erdős-Rényi, Barabási–Albert model, Watts–Strogatz)
### 3. Community Detection
    - Modularity for quality criterion
    - Community detection algorithms with interpretations
        - Agglomerative Clustering
        - Girvan-Newman algorithm
        - k-cores decomposition
    - Clique search
