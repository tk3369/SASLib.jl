"""
Sample usage:

```julia
import SASLib
df = SASLib.read_sas7bdat("whatever.sas7bdat")
```

```julia
df = SASLib.read_sas7bdat("whatever.sas7bdat", Dict(
        :encoding => "UTF-8"
        :chunksize => 1,
        :convert_dates => true,
        :convert_empty_string_to_missing => true,
        :convert_text => true,
        :convert_header_text => true
        ))
```

"""
module SASLib

using StringEncodings

export readsas,
    ReaderConfig, Handler, openfile, readfile, close

include("constants.jl")
include("utils.jl")

struct FileFormatError <: Exception
    message::AbstractString
end 

# NOTE there's no "index" for Julia's DataFrame as compared to Pandas
struct ReaderConfig 
    filename::AbstractString
    encoding::AbstractString
    chunksize::UInt8
    convert_dates::Bool
    convert_empty_string_to_missing::Bool
    convert_text::Bool
    convert_header_text::Bool
    ReaderConfig(filename, config = Dict()) = new(filename, 
        get(config, :encoding, default_encoding),
        get(config, :chunksize, default_chunksize),
        get(config, :convert_dates, default_convert_dates), 
        get(config, :convert_empty_string_to_missing, default_convert_empty_string_to_missing),
        get(config, :convert_text, default_convert_text), 
        get(config, :convert_header_text, default_convert_header_text))
end

mutable struct Handler
    config::ReaderConfig
    
    compression::AbstractString
    column_names_strings::Array{AbstractString,1}
    column_names::Array{AbstractString,1}
    column_types::Array{AbstractString,1}
    column_formats::Array{AbstractString,1}
    columns::Array{AbstractString,1}
    
    _current_page_data_subheader_pointers::Array{Any}
    _cached_page::Array{UInt8,1}
    _column_data_lengths::Array{Any}
    _column_data_offsets::Array{Any}
    _current_row_in_file_index::UInt64
    _current_row_on_page_index::UInt64

    io::IOStream

    state::Dict{Symbol, Any}
    x::Any # TODO - debug only, removed later

    Handler(config::ReaderConfig) = new(config,
        "", [], [], [], [], [],
        [], [], [], [], 0, 0,
        Base.open(config.filename),
        Dict{Symbol, Any}(),
        nothing
        )
end

"""
Returns a Handler struct
"""
function openfile(config::ReaderConfig) 
    # info("Opening $(config.filename)")
    Handler(config)
end

function readfile(handler) 
    info("Reading $(handler.config.filename)")
    return handler  # TODO not returning any real data until later
end

function closefile(handler) 
    # info("Closing $(handler.config.filename)")
    close(handler.io)
end

function readsas(filename; config = Dict())
    handler = openfile(ReaderConfig(filename, config))
    try
        properties = _get_properties(handler)
        return readfile(handler)
    finally
        closefile(handler)
    end
end

# Read a single float of the given width (4 or 8).
function _read_float(handler, offset, width)
    if !(width in [4, 8])
        throw(ArgumentError("invalid float width $(width)"))
    end
    buf = _read_bytes(handler, offset, width)
    value = reinterpret(width == 4 ? Float32 : Float64, buf)[1]
    if (handler.state[:byte_swap])
        value = bswap(value)
    end
    return value
end

# Read a single signed integer of the given width (1, 2, 4 or 8).
function _read_int(handler, offset, width)
    if !(width in [1, 2, 4, 8])
        throw(ArgumentError("invalid int width $(width)"))
    end
    buf = _read_bytes(handler, offset, width)
    value = reinterpret(Dict(1 => Int8, 2 => Int16, 4 => Int32, 8 => Int64)[width], buf)[1]
    if (handler.state[:byte_swap])
        value = bswap(value)
    end
    return value
end

function _read_bytes(handler, offset, len)
    if handler._cached_page == []
        seek(handler.io, offset)
        try
            return read(handler.io, len)
        catch
            throw(FileFormatError("Unable to read $(len) bytes from file position $(offset)"))
        end
    else
        if offset + len > length(handler._cached_page)
            throw(FileFormatError(
                "The cached page $(length(handler._cached_page)) is too small " *
                "to read for range positions $offset to $len"))
        end
        return handler._cached_page[offset+1:offset+len]  #offset is 0-based
    end
