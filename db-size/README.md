# dbsize-audit

Scripts simples para responder uma pergunta que todo DBA faz cedo ou tarde:
**"quanto do meu banco é dado de verdade, e quanto é índice?"**

Três scripts, um por SGBD — sem dependências externas, sem instalação, só
rodar e ler o resultado.

| Script | SGBD | Requisito |
|---|---|---|
| `mysql_size_data_vs_index.sql` | MySQL / MariaDB | Leitura em `information_schema` |
| `postgresql_size_data_vs_index.sql` | PostgreSQL | Leitura no catálogo do banco conectado |
| `postgresql_size_all_databases.sh` | PostgreSQL (cluster inteiro) | `psql` no PATH |
| `sqlserver_size_data_vs_index.sql` | SQL Server / Azure SQL | `VIEW DATABASE STATE` |

## Por que isso importa

Um banco com índice desproporcional ao volume de dados geralmente indica
índices redundantes, duplicados ou nunca usados — cada um deles consome
espaço em disco e desacelera toda escrita (`INSERT`/`UPDATE`/`DELETE`)
precisa manter). Rodar esse diagnóstico antes de decidir escalar
verticalmente (mais disco, mais RAM) frequentemente revela que o problema
real é limpeza de índice, não capacidade.

## Uso rápido

```bash
# MySQL
mysql -u usuario -p < mysql_size_data_vs_index.sql

# PostgreSQL — um banco
psql -U usuario -d meu_banco -f postgresql_size_data_vs_index.sql

# PostgreSQL — todos os bancos do cluster
./postgresql_size_all_databases.sh -h localhost -U usuario

# SQL Server
sqlcmd -S servidor -d meu_banco -i sqlserver_size_data_vs_index.sql
```

## O que cada script entrega

1. **Visão geral** — total de dados, total de índices, e o percentual de
   cada um, agregado no nível do banco.
2. **Detalhe por tabela** — as 25 tabelas que mais consomem espaço,
   ordenadas por tamanho total, com o mesmo breakdown dado/índice.

## Limitações conhecidas

- MySQL: `data_length`/`index_length` do InnoDB são estimativas baseadas em
  estatísticas internas — rode `ANALYZE TABLE` antes para maior precisão.
- PostgreSQL: cada conexão enxerga só o próprio banco — use o script `.sh`
  para rodar em todos os bancos do cluster de uma vez.
- SQL Server: sem visão cross-database nativa sem depender de procedures
  não documentadas — troque o banco da conexão manualmente se precisar
  auditar vários.

## Licença

MIT — use, copie, modifique e redistribua livremente.

## Sobre

Mantido pela [HTI Tecnologia](https://hti.com.br) — consultoria, DBA remoto
24/7 e suporte especializado em MySQL, PostgreSQL, SQL Server, Oracle e
MongoDB desde 1990.

Encontrou um bug ou quer sugerir um ajuste? Abra uma issue ou um PR.
