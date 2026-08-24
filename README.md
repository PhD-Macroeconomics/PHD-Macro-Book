# PHD-Macro-Book

Teaching and replication materials for **_[Macroeconomics](https://phdmacrobook.org/)_**, by Marina Azzimonti, Per
Krusell, Alisdair McKay, and Toshihiko Mukoyama, with contributing authors*
(Oxford University Press, 2026). 

*Macroeconomics* is a graduate text for first-year PhD courses. It builds a common
analytical and methodological framework and then applies it across the field, connecting
theory to data throughout. This repository holds the material that goes with the book:
lecture slides and the code and data behind its quantitative results.

The companion website is **[phdmacrobook.org](https://phdmacrobook.org/)**, where you will
also find the online appendices and other resources.

---

## What is here

| Folder | Contents |
|---|---|
| **[Slides](Slides)** | Lecture slides for each chapter, as compiled PDFs and as LaTeX/Beamer sources you can adapt |
| **[Codes-and-Data](Codes-and-Data)** | Code and data reproducing the figures, tables, and quantitative results in the book |

Everything is organized by chapter number, so if you are working on a given chapter you can
go to the folder with that number in both places.

The book has 25 chapters in three parts. **Foundations** (Chapters 1-8) develops the core
framework and is meant to be read in order. **Tools** (Chapters 9-10) covers continuous-time
and computational methods. **Applications** (Chapters 11-25) are self-contained topic
chapters, most written with a contributing expert.

## How to use it

**Teaching from the book.** The slides are a starting point, not a fixed
package. The LaTeX sources are here so you can cut, reorder, and rewrite them to fit your
own sequence.

**Studying from the book.** The code is often the most useful part. Several chapters work
through models that can only be solved numerically, and reading the code alongside the text
is usually the fastest way to see how a model actually gets solved.

**Reproducing a figure or table.** Look in [`Codes-and-Data`](Codes-and-Data) under the
relevant chapter. Each chapter folder has a README describing what the files do.

Code in the repository is written in MATLAB, Stata, Python, Fortran, and GAUSS, depending
on the chapter; each chapter README says what its files need.

## Availability

The repository is filled in chapter by chapter as material is finalized, so some folders
are still empty. If what you need is not here yet it is most likely still in preparation. Check for updates or contact us requesting missing material for a specific chapter.

## Citing the book

```bibtex
@book{azzimonti2026macroeconomics,
  author    = {Azzimonti, Marina and Krusell, Per and McKay, Alisdair
               and Mukoyama, Toshihiko},
  title     = {Macroeconomics},
  publisher = {Oxford University Press},
  year      = {2026},
  isbn      = {978-0-19-783601-9},
  doi       = {10.1093/oso/9780197836019.001.0001}
}
```
## Citing Code

If you use code or data from this repository for your work, please cite it.

```bibtex
@software{phd_macro_book_code,
  author = {Azzimonti, Marina and Krusell, Per and McKay, Alisdair
               and Mukoyama, Toshihiko},
  title = {Macroeconomics, Code and Data},
  url = {https://github.com/PhD-Macroeconomics/PHD-Macro-Book},
  version = {1.0},
  date = {2026}
}
```

## Comments and corrections

Comments, corrections, and suggestions on the book and on these materials are welcome.
See the contact page at [phdmacrobook.org](https://phdmacrobook.org/).

## * Contributing Authors

Timo Boppart, University of Zurich

Giancarlo Corsetti, European University Institute

Luca Dedola, European Central Bank

Juan Carlos Hatchondo, Western University

John Hassler, IIES, Stockholm University

Jonathan Heathcote, Federal Reserve Bank of Minneapolis

Andreas Hornstein, Federal Reserve Bank of Richmond

Peter Klenow, Stanford University

Simon Lloyd, Bank of England

Leonardo Martinez, IMF

Kurt Mitman, IIES, Stockholm University

Conny Olovsson, Sveriges Riksbank

Monika Piazzesi, Stanford University

Vincenzo Quadrini, Marshall School of Business, University of Southern California

Morten Ravn, University College London

Richard Rogerson, Princeton University

José-Víctor Ríos Rull, University of Pennsylvania

Aysegül Sahin, Princeton University

Martin Schneider, Stanford University

Kjetil Storesletten, University of Minnesota

Gianluca Violante, Princeton University
