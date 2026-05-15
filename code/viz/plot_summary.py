"""Build summary effect comparison figure for slides."""

from pathlib import Path
import re
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


ROOT = Path(__file__).resolve().parents[2]
TABLES = ROOT / "output" / "tables"
SLIDES = ROOT / "output" / "slides"
SLIDES.mkdir(parents=True, exist_ok=True)


def _as_number(text: str) -> float:
    clean = re.sub(r"[^0-9\-.]", "", text or "")
    return float(clean) if clean not in {"", "-", ".", "-."} else float("nan")


def treatment_coef(csv_file: Path, column_index: int) -> float:
    rows = [r.strip() for r in csv_file.read_text(encoding="utf-8", errors="ignore").splitlines() if r.strip()]
    for row in rows:
        if "treatment" in row.lower():
            parts = [p.strip().replace('"', "") for p in row.split(",")]
            if column_index < len(parts):
                return _as_number(parts[column_index])
    return float("nan")


def gender_key(raw_val: str) -> str:
    v = str(raw_val).strip().lower()
    return "MalS" if v in {"1", "male", "hombre"} else "FemS"


def load_mean_stats() -> dict:
    df = pd.read_csv(TABLES / "mean_stats_by_gender.csv")
    key_col = "male_code" if "male_code" in df.columns else "male"
    out = {}
    for _, row in df.iterrows():
        key = "MalS" if gender_key(row[key_col]) == "MalS" else "FemS"
        out[key] = {
            "treatment": float(row["treatment"]),
            "aedu": float(row["aedu"]),
        }
    return out


def load_treat_se() -> dict:
    df = pd.read_csv(TABLES / "treat_se_by_gender.csv")
    out = {}
    for _, row in df.iterrows():
        g = str(row["group"]).strip()
        y = str(row["outcome"]).strip()
        out[(g, y)] = {
            "b_treat": float(row["b_treat"]),
            "se_treat": float(row["se_treat"]),
            "mean_treat": float(row["mean_treat"]),
            "mean_outcome": float(row["mean_outcome"]),
        }
    return out


paper = {
    "wage": {"Female": -1.9, "Male": -3.2},
    "edu": {"Female": -1.58, "Male": -2.02},
}

means = load_mean_stats()
ses = load_treat_se()
coef_w_f = treatment_coef(TABLES / "Table2_PanelC_FemS.csv", 2)
coef_w_m = treatment_coef(TABLES / "Table2_PanelC_MalS.csv", 2)
coef_e_f = treatment_coef(TABLES / "Table2_PanelA_FemS.csv", 3)
coef_e_m = treatment_coef(TABLES / "Table2_PanelA_MalS.csv", 3)

rep_w_f = 100 * ses[("FemS", "log_wage")]["b_treat"] * ses[("FemS", "log_wage")]["mean_treat"]
rep_w_m = 100 * ses[("MalS", "log_wage")]["b_treat"] * ses[("MalS", "log_wage")]["mean_treat"]
rep_e_f = 100 * ses[("FemS", "aedu")]["b_treat"] * ses[("FemS", "aedu")]["mean_treat"] / ses[("FemS", "aedu")]["mean_outcome"]
rep_e_m = 100 * ses[("MalS", "aedu")]["b_treat"] * ses[("MalS", "aedu")]["mean_treat"] / ses[("MalS", "aedu")]["mean_outcome"]

err_w = [
    1.96 * ses[("FemS", "log_wage")]["se_treat"] * ses[("FemS", "log_wage")]["mean_treat"] * 100,
    1.96 * ses[("MalS", "log_wage")]["se_treat"] * ses[("MalS", "log_wage")]["mean_treat"] * 100,
]
err_e = [
    1.96 * ses[("FemS", "aedu")]["se_treat"] * ses[("FemS", "aedu")]["mean_treat"] / ses[("FemS", "aedu")]["mean_outcome"] * 100,
    1.96 * ses[("MalS", "aedu")]["se_treat"] * ses[("MalS", "aedu")]["mean_treat"] / ses[("MalS", "aedu")]["mean_outcome"] * 100,
]

plt.style.use("seaborn-v0_8-whitegrid")
fig, axes = plt.subplots(1, 2, figsize=(10.4, 4.8))
x = np.arange(2)
labels = ["Female", "Male"]
bar_w = 0.34

axes[0].bar(x - bar_w / 2, [paper["wage"]["Female"], paper["wage"]["Male"]], bar_w, color="#334E68", label="Paper")
axes[0].bar(x + bar_w / 2, [rep_w_f, rep_w_m], bar_w, color="#D64550", yerr=err_w, capsize=4, label="Replication")
axes[0].axhline(0, color="black", linewidth=0.8, linestyle="--")
axes[0].set_title("Wage Effect at Mean Exposure (%)")
axes[0].set_xticks(x, labels)
axes[0].set_ylabel("Percent change")

axes[1].bar(x - bar_w / 2, [paper["edu"]["Female"], paper["edu"]["Male"]], bar_w, color="#334E68", label="Paper")
axes[1].bar(x + bar_w / 2, [rep_e_f, rep_e_m], bar_w, color="#D64550", yerr=err_e, capsize=4, label="Replication")
axes[1].axhline(0, color="black", linewidth=0.8, linestyle="--")
axes[1].set_title("Education Effect at Mean Exposure (%)")
axes[1].set_xticks(x, labels)
axes[1].set_ylabel("Percent change")

for ax in axes:
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)

fig.suptitle("Replication vs Paper Benchmarks", fontsize=13, fontweight="bold")
fig.legend(loc="lower center", ncol=2, frameon=False, bbox_to_anchor=(0.5, 0.01))
fig.text(0.01, 0.01, "Replication bars from Table 2; error bars show approx. 95% CI from treatment SE.", fontsize=9)
fig.tight_layout(rect=[0, 0.06, 1, 1])
fig.savefig(SLIDES / "fig_summary_effects.png", dpi=300, bbox_inches="tight")
fig.savefig(SLIDES / "fig_summary_effects.pdf", dpi=300, bbox_inches="tight")
print("fig_summary_effects saved")
