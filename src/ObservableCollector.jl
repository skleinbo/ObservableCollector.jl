module ObservableCollector

export  @at,
        @every,
        @observations

function get_arguments(args)
    name, map, step = ("", nothing, 0)
    for arg in args
        if typeof(arg)==String
            name = arg
        elseif typeof(arg)<:Integer
            step = arg
        else
            map = arg
        end
    end
    if name == "" || map == nothing
        error("Invalid arguments to @at")
    end
    (name,map,step)
end

macro at(args...)
    if length(args)!==3
        throw(ArgumentError("@at requires 3 arguments."))
    end
    name,map,step = get_arguments(args)
    return esc(:( (name=$name, map=$map, condition=(state,t)->t==$step) ))
end

macro every(args...)
    if length(args)!==3
        throw(ArgumentError("@every requires 3 arguments."))
    end
    name,map,step = get_arguments(args)
    return esc(:( (name=$name, map=$map, condition=(state,t)->(t% $step)==0) ))
end


macro observations(ex::Expr)
    bodyparts = Expr[]
    for subexpr in ex.args
        if typeof(subexpr)==Expr && subexpr.head==:macrocall
            f = eval(subexpr)
            bodypart = quote
                if $(f.condition)(state,t)
                    push!(output, ($(f.name),$(f.map)(state,t)))
                end
            end
            push!(bodyparts, bodypart)
        end
    end
    fullbody = :()
    for bodypart in bodyparts
        fullbody = :($fullbody; $bodypart)
    end
    return quote
        (output, state, t) -> $fullbody;
    end
end

end
