

## Activate environment and import packages
cd(@__DIR__)
using Pkg
Pkg.activate(".")
using DirectDetections, Distributions

###################################
## More sophisticated model: fit orbit and mass using both astrometry and GAIA-HIPPARCOS proper motion anomaly.
@named b = Planet(
    Priors(
        a = Uniform(1, 75),
        i = Sine(),
        e = Uniform(0,  1),
        Ω = Uniform(0,  π),
        ω = Uniform(0, 2π),
        τ = Uniform(0, 1),
        # Mass in Jupiter-masses. Log-uniform is a reasonable uninformative prior.
        mass = Uniform(0.1, 100)
    ),
    Astrometry(
        (epoch=57009.0, ra= 69.3356, dec=-448.917, σ_ra= 1.82477,  σ_dec= 1.8787 ),
        (epoch=57052.0, ra= 78.3783, dec=-444.96 , σ_ra= 2.05054,  σ_dec= 2.05971),
        (epoch=57053.0, ra= 77.8303, dec=-450.121, σ_ra= 2.39716,  σ_dec= 2.565  ),
        (epoch=57054.0, ra= 76.9638, dec=-455.037, σ_ra=24.1568 ,  σ_dec=23.9074 ),
        (epoch=57266.0, ra=100.052 , dec=-443.966, σ_ra= 2.07345,  σ_dec= 2.22231),
        (epoch=57332.0, ra=108.641 , dec=-439.656, σ_ra= 4.56234,  σ_dec= 5.36208),
        (epoch=57374.0, ra=112.918 , dec=-441.705, σ_ra= 4.65729,  σ_dec= 6.13954),
        (epoch=57376.0, ra=112.464 , dec=-440.892, σ_ra= 3.39255,  σ_dec= 3.0549 ),
        (epoch=57415.0, ra=110.406 , dec=-440.845, σ_ra= 4.18857,  σ_dec= 5.93133),
        (epoch=57649.0, ra=142.053 , dec=-432.057, σ_ra= 2.05962,  σ_dec= 2.02432),
        (epoch=57652.0, ra=141.521 , dec=-428.673, σ_ra= 2.46576,  σ_dec= 2.6485 ),
        (epoch=57739.0, ra=153.258 , dec=-422.449, σ_ra= 2.12148,  σ_dec= 2.14627),
        (epoch=58068.0, ra=187.509 , dec=-406.365, σ_ra= 3.04171,  σ_dec= 3.02463),
        (epoch=58442.0, ra=219.468 , dec=-374.674, σ_ra= 1.815  ,  σ_dec= 1.9453 ),
    )
)
@named cEri_pma = System(
    Priors(
        plx = gaia_plx(gaia_id=3205095125321700480),
        M  = TruncatedNormal(1.75, 0.005, 0, Inf),
    ),
    # We compute the proper motion anomaly by comparing the GAIA and HIPPARCOS proper motions against their
    # long-term trend in position. This is like radial velocity detection, but in the plane of the sky instead
    # of towards/away.
    ProperMotionAnomHGCA(gaia_id=3205095125321700480),
    # And here we list our planets:
    b
)

chains_pma = DirectDetections.hmc(
    cEri_pma, 0.95,
    adaptation=  1_000,
    iterations= 25_000,
    tree_depth=    13,
)

## Plot fitted model (will take ~1 minute the first time), coloured by ecentricity.
using Plots
plotmodel(chains_pma, color=:e, pma_scatter=:mass, xlims=(-750,750), ylims=(-500,750))

##
# using DirectOrbits
# function mplot(chain, planet_key, color, prop)
#     planet = chain.info.model.planets[planet_key]
#     if prop == :ra
#         ylabel = "RA"
#     elseif prop == :dec
#         ylabel = "DEC"
#     elseif prop == :rv
#         ylabel = "RV"
#     elseif prop == :pmra
#         ylabel = "RA/yr"
#     elseif prop == :pmdec
#         ylabel = "DEC/yr"
#     end
#     p1 = plot(;
#         ylabel,
#         legend=:none
#     )
#     N = 500
#     ii = rand(1:size(chain,1)*size(chain,3), N)
#     elements = DirectDetections.construct_elements(chain, planet_key, ii)
#     y = nothing
#     if prop == :ra
#         t = range((extrema(b.astrometry.epoch) .+ [-300, 300])..., length=100)
#         y = planet.astrometry.ra
#         yerr = planet.astrometry.σ_ra
#         fit = raoff.(elements, t')'
#         x = planet.astrometry.epoch
#     elseif prop == :dec
#         t = range((extrema(b.astrometry.epoch) .+ [-300, 300])..., length=100)
#         y = planet.astrometry.dec
#         yerr = planet.astrometry.σ_dec
#         fit = decoff.(elements, t')'
#         x = planet.astrometry.epoch
#     elseif prop == :pmra
#         t = range((extrema(chain.info.model.propermotionanom.ra_epoch) .+ [-300, 300])..., length=100)
#         y = chain.info.model.propermotionanom.pm_ra
#         yerr = chain.info.model.propermotionanom.σ_pm_ra
#         fit = getindex.(
#             propmotionanom.(elements, t', collect(chain["$planet_key[mass]"][ii]).*DirectDetections.mjup2msol),
#             1
#         )'
#         x = chain.info.model.propermotionanom.ra_epoch
#     elseif prop == :pmdec
#         t = range((extrema(chain.info.model.propermotionanom.dec_epoch) .+ [-300, 300])..., length=100)
#         y = chain.info.model.propermotionanom.pm_dec
#         yerr = chain.info.model.propermotionanom.σ_pm_dec
#         fit = getindex.(
#             propmotionanom.(elements, t', collect(chain["$planet_key[mass]"][ii]).*DirectDetections.mjup2msol),
#             2
#         )'
#         x = chain.info.model.propermotionanom.dec_epoch
#     elseif prop == :rv
#         # TODO
#         t = range((extrema(b.astrometry.epoch) .+ [-300, 300])..., length=100)
#         x = planet.astrometry.epoch
#         fit = radvel.(elements, t', collect(chain["$planet_key[mass]"][ii]))'
#     end
#     plot!(
#         t, fit,
#         line_z=repeat(
#             collect(chain["$planet_key[$color]"][ii]),
#             1, length(t)
#         )',
#         alpha=0.05
#     )
#     if !isnothing(y)
#         scatter!(
#             p1,
#             x,
#             y; yerr
#         )
#     end
#     p1
# end
using Plots
plot(
    DirectDetections.timeplot(chains_pma, :b, :mass, :ra),
    DirectDetections.timeplot(chains_pma, :b, :mass, :dec),
    DirectDetections.timeplot(chains_pma, :b, :mass, :rv),
    DirectDetections.timeplot(chains_pma, :b, :mass, :pmra),
    DirectDetections.timeplot(chains_pma, :b, :mass, :pmdec),
    layout = @layout([
        A
        B
        C
        D E
    ]),
    framestyle=:box,
    size=(500,700)
)

