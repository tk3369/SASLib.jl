module SASLib

using StringEncodings
using TabularDisplay
using Tables

using Dates

import IteratorInterfaceExtensions, TableTraits

export readsas, REGULAR_STR_ARRAY

import Base: show, size

include("constants.jl")
include("utils.jl")
include("ObjectPool.jl")
include("CIDict.jl")
include("Types.jl")
include("ResultSet.jl")
include("Metadata.jl")
include("tables.jl")

function _open(config::ReaderConfig)
    # println("Opening $(config.filename)")
    handler = Handler(config)
    init_handler(handler)
    read_header(handler)
    read_file_metadata(handler)
    populate_column_names(handler)
    check_user_column_types(handler)
    read_first_page(handler)
    return handler
end

"""
open(filename::AbstractString;
        encoding::AbstractString = "",
        convert_dates::Bool = true,
        include_columns::Vector = [],
        exclude_columns::Vector = [],
        string_array_fn::Dict = Dict(),
        number_array_fn::Dict = Dict(),
        column_types::Dict = Dict{Symbol,Type}(),
        verbose_level::Int64 = 1)

Open a SAS7BDAT data file.  Returns a `SASLib.Handler` object that can be used in
the subsequent `SASLib.read` and `SASLib.close` functions.
"""
function open(filename::AbstractString;
        encoding::AbstractString = "",
        convert_dates::Bool = true,
        include_columns::Vector = [],
        exclude_columns::Vector = [],
        string_array_fn::Dict = Dict(),
        number_array_fn::Dict = Dict(),
        column_types::Dict = Dict{Symbol,Type}(),
        verbose_level::Int64 = 1)
    return _open(ReaderConfig(filename, encoding, default_chunk_size, convert_dates,
        include_columns, exclude_columns, string_array_fn, number_array_fn,
        column_types, verbose_level))
end

"""
read(handler::Handler, nrows=0)

Read data from the `handler` (see `SASLib.open`).  If `nrows` is not specified,
read the entire file content.  When called again, fetch the next `nrows` rows.
"""
function read(handler::Handler, nrows=0)
    # println("Reading $(handler.config.filename)")
    elapsed = @elapsed result = read_chunk(handler, nrows)
    elapsed = round(elapsed, digits = 5)
    println1(handler, "Read $(handler.config.filename) with size $(size(result, 1)) x $(size(result, 2)) in $elapsed seconds")
    return result
end

"""
close(handler::Handler)

Close the `handler` object.  This function effectively closes the
underlying iostream.  It must be called after the program
finished reading data.

This function is needed only when `SASLib.open` and `SASLib.read`
functions are used instead of the more convenient `readsas` function.
"""
function close(handler::Handler)
    # println("Closing $(handler.config.filename)")
    Base.close(handler.io)
end

"""
readsas(filename::AbstractString;
        encoding::AbstractString = "",
        convert_dates::Bool = true,
        include_columns::Vector = [],
        exclude_columns::Vector = [],
        string_array_fn::Dict = Dict(),
        number_array_fn::Dict = Dict(),
        column_types::Dict = Dict{Symbol,Type}(),
        verbose_level::Int64 = 1)

Read a SAS7BDAT file.

`Encoding` may be used as an override only if the file cannot be read
using the encoding specified in the file.  If you receive a warning
about unknown encoding then check your system's supported encodings from
the iconv library e.g. using the `iconv --list` command.

If `convert_dates == false` then no conversion is made
and you will get the number of days for Date columns (or number of
seconds for DateTime columns) since 1-JAN-1960.

By default, all columns will be read.  If you only need a subset of the
columns, you may specify
either `include_columns` or `exclude_columns` but not both.  They are just
arrays of columns indices or symbols e.g. [1, 2, 3] or [:employeeid, :firstname, :lastname]

String columns by default are stored in `SASLib.ObjectPool`, which is an array-like
structure that is more space-efficient when there is a high number of duplicate
values.  However, if there are too many unique items (> 10%) then it's automatically
switched over to a regular Array.

If you wish to use a different kind of array, you can pass your
array constructor via the `string_array_fn` dict.  The constructor must
take a single integer argument that represents the size of the array.
The convenient `REGULAR_STR_ARRAY` function can be used if you just want to
use the regular Array{String} type.

For examples,
`string_array_fn = Dict(:column1 => (n)->CategoricalArray{String}((n,)))`
or
`string_array_fn = Dict(:column1 => REGULAR_STR_ARRAY)`.

For numeric columns, you may specify your own array constructors using
the `number_array_fn` parameter.  Perhaps you have a different kind of
array to store the values e.g. SharedArray.

Specify `column_type` argument if any conversion is required.  It should
be a Dict, mapping column symbol to a data type.

For debugging purpose, `verbose_level` may be set to a value higher than 1.
Verbose level 0 will output nothing to the console, essentially a total quiet
option.
"""
function readsas(filename::AbstractString;
        encoding::AbstractString = "",
        convert_dates::Bool = true,
        include_columns::Vector = [],
        exclude_columns::Vector = [],
        string_array_fn::Dict = Dict(),
        number_array_fn::Dict = Dict(),
        column_types::Dict = Dict{Symbol,Type}(),
        verbose_level::Int64 = 1)
    handler = nothing
    try
        handler = _open(ReaderConfig(filename, encoding, default_chunk_size, convert_dates,
            include_columns, exclude_columns, string_array_fn, number_array_fn,
            column_types, verbose_level))
        return read(handler)
    finally
        isdefined(handler, :string_decoder) && Base.close(handler.string_decoder)
        handler !== nothing && close(handler)
    end
end

# Read a single float of the given width (4 or 8).
function _read_float(handler, offset, width)
    if !(width in [4, 8])
        throw(ArgumentError("invalid float width $(width)"))
    end
    buf = _read_bytes(handler, offset, width)
    value = reinterpret(width == 4 ? Float32 : Float64, buf)[1]
    if (handler.byte_swap)
        value = bswap(value)
    end
    return value
end

# Read a single signed integer of the given width (1, 2, 4 or 8).
@inline function _read_int(handler, offset, width)
    b = _read_bytes(handler, offset, width)
    width == 1 ? Int64(b[1]) :
        (handler.file_endianness == :BigEndian ? convertint64B(b...) : convertint64L(b...))
end

@inline function _read_bytes(handler, offset, len)
    return handler.cached_page[offset+1:offset+len]  #offset is 0-based
    # => too conservative.... we expect cached_page to be filled before this function is called
    # if handler.cached_page == []
    #     @warn("_read_byte function going to disk")
    #     seek(handler.io, offset)
    #     try
    #         return Base.read(handler.io, len)
    #     catch
    #         throw(FileFormatError("Unable to read $(len) bytes from file position $(offset)"))
    #     end
    # else
    #     if offset + len > length(handler.cached_page)
    #         throw(FileFormatError(
    #             "The cached page $(length(handler.cached_page)) is too small " *
    #             "to read for range positions $offset to $len"))
    #     end
    #     return handler.cached_page[offset+1:offset+len]  #offset is 0-based
    # end
end

