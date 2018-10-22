"""
Fast tokenization function.
"""
function custom_tokenize(doc::AbstractString, splitter::Regex=DEFAULT_SPLITTER)
    # First, split
    tokens = strip.(split(doc, splitter))
    # Filter out empty strings
    filter!(!isempty, tokens)
end



"""
Retrieves the embedding matrix for a given `document`.
"""
function embed_document(conceptnet::ConceptNet,
                        document::AbstractString;
                        language=Languages.English(),
                        keep_size::Bool=true,
                        max_compound_word_length::Int=1,
                        search_mismatches::Symbol=:no,
                        show_words::Bool=true,
                        distance=Levenshtein())
    # Split document into tokens and embed
    return embed_document(conceptnet,
                          custom_tokenize(document),
                          language=language,
                          keep_size=keep_size,
                          max_compound_word_length=max_compound_word_length,
                          search_mismatches=search_mismatches,
                          show_words=show_words,
                          distance=distance)
end

function embed_document(conceptnet::ConceptNet,
                        document_tokens::Vector{S};
                        language=Languages.English(),
                        keep_size::Bool=true,
                        max_compound_word_length::Int=1,
                        search_mismatches::Symbol=:no,
                        show_words::Bool=true,
                        distance=Levenshtein()) where S<:AbstractString
    # Initializations
    sep = "_"
    embeddings = conceptnet.embeddings[language]
    # Generate positions of words that can be used for indexing (found)
    # and that can be searched (not_found)
    found = token_search(document_tokens,
                         embeddings,
                         sep=sep,
                         max_length=max_compound_word_length)
    # Get found words
    words = Vector{String}()
    for pos in found
        word = make_word_from_tokens(document_tokens, pos, sep, sep)
        push!(words, word)
    end
    # Get best matches for not found words
    words_not_found = setdiff(document_tokens, words)
    if keep_size && !isempty(words_not_found)  # keep_size has precendence
        for word in words_not_found
            if search_mismatches == :no
                # Insert not found words if exact matches are to be
                # returned only if a matrix of width equal to the
                # number of terms is to be returned
                push!(words, word)
            elseif search_mismatches == :brute_force
                match_word = ""
                distmin = Inf
                for dict_word in keys(embeddings)
                    dist = evaluate(distance, word, dict_word)
                    if dist < distmin
                        distmin = dist
                        match_word = dict_word
                    end
                end
                push!(words, match_word)
            else
                @warn "The only supported approximate string matching" *
                      " method is :brute_force. Use :no for skipping the" *
                      " search; will not search."
                push!(words, word)
            end
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
# from a document in a the embedded words and returns the positions of matched
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
# TODO(Corneliu): Implement wildcard matching as well
function token_search(tokens, embeddings; sep::String="_", max_length::Int=3)
    found = Vector{UnitRange{Int}}()
    n = length(tokens)
    i = 1
    j = n
    while i <= n
        token = join(tokens[i:j], sep, sep)
        if haskey(embeddings, token) && j-i+1 <= max_length
            push!(found, i:j)
            i = j + 1
            j = n
            continue
        else
            if i == j
                j = n
                i+= 1
            else
                j-= 1
            end
        end
    end
    return found
end
