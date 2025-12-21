# SAS7BDAT File Format Specification

This document provides a comprehensive technical specification of the SAS7BDAT file format, based on reverse-engineering efforts by Matt Shotwell and other researchers. The format is proprietary and not officially documented by SAS Institute.

## Table of Contents
1. [File Structure Overview](#1-file-structure-overview)
2. [File Header](#2-file-header)
   - [Header Structure](#21-header-structure)
   - [Important Header Fields](#22-important-header-fields)
3. [Page Structure](#3-page-structure)
   - [Page Header](#31-page-header)
   - [Page Types](#32-page-types)
4. [Subheaders](#4-subheaders)
   - [Common Subheader Types](#41-common-subheader-types)
5. [Data Types](#5-data-types)
   - [Numeric Data](#51-numeric-data)
   - [Character Data](#52-character-data)
6. [Compression](#6-compression)
   - [RLE (Run-Length Encoding)](#61-rle-run-length-encoding)
   - [RDC (Ross Data Compression)](#62-rdc-ross-data-compression)
7. [Implementation Notes](#7-implementation-notes)
   - [Endianness](#71-endianness)
   - [Character Encoding](#72-character-encoding)
   - [Date/Time Handling](#73-datetime-handling)
8. [References](#8-references)

## 1. File Structure Overview

A SAS7BDAT file consists of a **Header** followed by a series of **Pages**:

```
+------------------+
|     Header       |  (First 1024 or 8192 bytes)
+------------------+
|                  |
|     Page 1       |  (Fixed size, typically 8KB)
|                  |
+------------------+
|                  |
|     Page 2       |
|                  |
+------------------+
|       ...        |
+------------------+
```

## 2. File Header

The header contains critical metadata about the file and is typically 1024 or 8192 bytes in length.

### 2.1 Header Structure

| Offset (hex) | Length | Description |
|--------------|--------|-------------|
| 0x00         | 32     | Magic number ("SAS FILE") |
| 0x20         | 2      | Alignment (0x00 0x00) |
| 0x22         | 1      | Endianness (0x01 = little, 0x00 = big) |
| 0x24         | 1      | Platform (1 = Unix, 2 = Windows) |
| 0x25         | 1      | File format (1 = 32-bit, 2 = 64-bit) |
| 0x26         | 2      | Reserved |
| 0x28         | 4      | Page size (typically 8192) |
| 0x2C         | 4      | Header size (1024 or 8192) |
| 0x30         | 4      | Total page count |
| 0x34         | 4      | Reserved |
| 0x38         | 8      | Creation timestamp |
| 0x40         | 8      | Last modified timestamp |
| 0x48         | 64     | Dataset label |
| 0x88         | 64     | Dataset name |
| 0xC8         | 8      | SAS release string (e.g., "9.4") |
| 0xD0         | 8      | Server type |
| 0xD8         | 8      | OS name |
| 0xE0         | 8      | OS version |
| 0xE8         | 8      | Reserved |

### 2.2 Important Header Fields

- **Magic Number**: First 32 bytes, typically "SAS FILE" followed by null bytes
- **Endianness**: Determines byte order for multi-byte numbers (0x01 = little-endian, 0x00 = big-endian)
- **Page Size**: Usually 8KB (8192 bytes) but can vary
- **Timestamps**: Stored as seconds since 1960-01-01 00:00:00 UTC
- **Header Size**: Typically 1024 bytes for older files, 8192 bytes for newer versions

## 3. Page Structure

Each page starts with a header followed by its content. The header size varies between 32-bit (48 bytes) and 64-bit (64 bytes) formats.

### 3.1 Page Header (32-bit format)

| Offset | Length | Description |
|--------|--------|-------------|
| 0x00   | 2      | Page type (bitmask) |
| 0x02   | 2      | Block count |
| 0x04   | 4      | Subheader count |
| 0x08   | 4      | Reserved |
| 0x0C   | 4      | Page number |
| 0x10   | 4      | Block length |
| 0x14   | 4      | Reserved |
| 0x18   | 4      | Page flags |
| 0x1C   | 4      | Reserved |

### 3.2 Page Types

Pages are identified by bitmasks in the page header:

| Bit | Mask  | Description |
|-----|-------|-------------|
| 7   | 0x80  | Metadata page |
| 6   | 0x40  | Data page |
| 5   | 0x20  | Index page |
| 4   | 0x10  | Compressed page |
| 3   | 0x08  | Reserved |
| 2   | 0x04  | Deleted page |
| 1   | 0x02  | Reused page |
| 0   | 0x01  | Reserved |

## 4. Subheaders

Subheaders contain metadata and data within pages, each identified by a unique signature.

### 4.1 Common Subheader Types

1. **Row Size Subheader**
   - Signature: 0xF7F7F7F7 (32-bit) or 0xF7F7F7F7F7F7F7F7 (64-bit)
   - Contains: Row length, row count, and column count
   - Critical for determining data layout

2. **Column Text Subheader**
   - Signature: 0xFFFFFFFFFFFFFFFF
   - Contains: Column names and attributes
   - May include format and label information

3. **Column Attributes Subheader**
   - Signature: 0xFCFFFFFF
   - Contains: Data types, lengths, and formats
   - Defines the structure of each column

4. **Column Names Subheader**
   - Signature: 0xFEFFFFFF
   - Contains: Column names as null-terminated strings
   - Used in conjunction with column attributes

## 5. Data Types

### 5.1 Numeric Data
- Stored as 8-byte IEEE 754 floating-point numbers
- Special values:
  - Missing: 0x7FF0000000000000
  - ._ (illegal): 0xFFF0000000000000
  - .A-.Z: 0x7FF0000000000001 through 0x7FF000000000001A
- Dates and times are stored as numeric values with format attributes

### 5.2 Character Data
- Fixed-width strings
- Padded with spaces (0x20)
- Maximum length: 32,767 bytes
- Default encoding: Windows-1252 (CP1252)
- May contain embedded null characters

## 6. Compression

### 6.1 RLE (Run-Length Encoding)
- Simple compression method
- Replaces repeated bytes with a count and value
- Used in older SAS versions (pre-9.0)
- Less efficient but simpler to implement

### 6.2 RDC (Ross Data Compression)
- Advanced compression method
- Combines multiple techniques:
  - Run-length encoding
  - Dictionary compression
  - Delta encoding
- Used in SAS 9.0 and later
- More efficient but more complex to implement

## 7. Implementation Notes

### 7.1 Endianness
- Must be handled correctly for all multi-byte values
- Affects:
  - Integer values
  - Floating-point numbers
  - Timestamps
  - Offsets and lengths

### 7.2 Character Encoding
- Default: Windows-1252 (CP1252)
- May be overridden in file header
- Important for proper handling of non-ASCII characters
- Some SAS versions use special encodings for specific locales

### 7.3 Date/Time Handling
- **Dates**: Number of days since 1960-01-01
- **Times**: Number of seconds since midnight
- **Datetimes**: Number of seconds since 1960-01-01 00:00:00
- Special handling for missing/illegal values

## 8. References

1. Shotwell, M. S. (2013). SAS7BDAT Database Binary Format. CRAN Vignette.
2. ReadStat Project. https://github.com/WizardMac/ReadStat
3. SAS Institute Inc. (2016). SAS 9.4 Language Reference: Concepts, Fifth Edition. Cary, NC: SAS Institute Inc.
    *   **Block Count**: Number of subheaders/blocks in the page.
    *   **Subheader Pointers**: An array of offsets and lengths pointing to the subheaders within the page.

2.  **Subheaders**: These describe the content.
    *   **Row Size Subheader**: Defines the length of a data row in bytes and the number of rows per page.
    *   **Column Size Subheader**: Defines the number of columns.
    *   **Column Text Subheader**: Contains the names of the columns.
    *   **Column Attributes Subheader**: Defines data types (numeric vs char), lengths, and formats for each column.
    *   **Data Rows**: The actual binary data, usually packed sequentially.

### 4. Data Types
SAS is relatively simple regarding primitive types, supporting only two native types:

*   **Numeric**:
    *   Stored as 8-byte floating-point numbers (IEEE 754 doubles).
    *   **Truncation**: To save space, SAS allows storing fewer than 8 bytes (e.g., 3 to 7 bytes). When reading, these must be padded with zero bytes at the mantissa end to restore them to valid 8-byte doubles before parsing.
    *   **Missing Values**: Standard missing values are represented by specific `NaN` patterns or specific large negative numbers (for `.A` through `.Z`).
*   **Character**:
    *   Fixed-width strings.
    *   Padded with spaces (0x20) or nulls depending on the creation context.

### 5. Date and Time
SAS does not have a distinct Date type physically; they are stored as **Numeric** values with specific format tags attached in the metadata.
*   **Epoch**: January 1, 1960.
*   **Date**: Number of days since epoch.
*   **Datetime**: Number of seconds since epoch.
*   **Time**: Number of seconds since midnight.

### 6. Compression
If the file is compressed, the page structure changes significantly.
*   **RLE (Run Length Encoding)**: Older/simpler compression.
*   **RDC (Ross Data Compression)**: A proprietary algorithm used in newer SAS versions.
*   Compressed data usually sits inside the page payload, and you must decompress the stream before applying the row/column logic.

### 7. Reference Implementations
If you are working on `SASLib`, looking at existing open-source parsers is highly recommended:
*   **ReadStat (C)**: The backend for R's `haven` and Python's `pyreadstat`. It is widely considered the most robust open-source implementation.
*   **Parso (Java)**: A Java library for reading SAS files.
*   **Pandas (Python)**: The `read_sas` implementation in pandas is written in Python/Cython.

### 8. External References
You might be recalling the following document, which provided the initial comprehensive analysis of the format:

*   **"sas7bdat: Read SAS7BDAT Files in R" (Matt Shotwell)**: This vignette for the R package `sas7bdat` contains a detailed explanation of the reverse-engineering process and the file structure. It is often circulated as a PDF.

### 9. Technical Implementation Details (from Shotwell's Analysis)
While the sections above outline the structure, actual implementation requires handling specific byte offsets and signatures detailed in Shotwell's analysis:

*   **Critical Header Offsets**:
    *   **Magic Number**: Bytes 0-32.
    *   **Endianness**: Byte 37 (0x25). `0x01` usually implies Little Endian.
    *   **Encoding**: Byte 70 (0x46).

*   **Page Bitmasks**:
    *   The **Page Type** is not a simple enum but a bitmask located at offset 16 (for 32-bit files) or 24 (for 64-bit files) inside the page.
    *   **Bit 7 (0x80)**: Page contains Metadata.
    *   **Bit 6 (0x40)**: Page contains Data.
    *   **Bit 4 (0x10)**: Page is Compressed.

*   **Subheader Signatures**:
    *   Parsers differentiate subheaders by looking at their first few bytes (signatures).
    *   **Row Size Subheader**: Often identified by `0xF7F7F7F7` (32-bit) or `0xF7F7F7F7F7F7F7F7` (64-bit).
    *   **Column Text Subheader**: Often identified by `0xFFFFFFFFFFFFFFFF`.
