struct ConceptNet{N, W<:AbstractVector, E<:AbstractMatrix}
    words::W
    embeddings::E
end

ConceptNet(name::Symbol, words::W, embeddings::E) where
    {W<:AbstractVector, E<:AbstractMatrix} = ConceptNet{name, W, E}(words, embeddings)

ConceptNet(words::W, embeddings::E) where
    {W<:AbstractVector, E<:AbstractMatrix} = ConceptNet(:unknown, words, embeddings)


# Show methods
show(io::IO, conceptnet::ConceptNet{:multi_c, W, E}) where {W, E} = begin
    print(io, "ConceptNet (multilanguage, compressed) with $(length(conceptnet.words)) embeddings")
end

show(io::IO, conceptnet::ConceptNet{:multi, W, E}) where {W, E} = begin
    print(io, "ConceptNet (multilanguage) with $(length(conceptnet.words)) embeddings")
end

show(io::IO, conceptnet::ConceptNet{:en, W, E}) where {W, E} = begin
    print(io, "ConceptNet (English) with $(length(conceptnet.words)) embeddings")
end

show(io::IO, conceptnet::ConceptNet{N, W, E}) where {N, W, E} = begin
    print(io, "ConceptNet (Unknown language) with $(length(conceptnet.words)) embeddings")
end


# getindex methods 
getindex(::ConceptNet{:multi_c, W, E}, word::S) where {W, E, S<:AbstractString} = begin
    @info "Getindex :multi (compressed)"
end

getindex(::ConceptNet{:multi, W, E}, word::S) where {W, E, S<:AbstractString} = begin
    @info "Getindex :multi"
end

getindex(::ConceptNet{N, W, E}, word::S) where {N, W, E, S<:AbstractString} = begin
    @info "Getindex :en"
end


# length methods
length(conceptnet::ConceptNet) = length(conceptnet.words)


# size methods
size(conceptnet::ConceptNet, inds...) = size(conceptnet.embeddings, inds...)

