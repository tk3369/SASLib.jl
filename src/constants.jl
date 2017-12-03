# default settings
const default_encoding = "UTF-8"
const default_chunksize = 0
const default_convert_dates = true
const default_convert_empty_string_to_missing = true
const default_convert_text = true
const default_convert_header_text = true

const magic = [
         b"\x00\x00\x00\x00\x00\x00\x00\x00"  ;
         b"\x00\x00\x00\x00\xc2\xea\x81\x60"  ;
         b"\xb3\x14\x11\xcf\xbd\x92\x08\x00"  ;
         b"\x09\xc7\x31\x8c\x18\x1f\x10\x11" ]

const align_1_checker_value = b"3"
const align_1_offset = 32
const align_1_length = 1
const align_1_value = 4
const u64_byte_checker_value = b"3"
const align_2_offset = 35
const align_2_length = 1
const align_2_value = 4
const endianness_offset = 37
const endianness_length = 1
const platform_offset = 39
const platform_length = 1
const encoding_offset = 70
const encoding_length = 1
const dataset_offset = 92
const dataset_length = 64
const file_type_offset = 156
const file_type_length = 8
const date_created_offset = 164
const date_created_length = 8
const date_modified_offset = 172
const date_modified_length = 8
const header_size_offset = 196
const header_size_length = 4
const page_size_offset = 200
const page_size_length = 4
const page_count_offset = 204
const page_count_length = 4
const sas_release_offset = 216
const sas_release_length = 8
const sas_server_type_offset = 224
const sas_server_type_length = 16
const os_version_number_offset = 240
const os_version_number_length = 16
const os_maker_offset = 256
const os_maker_length = 16
const os_name_offset = 272
const os_name_length = 16
const page_bit_offset_x86 = 16
const page_bit_offset_x64 = 32
const subheader_pointer_length_x86 = 12
const subheader_pointer_length_x64 = 24
const page_type_offset = 0
const page_type_length = 2
const block_count_offset = 2
const block_count_length = 2
const subheader_count_offset = 4
const subheader_count_length = 2
const page_meta_type = 0
const page_data_type = 256
const page_amd_type = 1024
const page_metc_type = 16384
const page_comp_type = -28672
const page_mix_types = [512, 640]
const subheader_pointers_offset = 8
const truncated_subheader_id = 1
const compressed_subheader_id = 4
const compressed_subheader_type = 1
const text_block_size_length = 2
const row_length_offset_multiplier = 5
const row_count_offset_multiplier = 6
const col_count_p1_multiplier = 9
const col_count_p2_multiplier = 10
const row_count_on_mix_page_offset_multiplier = 15
const column_name_pointer_length = 8
const column_name_text_subheader_offset = 0
const column_name_text_subheader_length = 2
const column_name_offset_offset = 2
const column_name_offset_length = 2
const column_name_length_offset = 4
const column_name_length_length = 2
const column_data_offset_offset = 8
const column_data_length_offset = 8
const column_data_length_length = 4
const column_type_offset = 14
const column_type_length = 1
const column_format_text_subheader_index_offset = 22
const column_format_text_subheader_index_length = 2
const column_format_offset_offset = 24
const column_format_offset_length = 2
const column_format_length_offset = 26
const column_format_length_length = 2
const column_label_text_subheader_index_offset = 28
const column_label_text_subheader_index_length = 2
const column_label_offset_offset = 30
const column_label_offset_length = 2
const column_label_length_offset = 32
const column_label_length_length = 2
const rle_compression = b"SASYZCRL"
const rdc_compression = b"SASYZCR2"
 
const compression_literals = [rle_compression, rdc_compression]

# Incomplete list of encodings, using SAS nomenclature:
# http://support.sas.com/documentation/cdl/en/nlsref/61893/HTML/default/viewer.htm#a002607278.htm
const encoding_names = Dict(29 => "latin1", 20 => "utf-8", 33 => "cyrillic", 60 => "wlatin2",
                  61 => "wcyrillic", 62 => "wlatin1", 90 => "ebcdic870")


const index_rowSizeIndex = 0
const index_rowSizeIndex = 0
const index_columnSizeIndex = 1
const index_subheaderCountsIndex = 2
const index_columnTextIndex = 3
const index_columnNameIndex = 4
const index_columnAttributesIndex = 5
const index_formatAndLabelIndex = 6
const index_columnListIndex = 7
const index_dataSubheaderIndex = 8


