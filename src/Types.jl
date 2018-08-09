struct FileFormatError <: Exception
    message::AbstractString
end 

struct ConfigError <: Exception
    message::AbstractString
end 

struct ReaderConfig 
    filename::AbstractString
    encoding::AbstractString
    chunk_size::Int64
    convert_dates::Bool
    include_columns::Vector
    exclude_columns::Vector
    string_array_fn::Dict{Symbol, Function}
    number_array_fn::Dict{Symbol, Function}
    column_types::Dict{Symbol, Type}
    verbose_level::Int64
end

struct Column
    id::Int64
    name::AbstractString
    label::Vector{UInt8}  # really?
    format::AbstractString
    coltype::UInt8
    length::Int64
end

struct ColumnNamePointer
    index::Int
    offset::Int
    length::Int
end

# technically these fields may have lower precision (need casting?)
struct SubHeaderPointer
    offset::Int64
    length::Int64
    compression::Int64
    shtype::Int64
end

mutable struct Handler
    io::IOStream
    config::ReaderConfig
    
    compression::UInt8
    column_names_strings::Vector{Vector{UInt8}}
    column_names::Vector{AbstractString}
    column_symbols::Vector{Symbol}
    column_types::Vector{UInt8}
    column_formats::Vector{AbstractString}
    columns::Vector{Column}

    # column indices being read/returned 
    # tuple of column index, column symbol, column type
    column_indices::Vector{Tuple{Int64, Symbol, UInt8}}
    column_name_pointers::Vector{ColumnNamePointer}
    
    current_page_data_subheader_pointers::Vector{SubHeaderPointer}
    cached_page::Vector{UInt8}
    column_data_lengths::Vector{Int64}
    column_data_offsets::Vector{Int64}
    current_row_in_file_index::Int64
    current_row_in_page_index::Int64

    file_endianness::Symbol
    sys_endianness::Symbol
    byte_swap::Bool

    U64::Bool
    int_length::Int8
    page_bit_offset::Int8
    subheader_pointer_length::UInt8

    file_encoding::AbstractString
    platform::AbstractString
    name::Union{AbstractString,Vector{UInt8}}
    file_type::Union{AbstractString,Vector{UInt8}}

    date_created::DateTime
    date_modified::DateTime

    header_length::Int64
    page_length::Int64
    page_count::Int64
    sas_release::Union{AbstractString,Vector{UInt8}}
    server_type::Union{AbstractString,Vector{UInt8}}
    os_version::Union{AbstractString,Vector{UInt8}}
    os_name::Union{AbstractString,Vector{UInt8}}

    row_length::Int64
    row_count::Int64
    col_count_p1::Int64
    col_count_p2::Int64
    mix_page_row_count::Int64
    lcs::Int64
    lcp::Int64

    current_page_type::Int64
    current_page_block_count::Int64       # number of records in current page
    current_page_subheaders_count::Int64
    column_count::Int64
    # creator_proc::Union{Void, Vector{UInt8}}

    byte_chunk::Dict{Symbol, Vector{UInt8}}
    string_chunk::Dict{Symbol, AbstractVector{String}}
    current_row_in_chunk_index::Int64

    current_page::Int64    
    vendor::UInt8
    use_base_transcoder::Bool

    string_decoder_buffer::IOBuffer
    string_decoder::StringDecoder

    column_types_dict::CIDict{Symbol,Type}

    Handler(config::ReaderConfig) = new(
        Base.open(config.filename),
        config)
end

