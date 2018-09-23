using Pkg; Pkg.activate(".");
#=
# -----------------------------------------------------------
using ConceptnetNumberbatch
using BenchmarkTools
using Random

N = 100_000 # vocabulary/embeddings size
W = 300  # length of embedding vector
n = 1_000  #length of a query
m = 1_000 # number of queries
words = [randstring(10) for i in 1:N]
embs = rand(W, N)
dcpt = Dict(words[i]=>embs[:,i] for i in 1:N)
cpt = ConceptNet{:en, String, Vector{Float64}}(dcpt,W)
#cpt,_,_ = load_embeddings("../_conceptnet/unzipped/numberbatch-en-17.06.txt",
#                         language=:en)
#dcpt = Dict(cpt.words[idx]=>cpt.embeddings[:,idx] for idx in 1:length(cpt.words))

#targets = [words[rand(1:N, n)]..., [randstring(10) for i in 1:n]...] ;
targets = [words[rand(1:N, n)] for _ in 1:m] ;

# Burn-in
cpt["a"];
hcat((get(dcpt, word, zeros(300)) for word in targets)...)

#Benchmark
println("----------------------")

func_a(cpt, targets) = begin
    for t in targets 
        cpt[t]
    end
end

@benchmark func_a(cpt, targets)
=#
using StringDistances
using ConceptnetNumberbatch
using BenchmarkTools
using Random
using Serialization

fid = open("./_conceptnet_/numberbatch-en-17.06.txt.bin")
cptnet = deserialize(fid)
close(fid)
words = (key for key in keys(cptnet) if isascii(key))

target="sstring"
for dist in [Jaro(), Levenshtein(), DamerauLevenshtein(), Cosine(), QGram(2), QGram(3)]
    _, idx = findmin(map(x->evaluate(dist, target, x), words))
    println("---------------")
    @time _, idx = findmin(map(x->evaluate(dist, target, x), words))
    println("[$dist], best match: $(collect(words)[idx])")
end

