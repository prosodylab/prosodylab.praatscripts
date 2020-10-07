# Annotate words of interest
echo Annotate Words of Interest 


# This procedure saves the id-column-names in an array (column_name'number'))
# and identifies how many identifying columns there are (numberColumns)
procedure idColumns columns$


form Annotate Words of Interest	
	sentence Woi_file ../givrep5_woi.txt
	sentence Id_columns experiment_item_condition
	sentence Filename_format experiment_participant_item_condition
	natural wordTierNumber 1
	boolean Dry_run 1
	boolean restore_old_before 0
	boolean mkDir 0
endform



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

		woiline$ = replace$ (woiline$, "10", "ten", 0)
		woiline$ = replace$ (woiline$, ". ", " ", 0)
		woiline$ = replace$ (woiline$, "10", "ten", 0)
		woiline$ = replace$ (woiline$, "7", "seven", 0)
		woiline$ = replace_regex$(woiline$, ".", "\L&", 0)
		woiline$ = replace$ (woiline$, "’", "'", 0)
		woiline$ = replace$ (woiline$, "it's", "it s", 0)
		woiline$ = replace$ (woiline$, "she's", "she is", 0)
		woiline$ = replace$ (woiline$, "i've", "i ve", 0)
		woiline$ = replace$ (woiline$, "i'll", "i ll", 0)
		woiline$ = replace$ (woiline$, ".", "", 0)
		woiline$ = replace$ (woiline$, "  ", " ", 0)
		woiline$ = replace$ (woiline$, ":", "", 0)
		woiline$ = replace$ (woiline$, "!", " ", 0)
		#woiline$ = replace$ (woiline$, "—", " ", 0)
		woiline$ = replace$ (woiline$, "-", " ", 0)
		woiline$ = replace$ (woiline$, ", ", " ", 0)
		woiline$ = replace$ (woiline$, ",", "", 0)
		woiline$ = replace$ (woiline$, """", "", 0)
		woiline$ = replace$ (woiline$, ";", "", 0)
		woiline$ = replace$ (woiline$, "  ", " ", 0)
		woiline$ = replace$ (woiline$, "'S", " S", 0)
		woiline$ = replace$ (woiline$, "’S", " S", 0)
		woiline$ = replace$ (woiline$, "  ", " ", 0)
		woiline$ = replace$ (woiline$, "  ", " ", 0)
		woiline$ = replace$ (woiline$, "  ", " ", 0)
		woiline$ = replace$ (woiline$, "  ", " ", 0)
		woiline$ = replace$ (woiline$, "yo yo", "yo-yo", 0)
		woiline$ = replace$ (woiline$, "ice cold", "ice-cold", 0)
		woiline$ = replace$ (woiline$, "five card", "five-card", 0)
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
	
	# get correct textline$ with woi annotation
	call parsename 'filename$'
	call getWoiLine

        if woiline$<>""
		Read from file... 'filename$'
		printline 'filename$'
		tgrid = selected("TextGrid")

		# save original tgrid	
		if dry_run<>1
			Write to text file... 'storeold$'/'filename$'
		endif

		printline
		printline 'filename$'
		printline woi-annotation: 'woiline$'

        gridEnd=Get end time
        
		# Add new tier to textgrid		
		select tgrid
		tier_number = Get number of tiers
		tier_number = tier_number + 1
		last_woi_interval = 0
	
		Insert interval tier... 'tier_number' woi

		# Number of intervals on word tier
		words = Get number of intervals... 'wordTierNumber'
		intCounter = 0

	    repeat

		woiFound = 0

		repeat
			intCounter=intCounter+1
			if intCounter <= words
    			label$ = Get label of interval... 'wordTierNumber' 'intCounter'
			endif
		until (label$<>"sil" and label$<>"sp" and label$<>"") or intCounter > words


		# Get next word in woiline and truncate
		#
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
	
		uscore = index(word$, "_")

		if uscore <> 0
			woiFound = 1
			leng = space  - uscore
			nextLabel$ = right$(word$, leng)
			word$ = left$(word$, (uscore-1))
		endif 	
				
		if label$ <> word$ and label$ <> "<unk>"
			printline Unmatched word: textgrid: 'label$' woilineword: 'word$'
		elsif woiFound=1
			start = Get starting point... 'wordTierNumber' 'intCounter'
			end = Get end point... 'wordTierNumber' 'intCounter'

			endprevious=0

			if last_woi_interval <> 0
				endprevious = Get end point... 'tier_number' 'last_woi_interval'
			endif
			
			if endprevious <> start
					Insert boundary... 'tier_number' 'start'
					last_woi_interval=last_woi_interval+1
			endif
			
			last_woi_interval=last_woi_interval+1

            #make sure boundary is not at very end to avoid error
			if end = gridEnd
				end=end-0.001
			endif

			Insert boundary... 'tier_number' 'end'
			Set interval text... 'tier_number' 'last_woi_interval' 'nextLabel$'

			printline 'nextLabel$' 'label$'

	   	endif

	 	until woiline$=""		

		select tgrid
		if dry_run<>1
			Write to text file... 'filename$'
		endif
		select tgrid
		Remove

	endif

endfor


select woi_file
Remove

select filenames
Remove