const subheader_signature_to_index = Dict(
    b"\xF7\xF7\xF7\xF7" => index_rowSizeIndex,
    b"\x00\x00\x00\x00\xF7\xF7\xF7\xF7" => index_rowSizeIndex,
    b"\xF7\xF7\xF7\xF7\x00\x00\x00\x00" => index_rowSizeIndex,
    b"\xF7\xF7\xF7\xF7\xFF\xFF\xFB\xFE" => index_rowSizeIndex,
    b"\xF6\xF6\xF6\xF6" => index_columnSizeIndex,
    b"\x00\x00\x00\x00\xF6\xF6\xF6\xF6" => index_columnSizeIndex,
    b"\xF6\xF6\xF6\xF6\x00\x00\x00\x00" => index_columnSizeIndex,
    b"\xF6\xF6\xF6\xF6\xFF\xFF\xFB\xFE" => index_columnSizeIndex,
    b"\x00\xFC\xFF\xFF" => index_subheaderCountsIndex,
    b"\xFF\xFF\xFC\x00" => index_subheaderCountsIndex,
    b"\x00\xFC\xFF\xFF\xFF\xFF\xFF\xFF" => index_subheaderCountsIndex,
    b"\xFF\xFF\xFF\xFF\xFF\xFF\xFC\x00" => index_subheaderCountsIndex,
    b"\xFD\xFF\xFF\xFF" => index_columnTextIndex,
    b"\xFF\xFF\xFF\xFD" => index_columnTextIndex,
    b"\xFD\xFF\xFF\xFF\xFF\xFF\xFF\xFF" => index_columnTextIndex,
    b"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFD" => index_columnTextIndex,
    b"\xFF\xFF\xFF\xFF" => index_columnNameIndex,
    b"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF" => index_columnNameIndex,
    b"\xFC\xFF\xFF\xFF" => index_columnAttributesIndex,
    b"\xFF\xFF\xFF\xFC" => index_columnAttributesIndex,
    b"\xFC\xFF\xFF\xFF\xFF\xFF\xFF\xFF" => index_columnAttributesIndex,
    b"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFC" => index_columnAttributesIndex,
    b"\xFE\xFB\xFF\xFF" => index_formatAndLabelIndex,
    b"\xFF\xFF\xFB\xFE" => index_formatAndLabelIndex,
    b"\xFE\xFB\xFF\xFF\xFF\xFF\xFF\xFF" => index_formatAndLabelIndex,
    b"\xFF\xFF\xFF\xFF\xFF\xFF\xFB\xFE" => index_formatAndLabelIndex,
    b"\xFE\xFF\xFF\xFF" => index_columnListIndex,
    b"\xFF\xFF\xFF\xFE" => index_columnListIndex,
    b"\xFE\xFF\xFF\xFF\xFF\xFF\xFF\xFF" => index_columnListIndex,
    b"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFE" => index_columnListIndex
)


# List of frequently used SAS date and datetime formats
# http://support.sas.com/documentation/cdl/en/etsug/60372/HTML/default/viewer.htm#etsug_intervals_sect009.htm
# https://github.com/epam/parso/blob/master/src/main/java/com/epam/parso/impl/SasFileConstants.java
const sas_date_formats = ["DATE", "DAY", "DDMMYY", "DOWNAME", "JULDAY", "JULIAN",
                    "MMDDYY", "MMYY", "MMYYC", "MMYYD", "MMYYP", "MMYYS",
                    "MMYYN", "MONNAME", "MONTH", "MONYY", "QTR", "QTRR",
                    "NENGO", "WEEKDATE", "WEEKDATX", "WEEKDAY", "WEEKV",
                    "WORDDATE", "WORDDATX", "YEAR", "YYMM", "YYMMC", "YYMMD",
                    "YYMMP", "YYMMS", "YYMMN", "YYMON", "YYMMDD", "YYQ",
                    "YYQC", "YYQD", "YYQP", "YYQS", "YYQN", "YYQR", "YYQRC",
                    "YYQRD", "YYQRP", "YYQRS", "YYQRN",
                    "YYMMDDP", "YYMMDDC", "E8601DA", "YYMMDDN", "MMDDYYC",
                    "MMDDYYS", "MMDDYYD", "YYMMDDS", "B8601DA", "DDMMYYN",
                    "YYMMDDD", "DDMMYYB", "DDMMYYP", "MMDDYYP", "YYMMDDB",
                    "MMDDYYN", "DDMMYYC", "DDMMYYD", "DDMMYYS",
                    "MINGUO"]

const sas_datetime_formats = ["DATETIME", "DTWKDATX",
                        "B8601DN", "B8601DT", "B8601DX", "B8601DZ", "B8601LX",
                        "E8601DN", "E8601DT", "E8601DX", "E8601DZ", "E8601LX",
                        "DATEAMPM", "DTDATE", "DTMONYY", "DTMONYY", "DTWKDATX",
                        "DTYEAR", "TOD", "MDYAMPM"]

const zero_space = b"\x00 "

const column_type_none    = 0x00
const column_type_decimal = 0x01
const column_type_string  = 0x02
