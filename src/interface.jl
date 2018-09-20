struct ConceptNet{N, W<:AbstractVector, E<:AbstractMatrix}
    words::W
    embeddings::E
end

ConceptNet(name::Symbol, words::W, embeddings::E) where
    {W<:AbstractVector, E<:AbstractMatrix} = ConceptNet{name, W, E}(words, embeddings)

ConceptNet(words::W, embeddings::E) where
    {W<:AbstractVector, E<:AbstractMatrix} = ConceptNet(:unknown, words, embeddings)

const ConceptNetMulti = ConceptNet{:multi, Vector{String}, Matrix{Float64}}
const ConceptNetMultiCompressed = ConceptNet{:multi_c, Vector{String}, Matrix{Int8}}
const ConceptNetEnglish = ConceptNet{:en, Vector{String}, Matrix{Float64}}
const ConceptNetUnknown = ConceptNet{:ubknown, Vector{String}, Matrix{Float64}}

# Show methods
show(io::IO, conceptnet::ConceptNetMultiCompressed) = begin
    print(io, "ConceptNet (multilanguage, compressed) with $(length(conceptnet.words)) embeddings")
end

show(io::IO, conceptnet::ConceptNetMulti) = begin
    print(io, "ConceptNet (multilanguage) with $(length(conceptnet.words)) embeddings")
end

show(io::IO, conceptnet::ConceptNetEnglish) = begin
    print(io, "ConceptNet (English) with $(length(conceptnet.words)) embeddings")
end

show(io::IO, conceptnet::ConceptNetUnknown) = begin
    print(io, "ConceptNet (Unknown language) with $(length(conceptnet.words)) embeddings")
end


# getindex methods 
function getindex(conceptnet::ConceptNetMultiCompressed, words::S) where
        {S<:AbstractVector{<:AbstractString}}
    @warn "Results may be wrong!"
    return conceptnet.embeddings[:, findall((in)(words), conceptnet.words)]
end

function getindex(conceptnet::ConceptNetMulti, words::S) where
        {S<:AbstractVector{<:AbstractString}}
    @warn "Results may be wrong!"
    return conceptnet.embeddings[:, findall((in)(words), conceptnet.words)]
end

function getindex(conceptnet::ConceptNetEnglish, words::S) where
        {S<:AbstractVector{<:AbstractString}}
    lenemb = size(conceptnet.embeddings, 1)
    embeddings = zeros(eltype(conceptnet.embeddings), lenemb, length(words))
    indices = indexin(conceptnet.words, words)
    for idx in indices
        if idx != nothing
            embeddings[:,idx] = conceptnet.embeddings[:, idx]
        end
    end
    return embeddings
end

getindex(::ConceptNetUnknown{N, W, E}, words::S) where
         {N, W, E, S<:Vector{<:AbstractString}} =
     @error "Indexing not supported for an :unknown language ConceptNet"

getindex(conceptnet::ConceptNet, word::S where S<:AbstractString)= conceptnet[[word]]


# length methods
length(conceptnet::ConceptNet) = length(conceptnet.words)


# size methods
size(conceptnet::ConceptNet, inds...) = size(conceptnet.embeddings, inds...)
