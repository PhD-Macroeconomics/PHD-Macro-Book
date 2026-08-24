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
fig, axes = plt.subplots(1, 1, figsize=(6,4.5),dpi=dpi,layout=engine)
fig.set_constrained_layout_pads() # apply layout, possible to override defaults



# Load data
df = pd.read_csv('Fig_4_data.csv')

# plot
plt.plot(df.riskfree,df.equitypremium,color='k')
plt.fill_between(df.riskfree,df.equitypremium, 0,color=3*[0.3])  # shade down to baseline y=0
plt.xlabel("Risk-free rate (in percent)",fontsize=14)
plt.ylabel("Equity premium (in percent)",fontsize=14)

plt.ylim([0,1])
plt.xlim([0,4])
plt.yticks(np.arange(0,1.1,0.1))




plt.tight_layout()
plt.savefig("fig4.pdf", bbox_inches="tight", format="pdf")

plt.show()