end

function _get_properties(handler)

    io = handler.io 

    # read header section
    seekstart(io)
    handler._cached_page = read(io, 288)

    # Initiate state
    state = handler.state = Dict{Symbol, Any}()

    # Check magic number
    if handler._cached_page[1:length(magic)] != magic
        throw(FileFormatError("magic number mismatch (not a SAS file?)"))
    end
    info("good magic number")
    
    # Get alignment information
    align1, align2 = 0, 0
    buf = _read_bytes(handler, align_1_offset, align_1_length)
    if buf == u64_byte_checker_value
        align2 = align_2_value
        state[:U64] = true
        state[:int_length] = 8
        state[:page_bit_offset] = page_bit_offset_x64
        state[:subheader_pointer_length] = subheader_pointer_length_x64
    else
        state[:U64] = false
        state[:page_bit_offset] = page_bit_offset_x86
        state[:subheader_pointer_length] = subheader_pointer_length_x86
        state[:int_length] = 4
    end
    buf = _read_bytes(handler, align_2_offset, align_2_length)
    if buf == align_1_checker_value
        align1 = align_2_value
    end
    total_align = align1 + align2
    info("successful reading alignment information")
    info("buf = $buf, align1 = $align1, align2 = $align2, total_align=$total_align, state=$(state)")

    # Get endianness information
    buf = _read_bytes(handler, endianness_offset, endianness_length)
    if buf == b"\x01"
        state[:file_endianness] = :LittleEndian
    else
        state[:file_endianness] = :BigEndian
    end
    info("file_endianness = $(state[:file_endianness])")
    
    # Detect system-endianness and determine if byte swap will be required
    state[:sys_endianness] = ENDIAN_BOM == 0x04030201 ? :LittleEndian : :BigEndian
    info("system endianess = $(state[:sys_endianness])")

    state[:byte_swap] = state[:sys_endianness] != state[:file_endianness]
    info("byte_swap = $(state[:byte_swap])")
        
    # Get encoding information
    buf = _read_bytes(handler, encoding_offset, encoding_length)[1]
    if haskey(encoding_names, buf)
        state[:file_encoding] = encoding_names[buf]
    else
        state[:file_encoding] = "unknown (code=$buf)" 
    end
    info("file_encoding = $(state[:file_encoding])")

    # Get platform information
    buf = _read_bytes(handler, platform_offset, platform_length)
    if buf == b"1"
        state[:platform] = "unix"
    elseif buf == b"2"
        state[:platform] = "windows"
    else
        state[:platform] = "unknown"
    end
    info("platform = $(state[:platform])")

    buf = _read_bytes(handler, dataset_offset, dataset_length)
    state[:name] = brstrip(buf, b"\x00 ")
    if handler.config.convert_header_text
        info("before decode: name = $(state[:name])")
        state[:name] = decode(state[:name], handler.config.encoding)
        info("after decode:  name = $(state[:name])")
    end

    buf = _read_bytes(handler, file_type_offset, file_type_length)
    state[:file_type] = brstrip(buf, b"\x00 ")
    if handler.config.convert_header_text
        info("before decode: file_type = $(state[:file_type])")
        state[:file_type] = decode(state[:file_type], handler.config.encoding)
        info("after decode:  file_type = $(state[:file_type])")
    end

    # Timestamp is epoch 01/01/1960
    epoch =DateTime(1960, 1, 1, 0, 0, 0)
    x = _read_float(handler, date_created_offset + align1, date_created_length)
    state[:date_created] = epoch + Base.Dates.Millisecond(round(x * 1000))
    info("date created = $(x) => $(state[:date_created])")
    x = _read_float(handler, date_modified_offset + align1, date_modified_length)
    state[:date_modified] = epoch + Base.Dates.Millisecond(round(x * 1000))
    info("date modified = $(x) => $(state[:date_modified])")
    
    state[:header_length] = _read_int(handler, header_size_offset + align1, header_size_length)

    # Read the rest of the header into cached_page.
    buf = read(io, state[:header_length] - 288)
    append!(handler._cached_page, buf)
    if length(handler._cached_page) != state[:header_length]
        throw(FileFormatError("The SAS7BDAT file appears to be truncated."))
    end

    state[:page_length] = _read_int(handler, page_size_offset + align1, page_size_length)
    info("page_length = $(state[:page_length])")

    state[:page_count] = _read_int(handler, page_count_offset + align1, page_count_length)
    info("page_count = $(state[:page_count])")
    
    buf = _read_bytes(handler, sas_release_offset + total_align, sas_release_length)
    state[:sas_release] = brstrip(buf, b"\x00 ")
    if handler.config.convert_header_text
        state[:sas_release] = decode(state[:sas_release], handler.config.encoding)
    end
    info("SAS Release = $(state[:sas_release])")

    buf = _read_bytes(handler, sas_server_type_offset + total_align, sas_server_type_length)
    state[:server_type] = brstrip(buf, b"\x00 ")
    if handler.config.convert_header_text
        state[:server_type] = decode(state[:server_type], handler.config.encoding)
    end
    info("server_type = $(state[:server_type])")

    buf = _read_bytes(handler, os_version_number_offset + total_align, os_version_number_length)
    state[:os_version] = brstrip(buf, b"\x00 ")
    if handler.config.convert_header_text
        state[:os_version] = decode(state[:os_version], handler.config.encoding)
    end
    info("os_version = $(state[:os_version])")
    
    buf = _read_bytes(handler, os_name_offset + total_align, os_name_length)
    buf = brstrip(buf, b"\x00 ")
    if length(buf) > 0
        state[:os_name] = decode(buf, handler.config.encoding)
    else
        buf = _read_bytes(handler, os_maker_offset + total_align, os_maker_length)
        state[:os_name] = brstrip(buf, b"\x00 ")
        if handler.config.convert_header_text
            state[:os_name] = decode(state[:os_name], handler.config.encoding)
        end
    end
    info("os_name = $(state[:os_name])")
