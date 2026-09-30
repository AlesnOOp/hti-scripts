-- ============================================================================
-- postgresql_size_data_vs_index.sql
-- Reporta o tamanho das tabelas no banco atual, separando dados e índices.
-- Parte do toolkit dbsize-audit (HTI Tecnologia) — MIT License.
--
-- Uso:
--   psql -U USUARIO -d NOME_DO_BANCO -f postgresql_size_data_vs_index.sql
--
-- IMPORTANTE: no PostgreSQL, ao contrário do MySQL, uma conexão enxerga
-- apenas o banco (database) ao qual está conectada — não existe uma visão
-- cross-database nativa. Para rodar em todos os bancos do cluster, use o
-- wrapper postgresql_size_all_databases.sh incluído neste toolkit.
--
-- Funciona em PostgreSQL 10+. Requer apenas privilégio de leitura no
-- catálogo (disponível por padrão para qualquer usuário autenticado).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) Visão geral: total do banco atual, dados vs índice, em %
-- ---------------------------------------------------------------------------
SELECT
    current_database()                                           AS banco,
    COUNT(*)                                                      AS tabelas,
    pg_size_pretty(SUM(pg_table_size(c.oid)))                     AS dados,
    pg_size_pretty(SUM(pg_indexes_size(c.oid)))                   AS indices,
    pg_size_pretty(SUM(pg_total_relation_size(c.oid)))            AS total,
    ROUND(
        100.0 * SUM(pg_table_size(c.oid))
        / NULLIF(SUM(pg_total_relation_size(c.oid)), 0), 1
    )                                                              AS pct_dados,
    ROUND(
        100.0 * SUM(pg_indexes_size(c.oid))
        / NULLIF(SUM(pg_total_relation_size(c.oid)), 0), 1
    )                                                              AS pct_indices
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r'
    AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast');

-- ---------------------------------------------------------------------------
-- 2) Detalhe por tabela — útil pra achar onde o espaço está concentrado
-- ---------------------------------------------------------------------------
SELECT
    n.nspname                                                     AS schema,
    c.relname                                                     AS tabela,
    pg_size_pretty(pg_table_size(c.oid))                          AS dados,
    pg_size_pretty(pg_indexes_size(c.oid))                        AS indices,
    pg_size_pretty(pg_total_relation_size(c.oid))                 AS total,
    ROUND(
        100.0 * pg_indexes_size(c.oid)
        / NULLIF(pg_total_relation_size(c.oid), 0), 1
    )                                                              AS pct_indices
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r'
    AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
ORDER BY pg_total_relation_size(c.oid) DESC
LIMIT 25;

-- ---------------------------------------------------------------------------
-- Nota: pg_table_size() já inclui TOAST e o forkmap, mas EXCLUI índices;
-- pg_indexes_size() soma todos os índices da tabela; pg_total_relation_size()
-- é a soma dos dois. Essa é a forma correta de medir — evite usar apenas
-- pg_relation_size() sozinho, que ignora TOAST e subestima tabelas com
-- colunas grandes (text, jsonb, bytea).
-- ============================================================================
