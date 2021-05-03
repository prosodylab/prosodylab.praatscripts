# Annotation/truncation script 
# michael wagner. chael@mcgill.ca. 2009/2020

Text writing preferences: "UTF-8"

#
# Every soundfile in the folder is brought up in an editor window
# you have to edit the annotation categories by hand
#
# -- make sure correct columns are added
# -- make sure that annotations are stored in correct column before saving spreadsheet again
# -- when you anntoate, always check after annotation one file whether things are propertly recorded

# You can use an existing spreadsheet and add annotation columns to that
# Or you can generate a new spreadsheet based on all sound files in a directory
# If you generate a new file, the order of rows will be randomized
# If you use an existing files, it assumes that they are already in the order you want to annotate in

# When you truncate:
# You can have the script make a case what's the part that you want to keep
# You can change the selection by hand.
# Whatever is selected when you hit 'continue' is what the soundfile will be truncated to
# The lab text or textgrid will also be saved
#
# If directories truncated/ and untruncated/ don't exist yet, click on 'make directories'
# The script automatically also truncates the textgrid file if there is one, 
# and it copies the label (.lab) file into both folders (if there is one)
#
# A truncation log is kept, so the script can look up which files where already truncated before.
#

echo Annotation Script
printline


form Annotation
    comment Annotator name and annotation file:
    sentence left_annotator nameAnnotator
    sentence right_responsesFile althutAnnotation.txt
    boolean RandomizePresentationOrder yes
    #
    comment Start new annotation, create response file, or add rows?
	boolean newAnnotation
	boolean makeDirectory
    boolean CreateNewResponsesFile no
    boolean AddRowsForNewSoundFiles no
    # Annotation file name:
	
    #
    comment Soundfile location (specify directory if not same) and extension:
	boolean Soundfile_in_same_directory_as_script no
	sentence left_soundDirectory ../recordedFilesWav
    sentence right_Extension .wav
	sentence filenameFormat experiment_participant_item_condition
    comment Load TexgGrids (empty if same), or create new from template (empty if not)?
	sentence left_gridDirectory
	sentence right_templateGrid
    #
    comment Save sound, lab, and Textgrid?
	boolean truncate yes
    comment Make guess of what part of sound to keep?
    boolean make_guess no
	natural silenceThreshhold 50
    #
    comment Zone in to certain part (specify woiTier and WOI if yes)?
	optionmenu ZoneIn: 1
		option No
		option up to word of interest
		option as of word of interest
		option start after word of interest
    natural left_woiTier 3
	integer right_zoneWOI 1
    positive marginSize 0.1
    comment Restrict to certain conditions, and if yes which?
	optionmenu conditionRestriction: 1
		option No
		option only annotate this condition
		option don't annotate this condition
    natural restrictCondition 1
    comment Restrict to certain experiment?
	optionmenu experimentRestriction: 3
		option No
		option only annotate this experiment
		option don't annotate this experiment
    sentence restrictExperiment micCheck
endform


# simplify variable names
#
extension$ = right_Extension$
soundDirectory$ = left_soundDirectory$
woiTier = left_woiTier
zoneWoi = right_zoneWOI
templateGrid$ = right_templateGrid$
gridDirectory$ = left_gridDirectory$
annotator$ = left_annotator$
responsesFile$ =  right_responsesFile$


createTextGridFromTemplate = 0
if templateGrid$ <> ""
  createTextGridFromTemplate = 1
endif


# Store names of the parts of the filename 
call storeNameParts 'filenameFormat$'


procedure storeNameParts nameFormat$
  #
  #
  # This procedure saves the nameParts in an array (namePart'number'))
  # and identifies how many identifying parts there are (numberNameParts)
  #
  numberNameParts = 0
  
  repeat
  
    numberNameParts = numberNameParts + 1

	seperator = index (nameFormat$, "_")
	if seperator = 0
		namePart'numberNameParts'$ = nameFormat$
		nameFormat$ = ""
	else
		namePart'numberNameParts'$  = left$(nameFormat$,seperator-1)
		len = length(nameFormat$)
		len = len - seperator
		nameFormat$ = right$(nameFormat$, len)
	endif	

  until nameFormat$ = ""

endproc


