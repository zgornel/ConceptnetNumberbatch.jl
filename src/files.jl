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
function load_embeddings(filepath::AbstractString;
                         max_vocab_size::Union{Nothing,Int}=nothing,
                         keep_words=String[],
                         language=:unknown)
    if any(endswith.(filepath, [".gz", ".gzip"]))
        conceptnet = _load_gz_embeddings(filepath,
                                         GzipDecompressor(),
                                         max_vocab_size,
                                         keep_words,
                                         language=language)
    elseif any(endswith.(filepath, [".h5", ".hdf5"]))
        conceptnet = _load_hdf5_embeddings(filepath,
                                           max_vocab_size,
                                           keep_words)
    else
        conceptnet = _load_gz_embeddings(filepath,
                                         Noop(),
                                         max_vocab_size,
                                         keep_words,
                                         language=language)
    end
    return conceptnet
end


# Loads the ConceptNetNumberbatch from a .gz or uncompressed file
function _load_gz_embeddings(filepath::S1,
                             decompressor::TranscodingStreams.Codec,
                             max_vocab_size::Union{Nothing,Int},
                             keep_words::Vector{S2};
                             language::Symbol=:unknown) where
        {S1<:AbstractString, S2<:AbstractString}
    local embeddings, indices, _length::Int, _width::Int
    type_word = String
    type_vector = Vector{Float64}
    open(filepath, "r") do fid
        cfid = TranscodingStream(decompressor, fid)
        _length, _width = parse.(Int64, split(readline(cfid)))
        embeddings = Dict{type_word, type_vector}()
        vocab_size = _get_vocab_size(_length,
                                     max_vocab_size,
                                     keep_words)
        _progress = Progress(vocab_size, dt=1,
                             desc="Loading embeddings...",
                             barlen=50, color=:white,
                             barglyphs=BarGlyphs("[=> ]"))
        no_custom_words = length(keep_words)==0
        cnt = 0
        indices = Int[]
        for (idx, line) in enumerate(eachline(cfid))
            word, _ = _parseline(line, word_only=true)
            if word in keep_words || no_custom_words
                _, embedding = _parseline(line)
                push!(embeddings, word=>embedding)
                update!(_progress, idx)
                cnt+=1
                if cnt > vocab_size-1
                    break
                end
            end
        end
        close(cfid)
    end
    return ConceptNet{language, type_word, type_vector}(embeddings, _width),
           _length, _width
end


# Loads the ConceptNetNumberbatch from a HDF5 file
function _load_hdf5_embeddings(filepath::S1,
                               max_vocab_size::Union{Nothing,Int},
                               keep_words::Vector{S2}) where
        {S1<:AbstractString, S2<:AbstractString}
    type_word = String
    type_matrix = Vector{Int8}
    payload = h5open(read, filepath)["mat"]
    words = payload["axis1"]
    embeddings = payload["block0_values"]
    vocab_size = _get_vocab_size(length(words),
                                 max_vocab_size,
                                 keep_words)
    _progress = Progress(vocab_size, dt=1,
                         desc="Loading embeddings...",
                         barlen=50, color=:white,
                         barglyphs=BarGlyphs("[=> ]"))
    no_custom_words = length(keep_words)==0
    cnt = 0
    indices = Int[]
    for (idx, word) in enumerate(words)
        if word in keep_words || no_custom_words
            push!(indices, idx)
            update!(_progress, idx)
            cnt+=1
            if cnt > vocab_size-1
                break
            end
        end
    end
    _length::Int = length(words)
    _width::Int = size(embeddings,1)
    return ConceptNet{:multi_c, type_word, type_matrix}(
                Dict(words[index]=>embeddings[:, index]
                     for index in indices), _width),
           _length, _width
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


function _parseline(buf; word_only=false)
    bufvec = split(buf, " ")
    word = string(popfirst!(bufvec))
    if word_only
        return word, Float64[]
    else
        embedding = parse.(Float64, bufvec)
        return word, embedding
    end
end
