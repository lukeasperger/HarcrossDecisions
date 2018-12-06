
using Printf
using DataFrames
using CSV
using SpecialFunctions
using Random
using SparseArrays
using JSON


#this file will produce dictionary of all the Q-values for state, action pairs
function compute_policies(infile)
    discount = 0.95
    df = CSV.read(infile)
    s = df[1,1]
    a  = df[1,2]
    sp = df[1,3]
    r = df[1,4]
    N = Dict()
    N_sums = Dict()
    reward = Dict()
    T = Dict()
    T_sums = Dict()
    R = Dict()
    Q = Dict()
    N[(s,a,sp)] = 1
    N_sums[(s,a)] = 1
    reward[(s,a)] = r
    T[(sp,s,a)] = float(N[(s,a,sp)])/N_sums[(s,a)]
    R[(s,a)] = float(reward[(s,a)])/N_sums[(s,a)]
    Q[(s,a)] = R[(s,a)] # iterate over actions Q(s',a'), 0 if action unseen
    n = 1
    while (n < size(df,1))
        n = n + 1
        s = df[n,1]
        a = df[n,2]
        sp = df[n,3]
        r = df[n,4]
        if haskey(N,(s,a,sp))
            N[(s,a,sp)] = N[(s,a,sp)] + 1
        else
            N[(s,a,sp)] = 1
        end
        if haskey(N_sums,(s,a))
            N_sums[(s,a)] = N_sums[(s,a)] + 1
        else
            N_sums[(s,a)] = 1
        end
        if haskey(reward,(s,a))
            reward[(s,a)] = reward[(s,a)] + r
        else
            reward[(s,a)] = r
        end
        T[(sp,s,a)] = N[(s,a,sp)]/N_sums[(s,a)]
        R[(s,a)] = reward[(s,a)]/N_sums[(s,a)]
        max = 0
        for ap in collect(1:4)
            if haskey(Q,(sp,ap))
                    val = Q[(sp,ap)]*T[(sp,s,a)]
            else
                    val = 0
            end
            if val > max
                max = val
            end
        end
        Q[(s,a)] = R[(s,a)] + discount*max #max_aiQ(sp,ap), iterate over actions Q(s',a'), 0 if action unseen
    end
    optimalPols = Dict()
    num_states = 1296
    num_actions = 15
    json_string = JSON.json(Q)
    open("skull_Q.json","w") do f
      JSON.print(f, json_string)
    end
end

inputfilename = "100000_rounds.CSV"
compute_policies(inputfilename)



using JSON
data=JSON.parsefile("skull_Q.json")  # parse and transform data
data = data[3:end-1]
d = split(data, """,\"""" )
values = []
dict = Dict()
for i in 1:length(d)
    string = d[i]
    right_paren = findfirst(")", string)
    #print(right_paren[1])
    key = string[2:right_paren[1]-1]
    keys = split(key, ",")
    sa_pair = (parse(Int32, keys[1]),parse(Int32, keys[2][1:end]))
    value = string[right_paren[1] + 3:end]
    value = parse(Float64,value)
    dict[sa_pair] = value
end
return dict

for (key,value) in dict
    print(key, "==>", value)
end
