module ObservableCollector

export  @at,
        @every,
        @condition,
        @observations

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

macro condition(args...)
    if length(args)!==3
        throw(ArgumentError("@condition requires 3 arguments."))
    end
    esc(quote
        @condition $(args[1]) begin $(args[2]) --> $(args[3]) end
    end)
end

macro at(args...)
    esc(quote
        @condition (s,t)->t==$(args[1]) $(args[2]) $(args[3])
    end)
end

macro every(args...)
    esc(quote
        @condition (s,t)->t % $(args[1])==0 $(args[2]) $(args[3])
    end)
end

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
