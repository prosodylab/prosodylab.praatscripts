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


# This precedure identifies the right textline in the _woi file for a given sound file
# if there no corresponding line, then an empty string is returned.

procedure parsename txt$
	columnCount = 0
	select woi_file
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


procedure getWoiLine

	rw = 0
	woiline$ = ""

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
			woiline$ = Get value... 'rw' woi
		endif

		woiline$ =replace_regex$(woiline$, ".", "\U&", 0)
		woiline$ = replace$ (woiline$, ".", "", 0)
		woiline$ = replace$ (woiline$, ":", "", 0)
		woiline$ = replace$ (woiline$, ",", "", 0)
		woiline$ = replace$ (woiline$, "j'", "j ", 0)
		woiline$ = replace$ (woiline$, "t'", "t ", 0)
		woiline$ = replace$ (woiline$, "s'", "s ", 0)
		woiline$ = replace$ (woiline$, "c'", "c ", 0)
		woiline$ = replace$ (woiline$, "d'", "d ", 0)
		woiline$ = replace$ (woiline$, "l'", "l ", 0)
		woiline$ = replace$ (woiline$, "n'", "n ", 0)
		woiline$ = replace$ (woiline$, "qu'", "qu ", 0)
		woiline$ = replace$ (woiline$, "m'", "m ", 0)
		woiline$ = replace$ (woiline$, "jusqu'", "jusqu ", 0)
		woiline$ = replace$ (woiline$, "y'", "y ", 0)
		woiline$ = replace$ (woiline$, "&", "et", 0)
		woiline$ = replace$ (woiline$, "'", "", 0)
		woiline$ = replace$ (woiline$, """", "", 0)


until  (woiline$ <> "") or (rw = nrows)

endproc


procedure parseline 
# this procedure returns the next woi and its label and returns a pruned string
# nextWoi$ extracted from  textline$, nextLabel$ determined, textline$ is pruned

woiFound = 0

repeat

space = index(woiline$, " ")
word$ = left$(woiline$, space)

if space = 0
	word$ = woiline$
	space = length(woiline$)
endif

uscore = index(word$, "_")

if uscore <> 0
	woiCount = woiCount + 1
	nextWoi$ = left$(word$, (uscore-1))
	leng = space - uscore
	nextLabel$ = mid$(woiline$, (uscore+1), leng)
	woiFound = 1
endif 

len = length(woiline$)
len = len - space
woiline$ = right$(woiline$,len)
len = length(woiline$)

until (woiFound = 1) or (len=0)

endproc





form Annotate Words of Interest	
	sentence Woi_file 0_confre_french_newWOI_utf8.txt
	sentence Id_columns experiment_item_condition
	sentence Filename_format experiment_lan_participant_item_condition
	natural wordTierNumber 2
	boolean Dry_run 1
	boolean restore_old_before 0
endform

storeold$="0_oldTextGrids"

if restore_old_before = 1
     system mv 'storeold$'/*.TextGrid .
     system rmdir 'storeold$'
endif

call idColumns 'id_columns$'

#  Read in woi file
Read Table from tab-separated file... 'woi_file$'
woi_file = selected("Table")

# 
call columnIndex  'filename_format$'

# Strings of all sounds files
Create Strings as file list... list  *.TextGrid
filenames = selected("Strings")
numberOfFiles = Get number of strings

if dry_run=0
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
	Read from file... 'filename$'
	tgrid = selected("TextGrid")

	# save original tgrid	
	if dry_run<>1
		Write to text file... 'storeold$'/'filename$'
	endif
	
	# get correct textline$ with woi annotation
	call parsename 'filename$'

	call getWoiLine

       if woiline$<>""

		printline
		printline 'filename$'
		printline 'woiline$'

	# Add new tier to textgrid		
	select tgrid
	tier_number = Get number of tiers
	tier_number = tier_number + 1
	
	Insert interval tier... 'tier_number' woi

	# Number of intervals on word tier
	words = Get number of intervals... 'wordTierNumber'


		# Get first woi
	woiCount = 0
	current_woi_interval = 1
	call parseline 'woiline$'

	for j to words

		label$ = Get label of interval... 'wordTierNumber' 'j'
   
   		if label$ = nextWoi$	

			start = Get starting point... 'wordTierNumber' 'j'
			end = Get end point... 'wordTierNumber' 'j'

			endprevious = Get starting point... 'tier_number' 'current_woi_interval'

			if endprevious <> start
				Insert boundary... 'tier_number' 'start'
				current_woi_interval = current_woi_interval + 1
			endif

			Insert boundary... 'tier_number' 'end'

			Set interval text... 'tier_number' 'current_woi_interval' 'nextLabel$'

			printline 'nextLabel$' 'label$'
			current_woi_interval = current_woi_interval + 1
			call parseline 'textline$'
   		endif

	endfor  		

	select tgrid
	if dry_run<>1
		Write to text file... 'filename$'
	endif

	endif

	select tgrid
	Remove

endfor


select woi_file
Remove

select filenames
Remove