# Get file properties from the header (first page of the file).
#
# At least 2 i/o operation is required:
# 1. First 288 bytes contain some important info e.g. header_length
# 2. Rest of the bytes in the header is just header_length - 288
#
function read_header(handler)

    # read header section
    seekstart(handler.io)
    handler.cached_page = Base.read(handler.io, 288)

    # Check magic number
    if handler.cached_page[1:length(magic)] != magic
        throw(FileFormatError("magic number mismatch (not a SAS file?)"))
    end
    # println("good magic number")

    # Get alignment debugrmation
    align1, align2 = 0, 0
    buf = _read_bytes(handler, align_1_offset, align_1_length)
    if buf == u64_byte_checker_value
        align2 = align_2_value
        handler.U64 = true
        handler.int_length = 8
        handler.page_bit_offset = page_bit_offset_x64
        handler.subheader_pointer_length = subheader_pointer_length_x64
    else
        handler.U64 = false
        handler.int_length = 4
        handler.page_bit_offset = page_bit_offset_x86
        handler.subheader_pointer_length = subheader_pointer_length_x86
    end
    # println2(handler, "U64 = $(handler.U64)")
    buf = _read_bytes(handler, align_2_offset, align_2_length)
    if buf == align_1_checker_value
        align1 = align_2_value
    end
    total_align = align1 + align2
    # println("successful reading alignment debugrmation")
    # println3(handler, "align1 = $align1, align2 = $align2, total_align=$total_align")
    # println3(handler, "header[33   ] = $([handler.cached_page[33]])       (align1)")
    # println3(handler, "header[34:35] = $(handler.cached_page[34:35]) (unknown)")
    # println3(handler, "header[36   ] = $([handler.cached_page[36]])       (align2)")
    # println3(handler, "header[37   ] = $([handler.cached_page[37]])       (unknown)")
    # println3(handler, "header[41:56] = $([handler.cached_page[41:56]]) (unknown)")
    # println3(handler, "header[57:64] = $([handler.cached_page[57:64]]) (unknown)")
    # println3(handler, "header[65:84] = $([handler.cached_page[65:84]]) (unknown)")

    # Get endianness information
    buf = _read_bytes(handler, endianness_offset, endianness_length)
    if buf == b"\x01"
        handler.file_endianness = :LittleEndian
    else
        handler.file_endianness = :BigEndian
    end
    # println2(handler, "file_endianness = $(handler.file_endianness)")

    # Detect system-endianness and determine if byte swap will be required
    handler.sys_endianness = ENDIAN_BOM == 0x04030201 ? :LittleEndian : :BigEndian
    # println2(handler, "system endianess = $(handler.sys_endianness)")

    handler.byte_swap = handler.sys_endianness != handler.file_endianness
    # println2(handler, "byte_swap = $(handler.byte_swap)")

    # Get encoding information
    buf = _read_bytes(handler, encoding_offset, 1)[1]
    if haskey(encoding_names, buf)
        handler.file_encoding = "$(encoding_names[buf])"
    else
        handler.file_encoding = FALLBACK_ENCODING         # hope for the best
        handler.config.verbose_level > 0 &&
            @warn("Unknown file encoding value ($buf), defaulting to $(handler.file_encoding)")
    end
    #println2(handler, "file_encoding = $(handler.file_encoding)")

    # User override for encoding
    if handler.config.encoding != ""
        handler.config.verbose_level > 0 &&
            @warn("Encoding has been overridden from $(handler.file_encoding) to $(handler.config.encoding)")
        handler.file_encoding = handler.config.encoding
    end
    # println2(handler, "Final encoding = $(handler.file_encoding)")

    # remember if Base.transcode should be used
    handler.use_base_transcoder = uppercase(handler.file_encoding) in
        ENCODINGS_OK_WITH_BASE_TRANSCODER
    # println2(handler, "Use base encoder = $(handler.use_base_transcoder)")

    # prepare string decoder if needed
    if !handler.use_base_transcoder
        println2(handler, "creating string buffer/decoder for with $(handler.file_encoding)")
        handler.string_decoder_buffer = IOBuffer()
        handler.string_decoder = StringDecoder(handler.string_decoder_buffer,
            handler.file_encoding)
    end

    # Get platform information
    buf = _read_bytes(handler, platform_offset, platform_length)
    if buf == b"1"
        handler.platform = "Unix"
    elseif buf == b"2"
        handler.platform = "Windows"
    else
        handler.platform = "Unknown"
    end
    # println("platform = $(handler.platform)")

    buf = _read_bytes(handler, dataset_offset, dataset_length)
    handler.name = transcode_metadata(brstrip(buf, zero_space))

    buf = _read_bytes(handler, file_type_offset, file_type_length)
    handler.file_type = transcode_metadata(brstrip(buf, zero_space))

    # Timestamp is epoch 01/01/1960
    epoch = DateTime(1960, 1, 1, 0, 0, 0)
    x = _read_float(handler, date_created_offset + align1, date_created_length)
    handler.date_created = epoch + Millisecond(round(x * 1000))
    # println("date created = $(x) => $(handler.date_created)")

    x = _read_float(handler, date_modified_offset + align1, date_modified_length)
    handler.date_modified = epoch + Millisecond(round(x * 1000))
    # println("date modified = $(x) => $(handler.date_modified)")

    handler.header_length = _read_int(handler, header_size_offset + align1, header_size_length)

    # Read the rest of the header into cached_page.
    # println3(handler, "Reading rest of page, header_length=$(handler.header_length) willread=$(handler.header_length - 288)")
    buf = Base.read(handler.io, handler.header_length - 288)
    append!(handler.cached_page, buf)
    if length(handler.cached_page) != handler.header_length
        throw(FileFormatError("The SAS7BDAT file appears to be truncated."))
    end

    # debug
    # println3(handler, "header[209+a1+a2] = $([handler.cached_page[209+align1+align2:209+align1+align2+8]]) (unknown)")
    # println3(handler, "header[289+a1+a2] = $([handler.cached_page[289+align1+align2:289+align1+align2+8]]) (unknown)")
    # println3(handler, "header[297+a1+a2] = $([handler.cached_page[297+align1+align2:297+align1+align2+8]]) (unknown)")
    # println3(handler, "header[305+a1+a2] = $([handler.cached_page[305+align1+align2:305+align1+align2+8]]) (unknown)")
    # println3(handler, "header[313+a1+a2] = $([handler.cached_page[313+align1+align2:313+align1+align2+8]]) (unknown)")

    handler.page_length = _read_int(handler, page_size_offset + align1, page_size_length)
    # println("page_length = $(handler.page_length)")

    handler.page_count = _read_int(handler, page_count_offset + align1, page_count_length)
    # println("page_count = $(handler.page_count)")

    buf = _read_bytes(handler, sas_release_offset + total_align, sas_release_length)
    handler.sas_release = transcode_metadata(brstrip(buf, zero_space))
    # println2(handler, "SAS Release = $(handler.sas_release)")

    # determine vendor - either SAS or STAT_TRANSFER
    _determine_vendor(handler)
    # println2(handler, "Vendor = $(handler.vendor)")

    buf = _read_bytes(handler, sas_server_type_offset + total_align, sas_server_type_length)
    handler.server_type = transcode_metadata(brstrip(buf, zero_space))
    # println("server_type = $(handler.server_type)")

    buf = _read_bytes(handler, os_version_number_offset + total_align, os_version_number_length)
    handler.os_version = transcode_metadata(brstrip(buf, zero_space))
    # println2(handler, "os_version = $(handler.os_version)")

    buf = _read_bytes(handler, os_name_offset + total_align, os_name_length)
    buf = brstrip(buf, zero_space)
    if length(buf) > 0
        handler.os_name = transcode_metadata(buf)
    else
        buf = _read_bytes(handler, os_maker_offset + total_align, os_maker_length)
        handler.os_name = transcode_metadata(brstrip(buf, zero_space))
    end
    # println("os_name = $(handler.os_name)")
end

# Read all pages to find metadata
# TODO however, this is inefficient since it reads a lot of data from disk
# TODO can we tell if metadata is complete and break out of loop early?
function read_file_metadata(handler)
    # println3(handler, "IN: _parse_metadata")
    i = 1
    while true
        # println3(handler, "  filepos=$(position(handler.io)) page_length=$(handler.page_length)")
        handler.cached_page = Base.read(handler.io, handler.page_length)
        if length(handler.cached_page) <= 0
            break
        end
        if length(handler.cached_page) != handler.page_length
            throw(FileFormatError("Failed to read a meta data page from the SAS file."))
        end
        # println("page $i = $(current_page_type_str(handler))")
        _process_page_meta(handler)
        i += 1
    end
end

# Check user's provided column types has keys that matches column symbols in the file
function check_user_column_types(handler)
    # save a copy of column types in a case insensitive dict
    handler.column_types_dict = CIDict{Symbol,Type}(handler.config.column_types)
    # check column_types
    for k in keys(handler.config.column_types)
        if !case_insensitive_in(k, handler.column_symbols)
            @warn("Unknown column symbol ($k) in column_types. Ignored.")
        end
    end
end

