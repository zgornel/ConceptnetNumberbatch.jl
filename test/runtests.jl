using Test
using ConceptnetNumberbatch

# Test file with just 2 entriesa (test purposes only)
const CONCEPTNET_TEST_DATA = Dict(  # filename => output type
    (joinpath(string(@__DIR__), "data", "_test_file_en.txt.gz") =>
     (:en,
      ["####_ish", "####_form", "####_metres"],
      ConceptNet{:en, Vector{String}, Matrix{Float64}})),

    (joinpath(string(@__DIR__), "data", "_test_file_en.txt") =>
     (:en,
      ["####_ish", "####_form", "####_metres"],
      ConceptNet{:en, Vector{String}, Matrix{Float64}})),

    (joinpath(string(@__DIR__), "data", "_test_file.txt") =>
     (:multi,
     ["/c/af/1_konings", "/c/af/aaklig", "/c/af/aak"],
      ConceptNet{:multi, Vector{String}, Matrix{Float64}})),

    (joinpath(string(@__DIR__), "data", "_test_file.h5") =>
     (:multi_c,
      ["/c/de/1", "/c/de/2", "/c/de/2d"],
      ConceptNet{:multi_c, Vector{String}, Matrix{Int8}}))
   )

@testset "Parser: (no arguments)" begin
    for (filename, (language, _, resulting_type)) in CONCEPTNET_TEST_DATA
        conceptnet, _len, _width= load_embeddings(filename, language=language);
        @test conceptnet isa resulting_type
        @test _len isa Int
        @test _len == length(conceptnet)
        @test _width isa Int
        @test _width == size(conceptnet, 1)
    end
end

max_vocab_size=5
@testset "Parser: max_vocab_size=5" begin
    for (filename, _) in CONCEPTNET_TEST_DATA
        conceptnet, _len, _width= load_embeddings(filename,
                                                  max_vocab_size=max_vocab_size);
        @test length(conceptnet) == max_vocab_size
    end
end

max_vocab_size=5
@testset "Parser: max_vocab_size=5, 3 keep words" begin
    for (filename, (_, keep_words, _)) in CONCEPTNET_TEST_DATA
        conceptnet, _len, _width= load_embeddings(filename,
                                                  max_vocab_size=max_vocab_size,
                                                  keep_words=keep_words)
        @test length(conceptnet) == length(keep_words)
        for word in keep_words
            @test word in conceptnet.words
        end
    end
end

# show methods
@testset "Show methods" begin
    buf = IOBuffer()
    for (filename, (language, _, _)) in CONCEPTNET_TEST_DATA
        try
            conceptnet = load_embeddings(filename, language=language)
            show(buf, conceptnet)
            @test true
        catch
            @test false
        end
    end
end
