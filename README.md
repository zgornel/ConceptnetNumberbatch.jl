# ConceptnetNumberbatch.jl

An Julia interface to [ConceptNetNumberbatch](https://github.com/commonsense/conceptnet-numberbatch)

[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md)
[![Build Status](https://travis-ci.org/zgornel/ConceptnetNumberbatch.jl.svg?branch=master)](https://travis-ci.org/zgornel/ConceptnetNumberbatch.jl)
[![Coverage Status](https://coveralls.io/repos/github/zgornel/ConceptnetNumberbatch.jl/badge.svg?branch=master)](https://coveralls.io/github/zgornel/ConceptnetNumberbatch.jl?branch=master)



## Introduction

This package is a simple API to **ConceptNetNumberbatch**.



## Documentation

The following examples illustrate some common usage patterns:

```julia>
julia> using Conceptnet, Languages
	   path_h5 = download_embeddings(url=CONCEPTNET_HDF5_LINK, localfile="./_conceptnet_/conceptnet.h5");
# [ Info: Download ConceptNetNumberbatch to ./_conceptnet_/conceptnet.h5...
#   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
#                                  Dload  Upload   Total   Spent    Left  Speed
# 100  127M  100  127M    0     0  3646k      0  0:00:35  0:00:35 --:--:-- 4107k
"./_conceptnet_/conceptnet.h5"

# Load embeddings
julia> conceptnet = load_embeddings(path_h5, languages=[Languages.English()])
# ConceptNet{Languages.English} (compressed): 1 language(s), 150875 embeddings

julia> conceptnet["apple"]  # Get embeddings for a single word
# 300×1 Array{Int8,2}:
#   0
#   0
#   1
#  -4
# ...

julia> conceptnet[["apple", "pear", "cherry"]]  # Get embeddings for multiple words
# 300×3 Array{Int8,2}:
#   0   0   0
#   0   0   0
#   1   1   1
#  -4  -6  -7
# ...
```

```julia
# Load multiple languages
julia> conceptnet = load_embeddings(path_h5, languages=[Languages.English(), Languages.French()])
# ConceptNet{Language} (compressed): 2 language(s), 174184 embeddings

julia> conceptnet["apple"]  # fails, language must be specified
# ERROR: ...

julia> [conceptnet[:en, "apple"] conceptnet[:fr, "poire"]]  # languages can be specified also as Languages.English(), Languages.French()
# 300×2 Array{Int8,2}:
#   0   -2
#   0   -2
#   1   -2
#  -4   -7
# ...

# Wildcard matching
julia> conceptnet[:en, "xxyyzish"]  # returns embedding for "#####ish"
# 300×1 Array{Int8,2}:
#   5
#  -1
#   0
#   1
# ...
```

```julia
# Useful functions
julia> length(conceptnet)  # total number of embeddings for all languages
# 174184

julia> size(conceptnet)  # embedding vector length, number of embeddings
# (300, 174184)

julia> "apple" in conceptnet  # found in the English embeddings
# true

julia> "poire" in conceptnet  # found in the French embeddings
# true

julia> # `keys` returns an iterator for all words
       for word in Iterators.take(keys(conceptnet),3)
           println(word)
       end
# définie
# invités
# couvents
```


## Remarks

 - fast for retrieving embeddings of exact matches
 - fast for retrieving embeddings of wildcard matches (`xyzabcish` is matched to `######ish`)
 - if neither exact or wildcard matches exist, retrieval can be based on string distances (slow, see `src/search.jl`)



## Installation

The installation can be done through the usual channels (manually by cloning the repository or installing it though the julia `REPL`).



## License

This code has an MIT license and therefore it is free.



## References

[1] [ConceptNetNumberbatch GitHub homepage](https://github.com/commonsense/conceptnet-numberbatch)
[2] [ConceptNet GitHub homepage](https://github.com/commonsense/conceptnet5)
[3] [Embeddings.jl - another embeddings package](https://github.com/JuliaText/Embeddings.jl)