end

function _parse_metadata(handler)
    done = false
    while !done
        handler._cached_page = read(handler.io, handler.state[:page_length])
        if length(handler._cached_page) <= 0
            break
        end
        if length(handler._cached_page) != handler.state[:page_length]
            throw(FileFormatError("Failed to read a meta data page from the SAS file."))
        end
        done = _process_page_meta(handler)
    end
end

function _process_page_meta(handler)
    _read_page_header(handler)  
    state = handler.state
    pt = [page_meta_type, page_amd_type] + page_mix_types
    if state[:current_page_type] in pt
        _process_page_metadata(handler)
    end
    return ((state[:current_page_type] in [256] + page_mix_types) ||
            (handler._current_page_data_subheader_pointers != []))
end

function _read_page_header(handler)
    state = handler.state
    bit_offset = state[:page_bit_offset]
    tx = page_type_offset + bit_offset
    state[:_current_page_type] = _read_int(handler, tx, page_type_length)
    tx = block_count_offset + bit_offset
    state[:current_page_block_count] = _read_int(handler, tx, block_count_length)
    tx = subheader_count_offset + bit_offset
    state[:current_page_subheaders_count] = _read_int(handler, tx, subheader_count_length)
end

function _process_page_metadata(handler)
end

# def _process_page_metadata(self):
# bit_offset = self._page_bit_offset

# for i in range(self._current_page_subheaders_count):
#     pointer = self._process_subheader_pointers(
#         const.subheader_pointers_offset + bit_offset, i)
#     if pointer.length == 0:
#         continue
#     if pointer.compression == const.truncated_subheader_id:
#         continue
#     subheader_signature = self._read_subheader_signature(
#         pointer.offset)
#     subheader_index = (
#         self._get_subheader_index(subheader_signature,
#                                   pointer.compression, pointer.ptype))
#     self._process_subheader(subheader_index, pointer)

# def _get_subheader_index(self, signature, compression, ptype):
# index = const.subheader_signature_to_index.get(signature)
# if index is None:
#     f1 = ((compression == const.compressed_subheader_id) or
#           (compression == 0))
#     f2 = (ptype == const.compressed_subheader_type)
#     if (self.compression != "") and f1 and f2:
#         index = const.index.dataSubheaderIndex
#     else:
#         self.close()
#         raise ValueError("Unknown subheader signature")
# return index

