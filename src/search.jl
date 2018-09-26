"""
Retrieves the embedding matrix for a given `phrase`.
"""
function phrase_embeddings(conceptnet::ConceptNet,
                           phrase::S where S<:AbstractString;
                           language=Languages.English(),
                           keep_size::Bool=true,
                           max_compound_word_length::Int=1,
                           search_mismatches::Symbol=:no,
                           show_words::Bool=true,
                           distance=Levenshtein())
    # Initializations
    sep = "_"
    tokens = split(phrase)
    dictionary = collect(keys(conceptnet.embeddings[language]))
    # Generate positions of words that can be used for indexing (found)
    # and that can be searched (not_found)
    found = token_search(tokens,
                         dictionary,
                         sep=sep,
                         max_length=max_compound_word_length)
    not_found = setdiff(1:length(tokens), found...)
    # Get found words
    words = Vector{String}()
    for pos in found
        word = make_word_from_tokens(tokens, pos, sep, sep)
        push!(words, word)
    end
    # Get best matches for not found words
    for pos in not_found
        word = make_word_from_tokens(tokens, pos, sep, sep)
        if search_mismatches == :no
            # Insert not found words if exact matches are to be
            # returned only if a matrix of width equal to the
            # number of terms is to be returned
            keep_size && push!(words, word)
        elseif search_mismatches == :brute_force
            matcher = dict_word->evaluate(distance, word, dict_word)
            _, match_pos = findmin(map(matcher, dictionary))
            push!(words, dictionary[match_pos])
        else
            @warn "The only supported approximate string matching" *
                  " method is :brute_force. Use :no for skipping the" *
                  " search; will not search."
            push!(words, word)
        end
    end
    # Return
    show_words && @show words
    return conceptnet[language, words]
end



# Small function that builds a compound word
function make_word_from_tokens(tokens, pos, sep, sep_end)
    if length(pos) == 1
        return join(tokens[pos])
    else
        return join(tokens[pos], sep, sep_end)
    end
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
