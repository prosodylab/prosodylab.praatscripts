# Calculate various acoustic variables
# Michael Wagner. chael@mcgill.ca. July 2004/July 2009/Updated July 2014

echo Extract Acoustic Measures for Words and Zones

# This script measures various acoustic variables in our annotated files
# All soundfiles without corresponding TextGrid files in the folder are ignored

form Calculate Results for Production Experiments
	sentence Name_Format experiment_participant_item_condition
	sentence Output_Filename cont
	sentence extension .wav
	# Specify directory -- otherwise selected soundfiles will be annotated
	sentence Sound_directory ../4_annotate/truncated
	natural Required_Tiers 3
        natural phonTier 1
	natural wordTier 2
	natural woiTier 3
	#Number of pitch points per interval for average curves
	natural Number_of_Measure_Points 10
endform

procedure cutname thename$
	# This procedure parses the file at underscores 
	# and returns a tab-delimited variable with the parts

	remain$ = thename$
	return$ = ""

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
	#
	# now a tab delimited string with the column names is in variable return$
endproc

#
# Main script
#

# Write into tab-delimited file (rather than comma delimited)
seperator$=tab$

# This creates the column labels from the filename structure:
call cutname 'name_Format$'

# This adds the additional column labels:

columnNamesPit$=""
for i to number_of_Measure_Points
	columnNamesPit$=columnNamesPit$ + "pitch'i', pitch'i'_time, "
endfor

columnNamesInt$ =  replace$(columnNamesPit$,"pitch","intensity",0)

columnNames$=return$ + ", fileName, word, wordLabel, woiLabel, wordOnset, wordOffset, duration, silence, duraSil, phoneLength, "
columnNames$= columnNames$ + "meanPitch, maxPitch, maxPitTime, minPitch, minPitTime, " + columnNamesPit$ + "meanIntensity, maxIntensity, maxIntTime, "  + columnNamesInt$
columnNames$ = columnNames$ + "zstart, zend,  zDuration, zPhonelength, zmeanPitch, zmaxPitch, zmaxPitTime, zminPitch, zminPitTime, zmeanIntensity, zmaxIntensity, zmaxIntTime, zLabel"
columnNames$=replace$(columnNames$,", ",tab$,0)
columnNames$ = columnNames$ + newline$

# Write column names to output file in same directory as script is in
columnNames$ > 'output_Filename$'.txt

# This keeps track of how many files were considered for measurements:
filesconsidered = 0

