using Pkg
Pkg.activate(".")
using ConceptnetNumberbatch
using Serialization

local cptnet

# Load a serialized version of ConceptNetEnglish
fid = open("./_conceptnet_/numberbatch-en-17.06.txt.bin")
cptnet = deserialize(fid)
close(fid)

phrase = "this is a phrase that containz some iwords"
ConceptnetNumberbatch.word_embeddings(cptnet, phrase)
@time embs =ConceptnetNumberbatch.word_embeddings(cptnet, phrase)
println("Loaded $(size(embs, 2)) embedding vectors of $(size(embs,1)) elements each.") 