# def _process_subheader_pointers(self, offset, subheader_pointer_index):

# subheader_pointer_length = self._subheader_pointer_length
# total_offset = (offset +
#                 subheader_pointer_length * subheader_pointer_index)

# subheader_offset = self._read_int(total_offset, self._int_length)
# total_offset += self._int_length

# subheader_length = self._read_int(total_offset, self._int_length)
# total_offset += self._int_length

# subheader_compression = self._read_int(total_offset, 1)
# total_offset += 1

# subheader_type = self._read_int(total_offset, 1)

# x = _subheader_pointer()
# x.offset = subheader_offset
# x.length = subheader_length
# x.compression = subheader_compression
# x.ptype = subheader_type

# return x

# def _read_subheader_signature(self, offset):
# subheader_signature = self._read_bytes(offset, self._int_length)
# return subheader_signature

# def _process_subheader(self, subheader_index, pointer):
# offset = pointer.offset
# length = pointer.length

# if subheader_index == const.index.rowSizeIndex:
#     processor = self._process_rowsize_subheader
# elif subheader_index == const.index.columnSizeIndex:
#     processor = self._process_columnsize_subheader
# elif subheader_index == const.index.columnTextIndex:
#     processor = self._process_columntext_subheader
# elif subheader_index == const.index.columnNameIndex:
#     processor = self._process_columnname_subheader
# elif subheader_index == const.index.columnAttributesIndex:
#     processor = self._process_columnattributes_subheader
# elif subheader_index == const.index.formatAndLabelIndex:
#     processor = self._process_format_subheader
# elif subheader_index == const.index.columnListIndex:
#     processor = self._process_columnlist_subheader
# elif subheader_index == const.index.subheaderCountsIndex:
#     processor = self._process_subheader_counts
# elif subheader_index == const.index.dataSubheaderIndex:
#     self._current_page_data_subheader_pointers.append(pointer)
#     return
# else:
#     raise ValueError("unknown subheader index")

# processor(offset, length)

# def _process_rowsize_subheader(self, offset, length):

# int_len = self._int_length
# lcs_offset = offset
# lcp_offset = offset
# if self.U64:
#     lcs_offset += 682
#     lcp_offset += 706
# else:
#     lcs_offset += 354
#     lcp_offset += 378

# self.row_length = self._read_int(
#     offset + const.row_length_offset_multiplier * int_len, int_len)
# self.row_count = self._read_int(
#     offset + const.row_count_offset_multiplier * int_len, int_len)
# self.col_count_p1 = self._read_int(
#     offset + const.col_count_p1_multiplier * int_len, int_len)
# self.col_count_p2 = self._read_int(
#     offset + const.col_count_p2_multiplier * int_len, int_len)
# mx = const.row_count_on_mix_page_offset_multiplier * int_len
# self._mix_page_row_count = self._read_int(offset + mx, int_len)
# self._lcs = self._read_int(lcs_offset, 2)
# self._lcp = self._read_int(lcp_offset, 2)

# def _process_columnsize_subheader(self, offset, length):
# int_len = self._int_length
# offset += int_len
# self.column_count = self._read_int(offset, int_len)
# if (self.col_count_p1 + self.col_count_p2 !=
#         self.column_count):
#     print("Warning: column count mismatch (%d + %d != %d)\n",
#           self.col_count_p1, self.col_count_p2, self.column_count)

# # Unknown purpose
# def _process_subheader_counts(self, offset, length):
# pass

# def _process_columntext_subheader(self, offset, length):

# offset += self._int_length
# text_block_size = self._read_int(offset, const.text_block_size_length)

# buf = self._read_bytes(offset, text_block_size)
# cname_raw = buf[0:text_block_size].rstrip(b"\x00 ")
# cname = cname_raw
# if self.convert_header_text:
#     cname = cname.decode(self.encoding or self.default_encoding)
# self.column_names_strings.append(cname)

# if len(self.column_names_strings) == 1:
#     compression_literal = ""
#     for cl in const.compression_literals:
#         if cl in cname_raw:
#             compression_literal = cl
#     self.compression = compression_literal
#     offset -= self._int_length

#     offset1 = offset + 16
#     if self.U64:
#         offset1 += 4

