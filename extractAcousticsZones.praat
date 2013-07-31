# Calculate various acoustic variables
# Michael Wagner. chael@mcgill.ca. July 2009

echo Measure

# This script measures various acoustic variables in our annotated files
# You have to *select* all sound files that you want to be included before
# running the script. All soundfiles without corresponding TextGrid files 
#  in the object list are ignored.


## The following procedure cuts apart the file name at underscores and hyphens
## and returns a tab-delimited variable with the pieces
procedure cutname thename$
   remain$ = thename$
   return$ = ""

# cut name into columns

repeat

     seper = index (remain$, "_")

     if seper = 0
         return$ = return$ + remain$
         remain$ = ""
     else
        seper = seper - 1
        return$ = return$ + left$(remain$, seper) +  "'seperator$'"
      
     	len = length(remain$)
     	len = len - seper -1
        remain$ = right$(remain$, len)
     endif

until remain$ = ""  
	
# now tab delimited columns from name are in variable return$
	   
endproc


form Calculate Results for Production Experiments
	sentence Name_Format experiment_participant_item_condition
	sentence Result_filename socrlo
	sentence extension .wav
	sentence Sound_directory ../2_data/2_soundfiles/
	natural woiTier 3
	natural wordTier 2
        natural phonTier 1
endform

output$ = "" 
output$ > 'result_filename$'.txt

seperator$=tab$

call cutname 'name_Format$'

# This creates the column labels:

call cutname 'name_Format$'

# This creates the column labels:

columnNames$ = return$ + tab$
columnNames$ = columnNames$ + "woilabel" + tab$
columnNames$ = columnNames$ + "wordlabel" + tab$
columnNames$ = columnNames$ + "phonelength" + tab$
columnNames$ = columnNames$ + "duration" + tab$
columnNames$ = columnNames$ + "silence" + tab$
columnNames$ = columnNames$ + "durasil" + tab$
columnNames$ = columnNames$ + "meanpitch" + tab$
columnNames$ = columnNames$ + "maxpitch" + tab$
columnNames$ = columnNames$ + "maxPitTime" + tab$
columnNames$ = columnNames$ + "minPitch" + tab$
columnNames$ = columnNames$ + "minPitTime" + tab$
columnNames$ = columnNames$ + "firstpitch" + tab$
columnNames$ = columnNames$ + "secondpitch" + tab$
columnNames$ = columnNames$ + "thirdpitch" + tab$
columnNames$ = columnNames$ + "fourthpitch" + tab$
columnNames$ = columnNames$ + "meanIntensity" + tab$
columnNames$ = columnNames$ + "maxIntensity" + tab$

columnNames$ = columnNames$ + "zduration" + tab$
columnNames$ = columnNames$ + "zbeginzone" + tab$
columnNames$ = columnNames$ + "zendzone" + tab$
columnNames$ = columnNames$ + "zphonelength" + tab$
columnNames$ = columnNames$ + "zmeanpitch" + tab$
columnNames$ = columnNames$ + "zmaxpitch" + tab$
columnNames$ = columnNames$ + "zmaxPitTime" + tab$
columnNames$ = columnNames$ + "zminPitch" + tab$
columnNames$ = columnNames$ + "zminPitTime" + tab$
columnNames$ = columnNames$ + "zfirstpitch" + tab$
columnNames$ = columnNames$ + "zsecondpitch" + tab$
columnNames$ = columnNames$ + "zthirdpitch" + tab$
columnNames$ = columnNames$ + "zfourthpitch" + tab$
columnNames$ = columnNames$ + "zmeanIntensity" + tab$
columnNames$ = columnNames$ + "zmaxIntensity" + tab$

columnNames$ = columnNames$ + "filename" + newline$

columnNames$ >> 'result_filename$'.txt

# This keeps track of how many files were considered for measurements:
filesconsidered = 0

Create Strings as file list... list 'sound_directory$'*'extension$'
n = Get number of strings

# Now we'll cycle through all files and do the measurments

