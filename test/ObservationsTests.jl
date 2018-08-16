using Test
using ObservableCollector

output = []

obs01 = @observations begin
end
obs02 = @observations begin
    @every 2 "O2" (s,t)->t
end
obs03 = @observations begin
    @condition (s,t)->s+t==5 "sumtofive" (s,t)->t
end


@test begin
    output = []
    for t in 1:10
        obs02(output,0,t)
    end
    output == [(name=:O2, val=2j) for j in 1:5]
end

@test begin
    output = []
    for t in 1:10
        obs03(output,1,t)
    end
    output == [(name=:sumtofive, val=4)]
end