function _process_page_meta(handler)
    # println3(handler, "IN: _process_page_meta")
    _read_page_header(handler)
    pt = vcat([page_meta_type, page_amd_type], page_mix_types)
    # println("  pt=$pt handler.current_page_type=$(handler.current_page_type)")
    if handler.current_page_type in pt
        # println3(handler, "  current_page_type = $(current_page_type_str(handler))")
        # println3(handler, "  current_page = $(handler.current_page)")
        # println3(handler, "  $(concatenate(stringarray(currentpos(handler))))")
        _process_page_metadata(handler)
    end
    # println("  condition var #1: handler.current_page_type=$(handler.current_page_type)")
    # println("  condition var #2: page_mix_types=$(page_mix_types)")
    # println("  condition var #3: handler.current_page_data_subheader_pointers=$(handler.current_page_data_subheader_pointers)")
    return ((handler.current_page_type in vcat([256], page_mix_types)) ||
            (handler.current_page_data_subheader_pointers != []))
end

function _read_page_header(handler)
    # println3(handler, "IN: _read_page_header")
    bit_offset = handler.page_bit_offset
    tx = page_type_offset + bit_offset
    handler.current_page_type = _read_int(handler, tx, page_type_length)
    # println("  bit_offset=$bit_offset tx=$tx handler.current_page_type=$(handler.current_page_type)")
    tx = block_count_offset + bit_offset
    handler.current_page_block_count = _read_int(handler, tx, block_count_length)
    # println3(handler, "  tx=$tx handler.current_page_block_count=$(handler.current_page_block_count)")
    tx = subheader_count_offset + bit_offset
    handler.current_page_subheaders_count = _read_int(handler, tx, subheader_count_length)
    # println3(handler, "  tx=$tx handler.current_page_subheaders_count=$(handler.current_page_subheaders_count)")
end

function _process_page_metadata(handler)
    # println3(handler, "IN: _process_page_metadata")
    bit_offset = handler.page_bit_offset
    # println("  bit_offset=$bit_offset")
    # println3(handler, "  filepos=$(Base.position(handler.io))")
    # println3(handler, "  loop from 0 to $(handler.current_page_subheaders_count-1)")
    for i in 0:handler.current_page_subheaders_count-1
        # println3(handler, " i=$i")
        pointer = _process_subheader_pointers(handler, subheader_pointers_offset + bit_offset, i)
        # ignore subheader when no data is present (variable QL == 0)
        if pointer.length == 0
            # println3(handler, "  pointer.length==0, ignoring subheader")
            continue
        end
        # subheader with truncated compression flag may be ignored (variable COMP == 1)
        if pointer.compression == subheader_comp_truncated
            # println3(handler, "  subheader truncated, ignoring subheader")
            continue
        end
        subheader_signature = _read_subheader_signature(handler, pointer.offset)
        subheader_index =
            _get_subheader_index(handler, subheader_signature, pointer.compression, pointer.shtype)
        # println3(handler, "  subheader_index = $subheader_index")
        if subheader_index == index_end_of_header
            break
        end
        _process_subheader(handler, subheader_index, pointer)
    end
end

function _process_subheader_pointers(handler, offset, subheader_pointer_index)
    # println3(handler, "IN: _process_subheader_pointers")
    # println3(handler, "  offset=$offset (beginning of the pointers array)")
    # println3(handler, "  subheader_pointer_index=$subheader_pointer_index")

    # deference the array by index
    # handler.subheader_pointer_length is 12 or 24 (variable SL)
    total_offset = (offset + handler.subheader_pointer_length * subheader_pointer_index)
    # println3(handler, "  handler.subheader_pointer_length=$(handler.subheader_pointer_length)")
    # println3(handler, "  total_offset=$total_offset")

    # handler.int_length is either 4 or 8 (based on u64 flag)
    # subheader_offset contains where to find the subheader
    subheader_offset = _read_int(handler, total_offset, handler.int_length)
    # println3(handler, "  subheader_offset=$subheader_offset")
    total_offset += handler.int_length
    # println3(handler, "  total_offset=$total_offset")

    # subheader_length contains the length of the subheader (variable QL)
    # QL is sometimes zero, which indicates that no data is referenced by the
    # corresponding subheader pointer. When this occurs, the subheader pointer may be ignored.
    subheader_length = _read_int(handler, total_offset, handler.int_length)
    # println3(handler, "  subheader_length=$subheader_length")
    total_offset += handler.int_length
    # println3(handler, "  total_offset=$total_offset")

    # subheader_compression contains the compression flag (variable COMP)
    subheader_compression = _read_int(handler, total_offset, 1)
    # println3(handler, "  subheader_compression=$subheader_compression")
    total_offset += 1
    # println3(handler, "  total_offset=$total_offset")

    # subheader_type contains the subheader type (variable ST)
    subheader_type = _read_int(handler, total_offset, 1)

    return SubHeaderPointer(
                subheader_offset,
                subheader_length,
                subheader_compression,
                subheader_type)

end

# Read the subheader signature from the first 4 or 8 bytes.
# `offset` contains the offset from the start of page that contains the subheader
function _read_subheader_signature(handler, offset)
    # println("IN: _read_subheader_signature (offset=$offset)")
    bytes = _read_bytes(handler, offset, handler.int_length)
    return bytes
end

# Identify the type of subheader from the signature
function _get_subheader_index(handler, signature, compression, shtype)
    # println3(handler, "IN: _get_subheader_index")
    # println3(handler, "  signature=$signature")
    # println3(handler, "  compression=$compression <-> subheader_comp_compressed=$subheader_comp_compressed")
    # println3(handler, "  shtype=$shtype <-> subheader_comp_compressed=$subheader_comp_compressed")
    val = get(subheader_signature_to_index, signature, nothing)

    # if the signature is not found then it's likely storing binary data.
    # RLE (variable COMP == 4)
    # Uncompress (variable COMP == 0)
    if val === nothing
        if compression == subheader_comp_uncompressed || compression == subheader_comp_compressed
            val = index_dataSubheaderIndex
        else
            val = index_end_of_header
        end
    end
    return val
end

function _process_subheader(handler, subheader_index, pointer)
    # println3(handler, "IN: _process_subheader")
    offset = pointer.offset
    length = pointer.length

    # println3(handler, "  $(tostring(pointer))")

    if subheader_index == index_rowSizeIndex
        processor = _process_rowsize_subheader
    elseif subheader_index == index_columnSizeIndex
        processor = _process_columnsize_subheader
    elseif subheader_index == index_columnTextIndex
        processor = _process_columntext_subheader
    elseif subheader_index == index_columnNameIndex
        processor = _process_columnname_subheader
    elseif subheader_index == index_columnAttributesIndex
        processor = _process_columnattributes_subheader
    elseif subheader_index == index_formatAndLabelIndex
        processor = _process_format_subheader
    elseif subheader_index == index_columnListIndex
        processor = _process_columnlist_subheader
    elseif subheader_index == index_subheaderCountsIndex
        processor = _process_subheader_counts
    elseif subheader_index == index_dataSubheaderIndex
        # do not process immediately and just accumulate the pointers
        push!(handler.current_page_data_subheader_pointers, pointer)
        return
    else
        throw(FileFormatError("unknown subheader index"))
    end
    processor(handler, offset, length)
end

function _process_rowsize_subheader(handler, offset, length)
    println3(handler, "IN: _process_rowsize_subheader")
    int_len = handler.int_length
    lcs_offset = offset
    lcp_offset = offset
    if handler.U64
        lcs_offset += 682
        lcp_offset += 706
    else
        lcs_offset += 354
        lcp_offset += 378
    end
    handler.row_length = _read_int(handler,
        offset + row_length_offset_multiplier * int_len, int_len)
    handler.row_count = _read_int(handler,
        offset + row_count_offset_multiplier * int_len, int_len)
    handler.col_count_p1 = _read_int(handler,
        offset + col_count_p1_multiplier * int_len, int_len)
    handler.col_count_p2 = _read_int(handler,
        offset + col_count_p2_multiplier * int_len, int_len)
    mx = row_count_on_mix_page_offset_multiplier * int_len
    handler.mix_page_row_count = _read_int(handler, offset + mx, int_len)
    handler.lcs = _read_int(handler, lcs_offset, 2)
    handler.lcp = _read_int(handler, lcp_offset, 2)

    # println3(handler, "  handler.row_length=$(handler.row_length)")
    # println3(handler, "  handler.row_count=$(handler.row_count)")
    # println3(handler, "  handler.mix_page_row_count=$(handler.mix_page_row_count)")