## Look at just the mass
histogram(chains_pma["b[mass]"], xlabel="mass (Mⱼᵤₚ)")

## Mass vs. semi-major axis
histogram2d(
    chains_pma["b[a]"   ],
    chains_pma["b[mass]"],
    xlabel="a (AU)",
    ylabel="mass (Mⱼᵤₚ)",
)

##
density(chains_pma["b[mass]"], xlabel="mass (Mⱼᵤₚ)")

##
using PairPlots
corner(chains_pma)


## investigate acceleration
elems = DirectDetections.construct_elements(chains_pma, :b, 1:size(chains_pma,1));

using ForwardDiff
using StaticArrays
using DirectOrbits
function accel(elems, t, mass)
    ∂²ra∂t² =  ForwardDiff.derivative(t->propmotionanom(elems, t, mass)[1], t)
    ∂²dec∂t² =  ForwardDiff.derivative(t->propmotionanom(elems, t, mass)[2], t)
    return SVector(∂²ra∂t²*DirectOrbits.year2days, ∂²dec∂t²*DirectOrbits.year2days)
end
@time accel(elems[1], 1000.0, chains_pma["b[mass]"][1].*DirectDetections.mjup2msol)


##

N = 250
ii = rand(1:size(chains_pma,1), N)

# ts = range(first(b.astrometry.epoch) - 10*365, last(b.astrometry.epoch) + 10*365, length=200)
ts = range(first(cEri_pma.propermotionanom.ra_epoch) - 365, last(cEri_pma.propermotionanom.ra_epoch) + 365, length=200)

##
line_z=repeat(
    collect(chains_pma["b[mass]"][ii]),
    1, length(ts)
)'

vel = propmotionanom.(elems[ii], ts', chains_pma["b[mass]"][ii].*DirectDetections.mjup2msol)';
dra = getindex.(vel, 1)
ddec = getindex.(vel, 2)
pvelra = plot(ts, dra, color=:black, alpha=0.5,title="vel ra", line_z=line_z,label="", legend=false)
scatter!(cEri_pma.propermotionanom.ra_epoch, cEri_pma.propermotionanom.pm_ra, yerr=cEri_pma.propermotionanom.σ_pm_ra)
pveldec = plot(ts, ddec, color=:black, alpha=0.5,title="vel dec", line_z=line_z,label="", colorbar_title="mass (mjup)")
scatter!(cEri_pma.propermotionanom.dec_epoch, cEri_pma.propermotionanom.pm_dec, yerr=cEri_pma.propermotionanom.σ_pm_dec, label="")


acc = accel.(elems[ii], ts', chains_pma["b[mass]"][ii].*DirectDetections.mjup2msol)';
ddra = getindex.(acc, 1)
dddec = getindex.(acc, 2)
paccra = plot(ts, ddra, color=:black, alpha=0.5, title="acc ra", line_z=line_z,label="", legend=false)
paccdec = plot(ts, dddec, color=:black, alpha=0.5, title="acc dec", line_z=line_z,label="", colorbar_title="mass (mjup)")
plts = pvelra, pveldec, paccra, paccdec
vline!.(plts, Ref([extrema(cEri_pma.propermotionanom.ra_epoch)...]), label="")
p=plot(plts..., layout=(2,2))

##
elem_earth = KeplerianElementsDeg(
    a = 1.0,
    μ = 1.0,
    i = 0,
    e = 0,
    ω = 0,
    Ω = 0,
    plx = 1000,
    τ = 0,
)
vel = propmotionanom.(elem_earth, ts, 1 .* DirectDetections.mjup2msol);
dra = getindex.(vel, 1)
acc = accel.(elem_earth, ts,  1 .* DirectDetections.mjup2msol);
ddra = getindex.(acc, 1)
plot(ts, dra, legend=false)
plot!(ts, ddra, legend=false)
