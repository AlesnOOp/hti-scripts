-- ============================================================================
-- sqlserver_size_data_vs_index.sql
-- Reporta o tamanho do banco atual, separando dados e índices.
-- Parte do toolkit dbsize-audit (HTI Tecnologia) — MIT License.
--
-- Uso:
--   sqlcmd -S SERVIDOR -d NOME_DO_BANCO -i sqlserver_size_data_vs_index.sql
--   -- ou rode direto no SSMS / Azure Data Studio, conectado ao banco alvo
--
-- Funciona em SQL Server 2012+ e Azure SQL Database. Requer apenas
-- permissão de leitura nas DMVs do sistema (VIEW DATABASE STATE).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) Visão geral: total do banco atual, dados vs índice, em %
--    (index_id = 0 ou 1 = dados da tabela; index_id > 1 = índices não-clusterizados)
-- ---------------------------------------------------------------------------
SELECT
    DB_NAME()                                                     AS banco,
    COUNT(DISTINCT ps.object_id)                                  AS tabelas,
    CAST(SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.used_page_count ELSE 0 END)
        * 8.0 / 1024 AS DECIMAL(12,2))                            AS dados_mb,
    CAST(SUM(CASE WHEN ps.index_id > 1 THEN ps.used_page_count ELSE 0 END)
        * 8.0 / 1024 AS DECIMAL(12,2))                            AS indices_mb,
    CAST(SUM(ps.used_page_count) * 8.0 / 1024 AS DECIMAL(12,2))   AS total_mb,
    CAST(
        100.0 * SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.used_page_count ELSE 0 END)
        / NULLIF(SUM(ps.used_page_count), 0) AS DECIMAL(5,1))     AS pct_dados,
    CAST(
        100.0 * SUM(CASE WHEN ps.index_id > 1 THEN ps.used_page_count ELSE 0 END)
        / NULLIF(SUM(ps.used_page_count), 0) AS DECIMAL(5,1))     AS pct_indices
FROM sys.dm_db_partition_stats ps
JOIN sys.tables t ON t.object_id = ps.object_id
WHERE t.is_ms_shipped = 0;

-- ---------------------------------------------------------------------------
-- 2) Detalhe por tabela — útil pra achar onde o espaço está concentrado
-- ---------------------------------------------------------------------------
SELECT
    t.name                                                        AS tabela,
    CAST(SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.used_page_count ELSE 0 END)
        * 8.0 / 1024 AS DECIMAL(12,2))                            AS dados_mb,
    CAST(SUM(CASE WHEN ps.index_id > 1 THEN ps.used_page_count ELSE 0 END)
        * 8.0 / 1024 AS DECIMAL(12,2))                            AS indices_mb,
    CAST(SUM(ps.used_page_count) * 8.0 / 1024 AS DECIMAL(12,2))   AS total_mb,
    CAST(
        100.0 * SUM(CASE WHEN ps.index_id > 1 THEN ps.used_page_count ELSE 0 END)
        / NULLIF(SUM(ps.used_page_count), 0) AS DECIMAL(5,1))     AS pct_indices
FROM sys.dm_db_partition_stats ps
JOIN sys.tables t ON t.object_id = ps.object_id
WHERE t.is_ms_shipped = 0
GROUP BY t.name
ORDER BY total_mb DESC;

-- ---------------------------------------------------------------------------
-- Nota: este script reporta o banco ao qual a conexão está ativa (não existe
-- visão cross-database nativa no SQL Server sem sp_MSforeachdb, que é uma
-- procedure não documentada oficialmente — por isso não a usamos aqui).
-- Para rodar em múltiplos bancos, troque o banco na conexão e execute de novo,
-- ou use sqlcmd em loop a partir de uma lista de bancos via
-- sys.databases WHERE database_id > 4 (exclui bancos de sistema).
-- ============================================================================
