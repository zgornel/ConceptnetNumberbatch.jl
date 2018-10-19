struct ConceptNet{L<:Language, K<:AbstractString, V<:AbstractVector}
    embeddings::Dict{L, Dict{K,V}}
    width::Int
    fuzzy_words::Dict{L, Vector{K}}
end

ConceptNet(embeddings::Dict{K,V}, width::Int) where
        {K<:AbstractString, V<:AbstractVector} =
    ConceptNet{Languages.English(), K, V}(embeddings, width, Dict(Languages.English()=>K[]))


# Aliases
const ConceptNetMulti{L} = ConceptNet{L, String, Vector{Float64}}
const ConceptNetMultiCompressed{L} = ConceptNet{L, String, Vector{Int8}}
const ConceptNetEnglish = ConceptNet{Languages.English, String, Vector{Float64}}



# Show methods
show(io::IO, conceptnet::ConceptNetMultiCompressed{L}) where {L} = begin
    nlanguages = length(conceptnet.embeddings)
    print(io, "ConceptNet{$L} (compressed): $nlanguages language(s)",
          ", $(length(conceptnet)) embeddings")
end

show(io::IO, conceptnet::ConceptNetMulti{L}) where {L} = begin
    nlanguages = length(conceptnet.embeddings)
    print(io, "ConceptNet{$L}: $nlanguages language(s)",
          ", $(length(conceptnet)) embeddings")
end

show(io::IO, conceptnet::ConceptNetEnglish) =
    print(io, "ConceptNet{English}: $(length(conceptnet)) embeddings")



# Overloaded `get` method for a ConceptNet language dictionary
# Example: the embedding corresponding to "###_something" is returned for any search query
#          of two words where the first word in made out out 3 letters followed by
#          the word 'something'
function get(embeddings::Dict{K,V}, keyword, default::V, fuzzy_words::Vector{K}) where
        {K<:AbstractString, V<:AbstractVector}
    if haskey(embeddings, keyword)
        # The keyword exists in the dictionary
        return embeddings[keyword]
    else
        # The keyword is not found; try fuzzy matching
        ω = 0.4 # weight assinged to matching a #, 1-w weight assigned to a matching letter
        L = length(keyword)
        matches = (word for word in fuzzy_words
                   if length(word) == L &&
                      occursin(Regex(replace(word,"#"=>".")), keyword))
        if isempty(matches)
            return default
        else
            best_match = ""
            max_score = 0
            for match in matches
                l = length(replace(match,"#"=>"")) # number of letters matched
                score = ω*(L-l)/L + (1-ω)*l/L
                if score > max_score
                    best_match = match
                    max_score = score
                end
            end
            return embeddings[best_match]
        end
    end
end



# Indexing
# Generic indexing, multiple words
# Example: julia> conceptnet[Languages.English(), ["another", "word"])
# TODO(Make type stable!); make new get for keyword vectors
getindex(conceptnet::ConceptNet{L,K,V}, language::L, words::S) where
        {L<:Language, K, V, S<:AbstractVector{<:AbstractString}} = begin
    if !isempty(words)
        hcat((get(conceptnet.embeddings[language],
                  word,
                  zeros(eltype(V), conceptnet.width),
                  conceptnet.fuzzy_words[language])
              for word in words)...
            )::Matrix{eltype(V)}
    else
        Vector{eltype(V)}()
    end
end

# Generic indexing, multiple words
# Example: julia> conceptnet[:en, ["another", "word"]]
getindex(conceptnet::ConceptNet{L,K,V}, language::Symbol, words::S) where
        {L<:Language, K, V, S<:AbstractVector{<:AbstractString}} =
    conceptnet[LANGUAGES[language], words]

# Generic indexing, single word
# Example: julia> conceptnet[Languages.English(), "word"]
getindex(conceptnet::ConceptNet{L,K,V}, language::L, word::S) where
        {L<:Language, K, V, S<:AbstractString} =
    conceptnet[language, [word]]

# Generic indexing, single word
# Example: julia> conceptnet[:en, "word"]
getindex(conceptnet::ConceptNet{L,K,V}, language::Symbol, word::S) where
        {L<:Language, K, V, S<:AbstractString} =
    conceptnet[LANGUAGES[language], [word]]

# Single-language indexing: conceptnet[["another", "word"]], if language==Languages.English()
getindex(conceptnet::ConceptNet{L,K,V}, words::S) where
        {L<:Languages.Language, K, V, S<:AbstractVector{<:AbstractString}} =
    conceptnet[L(), words]

# Single-language indexing: conceptnet["word"], if language==Languages.English()
getindex(conceptnet::ConceptNet{L,K,V}, word::S) where
        {L<:Languages.Language, K, V, S<:AbstractString} =
    conceptnet[L(), [word]]

# Index by language (returns a Dict{word=>embedding})
getindex(conceptnet::ConceptNet, language::L) where {L<:Languages.Language} =
    conceptnet.embeddings[language]

# Index by language (returns a Dict{word=>embedding})
getindex(conceptnet::ConceptNet, language::Symbol) =
    conceptnet.embeddings[LANGUAGES[language]]



# length methods
length(conceptnet::ConceptNet) = begin
    if !isempty(conceptnet.embeddings)
        return mapreduce(x->length(x[2]), +, conceptnet.embeddings)
    else
        return 0
    end
end



# size methods
size(conceptnet::ConceptNet) = (conceptnet.width, length(conceptnet))

size(conceptnet::ConceptNet, inds...) = (conceptnet.width, length(conceptnet))[inds...]



# in
function in(key::S, conceptnet::ConceptNet) where S<:AbstractString
    found = false
    for lang in keys(conceptnet.embeddings)
        if haskey(conceptnet.embeddings[lang], key)
            found = true
            break
        end
    end
    return found
end

function in(lang::L, conceptnet::ConceptNet) where L<:Languages.Language
    return haskey(conceptnet.embeddings, lang)
end



# Keys
keys(conceptnet::ConceptNet) =
    Iterators.flatten(keys(conceptnet.embeddings[lang]) for lang in keys(conceptnet.embeddings))
