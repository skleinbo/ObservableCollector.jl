module ObservableCollector

export  @at,
        @every,
        @condition,
        @observations


macro at(args...)
    if length(args)!==3
        throw(ArgumentError("@at requires 3 arguments."))
    end
    esc(quote
        eval_args = eval.($args)
        @assert reduce(&, (<:).(typeof.(eval_args), (Integer,String,Function))) == true "Wrong argument types to @at: $eval_args."
        local step,name,map = eval_args
        name = Symbol(name)
        if step == 0
            throw(ArgumentError("Step length cannot be zero."))
        end
        return (name=name, map=map, condition=(state,t)->(t == step)==0)
    end)
end

macro every(args...)
    if length(args)!==3
        throw(ArgumentError("@every requires 3 arguments."))
    end
    esc(quote
        eval_args = eval.($args)
        @assert reduce(&, (<:).(typeof.(eval_args), (Integer,String,Function))) == true "Wrong argument types to @every: $eval_args."
        local step,name,map = eval_args
        name = Symbol(name)
        if step == 0
            throw(ArgumentError("Step length cannot be zero."))
        end
        return (name=name, map=map, condition=(state,t)->(t % step)==0)
    end)
end

macro condition(args...)
    if length(args)!==3
        throw(ArgumentError("@condition requires 3 arguments."))
    end
    esc(quote
        eval_args = eval.($args)
        @assert reduce(&, (<:).(typeof.(eval_args), (Function,String,Function))) == true "Wrong argument types to @condition: $eval_args."
        local condition,name,map = eval_args
        name = Symbol(name)
        return (name=name, map=map, condition=condition)
    end)
end

macro observations(ex::Expr)
    bodyparts = filter(x->typeof(x)==Expr && x.head==:macrocall,ex.args)

    esc(quote
        clauses = eval.($bodyparts)
        global func = :(;)
        for clause in clauses
            global func = quote
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
