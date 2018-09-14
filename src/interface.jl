# TODO(Corneliu): Functionality to implement for v0.0.1
#


function _parseline(buf)
    bufvec = split(buf, " ")
    keyword = string(popfirst!(bufvec))
    embedding = parse.(Float64, bufvec)
    #embedding = map(x->parse(Float64,x), bufvec)
    return (keyword => embedding)
end

function parse_file(file::String, n::Int = -1)
    fid = open(file, "r")
    cfid = TranscodingStream(GzipDecompressor(), fid)
    length, width = map(x->parse(Int,x), split(readline(cfid)," ")) # ignore this (size)
    wordembs = Dict{String, Vector{Float64}}()
    if n < 0  n = length end
    n = min(n, length)
    _nlines = 0
    while _nlines <= n
        buf = readline(cfid)
        push!(wordembs, _parseline(buf))
        _nlines +=1
    end
    close(fid)
    close(cfid)
    return length, width, wordembs
end

