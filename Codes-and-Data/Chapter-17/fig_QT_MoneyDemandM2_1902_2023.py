import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib import layout_engine
from scipy.io import loadmat

#-- import figureoptions from parent dir --
import sys
from pathlib import Path

# Get the parent directory of the current script
parent_dir = Path(__file__).resolve().parent.parent

# Add the parent directory to sys.path
sys.path.insert(0, str(parent_dir))

from figureoptions import *
#--

# Matplotlib’s default fonts are small; use serif fonts (better for books):
plt.rcParams.update(fontoptions)



# Figure setup
engine = layout_engine.ConstrainedLayoutEngine(w_pad=0.05, h_pad=0.05, hspace=0.07, wspace=0.07)  # these are default options

# Use it in your figure
fig, ax1 = plt.subplots(1, 1, figsize=midfigsize,dpi=dpi,layout=engine)
fig.set_constrained_layout_pads() # apply layout, possible to override defaults


# Load data
df = pd.read_excel("QT_MoneyDemandM2_1902_2023.xlsx",sheet_name="Data")
df["Year"] = pd.to_datetime(df.Year, format="%Y")
df = df.set_index("Year")

# Plot

linestyles = ['-',    '-',      '--',    '--' ]
colors =     ['black','black','black','black']
widths =     [3,       1,        3,       1]



# Plot y1 and y2 on the left y-axis
for i in range(2):
    ax1.plot(df[df.columns[i]],linewidth=widths[i],color=colors[i],linestyle=linestyles[i],label=df.columns[i])


ax1.set_ylabel('M2 / GDP')
ax1.tick_params(axis='y')
ax1.legend(loc='upper left',frameon=False)


# shading
shadespans = [[1901,	1928],
              [1955,	1983],
              [2006,	2023]]
for start, end in shadespans:
    ax1.axvspan(pd.to_datetime(start,format="%Y"), pd.to_datetime(end,format="%Y"),
               color='gray', alpha=0.3)

ax1.set_xlim([df.index[0],df.index[-1]])

# Create a twin y-axis
ax2 = ax1.twinx()

# Plot y3 and y4 on the right y-axis
for i in range(2,4):
    ax2.plot(df[df.columns[i]],linewidth=widths[i],color=colors[i],linestyle=linestyles[i],label=df.columns[i])

ax2.set_ylabel('Percent')
ax2.tick_params(axis='y')
ax2.legend(loc='upper right',bbox_to_anchor=(0.87, 1.0),frameon=False)

ax1.set_xlabel('Year')





plt.savefig("fig_QT_MoneyDemandM2_1902_2023.pdf", bbox_inches="tight", format="pdf")

plt.show()