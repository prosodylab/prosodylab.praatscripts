# Calculate various acoustic variables
# Michael Wagner. chael@mcgill.ca. July 2009

echo SOI Measures

form Calculate Results for Production Experiments
	sentence Name_Format experiment_participant_item_condition
	sentence Result_filename ersapro14-15
	sentence extension .wav
	sentence Sound_directory ../3_truncate/truncated/
	natural wordTier 2
	natural woiTier 3
	sentence seperator ,
endform

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
# assumed structure: newonly1_pc_1_item1-1-a.wav
# will cut of beginning, 'pc', and last tab (which is linger internal and irrelevant)

repeat

     seper = index (remain$, "_")
     seperh = index (remain$, "-")

     if seper = 0 
         seper = seperh
     elsif seperh <> 0  and seperh < seper
            seper = seperh
     endif

     if seper = 0
         return$ = return$ + remain$ +  "'seperator$'"
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





output$ = "" 
output$ > 'result_filename$'.txt

# This creates the column labels:

call cutname 'name_Format$'
output$ = return$ + "word" +  "'seperator$'"  + "wordlabel" + "'seperator$'" + "segment" +  "'seperator$'"
		   ... + "precedingSegment" +  "'seperator$'" + "followingSegment" +  "'seperator$'"
		    ...+ "phonelength"
                     ...+  "'seperator$'" + "duration" +  "'seperator$'" + "silence" +  "'seperator$'" + "durasil"
                     ...+  "'seperator$'" + "meanpit" +  "'seperator$'" + "maxpitch" +  "'seperator$'" + "maxPitTime"
                     ...+  "'seperator$'" + "minpitch" +  "'seperator$'" + "minPitTime" 
		     ...+  "'seperator$'" + "firstpitch" +  "'seperator$'" + "secondpitch" +  "'seperator$'" + "thirdpitch"
		     ...+  "'seperator$'" + "fourthpitch" +  "'seperator$'" + "meanIntensity" +  "'seperator$'" + "maxIntensity"
		     ...+  "'seperator$'" + "firstF1" + "'seperator$'" + "firstF2" + "'seperator$'" + "firstdif"
		     ...+  "'seperator$'" + "secondF1" + "'seperator$'" + "secondF2" + "'seperator$'" + "seconddif"
		     ...+  "'seperator$'" + "thirdF1" + "'seperator$'" + "thirdF2" + "'seperator$'" + "thirddif"
		     ...+  "'seperator$'" + "fourthF1" + "'seperator$'" + "fourthF2" + "'seperator$'" + "fourthdif"
		     ...+  "'seperator$'" + "fifthF1" + "'seperator$'" + "fifthF2" + "'seperator$'" + "fifthdif"
                     ...+ newline$

# This starts up the output file by savign the column labels:
 output$ >> 'result_filename$'.txt

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
      if numberTiers > 2

     filesconsidered = filesconsidered + 1

     printline 'i' out of 'n'

# Create all objects necessary for measurements 

     select Sound 'dummy$'
     noprogress To Pitch (ac)... 0 75 15 no 0.02 0.45 0.01 0.35 0.14 350.0
     select Sound 'dummy$'
     noprogress To Intensity... 100 0.0 yes
     select Sound 'dummy$'
     noprogress To Formant (burg)... 0 5 5500 0.025 50
    
     select TextGrid 'dummy$'
     numbInt = Get number of intervals... woiTier
     nSegIntervals = Get number of intervals... 1
     numbIntWord = Get number of intervals... wordTier
    