end

function _process_columnsize_subheader(handler, offset, length)
    # println("IN: _process_columnsize_subheader")
    int_len = handler.int_length
    offset += int_len
    handler.column_count = _read_int(handler, offset, int_len)
    if (handler.col_count_p1 + handler.col_count_p2 != handler.column_count)
        @warn("Warning: column count mismatch ($(handler.col_count_p1) + $(handler.col_count_p2) != $(handler.column_count))")
    end
end

# Unknown purpose
function _process_subheader_counts(handler, offset, length)
    # println("IN: _process_subheader_counts")
end

function _process_columntext_subheader(handler, offset, length)
    # println3(handler, "IN: _process_columntext_subheader")

    p = offset + handler.int_length
    text_block_size = _read_int(handler, p, text_block_size_length)
    # println3(handler, "  text_block_size=$text_block_size")
    # println("  before reading buf: offset=$offset")

    # TODO this buffer includes the text_block_size itself in the beginning...
    buf = _read_bytes(handler, p, text_block_size)
    cname_raw = brstrip(buf[1:text_block_size], zero_space)
    # println3(handler, "  cname_raw=$cname_raw")

    cname = cname_raw
    # println3(handler, "  decoded=$(transcode_metadata(cname))")
    push!(handler.column_names_strings, cname)

    #println3(handler, "  handler.column_names_strings=$(handler.column_names_strings)")
    # println("  type=$(typeof(handler.column_names_strings))")
    # println("  content=$(handler.column_names_strings)")
    # println3(handler, "  content=$(size(handler.column_names_strings, 2))")

    # figure out some metadata if this is the first column
    if size(handler.column_names_strings, 2) == 1

        # check if there's compression signature
        if contains(cname_raw, rle_compression)
            compression_method = compression_method_rle
        elseif contains(cname_raw, rdc_compression)
            compression_method = compression_method_rdc
        else
            compression_method = compression_method_none
        end

        # println3(handler, "  handler.lcs = $(handler.lcs)")
        # println3(handler, "  handler.lcp = $(handler.lcp)")

        # save compression info in the handler
        handler.compression = compression_method

        # look for the compression & creator proc offset (16 or 20)
        offset1 = offset + 16
        if handler.U64
            offset1 += 4
        end

        # per doc, if first 8 bytes are _blank_ then file is not compressed, set LCS = 0
        # howver, we will use the above signature identification method instead.
        # buf = _read_bytes(handler, offset1, handler.lcp)
        # compression_literal = brstrip(buf, b"\x00")
        # if compression_literal == ""
        if compression_method == compression_method_none
            handler.lcs = 0
            offset1 = offset + 32
            if handler.U64
                offset1 += 4
            end
            buf = _read_bytes(handler, offset1, handler.lcp)
            creator_proc = buf[1:handler.lcp]
            # println3(handler, "  uncompressed: creator proc=$creator_proc decoded=$(transcode_metadata(creator_proc))")
        elseif compression_method == compression_method_rle
            offset1 = offset + 40
            if handler.U64
                offset1 += 4
            end
            buf = _read_bytes(handler, offset1, handler.lcp)
            creator_proc = buf[1:handler.lcp]
            # println3(handler, "  RLE compression: creator proc=$creator_proc decoded=$(transcode_metadata(creator_proc))")
        elseif handler.lcs > 0
            handler.lcp = 0
            offset1 = offset + 16
            if handler.U64
                offset1 += 4
            end
            buf = _read_bytes(handler, offset1, handler.lcs)
            creator_proc = buf[1:handler.lcp]
            # println3(handler, "  LCS>0: creator proc=$creator_proc decoded=$(transcode_metadata(creator_proc))")
        else
            creator_proc = nothing
        end
    end
end


function _process_columnname_subheader(handler, offset, length)
    # println3(handler, "IN: _process_columnname_subheader")
    int_len = handler.int_length
    # println(" int_len=$int_len")
    # println(" offset=$offset")
    offset += int_len
    # println(" offset=$offset (after adding int_len)")
    column_name_pointers_count = fld(length - 2 * int_len - 12, 8)
    # println(" column_name_pointers_count=$column_name_pointers_count")
    for i in 1:column_name_pointers_count
        text_subheader = offset + column_name_pointer_length *
            i + column_name_text_subheader_offset
        # println(" i=$i text_subheader=$text_subheader")
        col_name_offset = offset + column_name_pointer_length *
            i + column_name_offset_offset
        # println(" i=$i col_name_offset=$col_name_offset")
        col_name_length = offset + column_name_pointer_length *
            i + column_name_length_offset
        # println(" i=$i col_name_length=$col_name_length")

        idx = _read_int(handler,
            text_subheader, column_name_text_subheader_length)
        # println(" i=$i idx=$idx")
        col_offset = _read_int(handler,
            col_name_offset, column_name_offset_length)
        # println(" i=$i col_offset=$col_offset")
        col_len = _read_int(handler,
            col_name_length, column_name_length_length)
        # println(" i=$i col_len=$col_len")

        cnp = ColumnNamePointer(idx + 1, col_offset, col_len)
        push!(handler.column_name_pointers, cnp)
    end
end

function _process_columnattributes_subheader(handler, offset, length)
    # println("IN: _process_columnattributes_subheader")
    int_len = handler.int_length
    N = fld(length - 2 * int_len - 12, int_len + 8)
    # println("  column_attributes_vectors_count = $column_attributes_vectors_count")

    ty  = fill(column_type_none, N)
    len = fill(0::Int64, N)
    off = fill(0::Int64, N)
    # handler.column_types = fill(column_type_none, column_attributes_vectors_count)
    # handler.column_data_lengths = fill(0::Int64, column_attributes_vectors_count)
    # handler.column_data_offsets = fill(0::Int64, column_attributes_vectors_count)

    for i in 0:N-1
        col_data_offset = (offset + int_len +
                        column_data_offset_offset +
                        i * (int_len + 8))
        col_data_len = (offset + 2 * int_len +
                        column_data_length_offset +
                        i * (int_len + 8))
        col_types = (offset + 2 * int_len +
                    column_type_offset + i * (int_len + 8))
        j = i + 1
        off[j] = _read_int(handler, col_data_offset, int_len)
        len[j] = _read_int(handler, col_data_len, column_data_length_length)
        x = _read_int(handler, col_types, column_type_length)
        ty[j] = (x == 1) ? column_type_decimal : column_type_string
    end

    push!(handler.column_types, ty...)
    push!(handler.column_data_lengths, len...)
    push!(handler.column_data_offsets, off...)
end

function _process_columnlist_subheader(handler, offset, length)
    # println("IN: _process_columnlist_subheader")
    # unknown purpose
end

function _process_format_subheader(handler, offset, length)
    # println3(handler, "IN: _process_format_subheader")
    int_len = handler.int_length
    col_format_idx        = offset + 22 + 3 * int_len
    col_format_offset     = offset + 24 + 3 * int_len
    col_format_len        = offset + 26 + 3 * int_len
    col_label_idx         = offset + 28 + 3 * int_len
    col_label_offset      = offset + 30 + 3 * int_len
    col_label_len         = offset + 32 + 3 * int_len

    format_idx = _read_int(handler, col_format_idx, 2)
    # println3(handler, "  format_idx=$format_idx")
    # TODO julia bug?  must reference Base.length explicitly or else we get MethodError: objects of type Int64 are not callable
    format_idx = min(format_idx, Base.length(handler.column_names_strings) - 1)
    format_start = _read_int(handler, col_format_offset, 2)
    format_len = _read_int(handler, col_format_len, 2)
    # println3(handler, "  format_idx=$format_idx, format_start=$format_start, format_len=$format_len")
    format_names = handler.column_names_strings[format_idx+1]
    column_format = transcode_metadata(format_names[format_start+1: format_start + format_len])

    push!(handler.column_formats, column_format)

    # The following code isn't used and it's not working for some files e.g. topical.sas7bdat from AHS

    # label_idx = _read_int(handler, col_label_idx, 2)
    # # TODO julia bug?  must reference Base.length explicitly or else we get MethodError: objects of type Int64 are not callable
    # label_idx = min(label_idx, Base.length(handler.column_names_strings) - 1)
    # label_start = _read_int(handler, col_label_offset, 2)
    # label_len = _read_int(handler, col_label_len, 2)
    # println3(handler, "  label_idx=$label_idx, label_start=$label_start, label_len=$label_len")

    # println3(handler, "  handler.column_names_strings=$(size(handler.column_names_strings[1], 1))")
    # label_names = handler.column_names_strings[label_idx+1]
    # column_label = label_names[label_start+1: label_start + label_len]
    # println3(handler, "  column_label=$column_label decoded=$(transcode_metadata(column_label))")

    # current_column_number = size(handler.columns, 2)
    # println3(handler, "  current_column_number=$current_column_number")

    # col = Column(
    #     current_column_number,
    #     handler.column_names[current_column_number],
    #     column_label,
    #     column_format,
    #     handler.column_types[current_column_number],
    #     handler.column_data_lengths[current_column_number])

    # push!(handler.columns, col)
