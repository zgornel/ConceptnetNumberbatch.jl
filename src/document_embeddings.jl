"""
Fast tokenization function.
"""
function tokenize_for_conceptnet(doc::AbstractString, splitter::Regex=DEFAULT_SPLITTER)
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
                        compound_word_separator::String="_",
                        max_compound_word_length::Int=1,
                        wildcard_matching::Bool=false,
                        search_mismatches::Symbol=:no,
                        print_matched_words::Bool=false,
                        distance=Levenshtein())
    # Split document into tokens and embed
    return embed_document(conceptnet,
                          tokenize_for_conceptnet(document),
                          language=language,
                          keep_size=keep_size,
                          compound_word_separator=compound_word_separator,
                          max_compound_word_length=max_compound_word_length,
                          wildcard_matching=wildcard_matching,
                          search_mismatches=search_mismatches,
                          print_matched_words=print_matched_words,
                          distance=distance)
end

function embed_document(conceptnet::ConceptNet,
                        document_tokens::Vector{S};
                        language=Languages.English(),
                        keep_size::Bool=true,
                        compound_word_separator::String="_",
                        max_compound_word_length::Int=1,
                        wildcard_matching::Bool=false,
                        search_mismatches::Symbol=:no,
                        print_matched_words::Bool=false,
                        distance=Levenshtein()) where S<:AbstractString
    # Initializations
    embeddings = conceptnet.embeddings[language]
    # Get positions of words that can be used for indexing (found)
    # and those of words that can be searched (not_found)
    found_positions = token_search(conceptnet,
                                   document_tokens;
                                   language=language,
                                   separator=compound_word_separator,
                                   max_length=max_compound_word_length,
                                   wildcard_matching=wildcard_matching)
    # Get found words
    found_words = Vector{String}()
    for pos in found_positions
        word = make_word_from_tokens(document_tokens,
                                     pos,
                                     separator=compound_word_separator,
                                     separator_last=compound_word_separator)
        push!(found_words, word)
    end
    # Get best matches for not found words
    not_found_positions = setdiff(1:length(document_tokens),
                                  collect.(found_positions)...)
    words_not_found = document_tokens[not_found_positions]
    if keep_size && !isempty(words_not_found)  # keep_size has precendence
        for word in words_not_found
            if search_mismatches == :no
                # Insert not found words if exact matches are to be
                # returned only if a matrix of width equal to the
                # number of terms is to be returned
                push!(found_words, word)
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
                push!(found_words, match_word)
            else
                @warn "The only supported approximate string matching" *
                      " method is :brute_force. Use :no for skipping the" *
                      " search; will not search."
                push!(found_words, word)
            end
        end
    end
    # Return
    if print_matched_words
        println("Embedded words: $found_words")
        println("Mismatched words: $words_not_found")
    end
    return conceptnet[language, found_words], not_found_positions
end



# Small function that builds a compound word
function make_word_from_tokens(tokens::Vector{S},
                               pos;
                               separator::String="_",
                               separator_last::String="_") where
        S<:AbstractString
    if length(pos) == 1
        return join(tokens[pos])
    else
        return join(tokens[pos], separator, separator_last)
    end
end

# Function that searches subphrases (continuous token combinations)
# from a document in a the embedded words and returns the positions of matched
# subphrases/words
# Example:
#   - for a vector: String[a, simpler, world, would, be, more, complicated],
#     max_length=7 and separator='_', it would generate:
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
function token_search(conceptnet::ConceptNet{L,K,V},
                      tokens::S;
                      language::L=Languages.English(),
                      separator::String="_",
                      max_length::Int=3,
                      wildcard_matching::Bool=false) where
        {L<:Language, K, V, S<:AbstractVector{<:AbstractString}}
    # Initializations
    if wildcard_matching
        # Build function that checks whether a token is found in conceptnet
        # using/or not wildcard matching
        check_function = (conceptnet, language, token, default)->
                            !isempty(get(conceptnet[language],  # get from interface.jl
                                         token,
                                         default,
                                         conceptnet.fuzzy_words[language]))
    else
        check_function = (conceptnet, language, token, default)->
                            haskey(conceptnet[language], token)
    end
    found = Vector{UnitRange{Int}}()
    n = length(tokens)
    i = 1
    j = n
    while i <= n
        token = join(tokens[i:j], separator, separator)
        is_match = check_function(conceptnet, language, token, V())
        if is_match && j-i+1 <= max_length
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
