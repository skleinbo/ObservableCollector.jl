# ObservableCollector.jl

Easily define observables to be measured.

## Introduction

Simulating a physical/biological/chemical,... system typically involes the following steps
1. Setup a `state` with some initial conditions.
2. Evole `state` through some deterministic or stochastic dynamics for a number of steps.
3. Measure a host of observables; possibly only if some condition is fulfilled.
4. Go back to 2. until the simulation reaches a halting condition.

Step 3. typically involves preparing a vector for each quantity to be measured (or a dictionary) beforehand,
and then pushing the measurements onto them.

The package at hand implements a convinience layer around step 3.

__Terminology:__
- __state__ The current state of the model. Can be any data type or user defined structure. Contains all necessary information to determine observables from.
- __observable__ Function of state and possibly simulation time. In the an _observable_ will refer to a function `f(state, time)::Any`.

Let us look at a quick (and mostly trivial) example. The state is simply a fixed-size vector. In each timestep we add a bit of random noise to every entry (effectively simulating many random walks on the real line). We'd like to measure mean and variance over time. Additionally we imagine the steps happening at rate `1.0` and thus draw the waiting-time between steps from an exponential distribution.

```@example 1
using ObservableCollector
using Distributions

p = Gamma(100, 1.0) # sum of exponentially distr. rvs is gamma-distributed.
state = fill(0.0, 1000)

obs! = @observations begin
  @condition (s,t)->t%100==0 begin
    "step" --> (s,t)->t
    "dt" --> (s,t)->rand(p)
    "m" --> (s,t)->mean(s)
    "var" --> (s,t)->var(s)
  end
end # note the ! in the name I chose. `obs!` will mutate its first argument.

X = [] # empty array to store all measured quantities in.
for t in 0:10^5 # make 10^5 steps
  obs!(X, state, t)
  state .+= 0.05*randn(length(state))
end

X
```
This storage format is not very appealing. It is simply a linear record of observables collected throughout the run. We may use the `timeseries` function to cast it into a more useful form

```@example 1
timeseries(X)
```

## Hints

- `t` needn't necessarily be time. You may use it as some auxilliary variable, or even as a boolean switch to turn collection on/off. It also need not be a scalar, but could e.g. be a tuple.
- Observables are (by my definition) functions of state only and thus have no access to the measurement history. If you require observables to depend on previous measurements, store those in the state. (__TODO:__ example)

## Available methods

```@docs
@observations
@condition
@at
@every
timeseries
```
