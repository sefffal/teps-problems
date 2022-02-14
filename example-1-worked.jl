# This file is an example of fitting an orbit to exoplanet astrometry
# using our new package, DirectDetections.

# We will use the paper "An Updated Visual Orbit of the Directly Imaged
# Exoplanet 51 Eridani b and Prospects for a Dynamical Mass Measurement with Gaia"
# by Rosa et al, 2019
# https://iopscience.iop.org/article/10.3847/1538-3881/ab4da4

# You can copy and paste these blocks one at a time, or modify it
# and run it all by typing: include("example-1.jl")

## Setup: requires Julia 1.7
# Run this once to install the necessary packages.
# You only need to run this once, ever.
cd(@__DIR__)
using Pkg
Pkg.activate(".")
Pkg.update()
Pkg.Registry.add(RegistrySpec(url="https://github.com/sefffal/DirectRegistry.git"))
Pkg.instantiate()

## Activate environment and import packages
cd(@__DIR__)
using Pkg
Pkg.activate(".")
using DirectDetections, Distributions

## Create a 1-planet model
@named b = Planet(
    Priors(
        a = TruncatedNormal(20, 10, 0, Inf),
        i = Sine(),
        e = Beta(1.5, 10),
        Ω = Uniform(0,  π),
        ω = Uniform(0, 2π),
        τ = Uniform(0, 1)
    ),
    Astrometry(
        (epoch=57009.0, ra= 69.3356, dec=-448.917, σ_ra= 1.82477,  σ_dec= 1.8787  ),
        (epoch=57052.0, ra= 78.3783, dec=-444.96 , σ_ra= 2.05054,  σ_dec= 2.05971 ),
        (epoch=57053.0, ra= 77.8303, dec=-450.121, σ_ra= 2.39716,  σ_dec= 2.565   ),
        (epoch=57054.0, ra= 76.9638, dec=-455.037, σ_ra=24.1568 ,  σ_dec=23.9074  ),
        (epoch=57266.0, ra=100.052 , dec=-443.966, σ_ra= 2.07345,  σ_dec= 2.22231 ),
        (epoch=57332.0, ra=108.641 , dec=-439.656, σ_ra= 4.56234,  σ_dec= 5.36208 ),
        (epoch=57374.0, ra=112.918 , dec=-441.705, σ_ra= 4.65729,  σ_dec= 6.13954 ),
        (epoch=57376.0, ra=112.464 , dec=-440.892, σ_ra= 3.39255,  σ_dec= 3.0549  ),
        (epoch=57415.0, ra=110.406 , dec=-440.845, σ_ra= 4.18857,  σ_dec= 5.93133 ),
        (epoch=57649.0, ra=142.053 , dec=-432.057, σ_ra= 2.05962,  σ_dec= 2.02432 ),
        (epoch=57652.0, ra=141.521 , dec=-428.673, σ_ra= 2.46576,  σ_dec= 2.6485  ),
        (epoch=57739.0, ra=153.258 , dec=-422.449, σ_ra= 2.12148,  σ_dec= 2.14627 ),
        (epoch=58068.0, ra=187.509 , dec=-406.365, σ_ra= 3.04171,  σ_dec= 3.02463 ),
        (epoch=58442.0, ra=219.468 , dec=-374.674, σ_ra= 1.815  ,  σ_dec= 1.9453  ),
    )
)
@named cEri = System(
    Priors(
        plx = gaia_plx(gaia_id=3205095125321700480),
        M   = TruncatedNormal(1.75, 0.05, 0, Inf),
    ),
    b
)

## Fit 
# This could take ~5 minutes.
Random.seed!(9876543210)
@time chains = DirectDetections.hmc(
    cEri, 0.95,
    # adaptation=  1000,
    # iterations= 5_000,
    
    adaptation=  50,
    iterations= 50,
    tree_depth=    13,
)
# You can also run multiple chains in parallel - let us know and we can help you
# set that up.

## View summary of results
# display(chains)

## Plot fitted model (will take ~1 minute the first time), coloured by ecentricity.
# This is similar to figure 4.
using Plots
plotmodel(chains, color=:e, alpha=0.1)
xlims!(-1100,700)
ylims!(-600,1100)


## Look at just the semi-major axis histgoram (i.e. the marginal posterior)
histogram(chains["b[a]"])


## Create a corner plot like figure 3
using PairPlots
corner(chains)