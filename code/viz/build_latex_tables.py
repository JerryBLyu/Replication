"""
Generate LaTeX and PDF for main tables (Table1-Table8).
"""

from pathlib import Path
import subprocess
import shutil
import pandas as pd


ROOT = Path(__file__).resolve().parents[2]
TABLES = ROOT / "output" / "tables"
LATEX = ROOT / "output" / "latex"
LATEX.mkdir(parents=True, exist_ok=True)


def read_table(path: Path) -> pd.DataFrame:
    if path.suffix.lower() == ".xls":
        return pd.read_excel(path)
    return pd.read_csv(path)


def clean_cells(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df.columns = [str(c).replace("=", "").replace('"', "").strip() for c in df.columns]
    for col in df.columns:
        df[col] = (
            df[col]
            .astype(str)
            .str.replace("=", "", regex=False)
            .str.replace('"', "", regex=False)
            .str.replace("\\\\", "\\textbackslash{}", regex=False)
            .str.replace("&", "\\&", regex=False)
            .str.replace("%", "\\%", regex=False)
            .str.replace("_", "\\_", regex=False)
            .str.strip()
        )
    return df


def table_to_tex(df: pd.DataFrame, caption: str, label: str) -> str:
    body = clean_cells(df).to_latex(index=False, escape=False)
    return (
        "\\begin{table}[!htbp]\n"
        "\\centering\n"
        f"\\caption{{{caption}}}\n"
        f"\\label{{{label}}}\n"
        f"{body}\n"
        "\\end{table}\n"
    )


def compile_pdf(tex_file: Path) -> None:
    if shutil.which("pdflatex") is None:
        print(f"Skip compile (pdflatex not found): {tex_file.name}")
        return
    cmd = ["pdflatex", "-interaction=nonstopmode", tex_file.name]
    try:
        subprocess.run(cmd, cwd=tex_file.parent, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        print(f"PDF compile failed for {tex_file.name}; keep .tex for manual build.")


def build_main_tables() -> None:
    specs = [
        ("Table1.xls", "Main Table 1", "tab:table1"),
        ("Table2_PanelA_FemS.csv", "Main Table 2 Panel A Female", "tab:table2a_f"),
        ("Table2_PanelA_MalS.csv", "Main Table 2 Panel A Male", "tab:table2a_m"),
        ("Table2_PanelB_FemS.csv", "Main Table 2 Panel B Female", "tab:table2b_f"),
        ("Table2_PanelB_MalS.csv", "Main Table 2 Panel B Male", "tab:table2b_m"),
        ("Table2_PanelC_FemS.csv", "Main Table 2 Panel C Female", "tab:table2c_f"),
        ("Table2_PanelC_MalS.csv", "Main Table 2 Panel C Male", "tab:table2c_m"),
        ("Table2_PanelD_FemS.csv", "Main Table 2 Panel D Female", "tab:table2d_f"),
        ("Table2_PanelD_MalS.csv", "Main Table 2 Panel D Male", "tab:table2d_m"),
        ("Table3_FemS.csv", "Main Table 3 Female", "tab:table3_f"),
        ("Table3_MalS.csv", "Main Table 3 Male", "tab:table3_m"),
        ("Table4_FemS.csv", "Main Table 4 Female", "tab:table4_f"),
        ("Table4_MalS.csv", "Main Table 4 Male", "tab:table4_m"),
        ("Table5_FemS.csv", "Main Table 5 Female", "tab:table5_f"),
        ("Table5_MalS.csv", "Main Table 5 Male", "tab:table5_m"),
        ("Table6_FemS.csv", "Main Table 6 Female", "tab:table6_f"),
        ("Table6_MalS.csv", "Main Table 6 Male", "tab:table6_m"),
        ("Table7_PA_FemS_with_caba.csv", "Main Table 7 Panel A Female", "tab:table7a_f"),
        ("Table7_PA_MalS_with_caba.csv", "Main Table 7 Panel A Male", "tab:table7a_m"),
        ("Table7_PB_FemS_no_bs_as.csv", "Main Table 7 Panel B Female", "tab:table7b_f"),
        ("Table7_PB_MalS_no_bs_as.csv", "Main Table 7 Panel B Male", "tab:table7b_m"),
        ("Table7_PC_FemS_low_mig_prov.csv", "Main Table 7 Panel C Female", "tab:table7c_f"),
        ("Table7_PC_MalS_low_mig_prov.csv", "Main Table 7 Panel C Male", "tab:table7c_m"),
        ("Table7_PD_FemS_2010_over.csv", "Main Table 7 Panel D Female", "tab:table7d_f"),
        ("Table7_PD_MalS_2010_over.csv", "Main Table 7 Panel D Male", "tab:table7d_m"),
        ("Table7_PE_FemS_falsification.csv", "Main Table 7 Panel E Female", "tab:table7e_f"),
        ("Table7_PE_MalS_falsification.csv", "Main Table 7 Panel E Male", "tab:table7e_m"),
        ("Table7_PF_FemS.csv", "Main Table 7 Panel F Female", "tab:table7f_f"),
        ("Table7_PF_MalS.csv", "Main Table 7 Panel F Male", "tab:table7f_m"),
        ("Table7_PG_FemS_treatment_lower_than_200.csv", "Main Table 7 Panel G Female", "tab:table7g_f"),
        ("Table7_PG_MalS_treatment_lower_than_200.csv", "Main Table 7 Panel G Male", "tab:table7g_m"),
        ("Table7_PH_FemS.csv", "Main Table 7 Panel H Female", "tab:table7h_f"),
        ("Table7_PH_MalS.csv", "Main Table 7 Panel H Male", "tab:table7h_m"),
        ("Table8_FemS_12_17.csv", "Main Table 8 Female", "tab:table8_f"),
        ("Table8_MalS_12_17.csv", "Main Table 8 Male", "tab:table8_m"),
    ]

    tex_blocks = []
    for fname, caption, label in specs:
        path = TABLES / fname
        if not path.exists():
            print(f"Missing table skipped: {fname}")
            continue
        df = read_table(path)
        tex_blocks.append(table_to_tex(df, caption, label))

    wrapper = (
        "\\documentclass[11pt]{article}\n"
        "\\usepackage[margin=1in]{geometry}\n"
        "\\usepackage{booktabs}\n"
        "\\usepackage{longtable}\n"
        "\\usepackage{float}\n"
        "\\begin{document}\n"
        "\\section*{Main Results Tables (Table 1-8)}\n"
        + "\n\\clearpage\n".join(tex_blocks) +
        "\n\\end{document}\n"
    )

    tex_file = LATEX / "main_tables.tex"
    tex_file.write_text(wrapper, encoding="utf-8")
    compile_pdf(tex_file)
    print("Generated:", tex_file)
    if (LATEX / "main_tables.pdf").exists():
        print("Generated:", LATEX / "main_tables.pdf")


if __name__ == "__main__":
    build_main_tables()
