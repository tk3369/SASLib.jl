# SASLib.jl Implementation Details

## Overview
SASLib.jl is a high-performance Julia package for reading SAS7BDAT files, which are binary data files created by SAS software. This document provides an in-depth look at the implementation details of the package.

## Core Architecture

The package is structured around several key components:

1. **Main Module (SASLib.jl)**: Handles file I/O, parsing, and high-level API functions.
2. **Types (Types.jl)**: Defines core data structures and types used throughout the package.
3. **Constants (constants.jl)**: Contains all constant values, offsets, and magic numbers for the SAS7BDAT format.
4. **Utilities (utils.jl)**: Provides helper functions for common operations.
5. **ResultSet (ResultSet.jl)**: Implements the result set handling and data conversion.
6. **Object Pool (ObjectPool.jl)**: Manages object reuse for performance optimization.
7. **Case-Insensitive Dictionary (CIDict.jl)**: Provides case-insensitive dictionary functionality.
8. **Metadata (Metadata.jl)**: Handles metadata parsing and management.
9. **Tables Interface (tables.jl)**: Implements the Tables.jl interface for interoperability.

## File Format Specification

The SAS7BDAT file format is a binary format with the following structure:

### 1. File Header (First 288 bytes)
- **Bytes 0-31**: Magic number and file identification
  - First 8 bytes: Must match one of the known magic numbers
  - Byte 32: Alignment check (value 0x33 for valid files)
  - Byte 37: Endianness (0x01 for little-endian, 0x00 for big-endian)
  - Byte 39: Platform (1 = 32-bit, 2 = 64-bit)
  - Byte 70: Character encoding (0x20 = Latin1, 0x28 = UTF-8, etc.)
  
- **Bytes 156-163**: File type (should be 'SAS FILE' for valid files)
- **Bytes 164-171**: Creation timestamp (SAS datetime format)
- **Bytes 172-179**: Last modification timestamp (SAS datetime format)
- **Bytes 196-199**: Header size (typically 8KB)
- **Bytes 200-203**: Page size (typically 8KB)
- **Bytes 204-207**: Total page count
- **Bytes 216-223**: SAS release information

### 2. Page Structure
Each page (typically 8KB) contains:
- **Page Header** (24 bytes):
  - Page type (0x0000 = metadata, 0x0100 = data, 0x0400 = metadata index)
  - Block count
  - Page metadata flags
  - Compression information

- **Subheader Pointers**:
  - 4-byte offset
  - 4-byte length
  - 1-byte compression flag
  - 1-byte type
  - 2-byte attributes

### 3. Subheader Types
1. **Row Size Subheader**
   - Contains row length and row count information
   - Identified by signature 0xF7F7F7F7

2. **Column Text Subheader**
   - Contains column names and labels
   - May span multiple pages if needed

3. **Column Attributes Subheader**
   - Column types (1 = numeric, 2 = character)
   - Column widths
   - Storage information

4. **Data Subheaders**
   - Contain actual data rows
   - May be compressed using RLE or RDC

### 4. Data Representation
- **Numeric Values**: 8-byte double-precision floating point
- **Character Data**: Stored in the specified encoding (Latin1, UTF-8, etc.)
- **Dates/Times**: Stored as numeric values with format information
- **Missing Values**: Special numeric values (., ._, .A-.Z, ._)

## Key Data Structures

### Handler
The main structure that maintains the state during file reading:
```julia
mutable struct Handler
    io::IOStream
    config::ReaderConfig
    compression::UInt8
    column_names_strings::Vector{Vector{UInt8}}
    # ... other fields
end
```

### Column
Represents a column in the SAS dataset:
```julia
struct Column
    id::Int64
    name::AbstractString
    label::Vector{UInt8}
    format::AbstractString
    coltype::UInt8
    length::Int64
end
```

### SubHeaderPointer
Tracks subheader locations and properties:
```julia
struct SubHeaderPointer
    offset::Int64
    length::Int64
    compression::Int64
    shtype::Int64
end
```

## Detailed Reading Process

### 1. Initialization Phase
- **File Opening**
  - Opens the file in binary mode
  - Creates a Handler object to maintain state
  - Allocates initial buffers and caches

- **Header Validation**
  - Verifies magic number (first 32 bytes)
  - Checks alignment and endianness
  - Validates platform and encoding
  - Reads page size and calculates page count

- **Handler Initialization**
  ```julia
  function _open(config::ReaderConfig)
      handler = Handler(config)
      init_handler(handler)
      read_header(handler)
      read_file_metadata(handler)
      populate_column_names(handler)
      check_user_column_types(handler)
      read_first_page(handler)
      return handler
  end
  ```

### 2. Metadata Processing
- **Page Processing**
  - Iterates through pages using `my_read_next_page(handler)`
  - Identifies page type (metadata/data/index)
  - Processes subheader pointers to locate metadata blocks

- **Subheader Processing**
  - `_process_subheader_pointers()`: Maps subheader locations
  - `_process_rowsize_subheader()`: Extracts row dimensions
  - `_process_columntext_subheader()`: Processes column metadata
  - `_process_columnname_subheader()`: Maps column names and attributes
  - `_process_format_subheader()`: Handles data formatting information

### 3. Data Reading
- **Page-by-Page Processing**
  - Uses buffered I/O for efficient reading
  - Handles both compressed and uncompressed data
  - Processes data in chunks for memory efficiency

- **Type Conversion**
  - Numeric data: Converts from 8-byte floats to Julia `Float64`
  - Character data: Decodes using specified encoding
  - Dates/Times: Converts from SAS date/datetime values
  - Missing values: Handles SAS-specific missing value indicators

