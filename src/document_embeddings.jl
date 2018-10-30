"""
Fast tokenization function.
"""
tokenize_for_conceptnet(doc::Vector{S}, splitter::Regex=DEFAULT_SPLITTER
                       ) where S<:AbstractString = begin doc end

tokenize_for_conceptnet(doc::S, splitter::Regex=DEFAULT_SPLITTER
                       ) where S<:AbstractString = begin
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
                        print_matched_words::Bool=false)
    # Split document into tokens and embed
    return embed_document(conceptnet,
                          tokenize_for_conceptnet(document),
                          language=language,
                          keep_size=keep_size,
                          compound_word_separator=compound_word_separator,
                          max_compound_word_length=max_compound_word_length,
                          wildcard_matching=wildcard_matching,
                          print_matched_words=print_matched_words)
end

function embed_document(conceptnet::ConceptNet,
                        document_tokens::Vector{S};
                        language=Languages.English(),
                        keep_size::Bool=true,
                        compound_word_separator::String="_",
                        max_compound_word_length::Int=1,
                        wildcard_matching::Bool=false,
                        print_matched_words::Bool=false
                       ) where S<:AbstractString
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
    if keep_size
        for word in words_not_found
            push!(found_words, word)  # the zero-vectors will be the
        end                           # last columns of the document matrix
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
                      tokens::Vector{S};
                      language::L=Languages.English(),
                      separator::String="_",
                      max_length::Int=3,
                      wildcard_matching::Bool=false) where
        {L<:Language, K, V, S<:AbstractString}
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
        if j-i+1 <= max_length
            token = join(tokens[i:j], separator, separator)
            is_match = check_function(conceptnet, language, token, V())
            if is_match
                push!(found, i:j)
                i = j + 1
                j = n
                continue
            end
        end
        if i == j
            j = n
            i+= 1
        else
            j-= 1
        end
    end
    return found
end