Create Strings as file list... list 'sound_directory$'/*'extension$'
myStrings=selected()
n = Get number of strings

# Now we'll cycle through all files and do the measurments
missinggrids=0
missinggrid$=""

for i to n
   select Strings list
   filename$ = Get string... i
   length = length(filename$)
   length2 = length(extension$)
   length = length - length2
   shortname$ = left$(filename$, length)
   call cutname 'shortname$'
   grid$ = sound_directory$ + "/" + shortname$+".TextGrid"
    if fileReadable (grid$)=0
        missinggrids+=1
	missinggrid$= missinggrid$ + "'missinggrids'" + tab$ + shortname$+".wav" + tab$ + "No TextGrid" + newline$
    else
	Read from file... 'sound_directory$'/'filename$'
   	mySound=selected()
        Read from file... 'grid$'
        myGrid=selected()
        numberTiers = Get number of tiers
        if numberTiers < required_Tiers
        	missinggrids+=1
		missinggrid$= missinggrid$ + "'missinggrids'" + tab$ + shortname$+".wav" + tab$ + "No enough tiers" + newline$
	else
	        filesconsidered = filesconsidered + 1
   
		select mySound

		# Two step pitch extraction following praat group post by Daniel Hirst
		# but using 75,500 as lower and upper limit
		noprogress To Pitch... 0.01 75 500
		floor = Get quantile... 0 0 0.25 Hertz
		ceiling = Get quantile... 0 0 0.75 Hertz
		Remove
		if floor = undefined
			floor = 75
		else
			floor = max(75,floor*0.75)
			floor=min(150,floor)
		endif

		if ceiling = undefined
			ceiling = 600
		else
			ceiling = min(600,ceiling*1.5)
		endif


		select mySound
		myPitch = noprogress To Pitch... 0.01 floor ceiling
		select mySound
	     	myIntensity = noprogress To Intensity... 100 0.0 yes        

 	       select myGrid
	        numbInt = Get number of intervals... woiTier
	        numbIntWord = Get number of intervals... wordTier
    
	        # counter counts the number of words annotated
	        wcounter = 0
 	
		zstart=0
 		zend=0
		phonelength= 0
		zphonelength=0
		zlabel$=""

 	       for interval from 1 to numbIntWord

 	   		select myGrid
			label$ = Get label of interval... wordTier interval
	
			if label$ <> ""  
			    #only measure words that have been labeled

			    if label$ <>  "sil" and label$ <> "sp"			
				# only add measures for none-silence intervals (silence intervals following words will be measured when the preceding word is measured)

				wcounter+=1

				if zlabel$ = ""
					zlabel$=label$
				else
					zlabel$=zlabel$ + " " + label$
				endif

 	              		wordonset = Get starting point... wordTier interval
	          		wordoffset = Get end point... wordTier interval
				wduration=wordoffset-wordonset

				if zstart =0
					zstart=wordonset
				endif

				phoneinterval = Get interval at time... 1 'wordonset'
				phonelast = Get interval at time... 1 'wordoffset'
				wphonelength=phonelast - phoneinterval
				zphonelength = zphonelength + wphonelength

				here=wordonset+0.001
				hereinterval = Get interval at time... 'woiTier' 'here'
				woilabel$ = Get label of interval... woiTier hereinterval


				# Is next interval a silence?
				intervalSil = interval + 1
				wsilence = 0
				wdurasil = 0

				# the following 'if' will ignore final 'sil'---they shouldn't be counted. to include, use "<="
				if intervalSil < numbIntWord 
					labelsil$ = Get label of interval... 'wordTier' 'intervalSil'
					if labelsil$ = "sil" or labelsil$="sp"
	              				silonset = Get starting point... 'wordTier' 'intervalSil'
	          				siloffset = Get end point... 'wordTier' 'intervalSil'
						wsilence = siloffset - silonset
						wdurasil = wduration + wsilence
					endif
				endif

				# Add word measures to output
				output$=return$ + tab$ +  shortname$  + tab$ + "'wcounter'"  + tab$ + "'label$'" + tab$ + "'woilabel$'" + tab$ + "'wordonset:4'" + tab$ +  "'wordoffset:4'" + tab$ + "'wduration:4'" + tab$ + "'wsilence:3'" + tab$ + "'wdurasil:3'" +  tab$ + "'wphonelength:3'" 

				nwoi = extractNumber(woilabel$,"")

				# Get pitch measures
				select myPitch

				meanpitch = Get mean... 'wordonset' 'wordoffset' Hertz
	               		maxpitch = Get maximum... 'wordonset' 'wordoffset' Hertz Parabolic
	                	minpitch = Get minimum... 'wordonset' 'wordoffset' Hertz Parabolic
				maxPitTime = Get time of maximum... 'wordonset' 'wordoffset' Hertz Parabolic
				maxPitTime = maxPitTime - wordonset
				minPitTime = Get time of minimum... 'wordonset' 'wordoffset' Hertz Parabolic
				minPitTime = minPitTime - wordonset

				# Add pitch measures to output
				output$ = output$ +tab$ +  "'meanpitch:3'" + tab$ + "'maxpitch:3'" + tab$ + "'maxPitTime:3'" + tab$  + "'minpitch:3'" + tab$ + "'minPitTime:3'" 

				# Get invidual pitch measures
				distance=wduration/number_of_Measure_Points
				for j to number_of_Measure_Points
					slicetime=wordonset+j*distance
					pitch'j'_time=slicetime
					pitch'j'=do ("Get value at time...", slicetime,"Hertz", "Linear")
					output$ = output$ + tab$ + fixed$(pitch'j',3) + tab$ + fixed$(pitch'j'_time,3)
				endfor

				# Get intensity

			      	select myIntensity
				meanIntensity = Get mean... 'wordonset' 'wordoffset'
				maxIntensity = Get maximum... 'wordonset' 'wordoffset' Parabolic
				maxIntTime = Get time of maximum... 'wordonset' 'wordoffset' Parabolic
				maxIntTime = maxIntTime - wordonset

				# Add intensity measures to output
				output$ = output$ + tab$ +  "'meanIntensity:3'" + tab$  + "'maxIntensity:3'" + tab$ + "'maxIntTime:3'" 

	 			# Get invidual intensity measures
				for j to number_of_Measure_Points
					slicetime=wordonset+j*distance
					intensity'j'_time=slicetime
					intensity'j'=do ("Get value at time...", slicetime, "Linear")
					output$ = output$ + tab$ + fixed$(intensity'j',3) + tab$ + fixed$(intensity'j'_time,3)
				endfor

 				# end of zone reached?
    				if woilabel$ <> ""
					# zone measures here
					zend=wordoffset
					zduration=zstart-zend

					# add measures to output
					output$ = output$ + tab$ + "'zstart:3'" + tab$ + "'zend:3'"  + tab$ + "'zduration:3'" + tab$ + "'zphonelength'"

					# pitch measures for zone
					select myPitch
					zmeanPitch = Get mean... 'zstart' 'zend' Hertz
					zmaxPitch = Get maximum... 'zstart' 'zend'  Hertz Parabolic
					zmaxPitchTime = Get time of maximum... 'zstart' 'zend'  Hertz Parabolic
					zmaxPitchTime = zmaxPitchTime - zstart 
					zminPitch = Get minimum... 'zstart' 'zend'  Hertz Parabolic
					zminPitchTime = Get time of minimum... 'zstart' 'zend'  Hertz Parabolic
					zminPitchTime = zminPitchTime - zstart 
					#
					output$ = output$ + tab$ + "'zmeanPitch:3'" + tab$ + "'zmaxPitch:3'" + tab$ + "'zmaxPitchTime:3'" + tab$ + "'zminPitch:3'" + tab$ + "'zminPitchTime:3'" 	

					# intensity measures for zone
					select myIntensity
					zmeanIntensity = Get mean... 'zstart' 'zend'
					zmaxIntensity = Get maximum... 'zstart' 'zend' Parabolic
					zmaxIntTime = Get time of maximum... 'zstart' 'zend' Parabolic
					zmaxIntTime = maxIntTime - zstart
					#
					output$ = output$ + tab$ + "'zmeanIntensity:3'" + tab$ + "'zmeanIntensity:3'" + tab$ + "'zmaxIntTime:3'"  + tab$ + "'zlabel$'"
					
					zstart=0
					zlabel$=""
					zend=0
				else
					# set empty cells for zone measures if zone doesn't end here
					for j to 12
						output$ = output$ + tab$ + "" 
					endfor
				endif 

     				output$ = output$ + newline$
				output$ = replace$(output$,"--undefined--","",0)
				output$ >> 'output_Filename$'.txt



			endif
	         endif       
	  endfor
         
          select myPitch
	  plus myIntensity
	  Remove
        endif 
 
  select myGrid
  plus mySound
  Remove
  endif
  
  if i=10*round((i/10))	
 	writeInfoLine ("Processed sound 'i' of 'n'. So far, 'filesconsidered' files had measures extracted.")
  endif

endfor   

writeInfoLine("Done!")
appendInfoLine("")
appendInfoLine("Output was written to tab-delimited file 'output_Filename$'.txt.")
appendInfoLine("")
appendInfoLine("'filesconsidered' files out of 'n' had measures extracted.")
appendInfoLine("")

if missinggrids<>0
	missinggrid$ > GridMissingOrIncomplete.txt	
	appendInfoLine("There were 'missinggrids' files with TextGrids that were either missing or didn't have enough Tiers.")
	appendInfoLine("")
	appendInfoLine("See full list in tab-delimited file GridMissingOrIncomplete.txt, and below:")
	appendInfoLine("")
	appendInfoLine (missinggrid$)
endif

select myStrings
Remove

