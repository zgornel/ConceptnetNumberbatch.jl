# TODO(Corneliu): Functionality to implement for v0.0.1
# - converters: (.txt, .gz, .h5) ->
# - search words (similarity, language filters)


function download_embeddings(;url=CONCEPTNET_EN_LINK,
                             localfile=abspath("./_conceptnet_/" *
                                               split(url,"/")[end]))
    _dir = join(split(localfile, "/")[1:end-1], "/")
    !isempty(_dir) && !isdir(_dir) && mkpath(_dir)
    @info "Download ConceptNetNumberbatch to $localfile..."
    if !isfile(localfile)
        dowload(url, localfile)
        if isfile(localfile) return localfile end
    else
        @warn "$localfile already exists. Will not download."
        return localfile 
    end
end


# Function that loads the embeddings given a valid ConceptNetNumberbatch file
function load_embeddings(file::AbstractString;
                         max_vocab_size::Union{Nothing,Int}=nothing)
    if any(endswith.(file, [".gz", ".gzip"]))
        word_embeddings = _load_gz_embeddings(file, GzipDecompressor(),
                                              max_vocab_size=max_vocab_size)
    elseif any(endswith.(file, [".h5", ".hdf5"]))
        word_embeddings = _load_hdf5_embeddings(file, max_vocab_size=max_vocab_size)
    else
        word_embeddings = _load_gz_embeddings(file, Noop(),
                                                max_vocab_size=max_vocab_size)
    end
    return word_embeddings
end


# Loads the ConceptNetNumberbatch from a .gz or uncompressed file
function _load_gz_embeddings(file::AbstractString,
                             decompressor::TranscodingStreams.Codec;
                             max_vocab_size::Union{Nothing,Int}=nothing)
    fid = open(file, "r")
    cfid = TranscodingStream(decompressor, fid)
    _length, _width = map(x->parse(Int,x), split(readline(cfid)," ")) # ignore this (size)
    word_embeddings = Dict{String, Vector{Float64}}()
    max_vocab_size = _get_vocab_size(_length, max_vocab_size)
    _progress = Progress(max_vocab_size, dt=1, desc="Loading embeddings...",
                         barlen=50, color=:white,
                         barglyphs=BarGlyphs("[=> ]"))
    data = readlines(cfid)
    lines = randcycle(_length)[1:max_vocab_size]
    for (idx, _line) in enumerate(lines)
        buf = data[_line]
        push!(word_embeddings, _parseline(buf))
        update!(_progress, idx)
    end
    close(fid)
    close(cfid)
    return word_embeddings, _length, _width
end


function _parseline(buf)
    bufvec = split(buf, " ")
    keyword = string(popfirst!(bufvec))
    embedding = parse.(Float64, bufvec)
    #embedding = map(x->parse(Float64,x), bufvec)
    return (keyword => embedding)
end


# Loads the ConceptNetNumberbatch from a HDF5 file
function _load_hdf5_embeddings(file::AbstractString;
                               max_vocab_size::Union{Nothing,Int}=nothing)
    payload = h5open(read, file)["mat"]
    words = payload["axis1"]
    vectors = payload["block0_values"]
    max_vocab_size = _get_vocab_size(length(words), max_vocab_size)
    word_embeddings = Dict(words[idx]=>vectors[:,idx]
                           for idx in randcycle(length(words))[1:max_vocab_size])
    return word_embeddings, length(words), size(vectors,1)
end


# Function that calculates how many embeddings to retreive
function _get_vocab_size(real_vocab_size, max_vocab_size=nothing)

    real_vocab_size = max(0, real_vocab_size)
    if max_vocab_size == nothing
        max_vocab_size = real_vocab_size
    end
    max_vocab_size = min(real_vocab_size, max_vocab_size)
    return max_vocab_size
end


