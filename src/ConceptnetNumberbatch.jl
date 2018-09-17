# ConceptnetNumberbatch.jl - an interface for ConceptNetNumberbatch
#   written in Julia by Cornel Cofaru at 0x0α Research, 2018
#
# Paper:
#   Robert Speer, Joshua Chin, and Catherine Havasi (2017).
#       "ConceptNet 5.5: An Open Multilingual Graph of General Knowledge."
#       In proceedings of AAAI 2017.

module ConceptnetNumberbatch

using Serialization
using Random
using TranscodingStreams
using CodecZlib
using ProgressMeter
using HDF5

export download_embeddings,
       load_embeddings

# Links pointing to the latest ConceptNetNumberbatch version (v"17.06")
const CONCEPTNET_MULTI_LINK = "https://conceptnet.s3.amazonaws.com/downloads/2017/numberbatch/numberbatch-17.06.txt.gz"
const CONCEPTNET_EN_LINK = "https://conceptnet.s3.amazonaws.com/downloads/2017/numberbatch/numberbatch-en-17.06.txt.gz"
const CONCEPTNET_HDF5_LINK = "https://conceptnet.s3.amazonaws.com/precomputed-data/2016/numberbatch/17.06/mini.h5"

include("interface.jl")

end # module
