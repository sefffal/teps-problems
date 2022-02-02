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
Pkg.activate(".")
using DirectDetections, Distributions

## Create a 1-planet model
@named b = Planet(
    # Here we specify priors for different orbital parameters.
    # We'll start with uniform priors; however, uniform
    # priors are not ideal for real world orbit fitting.
    Priors(
        # Semi-major axis in AU:
        a = Uniform(1, 75),
        # The orbital inclination in radians.
        # The Sine() distribution gives a uniform distribution
        # orbits points in spherical coordinates:
        i = Sine(),
        # Eccentricity:
        e = Uniform(0,  1),
        # Longitude of the ascending node (i.e. orientation of the orbital plane)
        Ω = Uniform(0,  π),
        # Argument of periapsis (where does the planet come closest to the star)
        ω = Uniform(0, 2π),
        # Epoch of periastron passage, as fraction of orbital period after 2020-01-01.
        # (when did the planet make it's closest approach.)
        τ = Uniform(0, 1)
    ),
    # List any astrometry points we have for the planet.
    # Fill this in from Table 2. You will have to convert from
    # PA angle (deg) and separation (mas) to Δra, Δdec.
    # It's okay to estimate the σ_ra and σ_dec uncertainties.
    # Note: all values MUST include a decimal place.
    Astrometry(
        # Examples (replace data with table 2 in paper. 13 rows instead of 2)
        (epoch=12345., ra=123.0, dec=123.0, σ_ra=10., σ_dec=10.),
        (epoch=12645., ra=223.0, dec=-123.0, σ_ra=100., σ_dec=10.),
    )
)

# We place our planet model into a model of the whole system.
# You will be prompted to download a small star catalog the first time you run this.
@named cEri = System(
    Priors(
        # plx represents the parallax distance in milliarcseconds to the system.
        # Replace this ID with the GAIA EDR3 identifier for 51 Eri (aka cEri).
        # You can find it on SIMBAD: http://simbad.u-strasbg.fr/simbad/sim-id?Ident=51+Eri
        plx = gaia_plx(gaia_id=00000000),
        # μ represents the total system mass in solar masses. You can find an accepted value and uncertainty in the paper.
        μ   = TruncatedNormal(1.0, 0.5, 0, Inf),
    ),
    # And here we list our planets:
    b
)

## Fit 
# This could take ~2-5 minutes.
# If your answer doesn't match the paper, you can try re-running with more
# iteartions (e.g. 20,000 or even 100,000 if you're patient)
chains = DirectDetections.hmc(
    cEri, 0.95,
    adaptation=  1000,
    iterations= 5_000,
    tree_depth=    13,
)
# You can also run multiple chains in parallel - let us know and we can help you
# set that up.

## View summary of results
display(chains)

## Plot fitted model (will take ~1 minute the first time), coloured by ecentricity.
using Plots
plotmodel(chains, color=:e, alpha=0.1)
xlims!(-1000,750)
ylims!(-750,1000)

## Optional: save your figure
savefig("cEri-orbit-posterior.pdf")


## Look at just the semi-major axis histgoram (i.e. the marginal posterior)
histogram(chains["b[a]"])
