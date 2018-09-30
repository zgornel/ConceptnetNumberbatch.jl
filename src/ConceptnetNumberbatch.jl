# MMMMMMMMMMMMMMMMMMMMMMMMMMMWNNKN0KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
# MMMMMMMMMMMMMMMMMMMMMMMMMW0OMMMMX0MMMMMMMMMMXXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNWMMMMNMMMMMMMMMMMMMMMMMMMMMMMM
# MMMMMMMMMMMMMMMMMMMMMMMMMKMMMMMOKWMMMMMMMN:lkkdXMMNXWMMMWMNNMMMMWXWMMMNNMMMWMNNMMMlXWM;.xMMW.MMMWXWMM0dWWMMMMMMMMMMMM
# MMMMMMMMMMMMMMMMMMMMMMMMNXMMMMMXXMMMMMMMM:oMMMMMX,xkl:MK.xkd'MN,dkxMx:Ox,NW dkd'N0 xOM;OccWW.MW;dOcoN:;kNMMMMMMMMMMMM
# MMMMMMMMMMMMMMMMMMWXXXXXkMMMMMMM0MMMMMMMM:lMMMMMocMMM.XK.MMM Mk;MMMM.lxxlKM MMM;xM.NMM;OMk,X.MO.xxdoMolMMMMMMMMMMMMMM
# MMMMMMMMMMMMMMXXXXNMMMMMoMMMMMMMOMMMMMMMMW:cdxdWN;dxlcMK.MMM MW;oxdMk;dxdWM dxo,NM;lkM;OMMX'.MW:oxd0MO'xXMMMMMMMMMMMM
# MMMMMMMMMMMMXXWMMMMMMMMM0KMMMMMOOMMMMMMMMMMMWWMMMMMWMMMMMMMMMMMMMWMMMMWWMMM MWWMMMMWWMMMMMMMMMMMMWWMMMMWMMMMMMMMMMMMM
# MMMMMMMMMMW0WMMMMMMMMMMMMNMMMM0:WMMMMMMMMXxxNMM0kMMMMMMMMMMMMMMMMMMMMXl0MMMxMMMMMMMMMMMMModMMMMMMMMMMMMW0WMMMMMMMMdoM
# MMMMMMMMMM0MMMMMMMMMMMMMMMMMMk'0MMMMMMMMM0cxlXMxoMNxKMWd0M0xOxdOkxd0MXcxkdkWM0xkx0MNd0xxMlokdxNMNxkxkNNxcxkMXxxxOMdlk
# MMMMMMMMMMKMMMMMMMMMNK0XNMMMM:'OWMMMMMMMM0cNOlKkoMXcOMWckMkcXMxcNMdlMXcOMXcOXcdOxcKNcxWMMloMWooMN0OkcOMOcNMWldMMMMdlW
# NKOkk0KK0OkMMMMMMWd;:kWMWXX0kdo;'OMMMMMMM0cNMKlloMNlxXOckMkcWMxcMMdlMXcxXOcKNlxXXKWNcOMMMllKKlxMloX0cOM0c0XMooKXKMdoM
# MMMMWX0kdl:0MMMMX;'lWMMMMMMWk;'0XWMMMMMMMN0WMMX0KMMX00XKXMX0WMX0MMKKMW0N00XMMWK00KMW0XMMMKXK0KWMX00NKXMWK00MWK00XMKKM
# MMMMMMMMMMMWOOoc'o0KWMMMMMMMMWK0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
#                                                                                                                     #
# ConceptnetNumberbatch.jl - an interface for ConceptNetNumberbatch written in Julia at 0x0α Research, 2018           #
# Paper:                                                                                                              #
#   Robert Speer, Joshua Chin, and Catherine Havasi (2017).                                                           #
#       "ConceptNet 5.5: An Open Multilingual Graph of General Knowledge." in proceedings of AAAI 2017.               #
#######################################################################################################################
# General remarks:
#   - pretty fast for retrieving an existing word
#   - slow for retrieving a mismatch
#   - could be wrong for mismatches
#   - retrieval is based on string distances
#   - decreasing the vocabulary size based on language
#     (i.e. detect the language of the text before
#     searching) may increase performance significantly at the cost
#     of more mismatches for rare words

module ConceptnetNumberbatch

using TranscodingStreams
using CodecZlib
using HDF5
using Languages
using StringDistances
using NearestNeighbors

import Base: getindex, size, length, show, keys, values, in

# Links pointing to the latest ConceptNetNumberbatch version (v"17.06")
const CONCEPTNET_MULTI_LINK = "https://conceptnet.s3.amazonaws.com/downloads/2017/numberbatch/numberbatch-17.06.txt.gz"
const CONCEPTNET_EN_LINK = "https://conceptnet.s3.amazonaws.com/downloads/2017/numberbatch/numberbatch-en-17.06.txt.gz"
const CONCEPTNET_HDF5_LINK = "https://conceptnet.s3.amazonaws.com/precomputed-data/2016/numberbatch/17.06/mini.h5"

# Accepted languages (map from conceptnet to Languages.Language)
const LANG_MAP = Dict(:en=>Languages.English(),
                      :fr=>Languages.French(),
                      :de=>Languages.German(),
                      :it=>Languages.Italian(),
                      :fi=>Languages.Finnish(),
                      :nl=>Languages.Dutch(),
                      :af=>Languages.Dutch(),
                      :pt=>Languages.Portuguese(),
                      :es=>Languages.Spanish(),
                      :ru=>Languages.Russian(),
                      :ro=>Languages.Romanian(),
                      :sw=>Languages.Swedish()
                      # add more mappings here if needed
                      # AND supported by Languages.jl
                     )

export CONCEPTNET_MULTI_LINK,
       CONCEPTNET_EN_LINK,
       CONCEPTNET_HDF5_LINK,
       ConceptNet,
       download_embeddings,
       load_embeddings,
       phrase_embeddings

include("interface.jl")
include("files.jl")
include("search.jl")

end # module