# counter counts the silent intervals separating words
      counter = 0
      difpitch = 0		

     for interval from 1 to numbInt

		duration = 0
		silence = 0
		durasil = 0
		pitch    = 0
		maxpitch = 0
		minpitch = 0
		cenpitch = 0   
		earpitch = 0
		power = 0
		energy = 0
		maximum = 0
		maxPitTime = 0
		minPitTime = 0
		finalpitch = 0
		initpitch = 0
		latepitch = 0
		meanIntensity = 0
		maxIntensity = 0
		maxIntTime = 0
		minIntensity = 0
		minIntTime = 0
		phonelength = 0

		# store beginning and end of current word
		
    		select TextGrid 'dummy$'
		label$ = Get label of interval... woiTier interval

		#only measure annotated words
		if label$ <> ""

               	wordonset = Get starting point... woiTier interval
          	wordoffset = Get end point... woiTier interval

		phoneinterval = Get interval at time... 2 'wordonset'
		phonelength = Get interval at time... 2 'wordoffset'
		phonelength = phonelength - phoneinterval

		# Get the duration of the current word
 
		duration = wordoffset - wordonset

		#  Get label from wordtier
		midd = wordonset + duration/2
		wordint = Get interval at time... wordTier midd
		wordlabel$ = Get label of interval... wordTier wordint

		# Get label of segment
		segInterval = Get interval at time... 1 midd
		segment$ = Get label of interval... 1 segInterval

		# Get label of preceding segment
		precedingSegment$ = ""
		precInterval = segInterval

		repeat
			precInterval = segInterval - 1
			if precInterval <> 0
				precedingSegment$ = Get label of interval... 1 precInterval
			endif
		until precedingSegment$ <> "sil" & precedingSegment$ <> "sp"

		# Get label of following segment
		followingSegment$ = ""
		precInterval = segInterval

		repeat
			precInterval = segInterval + 1
			if precInterval <= nSegIntervals
				followingSegment$ = Get label of interval... 1 precInterval
			endif
		until followingSegment$ <> "sil" & followingSegment$ <> "sp"


		# Is next interval a silence?
		intervalSil = wordint + 1

		# this 'if' will ignore final 'sil'---they shouldn't be counted. to include, <=
		if intervalSil < numbIntWord 
			labelsil$ = Get label of interval... 'wordTier' 'intervalSil'
			if labelsil$ = "sil"
              			silonset = Get starting point... 'wordTier' 'intervalSil'
          			siloffset = Get end point... 'wordTier' 'intervalSil'
				silence = siloffset - silonset
			endif
		endif

		durasil = duration + silence

		# Get power, energy and maximum

                  select Sound 'dummy$'

		  energy = Get energy... 'wordonset' 'wordoffset'
		  power = Get power... 'wordonset' 'wordoffset'
                  maximum = Get maximum... 'wordonset' 'wordoffset' Sinc70

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
		minPitTime = Get time of minimum... 'wordonset' 'wordoffset' Hertz Parabolic
		maxPitTime = (maxPitTime - wordonset) / duration
		minPitTime = (minPitTime - wordonset) / duration

             	first = wordonset +(duration/ 4)
             	second = wordonset +(duration/ 2)
             	third = wordonset +(duration* (3/4))

	     	firstpitch = Get mean... 'wordonset' 'first' Hertz
		secondpitch = Get mean... 'first' 'second' Hertz
		thirdpitch = Get mean... 'second' 'third' Hertz
		fourthpitch = Get mean... 'third' 'wordoffset' Hertz

		# Measure formants at all five times

		select Formant 'dummy$'

		firstF1 = Get value at time... 1 'wordonset' Hertz Linear
		firstF2 = Get value at time... 2 'wordonset' Hertz Linear
		firstdif = firstF2 - firstF1
		secondF1 = Get value at time... 1 'first' Hertz Linear
		secondF2 = Get value at time... 2 'first' Hertz Linear
		seconddif = secondF2 - secondF1
		thirdF1 = Get value at time... 1 'second' Hertz Linear
		thirdF2 = Get value at time... 2 'second' Hertz Linear
		thirddif = thirdF2 - thirdF1
		fourthF1 = Get value at time... 1 'third' Hertz Linear
		fourthF2 = Get value at time... 2 'third' Hertz Linear
		fourthdif = fourthF2 - fourthF1
		fifthF1 = Get value at time... 1 'wordoffset' Hertz Linear
		fifthF2 = Get value at time... 2 'wordoffset' Hertz Linear
		fifthdif = fifthF2 - fifthF1
			
		return2$ = replace$(return$,  "'seperator$'","_",0)

	 	output$ = return$  + "'label$'" + "'seperator$'" + "'wordlabel$'" + "'seperator$'" + "'segment$'" +  "'seperator$'"     
						... + "'precedingSegment$'" +  "'seperator$'"  + "'followingSegment$'" +  "'seperator$'"      
		     				... + "'phonelength'" + "'seperator$'" + 
						... "'duration:3'" +  "'seperator$'" + 
		     				... "'silence:3'" +  "'seperator$'" + 
		     				... "'durasil:3'" +  "'seperator$'" + 
						...  "'meanpitch:3'" +  "'seperator$'" + "'maxpitch:2'"
						... +  "'seperator$'" + "'maxPitTime:3'" +  "'seperator$'" + "'minpitch:2'"
						...+  "'seperator$'" + "'minPitTime:3'" +  "'seperator$'" 
                                                ...+ "'firstpitch:3'" +  "'seperator$'" +"'secondpitch:3'"
						...+  "'seperator$'" + "'thirdpitch:3'" +  "'seperator$'" + "'fourthpitch:3'"
						...+  "'seperator$'" + "'meanIntensity:3'" +  "'seperator$'" + "'maxIntensity:3'"
						...+ "'seperator$'" + "'firstF1:3'" + "'seperator$'" + "'firstF2:3'" + "'seperator$'" + "'firstdif:3'"
						...+ "'seperator$'" + "'secondF1:3'" + "'seperator$'" + "'secondF2:3'" + "'seperator$'" + "'seconddif:3'"
						...+ "'seperator$'" + "'thirdF1:3'" + "'seperator$'" + "'thirdF2:3'" + "'seperator$'" + "'thirddif:3'"
						...+ "'seperator$'" + "'fourthF1:3'" + "'seperator$'" + "'fourthF2:3'" + "'seperator$'" + "'fourthdif:3'"
						...+ "'seperator$'" + "'fifthF1:3'" + "'seperator$'" + "'fifthF2:3'" + "'seperator$'" + "'fifthdif:3'"
						...+ newline$
             
                  output$ >> 'result_filename$'.txt

	   endif       
	endfor
     
                select Pitch 'dummy$'
                Remove
		select Intensity 'dummy$'
                Remove
                select TextGrid 'dummy$'
                Remove
		select Formant 'dummy$'
		Remove
       endif
	endif
	        select Sound 'dummy$'
                Remove
   endfor   
 
   printline Soundfiles selected: 'n'
   printline Files considered: 'filesconsidered'

	if seperator$=","
		system mv  'result_filename$'.txt 'result_filename$'.csv
	endif

select Strings list
Remove

