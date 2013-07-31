# Openfiles 
# michael wagner. chael@mcgill.ca. August 2009

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
	natural silenceThreshhold 50
        boolean make_guess yes
	sentence Extension .wav
	boolean Soundfile_in_same_directory_as_script no
	sentence Directory_sound ../3_data/
	boolean makeDirectory
endform

if makeDirectory
	system mkdir truncated
	system mkdir problematic
endif 

if soundfile_in_same_directory_as_script
    directory_sound$ = ""
else
     directory_sound$ = "'directory_sound$'/"
endif   


Create Strings as file list... list 'directory_sound$'*'extension$'
filelist = selected("Strings")
numberFiles = Get number of strings

 if fileReadable ("0_truncateLog.txt")
          Read Table from table file... 0_truncateLog.txt
	  Append row
	  numberTruncated=Get number of rows
else
	Create Table with column names... truncatetable 1 truncated
        numberTruncated=1
endif
truncateLog = selected("Table")


for ifile to numberFiles
   select Strings list
   filename$ = Get string... ifile
    
   Read from file... 'directory_sound$''filename$'
   soundfile = selected("Sound")

   # check whether already truncated
   truncated = 0
   select  truncateLog
   for itruncate to numberTruncated
	truncated$ = Get value... itruncate truncated
	if truncated$=filename$
		truncated=1
	endif
   endfor
  
   if truncated = 0
	   length = length(filename$)
	   length2 = length(extension$)
	   length = length - length2
  	   short$ = left$(filename$, length)

	   grid$ = directory_sound$+short$+".TextGrid"
	   gridshort$ = short$+".TextGrid"

	   lab$ = directory_sound$+short$+".lab"
	   labshort$ = short$ + ".lab"

	   txtgrd = 0
 
    	   if  fileReadable(lab$)
	  	txtgrd = 2
		select soundfile
	  	To TextGrid... label
	  	soundgrid = selected("TextGrid")
	  	Read Strings from raw text file... 'lab$'
	 	labelfile = selected("Strings")
	  	label$ = Get string... 1
	 	Remove
	   	select soundgrid
           	Set interval text... 1 1 	'label$'	
	   endif

     select soundfile
     totallength = Get end time

     onsettime = 0
     offsettime = 0

# Make guess about begin and end of sondfile

if make_guess
     select soundfile
     To Intensity... 100 0
     soundintense = selected("Intensity")
     n = Get number of frames

     onsetfound = 0	
     offsetfound = 0

    for i to n
	intensity = Get value in frame... i	
     	if intensity < silenceThreshhold and onsetfound = 1 and offsetfound = 0
		offsettime =  Get time from frame... i
		offsetfound = 1
	elsif intensity > silenceThreshhold and onsetfound = 0
		onsettime =  Get time from frame... i
	        onsetfound = 1
	elsif intensity > silenceThreshhold
		offsetfound = 0
	endif
    endfor	

endif

if make_guess and onsettime <> 0 and offsettime <> 0
		onsettime = onsettime - 0.0020
		offsettime = offsettime + 0.020
 else 
		onsetttime = 0
		offsettime = totallength
endif


# Truncate!
		select soundfile
		editorname$ = "Sound"

		if txtgrd <> 0
			plus soundgrid
			editorname$ = "TextGrid"
		endif

		Edit
		 editor 'editorname$' 'short$'
			 	Select... onsettime offsettime					
	
				beginPause("Truncate?")
					boolean ("Problematic",0)
                                        boolean ("Truncate",0)
				clicked = endPause("Continue",1)

			    if truncate = 0
				Select... onsettime offsettime
			   else
				onsettime = Get start of selection
				offsettime = Get end of selection
		           endif		
			
			  Extract selected sound (time from 0)
		          if txtgrd<>0
				Extract selected TextGrid (time from 0)
				newsoundgrid = selected("TextGrid")
			 endif
		endeditor

		if problematic=0
			select Sound untitled
			Write to WAV file... truncated/'filename$'
			Remove

			select soundfile 
		        Remove
			
			if txtgrd = 1
				select newsoundgrid 
				Write to text file... truncated/'gridshort$'
				select soundgrid 
				Remove
			elsif txtgrd = 2
				printline yes
				labshort$ = short$ + ".lab"
				select newsoundgrid 
				labtext$ = Get label of interval... 1 1
    				labtext$ = labtext$ + newline$
				labtext$ > truncated/'labshort$'
				Remove
				select soundgrid 
				Remove
			endif

			printline  'filename$'

		else 
			select Sound untitled
			Write to WAV file... problematic/'filename$'
			Remove

			select soundfile 
		        Remove

			if txtgrd = 1
				select soundgrid
				Write to text file... problematic/'gridshort$'
				Remove
				select soundgrid 
				Remove
			elsif txtgrd = 2
				select newsoundgrid 
				labtext$ = Get label of interval... 1 1
    				labtext$ = labtext$ + newline$
				labtext$ > problematic/'labshort$'
				Remove
				select soundgrid 
				Remove
			endif

			printline  'filename$' was *not* truncated and saved!
		endif
	
	
       if make_guess
		select soundintense 
		Remove
       endif

	select truncateLog
	row=Get number of rows
	Set string value... 'row' truncated 'filename$'
	Write to table file... 0_truncateLog.txt
	Append row

endif
endfor

select filelist
Remove

select truncateLog
Remove