end

function read_chunk(handler, nrows=0)

    if !isdefined(handler, :column_types)
        @warn("No columns to parse from file")
        return ResultSet()
    end
    # println("column_types = $(handler.column_types)")

    if handler.row_count == 0
        @warn("File has no data")
        return ResultSet()
    end

    # println("IN: read_chunk")
    #println(handler.config)
    if (nrows == 0) && (handler.config.chunk_size > 0)
        nrows = handler.config.chunk_size
    elseif nrows == 0
        nrows = handler.row_count
    end
    # println("nrows = $nrows")

    # println("row_count = $(handler.row_count)")
    m = handler.row_count - handler.current_row_in_file_index
    if nrows > m
        nrows = m
    end
    # println("nrows = $(nrows)")
    #info("Reading $nrows x $(length(handler.column_types)) data set")

    # TODO not the most efficient but normally it should be ok for non-wide tables
    nd = count(x -> x == column_type_decimal, handler.column_types)
    ns = count(x -> x == column_type_string,  handler.column_types)
    # println("nd = $nd (number of decimal columns)")
    # println("ns = $ns (number of string columns)")

    # ns > 0 && !handler.use_base_transcoder &&
    #     info("Note: encoding incompatible with UTF-8, reader will take more time")

    populate_column_indices(handler)

    # allocate columns
    handler.byte_chunk = Dict()
    handler.string_chunk = Dict()
    for (k, name, ty) in handler.column_indices
        if ty == column_type_decimal
            handler.byte_chunk[name] = fill(UInt8(0), Int64(8 * nrows)) # 8-byte values
        elseif ty == column_type_string
            handler.string_chunk[name] = createstrarray(handler, name, nrows)
        else
            throw(FileFormatError("unknown column type: $ty for column $name"))
        end
    end

    # don't do this or else the state is polluted if user wants to
    # read lines separately.
    # handler.current_page = 0
    handler.current_row_in_chunk_index = 0

    perf_read_data = @elapsed(read_data(handler, nrows))
    perf_chunk_to_data_frame = @elapsed(rslt = _chunk_to_dataframe(handler, nrows))

    if handler.config.verbose_level > 1
        println("Read data in ", perf_read_data, " msec")
        println("Converted data in ", perf_chunk_to_data_frame, " msec")
    end

    column_symbols = [sym for (k, sym, ty) in handler.column_indices]
    return ResultSet([rslt[s] for s in column_symbols], column_symbols,
        (nrows, length(column_symbols)))
end

# not extremely efficient but is a safe way to do it
function createstrarray(handler, column_symbol, nrows)
    if haskey(handler.config.string_array_fn, column_symbol)
        handler.config.string_array_fn[column_symbol](nrows)
    elseif haskey(handler.config.string_array_fn, :_all_)
        handler.config.string_array_fn[:_all_](nrows)
    else
        if nrows + 1 < 2 << 7
            ObjectPool{String, UInt8}(EMPTY_STRING, nrows)
        elseif nrows < 2 << 15
            ObjectPool{String, UInt16}(EMPTY_STRING, nrows)
        elseif nrows < 2 << 31
            ObjectPool{String, UInt32}(EMPTY_STRING, nrows)
        else
            ObjectPool{String, UInt64}(EMPTY_STRING, nrows)
        end
    end
end

# create numeric array
function createnumarray(handler, column_symbol, nrows)
    if haskey(handler.config.number_array_fn, column_symbol)
        handler.config.number_array_fn[column_symbol](nrows)
    elseif haskey(handler.config.number_array_fn, :_all_)
        handler.config.number_array_fn[:_all_](nrows)
    else
        zeros(Float64, nrows)
    end
end

function _read_next_page_content(handler)
    # println3(handler, "IN: _read_next_page_content")
    # println3(handler, "  positions = $(concatenate(stringarray(currentpos(handler))))")
    handler.current_page += 1
    # println3(handler, "  current_page = $(handler.current_page)")
    # println3(handler, "  file position = $(Base.position(handler.io))")
    # println3(handler, "  page_length = $(handler.page_length)")

    handler.current_page_data_subheader_pointers = []
    handler.cached_page = Base.read(handler.io, handler.page_length)
    if length(handler.cached_page) <= 0
        return true
    elseif length(handler.cached_page) != handler.page_length
        throw(FileFormatError("Failed to read complete page from file ($(length(handler.cached_page)) of $(handler.page_length) bytes"))
    end
    _read_page_header(handler)
    if handler.current_page_type == page_meta_type
        _process_page_metadata(handler)
    end

    # println3(handler, "  type=$(current_page_type_str(handler))")
    if ! (handler.current_page_type in page_meta_data_mix_types)
        # println3(handler, "page type not found $(handler.current_page_type)... reading next one")
        return _read_next_page_content(handler)
    end
    return false
end

# test -- copied from _read_next_page_content
function my_read_next_page(handler)
    handler.current_page += 1
    handler.current_page_data_subheader_pointers = []
    handler.cached_page = Base.read(handler.io, handler.page_length)
    _read_page_header(handler)
    handler.current_row_in_page_index = 0
end

# convert Float64 value into Date object
function date_from_float(x::Vector{Float64})
    v = Vector{Union{Date, Missing}}(undef, length(x))
    for i in 1:length(x)
        v[i] = isnan(x[i]) ? missing : (sas_date_origin + Dates.Day(round(Int64, x[i])))
    end
    v
end

# convert Float64 value into DateTime object
function datetime_from_float(x::Vector{Float64})
    v = Vector{Union{DateTime, Missing}}(undef, length(x))
    for i in 1:length(x)
        v[i] = isnan(x[i]) ? missing : (sas_datetime_origin + Dates.Second(round(Int64, x[i])))
    end
    v
end

# Construct Dict object that holds the columns.
# For date or datetime columns, convert from numeric value to Date/DateTime type column.
# The resulting dictionary uses column symbols as the key.
function _chunk_to_dataframe(handler, nrows)
    # println("IN: _chunk_to_dataframe")

    n = handler.current_row_in_chunk_index
    m = handler.current_row_in_file_index
    rslt = Dict()

    # println("handler.column_names=$(handler.column_names)")
    for (k, name, ty) in handler.column_indices
        if ty == column_type_decimal  # number, date, or datetime
            # println("  String: size=$(size(handler.byte_chunk))")
            # println("  Decimal: column $j, name $name, size=$(size(handler.byte_chunk[jb, :]))")
            bytes = handler.byte_chunk[name]
            #if j == 1  && length(bytes) < 100  #debug only
                # println("  bytes=$bytes")
            #end
            values = createnumarray(handler, name, nrows)
            convertfloat64f!(values, bytes, handler.file_endianness)
            #println(length(bytes))
            #rslt[name] = bswap(rslt[name])
            rslt[name] = values
            if handler.config.convert_dates
                if handler.column_formats[k] in sas_date_formats
                    rslt[name] = date_from_float(rslt[name])
                elseif handler.column_formats[k] in sas_datetime_formats
                    # TODO probably have to deal with timezone somehow
                    rslt[name] = datetime_from_float(rslt[name])
                end
            end
            convert_column_type_if_needed!(handler, rslt, name)
        elseif ty == column_type_string
            # println("  String: size=$(size(handler.string_chunk))")
            # println("  String: column $j, name $name, size=$(size(handler.string_chunk[js, :]))")
            rslt[name] = handler.string_chunk[name]
        else
            throw(FileFormatError("Unknown column type: $ty"))
        end
    end
    return rslt
