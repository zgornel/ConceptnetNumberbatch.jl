
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
    @show words
    return conceptnet[language, words]
end


# Function that searches subphrases (continuous token combinations)
# from a phrase in a dictionary and returns the positions of matched
# subphrases/words
# Example:
#   - for a vector: String[a, simpler, world, would, be, more, complicated],
#     max_length=7 and sep='_', it would generate:
#       String[a_simple_world_..._complicated,
#              a_simple_world_..._more,
#              ...
#              a_simple,
#              a,
#              simple_world_..._complicated,
#              simple_world_..._more,
#              ...
#              simple_world,
#              simple,
#              ...
#              ...
#              more_complicated,
#              complicated]
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
