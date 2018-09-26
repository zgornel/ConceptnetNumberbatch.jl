struct ConceptNet{L<:Language, K<:AbstractString, V<:AbstractVector}
    embeddings::Dict{L, Dict{K,V}}
    width::Int
end

ConceptNet(embeddings::Dict{K,V}, width::Int) where
        {K<:AbstractString, V<:AbstractVector} =
    ConceptNet{Languages.English(), K, V}(embeddings, width)


# Aliases
const ConceptNetMulti = ConceptNet{Language, String, Vector{Float64}}

const ConceptNetMultiCompressed = ConceptNet{Language, String, Vector{Int8}}

const ConceptNetEnglish = ConceptNet{Languages.English, String, Vector{Float64}}



# Show methods
show(io::IO, conceptnet::ConceptNetMultiCompressed) = begin
    nlanguages = length(conceptnet.embeddings)
    if !isempty(conceptnet.embeddings)
        nembs = mapreduce(x->length(x[2]), +, conceptnet.embeddings)
    else
        nembs = 0
    end
    print(io, "ConceptNet (compressed): $nlanguages languages",
          ", $(length(conceptnet)) embeddings")
end

show(io::IO, conceptnet::ConceptNetMulti) = begin
    nlanguages = length(conceptnet.embeddings)
    print(io, "ConceptNet (multilanguage): $nlanguages languages",
          ", $(length(conceptnet)) embeddings")
end

show(io::IO, conceptnet::ConceptNetEnglish) =
    print(io, "ConceptNet (English): $(length(conceptnet)) embeddings")



# Get index
getindex(conceptnet::ConceptNet{L,K,V}, language::L, words::S) where
        {L<:Language, K, V, S<:AbstractVector{<:AbstractString}}=
    hcat((get(conceptnet.embeddings[language],
              word,
              zeros(eltype(V), conceptnet.width))
          for word in words)...
        )::Matrix{eltype(V)}

getindex(conceptnet::ConceptNet{L,K,V}, language::Symbol, words::S) where
        {L<:Language, K, V, S<:AbstractVector{<:AbstractString}} =
    conceptnet[LANG_MAP[language], words]

getindex(conceptnet::ConceptNet, language::L, word::S) where
        {L<:Languages.Language, S<:AbstractString} =
    conceptnet[language, [word]]

getindex(conceptnet::ConceptNet, language::L) where {L<:Languages.Language} =
    conceptnet.embeddings[language]

getindex(conceptnet::ConceptNet, language::Symbol) =
    conceptnet.embeddings[LANG_MAP[language]]

getindex(conceptnet::ConceptNet, language::Symbol, word::S) where
        {S<:AbstractString} = conceptnet[LANG_MAP[language], word]

getindex(conceptnet::ConceptNetEnglish, word::S) where {S<:AbstractString} =
    get(conceptnet.embeddings[Languages.English()],
        word,
        zeros(conceptnet.width))

getindex(conceptnet::ConceptNetEnglish, words::S) where
        {S<:Vector{<:AbstractString}} =
    hcat((get(conceptnet.embeddings[Languages.English()], word,
              zeros(conceptnet.width))
          for word in words)...)



# length methods
length(conceptnet::ConceptNet) =
    ifelse(!isempty(conceptnet.embeddings),
           mapreduce(x->length(x[2]), +, conceptnet.embeddings),
           0)



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
