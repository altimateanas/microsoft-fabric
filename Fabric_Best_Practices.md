# Microsoft Fabric Best Practices

A practical reference for building production-grade analytics on Microsoft Fabric, covering medallion architecture, semantic models, and Power BI reports.

---

## Table of Contents

1. [Medallion Architecture](#1-medallion-architecture)
2. [Semantic Layer (Power BI Semantic Models)](#2-semantic-layer-power-bi-semantic-models)
3. [Power BI Reports and Dashboards](#3-power-bi-reports-and-dashboards)
4. [Cross-Cutting Concerns](#4-cross-cutting-concerns)

---

## 1. Medallion Architecture

The medallion pattern organizes data into progressively refined layers — **bronze (raw)**, **silver (cleansed)**, and **gold (curated)** — each with distinct quality, structure, and consumer expectations.

### 1.1 Workspace and Storage Design

- **Separate workspaces by stage when at scale.** A single workspace per layer (`Bronze_WS`, `Silver_WS`, `Gold_WS`) provides clean security boundaries, independent capacity allocation, and simpler permissions. For smaller projects, separate Lakehouses or schemas within one workspace work fine.
- **Use OneLake shortcuts to avoid data duplication.** Reference external sources (ADLS Gen2, S3, Dataverse) via shortcuts rather than copying data into bronze. Shortcuts are zero-copy and respect source-side updates.
- **Pick the right item type per layer.** Lakehouses are best for raw and semi-structured bronze data and Spark/notebook workloads. Warehouses are best for silver and gold when transformations are SQL-centric and consumers are BI tools. Mixing is normal — don't over-standardize.
- **Use a domain-aligned folder structure within each layer.** Group tables by business domain (`sales/`, `finance/`, `hr/`) rather than by source system. Domain alignment makes ownership and governance clearer.
- **Keep raw data immutable.** Bronze tables should be append-only or replace-only — never edited in place. This guarantees replay capability and audit traceability.

### 1.2 Bronze Layer (Raw)

- **Land data with minimal transformation.** Preserve source schemas and types as faithfully as possible. The only acceptable transformations are format normalization (CSV/JSON to Delta) and partition addition.
- **Add ingestion metadata to every row.** Include `_ingested_at`, `_source_system`, `_source_file`, and `_batch_id` columns. These are essential for debugging, replay, and lineage.
- **Partition by ingestion date.** Use `_ingested_date` (or equivalent) as the primary partition key. This pattern is universally useful for retention, replay, and incremental processing.
- **Retain history.** Bronze is your system of record for raw data. Configure Delta retention to match your audit and compliance requirements (often 90+ days).
- **Document source contracts.** Maintain a per-source schema document describing expected columns, types, nullability, and known quirks. Update it when sources change.

### 1.3 Silver Layer (Cleansed and Conformed)

- **Apply data quality rules and reject failures.** Validate types, ranges, referential integrity, and required fields. Quarantine invalid rows in a `_rejects` table rather than failing the whole batch.
- **Standardize naming conventions.** Lowercase snake_case throughout (`customer_id`, not `CustomerID` or `customerId`). Pick one convention and enforce it across all silver tables.
- **Deduplicate deterministically.** Use surrogate keys or natural-key + timestamp combinations. Document the dedup strategy per table.
- **Conform across sources.** If two source systems both have customers, silver should produce a unified customer dataset with consistent identifiers, not two parallel tables.
- **Avoid business logic.** Silver is for cleansing and conforming; business rules and aggregations belong in gold. Mixing levels makes silver tables inconsistent in scope.
- **Use SCD Type 2 where history matters.** For dimensions where historical context is required, implement Slowly Changing Dimensions Type 2 with `valid_from`, `valid_to`, and `is_current` columns.

### 1.4 Gold Layer (Curated, Business-Ready)

- **Model as a star schema.** Conformed dimensions surrounded by fact tables. Avoid normalized 3NF structures — they kill semantic model performance.
- **Use surrogate keys on dimensions.** Integer surrogate keys outperform natural keys for joins and compression. Keep natural keys as columns, but join on surrogates.
- **Establish clear grain for every fact.** Document the grain (e.g., "one row per order line per day") in table comments. Mixed-grain facts cause analytical errors that are painful to diagnose.
- **Pre-aggregate when it makes sense.** If a measure is always queried at month-level, materialize a monthly aggregate table. Direct Lake performs well, but reducing scan size still helps.
- **Apply V-Order optimization.** Run `OPTIMIZE` with V-Order on gold Delta tables. This significantly improves Direct Lake query performance.
- **Run `OPTIMIZE` and `VACUUM` regularly.** Compact small files weekly; vacuum old versions monthly. Small-file proliferation is the #1 cause of degraded Lakehouse performance.
- **Choose Direct Lake-friendly data types.** Prefer `INT`, `BIGINT`, `DECIMAL`, `DATE`, `DATETIME2`, `VARCHAR`. Avoid types that trigger DirectQuery fallback.
- **Document semantic intent.** Add SQL comments or extended properties describing what each fact and dimension represents in business terms.

### 1.5 Transformation Patterns

- **Pick one transformation engine per layer.** Mixing notebooks, stored procedures, and dataflows in the same layer creates a maintenance nightmare. Standardize.
- **Stored procedures for SQL-centric workflows.** When transformations are set-based and the team has T-SQL skills, stored procs in a Warehouse are the simplest and fastest path. Version them in Git.
- **Notebooks for procedural or ML workflows.** Use PySpark notebooks when transformations involve complex string parsing, ML feature engineering, or non-tabular data.
- **Dataflows Gen2 for citizen-developer scenarios only.** Power Query is approachable but harder to version, test, and review. Avoid for production-critical pipelines.
- **Keep transformations idempotent.** Running the same job twice should produce the same result. Use `MERGE` or `INSERT OVERWRITE` patterns, not blind appends.
- **Make transformations incremental where possible.** Process only new or changed data using watermark columns or change data feed (CDF). Full reloads should be the exception.

### 1.6 Orchestration

- **Use Fabric Data Pipelines as the orchestrator.** Built on the same engine as Azure Data Factory, with native Fabric integration. Don't introduce ADF unless you have a specific cross-platform need.
- **Define explicit dependencies.** Stored procs and notebooks don't have a built-in DAG. Encode dependencies in the pipeline graph or in a master orchestration procedure.
- **Schedule incrementally.** Run silver right after bronze completes, gold right after silver completes. Avoid fixed-time schedules that race against ingestion.
- **Implement retry and alerting.** Configure pipeline-level retries with exponential backoff. Alert on failure to a monitored channel (Teams, email, PagerDuty).
- **Make runs observable.** Log start/end times, row counts, and outcome to a dedicated monitoring table. Reference this table for SLA reporting.

### 1.7 Testing and Data Quality

- **Test every layer.** Bronze: schema and ingestion tests. Silver: deduplication, NULL rates, referential integrity. Gold: row counts, aggregates, business rule validation.
- **Adopt a testing framework.** tSQLt for T-SQL, PyTest for Python, or a custom framework. The framework matters less than the discipline of running tests in CI.
- **Write data contracts for handoffs between layers.** A contract specifies the schema, freshness, and quality guarantees that downstream consumers can rely on.
- **Use Great Expectations or equivalent for proactive data quality.** Define expectations once and run them across layers as part of the pipeline.
- **Track quality metrics over time.** Row counts, NULL rates, and distinct value counts trended over weeks reveal slow-moving problems before they become incidents.

### 1.8 Security and Governance

- **Apply Row-Level Security at the lowest layer that needs it.** RLS in the Warehouse or semantic model is fine; pushing it earlier is rarely necessary.
- **Use sensitivity labels consistently.** Label tables containing PII or financial data at creation. Labels propagate downstream automatically.
- **Mask PII early.** If silver doesn't need raw PII for processing, mask or tokenize it during the bronze-to-silver transformation.
- **Limit production access.** Only the service principal running pipelines should have write access to gold. Humans get read-only.
- **Audit data access.** Enable Fabric audit logging and review periodically — especially for gold-layer access patterns.

---

## 2. Semantic Layer (Power BI Semantic Models)

The semantic model is the contract between your data and every analytical consumer. Investment here pays off across reports, Excel users, embedded apps, and AI-driven Q&A.

### 2.1 Architecture and Modeling Approach

- **Model as a star schema. Always.** Power BI's engine is optimized for star schemas. Snowflake or normalized models cause performance and DAX complexity issues.
- **Use Direct Lake mode by default on Fabric.** Direct Lake reads OneLake Delta files directly — no import, no refresh, near-import performance. It is the strategic default for Fabric semantic models.
- **Fall back to Import mode for small models with complex transformations.** Use Import when the model is small (< 10GB), needs Power Query transformations, or the source isn't OneLake-native.
- **Avoid DirectQuery unless required.** DirectQuery has performance and feature limitations. Use it only when data must be live and Direct Lake isn't viable.
- **One business-aligned model per domain.** Don't build one giant model covering everything. Don't build one model per report either. Aim for one model per business domain (sales, finance, supply chain).

### 2.2 Tables and Relationships

- **Hide foreign-key columns from report view.** Right-click → Hide. Users should never drag FK columns onto visuals.
- **Use single-direction relationships by default.** Many-to-one from fact to dimension. Bidirectional cross-filtering is occasionally necessary but causes ambiguity and performance issues.
- **One active relationship per table pair.** Multiple active relationships create ambiguity. Use inactive relationships with `USERELATIONSHIP()` in DAX when needed.
- **Mark date tables explicitly.** Right-click your date table → Mark as date table. This enables time intelligence functions to work correctly.
- **Always include a dedicated date dimension.** Don't rely on auto-generated date hierarchies. A proper `dim_date` with fiscal calendar, holidays, and business-day flags is essential.
- **Avoid calculated columns where measures will do.** Calculated columns consume memory and don't compose well. Prefer measures unless you specifically need a column for filtering or grouping.

### 2.3 Measures and DAX

- **Centralize all measures in the semantic model.** Never define measures in individual reports — every consumer must see the same definitions.
- **Use a dedicated measure table.** Create an empty table called `_Measures` and put all measures there. This separates measures from data tables visually and organizes them for users.
- **Organize measures with display folders.** Use `displayFolder` to group measures by domain ("Revenue", "Profitability", "Customer Counts"). Users find them faster.
- **Set format strings on every measure.** `FORMAT "$#,##0"` for currency, `"0.00%"` for percentages. Don't rely on report-level formatting.
- **Use variables (`VAR`) for readability and performance.** Calculate intermediate values once, reference them multiple times. Improves both DAX clarity and engine optimization.
- **Use `DIVIDE()` instead of `/`.** `DIVIDE` handles division-by-zero gracefully without errors.
- **Use `CALCULATE()` over `FILTER()` for simple filters.** `CALCULATE([Measure], column = value)` is dramatically faster than `CALCULATE([Measure], FILTER(table, table[column] = value))`.
- **Avoid iterators on large tables.** `SUMX`, `AVERAGEX`, etc., over fact tables can be slow. Look for set-based alternatives first.
- **Document complex measures.** Use TMDL `description` fields to explain what a measure calculates and any business rules embedded in it.

### 2.4 Naming Conventions

- **Use business-friendly names with proper capitalization.** `Total Revenue`, not `total_revenue` or `TotalRevenue`. Users see these names directly.
- **Be consistent.** Pick a convention (`Total X`, `X Amount`, `# of X`) and apply it everywhere. Inconsistency erodes trust.
- **Prefix internal helpers.** Use a prefix like `_` or `Helper_` for measures not intended for direct user consumption. Hide them or place them in a `_Internal` folder.
- **Avoid abbreviations.** `Customer Acquisition Cost`, not `CAC`. Spell out terms; users searching the field list won't always know acronyms.
- **Suffix with units when ambiguous.** `Average Order Value (USD)`, `Response Time (Seconds)`. Reduces ambiguity in reports consumed by mixed audiences.

### 2.5 Direct Lake Specifics

- **Verify Direct Lake readiness before deploying.** Some data types (e.g., `BINARY`, certain `DECIMAL` precisions) trigger DirectQuery fallback. Validate in advance.
- **Avoid calculated columns in Direct Lake models where possible.** They force fallback for any query touching them.
- **Avoid composite models with Direct Lake.** Mixing Direct Lake with Import or DirectQuery introduces complexity and limits optimization.
- **Monitor fallback frequency.** Use Fabric capacity metrics or DAX Studio to detect when queries fall back to DirectQuery. Frequent fallback indicates a modeling issue.
- **Reframe instead of refresh.** Direct Lake doesn't refresh — it reframes (picks up new Delta files). Trigger reframes only when necessary; Fabric handles most automatically.

### 2.6 Row-Level Security

- **Define RLS at the model layer.** This way every report consuming the model inherits the security automatically.
- **Use dynamic RLS based on user identity.** `USERPRINCIPALNAME()` or `USERNAME()` matched against a security dimension. Avoids per-user role definitions.
- **Test RLS with multiple identities.** Use "View as" in Power BI Desktop or Tabular Editor to simulate different users before deploying.
- **Document the security model.** Maintain a doc explaining who sees what, with examples. Auditors and new team members will need it.
- **Avoid Object-Level Security (OLS) unless truly necessary.** OLS hides columns or tables entirely from unauthorized users. Powerful, but adds significant complexity.

### 2.7 Code-First Workflow

- **Define models as TMDL in Git.** Power BI Desktop's `.pbix` is a binary; TMDL is text. Code-first enables pull requests, diffs, and CI/CD.
- **Use Tabular Editor for advanced authoring.** Calculation groups, perspectives, translations, and bulk operations are dramatically easier in Tabular Editor than in Desktop.
- **Run Best Practice Analyzer in CI.** The community-maintained BPA ruleset catches naming, performance, and modeling issues automatically.
- **Use deployment pipelines for environment promotion.** Dev → Test → Prod via Fabric Deployment Pipelines or custom CI/CD with the XMLA endpoint.
- **Version control everything.** TMDL files, BPA rules, deployment scripts, RLS test cases — all in Git.

### 2.8 Performance Optimization

- **Reduce cardinality where possible.** High-cardinality columns (especially text) consume memory and slow queries. Truncate timestamps to dates if seconds aren't needed.
- **Use integer keys for joins.** Always faster than string or GUID keys.
- **Avoid bidirectional relationships on large tables.** They expand the filter context dramatically and degrade performance.
- **Profile slow measures with DAX Studio.** Run server timings to see what's actually slow. Don't optimize blindly.
- **Use aggregation tables for common queries.** For very large fact tables, pre-aggregated summary tables can speed up dashboards substantially.
- **Limit visuals per report page.** Each visual is a query. Pages with 20+ visuals slow down. Aim for 6-10 visuals per page.

---

## 3. Power BI Reports and Dashboards

Reports are how the work above reaches users. Good reports are clear, fast, and respect the user's time.

### 3.1 Design Principles

- **Start with the audience and the question.** What decision does this report support? Who is the reader? Design backward from the answer.
- **One question per page.** Don't try to answer five questions on one page. Use multiple pages with clear navigation.
- **Lead with the most important number.** Headline KPIs at the top. Detail and breakdowns below.
- **Use the F-pattern or Z-pattern layout.** Eyes scan in predictable patterns. Place key information along these paths.
- **Limit colors deliberately.** Use a corporate palette (3-5 colors max). Reserve red for negative/alerts, green for positive — and only use them when the meaning is genuinely positive or negative.
- **Avoid 3D charts, exploded pies, and gimmicks.** They obscure data and look unprofessional.

### 3.2 Visual Selection

- **Match the visual to the question.** Trends → line chart. Comparison → bar chart. Composition → stacked bar or treemap. Distribution → histogram or box plot. Relationship → scatter plot.
- **Avoid pie charts for more than 4-5 slices.** Bar charts are almost always more readable.
- **Use small multiples (multi-row card or facet visuals) for comparisons.** Easier to compare across categories than overlaying lines.
- **Tables and matrices for detailed data.** When precise numbers matter, a well-formatted table beats any chart.
- **Use cards for single KPIs.** With supporting context (target, trend arrow, comparison period).
- **Add reference lines.** Targets, averages, and benchmarks make charts immediately interpretable.

### 3.3 Performance

- **Build on top of a well-designed semantic model.** The biggest performance lever is the model, not the report.
- **Limit visuals per page (6-10 typical, 12 max).** Each visual issues a query. More visuals = slower page load.
- **Avoid "Show items with no data" unless necessary.** It significantly increases query cost.
- **Disable interactions where they're not needed.** Edit interactions to remove unnecessary cross-filtering between visuals.
- **Use slicers sparingly.** Each slicer is a query. Filter pane is often a better choice for less-used filters.
- **Profile with Performance Analyzer.** Built into Power BI Desktop. Identifies which visuals are slow and why.
- **Cache where possible.** Direct Lake handles this automatically; for Import models, schedule refresh during off-hours.

### 3.4 Interactivity

- **Use bookmarks for guided narratives.** Walk users through a data story with predefined views.
- **Implement drill-through for detail.** Right-click a region → drill through to a detail page filtered to that region.
- **Use tooltips to add context without clutter.** Hover-over tooltips can show additional measures, mini-charts, or text.
- **Enable cross-filtering thoughtfully.** Default cross-filtering is powerful but can confuse users. Test with non-technical users.
- **Add "Reset filters" buttons.** Users get lost in deeply filtered states. Make it easy to return to default.

### 3.5 Accessibility

- **Use sufficient color contrast.** Aim for WCAG AA (4.5:1 for normal text, 3:1 for large text).
- **Don't rely on color alone.** Use icons, labels, or shapes alongside color to convey meaning. Helps colorblind users and printed reports.
- **Add alt text to visuals.** Right-click → Format → Alt text. Screen readers depend on this.
- **Set tab order on report pages.** Format pane → Tab order. Logical keyboard navigation is essential for accessibility.
- **Test with the Accessibility Insights tool.** Microsoft's free tool catches common accessibility issues.

### 3.6 Mobile and Responsive Design

- **Build a dedicated mobile layout.** Don't assume the desktop layout will work on a phone — it won't.
- **Prioritize KPIs on mobile.** Mobile users want quick answers, not detailed exploration.
- **Use the Power BI mobile app for testing.** What looks good in the browser may not work in the app.
- **Configure dashboard tiles for mobile.** Dashboards have separate mobile views — set them up explicitly.

### 3.7 Reports vs. Dashboards

- **Reports are multi-page, interactive analytical documents.** Built in Desktop or web, support rich interactivity, drill-through, bookmarks.
- **Dashboards are single-page collections of pinned tiles.** Designed for at-a-glance monitoring across multiple reports and data sources.
- **Use dashboards for executive monitoring.** A "single pane of glass" with the most important KPIs from multiple domains.
- **Use reports for operational and analytical work.** Detailed exploration, what-if analysis, drill-through investigation.
- **Don't pin everything.** Dashboards become noise when overloaded. Curate ruthlessly.

### 3.8 Distribution and Lifecycle

- **Use Power BI Apps for distribution.** Apps bundle reports and dashboards with controlled access — users see a clean published experience, not the workspace.
- **Certify production datasets and reports.** Endorsement (Promoted → Certified) signals trust and surfaces in search.
- **Monitor usage.** Power BI usage metrics show who's using reports and how often. Retire unused reports to reduce clutter.
- **Set up subscriptions thoughtfully.** Email subscriptions are powerful but can spam users. Default to opt-in.
- **Document data refresh schedules and SLAs.** Users need to know when data is fresh and when to expect updates.
- **Plan for report deprecation.** Retire old versions when new ones are published. Confused users with multiple versions of "the dashboard" is a common organizational pain.

### 3.9 Authoring Workflow

- **Use Power BI Desktop for authoring.** The web editor has improved but still lacks features. Desktop is the production authoring tool.
- **Connect reports to deployed semantic models, not local data.** Reports should reference the certified semantic model in the workspace, not contain their own data.
- **Use thin reports.** A "thin report" has no data of its own — it's purely visualization on top of a shared semantic model. This is the recommended pattern.
- **Version reports in Git via Fabric Git integration.** Reports can be serialized to PBIR (Power BI Report) format and stored as text. Pull-request reviews work for visuals too.
- **Use templates for consistency.** Create a `.pbit` template with corporate themes, standard fonts, and placeholder visuals. New reports start from the template.

### 3.10 Copilot and AI Features

- **Invest in semantic model quality to enable Copilot.** Copilot in Power BI uses the semantic model. Good measure names, descriptions, and synonyms dramatically improve answer quality.
- **Add synonyms for Q&A.** Configure synonyms so users can ask "sales" or "revenue" or "income" and get the same measure.
- **Define measure descriptions.** Copilot uses descriptions to choose the right measure. Vague or missing descriptions produce poor answers.
- **Test Copilot with real user questions.** Run a sample of actual user questions through Copilot before rolling it out broadly.
- **Set expectations.** Copilot is a powerful aid, not infallible. Train users to verify critical numbers against trusted reports.

---

## 4. Cross-Cutting Concerns

Some practices apply across all three areas above and deserve their own treatment.

### 4.1 Code-First and CI/CD

- **Everything in Git.** SQL, TMDL, pipeline definitions, RLS test cases, BPA rules, deployment scripts.
- **Pull-request review for all changes.** No direct edits to production. Two-person review for critical changes.
- **Automated linting in CI.** SQL linting, DAX best practices, TMDL validation. Block merges that fail.
- **Deployment pipelines for promotion.** Dev → Test → Prod with explicit gates. Use Fabric Deployment Pipelines or custom CI/CD.
- **Rollback strategy.** Every deployment should have a clear rollback path — revert the Git commit and redeploy.

### 4.2 Capacity and Cost

- **Right-size capacity from observed usage.** Start with a smaller SKU and scale up based on telemetry. Over-provisioning is the most common cost mistake.
- **Monitor Capacity Units (CUs) actively.** Use the Capacity Metrics App. Investigate spikes promptly.
- **Identify expensive operations.** Direct Lake reframes, large refreshes, and inefficient DAX queries are the typical culprits.
- **Use auto-scale or dedicated capacities for spiky workloads.** Don't let one workload starve others.
- **Schedule heavy work off-hours.** Refreshes, optimization jobs, and bulk loads can run overnight.

### 4.3 Documentation

- **Document the data flow.** A diagram showing source → bronze → silver → gold → semantic model → reports is invaluable for onboarding.
- **Document business definitions.** What does "active customer" mean? "Revenue" — net of refunds? Maintain a glossary.
- **Document data ownership.** Who owns each table, model, and report. Who to call when something breaks.
- **Document SLAs.** Refresh schedules, expected latency, support response times.
- **Use Microsoft Purview or equivalent for cataloging.** Surfaces datasets, lineage, and ownership across the organization.

### 4.4 Monitoring and Alerting

- **Monitor pipeline success and freshness.** Alert on failures and on data not arriving when expected.
- **Monitor capacity health.** Alert on sustained high CU consumption or throttling events.
- **Monitor semantic model performance.** Track query duration trends and Direct Lake fallback rates.
- **Monitor report usage.** Identify high-value reports (and unused ones).
- **Centralize alerts.** Don't have ten dashboards each emailing a different person. Route everything through one channel with on-call rotation.

### 4.5 Team and Skills

- **Treat analytics as engineering.** Code review, testing, CI/CD, on-call. The same disciplines that make software teams reliable apply here.
- **Pair BI developers with data engineers.** Each understands one half of the stack well; together they cover the whole.
- **Invest in DAX and modeling skills.** The semantic model is where the leverage lives. A strong modeler is worth ten strong report builders.
- **Build a center of excellence.** A small team that owns standards, templates, and platform tooling. Federated teams build on top.
- **Train users on self-service.** Power BI's strength is enabling business users. Provide training, templates, and support — but with guardrails.

---

## Quick-Reference Checklist

A condensed checklist for spot-checking a Fabric implementation:

**Medallion**
- [ ] Bronze immutable, with ingestion metadata
- [ ] Silver cleansed, deduplicated, conformed
- [ ] Gold modeled as a star schema with surrogate keys
- [ ] V-Order optimization applied to gold tables
- [ ] OPTIMIZE/VACUUM scheduled regularly
- [ ] Pipelines orchestrated via Fabric Data Pipelines
- [ ] Tests run in CI for every layer

**Semantic Model**
- [ ] Direct Lake mode (unless specifically not viable)
- [ ] Star schema, no bidirectional relationships unless justified
- [ ] Measures centralized, formatted, organized in display folders
- [ ] RLS defined, tested, documented
- [ ] TMDL files in Git, BPA running in CI
- [ ] Marked date table with proper time intelligence

**Reports**
- [ ] Built on top of certified semantic model (thin reports)
- [ ] 6-10 visuals per page, performance-tested
- [ ] Mobile layout configured
- [ ] Accessibility checked (contrast, alt text, tab order)
- [ ] Distributed via Power BI Apps, not raw workspace access
- [ ] Usage monitored, unused reports retired

**Cross-cutting**
- [ ] Capacity sized to observed usage
- [ ] Pipelines, models, reports all version-controlled
- [ ] Pull-request review enforced
- [ ] Monitoring and alerting in place
- [ ] Documentation and ownership clear

---

*This document is a living reference. Practices evolve as Fabric matures — review and update periodically.*
