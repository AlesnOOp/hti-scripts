-- ============================================================================
-- mysql_size_data_vs_index.sql
-- Reporta o tamanho de cada base de dados MySQL, separando dados e índices.
-- Parte do toolkit dbsize-audit (HTI Tecnologia) — MIT License.
--
-- Uso:
--   mysql -u USUARIO -p < mysql_size_data_vs_index.sql
--   -- ou, para uma base específica:
--   mysql -u USUARIO -p -e "SOURCE mysql_size_data_vs_index.sql"
--
-- Funciona em MySQL 5.7+, MariaDB 10.x+. Não requer privilégios especiais
-- além de SELECT em information_schema (disponível para qualquer usuário
-- autenticado por padrão).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) Visão geral: tamanho total por base de dados, dados vs índice, em %
-- ---------------------------------------------------------------------------
SELECT
    table_schema                                            AS banco,
    COUNT(*)                                                AS tabelas,
    ROUND(SUM(data_length) / 1024 / 1024, 2)                AS dados_mb,
    ROUND(SUM(index_length) / 1024 / 1024, 2)                AS indices_mb,
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2)  AS total_mb,
    ROUND(
        100 * SUM(data_length) / NULLIF(SUM(data_length + index_length), 0), 1
    )                                                        AS pct_dados,
    ROUND(
        100 * SUM(index_length) / NULLIF(SUM(data_length + index_length), 0), 1
    )                                                        AS pct_indices
FROM information_schema.tables
WHERE table_schema NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys')
GROUP BY table_schema
ORDER BY total_mb DESC;

-- ---------------------------------------------------------------------------
-- 2) Detalhe por tabela — útil pra achar onde o espaço está concentrado
--    Ajuste o WHERE table_schema = '...' para a base de interesse
-- ---------------------------------------------------------------------------
SELECT
    table_schema                                            AS banco,
    table_name                                              AS tabela,
    engine,
    table_rows                                              AS linhas_aprox,
    ROUND(data_length / 1024 / 1024, 2)                     AS dados_mb,
    ROUND(index_length / 1024 / 1024, 2)                     AS indices_mb,
    ROUND((data_length + index_length) / 1024 / 1024, 2)     AS total_mb,
    ROUND(
        100 * index_length / NULLIF(data_length + index_length, 0), 1
    )                                                        AS pct_indices
FROM information_schema.tables
WHERE table_schema NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys')
    -- AND table_schema = 'nome_do_seu_banco'  -- descomente para filtrar
ORDER BY total_mb DESC
LIMIT 25;

-- ---------------------------------------------------------------------------
-- Nota sobre precisão:
-- table_rows, data_length e index_length no InnoDB são ESTIMATIVAS baseadas
-- em estatísticas internas, não contagem exata. Para números exatos em uma
-- tabela específica, rode ANALYZE TABLE nome_da_tabela; antes de consultar,
-- ou use SELECT COUNT(*) diretamente (mais lento em tabelas grandes).
-- ============================================================================
