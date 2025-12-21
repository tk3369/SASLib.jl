using SASLib
using ReadStat
using CSV
using DataFrames
using StatFiles 

function main()
    # Check if input file is provided
    if length(ARGS) != 1
        println("Usage: julia compare.jl <input_file.sas7bdat>")
        println("This will create two files: <input_file>_saslib.csv and <input_file>_readstat.csv")
        return 1
    end

    input_file = ARGS[1]
    
    # Check if file exists
    if !isfile(input_file)
        println("Error: File '", input_file, "' not found")
        return 2
    end

    # Generate output filenames
    base_name = splitext(input_file)[1]  # Remove extension
    output_saslib = "$(base_name)_saslib.csv"
    output_readstat = "$(base_name)_readstat.csv"

    try
        # Read using SASLib
        @info "Reading with SASLib..."
        df_saslib = readsas(input_file, verbose_level=0)
        
        # Read using ReadStat and convert to DataFrame
        @info "Reading with ReadStat..."
        df_readstat = load(input_file)
        
        # Convert ReadStatDataFrame to a regular DataFrame
        df_readstat_df = DataFrame(df_readstat)
        
        # Write to CSV files
        @info "Writing results to CSV files..."
        CSV.write(output_saslib, df_saslib)
        CSV.write(output_readstat, df_readstat_df)
        
        @info "Done!"
        println("SASLib output: ", output_saslib)
        println("ReadStat output: ", output_readstat)
        
        return 0
    catch e
        @error "Error processing file: " exception=(e, catch_backtrace())
        return 3
    end
end

# Run the main function and exit with appropriate status code
exit(main())
