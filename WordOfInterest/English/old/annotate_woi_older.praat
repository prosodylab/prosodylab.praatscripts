# Annotate words of interest
echo Annotate Words of Interest

nextWoi$=""


# This procedure keeps track of which columns in the name
# correspond to the columns in the _woi.txt file
# and how many identifying columns there are (numberColumns)

procedure idColumns columns$ name$

nextColumn = 1
columnCount = 0
numberColumns = 0

repeat

if nextColumn = 1 and (columns$<>"")
	seperator = index (columns$, "_")
	if seperator = 0
		currentColumn$ = columns$
		columns$ = ""
	else
		currentColumn$ = left$(columns$,seperator-1)
		len = length(columns$)
		len = len - seperator
		columns$ = right$(columns$, len)
	endif	
	nextColumn = 0
	numberColumns = numberColumns + 1
endif

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

columnCount = columnCount + 1

if nameColumn$ = currentColumn$
	column'numberColumns' = columnCount 
	nextColumn = 1	
endif

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
			if column'cl'=columnCount
				valueCol'cl'$ = currentColumn$
			endif 
		endfor

	until txt$ = ""

	rw = 0
	textline$ = ""

	repeat
		rw = rw + 1

		yessir = 1
		for cl to numberColumns
			slabel$ = Get value... 'rw' 'cl'
			if slabel$ <> valueCol'cl'$
			 	yessir = 0
			endif
		endfor

		if yessir
			cl = numberColumns + 1
			textline$ = Get value... 'rw' 'cl'
		endif

until  (textline$ <> "") or (rw = nrows)

endproc


procedure parseline 
# this procedure returns the next woi and its label and returns a pruned string
# nextWoi$ extracted from  textline$, nextLabel$ determined, textline$ is pruned

woiFound = 0

repeat

space = index(textline$, " ")
word$ = left$(textline$, space)

if space = 0
	word$ = textline$
	space = length(textline$)
endif

uscore = index(word$, "_")

if uscore <> 0
	woiCount = woiCount + 1
	nextWoi$ = left$(word$, (uscore-1))
	leng = space - uscore
	nextLabel$ = mid$(textline$, (uscore+1), leng)
	woiFound = 1
endif 

len = length(textline$)
len = len - space
textline$ = right$(textline$,len)
len = length(textline$)

until (woiFound = 1) or (len=0)

endproc




form Annotate Words of Interest	
	sentence Woi_file woi.txt
	sentence Id_columns item_condition_condition2
	sentence Filename_format exp_subj_item_condition_condition2
	sentence TextGrid_Directory ../2_seg/data/
	natural wordTierNumber 1
	boolean Dry_run 1
endform

# 
call idColumns 'id_columns$' 'filename_format$'

#  Read in text file with woi

Read Table from tab-separated file... 'woi_file$'
woi_file = selected("Table")

# Strings of all sounds files
Create Strings as file list... list 'TextGrid_Directory$'*.TextGrid
filenames = selected("Strings")
numberOfFiles = Get number of strings

if dry_run<>1
 # make directory for old textGrid files
 system mkdir  'TextGrid_Directory$'oldTextGrids
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
	Read from file... 'TextGrid_Directory$''filename$'
	
	if dry_run<>1
		Write to text file... 'TextGrid_Directory$'oldTextGrids/'filename$'
	endif
	tgrid = selected("TextGrid")

	# get correct textline$ with woi annotation
	call parsename 'filename$'

	# Get first woi
	woiCount = 0
	current_woi_interval = 1
	call parseline 'textline$'

	# Add new tier to textgrid		
	select tgrid
	tier_number = Get number of tiers
	tier_number = tier_number + 1
	
	Insert interval tier... 'tier_number' woi

	# Number of intervals on word tier
	words = Get number of intervals... 'wordTierNumber'

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
		Write to text file... 'TextGrid_Directory$''filename$'
	endif
	Remove

	printline

endfor


select woi_file
Remove

select filenames
Remove