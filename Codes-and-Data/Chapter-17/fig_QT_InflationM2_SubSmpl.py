import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib import layout_engine

#-- import figureoptions from parent dir --
import sys
from pathlib import Path

# Get the parent directory of the current script
parent_dir = Path(__file__).resolve().parent.parent

# Add the parent directory to sys.path
sys.path.insert(0, str(parent_dir))

from figureoptions import *
#--
# Figure setup
# Matplotlib’s default fonts are small; use serif fonts (better for books):
plt.rcParams.update(fontoptions)


engine = layout_engine.ConstrainedLayoutEngine(w_pad=0.05, h_pad=0.05, hspace=0.07, wspace=0.07)  # these are default options

# Use it in your figure
fig, axes = plt.subplots(3, 2, figsize=tallfigsize,dpi=dpi,layout=engine)
fig.set_constrained_layout_pads() # apply layout, possible to override defaults




# -- Data loading and setup
n = 5
sheetnames = ["1902-1928","1929-1954","1955-1983","1984-2005","2006-2023"]


# -- loop through panels

for i in range(n):

    a = int(np.floor(i/2))
    b = i - 2*a
    sn = sheetnames[i]
    df = pd.read_excel("QT_InflationM2_SubSmpl.xlsx",sheet_name=sn)
    df = df.set_index(df.columns[0])
    axes[a,b].scatter(df.index,df[df.columns[0]],s=80, facecolors='none', edgecolors='black')
    axes[a,b].plot(df.index,df[df.columns[1]], color='black',linewidth=2)
    x = np.linspace(0,10,11)
    axes[a,b].plot(x, x, linestyle='--', color='gray')
    if i == 0:
        axes[a,b].set_ylim([-5,10])
    elif i == 1:
        axes[a,b].set_ylim([-2,10])
    else:
        axes[a,b].set_ylim([0,10])

    axes[a,b].set_xlim([0,10])


    # Labels and Title
    axes[a,b].set_xlabel("$\Delta \ln M2$, Percent", fontsize=14)
    axes[a,b].set_ylabel("$\Delta \ln p$, Percent", fontsize=14)
    axes[a,b].set_title(sn, fontsize=14)


# Text to display in lower-right
text = (
    "Coefficients of Regressions\n"
    "on Filtered Data\n"
    "(with standard errors)\n"
    "\n"
    "1902-1928 : 1.11 (0.10)\n"
    "1929-1954 : 0.85 (0.05)\n"
    "1955-1983 : 1.28 (0.16)\n"
    "1984-2005 : 0.76 (0.32)\n"
    "2006-2023 : -0.28 (0.02)\n"
    "1902-2023 : 0.84 (0.12)"
)

# Add the text box
ax = axes[2,1]
ax.text(
    0.05, 0.9, text,
    fontsize=14,
    verticalalignment='top',
    horizontalalignment='left',
)

# Turn off ticks and tick labels
ax.set_xticks([])
ax.set_yticks([])
ax.set_xticklabels([])
ax.set_yticklabels([])

# Remove spines (the box around the plot)
for spine in ax.spines.values():
    spine.set_visible(False)




plt.savefig("fig_QT_InflationM2_SubSmpl.pdf", bbox_inches="tight", format="pdf")

plt.show()