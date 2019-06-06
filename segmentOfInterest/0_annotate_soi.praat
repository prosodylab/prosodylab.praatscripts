##########################################################################################################################
## annotate_soi:
## Takes an experiment file with demarcated soi file (created by woi_IPA_column.praat) and a directory of TextGrids as input
## Adds a tier for segments of interest and their labels
##
## 	Note: In the experiment file, word boundaries must be demarcated by curly brackets, alternative transcription 
## 	options by slashes and segments of interest by underscores followed by one character labels
## 		e.g. {W O R D1/W O R D1a} {W O R D2} {W O R D3/W O R D3b}
##
##
## Eric Doty , Michael Wagner, Meghan Clayards
## McGill University
## October 2011
#########################################################################################################################

echo Annotate Words of Interest


# This procedure saves the id-column-names in an array (column_name'number'))
# and identifies how many identifying columns there are (numberColumns)
procedure idColumns columns$

	numberColumns = 0

	repeat

		numberColumns = numberColumns + 1

		seperator = index (columns$, "_")
		if seperator = 0
			column_name'numberColumns'$ = columns$
			columns$ = ""
		else
			column_name'numberColumns'$  = left$(columns$,seperator-1)
			len = length(columns$)
			len = len - seperator
			columns$ = right$(columns$, len)
		endif	

	until columns$=""

endproc


# This procedure identifies where the name 
# the information corresponding to the id-columns is.

procedure columnIndex name$

	currentColumn = 0

	repeat 

		seperator = index (name$, "_")

		if seperator = 0
			nameColumn$ = name$
			name$ = ""
		else
			nameColumn$ = left$(name$,seperator-1)
			len = length(name$)
			len = len - seperator
			name$ = right$(name$, len)
		endif 

		currentColumn  = currentColumn  + 1

		for k to numberColumns
			if nameColumn$ = column_name'k'$
				column_index'k' = currentColumn  	
			endif
		endfor

	until name$ = ""

	if columns$ <> ""
		exit id_columns and name_columns don't match up!
	endif

endproc


# This precedure identifies the right textline in the _soi file for a given sound file
# if there no corresponding line, then an empty string is returned.

procedure parsename txt$
	columnCount = 0
	select soi_file
	nrows = Get number of rows

	repeat 
		columnCount = columnCount + 1
		seperator = index (txt$, "_")
		if seperator = 0
			seperator = index (txt$,".")
			currentColumn$ = left$(txt$,seperator-1)
			txt$ = ""
		else
			currentColumn$ = left$(txt$, seperator-1)
			len = length(txt$)
			len = len - seperator
			txt$ = right$(txt$, len)
		endif

		for cl to numberColumns
			if column_index'cl'=columnCount
				column_value'cl'$ = currentColumn$
			endif 
		endfor

	until txt$ = ""
endproc


