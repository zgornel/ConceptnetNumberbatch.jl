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
        download(url, localfile)
        if isfile(localfile) return localfile end
    else
        @warn "$localfile already exists. Will not download."
        return localfile 
    end
end


# Function that loads the embeddings given a valid ConceptNetNumberbatch file
function load_embeddings(file::AbstractString;
                         max_vocab_size::Union{Nothing,Int}=nothing,
                         keep_words=String[])
    if any(endswith.(file, [".gz", ".gzip"]))
        word_embeddings = _load_gz_embeddings(file,
                                              GzipDecompressor(),
                                              max_vocab_size,
                                              keep_words)
    elseif any(endswith.(file, [".h5", ".hdf5"]))
        word_embeddings = _load_hdf5_embeddings(file,
                                                max_vocab_size,
                                                keep_words)
    else
        word_embeddings = _load_gz_embeddings(file,
                                              Noop(),
                                              max_vocab_size,
                                              keep_words)
    end
    return word_embeddings
end


# Loads the ConceptNetNumberbatch from a .gz or uncompressed file
function _load_gz_embeddings(file::S1,
                             decompressor::TranscodingStreams.Codec,
                             max_vocab_size::Union{Nothing,Int},
                             keep_words::Vector{S2}) where
        {S1<:AbstractString, S2<:AbstractString}
    local word_embeddings, _length::Int, _width::Int
    word_embeddings = Dict{String, Vector{Float64}}()
    open(file, "r") do fid
        cfid = TranscodingStream(decompressor, fid)
        _length, _width = parse.(Int64, split(readline(cfid)))
        vocab_size = _get_vocab_size(_length,
                                     max_vocab_size,
                                     keep_words)
        _progress = Progress(vocab_size, dt=1,
                             desc="Loading embeddings...",
                             barlen=50, color=:white,
                             barglyphs=BarGlyphs("[=> ]"))
        
        no_custom_words = length(keep_words)==0
        lines = readlines(cfid)
        cnt = 0
        for (idx, line) in enumerate(lines)
            word, embedding = _parseline(line)
            if word in keep_words || no_custom_words
                push!(word_embeddings, word=>embedding)
                update!(_progress, idx)
                cnt+=1
                if cnt > vocab_size-1
                    break
                end
            end
        end
        close(cfid)
    end
    return word_embeddings, _length, _width
end


# Loads the ConceptNetNumberbatch from a HDF5 file
function _load_hdf5_embeddings(file::S1,
                               max_vocab_size::Union{Nothing,Int},
                               keep_words::Vector{S2}) where
        {S1<:AbstractString, S2<:AbstractString}
    payload = h5open(read, file)["mat"]
    words = payload["axis1"]
    embeddings = payload["block0_values"]
    word_embeddings=Dict{String, Vector{Int8}}()
    vocab_size = _get_vocab_size(length(words),
                                 max_vocab_size,
                                 keep_words)
    _progress = Progress(vocab_size, dt=1,
                         desc="Loading embeddings...",
                         barlen=50, color=:white,
                         barglyphs=BarGlyphs("[=> ]"))
    no_custom_words = length(keep_words)==0
    cnt = 0
    for (idx, word) in enumerate(words)
        if word in keep_words || no_custom_words
            push!(word_embeddings, word=>embeddings[:,idx])
            update!(_progress, idx)
            cnt+=1
            if cnt > vocab_size-1
                break
            end
        end
    end
    _length::Int = length(words)
    _width::Int = size(embeddings,1)
    return word_embeddings, _length, _width
end


# Function that calculates how many embeddings to retreive
function _get_vocab_size(real_vocab_size,
                         max_vocab_size=nothing,
                         keep_words=String[])

    # The real dataset cannot contain negative samples
    real_vocab_size = max(0, real_vocab_size)
    # If no maximum number of words is specified, 
    # maximum size is the actual size
    if max_vocab_size == nothing
        max_vocab_size = real_vocab_size
    end
    # The maximum has to be at most the real size
    max_vocab_size = min(real_vocab_size, max_vocab_size)
    # The maximum cannot be more than the number of custom words
    # if there are custom words
    n_custom_words = length(keep_words)
    if n_custom_words > 0
        max_vocab_size = min(max_vocab_size, n_custom_words)
    end
    return max_vocab_size
end


function _parseline(buf)
    bufvec = split(buf, " ")
    keyword = string(popfirst!(bufvec))
    embedding = parse.(Float64, bufvec)
    #embedding = map(x->parse(Float64,x), bufvec)
    return (keyword => embedding)
end
