"""Run all Python plotting scripts for slides."""

from pathlib import Path
import subprocess
import sys


HERE = Path(__file__).resolve().parent
SLIDES = HERE.parent.parent / "output" / "slides"
SLIDES.mkdir(parents=True, exist_ok=True)

SCRIPTS = [
    "plot_summary.py",
    "plot_event_study.py",
    "build_paper_style_report_v2.py",
]

LEGACY_FILES = [
    "fig_event_study_wage_fems.png",
    "fig_event_study_wage_fems.pdf",
    "fig_event_study_wage_mals.png",
    "fig_event_study_wage_mals.pdf",
]

for name in LEGACY_FILES:
    old = SLIDES / name
    if old.exists():
        old.unlink()

for script in SCRIPTS:
    cmd = [sys.executable, str(HERE / script)]
    print("Running:", " ".join(cmd))
    subprocess.run(cmd, check=True)

print("Generated files:")
for p in sorted(SLIDES.glob("*")):
    print("-", p.name)