procedure getSoiLine
	rw = 0
	soiline$ = ""
	repeat
		rw = rw + 1
		yessir = 1
		for cl to numberColumns
			name$ = column_name'cl'$
			slabel$ = Get value... 'rw' 'name$'
			if slabel$ <> column_value'cl'$
			 	yessir = 0
			endif
		endfor

		if yessir
			soiline$ = Get value... 'rw' soi
		endif

		soiline$ =replace_regex$(soiline$, ".", "\U&", 0)
	    soiline$ = replace$ (soiline$, "  ", " ", 0)
		soiline$ = replace$ (soiline$, ".", "", 0)
		soiline$ = replace$ (soiline$, ":", "", 0)
		soiline$ = replace$ (soiline$, ",", "", 0)
		soiline$ = replace$ (soiline$, """", "", 0)
		soiline$ = replace$ (soiline$, ";", "", 0)
		soiline$ = replace$ (soiline$, "  ", " ", 0)
	until  (soiline$ <> "") or (rw = nrows)
endproc


procedure parseline 
# this procedure returns the next soi and its label and returns a pruned string
# nextSoi$ extracted from  textline$, nextLabel$ determined, textline$ is pruned
	soiFound = 0
	repeat
		space = index(soiline$, " ")
		word$ = left$(soiline$, space)

		if space = 0
			word$ = soiline$
			space = length(soiline$)
		endif

		uscore = index(word$, "_")

		if uscore <> 0
			soiCount = soiCount + 1
			nextSoi$ = left$(word$, (uscore-1))
			leng = space - uscore
			nextLabel$ = mid$(soiline$, (uscore+1), leng)
			soiFound = 1
		endif 

		len = length(soiline$)
		len = len - space
		soiline$ = right$(soiline$,len)
		len = length(soiline$)

	until (soiFound = 1) or (len=0)
endproc


#pickTranscription takes as input the word transcription options and the TextGrid transcriptions for that given word
procedure pickTranscription options$
	tgrid_segments$ = word_segments$
	transcription$ = ""
	wordFound =0

	#Parse options$ string one word_option$ at a time, separated by slashes
	repeat	
		chosen_trans$ = ""
		slash = index(options$, "/")
		if slash = 0
			word_option$ = options$
			options$ = ""
		else 
			word_option$ = left$(options$, slash-1)
			len = length(options$)
			len = len-slash
			options$ = right$(options$, len)	
		endif		


		len = length(options$)

		#Remove "sp" segments from segments list within a word
		repeat
			sp = index(tgrid_segments$, "sp")
			word_len = length(tgrid_segments$)
			if sp<>0
				tgrid_segments$ = left$(tgrid_segments$, sp-2) + right$(tgrid_segments$, word_len-sp-1)
			endif
		until sp=0
	
		#Search for trailing spaces
		index=1
		onespace = 0
		len_word = length(tgrid_segments$)
		repeat
			index=index+1
			leftword$ = left$(tgrid_segments$, index)
			rightword$ = right$(leftword$, 1)
			if rightword$ = " "
				onespace=onespace+1
				#Quit after 2 spaces found
				if onespace>1
					index=index-2
				endif
			else
				onespace=0
			endif
		until onespace>1 or index=len_word

		#Trim off leading and trailing spaces
		tgrid_segments$ = left$(tgrid_segments$, index)
		len_word = length(tgrid_segments$)

		if left$(tgrid_segments$, 1) = " "
			tgrid_segments$ = right$(tgrid_segments$, len_word-1)
		endif

		if right$(tgrid_segments$, 1) = " "
			tgrid_segments$ = left$(tgrid_segments$, len_word-1)
		endif

		#Remove underscores from word options
		test_option$ = word_option$
		repeat
			underscore = index(test_option$, "_")
			word_len = length(test_option$)
			if underscore<>0
				test_option$ = left$(test_option$, underscore-1) + right$(test_option$, word_len-underscore-1)
			endif
		until underscore=0

       len_word2 = length(test_option$)
		if left$(test_option$, 1) = " "
			test_option$ = right$(test_option$, len_word2-1)
		endif

		#Return proper word transcription including _ and soi
         

		if test_option$ == tgrid_segments$
			wordFound=1
			chosen_trans$ = word_option$
		endif
	until (wordFound=1) or (len=0)

	#If no word found, return error message with name of word and segments
	if wordFound ==0
		printline No experiment file match found for word 'interval_label$' with soi annotation .'test_option$'. and TextGrid segments .'tgrid_segments$'.
	endif

endproc

# getWordSegments takes a word number as input and finds the segments corresponding to that word
procedure getWordSegments int_num

	word_segments$ = ""
	start = Get start point... wordTierNumber int_num
	end = Get end point... wordTierNumber int_num
	seg = Get interval at time... segTierNumber start
	end_seg = Get interval at time... segTierNumber end-0.000001

	repeat
		seg_label$ = Get label of interval... segTierNumber seg
		if word_segments$ <> ""
			word_segments$ = word_segments$ + " " + seg_label$
		else
			word_segments$ = seg_label$
		endif
		seg=seg+1
	until seg>end_seg

endproc

########################################################################################################################
form Annotate Words of Interest	
	sentence Soi_file 0_darkside_soi.txt
	sentence Id_columns experiment_item_condition
	sentence Filename_format experiment_participant_item_condition
	natural segTierNumber 2
	natural wordTierNumber 1
	comment Select "Dry run" to test without saving. 
	boolean Dry_run 1
	comment Select "restore old before" to operate on old TextGrid files.
	boolean restore_old_before 0
	comment Select "mkDir" to make directory for storing old TextGrid files.
	boolean mkDir 0
endform
########################################################################################################################

storeold$="./0_oldTextGrids"

if restore_old_before = 1
     system mv 'storeold$'/*.TextGrid .
     system rmdir  'storeold$'
endif

call idColumns 'id_columns$'

#  Read in soi file
Read Table from tab-separated file... 'soi_file$'
soi_file = selected("Table")

call columnIndex  'filename_format$'

# Strings of all sounds files
Create Strings as file list... list  *.TextGrid
filenames = selected("Strings")
numberOfFiles = Get number of strings

if dry_run=0 and mkDir=1
 	# make directory for old textGrid files
 	system mkdir  'storeold$'
endif 

# Cycle through soundfiles
if  dry_run=1
		numberOfLoops = 10
else
		numberOfLoops = numberOfFiles
endif

for i to numberOfLoops

	select filenames
	filename$ = Get string... i
	
	# get correct textline$ with soi annotation
	call parsename 'filename$'
	call getSoiLine

        if soiline$<>""
		Read from file... 'filename$'
		printline
		printline 'filename$'
		printline soi-Annotation: 'soiline$'
		tgrid = selected("TextGrid")

		# save original tgrid	
		if dry_run<>1
			Write to text file... 'storeold$'/'filename$'
		endif

		# Loop through the word tier
		num_intervals = Get number of intervals... 'wordTierNumber'
		word_num = 0
		new_soiline$ = ""
		sentence$ = ""
		for w to num_intervals
			word_num = word_num+1
			interval_label$ = Get label of interval... wordTierNumber w

			# When the interval isn't a silence, add the word to the sentence and the list of segments
			if interval_label$ <> "sil" and interval_label$ <> "sp" and interval_label$ <> ""
				# sentence$ is used only to output the annotated sentence to the user
				if sentence$ <> ""
					sentence$ = sentence$ + " " + interval_label$
				else
					sentence$ = interval_label$
				endif

				#Get the segments of the current word interval
				call getWordSegments w

				#Get the next word in the soiline
				leftbrace = index(soiline$, "{")
				rightbrace = index(soiline$, "}")
				length = rightbrace-leftbrace-1
				current_word$ = mid$(soiline$, leftbrace+1, length)
				word_len = length(soiline$)
				soiline$ = right$(soiline$, word_len-rightbrace)
	
				#Get the right transcription from the experiment file and match to segments
				call pickTranscription 'current_word$'

				#Update the soiline to include new word segments
				if new_soiline$ <> ""
					new_soiline$ = new_soiline$ + " " + chosen_trans$
				else
					new_soiline$ = chosen_trans$
				endif
			else
				word_num=word_num-1	
			endif
		endfor	

		soiline$ = new_soiline$
		printline Words in textgrid: 'sentence$'

		# Add new tier to textgrid		
		select tgrid
		tier_number = Get number of tiers
		tier_number = tier_number + 1
		last_soi_interval = 0
	
		Insert interval tier... 'tier_number' soi

		# Number of intervals on seg tier
		segs = Get number of intervals... 'segTierNumber'
		intCounter = 0

	        repeat

			soiFound = 0

			repeat
				error=0
				intCounter=intCounter+1
				if intCounter<segs
					label$ = Get label of interval... 'segTierNumber' 'intCounter'
				else
					error=1
				endif
			until label$<>"sil" and label$<>"" or error==1

            # Remove leading space
            len_soiline=length(soiline$)

		    if left$(soiline$, 1) = " "
			    soiline$ = right$(soiline$, len_soiline-1)
		    endif

			# Get next segment in soiline and truncate
	       		space = index(soiline$, " ")

	   		if space = 0
				seg$ = soiline$
				space = len_soiline
			else 
				space=space-1
			endif	

			seg$ = left$(soiline$, space)
			len = length(soiline$)
			len = len - space
			soiline$ = right$(soiline$,len-1)
			len = length(soiline$)
	
			uscore = index(seg$, "_")

			if uscore <> 0
				soiFound = 1
				leng = space  - uscore
				nextLabel$ = right$(seg$, leng)
				seg$ = left$(seg$, (uscore-1))
			endif


			#printline label 'label$' seg 'seg$'
			
			if label$ <> seg$
				printline Unmatched seg in labfile: 'label$' segment: 'seg$'
			elsif soiFound=1
				start = Get starting point... 'segTierNumber' 'intCounter'
				end = Get end point... 'segTierNumber' 'intCounter'

				endprevious=0

				if last_soi_interval <> 0
					endprevious = Get end point... 'tier_number' 'last_soi_interval'
				endif
			
				if endprevious <> start
					Insert boundary... 'tier_number' 'start'
					last_soi_interval=last_soi_interval+1
				endif

				last_soi_interval=last_soi_interval+1

				Insert boundary... 'tier_number' 'end'
				Set interval text... 'tier_number' 'last_soi_interval' 'nextLabel$'

				printline 'nextLabel$' 'label$'

	   		endif

	 	until soiline$=""		

		select tgrid
		if dry_run<>1
			Write to text file... 'filename$'
			select tgrid
			Remove
		endif
	endif

endfor


select soi_file
Remove

select filenames
Remove
printline 
printline done
