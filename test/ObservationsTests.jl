using Test
using ObservableCollector

output = []

obs01 = @observations begin
end
obs02 = @observations begin
    @every 2 "O1" (s,t)->t
end

@test obs01(output,0,0) == ()

@test begin
    output = []
    for t in 1:10
        obs02(output,0,t)
    end
    output == [("O1",2),("O1",4),("O1",6),("O1",8),("O1",10)]
end
