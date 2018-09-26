# ConceptnetNumberbatch.jl

An Julia interface to [ConceptNetNumberbatch](https://github.com/commonsense/conceptnet-numberbatch)

[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md)
[![Build Status](https://travis-ci.org/zgornel/ConceptnetNumberbatch.jl.svg?branch=master)](https://travis-ci.org/zgornel/ConceptnetNumberbatch.jl)
[![Coverage Status](https://coveralls.io/repos/github/zgornel/ConceptnetNumberbatch.jl/badge.svg?branch=master)](https://coveralls.io/github/zgornel/ConceptnetNumberbatch.jl?branch=master)



## Introduction

This package is a simple API to *ConceptNetNumberbatch*.

## Documentation

There is little documentation available however these examples illustrate some common usage patterns:
TODO



## Limitations and Caveats

 - pretty fast for retrieving an existing word
 - slow for retrieving a mismatch
 - could be wrong for mismatches
 - retrieval is based on string distances
 - decreasing the vocabulary size based on language (i.e. detect the language of the text before searching) may increase performance significantly at the cost of more mismatches for rare words



## Installation

The installation can be done through the usual channels (manually by cloning the repository or installing it though the julia `REPL`).



## Remarks

At this point this is a work in progress and should NOT be used. For an alternative to this
package (with respect to word embeddings), check out [Embeddings.jl](https://github.com/JuliaText/Embeddings.jl)



## License

This code has an MIT license and therefore it is free.



## References

[1] [ConceptNetNumberbatch GitHub homepage](https://github.com/commonsense/conceptnet-numberbatch)
[2] [ConceptNet GitHub homepage](https://github.com/commonsense/conceptnet5)
