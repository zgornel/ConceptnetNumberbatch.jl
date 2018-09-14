using Test
using Serialization
using ConceptnetNumberbatch

# Burn-in
const CPTNET_PATH = joinpath(string(@__DIR__), "data", "_test_file.txt.gz")

@testset "Parser" begin
    _len, _width, cptnet= parse_file(CPTNET_PATH);
    pop!(cptnet, "")  # remove the last entry i.e. ""=>[]
    @test _len == length(cptnet)
    for k in keys(cptnet)
        @test _width == length(cptnet[k])
    end
end

# fid = open("_tmp.bin","w+")
# @time serialize(fid, cptnet)
# seekstart(fid); deserialize(fid)

# println("Loading from disk ...")
# seekstart(fid); xx=@time deserialize(fid)
