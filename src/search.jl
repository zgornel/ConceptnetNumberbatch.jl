#TODO(Corneliu) Implement word_embeddings for other ConceptNet types
#TODO(Corneliu) Implement faster fuzzy matcher (i.e. n-gram based/NearestNeighbors)



function word_embeddings(conceptnet::ConceptNetEnglish,
                         phrase::S where S<:AbstractString;
                         search_mismatches::Bool=true,
                         distance=Jaro())
    dictionary = collect(keys(conceptnet))
    tokens = split(phrase)
    sep = "_"
    found = token_search(tokens, dictionary, sep=sep, max_length=2)
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
            push!(words, tokens[pos])
        end
    end
    @show words
    return conceptnet[words]
end


# Function that searches subphrases (continuous token combinations)
# from a phrase in a dictionary and returns the positions of matched 
# subphrases/words
function token_search(tokens, dictionary; sep::String="_", max_length::Int=3)
    found = Vector{UnitRange{Int}}()
    n = length(tokens)
    i = 1
    j = n
    while length(tokens)!=0 && i<=j
        if i > n || j <=0 
            break 
        elseif j-i+1 > max_length 
            j -=1
        else
            tok = join(tokens[i:j], sep)
            if tok in dictionary
                push!(found, i:j)
                i = j+1
                j = n
                continue
            end
            if i == j
                i += 1
                j = n
            else
                j -= 1
            end
        end
    end
    return found
end

