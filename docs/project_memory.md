# Project Memory (Cross-Conversation)

Last updated: 2026-05-15 19:35+  
Project: Jaume & Willén (2019) replication refactor

## 1) User hard requirements (must persist)

1. 对话回复必须使用简体中文。
2. 所有新增产物放在 `Replication/` 下。
3. 代码必须是独立重写实现，不复制作者原代码结构；但计量口径需与论文一致。
4. 可视化需面向展示优化。
5. 缺失依赖可自动安装；项目需可复现、可审计、可一键运行。
6. 最终产物需可整理为 GitHub 上传版本（保留核心代码、输出、文档和数据目录结构）。

## 2) 本轮最终实现状态（已完成）

### Stata 主流程

- `code/00_master.do`
  - 保留占位根路径，同时新增自动 root 检测（从项目根或 `code/` 触发均可）。
  - 核心包（`estout reghdfe ftools csdid`）安装失败即中止。
  - 可选包（`event_plot binscatter`）安装失败仅警告，不阻断主流程。
  - 全流程失败即停止，日志写入 `output/replication_log.txt`。

- `code/01_clean.do` ~ `code/05_appendix.do`
  - 已全部改为独立重写版本。
  - 每个 do 文件末尾均补 `✓ xx.do complete`。
  - `04_robustness.do` 已恢复 `Table7` 全部关键面板（PA~PH，包括 PC/PD/PF/PG）。

### Python 可视化与表格构建

- `code/viz/plot_summary.py`
  - 点估计与 CI 均统一来自 `output/tables/treat_se_by_gender.csv`（同一口径）。
  - 不再使用任意 10% 误差棒。

- `code/viz/plot_event_study.py`
  - 命名与内容统一为分位数分布效应图（非伪 event-study）。

- `code/viz/build_slides_figures.py`
  - 一键执行图形与 LaTeX 表格生成。

- 新增 `code/viz/build_latex_tables.py`
  - 自动将 `Table1-8` 主结果汇总生成：
    - `output/latex/main_tables.tex`
    - `output/latex/main_tables.pdf`

## 3) 关键输出（当前可交付）

- 主日志：`output/replication_log.txt`（19:12:44 开始、19:15:03 结束，5阶段成功收尾）
- 主表：`output/tables/Table1.xls` 到 `Table8_*.csv`
- Table7：`PA/PB/PC/PD/PE/PF/PG/PH` 男女文件均存在
- 附录：`output/tables/appendix/TA*.csv|xls`
- 论文图：`output/figures/Figure2A.png`、`Figure2B.png`、`FigureA1.png`
- 展示图：`output/slides/fig_summary_effects.*`、`fig_distributional_wage_*.png/.pdf`
- LaTeX 主表：`output/latex/main_tables.tex`、`main_tables.pdf`

## 4) 结果一致性记录（当前口径）

- 论文对照主结果（平均暴露下工资效应）：
  - Male replication ≈ `-2.64%`（论文约 `-3.2%`）
  - Female replication ≈ `-1.57%`（论文约 `-1.9%`）
- `docs/replication_notes.md` 与 `README.md` 已同步更新上述口径说明。

## 5) 已清理的残留

- 已删除超大验证日志：
  - `output/rewrite_validation_log.txt`
  - `output/rewrite_validation_compact.txt`

## 6) 当前保留结构（符合上传准备要求）

- 保留：`code/`、`output/`、`README.md`、`docs/`、`data/`目录结构
- `data/raw` 不入库；`data/processed` 可重建

## 7) 仍需注意（未来会话）

1. 若从 Stata GUI 菜单直接运行，建议手动确认 `00_master.do` 的 `global root`。
2. `main_tables.pdf` 会随本地 LaTeX 环境差异出现日志警告；若 PDF 已生成可视为通过，必要时手工复编译 `main_tables.tex`。
3. 如需最终提交打包，建议再做一次“清空 `data/processed` 后重跑”并记录文件时间戳/清单。
