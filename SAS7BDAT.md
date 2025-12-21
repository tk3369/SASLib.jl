# SAS7BDAT File Format

Since the `sas7bdat` format is proprietary and not officially documented by the SAS Institute, most available information comes from reverse-engineering efforts. Below is a technical breakdown of the file format structure based on community research (such as the `readstat` C library and the `sas7bdat` R package).

### 1. High-Level Structure
A `.sas7bdat` file is organized into **Header** followed by a sequence of **Pages**.

*   **Header**: Contains global metadata (file signature, endianness, encoding, creation time, page size).
*   **Pages**: Fixed-size blocks (size defined in the header) containing data rows and metadata subheaders.

### 2. The Header
The header usually occupies the first page of the file. Key offsets and values include:

*   **Magic Number**: The file typically starts with a 32-byte magic string.
*   **Endianness**: A byte indicating whether the file is Little Endian (Intel) or Big Endian (Mainframe/SPARC). This is crucial for reading subsequent integers and doubles.
*   **Encoding**: Information about the character set (e.g., UTF-8, Latin1, WLATIN1).
*   **Page Size**: An integer defining the byte length of every page in the file.
*   **Header Length**: The length of the header itself (often 1024 bytes or 8192 bytes depending on the SAS version and platform).
*   **SAS Release**: The version of SAS used to create the file (e.g., "9.0401M6").

### 3. Page Structure
Every page after the header has a specific structure:

1.  **Page Header**: Located at the beginning of the page.
    *   **Page Type**: Indicates if the page contains data, metadata, or a mix. Common types include:
        *   `META`: Contains metadata subheaders (column names, types, labels).
        *   `DATA`: Contains actual row data.
        *   `MIX`: Contains both.
        *   `AMD`: Associated Metadata (often deleted records or index info).
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
