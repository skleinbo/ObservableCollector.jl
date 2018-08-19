using Test
using ObservableCollector

output = []

@test begin
    output = []
    obs = @observations begin
        @every 2 "O2" (s,t)->t
    end
    for t in 1:10
        obs(output,0,t)
    end
    output == [(name=:O2, val=2j) for j in 1:5]
end

@test begin
    output = []
    obs = @observations begin
        @at 2 "AT" (s,t)->t
    end
    for t in 1:10
        obs(output,0,t)
    end
    output == [(name=:AT, val=2)]
end

@test begin
    output = []
    obs = @observations begin
        @condition (s,t)->s+t==5 "sumtofive" (s,t)->t
    end
    for t in 1:10
        obs(output,1,t)
    end
    output == [(name=:sumtofive, val=4)]
end

@test begin
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
    output == [(name=:A, val=1),(name=:T, val=3),(name=:A, val=1),(name=:T, val=4)]
end
