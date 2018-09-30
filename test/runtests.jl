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
        conceptnet = load_embeddings(filename, languages=languages);
        @test conceptnet isa resulting_type
    end
end

max_vocab_size=5
@testset "Parser: max_vocab_size=5" begin
    for (filename, (languages, _, _)) in CONCEPTNET_TEST_DATA
        conceptnet = load_embeddings(filename, max_vocab_size=max_vocab_size,
                                     languages=languages);
        @test length(conceptnet) == max_vocab_size
    end
end

max_vocab_size=5
@testset "Parser: max_vocab_size=5, 3 keep words" begin
    for (filename, (languages, keep_words, _)) in CONCEPTNET_TEST_DATA
        conceptnet = load_embeddings(filename, max_vocab_size=max_vocab_size,
                                     keep_words=keep_words, languages=languages)
        @test length(conceptnet) == length(keep_words)
        for word in keep_words
            @test word in conceptnet
        end
    end
end

@testset "Indexing" begin
    # English language
    filepath = joinpath(string(@__DIR__), "data", "_test_file_en.txt.gz")
    conceptnet = load_embeddings(filepath, languages=[Languages.English()])
    words = ["####_ish", "####_form", "####_metres", "not_found", "not_found2"]

    # Test indexing
    idx = 1
    @test conceptnet[words[idx]] == conceptnet[:en, words[idx]] ==
        conceptnet[Languages.English(), words[idx]]

    # Test values
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
    conceptnet = load_embeddings(filepath, languages=nothing)
    words = ["1_konings", "aaklig", "aak", "maggunfully"]

    # Test indexing
    @test_throws MethodError conceptnet[words]  # type of language is Language, cannot directly search
    @test_throws KeyError conceptnet[:en, "word"]  # English language not present
    @test conceptnet[:nl, words[idx]] ==
        conceptnet[Languages.Dutch(), words[idx]]

    # Test values
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

@testset "Fuzzy Indexing" begin
    filepath = joinpath(string(@__DIR__), "data", "_test_file_en.txt.gz")
    conceptnet = load_embeddings(filepath, languages=[Languages.English()])
    words_and_matches = Dict("aq" => "##",
                             "p'"=>"##",
                             "ab," =>"###",
                             "ddsaw_metres"=>"#####_metres")
    for (word, matching_word) in words_and_matches
        @test conceptnet[word] == conceptnet[matching_word]
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