end

# If the user specified a type for the column, try to convert the column data.
function convert_column_type_if_needed!(handler, rslt, name)
    if haskey(handler.column_types_dict, name)
        type_wanted = handler.column_types_dict[name]
        #println("$name exists in config.column_types, type_wanted=$type_wanted")
        if type_wanted != Float64
            try
                rslt[name] = convert(Vector{type_wanted}, rslt[name])
            catch ex
                @warn("Unable to convert column to type $type_wanted, error=$ex")
            end
        end
    end
end

# Simple loop that reads data row-by-row.
function read_data(handler, nrows)
    # println("IN: read_data, nrows=$nrows")
    for i in 1:nrows
        done = readline(handler)
        if done
            break
        end
    end
end

function read_next_page(handler)
    done = _read_next_page_content(handler)
    if done
        handler.cached_page = []
    else
        handler.current_row_in_page_index = 0
    end
    return done
end

# Return `true` when there is nothing else to read
function readline(handler)
    # println("IN: readline")

    subheader_pointer_length = handler.subheader_pointer_length

    # If there is no page, go to the end of the header and read a page.
    # TODO commented out for performance reason... do we really need this?
    # if handler.cached_page == []
    #     println("  no cached page... seeking past header")
    #     seek(handler.io, handler.header_length)
    #     println("  reading next page")
    #     done = read_next_page(handler)
    #     if done
    #         println("  no page! returning")
    #         return true
    #     end
    # end

    # Loop until a data row is read
    # println("  start loop")
    while true
        if handler.current_page_type == page_meta_type
            #println("    page type == page_meta_type")
            flag = handler.current_row_in_page_index >= length(handler.current_page_data_subheader_pointers)
            if flag
                # println("    reading next page")
                done = read_next_page(handler)
                if done
                    # println("    all done, returning #1")
                    return true
                end
                continue
            end
            current_subheader_pointer =
                handler.current_page_data_subheader_pointers[handler.current_row_in_page_index+1]
                # println3(handler, "    current_subheader_pointer = $(current_subheader_pointer)")
                # println3(handler, "    handler.compression = $(handler.compression)")
                cm = compression_method_none
                if current_subheader_pointer.compression == subheader_comp_compressed
                    if handler.compression != compression_method_none
                        cm = handler.compression
                    else
                        cm = compression_method_rle  # default to RLE if handler doesn't have the info yet
                    end
                end
                process_byte_array_with_data(handler,
                    current_subheader_pointer.offset,
                    current_subheader_pointer.length, cm)
            return false
        elseif (handler.current_page_type == page_mix_types[1] ||
                handler.current_page_type == page_mix_types[2])
            # println3(handler, "  page type == page_mix_types_1/2")

            offset = handler.page_bit_offset
            offset += subheader_pointers_offset
            offset += (handler.current_page_subheaders_count * subheader_pointer_length)

            align_correction = offset % 8
            offset += align_correction

            # hack for stat_transfer files
            if align_correction == 4 && handler.vendor == VENDOR_STAT_TRANSFER
                # println3(handler, "alignment hack, vendor=$(handler.vendor) align_correction=$align_correction")
                offset -= align_correction
            end

            # locate the row
            offset += handler.current_row_in_page_index * handler.row_length

            process_byte_array_with_data(handler, offset, handler.row_length, handler.compression)
            mn = min(handler.row_count, handler.mix_page_row_count)
            # println("    handler.current_row_in_page_index=$(handler.current_row_in_page_index)")
            # println("    mn = $mn")
            if handler.current_row_in_page_index == mn
                # println("    reading next page")
                done = read_next_page(handler)
                if done
                    # println("    all done, returning #2")
                    return true
                end
            end
            return false
        elseif handler.current_page_type == page_data_type
            #println("    page type == page_data_type")
            process_byte_array_with_data(handler,
                handler.page_bit_offset + subheader_pointers_offset +
                handler.current_row_in_page_index * handler.row_length,
                handler.row_length,
                handler.compression)
            # println("    handler.current_row_in_page_index=$(handler.current_row_in_page_index)")
            # println("    handler.current_page_block_count=$(handler.current_page_block_count)")
            flag = (handler.current_row_in_page_index == handler.current_page_block_count)
            #println("$(handler.current_row_in_page_index) $(handler.current_page_block_count)")
            if flag
                # println("    reading next page")
                done = read_next_page(handler)
                if done
                    # println("    all done, returning #3")
                    return true
                end
            end
            return false
        else
            throw(FileFormatError("unknown page type: $(handler.current_page_type)"))
        end
    end
end

function process_byte_array_with_data(handler, offset, length, compression)

    # println("IN: process_byte_array_with_data, offset=$offset, length=$length")

    # Original code below.  Julia type is already Vector{UInt8}
    # source = np.frombuffer(
    #     handler.cached_page[offset:offset + length], dtype=np.uint8)
    source = handler.cached_page[offset+1:offset+length]

    # TODO decompression
    # if handler.decompress != NULL and (length < handler.row_length)
    # println("  length=$length")
    # println("  handler.row_length=$(handler.row_length)")
    if length < handler.row_length
        if compression == compression_method_rle
            # println3(handler, "decompress using rle_compression method, length=$length, row_length=$(handler.row_length)")
            source = rle_decompress(handler.row_length, source)
        elseif compression == compression_method_rdc
            # println3(handler, "decompress using rdc_compression method, length=$length, row_length=$(handler.row_length)")
            source = rdc_decompress(handler.row_length, source)
        else
            # println3(handler, "process_byte_array_with_data")
            # println3(handler, "  length=$length")
            # println3(handler, "  handler.row_length=$(handler.row_length)")
            # println3(handler, "  source=$source")
            throw(FileFormatError("Unknown compression method: $(handler.compression)"))
        end
    end

    current_row = handler.current_row_in_chunk_index
    s = 8 * current_row

    # TODO PERF there's not reason to deference by name everytime.
    #    Ideally, we can still go by the result's column index
    #    and then only at the very end (outer loop) we assign them to
    #    the column symbols
    @inbounds for (k, name, ty) in handler.column_indices
        lngt = handler.column_data_lengths[k]
        start = handler.column_data_offsets[k]
        ct = handler.column_types[k]
        if ct == column_type_decimal
            # The data may have 3,4,5,6,7, or 8 bytes (lngt)
            # and we need to copy into an 8-byte destination.
            # Hence endianness matters - for Little Endian file
            # copy it to the right side, else left side.
            if handler.file_endianness == :LittleEndian
                m = s + 8 - lngt
            else
                m = s
            end
            # if current_row == 0 && k == 1
            #     println3(handler, "First cell:")
            #     println3(handler, "  k=$k name=$name ty=$ty")
            #     println3(handler, "  s=$s m=$m lngt=$lngt start=$start")
            #     println3(handler, "  source =$(source[start+1:start+lngt])")
            # end
            dst = handler.byte_chunk[name]
            for i in 1:lngt
                @inbounds dst[m + i] = source[start + i]
            end
            # @inbounds handler.byte_chunk[name][m+1:m+lngt] = source[start+1:start+lngt]
            #println3(handler, "byte_chunk[$name][$(m+1):$(m+lngt)] = source[$(start+1):$(start+lngt)] => $(source[start+1:start+lngt])")
        elseif ct == column_type_string
            # issue 12 - heuristic for switching to regular Array type
            ar = handler.string_chunk[name]
            if  handler.current_row_in_chunk_index > 2000 &&
                    handler.current_row_in_chunk_index % 200 == 0 &&
                    isa(ar, ObjectPool) &&
                    ar.uniqueitemscount / ar.itemscount > 0.10
                println2(handler, "Bumping column $(name) to regular array due to too many unique items $(ar.uniqueitemscount) out of $(ar.itemscount)")
                ar = Array(ar)
                handler.string_chunk[name] = ar
            end
            pos = lastcharpos(source, start, lngt)
            @inbounds ar[current_row+1] =
                # rstrip2(transcode_data(handler, source, start+1, start+lngt, lngt))
                transcode_data(handler, source, start+1, start+pos, pos)
        end
    end

    handler.current_row_in_page_index += 1
    handler.current_row_in_chunk_index += 1
    handler.current_row_in_file_index += 1