### 4. Result Assembly
- **ResultSet Construction**
  ```julia
  struct ResultSet
      data::Vector{Vector}
      colnames::Vector{Symbol}
      coltypes::Vector{Type}
      nrows::Int
      ncols::Int
  end
  ```
- **Final Processing**
  - Applies user-specified column filters
  - Converts to requested types
  - Handles missing values
  - Returns a Tables.jl compatible object

## Advanced Performance Optimizations

### 1. I/O and Memory Efficiency
- **Buffered Reading**
  - Uses 8KB page-aligned reads to match disk block size
  - Implements lookahead buffering for sequential access
  - Reduces system calls with large, aligned reads
  - Uses `IOBuffer` for efficient string decoding

- **Zero-Copy Processing**
  - Uses memory-mapped I/O where possible
  - Implements slice-based parsing to avoid data copying
  - Reuses memory buffers across operations
  - Uses views instead of copies where possible

- **String Handling**
  - Implements custom string transcoding with fallback to base transcoder
  - Uses `StringDecoder` for efficient string conversion
  - Implements custom string pool for memory efficiency with repeated strings

### 2. Compression Handling

#### Compression Detection
```julia
# In _process_columntext_subheader
if contains(cname_raw, rle_compression)
    compression_method = compression_method_rle
elseif contains(cname_raw, rdc_compression)
    compression_method = compression_method_rdc
else
    compression_method = compression_method_none
end
```

#### RLE (Run-Length Encoding) Decompression
```julia
function rle_decompress(output_len, input::Vector{UInt8})
    # Implements SAS-specific RLE with multiple command types:
    # - COPY64: Copy 64+ bytes
    # - INSERT_BYTE18: Insert repeated byte (18+ times)
    # - INSERT_AT17: Insert repeated '@' (17+ times)
    # - INSERT_BLANK17: Insert repeated spaces (17+ times)
    # - And more specialized commands...
end
```
- Optimized for common run patterns in SAS data
- Handles edge cases in compressed data
- Processes data in a single pass for efficiency

#### RDC (Ross Data Compression) Decompression
```julia
function rdc_decompress(result_length, inbuff::Vector{UInt8})
    # Implements Ross Data Compression algorithm with:
    # - Literal runs
    # - Short and long RLE (Run-Length Encoding)
    # - Pattern matching with backreferences
end
```
- Uses sliding window for pattern matching
- Optimized for typical tabular data patterns
- Handles both short and long matches efficiently

#### Compression-Specific Optimizations
- **Automatic Detection**: Detects compression method from file header
- **Fallback Handling**: Gracefully falls back to uncompressed processing
- **Memory Efficiency**: Processes data in chunks to limit memory usage
- **Performance**: Uses pre-allocated buffers for decompression output

### 3. Memory Management
- **Object Pooling**
  ```julia
  module ObjectPool
      mutable struct ObjectPool{T}
          objects::Vector{T}
          constructor::Function
      end
      # Implementation...
  end
  ```
  - Reduces GC pressure for temporary objects
  - Thread-safe pool access
  - Configurable pool sizes

- **Buffer Management**
  - Pre-allocates buffers based on file size
  - Implements buffer pooling for common sizes
  - Uses views instead of copies where possible

### 4. Parallel Processing
- **Page-Level Parallelism**
  - Processes independent pages in parallel
  - Uses work-stealing for load balancing
  - Thread-safe result aggregation

- **Vectorized Operations**
  - Uses SIMD instructions for type conversion
  - Batches small operations
  - Optimizes for cache locality

## Error Handling

The package implements robust error handling with custom exception types and validation:

### Exception Types
- `FileFormatError`: Raised for issues with the SAS7BDAT file format
  - Invalid magic number
  - Unsupported compression method
  - Corrupted data structures
  - Decompression failures
  - Invalid page types

- `ConfigError`: Raised for configuration-related issues
  - Invalid column specifications
  - Unsupported encoding
  - Invalid combination of parameters

### Validation and Error Checking
- **File Structure Validation**
  - Verifies magic number and file signature
  - Validates page headers and subheaders
  - Checks for consistent file structure

- **Data Integrity**
  - Validates compression headers
  - Checks buffer boundaries
  - Verifies decompressed data size matches expected

- **Recovery**
  - Graceful handling of corrupted data
  - Detailed error messages for debugging
  - Resource cleanup in case of errors

## Dependencies

- StringEncodings: For handling various text encodings
- TabularDisplay: For pretty-printing tables
- Tables: For implementing the Tables.jl interface
- Dates: For date/time handling
- IteratorInterfaceExtensions: For iterator support
- TableTraits: For table-like behavior

## Limitations

- Only supports reading SAS7BDAT files (not other SAS formats)
- Write functionality is not implemented
- Some SAS-specific features may not be fully supported

## Future Improvements

### Core Functionality
- **Write Support**
  - Implement SAS7BDAT file writing
  - Support for creating new SAS datasets
  - Conversion from DataFrame to SAS format

### Performance
- **Enhanced Compression**
  - Support for additional compression algorithms
  - Optimized compression for different data patterns
  - Parallel compression/decompression

### Data Type Support
- **Extended Type System**
  - Better handling of SAS-specific numeric formats
  - Support for SAS datetime precision
  - Improved handling of missing values

### Usability
- **API Improvements**
  - More flexible column selection
  - Better handling of large datasets
  - Improved memory management

### Testing & Documentation
- **Test Coverage**
  - More comprehensive test suite
  - Fuzz testing for robustness
  - Performance benchmarking
- **Documentation**
  - Detailed binary format specification
  - API reference
  - User guide with examples

### Integration
- **Data Ecosystem**
  - Better integration with Tables.jl
  - Support for more array types
  - Integration with data manipulation packages
