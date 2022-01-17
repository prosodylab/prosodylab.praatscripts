# Measure various acoustic variables

# Michael Wagner, prosodylab. chael@mcgill.ca. May 2003, revised various times since


Text writing preferences: "UTF-8"

echo Extract Acoustic Measures for intervals and zones of interest

# This script measures various acoustic variables in our annotated files
# All soundfiles without corresponding TextGrid files in the folder are ignored, as well as TextGrids that don't have a sufficient number of tiers

# The script either records measures for all intervals of interest, or for all words
# The latter option will allow to plot average measures across the utterance (e.g. pitch tracks)
# If all words are measured, intervals of interest have to correspond to words

# If there are no intervals of interest annotated, set ioiTier to zero
# In that case allWords has to be set, and measures will be returned for all words

form Calculate Results for Production Experiments
	sentence Name_Format experiment_participant_item_condition
	sentence Output_Filename phocusWAcousticsStressed
	sentence extension .wav
	comment Specify directory -- otherwise selected soundfiles will be annotated
	sentence soundDirectory ../recordedFilesAnnotate/truncated_relabeled
	sentence gridDirectory ../TextGrids
	natural wordTier 1
    natural phonTier 2
	comment Tier with intervals of interest (0 if none)
	natural ioiTier 4
	comment Measures for zones as well?
    boolean zones 1
	comment Measure all words, so one can plot entire utterance?
	comment (only works if intervals of interest correspond to entire words)
    boolean AllWords 0
	comment Multiple measures within IOI?
	boolean multiple 0
	comment Number of pitch points per interval for average curves
	natural Number_of_Measure_Points 5
	comment include formants in multiple measures?
	boolean formants 1
	comment include previous and following segment?
	boolean adjacentSegments 1
endform


#####
# cuts filenames, strings separated with column names will become column names
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


############
#
# Main script
#

# Write into tab-delimited file (rather than comma delimited)
seperator$ = tab$

# When formants are measures, multiple measures must be taken in general
if formants
	multiple = 1
	printline
	printline  Parameter multiple set to true, since formant measures were requested
	printline
endif

required_Tiers = ioiTier

# This creates the column labels from the filename structure:
call cutname 'name_Format$'

# Set column names for spreadsheet

columnNames$ = return$ + ", fileName, measuredIntervalNumber, wordLabel, ioiLabel, ioiTranscription, ioiOnset, ioiOffset, duration, silence, duraSil, phoneLength"

if adjacentSegments
	columnNames$= columnNames$ + ", precedingSegment, followingSegment"
endif

columnNames$= columnNames$ + ", meanPitch, maxPitch, maxPitTime, minPitch, minPitTime, meanIntensity, maxIntensity, maxIntTime"  

# column names for multipole measures on quantiles of interval:

if multiple
	multipleColumnNames$=""
 	for i to number_of_Measure_Points
		multipleColumnNames$ = multipleColumnNames$ + ", time'i', pitch'i', intensity'i'"
		if formants
			multipleColumnNames$ = multipleColumnNames$  + ", F1Female_'i', F2Female_'i', F1Male_'i', F2Male_'i'"
        endif
	endfor
	columnNames$ = columnNames$ + multipleColumnNames$
endif

# additional column for zones of interest if requested

if zones
	columnNames$ = columnNames$ + ", zoneWords, zNumberWords, zTranscripion, zPhoneLength, zstart, zend, zDuration, zmeanPitch, zmaxPitch, zmaxPitTime, zminPitch, zminPitTime, zmeanIntensity, zmaxIntensity, zmaxIntTime"
endif



# convert commans to tabs
columnNames$ = replace$(columnNames$,", ",tab$,0)
columnNames$ = columnNames$ + newline$

# Write column names to output file in same directory as script is in
columnNames$ > 'output_Filename$'.txt

# This keeps track of how many files were considered for measurements:
filesconsidered = 0

