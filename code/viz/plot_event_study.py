"""
Distributional coefficient plot for slides.
Reads Stata-generated percentile table and plots treatment effects by wage decile.
Writes:
  - output/slides/fig_distributional_wage_male.png/.pdf
  - output/slides/fig_distributional_wage_female.png/.pdf
"""

from pathlib import Path
import re
import numpy as np
import matplotlib.pyplot as plt


ROOT = Path(__file__).resolve().parents[2]
TABLES = ROOT / "output" / "tables"
SLIDES = ROOT / "output" / "slides"
SLIDES.mkdir(parents=True, exist_ok=True)


def _to_float(token: str) -> float:
    cleaned = re.sub(r"[^0-9\-.]", "", token or "")
    return float(cleaned) if cleaned not in {"", "-", "."} else float("nan")


def parse_treatment_row(path: Path):
    text = path.read_text(encoding="utf-8", errors="ignore")
    for line in text.splitlines():
        if "treatment" not in line.lower():
            continue
        parts = [p.replace('"', "").replace("=", "").strip() for p in line.split(",")]
        vals = [_to_float(p) for p in parts[1:]]
        return [v for v in vals if not np.isnan(v)]
    return []


def make_plot(suffix: str, title: str):
    vals = parse_treatment_row(TABLES / f"Table3_{suffix}.csv")
    # Select wage decile block: positions 10-18 in Table3 stacking.
    wage_block = vals[9:18] if len(vals) >= 27 else vals[:9]
    x = np.arange(1, len(wage_block) + 1)

    plt.rcParams.update(
        {
            "font.family": "serif",
            "font.size": 10,
            "axes.titlesize": 11,
            "axes.labelsize": 10,
        }
    )
    fig, ax = plt.subplots(figsize=(7.0, 4.4))
    ax.plot(x, wage_block, marker="o", color="#1E6091", linewidth=1.8, markersize=4.2)
    ax.axhline(0, color="black", linestyle="--", linewidth=0.9, alpha=0.6)
    ax.set_xticks(x)
    ax.set_xticklabels([f"P{10*i}" for i in x], fontsize=10)
    ax.set_xlabel("Wage percentile", fontsize=11)
    ax.set_ylabel("Treatment Coefficient", fontsize=11)
    ax.set_title(title, fontsize=12, fontweight="bold")
    ax.grid(axis="y", linestyle=":", linewidth=0.6, alpha=0.6)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    fig.text(0.01, 0.01, "Coefficient profile across wage deciles, based on Table 3.", fontsize=8.5)
    fig.tight_layout()
    stem = "male" if suffix == "MalS" else "female"
    fig.savefig(SLIDES / f"fig_distributional_wage_{stem}.png", dpi=300, bbox_inches="tight")
    fig.savefig(SLIDES / f"fig_distributional_wage_{stem}.pdf", dpi=300, bbox_inches="tight")


make_plot("MalS", "Distributional Wage Effects by Decile (Male)")
make_plot("FemS", "Distributional Wage Effects by Decile (Female)")
print("distributional wage figures saved")
