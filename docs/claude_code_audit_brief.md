# Claude Code 审核说明（独立重写版）

## 1) 审核目标

请对本项目进行独立审查，重点回答两件事：

1. 是否满足“**自行写出全部代码，非复制原作者实现**”的工程标准。  
2. 是否满足“**可一键复现、可稳定运行、输出与论文口径一致**”的工程标准。

注意：你需要做的是工程审查与复现风险审查，不是法律裁定。

---

## 2) 项目路径与结构

- 项目根目录：`c:/Users/lyuan/OneDrive/Desktop/Replication Files/Replication`
- 关键代码目录：`code/`
- 关键文档目录：`docs/`
- 产出目录：`output/`

关键脚本（本轮已重写）：

- `code/00_master.do`
- `code/01_clean.do`
- `code/02_descriptive.do`
- `code/03_main_tables.do`
- `code/04_robustness.do`
- `code/05_appendix.do`
- `code/viz/plot_summary.py`
- `code/viz/plot_event_study.py`
- `code/viz/build_slides_figures.py`

---

## 3) 本轮实现要点（供你核对）

### 3.1 主流程与依赖

- `00_master.do` 为单入口，串行调用 `01-05` 脚本；
- 依赖包缺失时自动安装（`ssc install`）；
- 任一步骤失败即停止（fail-fast）；
- 路径采用 `global root` + 派生目录，支持 `data/raw` 与 `../Data files` 回退。

### 3.2 数据清洗与样本构造

- `01_clean.do` 从原始数据构造标准样本：
  - 成人主样本 `analysis_sample.dta`
  - 青少年样本 `analysis_sample_young.dta`
  - 36-48 样本 `analysis_sample_36_48.dta`
- 生成 `processed` 目录快照文件，供下游统一读取。

### 3.3 描述统计与图形

- `02_descriptive.do` 重建 `Table1.xls`（按性别描述统计）；
- `Figure2A/B` 去除 `National Strikes` 线；
- 统一输出到 `output/figures/`。

### 3.4 主结果与稳健性

- `03_main_tables.do` 生成 `Table2-5`；
- 导出 `mean_stats_by_gender.csv` 供 Python 图脚本读取（替代硬编码）；
- `04_robustness.do` 生成 `Table6-8`，包含 falsification/placebo；
- Placebo GDP 五年均值分母使用 `/5`（已修正）。

### 3.5 附录与可视化

- `05_appendix.do` 生成 `TA1-TA10` 与 `FigureA1`；
- `plot_summary.py`、`plot_event_study.py` 从回归表读取系数并出图；
- 图文件输出到 `output/slides/`，并清理历史旧命名残留。

---

## 4) 已验证产出（你可复查）

主表：

- `output/tables/Table1.xls`
- `output/tables/Table2_*.csv` 到 `Table8_*.csv`

附录：

- `output/tables/appendix/TA*.csv`
- `output/tables/appendix/TA1.xls`
- `output/tables/appendix/TA2.xls`

图形：

- `output/figures/Figure2A.png`
- `output/figures/Figure2B.png`
- `output/figures/FigureA1.png`
- `output/slides/fig_summary_effects.png`
- `output/slides/fig_distributional_wage_female.png`
- `output/slides/fig_distributional_wage_male.png`

---

## 5) 请你重点审核的风险点

### A. 原创性/独立实现风险

- 是否存在明显“结构照搬、命名照搬、语句序列照搬”痕迹；
- 是否只是换变量名但控制流仍高度同构；
- 是否仍有“硬编码结果值”而非由估计结果生成。

### B. 统计与工程正确性风险

- 加权口径是否前后一致；
- 子样本筛选与论文口径是否一致；
- 回归控制项与固定效应是否一致；
- `do` 脚本宏作用域、程序定义冲突、静默失败风险；
- Python CSV 解析是否脆弱（列位置漂移、标签语言差异）。

### C. 可复现风险

- 路径可移植性（不同机器是否只改 `global root` 即可）；
- 缺依赖时是否可自动补齐；
- 失败中止机制是否确实阻断后续步骤；
- 输出是否完整且不依赖手工步骤。

---

## 6) 你需要输出的格式

请按以下结构输出：

1. **发现列表（按严重性）**
   - P0（致命，影响正确性/可复现）
   - P1（高优先，影响可信度/一致性）
   - P2（改进项，影响质量/维护性）

每条发现请给出：

- 影响
- 证据（文件路径 + 关键代码位置描述）
- 修复建议

2. **结论摘要**
   - A) 是否达到“独立重写实现”标准：是 / 部分 / 否
   - B) 是否达到“可复现可运行”标准：是 / 部分 / 否
   - C) 最关键的 3 条改进建议

---

## 7) 审核约束

- 不要只看单文件；必须跨 `00-05` 与 `viz` 全链路评估；
- 不要泛泛而谈；请给出可执行修复建议；
- 以“工程可复现 + 学术诚信实现”为最高优先级。