#     buf = self._read_bytes(offset1, self._lcp)
#     compression_literal = buf.rstrip(b"\x00")
#     if compression_literal == "":
#         self._lcs = 0
#         offset1 = offset + 32
#         if self.U64:
#             offset1 += 4
#         buf = self._read_bytes(offset1, self._lcp)
#         self.creator_proc = buf[0:self._lcp]
#     elif compression_literal == const.rle_compression:
#         offset1 = offset + 40
#         if self.U64:
#             offset1 += 4
#         buf = self._read_bytes(offset1, self._lcp)
#         self.creator_proc = buf[0:self._lcp]
#     elif self._lcs > 0:
#         self._lcp = 0
#         offset1 = offset + 16
#         if self.U64:
#             offset1 += 4
#         buf = self._read_bytes(offset1, self._lcs)
#         self.creator_proc = buf[0:self._lcp]
#     if self.convert_header_text:
#         if hasattr(self, "creator_proc"):
#             self.creator_proc = self.creator_proc.decode(
#                 self.encoding or self.default_encoding)

# def _process_columnname_subheader(self, offset, length):
# int_len = self._int_length
# offset += int_len
# column_name_pointers_count = (length - 2 * int_len - 12) // 8
# for i in range(column_name_pointers_count):
#     text_subheader = offset + const.column_name_pointer_length * \
#         (i + 1) + const.column_name_text_subheader_offset
#     col_name_offset = offset + const.column_name_pointer_length * \
#         (i + 1) + const.column_name_offset_offset
#     col_name_length = offset + const.column_name_pointer_length * \
#         (i + 1) + const.column_name_length_offset

#     idx = self._read_int(
#         text_subheader, const.column_name_text_subheader_length)
#     col_offset = self._read_int(
#         col_name_offset, const.column_name_offset_length)
#     col_len = self._read_int(
#         col_name_length, const.column_name_length_length)

#     name_str = self.column_names_strings[idx]
#     self.column_names.append(name_str[col_offset:col_offset + col_len])

# def _process_columnattributes_subheader(self, offset, length):
# int_len = self._int_length
# column_attributes_vectors_count = (
#     length - 2 * int_len - 12) // (int_len + 8)
# self.column_types = np.empty(
#     column_attributes_vectors_count, dtype=np.dtype('S1'))
# self._column_data_lengths = np.empty(
#     column_attributes_vectors_count, dtype=np.int64)
# self._column_data_offsets = np.empty(
#     column_attributes_vectors_count, dtype=np.int64)
# for i in range(column_attributes_vectors_count):
#     col_data_offset = (offset + int_len +
#                        const.column_data_offset_offset +
#                        i * (int_len + 8))
#     col_data_len = (offset + 2 * int_len +
#                     const.column_data_length_offset +
#                     i * (int_len + 8))
#     col_types = (offset + 2 * int_len +
#                  const.column_type_offset + i * (int_len + 8))

#     x = self._read_int(col_data_offset, int_len)
#     self._column_data_offsets[i] = x

#     x = self._read_int(col_data_len, const.column_data_length_length)
#     self._column_data_lengths[i] = x

#     x = self._read_int(col_types, const.column_type_length)
#     if x == 1:
#         self.column_types[i] = b'd'
#     else:
#         self.column_types[i] = b's'

# def _process_columnlist_subheader(self, offset, length):
# # unknown purpose
# pass

# def _process_format_subheader(self, offset, length):
# int_len = self._int_length
# text_subheader_format = (
#     offset +
#     const.column_format_text_subheader_index_offset +
#     3 * int_len)
# col_format_offset = (offset +
#                      const.column_format_offset_offset +
#                      3 * int_len)
# col_format_len = (offset +
#                   const.column_format_length_offset +
#                   3 * int_len)
# text_subheader_label = (
#     offset +
#     const.column_label_text_subheader_index_offset +
#     3 * int_len)
# col_label_offset = (offset +
#                     const.column_label_offset_offset +
#                     3 * int_len)
# col_label_len = offset + const.column_label_length_offset + 3 * int_len

# x = self._read_int(text_subheader_format,
#                    const.column_format_text_subheader_index_length)
# format_idx = min(x, len(self.column_names_strings) - 1)

