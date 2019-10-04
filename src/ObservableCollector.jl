module ObservableCollector

import Base: push!

export  timeseries,
        @at,
        @every,
        @condition,
        @observations



function Base.push!(D::Dict{Symbol, T}, m::NamedTuple{(:name, :val), Tuple{Symbol, V}}) where {T,V}
    if !haskey(D, m.name)
        push!(D, m.name => Union{V, Missing}[m.val])
    else
        push!(D[m.name], m.val)
    end
    D
end

function timeseries(x::AbstractArray)
    D = Dict{Symbol,Any}()
    for m in x
        if !haskey(D, m.name)
            push!(D, m.name => Union{typeof(m.val), Missing}[m.val])
        else
            push!(D[m.name], m.val)
        end
    end
    # Flatten all arrays of length 1
    for d in D
        if length(d[2])==1
            D[d[1]] = d[2][1]
        end
    end
    D
end



"""
    @condition(cond, block)

Define multiple observables to be evaluated under the same condition. Use `-->`
to define pairs of `name --> map`.

# Example
```julia
@condition (s,t)->t>=3 begin
    "S" --> (s,t)->s^2
    "T" --> (s,t)->t
end
```
"""
macro condition(condition, block)
    typeof(block)==Expr && block.head == :block || throw(ArgumentError("b in @condition(a, b) must be a block."))
    subexpr = filter(x->(typeof(x)==Expr && x.head==:-->), block.args)

    esc(quote
        local observables = []
        for ob in $subexpr
            name, func = eval.(ob.args)
            typeof(name) == String && typeof(func) <: Function || throw(ArgumentError("String and function expected."))
            name = Symbol(name)
            push!(observables, (name = name, map=func))
        end
        (condition=$condition, observables=observables)
    end)
end

"""
    @condition(cond, name, map)

Creates a clause to collect an observable `map(state,time)` called `name` under
condition `cond(state,time)`.

See also: [`@at`](@ref), [`@every`](@ref)
"""
macro condition(cond, name, map)
    esc(quote
        @condition $cond begin $name --> $map end
    end)
end

"""
    @at(N::Integer, name, map)

Creates a clause to collect an observable `map(state,time)` called `name` at
timestep `N`.

See also: [`@condition`](@ref)
"""
macro at(args...)
    esc(quote
        @condition (s,t)->t==$(args[1]) $(args[2]) $(args[3])
    end)
end

"""
    @every(N::Integer, name, map)

Creates a clause to collect an observable `map(state,time)` called `name` every
`N` timesteps, i.e `t%N==0`.

See also: [`@condition`](@ref)
"""
macro every(args...)
    esc(quote
        @condition (s,t)->t % $(args[1])==0 $(args[2]) $(args[3])
    end)
end

"""
    @observations(block)

Creates an anonymous function with arguments `(output::Vector{Any}, state, time)`
    that collects observables under conditions defined in `block`.

# Example:
```julia
output = []
obs = @observations begin
    @condition (s,t)->t>=3 begin
        "A" --> (s,t)->s
        "T" --> (s,t)->t
    end
end
for t in 1:4
    obs(output,1,t)
end

julia> @show output
output = Any[(name = :A, val = 1), (name = :T, val = 3), (name = :A, val = 1), (name = :T, val = 4)]
4-element Array{Any,1}:
 (name = :A, val = 1)
 (name = :T, val = 3)
 (name = :A, val = 1)
 (name = :T, val = 4)
```
"""
macro observations(ex::Expr)
    bodyparts = filter(x->typeof(x)==Expr && x.head==:macrocall,ex.args)

    esc(quote
        local clauses = eval.($bodyparts)
        local func = :(;)
        local inner = :(;)
        for clause in clauses
            if haskey(clause, :observables)
                inner = :(;)
                for m in clause.observables
                    inner = quote
                        $inner;
                        push!(output, (name=($m).name,val=(($m).map)(state,t)))
                    end
                end
            elseif haskey(clause, :map)
                inner = :( push!(output, (name=($clause).name,val=(($clause).map)(state,t))) )
            end
            func = quote
                $func;
                if (($clause).condition)(state,t)
                    $inner;
                end
            end
        end
        eval( :( (output, state, t) -> begin $func; nothing end ) )
    end)

end

end