end

# Notes about performance enhancement related to stripping off space characters.
#
# Apparently SAS always use 0x20 (space) even for non-ASCII encodings
# but what if 0x20 happens to be there as part of a multi-byte encoding?
# ```
# julia> decode([0x02, 0x20], "UTF-16")
# "Ƞ"
# ````
#
# Knowing that we can only understand a certain set of char encodings as in
# the constants.jl file, we just need to make sure that the ones that we
# support does not use 0x20 as part of any multi-byte chars.
#
# Seems ok. Some info available at
# https://www.debian.org/doc/manuals/intro-i18n/ch-codes.en.html
#
# find the last char position that is not space
function lastcharpos(source::Vector{UInt8}, start::Int64, lngt::Int64)
    i = lngt
    while i ≥ 1
        if source[start + i] != 0x20
            break
        end
        i -= 1
    end
    return i
end

# TODO possible issue with the 7-bit check... maybe not all encodings are ascii compatible for 7-bit values?
# Use unsafe_string to avoid bounds check for performance reason
# Use custom decode_string function with our own decoder/decoder buffer to avoid unncessary objects creation
@inline transcode_data(handler::Handler, source::Vector{UInt8}, startidx::Int64, endidx::Int64, lngt::Int64) =
    handler.use_base_transcoder || seven_bit_data(source, startidx, endidx) ?
        unsafe_string(pointer(source) + startidx - 1, lngt) :
        decode_string(source, startidx, endidx, handler.string_decoder_buffer, handler.string_decoder)
        #decode_string2(source[startidx:endidx], handler.file_encoding)

# metadata is always ASCII-based (I think)
@inline transcode_metadata(bytes::Vector{UInt8}) =
    Base.transcode(String, bytes)

# determine if string data contains only 7-bit characters
@inline function seven_bit_data(source::Vector{UInt8}, startidx::Int64, endidx::Int64)
    for i in startidx:endidx
        if source[i] > 0x7f
            return false
        end
    end
    true
end

@inline function decode_string(source::Vector{UInt8}, startidx::Int64, endidx::Int64, io::IOBuffer, decoder::StringDecoder)
    truncate(io, 0)
    for i in startidx:endidx
        write(io, source[i])
    end
    seek(io, 0)
    str = String(Base.read(decoder))
    # println("decoded ", str)
    str
end

# @inline function decode_string2(bytes, encoding)
#     decode(bytes, encoding)
# end

# Courtesy of ReadStat project
# https://github.com/WizardMac/ReadStat

const SAS_RLE_COMMAND_COPY64          = 0
const SAS_RLE_COMMAND_INSERT_BYTE18   = 4
const SAS_RLE_COMMAND_INSERT_AT17     = 5
const SAS_RLE_COMMAND_INSERT_BLANK17  = 6
const SAS_RLE_COMMAND_INSERT_ZERO17   = 7
const SAS_RLE_COMMAND_COPY1           = 8
const SAS_RLE_COMMAND_COPY17          = 9
const SAS_RLE_COMMAND_COPY33          = 10 # 0x0A
const SAS_RLE_COMMAND_COPY49          = 11 # 0x0B
const SAS_RLE_COMMAND_INSERT_BYTE3    = 12 # 0x0C
const SAS_RLE_COMMAND_INSERT_AT2      = 13 # 0x0D
const SAS_RLE_COMMAND_INSERT_BLANK2   = 14 # 0x0E
const SAS_RLE_COMMAND_INSERT_ZERO2    = 15 # 0x0F

function rle_decompress(output_len,  input::Vector{UInt8})
    #error("stopped for debugging $output_len $input")
    input_len = length(input)
    output = zeros(UInt8, output_len)
    # logdebug("rle_decompress: output_len=$output_len, input_len=$input_len")

    ipos = 1
    rpos = 1
    while ipos <= input_len
        control = input[ipos]
        ipos += 1
        command = (control & 0xF0) >> 4
        dlen    = (control & 0x0F)
        copy_len = 0
        insert_len = 0
        insert_byte = 0x00
        if command == SAS_RLE_COMMAND_COPY64
            # logdebug("  SAS_RLE_COMMAND_COPY64")
            copy_len = input[ipos] + 64 + dlen * 256
            ipos += 1
        elseif command == SAS_RLE_COMMAND_INSERT_BYTE18
            # logdebug("  SAS_RLE_COMMAND_INSERT_BYTE18")
            insert_len  = input[ipos] + 18 + dlen * 16
            ipos += 1
            insert_byte = input[ipos]
            ipos += 1
        elseif command == SAS_RLE_COMMAND_INSERT_AT17
            # logdebug("  SAS_RLE_COMMAND_INSERT_AT17")
            insert_len  = input[ipos] + 17 + dlen * 256
            insert_byte = 0x40   # char: @
            ipos += 1
        elseif command == SAS_RLE_COMMAND_INSERT_BLANK17
            # logdebug("  SAS_RLE_COMMAND_INSERT_BLANK17")
            insert_len  = input[ipos] + 17 + dlen * 256
            insert_byte = 0x20   # char: <space>
            ipos += 1
        elseif command == SAS_RLE_COMMAND_INSERT_ZERO17
            # logdebug("  SAS_RLE_COMMAND_INSERT_ZERO17")
            insert_len  = input[ipos] + 17 + dlen * 256
            insert_byte = 0x00
            ipos += 1
        elseif command == SAS_RLE_COMMAND_COPY1
            # logdebug("  SAS_RLE_COMMAND_COPY1")
            copy_len = dlen + 1
        elseif command == SAS_RLE_COMMAND_COPY17
            # logdebug("  SAS_RLE_COMMAND_COPY17")
            copy_len = dlen + 17
        elseif command == SAS_RLE_COMMAND_COPY33
            # logdebug("  SAS_RLE_COMMAND_COPY33")
            copy_len = dlen + 33
        elseif command == SAS_RLE_COMMAND_COPY49
            # logdebug("  SAS_RLE_COMMAND_COPY49")
            copy_len = dlen + 49
        elseif command == SAS_RLE_COMMAND_INSERT_BYTE3
            # logdebug("  SAS_RLE_COMMAND_INSERT_BYTE3")
            insert_len  = dlen + 3
            insert_byte = input[ipos]
            ipos += 1
        elseif command == SAS_RLE_COMMAND_INSERT_AT2
            # logdebug("  SAS_RLE_COMMAND_INSERT_AT2")
            insert_len  = dlen + 2
            insert_byte = 0x40   # char: @
        elseif command == SAS_RLE_COMMAND_INSERT_BLANK2
            # logdebug("  SAS_RLE_COMMAND_INSERT_BLANK2")
            insert_len  = dlen + 2
            insert_byte = 0x20   # char: <space>
        elseif command == SAS_RLE_COMMAND_INSERT_ZERO2
            # logdebug("  SAS_RLE_COMMAND_INSERT_ZERO2")
            insert_len  = dlen + 2
            insert_byte = 0x00   # char: @
        end
        if copy_len > 0
            # logdebug("  ipos=$ipos rpos=$rpos copy_len=$copy_len => output[$rpos:$(rpos+copy_len-1)] = input[$ipos:$(ipos+copy_len-1)]")
            for i in 0:copy_len-1
                output[rpos + i] = input[ipos + i]
                #output[rpos:rpos+copy_len-1] = input[ipos:ipos+copy_len-1]
            end
            rpos += copy_len
            ipos += copy_len
        end
        if insert_len > 0
            # logdebug("  ipos=$ipos rpos=$rpos insert_len=$insert_len insert_byte=0x$(hex(insert_byte))")
            for i in 0:insert_len-1
                output[rpos + i] = insert_byte
                #output[rpos:rpos+insert_len-1] = insert_byte
            end
            rpos += insert_len
        end
    end
    output
end