# get all sound file names in sound directory
Create Strings as file list... list 'soundDirectory$'/*'extension$'
myStrings=selected()
n = Get number of strings

# Now cycle through all files and do the measurments
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
   grid$ = gridDirectory$ + "/" + shortname$+".TextGrid"

   if fileReadable (grid$)=0
	 missinggrids+=1
	 missinggrid$= missinggrid$ + "'missinggrids'" + tab$ + shortname$+".wav" + tab$ + "No TextGrid" + newline$
   else
	 Read from file... 'soundDirectory$'/'filename$'
	 mySound=selected()
	 Read from file... 'grid$'
	 myGrid=selected()
	 numberTiers = Get number of tiers

	 if numberTiers < required_Tiers
        missinggrids+=1
		missinggrid$= missinggrid$ + "'missinggrids'" + tab$ + shortname$+".wav" + tab$ + "No enough tiers" + newline$
	   else
	    filesconsidered = filesconsidered + 1


		# Create all objects necessary for measurements 
   
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

		# formants extracted twice, once with male and female settings
		if formants
		     # formant extraction for female speakers
			select mySound
			myFemaleFormants = noprogress To Formant (burg)... 0 5 5500 0.025 50

			# formant extraction for male speakers
			select mySound
			myMaleFormants = noprogress To Formant (burg)... 0 5 5000 0.025 50
		endif
  
 	    select myGrid
	    numberIoi = Get number of intervals... ioiTier
	    numberWords = Get number of intervals... wordTier
    
	    # counter counts the number of words annotated
	    wcounter = 0

		# measure all labeled words if no interval of interest tier annotated
		if ioiTier = 0
			ioiTier = wordTier
		endif

		# specify which tier is used to decide whether measurements will be taken
        if allWords
			intervalCounter = numberWords
			counterInterval = wordTier
        else
			intervalCounter = numberIoi
            counterInterval = ioiTier
        endif

 	
		# (re)set segment length of interval of interest
		phonelength= 0
    
		# (re)set zone start
		zstart = 0

 	    for interval from 1 to intervalCounter

 	   		select myGrid
			label$ = Get label of interval... counterInterval interval

			ioiOnset = Get starting point... counterInterval interval
			ioiOffset = Get end point... counterInterval interval
			ioiDuration = ioiOffset - ioiOnset
			here = ioiOnset + 0.001

			# Get label of current ioi

			if allWords
				currentIoi = Get interval at time... ioiTier here
				ioiLabel$ = Get label of interval... ioiTier currentIoi
				wordLabel$ = label$
            else
				currentIoi = interval
				ioiLabel$ = Get label of interval... ioiTier currentIoi
				currentWord = Get interval at time... wordTier here
				wordLabel$ = Get label of interval... wordTier currentWord
				
			endif


            if allWords = 1
				chooserLabel$ = wordLabel$
            else
				chooserLabel$ = ioiLabel$
			endif
	
	
			# only measure words for which relevant interval has been labeled

			if chooserLabel$ <> "" 

			    #only measure words that have been labeled

			    if label$ <>  "sil" and label$ <> "sp"			
				# only add measures for none-silence intervals (silence intervals following words will be measured when the preceding word is measured)

				wcounter+=1

				# Get number of of segments in current interval under consideration

				phoneFirst = Get interval at time... 'phonTier' 'ioiOnset'
				phoneLast = Get interval at time... 'phonTier' 'ioiOffset'
				ioiPhoneLength= phoneLast - phoneFirst

				# Get transcription of interval
				ioiTranscription$ = ""
				for transc from 1 to ioiPhoneLength
					phoneLabel$ = Get label of interval... phonTier phoneFirst+transc-1
					ioiTranscription$ = ioiTranscription$ + " " + phoneLabel$
				endfor

				# Get preceding and following segment if requested
				# if previous or following is a silence, go until you find segment
				# (information that there was a pause will be implicit by non-zero  duration of 'silence' column)
				if adjacentSegments

					# Getting preceding segment
					precedingSegment$ = ""
					nextPhone = phoneFirst - 1
					while nextPhone > 0
						segmentLabel$ = Get label of interval... phonTier nextPhone
						# stop if found segment that is not a silence
						if segmentLabel$ <> "sil" & segmentLabel$ <> "sp"
							nextPhone = 0
							precedingSegment$ = segmentLabel$
						endif
						nextPhone = nextPhone - 1
					endwhile

					# Get following segment
					followingSegment$ = ""
					maxPhoneInterval = Get number of intervals... phonTier
					nextPhone = phoneLast
					while nextPhone <= maxPhoneInterval 
						segmentLabel$ = Get label of interval... phonTier nextPhone
						# stop if found segment that is not a silence
						if segmentLabel$ <> "sil" & segmentLabel$ <> "sp"
							nextPhone = maxPhoneInterval
							followingSegment$ = segmentLabel$	
						endif
						nextPhone = nextPhone + 1
					endwhile
					
				endif


				# Get label of current segment

				herePhoninterval = Get interval at time... phonTier here
				phonLabel$ = Get label of interval... phonTier herePhoninterval

				# Get segment label of phone interval following ioi interval, in order to see whether it is a silence
				there=ioiOffset+0.001
				followingPhonInterval = Get interval at time... phonTier there

				# Is next interval a silence?
				intervalSil = interval + 1
				wsilence = 0
				wdurasil = 0

				# Check whether there is a following silence, unless we're at the end anyways
				# The following 'if' will ignore final 'sil'---they shouldn't be counted, since end of silence can't be measured.  to include, change comparsion below to "<="
				# If there is a silence, measure its duration
				if intervalSil < numberWords 
					labelsil$ = Get label of interval... 'phonTier' 'followingPhonInterval'
					if labelsil$ = "sil" or labelsil$="sp"
	              		silonset = Get starting point... 'phonTier' 'followingPhonInterval'
	          			siloffset = Get end point... 'phonTier' 'followingPhonInterval'
						wsilence = siloffset - silonset
						wdurasil = ioiDuration + wsilence
					endif
				endif

				# Add word measures to output
				output$=return$ + tab$ +  shortname$  + tab$ + "'wcounter'"  + tab$ + "'wordLabel$'" + tab$ + "'ioiLabel$'" + tab$ + "'ioiTranscription$'" + tab$ + "'ioiOnset:4'" + tab$ +  "'ioiOffset:4'" + tab$ + "'ioiDuration:4'" + tab$ + "'wsilence:3'" + tab$ + "'wdurasil:3'" +  tab$ + "'ioiPhoneLength'" 

				# Add preceding and following if requested
				if adjacentSegments
					output$ = output$ + tab$ +  "'precedingSegment$'" + tab$  + "'followingSegment$'"
				endif

				# Get pitch measures
				select myPitch

				meanpitch = Get mean... 'ioiOnset' 'ioiOffset' Hertz
	            maxpitch = Get maximum... 'ioiOnset' 'ioiOffset' Hertz Parabolic
	            minpitch = Get minimum... 'ioiOnset' 'ioiOffset' Hertz Parabolic
				maxPitTime = Get time of maximum... 'ioiOnset' 'ioiOffset' Hertz Parabolic
				maxPitTime = maxPitTime - ioiOnset
				minPitTime = Get time of minimum... 'ioiOnset' 'ioiOffset' Hertz Parabolic
				minPitTime = minPitTime - ioiOnset

				# Add pitch measures to output
				output$ = output$ +tab$ +  "'meanpitch:3'" + tab$ + "'maxpitch:3'" + tab$ + "'maxPitTime:3'" + tab$  + "'minpitch:3'" + tab$ + "'minPitTime:3'" 

				# Get intensity

			    select myIntensity
				meanIntensity = Get mean... 'ioiOnset' 'ioiOffset'
				maxIntensity = Get maximum... 'ioiOnset' 'ioiOffset' Parabolic
				maxIntTime = Get time of maximum... 'ioiOnset' 'ioiOffset' Parabolic
				maxIntTime = maxIntTime - ioiOnset

				# Add intensity measures to output
				output$ = output$ + tab$ +  "'meanIntensity:3'" + tab$  + "'maxIntensity:3'" + tab$ + "'maxIntTime:3'" 


				# Get multiple measures if requested

				if multiple

					# size of individual quantiles of ioi
					distance=ioiDuration/number_of_Measure_Points
					multipleMeasures$ = ""


					for j to number_of_Measure_Points

						slicetime=ioiOnset+j*distance
						slice'j'_time = slicetime
						multipleMeasures$ = multipleMeasures$ + tab$ + fixed$(slice'j'_time,3)

						select myPitch
						pitch'j'=do ("Get value at time...", slicetime,"Hertz", "Linear")
						multipleMeasures$ = multipleMeasures$ + tab$ + fixed$(pitch'j',3) 

						select myIntensity
						intensity'j'=do ("Get value at time...", slicetime, "Linear")
						multipleMeasures$ = multipleMeasures$ + tab$ + fixed$(intensity'j',3)

						if formants

							select myFemaleFormants
							f1_'j'= Get value at time... 1 slicetime Hertz Linear
							f2_'j'= Get value at time... 2 slicetime Hertz Linear
							multipleMeasures$  = multipleMeasures$ + tab$ + fixed$(f1_'j',3) + tab$ + fixed$(f2_'j',3)

							select myMaleFormants
							f1_'j'= Get value at time... 1 slicetime Hertz Linear
							f2_'j'= Get value at time... 2 slicetime Hertz Linear
							multipleMeasures$  = multipleMeasures$ + tab$ + fixed$(f1_'j',3) + tab$ + fixed$(f2_'j',3)

						endif

					endfor

				    # add multiple measures to output
					output$ = output$ + multipleMeasures$

				endif

				if zones

 				  # end of zone reached? if so, get zone measures

    			  if ioiLabel$ <> ""

					select myGrid

					# calculate zone measures
					zend = ioiOffset

					# if first zone, determine beginning of utterance
					# beginning of first labeled word is taken to be beginning of utterance
                   transc = 0
					while zstart = 0 and transc <= numberWords
						transc += 1
						labelWord$ = Get label of interval... wordTier transc
						if labelWord$ <> ""
							zstart = Get start time of interval... wordTier transc
						endif
					endwhile

					zduration =  zend - zstart

					# Get all words in zone
					wordFirst = Get interval at time... wordTier zstart
				    wordLast = Get interval at time... wordTier zend
					zNumberWords = wordLast - wordFirst

					zoneWords$ = ""
				    for transc from 1 to zNumberWords
						thisWordLabel$ = Get label of interval... wordTier wordFirst+transc-1
						zoneWords$ = zoneWords$ + "'thisWordLabel$'"
						if transc <> zNumberWords
							zoneWords$ = zoneWords$ + " "
						endif
					endfor
										
					# get phoneLength and transcription of zone
					phoneFirst = Get interval at time... phonTier zstart
				    phoneLast = Get interval at time... phonTier zend
					zonePhoneLength= phoneLast - phoneFirst
				
					zoneTranscription$ = ""
				    for transc from 1 to zonePhoneLength
						phoneLabel$ = Get label of interval... phonTier phoneFirst+transc-1
						zoneTranscription$ = zoneTranscription$ + " " + phoneLabel$
					endfor

					# add measures to output
					output$ = output$ + tab$ + "'zoneWords$'" + tab$ + "'zNumberWords'" + tab$ + "'zoneTranscription$'" + tab$ + "'zonePhoneLength'" + tab$ + "'zstart:3'" + tab$ + "'zend:3'"  + tab$ + "'zduration:3'" 

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
					zmaxIntTime = zmaxIntTime - zstart
					#
					output$ = output$ + tab$ + "'zmeanIntensity:3'" + tab$ + "'zmeanIntensity:3'" + tab$ + "'zmaxIntTime:3'"

					# reset zone variables
					zstart = zend
					zend = 0
              	
				  else
					# set empty cells for zone measures if zone doesn't end here
					for j to 16
						output$ = output$ + tab$ + "" 
					endfor
				  endif 
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

	  if formants
	  	select myMaleFormants
	  	plus myFemaleFormants
	  	Remove
	  endif

	  if ioiLabel$ == "1"
		printline ioi 'ioiLabel$': 'fileName$'
	  endif

  endif 
 
  select myGrid
  plus mySound
  Remove
  endif

  
  if i=25*round((i/25))	
 	appendInfoLine ("Processed sound 'i' of 'n'. So far, 'filesconsidered' files had measures extracted.")
  endif

endfor  
 
printline
printline
appendInfo("Done!")
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