procedure parsename fileName$ namePart$
#
# This procedure parses the file name
# based on the variable filenameFormat
# This is useful so that one can find the participant information
# and if necessary mark all files of a participant as problematic/non-native/etc.
# and thereby avoid having to annotate them all
#

    partCount = 0
    relevantPart$ = ""

    # avoid _ in "session_id" to be considered a cut-point
    fileName$  = replace$(fileName$,"SESSION_ID","SESSIONID",0)

	repeat 
		partCount = partCount + 1

		# cut next part of name up to underscore or extension
		seperator = index (fileName$, "_")
		if seperator = 0
			seperator = index (fileName$,".")
			currentPart$ = left$(fileName$,seperator-1)
			fileName$ = ""
		else
			currentPart$ = left$(fileName$, seperator-1)
			len = length(fileName$)
			len = len - seperator
			fileName$ = right$(fileName$, len)
		endif

        if namePart'partCount'$ = 'namePart$'
          relevantPart$ = currentPart$
        endif

	until fileName$ = ""
endproc

# If trying to zone in to word of interest, show which one:
if zoneIn <> 1
    printline Script tries to zone in to 'zoneIn$': 'zoneWOI'
endif

if makeDirectory
  system mkdir truncated
endif 

if soundfile_in_same_directory_as_script
  directory_sound$ = ""
else
  directory_sound$ = "'directory_sound$'/"
endif   