# rdc_decompress decompresses data using the Ross Data Compression algorithm:
#
# http://collaboration.cmc.ec.gc.ca/science/rpn/biblio/ddj/Website/articles/CUJ/1992/9210/ross/ross.htm
function rdc_decompress(result_length, inbuff::Vector{UInt8})

	ctrl_bits = UInt16(0)
    ctrl_mask = UInt16(0)
    ipos = 1
    rpos = 1
    outbuff = zeros(UInt8, result_length)

    while ipos <= length(inbuff)

        ctrl_mask = ctrl_mask >> 1
        if ctrl_mask == 0
            ctrl_bits = (UInt16(inbuff[ipos]) << 8) + UInt16(inbuff[ipos + 1])
            ipos += 2
            ctrl_mask = 0x8000
        end

        if ctrl_bits & ctrl_mask == 0
            outbuff[rpos] = inbuff[ipos]
            ipos += 1
            rpos += 1
            continue
        end

        cmd = (inbuff[ipos] >> 4) & 0x0F
        cnt = UInt16(inbuff[ipos] & 0x0F)
        ipos += 1

        # short RLE
        if cmd == 0
            cnt += 3
            for k in 0:cnt-1
                outbuff[rpos + k] = inbuff[ipos]
            end
            rpos += cnt
            ipos += 1

        # long RLE
        elseif cmd == 1
            cnt += UInt16(inbuff[ipos]) << 4
            cnt += 19
            ipos += 1
            for k in 0:cnt-1
                outbuff[rpos + k] = inbuff[ipos]
            end
            rpos += cnt
            ipos += 1

        # long pattern
        elseif cmd == 2
            ofs = cnt + 3
            ofs += UInt16(inbuff[ipos]) << 4
            ipos += 1
            cnt = UInt16(inbuff[ipos])
            ipos += 1
            cnt += 16
            for k in 0:cnt-1
                outbuff[rpos + k] = outbuff[rpos - ofs + k]
            end
            rpos += cnt

        # short pattern
        elseif (cmd >= 3) & (cmd <= 15)
            ofs = cnt + 3
            ofs += UInt16(inbuff[ipos]) << 4
            ipos += 1
            for k in 0:cmd-1
                outbuff[rpos + k] = outbuff[rpos - ofs + k]
            end
            rpos += cmd

        else
            throw(FileFormatError("unknown RDC command"))
        end
    end

    if length(outbuff) != result_length
        throw(FileFormatError("RDC: $(length(outbuff)) != $result_length"))
    end

    return outbuff
end

# ---- Debugging methods ----

# verbose printing.  1=little verbose, 2=medium verbose, 3=very verbose, 4=very very verbose :-)
@inline println1(handler::Handler, msg::String) = handler.config.verbose_level >= 1 && println(msg)
@inline println2(handler::Handler, msg::String) = handler.config.verbose_level >= 2 && println(msg)
@inline println3(handler::Handler, msg::String) = handler.config.verbose_level >= 3 && println(msg)
logdebug = println

# string representation of the SubHeaderPointer structure
# function tostring(x::SubHeaderPointer)
#   "<SubHeaderPointer: offset=$(x.offset), length=$(x.length), compression=$(x.compression), type=$(x.shtype)>"
# end

# Return the current position in various aspects (file, page, chunk)
# This is useful for debugging purpose especially during incremental reads.
# function currentpos(handler)
#     d = Dict()
#     if isdefined(handler, :current_row_in_file_index)
#         d[:current_row_in_file] = handler.current_row_in_file_index
#     end
#     if isdefined(handler, :current_row_in_page_index)
#         d[:current_row_in_page] = handler.current_row_in_page_index
#     end
#     if isdefined(handler, :current_row_in_chunk_index)
#         d[:current_row_in_chunk] = handler.current_row_in_chunk_index
#     end
#     return d
# end

# case insensitive column mapping
Base.lowercase(s::Symbol) = Symbol(lowercase(String(s)))
case_insensitive_in(s::Symbol, ar::AbstractArray) =
    lowercase(s) in [x isa Symbol ? lowercase(x) : x for x in ar]

# fill column indices as a dictionary (key = column index, value = column symbol)
function populate_column_indices(handler)
    handler.column_indices = Vector{Tuple{Int64, Symbol, UInt8}}()
    inflag = length(handler.config.include_columns) > 0
    exflag = length(handler.config.exclude_columns) > 0
    inflag && exflag && throw(ConfigError("You can specify either include_columns or exclude_columns but not both."))
    processed = []
    # println("handler.column_symbols = $(handler.column_symbols) len=$(length(handler.column_symbols))")
    # println("handler.column_types = $(handler.column_types) len=$(length(handler.column_types))")
    for j in 1:length(handler.column_symbols)
        name = handler.column_symbols[j]
        if inflag
            if j in handler.config.include_columns ||
                    case_insensitive_in(name, handler.config.include_columns)
                push!(handler.column_indices, (j, name, handler.column_types[j]))
                push!(processed, lowercase(name))
            end
        elseif exflag
            if !(j in handler.config.exclude_columns ||
                    case_insensitive_in(name, handler.config.exclude_columns))
                push!(handler.column_indices, (j, name, handler.column_types[j]))
            else
                push!(processed, lowercase(name))
            end
        else
            push!(handler.column_indices, (j, name, handler.column_types[j]))
        end
    end
    if inflag && length(processed) != length(handler.config.include_columns)
        diff = setdiff(handler.config.include_columns, processed)
        for c in diff
            @warn("Unknown include column $c")
        end
    end
    if exflag && length(processed) != length(handler.config.exclude_columns)
        diff = setdiff(handler.config.exclude_columns, processed)
        for c in diff
            @warn("Unknown exclude column $c")
        end
    end
    # println2(handler, "column_indices = $(handler.column_indices)")
end

function _determine_vendor(handler::Handler)
    # convert a release string into "9.0401M1" into 3 separate numbers
    (version, revision) = split(handler.sas_release, "M")
    (major, minor) = split(version, ".")
    (major, minor, revision) = parse.(Int, (major, minor, revision))

    if major == 9 && minor == 0 && revision == 0
        # A bit of a hack, but most SAS installations are running a minor update
        handler.vendor = VENDOR_STAT_TRANSFER
    else
        handler.vendor = VENDOR_SAS
    end
end

# Populate column names after all meta info is read
function populate_column_names(handler)
    for cnp in handler.column_name_pointers
        if cnp.index > length(handler.column_names_strings)
            name = "unknown_$(cnp.index)_$(cnp.offset)"
        else
            name_str = handler.column_names_strings[cnp.index]
            name = transcode_metadata(name_str[cnp.offset+1:cnp.offset + cnp.length])
        end
        push!(handler.column_names, name)
        push!(handler.column_symbols, Symbol(name))
    end
    # println("column_names=", handler.column_names)
    # println("column_symbols=", handler.column_symbols)
end

# Returns current page type as a string at the current state
function current_page_type_str(handler)
    pt = _read_int(handler, handler.page_bit_offset, page_type_length)
    return page_type_str(pt)
end

# Convert page type value to human readable string
function page_type_str(pt)
    if pt == page_meta_type return "META"
    elseif pt == page_amd_type return "AMD"
    elseif pt == page_data_type return "DATA"
    elseif pt in page_mix_types return "MIX"
    else return "UNKNOWN $(pt)"
    end
end

# Go back and read the first page again and be ready for read
# This is needed after all metadata is written and the system needs to rewind
function read_first_page(handler)
    seek(handler.io, handler.header_length)
    my_read_next_page(handler)
end

# Initialize handler object
function init_handler(handler)
    handler.compression = compression_method_none
    handler.column_names_strings = []
    handler.column_names = []
    handler.column_symbols = []
    handler.column_name_pointers = []
    handler.column_formats = []
    handler.column_types = []
    handler.column_data_lengths = []
    handler.column_data_offsets = []
    handler.current_page_data_subheader_pointers = []
    handler.current_row_in_file_index = 0
    handler.current_row_in_chunk_index = 0
    handler.current_row_in_page_index = 0
    handler.current_page = 0
end

Base.show(io::IO, h::Handler) = print(io, "SASLib.Handler[", h.config.filename, "]")

end # module
