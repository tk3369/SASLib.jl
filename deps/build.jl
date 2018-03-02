if !isfile(joinpath(@__DIR__, "notice_0.5.0"))
    print_with_color(Base.info_color(), STDERR,
    """
	SASLib.jl v0.5.0 has a major breaking change.  In prior versions, read operations
	would return a Dict object.  Starting v0.5.0, it returns a SASLib.ResultSet 
	object.  Please see README.md for more details.
    """)
    touch("notice_0.5.0")
end