for i to n
   select Strings list
   filename$ = Get string... i
   Read from file... 'sound_directory$''filename$'

   length = length(filename$)
   length2 = length(extension$)
   length = length - length2
   dummy$ = left$(filename$, length)

     call cutname 'dummy$'
 
    grid$ = sound_directory$ +dummy$+".TextGrid"
 
    if fileReadable (grid$)
      Read from file... 'grid$'
   
        numberTiers = Get number of tiers
  
        filesconsidered = filesconsidered + 1

 	call cutname 'dummy$'
   
	select Sound 'dummy$'
     	To Pitch (ac)... 0 75 15 no 0.02 0.45 0.01 0.35 0.14 350.0
     	select Sound 'dummy$'
     	To Intensity... 100 0.0 yes        

        select TextGrid 'dummy$'
        numbInt = Get number of intervals... woiTier
        numbIntWord = Get number of intervals... wordTier
    
       # counter counts the silent intervals separating words
       counter = 0
 	
	beginzone=0
	endzone=0
	zphonelength=0

       for interval from 1 to numbIntWord

    		select TextGrid 'dummy$'
		label$ = Get label of interval... wordTier interval

		#only measure annotated words
		if label$ <> "" 

               	wordonset = Get starting point... wordTier interval
          	wordoffset = Get end point... wordTier interval

		if beginzone=0
			beginzone=wordonset
		endif

		phoneinterval = Get interval at time... 1 'wordonset'
		phonelast = Get interval at time... 1 'wordoffset'
		wphonelength=phonelast - phoneinterval
		zphonelength = zphonelength + wphonelength

		here=wordonset+0.001

		hereinterval = Get interval at time... 'woiTier' 'here'
		woilabel$ = Get label of interval... woiTier hereinterval

		# end of zone reached?
    		if woilabel$ <> ""

  		wduration = 0
  		wsilence = 0
  		wdurasil = 0
  		wmeanpitch = 0
  		wmaxpitch = 0
  		wminpitch = 0
  		wmaxPitTime = 0
  		wminPitTime = 0
  		wfirstpitch = 0
  		wsecondpitch = 0
  		wthirdpitch = 0
  		wfourthpitch = 0
  		wmeanIntensity = 0
  		wmaxIntensity = 0

    		zduration = 0
  		zmeanpitch = 0
  		zmaxpitch = 0
  		zminpitch = 0
  		zmaxPitTime = 0
  		zminPitTime = 0
  		zfirstpitch = 0
  		zsecondpitch = 0
  		zthirdpitch = 0
  		zfourthpitch = 0
  		zmeanIntensity = 0
  		zmaxIntensity = 0

		wduration=wordoffset-wordonset
		endzone=wordoffset
		zduration=endzone-beginzone

		# Is next interval a silence?
		intervalSil = interval + 1

		# this 'if' will ignore final 'sil'---they shouldn't be counted. to include, <=
		if intervalSil < numbIntWord 
			labelsil$ = Get label of interval... 'wordTier' 'intervalSil'
			if labelsil$ = "sil" or labelsil$="sp"
              			silonset = Get starting point... 'wordTier' 'intervalSil'
          			siloffset = Get end point... 'wordTier' 'intervalSil'
				wsilence = siloffset - silonset
			endif
		endif

		wdurasil = wduration + wsilence
		duration=wduration

		nzone = extractNumber(woilabel$,"")

		# Get pitch and intensity measures

		# Get intensity

		      select Intensity 'dummy$'
			meanIntensity = Get mean... 'wordonset' 'wordoffset'
			minIntensity = Get minimum... 'wordonset' 'wordoffset' Parabolic
			minIntTime = Get time of minimum... 'wordonset' 'wordoffset' Parabolic
			maxIntensity = Get maximum... 'wordonset' 'wordoffset' Parabolic
			maxIntTime = Get time of maximum... 'wordonset' 'wordoffset' Parabolic

			maxIntTime = (maxIntTime - wordonset) / duration
			minIntTime = (minIntTime - wordonset) / duration

		

	     	# Get pitch measures

             	select Pitch 'dummy$'

                meanpitch = Get mean... 'wordonset' 'wordoffset' Hertz
               	maxpitch = Get maximum... 'wordonset' 'wordoffset' Hertz Parabolic
                minpitch = Get minimum... 'wordonset' 'wordoffset' Hertz Parabolic
		maxPitTime = Get time of maximum... 'wordonset' 'wordoffset' Hertz Parabolic
		maxPitTime = maxPitTime - wordonset
		minPitTime = Get time of minimum... 'wordonset' 'wordoffset' Hertz Parabolic
		minPitTime = minPitTime - wordonset

             	first = wordonset +(duration/ 4)
             	second = wordonset +(duration/ 2)
             	third = wordonset +(duration* (3/4))

	     	firstpitch = Get mean... 'wordonset' 'first' Hertz
		secondpitch = Get mean... 'first' 'second' Hertz
		thirdpitch = Get mean... 'second' 'third' Hertz
		fourthpitch = Get mean... 'third' 'wordoffset' Hertz

		output$=return$ + tab$
		output$ = output$ + "'woilabel$'" + tab$
		output$ = output$ + "'label$'" + tab$
		output$ = output$ + "'wphonelength:3'" + tab$
		output$ = output$ + "'wduration:3'" + tab$
		output$ = output$ + "'wsilence:3'" + tab$
		output$ = output$ + "'wdurasil:3'" + tab$
		output$ = output$ + "'meanpitch:3'" + tab$
		output$ = output$ + "'maxpitch:3'" + tab$
		output$ = output$ + "'maxPitTime:3'" + tab$
		output$ = output$ + "'minpitch:3'" + tab$
		output$ = output$ + "'minPitTime:3'" + tab$
		output$ = output$ + "'firstpitch:3'" + tab$
		output$ = output$ + "'secondpitch:3'" + tab$
		output$ = output$ + "'thirdpitch:3'" + tab$
		output$ = output$ + "'fourthpitch:3'" + tab$
		output$ = output$ + "'meanIntensity:3'" + tab$
		output$ = output$ + "'maxIntensity:3'" + tab$

			wordonset=beginzone
			wordoffset=endzone
			duration=zduration

			# Get intensity

		      select Intensity 'dummy$'
			meanIntensity = Get mean... 'wordonset' 'wordoffset'
			minIntensity = Get minimum... 'wordonset' 'wordoffset' Parabolic
			minIntTime = Get time of minimum... 'wordonset' 'wordoffset' Parabolic
			maxIntensity = Get maximum... 'wordonset' 'wordoffset' Parabolic
			maxIntTime = Get time of maximum... 'wordonset' 'wordoffset' Parabolic

			maxIntTime = (maxIntTime - wordonset) / duration
			minIntTime = (minIntTime - wordonset) / duration


	     	# Get pitch measures

             	select Pitch 'dummy$'

                meanpitch = Get mean... 'wordonset' 'wordoffset' Hertz
               	maxpitch = Get maximum... 'wordonset' 'wordoffset' Hertz Parabolic
                minpitch = Get minimum... 'wordonset' 'wordoffset' Hertz Parabolic
		maxPitTime = Get time of maximum... 'wordonset' 'wordoffset' Hertz Parabolic
		maxPitTime = maxPitTime - wordonset
		minPitTime = Get time of minimum... 'wordonset' 'wordoffset' Hertz Parabolic
		minPitTime = minPitTime - wordonset

             	first = wordonset +(duration/ 4)
             	second = wordonset +(duration/ 2)
             	third = wordonset +(duration* (3/4))

	     	firstpitch = Get mean... 'wordonset' 'first' Hertz
		secondpitch = Get mean... 'first' 'second' Hertz
		thirdpitch = Get mean... 'second' 'third' Hertz
		fourthpitch = Get mean... 'third' 'wordoffset' Hertz


		output$ = output$ + "'duration:3'" + tab$
		output$ = output$ + "'beginzone:3'" + tab$
		output$ = output$ + "'endzone:3'" + tab$
		output$ = output$ + "'zphonelength:3'" + tab$
		output$ = output$ + "'meanpitch:3'" + tab$
		output$ = output$ + "'maxpitch:3'" + tab$
		output$ = output$ + "'maxPitTime:3'" + tab$
		output$ = output$ + "'minpitch:3'" + tab$
		output$ = output$ + "'minPitTime:3'" + tab$
		output$ = output$ + "'firstpitch:3'" + tab$
		output$ = output$ + "'secondpitch:3'" + tab$
		output$ = output$ + "'thirdpitch:3'" + tab$
		output$ = output$ + "'fourthpitch:3'" + tab$
		output$ = output$ + "'meanIntensity:3'" + tab$
		output$ = output$ + "'maxIntensity:3'" + tab$

		output$ = output$ + "'dummy$'" + newline$

                output$ >> 'result_filename$'.txt

		beginzone=0
		endzone=0
		zphonelength = 0

		endif
	   endif       
	endfor
     
             	select Pitch 'dummy$'
		Remove

		select   Intensity 'dummy$'
		Remove
  
                select TextGrid 'dummy$'
                Remove
    
	        select Sound 'dummy$'
                Remove

        endif 
   endfor   

   printline Soundfiles selected: 'n'
   printline Files considered: 'filesconsidered'

