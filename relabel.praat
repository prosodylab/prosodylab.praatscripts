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

		fileID$=currentColumn$

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
				woiline$ = Get value... 'rw' lab
			
		endif

		endif

		woiline$ =replace_regex$(woiline$, ".", "\U&", 0)
		woiline$ = replace$ (woiline$, ".", "", 0)
		woiline$ = replace$ (woiline$, ":", "", 0)
		woiline$ = replace$ (woiline$, ",", "", 0)
		woiline$ = replace$ (woiline$, """", "", 0)
		woiline$ = replace$ (woiline$, "  ", " ", 0)


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
	sentence Woi_file ../../1_experiment/mlteuf8.txt
	sentence Id_columns experiment_item_condition
	sentence Filename_format experiment_participant_item_condition_file
	natural wordTierNumber 2
	boolean Dry_run 1
endform

call idColumns 'id_columns$'

#  Read in woi file
Read Table from tab-separated file... 'woi_file$'
woi_file = selected("Table")

# 
call columnIndex  'filename_format$'

# Strings of all sounds files
Create Strings as file list... list  *.wav
filenames = selected("Strings")
numberOfFiles = Get number of strings

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
		len=length(filename$)
		len=len-4
		filename$=left$(filename$,len)
		printline 'filename$'
		printline lab 'woiline$'

		# save original tgrid	
		if dry_run<>1
			 woiline$ > 'filename$'.lab
		endif

	endif

endfor


select woi_file
Remove

select filenames
Remove