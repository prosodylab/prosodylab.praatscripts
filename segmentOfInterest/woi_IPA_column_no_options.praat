echo Testing file

form Annotate Words of Interest	
	sentence Woi_file /Users/speechlab/work/8_erictest/1_experiment/rogerDan.txt
	sentence New_file /Users/speechlab/work/8_erictest/1_experiment/rogerDan_segs.txt
	sentence Dictionary_file /Applications/aligner/dictionary.txt
	sentence Word_boundary  
endform

temp_file$ = "./woitemp.txt"

#  Read in woi file
Read Table from tab-separated file... 'woi_file$'
woi_file = selected("Table")
Append column... soi
num_rows = Get number of rows

for r to num_rows
	woiline$ = Get value... r woi
	woiline$ =replace_regex$(woiline$, ".", "\U&", 0)
	woiline$ = replace$ (woiline$, ".", "", 0)
	woiline$ = replace$ (woiline$, ":", "", 0)
	woiline$ = replace$ (woiline$, ",", "", 0)
	woiline$ = replace$ (woiline$, """", "", 0)
	woiline$ = replace$ (woiline$, ";", "", 0)
	woiline$ = replace$ (woiline$, "  ", " ", 0)
	printline Woiline: 'woiline$'
	word_segments$ = ""

	repeat
		woiFound = 0

		# Get next word in woiline and truncate
	       	space = index(woiline$, " ")
	   	if space = 0
			word$ = woiline$
			space = length(woiline$)
		else 
			space=space-1
		endif	
		word$ = left$(woiline$, space)
		len = length(woiline$)
		len = len - space
		woiline$ = right$(woiline$,len-1)
		len = length(woiline$)
	
		# Remove underscores
		uscore = index(word$, "_")

		if uscore <> 0
			word$ = left$(word$, (uscore-1))
		endif

		# Search dictionary for lines containing word
		system grep -i -w 'word$' 'dictionary_file$' > 'temp_file$'
		Read Strings from raw text file... 'temp_file$'
		
		# Check to make sure line is correct word
		try=0
		satisfied=0
		num_strings = Get number of strings
		repeat
			try = try +1

			if try > num_strings
				printline No dictionary result for 'word$'
			endif

			dict_line$ = Get string... try
			space = index(dict_line$, " ")
			if space<>0
				space = space-1
			endif
			dict_word$ = left$(dict_line$, space)
			if word$ = dict_word$
				satisfied=1
			endif
		until satisfied=1
			
		word_len = length(word$)			
		total_len = length(dict_line$)
		segments$ = right$(dict_line$, total_len-word_len-1)

		word_segments$ = word_segments$ + segments$ + word_boundary$

		printline 'word$': 'segments$'

		select Strings woitemp
		Remove

	until woiline$=""
	printline
	select woi_file	
	word_segments$ = word_segments$ + "."
	Set string value... r soi 'word_segments$'

endfor
select woi_file
Write to table file... 'new_file$'
system rm 'temp_file$'

select woi_file
Remove
printline done