# format_start = self._read_int(
#     col_format_offset, const.column_format_offset_length)
# format_len = self._read_int(
#     col_format_len, const.column_format_length_length)

# label_idx = self._read_int(
#     text_subheader_label,
#     const.column_label_text_subheader_index_length)
# label_idx = min(label_idx, len(self.column_names_strings) - 1)

# label_start = self._read_int(
#     col_label_offset, const.column_label_offset_length)
# label_len = self._read_int(col_label_len,
#                            const.column_label_length_length)

# label_names = self.column_names_strings[label_idx]
# column_label = label_names[label_start: label_start + label_len]
# format_names = self.column_names_strings[format_idx]
# column_format = format_names[format_start: format_start + format_len]
# current_column_number = len(self.columns)

# col = _column()
# col.col_id = current_column_number
# col.name = self.column_names[current_column_number]
# col.label = column_label
# col.format = column_format
# col.ctype = self.column_types[current_column_number]
# col.length = self._column_data_lengths[current_column_number]

# self.column_formats.append(column_format)
# self.columns.append(col)

# def read(self, nrows=None):

# if (nrows is None) and (self.chunksize is not None):
#     nrows = self.chunksize
# elif nrows is None:
#     nrows = self.row_count

# if len(self.column_types) == 0:
#     self.close()
#     raise EmptyDataError("No columns to parse from file")

# if self._current_row_in_file_index >= self.row_count:
#     return None

# m = self.row_count - self._current_row_in_file_index
# if nrows > m:
#     nrows = m

# nd = (self.column_types == b'd').sum()
# ns = (self.column_types == b's').sum()

# self._string_chunk = np.empty((ns, nrows), dtype=np.object)
# self._byte_chunk = np.empty((nd, 8 * nrows), dtype=np.uint8)

# self._current_row_in_chunk_index = 0
# p = Parser(self)
# p.read(nrows)

# rslt = self._chunk_to_dataframe()
# if self.index is not None:
#     rslt = rslt.set_index(self.index)

# return rslt

# def _read_next_page(self):
# self._current_page_data_subheader_pointers = []
# self._cached_page = self._path_or_buf.read(self._page_length)
# if len(self._cached_page) <= 0:
#     return True
# elif len(self._cached_page) != self._page_length:
#     self.close()
#     msg = ("failed to read complete page from file "
#            "(read {:d} of {:d} bytes)")
#     raise ValueError(msg.format(len(self._cached_page),
#                                 self._page_length))

# self._read_page_header()
# if self._current_page_type == const.page_meta_type:
#     self._process_page_metadata()
# pt = [const.page_meta_type, const.page_data_type]
# pt += [const.page_mix_types]
# if self._current_page_type not in pt:
#     return self._read_next_page()

# return False

# def _chunk_to_dataframe(self):

# n = self._current_row_in_chunk_index
# m = self._current_row_in_file_index
# ix = range(m - n, m)
# rslt = pd.DataFrame(index=ix)

# js, jb = 0, 0
# for j in range(self.column_count):

#     name = self.column_names[j]

#     if self.column_types[j] == b'd':
#         rslt[name] = self._byte_chunk[jb, :].view(
#             dtype=self.byte_order + 'd')
#         rslt[name] = np.asarray(rslt[name], dtype=np.float64)
#         if self.convert_dates:
#             unit = None
#             if self.column_formats[j] in const.sas_date_formats:
#                 unit = 'd'
#             elif self.column_formats[j] in const.sas_datetime_formats:
#                 unit = 's'
#             if unit:
#                 rslt[name] = pd.to_datetime(rslt[name], unit=unit,
#                                             origin="1960-01-01")
#         jb += 1
#     elif self.column_types[j] == b's':
#         rslt[name] = self._string_chunk[js, :]
#         if self.convert_text and (self.encoding is not None):
#             rslt[name] = rslt[name].str.decode(
#                 self.encoding or self.default_encoding)
#         if self.blank_missing:
#             ii = rslt[name].str.len() == 0
#             rslt.loc[ii, name] = np.nan
#         js += 1
#     else:
#         self.close()
#         raise ValueError("unknown column type %s" %
#                          self.column_types[j])

# return rslt


end # module
