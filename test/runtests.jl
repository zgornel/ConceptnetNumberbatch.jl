using Test
using ConceptnetNumberbatch

# Test file with just 2 entriesa (test purposes only)
const CONCEPTNET_TEST_FILES = [
    joinpath(string(@__DIR__), "data", "_test_file.txt.gz"),
    joinpath(string(@__DIR__), "data", "_test_file.txt"),
    joinpath(string(@__DIR__), "data", "_test_file.h5")
    ]

@testset "Parser: (no arguments)" begin
    for file in CONCEPTNET_TEST_FILES
        cptnet, _len, _width= load_embeddings(file);
        @test _len == length(cptnet)
        for k in keys(cptnet)
            @test _width == length(cptnet[k])
        end

        @test _len isa Int
        @test _width isa Int

        if occursin(".h5", file)
            @test cptnet isa Dict{String, Vector{Int8}}
        else
            @test cptnet isa Dict{String, Vector{Float64}}
        end
    end
end

max_vocab_size=5
keep_words = ["####_ish", "####_form", "####_metres"]
@testset "Parser: max_vocab_size=5" begin
    for file in CONCEPTNET_TEST_FILES[1:2]  # skip hdf5 file
        cptnet, _len, _width= load_embeddings(file, max_vocab_size=max_vocab_size);
        @test length(cptnet) == max_vocab_size
    end
end

@testset "Parser: max_vocab_size=5, 3 keep words" begin
    for file in CONCEPTNET_TEST_FILES[1:2]  # skip hdf5 file
        cptnet, _len, _width= load_embeddings(file, max_vocab_size=max_vocab_size,
                                              keep_words=keep_words);
        @test length(cptnet) == length(keep_words)
        for word in keep_words
            @test word in keys(cptnet)
        end
    end
end
