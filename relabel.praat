# Relable (chael@mcgill.ca)
echo Write transcription into .lab files for each soundfile in a directory


# script that creates .lab files with a transcription for soundfiles 
# it looks up labels in a spreadsheet contains a lab colum
# it can identify the right row in the spreadsheet in one of two ways:
#  (i) using the filename (spreadsheet should contain column with soundfilename)
#  (ii) by parsing the name for identifying information separated by underscores (you have to specify the filename structure, e.g.: experiment_participant_item_condition)
# it will then look up columns that contain that information ('id columns', e.g.: experiment_item_condition)
 

form Write lab files	
	sentence fileWithLabColumn ../../PhocusW.txt
    sentence labelColumn plannedProduction
    comment Either go by whole file name or parse filename and look up id columns:
    boolean parseName yes
    # if not parsing filename, give filename column
    sentence fileNameColumn recordedFile
    # if parsing filename, give filename format and specify id columns
	sentence Id_columns experiment_item_condition
    sentence filenameFormat experiment_participant_item_condition
    choice Case: 3 
       button keep same
       button upper case
       button lower case
    boolean RemovePunctuation yes
	boolean Dry_run 1
endform


procedure idColumns columns$

# This procedure saves the id-column-names in an array (column_name'number'))
# and identifies how many identifying columns there are (numberIDColumns)


numberIDColumns = 0

repeat

	numberIDColumns = numberIDColumns + 1

	seperator = index (columns$, "_")
	if seperator = 0
		column_name'numberIDColumns'$ = columns$
		columns$ = ""
	else
		column_name'numberIDColumns'$  = left$(columns$,seperator-1)
		len = length(columns$)
		len = len - seperator
		columns$ = right$(columns$, len)
	endif	

until columns$=""
	
endproc




procedure columnIndex name$

# This procedure identifies where in the name 
# the information corresponding to the id-columns is.

numberNameParts = 0

currentColumn = 0

repeat 

numberNameParts = numberNameParts + 1
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

for k to numberIDColumns
	if nameColumn$ = column_name'k'$
		column_index'k' = currentColumn  	
	endif
endfor

until name$ = ""

if columns$ <> ""
	exit id_columns and name_columns don't match up!
endif

endproc




procedure parsename txt$

# This precedure identifies the right textline in the _woi file for a given sound file
# if there no corresponding line, then an empty string is returned.

	columnCount = 0
	select labFile
	
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

		for cl to numberIDColumns
			if column_index'cl'=columnCount
				column_value'cl'$ = currentColumn$
			endif 
		endfor

		fileID$=currentColumn$

	until txt$ = ""
endproc


procedure getLabel

  select labFile 
  rw = 0
  labText$ = ""

  if parseName

    # get relevant information from filename by parsing it based on underscores
    call parsename 'filename$'


    if columnCount <>  numberNameParts
       printline File 'filename$' doesn't have specified filename format 
    else

       # look up id columns to see which line is the right one
	   repeat
	    	rw = rw + 1

      		yessir = 1
      		for cl to numberIDColumns
      			name$ = column_name'cl'$
      			slabel$ = Get value... 'rw' 'name$'
	      		if slabel$ <> column_value'cl'$
			 	   yessir = 0
	   		   endif
		   endfor
		
		   if yessir
		      	labText$ = Get value... 'rw' 'labelColumn$'
		   endif

         until  (labText$ <> "") or (rw = nrows)
      endif 
   else
     # just look up filename in fileNameColumn

     repeat
       rw = rw + 1
       rowFileName$ = Get value... 'rw' 'fileNameColumn$'

       if filename$ = rowFileName$
            labText$ = Get value... 'rw' 'labelColumn$'
       endif

     until (labText$ <> "") or (rw = nrows)
     
   endif

   # delete punctuation and turn into upper case
   if labText$ <> ""
       if case$ = "upper case"
         labText$ =replace_regex$(labText$, ".", "\U&", 0)
       endif 
      
       if case$ = "lower case"
         labText$ =replace_regex$(labText$, ".", "\L&", 0)
       endif 

       if removePunctuation		
          labText$ = replace$ (labText$, ".", "", 0)
	      labText$ = replace$ (labText$, ":", "", 0)
	      labText$ = replace$ (labText$, ",", "", 0)
	      labText$ = replace$ (labText$, """", "", 0)
	      labText$ = replace$ (labText$, "  ", " ", 0)
       endif
   endif

endproc


#
#
# Main script continues
#
#


call idColumns 'id_columns$'

#  Read in spreadsheet with lab column
Read Table from tab-separated file... 'fileWithLabColumn$'
labFile = selected("Table")
nrows = Get number of rows

# 
call columnIndex  'filenameFormat$'

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
	
	# get correct line and look up lab annotation
	call getLabel

   # output labels for dry run
   if dry_run=1
    printline 'i'/'numberOfLoops': 'filename$'
    printline Transcription: 'labText$'
   endif

   # output where script is every 50 files
   if i/50 = round(i/50)
     printline Labeled 'i'/'numberOfLoops': 'filename$'
     printline 
   endif

    if labText$<>""
		len=length(filename$)
		len=len-4
		filename$=left$(filename$,len)

		# save original tgrid	
		if dry_run<>1
			 labText$ > 'filename$'.lab
		endif
    else
      # output files for which no label was found
      printline Problem with 'i'/'numberOfLoops': 'filename$' --- No label found!
      printline
	endif
 
endfor


select labFile
Remove

select filenames
Remove