# Create response files with all .wav files names in random order
#
if createNewResponsesFile
   if fileReadable(responsesFile$)
	 exitScript: "There already exists a response file with the name 'responsesFile$'!"
   else
     Create Strings as file list... responsesFile 'soundDirectory$'/*.wav
     fileList = selected("Strings")
     numberSoundFiles = Get number of strings
     if numberSoundFiles = 0
       exitScript:"No soundfiles found when trying to create response file"
     endif
     #
     # Uncomment following lines to make order or rows random
     #To Permutation... no
     #length = Get number of elements
     #permutation = selected("Permutation")
     #Permute randomly... 1 'length'
     #randomizedPermutation = selected("Permutation")
     #plus fileList
     #Permute strings
     #select permutation
     #Remove
     #select randomizedPermutation
     #Remove
     #
     select fileList
     Insert string... 1 recordedFile
     Save as raw text file... 'responsesFile$'
     Remove
  endif
endif

# Add rows for new soundfiles if desired and save file

if addRowsForNewSoundFiles
   if fileReadable(responsesFile$) = 0
     exitScript: "There is not file 'responsesFile$'yet!"
   else

     filesAdded = 0

     Read Table from tab-separated file... 'responsesFile$'
     responseFile = selected("Table")

     numberRows = Get number of rows

	 # list of soundfiles
     Create Strings as file list... fileList 'soundDirectory$'/*.wav
     fileList = selected("Strings")

     numberOfFiles = Get number of strings

	 for i from 1 to numberOfFiles

        select fileList
        soundName$ = Get string... 'file'

        select responseFile
        fileAlreadyThere = Search column... recordedFile 'soundName$'

		if fileAlreadyThere = 0
          Append row
          numberRows = numberRows + 1
          Set string value... numberRows "recordedFile" 'soundName$'
          filesAdded = filesAdded + 1
        endif

     endfor

     if filesAdded <> 0
       Write to table file... 'responsesFile$'
     endif
     
     select fileList
     #Remove
     select responseFile
     #Remove

     printline Files added to spreadsheet: 'filesAdded'
     printline

  endif
endif




# Read in response file
Read Table from tab-separated file... 'responsesFile$'
responsesFile = selected("Table")

trials = Get number of rows


# Set presentation order
if randomizePresentationOrder
  Create Permutation... PresentationOrder 'trials' no
else
  Create Permutation... PresentationOrder 'trials' yes
endif

presentationOrder = selected("Permutation")

# Add annotator columns if they aren't already theres
if newAnnotation 
	select responsesFile
    alreadyThere = Get column index... "'annotator$'_quality"
    if alreadyThere = 1
        exitScript: "Column 'annotator$'_quality already exists!"
    else
		Append column... 'annotator$'_tuneBeginning
		Append column... 'annotator$'_tuneEnd
		Append column... 'annotator$'_quality
		Append column... 'annotator$'_comments
    endif
endif


for i from 1 to trials

  select presentationOrder
  file = Get value... 'i'
  
  select responsesFile
  filename$ = Get value... 'file' recordedFile
  soundfile$ = soundDirectory$ + "/" + filename$

  annotateThisFile = 1

  # check if already annotated

  annot$ = Get value... 'file' 'annotator$'_quality

  if (annot$ <> "" and annot$ <> "?")
    annotateThisFile = 0
  endif
	
  # restrict to certain conditions if desired
  if conditionRestriction$ <> "No"
    call parsename 'filename$' "condition"
    if (conditionRestriction$ = "only annotate this condition") and (relevantPart$ <> "'restrictCondition'")
      annotateThisFile = 0
    elsif (conditionRestriction$ = "don't annotate this condition") and (relevantPart$ = "'restrictCondition'")
      annotateThisFile = 0
    endif
  endif

  # restrict to certain experiments if desired
  if experimentRestriction$ <> "No"
    call parsename 'filename$' "experiment"
    if (experimentRestriction$ = "only annotate this experiment") and (relevantPart$ <> restrictExperiment$)
      annotateThisFile = 0
    elsif (experimentRestriction$ = "don't annotate this experiment") and (relevantPart$ = restrictExperiment$)
      annotateThisFile = 0
    endif
  endif

  if annotateThisFile = 1

    if fileReadable(soundfile$) = 0
      printline 'i'/'trials': File 'filename$' (row: 'file') not readable
    else
      Read from file... 'soundfile$'
      soundfile = selected("Sound")
      totallength = Get end time
      onsettime = 0
      offsettime = totallength

      # extract participant name from soundfilename
      call parsename 'filename$' "participant"
      participant$ = relevantPart$

      # extract experiment name from sounfilename
      call parsename 'filename$' "experiment"
      experiment$ = relevantPart$

      # output information about trial
      printline 'i'/'trials': 'filename$' Row: 'file'
      printline   Experiment: 'experiment$' Participant: 'participant$'

          
      length = length(filename$)
      length2 = length(extension$)
      length = length - length2
      short$ = left$(filename$, length)

      txtgrd = 0

      # Create textrid from template if desired, or read one from folder
      if createTextGridFromTemplate
         if fileReadable (templateGrid$)
           txtgrd = 1
           Read from file... 'templateGrid$'
           soundgrid = selected("TextGrid")
         else
           exitScript: "Can't read template TextGrid 'templateGrid$'!"
         endif
      endif    

      grid$ = gridDirectory$ + "/" +short$+".TextGrid"
      gridshort$ = short$+".TextGrid"

      if fileReadable (grid$) & txtgrd = 1
        exitScript: "There is already a TextGrid at 'grid$'!"
      endif

      if fileReadable (grid$)
        txtgrd = 2
        Read from file... 'grid$'
        soundgrid = selected("TextGrid")
      endif

      # Read lab file if there is one

      lab$ = soundDirectory$ + "/" + short$+".lab"
      labshort$ = short$ + ".lab"
      lab = 0

      if fileReadable(lab$)
        lab = 1
        Read Strings from raw text file... 'lab$'
		labelfile = selected("Strings")
		label$ = Get string... 1
		Remove

		# add lab to textgrid if there is one, otherwise create new textgrid
	    if txtgrd <> 0
          select soundgrid
          Insert interval tier... 1 'lab'
          woiTier = woiTier + 1
        else
          select soundfile  
          To TextGrid... lab
          soundgrid = selected("TextGrid")
        endif

        Set interval text... 1 1 'label$'
      endif


      # Make guess about begin and end of sondfile
      if make_guess
        select soundfile
        To Intensity... 100 0
        soundintense = selected("Intensity")
        n = Get number of frames

        onsetfound = 0	
        offsetfound = 0

        for y to n
          intensity = Get value in frame... y	
          if intensity < silenceThreshhold and onsetfound = 1 and offsetfound = 0
            offsettime =  Get time from frame... y
            offsetfound = 1
            if (offsettime+marginSize)<=totallength
              offsettime=offsettime+marginSize
            endif
          elsif intensity > silenceThreshhold and onsetfound = 0
            onsettime =  Get time from frame... y
            onsetfound = 1
            # add a little silence at beginning:
            if (onsettime-marginSize)>0
              onsettime=onsettime-marginSize
            endif
          elsif intensity > silenceThreshhold
            offsetfound = 0
          endif
        endfor	
      endif


      if txtgrd <> 0 and zoneIn$ <> "No"
        select soundgrid
		nTier = Get number of tiers
        if nTier >= woiTier
			ninter = Get number of intervals... 'woiTier'
			for j to ninter
				labint$ = Get label of interval... 'woiTier' j
			
				if labint$="'zoneWOI'" or labint$="'zoneWOI' "
				    printline Zone in 'zoneIn$': 'labint$'

                   if zoneIn$="up to word of interest" 
 
				    	offsettime= Get end point... 'woiTier' j
						if (offsettime+marginSize)<totallength
		              		offsettime=offsettime+marginSize
                      	endif

                   elsif zoneIn$="start after word of interest"

				    	onsettime= Get end point... 'woiTier' j
						if (onsettime+marginSize)<totallength
		              		onsettime=onsettime+marginSize
                      	endif

					else
				    	onsettime= Get start point... 'woiTier' j
		            	if (onsettime-marginSize)>0
		              		onsettime=onsettime-marginSize
                      	endif

				   endif
              endif
			endfor
		else
			printline "There is no tier 'woiTier' to zone in, there are only 'nTier' tiers"
        endif
      endif


      # Annotate and truncate

      # Anonymize filenames so condition is not apparent

      select soundgrid 
      Rename... soundname

      select soundfile
      Rename... soundname
      editorname$ = "Sound"

      if (txtgrd <> 0) or (lab <> 0)
      	plus soundgrid
      	editorname$ = "TextGrid"
      endif

Edit
editor 'editorname$' soundname
  Select... onsettime offsettime	
  if zoneIn$ <> "No"
	Zoom to selection
  endif
				
  beginPause: "Annotation/Truncation"
	boolean: "TruncateAndSaveSound" , 'truncate'
	boolean: "SaveLabFile", 'truncate'
	choice: "tuneBeginning", 1
		option: "Unclear"
		option: "Rise"
		option: "High-Level"
		option: "Low-Level"
		option: "H*"
		option: "H* L%"
	choice: "tuneEnd", 1
		option: "Unclear"
		option: "EarlyFall"
		option: "LateFall"
		option: "H*"
		option: "Deaccented"
	sentence: "comments", ""
	optionMenu: "Quality", 1
		option: "OK"
		option: "Not Fluent"
		option: "Not Native"
		option: "Did not do task"
		option: "Wrong words"
		option: "Recording cut off"
		option: "Recording didn't work"
		option: "Testrun"
		option: "Problematic"
		option: "Alignment off"
		option: "WOI annotation didn't work"
	comment: "Check the following to avoid annotation/truncation of remaining files of"
	comment: "participant: 'participant$'"
	boolean: "applyQualitytoAllfilesofParticipant", 0
  clicked = endPause: "Continue", 1
				
  if truncateAndSaveSound = 0
    Select... onsettime offsettime
  else
    onsettime = Get start of selection
    offsettime = Get end of selection
  endif		
			
  Extract selected sound (time from 0)
  nsound=selected("Sound")

  if (txtgrd <> 0) or (lab = 1)
    Extract selected TextGrid (time from 0)
    newsoundgrid = selected("TextGrid")
  endif

endeditor

select responsesFile

if applyQualitytoAllfilesofParticipant = 0	
	Set string value... 'file' 'annotator$'_tuneBeginning 'tuneBeginning$'
	Set string value... 'file' 'annotator$'_tuneEnd 'tuneEnd$'
	Set string value... 'file' 'annotator$'_quality 'quality$'
	Set string value... 'file' 'annotator$'_comments 'comments$'
else
	# check whether there is a column 'participant'. If not, use column 'recordedFile
	participantColumn = Get column index... "participant"

	if participantColumn = 1
	  for j from 1 to trials
		rowParticipant$ = Get value... 'j' participant
        rowFile$ = Get value... 'j' recordedFile
		if rowParticipant$ = participant$
			Set string value... 'j' 'annotator$'_quality 'quality$'
            printline   File will be ignored: 'rowFile$'
		endif
      endfor
	else
	  for j from 1 to trials
        rowFile$ = Get value... 'j' recordedFile
		call parsename 'rowFile$' "participant"
		if relevantPart$ = participant$
			Set string value... 'j' 'annotator$'_quality 'quality$'
            printline   File will be ignored: 'rowFile$'
		endif
      endfor
    endif 

endif

Write to table file... 'responsesFile$'

if saveLabFile
  labshort$ = short$ + ".lab"
  select newsoundgrid 
  labtext$ = Get label of interval... 1 1
  labtext$ = labtext$ + newline$
  labtext$ > truncated/'labshort$'
endif

if truncateAndSaveSound

  # save truncated sound	
  select nsound
  Write to WAV file... truncated/'filename$'
  printline Saved soundfile 'filename$'

  # save truncated grid if there is one	
  if txtgrd <> 0
    select newsoundgrid 
    if lab = 1
	  # Remove tier with lab-file content
      Remove tier... 1
    endif
    Write to text file... truncated/'gridshort$'
    printline Saved TextGrid 'gridshort$'
  endif
endif

# If TextGrid generated from Template, save even if not truncating
if (truncateAndSaveSound) = 0 & txtgrd = 1
  select newsoundgrid 
  if lab = 1
    # Remove tier with lab-file content
    Remove tier... 1
  endif
  Write to text file... truncated/'gridshort$'
  printline Saved TextGrid 'gridshort$'
endif


if make_guess
  select soundintense 
  Remove
endif

select soundfile
Remove

select nsound
Remove


if (txtgrd <> 0) or (lab = 1)
  select soundgrid 
  Remove
  select newsoundgrid 
  Remove
endif

endif
endif


endfor


select presentationOrder
plus responsesFile
Remove

