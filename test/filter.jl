using HDF5
using HDF5.Filters
using Test
using H5Zblosc, H5Zlz4, H5Zbzip2, H5Zzstd

@testset "filter" begin

# Create a new file
fn = tempname()

# Create test data
data = rand(1000, 1000)

# Open temp file for writing
f = h5open(fn, "w")

# Create datasets
dsdeflate = create_dataset(f, "deflate", datatype(data), dataspace(data),
                           chunk=(100, 100), deflate=3)

dsshufdef = create_dataset(f, "shufdef", datatype(data), dataspace(data),
                           chunk=(100, 100), shuffle=true, deflate=3)

dsfiltdef = create_dataset(f, "filtdef", datatype(data), dataspace(data),
                           chunk=(100, 100), filters=Filters.Deflate(3))

dsfiltshufdef = create_dataset(f, "filtshufdef", datatype(data), dataspace(data),
                               chunk=(100, 100), filters=[Filters.Shuffle(), Filters.Deflate(3)])


# Write data
write(dsdeflate, data)
write(dsshufdef, data)
write(dsfiltdef, data)
write(dsfiltshufdef, data)

# Test compression filters

compressionFilters = Dict(
    "blosc" => BloscFilter,
    "bzip2" => Bzip2Filter,
    "lz4" => Lz4Filter,
    "zstd" => ZstdFilter
)

for (name, filter) in compressionFilters

    ds = create_dataset(
        f, name, datatype(data), dataspace(data),
        chunk=(100,100), filters=filter()
    )
    write(ds, data)

    ds = create_dataset(
        f, "shuffle+"*name, datatype(data), dataspace(data),
        chunk=(100,100), filters=[Filters.Shuffle(), filter()]
    )
    write(ds, data)

end

ds = create_dataset(
    f, "blosc_bitshuffle", datatype(data), dataspace(data),
    chunk=(100,100), filters=BloscFilter(shuffle=H5Zblosc.BITSHUFFLE)
)
write(ds, data)

# Close and re-open file for reading
close(f)
f = h5open(fn)

# Read datasets and test for equality
for name in keys(f)
    ds = f[name]
    @testset "$name" begin
        @debug "Filter Dataset" HDF5.name(ds)
        @test ds[] == data
        filters = HDF5.get_create_properties(ds).filters
        if startswith(name, "shuffle+")
            @test filters[1] isa Shuffle
            @test filters[2] isa compressionFilters[name[9:end]]
        elseif haskey(compressionFilters, name) || name == "blosc_bitshuffle"
            name = replace(name, r"_.*"=>"")
            @test filters[1] isa compressionFilters[name]
        end
    end
end

close(f)

# Issue #896 and https://github.com/JuliaIO/HDF5.jl/issues/285#issuecomment-1002243321
# Create an UnknownFilter from a Tuple
h5open(fn, "w") do f
    data = rand(UInt8, 512, 16, 512)
    # Tuple of integers should become an Unknown Filter
    ds, dt = create_dataset(f, "data", data, chunk=(256,1,256), filter=(H5Z_FILTER_BZIP2, 0))
    # Tuple of Filters should get pushed into the pipeline one by one
    dsfiltshufdef = create_dataset(f, "filtshufdef", datatype(data), dataspace(data),
                               chunk=(128, 4, 128), filters=(Filters.Shuffle(), Filters.Deflate(3)))
    write(ds, data)
    close(ds)
    write(dsfiltshufdef, data)
    close(dsfiltshufdef)
end

h5open(fn, "r") do f
    @test f["data"][] == data
    @test f["filtshufdef"][] == data
end

end # @testset "filter"