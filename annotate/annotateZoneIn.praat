# Filter Files 
# michael wagner. chael@mcgill.ca. August 2009

Text writing preferences: "UTF-8"

#
# Every soundfile in the folder is brought up in an editor window, the suggested truncation is selected.
# You can change the selection by hand.
# Whatever is selected when you hit 'continue' is what the soundfile will be truncated to.
#
# If directories truncated/ and untruncated/ don't exist yet, click on 'make directories'
# The script automatically also truncates the textgrid file if there is one, 
# and it copies the label (.lab) file into both folders (if there is one)
#
# A truncation log is kept, so the script can look up which files where already truncated before.
#

echo Truncate Silence from Soundfiles
printline

form Truncate Silence from Soundfiles
    sentence annotator Michael
	natural silenceThreshhold 50
	sentence Woi_file givrep4_responses_Michael.txt
	sentence Extension .wav
	boolean Soundfile_in_same_directory_as_script no
	sentence sound_Directory ../1_soundfiles/
	boolean makeDirectory
	boolean addcolumn 0
	boolean truncate no
    boolean make_guess no
	comment Zoning in? (set woiTier to 0 if not)
	natural woiTier 4
	integer wordOfInterest 0
    positive marginSize 0.2
endform


#  Read in woi file
Read Table from tab-separated file... 'woi_file$'
woi_file = selected("Table")

if addcolumn 
	select woi_file
	Append column... 'annotator$'_shift
	Append column... 'annotator$'_quality
	Append column... 'annotator$'_comments
endif

if makeDirectory
	system mkdir truncated
	system mkdir problematic
endif 

if soundfile_in_same_directory_as_script
    directory_sound$ = ""
else
     directory_sound$ = "'directory_sound$'/"
endif   

trials = Get number of rows

for i from 1 to trials

    select woi_file
    annot$ = Get value... 'i' 'annotator$'_shift
    condition = Get value... 'i' condition

    if (annot$ = "" or annot$ ="?")
        filename$ = Get value... 'i' recordedFile
	    printline 'filename$' 'i'/'trials'
	    soundfile$ = sound_Directory$ + filename$


 	    if fileReadable(soundfile$)
    
          Read from file... 'soundfile$'
          soundfile = selected("Sound")
          
	      length = length(filename$)
	      length2 = length(extension$)
	      length = length - length2
  	      short$ = left$(filename$, length)

	      grid$ = sound_Directory$+short$+".TextGrid"
	      gridshort$ = short$+".TextGrid"

	      lab$ = sound_Directory$+short$+".lab"
	      labshort$ = short$ + ".lab"

	      txtgrd = 0
 
    	  if fileReadable (grid$)
          	Read from file... 'grid$'
	  	    Insert interval tier... 1 sound
	  	    txtgrd = 1
	  	    soundgrid = selected("TextGrid")	
     	  elsif fileReadable(lab$)
	  	    txtgrd = 2
		    select soundfile
	  	    To TextGrid... label
	  	    soundgrid = selected("TextGrid")
	  	    Read Strings from raw text file... 'lab$'
	 	    labelfile = selected("Strings")
	  	    label$ = Get string... 1
	 	    Remove
	   	    select soundgrid
           	Set interval text... 1 1 'label$'
	      endif

        printline 'lab$' 'txtgrd' textgrid

        select soundfile
        totallength = Get end time

        onsettime = 0
        offsettime = totallength

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


zoneIn = 0

if txtgrd <> 0 and woiTier <> 0
        select soundgrid
		nTierr = Get number of tiers
        if nTierr >= woiTier
			ninter = Get number of intervals... 'woiTier'
			for j to ninter
				labint$ = Get label of interval... 'woiTier' j
			
				if labint$="'wordOfInterest'" or labint$="'wordOfInterest' "
				    printline Zone in to woi: 'labint$'
				    onsettime= Get start point... 'woiTier' j
		            if (onsettime-marginSize)>0
		              onsettime=onsettime-marginSize
                      endif
                      zoneIn = 1
				endif
			endfor
		else
			printline "No tier 'woiTier' for looking up woi and zoning in"
        endif
endif



# Truncate!

		select soundgrid 
		Rename... soundname

		select soundfile
		editorname$ = "Sound"

		if txtgrd <> 0
			plus soundgrid
			editorname$ = "TextGrid"
		endif

		Edit
		 editor 'editorname$' soundname
			 	Select... onsettime offsettime	
				if zoneIn=1
					Zoom to selection
				endif
				
				beginPause("Annotation/Truncation")
					boolean ("Problematic",0)
                   boolean ("Truncate",'truncate')
					boolean ("SaveWavAndLabFile",'truncate')
				    anno = choice ("shift",1)
					        option ("No Shift")
					        option ("Shift to adjective")
                    	    option ("Unclear")
                   			option ("Problematic")
                    anno = choice ("quality",1)
                   	        option ("ok")
                   	        option ("Not Fluent")
					        option ("Problematic")
                    sentence("comments","")
				clicked = endPause("Continue",1)
				
			   if truncate = 0
				   Select... onsettime offsettime
			   else
				   onsettime = Get start of selection
				   offsettime = Get end of selection
		       endif		
			
			  Extract selected sound (time from 0)
			  nsound=selected("Sound")
		      if txtgrd<>0
				Extract selected TextGrid (time from 0)
				newsoundgrid = selected("TextGrid")
			 endif
		   endeditor

		select woi_file
		Set string value... 'i' 'annotator$'_shift 'shift$'
		Set string value... 'i' 'annotator$'_quality 'quality$'
		Set string value... 'i' 'annotator$'_comments 'comments$'
		Write to table file... 'woi_file$'

	if  saveWavAndLabFile
		if problematic=0
			select nsound
			Write to WAV file... truncated/'filename$'
			
			if txtgrd = 1
				select newsoundgrid 
				Write to text file... truncated/'gridshort$'
			elsif txtgrd = 2
				printline yes
				labshort$ = short$ + ".lab"
				select newsoundgrid 
				labtext$ = Get label of interval... 1 1
    				labtext$ = labtext$ + newline$
				labtext$ > truncated/'labshort$'

			endif

			printline  'filename$'

		else 
			select nsound
			Write to WAV file... problematic/'filename$'

			if txtgrd = 1
				select soundgrid
				Write to text file... problematic/'gridshort$'
			elsif txtgrd = 2
				select newsoundgrid 
				labtext$ = Get label of interval... 1 1
    				labtext$ = labtext$ + newline$
				labtext$ > problematic/'labshort$'
			endif

			printline  'filename$' was *not* truncated and saved!
		endif
	  endif
	
       if make_guess
		select soundintense 
		Remove
       endif

		select soundfile
		  Remove
		  select nsound
		  Remove

			if txtgrd = 1
				select soundgrid 
				Remove
				select newsoundgrid 
				Remove
			elsif txtgrd = 2
				select newsoundgrid 
				Remove
				select soundgrid 
				Remove
			endif

endif
endif



endfor


select woi_file
Remove

