import numpy as np
from matplotlib.pyplot import savefig

fontoptions = {
    "font.size": 12,  # Adjust text size for readability
    "font.family": "serif",  # Serif fonts look more professional in books
    "axes.labelsize": 14,  # Labels slightly larger
    "axes.titlesize": 14,  
    "legend.fontsize": 12,  # Readable legend
    "xtick.labelsize": 12,
    "ytick.labelsize": 12,
    "mathtext.fontset": "cm"     # use Computer Modern
}

squarefigsize =(5,4)
widefigsize=(10, 4)
midfigsize=(10, 6)
tallfigsize=(10, 12)
dpi = 300
shadecolor=[0.5,0.5,0.5]

def mysavefig(fn):
    savefig(fn+'.pdf',bbox_inches='tight',format="pdf")
    savefig(fn+'.eps',bbox_inches='tight',format="eps")
