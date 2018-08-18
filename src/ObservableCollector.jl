module ObservableCollector

export  @at,
        @every,
        @condition,
        @observations

macro condition(args...)
    if length(args)!==3
        throw(ArgumentError("@condition requires 3 arguments."))
    end
    esc(quote
        local eval_args = eval.($args)
        @assert reduce(&, (<:).(typeof.(eval_args), (Function,String,Function))) == true "Wrong argument types to @condition: $eval_args."
        local condition,name,map = eval_args
        name = Symbol(name)
        return (name=name, map=map, condition=condition)
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
        for clause in clauses
            func = quote
                $func;
                if (($clause).condition)(state,t)
                    push!(output, (name=($clause).name,val=(($clause).map)(state,t)))
                end
            end
        end
        eval( :( (output, state, t) -> begin $func; nothing end ) )
    end)

end

end
