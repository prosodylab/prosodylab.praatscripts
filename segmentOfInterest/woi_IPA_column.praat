#########################################################################################
## woi_IPA_column:
## Takes an experiment file and adds the IPA transcription of the entire woi column to the file in a new column
##
## Eric Doty and Michael Wagner
## McGill University
## October 2011
#########################################################################################

echo Add IPA column to Word of Interest File

form Add IPA column to Word of Interest File
	sentence Woi_file /Users/speechlab/work/8_erictest/1_experiment/rogerDan.txt
	sentence New_file /Users/speechlab/work/8_erictest1_experiment/rogerDan_segs.txt
	sentence Dictionary_file /Applications/aligner/dictionary.txt 
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
	line_segments$ = ""

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
		
		# Check to make sure line is correct word, and append all possibilities
		num_strings = Get number of strings
		segments$ = "{"
		for n to num_strings

			dict_line$ = Get string... n

			space = index(dict_line$, " ")
			if space<>0
				space = space-1
			endif
			dict_word$ = left$(dict_line$, space)
			
			if word$ = dict_word$
				if segments$ <> "{"
					segments$ = segments$ + "/"
				endif
				word_len = length(word$)
				total_len = length(dict_line$)
				segments$ = segments$ + right$(dict_line$, total_len-word_len-1)
			endif
		endfor

		segments$ = segments$ + "}"
		if segments$ == "{}"
			printline No dictionary entry for 'word$'
		endif

		# Adds space between words, while avoiding adding a space before the first word
		if line_segments$ <> ""
			line_segments$ = line_segments$ + " " + segments$
		else
			line_segments$ = segments$
		endif

		printline 'word$': 'segments$'

		select Strings woitemp
		Remove

	until woiline$=""
	printline
	select woi_file	
	line_segments$ = line_segments$ + "."
	Set string value... r soi 'line_segments$'

endfor
select woi_file
Write to table file... 'new_file$'
#system rm 'temp_file$'

select woi_file
Remove
printline done

