using Test
using Serialization
using ConceptnetNumberbatch

# Test file with just 2 entriesa (test purposes only)
const CONCEPTNET_TEST_FILES = [
    joinpath(string(@__DIR__), "data", "_test_file.txt.gz"),
    joinpath(string(@__DIR__), "data", "_test_file.txt"),
    joinpath(string(@__DIR__), "data", "_test_file.h5")
    ]

@testset "Parser" begin
    for file in CONCEPTNET_TEST_FILES
        cptnet, _len, _width= ConceptnetNumberbatch.load_embeddings(file);
        @test _len == length(cptnet)
        for k in keys(cptnet)
            @test _width == length(cptnet[k])
        end
    end
end

# fid = open("_tmp.bin","w+")
# @time serialize(fid, cptnet)
# seekstart(fid); deserialize(fid)

# println("Loading from disk ...")
# seekstart(fid); xx=@time deserialize(fid)
