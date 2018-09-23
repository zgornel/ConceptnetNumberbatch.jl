struct ConceptNet{N, K<:AbstractString, V<:AbstractVector}
    embeddings::Dict{K,V}
    width::Int
end

ConceptNet(name::Symbol, embeddings::Dict{K,V}, width::Int) where
    {K<:AbstractString, V<:AbstractVector} = ConceptNet{name, K, V}(embeddings, width)

ConceptNet(embeddings::Dict{K,V}) where
    {K<:AbstractString, V<:AbstractVector} = ConceptNet(:unknown, embeddings, width)

const ConceptNetMulti = ConceptNet{:multi, String, Vector{Float64}}
const ConceptNetMultiCompressed = ConceptNet{:multi_c, String, Vector{Int8}}
const ConceptNetEnglish = ConceptNet{:en, String, Vector{Float64}}
const ConceptNetUnknown = ConceptNet{:unknown, String, Vector{Float64}}


# Show methods
show(io::IO, conceptnet::ConceptNetMultiCompressed) = begin
    print(io, "ConceptNet (multilanguage, compressed) with ",
          "$(length(conceptnet.embeddings)) embeddings")
end

show(io::IO, conceptnet::ConceptNetMulti) = begin
    print(io, "ConceptNet (multilanguage) with ",
          "$(length(conceptnet.embeddings)) embeddings")
end

show(io::IO, conceptnet::ConceptNetEnglish) = begin
    print(io, "ConceptNet (English) with ",
          "$(length(conceptnet.embeddings)) embeddings")
end

show(io::IO, conceptnet::ConceptNetUnknown) = begin
    print(io, "ConceptNet (Unknown language) with ",
          "$(length(conceptnet.embeddings)) embeddings")
end

# TODO(Corneliu):
#   - specific implementation for multilanguage files (w. language detection)
#   - add OOV - pre-processing functions
function getindex(conceptnet::ConceptNet{N,K,V}, words::S) where
        {N, K, V, S<:AbstractVector{<:AbstractString}}
    return hcat((get(conceptnet.embeddings, word, zeros(eltype(V), conceptnet.width))
                 for word in words)...)::Matrix{eltype(V)}
end

getindex(::ConceptNetUnknown, words::S) where {S<:Vector{<:AbstractString}} = begin
    throw(ArgumentError("Indexing not supported for an :unknown language ConceptNet"))
end


getindex(conceptnet::ConceptNet, word::S where S<:AbstractString)= conceptnet[[word]]


# length methods
length(conceptnet::ConceptNet) = length(conceptnet.embeddings)


# size methods
size(conceptnet::ConceptNet) = (conceptnet.width, length(conceptnet.embeddings))
size(conceptnet::ConceptNet, inds...) = (conceptnet.width, length(conceptnet.embeddings))[inds...]

# Iterators over keys, embeddings
keys(conceptnet::ConceptNet) = keys(conceptnet.embeddings)

values(conceptnet::ConceptNet) = values(conceptnet.embeddings)
