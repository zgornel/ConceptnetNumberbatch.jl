struct ConceptNet{L<:Language, K<:AbstractString, V<:AbstractVector}
    embeddings::Dict{L, Dict{K,V}}
    width::Int
end

ConceptNet(embeddings::Dict{K,V}, width::Int) where
        {K<:AbstractString, V<:AbstractVector} =
    ConceptNet{Languages.English(), K, V}(embeddings, width)


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



# Indexing

# Generic indexing, multiple words
# Example: julia> conceptnet[Languages.English(), ["another", "word"])
getindex(conceptnet::ConceptNet{L,K,V}, language::L, words::S) where
        {L<:Language, K, V, S<:AbstractVector{<:AbstractString}} =
    hcat((get(conceptnet.embeddings[language],
              word,
              zeros(eltype(V), conceptnet.width))
          for word in words)...
        )::Matrix{eltype(V)}

# Generic indexing, multiple words
# Example: julia> conceptnet[:en, ["another", "word"]]
getindex(conceptnet::ConceptNet{L,K,V}, language::Symbol, words::S) where
        {L<:Language, K, V, S<:AbstractVector{<:AbstractString}} =
    conceptnet[LANG_MAP[language], words]

# Generic indexing, single word
# Example: julia> conceptnet[Languages.English(), "word"]
getindex(conceptnet::ConceptNet{L,K,V}, language::L, word::S) where
        {L<:Language, K, V, S<:AbstractString} =
    conceptnet[language, [word]]

# Generic indexing, single word
# Example: julia> conceptnet[:en, "word"]
getindex(conceptnet::ConceptNet{L,K,V}, language::Symbol, word::S) where
        {L<:Language, K, V, S<:AbstractString} =
    conceptnet[LANG_MAP[language], [word]]

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
    conceptnet.embeddings[LANG_MAP[language]]



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
        if key in keys(conceptnet.embeddings[lang])
            found = true
            break
        end
    end
    return found
end

function in(lang::L, conceptnet::ConceptNet) where L<:Languages.Language
    return lang in keys(conceptnet.embeddings)
end



# Keys
keys(conceptnet::ConceptNet) =
    Iterators.flatten(keys(conceptnet.embeddings[lang]) for lang in keys(conceptnet.embeddings))
