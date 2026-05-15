"""
Build cleaned compact tables and a paper-style LaTeX report (v2).
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import re
import shutil
import subprocess
import pandas as pd


ROOT = Path(__file__).resolve().parents[2]
TABLES = ROOT / "output" / "tables"
FINAL = ROOT / "output" / "final"
COMPACT = FINAL / "compact_tables"
LATEX = FINAL / "latex"
FIGURES = FINAL / "figures"
SLIDES = FINAL / "slides"
COMPACT.mkdir(parents=True, exist_ok=True)
LATEX.mkdir(parents=True, exist_ok=True)


VAR_LABELS = {
    "treatment": "Exposure (teacher strike days index)",
    "_cons": "Constant",
    "fake_treat": "Placebo exposure",
    "pre_treat": "Pre-school exposure",
    "strike_early": "Exposure grades 1-4",
    "strike_late": "Exposure grades 5-7",
}


def clean_cell(x: object) -> str:
    s = "" if pd.isna(x) else str(x)
    s = s.replace('"', "").replace("=", "").strip()
    return s


def latex_escape(s: str) -> str:
    return (
        s.replace("\\", "\\textbackslash{}")
        .replace("&", "\\&")
        .replace("%", "\\%")
        .replace("_", "\\_")
        .replace("#", "\\#")
        .replace("$", "\\$")
        .replace("{", "\\{")
        .replace("}", "\\}")
    )


def pretty_var(v: str) -> str:
    if v in VAR_LABELS:
        return VAR_LABELS[v]
    vv = v.replace("_", " ").strip()
    return vv.title()


@dataclass
class EsttabTable:
    outcomes: list[str]
    rows: list[tuple[str, list[str], list[str]]]
    n_values: list[str]


def parse_esttab_csv(path: Path) -> EsttabTable:
    raw = pd.read_csv(path, header=None, dtype=str, engine="python").fillna("")
    for c in raw.columns:
        raw[c] = raw[c].map(clean_cell)

    values = raw.values.tolist()
    if len(values) < 3:
        return EsttabTable([], [], [])

    # Find model index row (contains "(1)", "(2)", ...), then outcome row is next.
    header_idx = None
    for i, row in enumerate(values):
        tail = [str(x).strip() for x in row[1:]]
        if any(re.fullmatch(r"\(\d+\)", t) for t in tail if t):
            header_idx = i
            break
    if header_idx is None or header_idx + 1 >= len(values):
        return EsttabTable([], [], [])

    outcomes = [x for x in values[header_idx + 1][1:] if x != ""]
    k = len(outcomes)
    rows: list[tuple[str, list[str], list[str]]] = []
    n_values: list[str] = []

    i = header_idx + 2
    while i < len(values):
        name = values[i][0]
        if name == "":
            i += 1
            continue
        lname = name.lower()
        if lname.startswith("standard errors") or lname.startswith("* p<"):
            i += 1
            continue
        if name == "N":
            n_values = values[i][1 : 1 + k]
            i += 1
            continue

        coef = values[i][1 : 1 + k]
        se = [""] * k
        if i + 1 < len(values) and values[i + 1][0] == "":
            nxt = values[i + 1][1 : 1 + k]
            if any(x.startswith("(") and x.endswith(")") for x in nxt if x):
                se = nxt
                i += 1
        rows.append((name, coef, se))
        i += 1

    return EsttabTable(outcomes, rows, n_values)


def esttab_to_sheet_df(t: EsttabTable) -> pd.DataFrame:
    cols = ["Variable"] + [f"Model {i+1}: {o}" for i, o in enumerate(t.outcomes)]
    data: list[list[str]] = []
    for var, coef, se in t.rows:
        row = [pretty_var(var)]
        for c, s in zip(coef, se):
            cell = c if s == "" else f"{c} {s}"
            row.append(cell)
        data.append(row)
    if t.n_values:
        data.append(["Observations"] + t.n_values)
    return pd.DataFrame(data, columns=cols)


def write_compact_tables() -> dict[str, Path]:
    out: dict[str, Path] = {}

    # Table 1 from xls
    t1 = pd.read_excel(TABLES / "Table1.xls", dtype=str).fillna("")
    p1 = COMPACT / "Table1.xlsx"
    with pd.ExcelWriter(p1, engine="openpyxl") as w:
        t1.to_excel(w, sheet_name="Table1", index=False)
    out["Table1"] = p1

    groups = {
        "Table2": [
            ("PanelA_Female", "Table2_PanelA_FemS.csv"),
            ("PanelA_Male", "Table2_PanelA_MalS.csv"),
            ("PanelB_Female", "Table2_PanelB_FemS.csv"),
            ("PanelB_Male", "Table2_PanelB_MalS.csv"),
            ("PanelC_Female", "Table2_PanelC_FemS.csv"),
            ("PanelC_Male", "Table2_PanelC_MalS.csv"),
            ("PanelD_Female", "Table2_PanelD_FemS.csv"),
            ("PanelD_Male", "Table2_PanelD_MalS.csv"),
        ],
        "Table3": [("Female", "Table3_FemS.csv"), ("Male", "Table3_MalS.csv")],
        "Table4": [("Female", "Table4_FemS.csv"), ("Male", "Table4_MalS.csv")],
        "Table5": [("Female", "Table5_FemS.csv"), ("Male", "Table5_MalS.csv")],
        "Table6": [("Female", "Table6_FemS.csv"), ("Male", "Table6_MalS.csv")],
        "Table7": [
            ("PA_Female", "Table7_PA_FemS_with_caba.csv"),
            ("PA_Male", "Table7_PA_MalS_with_caba.csv"),
            ("PB_Female", "Table7_PB_FemS_no_bs_as.csv"),
            ("PB_Male", "Table7_PB_MalS_no_bs_as.csv"),
            ("PC_Female", "Table7_PC_FemS_low_mig_prov.csv"),
            ("PC_Male", "Table7_PC_MalS_low_mig_prov.csv"),
            ("PD_Female", "Table7_PD_FemS_2010_over.csv"),
            ("PD_Male", "Table7_PD_MalS_2010_over.csv"),
            ("PE_Female", "Table7_PE_FemS_falsification.csv"),
            ("PE_Male", "Table7_PE_MalS_falsification.csv"),
            ("PF_Female", "Table7_PF_FemS.csv"),
            ("PF_Male", "Table7_PF_MalS.csv"),
            ("PG_Female", "Table7_PG_FemS_treatment_lower_than_200.csv"),
            ("PG_Male", "Table7_PG_MalS_treatment_lower_than_200.csv"),
            ("PH_Female", "Table7_PH_FemS.csv"),
            ("PH_Male", "Table7_PH_MalS.csv"),
        ],
        "Table8": [("Female_12_17", "Table8_FemS_12_17.csv"), ("Male_12_17", "Table8_MalS_12_17.csv")],
    }

    for tname, specs in groups.items():
        target = COMPACT / f"{tname}.xlsx"
        with pd.ExcelWriter(target, engine="openpyxl") as w:
            for sheet, fname in specs:
                parsed = parse_esttab_csv(TABLES / fname)
                df = esttab_to_sheet_df(parsed)
                df.to_excel(w, sheet_name=sheet[:31], index=False)
        out[tname] = target

    return out


def sheet_to_latex_table(df: pd.DataFrame, caption: str, label: str) -> str:
    ncols = len(df.columns)
    spec = "p{5.2cm}" + "p{2.6cm}" * (ncols - 1)
    headers = " & ".join(latex_escape(c) for c in df.columns) + " \\\\"
    lines = [
        "\\begin{table}[!htbp]",
        "\\centering",
        "\\footnotesize",
        f"\\caption{{{latex_escape(caption)}}}",
        f"\\label{{{label}}}",
        "\\setlength{\\tabcolsep}{4pt}",
        f"\\resizebox{{\\textwidth}}{{!}}{{%",
        f"\\begin{{tabular}}{{{spec}}}",
        "\\toprule",
        headers,
        "\\midrule",
    ]
    for _, row in df.iterrows():
        cells = []
        for j, v in enumerate(row):
            text = latex_escape(str(v))
            cells.append(text)
        lines.append(" & ".join(cells) + " \\\\")
    lines += ["\\bottomrule", "\\end{tabular}}", "\\end{table}"]
    return "\n".join(lines)


def build_latex_report(products: dict[str, Path]) -> Path:
    body_parts: list[str] = []
    body_parts.append("\\section*{Main Tables}")

    for i in range(1, 9):
        tname = f"Table{i}"
        xlsx = products[tname]
        xls = pd.ExcelFile(xlsx)
        body_parts.append(f"\\subsection*{{{tname}}}")
        for sheet in xls.sheet_names:
            df = pd.read_excel(xlsx, sheet_name=sheet, dtype=str).fillna("")
            cap = f"{tname} ({sheet.replace('_', ' ')})"
            lbl = f"tab:{tname.lower()}_{re.sub(r'[^a-zA-Z0-9]+', '_', sheet.lower())}"
            body_parts.append(sheet_to_latex_table(df, cap, lbl))
            body_parts.append("\\clearpage")

    body_parts.extend(
        [
            "\\section*{Main Figures}",
            "\\begin{figure}[!htbp]\\centering\\includegraphics[width=0.95\\textwidth]{../figures/Figure2A.png}\\caption{Figure 2A}\\end{figure}",
            "\\begin{figure}[!htbp]\\centering\\includegraphics[width=0.95\\textwidth]{../figures/Figure2B.png}\\caption{Figure 2B}\\end{figure}",
            "\\begin{figure}[!htbp]\\centering\\includegraphics[width=0.95\\textwidth]{../figures/FigureA1.png}\\caption{Figure A1}\\end{figure}",
            "\\clearpage",
            "\\section*{Presentation Figures}",
            "\\begin{figure}[!htbp]\\centering\\includegraphics[width=0.9\\textwidth]{../slides/fig_summary_effects.png}\\caption{Summary effects}\\end{figure}",
            "\\begin{figure}[!htbp]\\centering\\includegraphics[width=0.9\\textwidth]{../slides/fig_distributional_wage_female.png}\\caption{Distributional wage effects (female)}\\end{figure}",
            "\\begin{figure}[!htbp]\\centering\\includegraphics[width=0.9\\textwidth]{../slides/fig_distributional_wage_male.png}\\caption{Distributional wage effects (male)}\\end{figure}",
        ]
    )

    tex = (
        "\\documentclass[11pt]{article}\n"
        "\\usepackage[margin=1in]{geometry}\n"
        "\\usepackage{booktabs}\n"
        "\\usepackage{graphicx}\n"
        "\\setlength{\\parindent}{0pt}\n"
        "\\setlength{\\parskip}{4pt}\n"
        "\\title{Replication Results: Paper-Style Tables and Figures}\n"
        "\\author{Replication Package}\n"
        "\\date{\\today}\n"
        "\\begin{document}\n"
        "\\maketitle\n"
        + "\n".join(body_parts) +
        "\n\\end{document}\n"
    )
    out = LATEX / "paper_style_report_v2.tex"
    out.write_text(tex, encoding="utf-8")
    compile_pdf(out)
    return out


def compile_pdf(tex_file: Path) -> None:
    if shutil.which("pdflatex") is None:
        print("pdflatex not found, skip PDF compile.")
        return
    cmd = ["pdflatex", "-interaction=nonstopmode", tex_file.name]
    log1 = subprocess.run(cmd, cwd=tex_file.parent, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    log2 = subprocess.run(cmd, cwd=tex_file.parent, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if log1.returncode != 0 or log2.returncode != 0:
        raise RuntimeError(f"pdflatex failed for {tex_file.name}")


def main() -> None:
    products = write_compact_tables()
    report = build_latex_report(products)
    print("Built compact files:")
    for i in range(1, 9):
        print("-", COMPACT / f"Table{i}.xlsx")
    print("Built report:")
    print("-", report)
    pdf = report.with_suffix(".pdf")
    if pdf.exists():
        print("-", pdf)


if __name__ == "__main__":
    main()
