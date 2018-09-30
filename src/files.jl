"""
Downloads embeddings given a `url` and saves them to a file
pointed to by `localfile`.
"""
function download_embeddings(;url=CONCEPTNET_EN_LINK,
                             localfile=abspath("./_conceptnet_/" *
                                               split(url,"/")[end]))
    directory = join(split(localfile, "/")[1:end-1], "/")
    !isempty(directory) && !isdir(directory) && mkpath(directory)
    @info "Download ConceptNetNumberbatch to $localfile..."
    if !isfile(localfile)
        download(url, localfile)
        if isfile(localfile) return localfile end
    else
        @warn "$localfile already exists. Will not download."
        return localfile
    end
end



"""
Function that loads the embeddings given a valid ConceptNetNumberbatch `filepath`,
lading at most `max_vocab_size` embeddings if no specific `keep_words` are
specified, filtering on `languages`.
"""
function load_embeddings(filepath::AbstractString;
                         max_vocab_size::Union{Nothing,Int}=nothing,
                         keep_words=String[],
                         languages::Union{Nothing,
                                          Languages.Language,
                                          Vector{<:Languages.Language}
                                         }=nothing)
    if languages == nothing
        languages = unique(collect(values(LANG_MAP)))
    end

    if any(endswith.(filepath, [".gz", ".gzip"]))
        conceptnet = _load_gz_embeddings(filepath,
                                         GzipDecompressor(),
                                         max_vocab_size,
                                         keep_words,
                                         languages=languages)
    elseif any(endswith.(filepath, [".h5", ".hdf5"]))
        conceptnet = _load_hdf5_embeddings(filepath,
                                           max_vocab_size,
                                           keep_words,
                                           languages=languages)
    else
        conceptnet = _load_gz_embeddings(filepath,
                                         Noop(),
                                         max_vocab_size,
                                         keep_words,
                                         languages=languages)
    end
    return conceptnet
end



# Loads the ConceptNetNumberbatch from a .gz or uncompressed file
function _load_gz_embeddings(filepath::S1,
                             decompressor::TranscodingStreams.Codec,
                             max_vocab_size::Union{Nothing,Int},
                             keep_words::Vector{S2};
                             languages::Union{Nothing,
                                              Languages.Language,
                                              Vector{<:Languages.Language}
                                             }=nothing) where
        {S1<:AbstractString, S2<:AbstractString}
    local lang_embs, _length::Int, _width::Int, type_lang
    type_word = String
    type_vector = Vector{Float64}
    open(filepath, "r") do fid
        cfid = TranscodingStream(decompressor, fid)
        _length, _width = parse.(Int64, split(readline(cfid)))
        vocab_size = _get_vocab_size(_length,
                                     max_vocab_size,
                                     keep_words)
        lang_embs, languages, type_lang, english_only =
            process_language_argument(languages, type_word, type_vector)
        no_custom_words = length(keep_words)==0
        lang = :en
        cnt = 0
        for (idx, line) in enumerate(eachline(cfid))
            word, _ = _parseline(line, word_only=true)
            if !english_only
                _, _, _lang, word = split(word,"/")
                lang = Symbol(_lang)
            end
            if word in keep_words || no_custom_words
                if lang in keys(LANG_MAP) && LANG_MAP[lang] in languages  # use only languages mapped in LANG_MAP
                    _llang = LANG_MAP[lang]
                    if !(_llang in keys(lang_embs))
                        push!(lang_embs, _llang=>Dict{type_word, type_vector}())
                    end
                    _, embedding = _parseline(line, word_only=false)
                    push!(lang_embs[_llang], word=>embedding)
                    cnt+=1
                    if cnt > vocab_size-1
                        break
                    end
                end
            end
        end
        close(cfid)
    end
    return ConceptNet{type_lang, type_word, type_vector}(lang_embs, _width), _length, _width
end



# Loads the ConceptNetNumberbatch from a HDF5 file
function _load_hdf5_embeddings(filepath::S1,
                               max_vocab_size::Union{Nothing,Int},
                               keep_words::Vector{S2};
                               languages::Union{Nothing,
                                                Languages.Language,
                                                Vector{<:Languages.Language}
                                               }=nothing) where
        {S1<:AbstractString, S2<:AbstractString}
    type_word = String
    type_vector = Vector{Int8}
    payload = h5open(read, filepath)["mat"]
    words = map(payload["axis1"]) do val
        _, _, lang, word = split(val, "/")
        return Symbol(lang), word
    end
    embeddings = payload["block0_values"]
    vocab_size = _get_vocab_size(length(words),
                                 max_vocab_size,
                                 keep_words)
    lang_embs, languages, type_lang, _ =
        process_language_argument(languages, type_word, type_vector)
    no_custom_words = length(keep_words)==0
    cnt = 0
    for (idx, (lang, word)) in enumerate(words)
        if word in keep_words || no_custom_words
            if lang in keys(LANG_MAP) && LANG_MAP[lang] in languages  # use only languages mapped in LANG_MAP
                _llang = LANG_MAP[lang]
                if !(_llang in keys(lang_embs))
                    push!(lang_embs, _llang=>Dict{type_word, type_vector}())
                end
                push!(lang_embs[_llang], word=>embeddings[:,idx])
                cnt+=1
                if cnt > vocab_size-1
                    break
                end
            end
        end
    end
    _length::Int = length(words)
    _width::Int = size(embeddings,1)
    return ConceptNet{type_lang, type_word, type_vector}(lang_embs, _width), _length, _width
end



# Function that returns some needed structures based on the languages provided
# Returns:
#   - a dictionary to store the embeddings
#   - a vector of Languages.Language (used to check whether to load embedding or not
#     while parsing)
#   - the type of the language
#   - a flag specifying whether only English is used or not
function process_language_argument(languages::Nothing,
                                   type_word::T1,
                                   type_vector::T2) where {T1, T2}
    return Dict{Languages.Language, Dict{type_word, type_vector}}(),
           collect(language for language in LANG_MAP),
           Languages.Language, false
end

function process_language_argument(languages::Languages.English,
                                   type_word::T1,
                                   type_vector::T2) where {T1, T2}
    return Dict{Languages.English, Dict{type_word, type_vector}}(), [languages],
           Languages.English, true
end

function process_language_argument(languages::L,
                                   type_word::T1,
                                   type_vector::T2) where {L<:Languages.Language, T1, T2}
    return Dict{L, Dict{type_word, type_vector}}(), [languages], L, false
end

function process_language_argument(languages::Vector{L},
                                   type_word::T1,
                                   type_vector::T2) where {L<:Languages.Language, T1, T2}
    if length(languages) == 1
        return process_language_argument(languages[1], type_word, type_vector)
    else
        return Dict{L, Dict{type_word, type_vector}}(), languages, L, false
    end
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



# Parse a line
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
