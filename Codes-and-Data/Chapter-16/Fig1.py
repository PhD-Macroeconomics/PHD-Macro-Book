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

# Matplotlib’s default fonts are small; use serif fonts (better for books):
plt.rcParams.update(fontoptions)



# Figure setup
engine = layout_engine.ConstrainedLayoutEngine(w_pad=0.05, h_pad=0.05, hspace=0.07, wspace=0.07)  # these are default options

# Use it in your figure
fig, axes = plt.subplots(1, 1, figsize=widefigsize,dpi=dpi,layout=engine)
fig.set_constrained_layout_pads() # apply layout, possible to override defaults



# Load data
df = pd.read_csv('Fig_1_data.csv')
df.set_index('Year',inplace=True)
# plot
lines = plt.plot(df)

for l,c,s,w in zip(lines,[0.4,0],["--","-"],[4,2]):
    l.set_color(3*[c])
    l.set_linestyle(s)
    l.set_linewidth(w)




plt.text(1945,66,"Housing",fontsize=14)
plt.text(1988,70,"Stocks",fontsize=14)



plt.ylim([0,90])
plt.xlim([1929,2024])
# plt.axhline(0, color=3*[0.6], linestyle='-', linewidth=0.8)



# plt.ylabel(r"BTU $\times 10^{15}$",fontsize=14)
# plt.xlabel("Year",fontsize=14)


plt.tight_layout()
plt.savefig("fig1.pdf", bbox_inches="tight", format="pdf")

plt.show()