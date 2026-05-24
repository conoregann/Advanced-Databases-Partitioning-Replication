# Advanced Databases: Partitioning and Replication

Portfolio repository for an Advanced Databases project demonstrating distributed database design, partitioning strategies, replication, and CAP theorem trade-offs across PostgreSQL, Cassandra, and CouchDB.

## Project Highlights

- Built a Docker-based multi-database environment with PostgreSQL, a three-node Cassandra cluster, and a two-node CouchDB cluster.
- Implemented PostgreSQL range, list, and hash partitioning over a data warehouse sales fact table.
- Designed Cassandra keyspaces with different replication factors and tested consistency levels under node failure.
- Configured CouchDB replication workflows, partitioned datasets, and conflict handling.
- Captured screenshots and exported scripts/data to make the experiments reproducible and reviewable.

## Repository Structure

```text
.
├── Setup/
│   └── docker-compose.yml
├── PostgreSQL/
│   ├── Scripts/
│   └── Query Screenshots/
├── Cassandra/
│   ├── Scripts/
│   └── *.png
├── CouchDB/
│   ├── Scripts & JSON/
│   └── *.png
└── C22466756 Report.pdf
```

## Technologies

- PostgreSQL 17
- Apache Cassandra
- Apache CouchDB
- Docker Compose
- SQL, CQL, JSON, and CouchDB replication APIs

## Getting Started

1. Copy the example environment file:

   ```bash
   cp .env.example .env
   ```

2. Start the database stack:

   ```bash
   cd Setup
   docker compose up -d
   ```

3. Connect to the services:

   | Service | Port | Purpose |
   | --- | --- | --- |
   | PostgreSQL | `5432` | Data warehouse schema and partitioning experiments |
   | Cassandra node 1 | `9042` | Primary CQL connection |
   | Cassandra node 2 | `9043` | Failover/cluster testing |
   | Cassandra node 3 | `9044` | Failover/cluster testing |
   | CouchDB node 1 | `5984` | CouchDB database and replication testing |
   | CouchDB node 2 | `5985` | CouchDB replication target/source |

## Reproducing the Work

### PostgreSQL

Run the SQL files in this order:

1. `PostgreSQL/Scripts/dw_schema_C22466756.sql`
2. `PostgreSQL/Scripts/dw_etl_C22466756.sql`
3. `PostgreSQL/Scripts/Partitioning_C22466756.sql`
4. `PostgreSQL/Scripts/Partitioning_Queries_C22466756.sql`

The partitioning scripts demonstrate range partitioning by date, list partitioning by region, and hash partitioning by order identifier.

### Cassandra

Run:

```bash
docker exec -it cassandra1_C22466756 cqlsh
```

Then execute `Cassandra/Scripts/cassandra_C22466756.cql`. The script creates RF=1 and RF=3 keyspaces, inserts collection-based purchase records, enables tracing, and tests consistency behavior during a simulated node outage.

### CouchDB

Use the files in `CouchDB/Scripts & JSON/` to reproduce partitioning, replication, exported database state, and replicator configuration. Screenshots in `CouchDB/` show one-time replication, continuous replication, bidirectional replication, partition queries, and conflict handling.

## Evidence

The repository includes the final PDF report and screenshots of the main experiments so reviewers can inspect the results without needing to run the full stack.

## Notes

Runtime database files are intentionally excluded from Git. Docker named volumes are used for local persistence, while the portable scripts, exported JSON, report, and screenshots are versioned for review.
