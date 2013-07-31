# Annotate words of interest
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


form Annotate Words of Interest	
	sentence Soi_file ../../1_experiment/rogerDan_segs.txt
	sentence Dictionary_file /Applications/aligner/dictionary.txt
	sentence Id_columns experiment_item_condition
	sentence Filename_format experiment_participant_item_condition
	natural segTierNumber 1
	boolean Dry_run 1
	boolean restore_old_before 0
	boolean mkDir 0
endform

storeold$="0_oldTextGrids"

if restore_old_before = 1
     system mv 'storeold$'/*.TextGrid .
     system rmdir 'storeold$'
endif

call idColumns 'id_columns$'

#  Read in soi file
Read Table from tab-separated file... 'soi_file$'
soi_file = selected("Table")

# 
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
		printline 'filename$'
		tgrid = selected("TextGrid")

		# save original tgrid	
		if dry_run<>1
			Write to text file... 'storeold$'/'filename$'
		endif

		printline
		printline 'filename$'
		printline 'soiline$'

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
			until label$<>"sil" and label$<>"sp" or error==1

			# Get next word in soiline and truncate
			#
	       		space = index(soiline$, " ")
	   		if space = 0
				word$ = soiline$
				space = length(soiline$)
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

			if label$ <> seg$
				printline Unmatched seg in labfile: 'label$' soilineword: 'seg$'
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

#system grep -w soi$ -m 1 dictionary_file$