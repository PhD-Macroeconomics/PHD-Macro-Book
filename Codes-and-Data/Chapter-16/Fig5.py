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



# Load data and plot
plt.axhline(0, color=3*[0.6], linestyle='-', linewidth=0.8)
df = pd.read_csv('Fig_5_data_excessreturn.csv')
plt.plot(df.Year,df.exr,linestyle=":",color=3*[0.4],linewidth=3)
df = pd.read_csv('Fig_5_data_4DP.csv')
plt.plot(df.Year,df.PDratiosX4,linestyle="-",color='k',linewidth=2)




plt.text(1976,0.23,r"D/P $\times 4$",fontsize=14)
plt.text(1975,0.015,"Excess return",fontsize=14)



plt.ylim([-0.1,0.3])
plt.xlim([1945,2025])



# plt.ylabel(r"BTU $\times 10^{15}$",fontsize=14)
# plt.xlabel("Year",fontsize=14)


plt.tight_layout()
plt.savefig("fig5.pdf", bbox_inches="tight", format="pdf")

plt.show()