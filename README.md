# teps-problems

This repository has examples of fitting exoplanet orbits to astrometry using our new package, DirectDetections.
We will be reproducing the results of *"An Updated Visual Orbit of the Directly Imaged Exoplanet 51 Eridani b and Prospects for a Dynamical Mass Measurement with Gaia"* and going a bit beyond as well.

You can find the paper here: 
https://iopscience.iop.org/article/10.3847/1538-3881/ab4da4

## Files

* `example-1.jl` is a template you can use to fit the orbit of the planet. If you get stuck, `example-1-worked.jl` has the solutions.

* `example-2.jl` adds data from the HIPPARCOS-GAIA Catalog of Accelerations by Brandt et al, 2020. This lets us fit the dynamical mass of the planet and improve the orbital solution.

## Getting Started

1. Download Julia 1.7: https://julialang.org/downloads/
If you don't want to install it, you can use it on Compute Canada clusters too.

2. Look at, edit, and run `example-1.jl`
