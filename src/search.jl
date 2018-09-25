#TODO(Corneliu) Implement word_embeddings for other ConceptNet types
#TODO(Corneliu) Implement faster fuzzy matcher (i.e. n-gram based/NearestNeighbors)


function word_embeddings(conceptnet::ConceptNet,
                         phrase::S where S<:AbstractString;
                         language=Languages.English(),
                         keep_size::Bool=true,
                         max_length::Int=1,
                         search_mismatches::Bool=true,
                         distance=Levenshtein())
    dictionary = collect(keys(conceptnet.embeddings[language]))
    tokens = split(phrase)
    sep = "_"
    found = token_search(tokens, dictionary, sep=sep, max_length=max_length)
    not_found = setdiff(1:length(tokens), found...)
    words = Vector{String}()
    # Get found words
    for pos in found
        word = join(tokens[pos], sep, sep)
        push!(words, word)
    end
    # Get best matches for not found words
    for pos in not_found
        if search_mismatches
            matcher = word->evaluate(distance, tokens[pos], word)
            _, match_pos = findmin(map(matcher, dictionary))
            push!(words, dictionary[match_pos])
        else
            keep_size && push!(words, tokens[pos])
        end
    end
    return conceptnet[language, words]
end


# Function that searches subphrases (continuous token combinations)
# from a phrase in a dictionary and returns the positions of matched
# subphrases/words
function token_search(tokens, dictionary; sep::String="_", max_length::Int=3)
    found = Vector{UnitRange{Int}}()
    n = length(tokens)
    i = 1
    j = n
    while i<=n
        token = join(tokens[i:j], sep, sep)
        if token in dictionary && j-i+1 <= max_length
            push!(found, i:j)
            i=j+1
            j=n
            continue
        else
            if i==j
                j=n
                i+=1
            else
                j-=1
            end
        end
    end
    return found
end


#TODO(Corneliu) Improve quality and performance of this model
function build_nn_model(words; ngram_size::Int=2)
    #words = collect(keys(cptnet))
    words = words[isascii.(words)]
    ngrams = get_ngrams(words, ngram_size)
    m = length(ngrams)
    n = length(words)
    ngramdict = Dict(ngrams[i]=>i for i in 1:m)
    encmatrix = zeros(Float32, m, n)
    @inbounds for i in 1:n  # words
        _wgrams = get_ngrams(words[i], ngram_size)
        for _wg in _wgrams
            encmatrix[ngramdict[_wg], i] += 1.0
        end
    end
    return (words, ngramdict, KDTree(encmatrix, leafsize=1000), ngram_size)
end


function get_similar_words(target, words, ngramdict, model, ngram_size)
    _keys = keys(ngramdict)
    _wgrams = [wg for wg in get_ngrams(target, ngram_size) if wg in _keys]
    wordvec = zeros(Float32, length(ngramdict))
    for _wg in _wgrams
        wordvec[ngramdict[_wg]] += 1.0
    end
    return words[knn(model, wordvec, 3, true)[1]]
end


function get_ngrams(word::S, n::Int=2) where S<:AbstractString
    l = length(word)
    if l<=n
        return [word]
    else
        sz = n*div(l,n)-(n-1)
        ngrams = Vector{S}(undef, sz)
        for i in 1:sz
            ngrams[i] = word[i:i+n-1]
        end
        #push!(ngrams, word[n*div(l,n)-n+2:end])
    end
    return ngrams
end

function get_ngrams(words::Vector{S}, n::Int=2) where S<:AbstractString
    ngrams = S[]
    for word in words
        l = length(word)
        if l<=n
            push!(ngrams, word)
        else
            for i in 1:n*div(l,n)-(n-1)
                push!(ngrams, word[i:i+n-1])
            end
            #push!(ngrams, word[n*div(l,n)-n+2:end])
        end
    end
    return unique(ngrams)
end
