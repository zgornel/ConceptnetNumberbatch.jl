using Test
using Languages
using ConceptnetNumberbatch

# Test file with just 2 entriesa (test purposes only)
const CONCEPTNET_TEST_DATA = Dict(  # filename => output type
    (joinpath(string(@__DIR__), "data", "_test_file_en.txt.gz") =>
     ([Languages.English()],
      ["####_ish", "####_form", "####_metres"],
      ConceptNet{Languages.English, String, Vector{Float64}})),

    (joinpath(string(@__DIR__), "data", "_test_file_en.txt") =>
     ([Languages.English()],
      ["####_ish", "####_form", "####_metres"],
      ConceptNet{Languages.English, String, Vector{Float64}})),

    (joinpath(string(@__DIR__), "data", "_test_file.txt") =>
     (nothing,
     ["1_konings", "aaklig", "aak"],
      ConceptNet{Languages.Language, String, Vector{Float64}})),

    (joinpath(string(@__DIR__), "data", "_test_file.h5") =>
     (nothing,
      ["1", "2", "2d"],
      ConceptNet{Languages.Language, String, Vector{Int8}}))
   )

@testset "Parser: (no arguments)" begin
    for (filename, (languages, _, resulting_type)) in CONCEPTNET_TEST_DATA
        conceptnet, _len, _width = load_embeddings(filename, languages=languages);
        @test conceptnet isa resulting_type
        @test _len isa Int
        @test _width isa Int
        @test _width == size(conceptnet, 1)
    end
end

max_vocab_size=5
@testset "Parser: max_vocab_size=5" begin
    for (filename, (languages, _, _)) in CONCEPTNET_TEST_DATA
        conceptnet, _len, _width = load_embeddings(filename,
                                                   max_vocab_size=max_vocab_size,
                                                   languages=languages);
        @test length(conceptnet) == max_vocab_size
    end
end

max_vocab_size=5
@testset "Parser: max_vocab_size=5, 3 keep words" begin
    for (filename, (languages, keep_words, _)) in CONCEPTNET_TEST_DATA
        conceptnet, _len, _width = load_embeddings(filename,
                                                   max_vocab_size=max_vocab_size,
                                                   keep_words=keep_words,
                                                   languages=languages)
        @test length(conceptnet) == length(keep_words)
        for word in keep_words
            @test word in conceptnet
        end
    end
end

@testset "Indexing" begin
    # English language
    filepath = joinpath(string(@__DIR__), "data", "_test_file_en.txt.gz")
    conceptnet, _, _ = load_embeddings(filepath, languages=[Languages.English()])
    words = ["####_ish", "####_form", "####_metres", "not_found", "not_found2"]
    embeddings = conceptnet[words]
    for (idx, word) in enumerate(words)
        if word in conceptnet
            @test embeddings[:,idx] == conceptnet.embeddings[Languages.English()][word]
        else
            @test iszero(embeddings[:,idx])
        end
    end
    # Multiple languages
    filepath = joinpath(string(@__DIR__), "data", "_test_file.txt")
    conceptnet, _, _ = load_embeddings(filepath, languages=nothing)
    words = ["1_konings", "aaklig", "aak", "maggunfully"]
    @test_throws MethodError conceptnet[words]
    for (idx, word) in enumerate(words)
        @test_throws KeyError conceptnet[Languages.English(), word]
        if word in conceptnet
            @test vec(conceptnet[Languages.Dutch(), word]) ==
                conceptnet.embeddings[Languages.Dutch()][word]
        else
            @test iszero(conceptnet[Languages.Dutch(),word])
        end
    end
end


# show methods
@testset "Show methods" begin
    buf = IOBuffer()
    for (filename, (languages, _, _)) in CONCEPTNET_TEST_DATA
        try
            conceptnet = load_embeddings(filename, languages=languages)
            show(buf, conceptnet)
            @test true
        catch
            @test false
        end
    end
end
