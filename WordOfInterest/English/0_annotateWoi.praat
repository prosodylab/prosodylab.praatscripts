# Annotate words of interest
# prosodylab, Michael Wagner, updated 2022

echo Annotate words of interest

# for each woi, syllables can be added
# or vowels (use zone of interest measures for intervals)
# or stressed vowels (use zone of interest measures for abercrombian foot (sort of) 

form Annotate Words of Interest	
	sentence Woi_file ../../phocusW.txt
	sentence Id_columns experiment_item_condition
	sentence Filename_format experiment_participant_item_condition
	natural wordTierNumber 1
    natural segmentTier 2
	boolean Dry_run 1
	boolean restore_old_before 0
	boolean mkDir 0
    boolean verbose 0
    boolean addSyllables 1
    boolean addVowels 0
    boolean addStressedVowels 0
endform



##### Prep for syllable annotation
#
# vowels and onsets in language:
#
vowels$ = "-AA-AE-AH-AO-AW-AY-EH-ER-EY-IH-IY-OW-OY-UH-UW-"
onsets$ = "- P - T - K - B - D - G - F - V - TH - DH - S - Z - SH - CH - JH - M - N - R - L - HH - W - Y - P R - T R - K R - B R - D R - G R - F R - TH R - SH R - P L - K L - B L - G L - F L - S L - T W - K W - D W - S W - S P - S T - S K - S F - S M - S N - G W - SH W - S P R - S P L - S T R - S K R - S K W - S K L - TH W - ZH - P Y - K Y - B Y - F Y - HH Y - V Y - TH Y - M Y - S P Y - S K Y - G Y - HH W -"

#### Procedure check whether segment is a vowel
#
#
procedure checkIsVowel segmentLabel$
	#
	# remove stress level
	segmentLabel$ = replace$(segmentLabel$,"0","",0)
	segmentLabel$ = replace$(segmentLabel$,"1","",0)
	segmentLabel$ = replace$(segmentLabel$,"2","",0)
	#
	segmentLabel$ = "-"+segmentLabel$+"-"
	isVowel = index(vowels$,segmentLabel$)
	#
endproc


#### check whether onset is viable onset
#
#
procedure checkIsOnset segmentLabel$
	#
	segmentLabel$ = "- "+segmentLabel$+"-"
	isOnset = index(onsets$,segmentLabel$)
	#
endproc

#### shorten transcription by one segment
procedure shorten toBeShortened$
    #
    repeat
      lastCharacter$ = right$(toBeShortened$,1) 
      toBeShortened$ = left$(toBeShortened$,length(toBeShortened$)-1)
    until lastCharacter$ = " " or toBeShortened$ = ""
    shorter$ = toBeShortened$
endproc




######
#
# This procedure saves the id-column-names in an array (column_name'number'))
# and identifies how many identifying columns there are (numberColumns)
#
procedure idColumns columns$
#
if dry_run
   verbose = 1
endif
#
numberColumns = 0
#
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
#
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
		#woiline$ = replace$ (woiline$, "it's", "it s", 0)
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

############
##
## prepping

storeold$="0_oldTextGrids"

if restore_old_before = 1
     system mv 'storeold$'/*.TextGrid .
     system rmdir 'storeold$'
	 mkDir = 1
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

echo Number of files to label: 'numberOfFiles'
printline



## start main loop to look for woi
##
##
for i to numberOfLoops

    output$ = ""
    annotateError = 0

	select filenames
	filename$ = Get string... i
	
	# get correct textline$ with woi annotation
	call parsename 'filename$'
	call getWoiLine

        if woiline$<>""
		Read from file... 'filename$'
		output$ = output$ + "'i': 'filename$'" + newline$
		tgrid = selected("TextGrid")

		# save original tgrid	
		if dry_run<>1
			Write to text file... 'storeold$'/'filename$'
		endif

		output$ = output$ + "woi-annotation: 'woiline$'"

        if verbose
          printline
          printline
          print 'output$'
        endif

        gridEnd=Get end time
        
		# Add new tier to textgrid		
		select tgrid
		woiTier = Get number of tiers
		woiTier = woiTier + 1
		last_woi_interval = 0
	
		Insert interval tier... 'woiTier' woi

		# Add syllable tier if necessary
 		if addSyllables
          syllableTier  = woiTier + 1
          Insert interval tier... 'syllableTier' syllables
        endif

		# Add vowel tier if necessary
 		if addVowels
          tierNumber = Get number of tiers
          vowelTier  = tierNumber + 1
          Insert interval tier... 'vowelTier' vowels
        endif

		# Add stressed vowel tier if necessary
 		if addStressedVowels
          tierNumber = Get number of tiers
          stressTier  = tierNumber + 1
          Insert interval tier... 'stressTier' stressedVowels
        endif

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
            annotateError = 1
			printline "Unmatched word: textgrid: 'label$' woilineword: 'word$' File: 'filename$'
		elsif woiFound=1
			start = Get starting point... 'wordTierNumber' 'intCounter'
			end = Get end point... 'wordTierNumber' 'intCounter'

			endprevious=0

			if last_woi_interval <> 0
				endprevious = Get end point... 'woiTier' 'last_woi_interval'
			endif
			
			if endprevious <> start
					Insert boundary... 'woiTier' 'start'
					last_woi_interval=last_woi_interval+1
			endif
			
			last_woi_interval=last_woi_interval+1

            #make sure boundary is not at very end to avoid error
			if end = gridEnd
				end=end-0.001
			endif

			Insert boundary... 'woiTier' 'end'
			Set interval text... 'woiTier' 'last_woi_interval' 'nextLabel$'

			if verbose
              printline
              print 'nextLabel$' 'label$'
            endif

      if addSyllables

			#####
			# annotate the syllables of current word of interest on syllable tier

		    # add syllable boundary at the beginning of woi
            #Insert boundary... syllableTier start
            #currentSyllableInterval = Get interval at time... syllableTier start+0.0001

            # count segments
            startSegment = Get interval at time... segmentTier start
            endSegment = Get interval at time... segmentTier end
            numberSegments = endSegment - startSegment

			# initiate loop variables
			segmentCounter = 0
			syllable = 0
            previousSyllable$ = ""
            nextSyllable$ = ""

			# loop to syllabify woi
            repeat
	
		       labelCurrentSegment$ = Get label of interval... segmentTier startSegment+segmentCounter

               previousSyllable$ = previousSyllable$ + " " + labelCurrentSegment$
               
               call checkIsVowel 'labelCurrentSegment$'

               if isVowel

					call shorten 'previousSyllable$'
					previousSyllable$  = shorter$
					thisSyllable$ = labelCurrentSegment$

					onset$ = ""
					endSyllable = segmentCounter

                  maximizeOnset = 1
                  while maximizeOnset = 1 

                    if endSyllable = 0
                       maximizeOnset = 0
                    else
                      endSyllable = endSyllable - 1
                      labelPreviousSegment$ = Get label of interval... segmentTier startSegment+endSyllable 

                     call checkIsVowel 'labelPreviousSegment$'

                     if isVowel = 0
                        isItOnset$ = labelPreviousSegment$ + " " + onset$

                        call checkIsOnset 'isItOnset$'

                        if isOnset
                             onset$ = isItOnset$
                             endsyllable = endSyllable - 1

                  			  call shorten 'previousSyllable$'
				    	      previousSyllable$ = shorter$

                             thisSyllable$ =  labelPreviousSegment$ + " " + thisSyllable$
 						else
 						  maximizeOnset = 0
                         endSyllable = endSyllable + 1
                        endif
                      else
                         maximizeOnset = 0
						  endSyllable = endSyllable + 1
                     endif 
					endif
                   endwhile

                   # print previous syllable if there was one
					if previousSyllable$ <> "" & verbose
					    if syllable = 1
							print   Syllables:
						endif
					   print   ('previousSyllable$' )-'syllable'
                    endif

					syllable = syllable + 1

					previousSyllable$ = thisSyllable$

					# place boundary at end of previous syllable (or word beginning)
					syllableEndTime = Get start time of interval... segmentTier startSegment+endSyllable
					Insert boundary... syllableTier syllableEndTime

					# add label for current syllable
                    #
					currentSyllableInterval = Get interval at time... syllableTier syllableEndTime+0.0001
                   Set interval text... syllableTier currentSyllableInterval 'syllable'
		

               endif

               segmentCounter = segmentCounter + 1

             until segmentCounter = numberSegments

			if verbose
			  print   ( 'previousSyllable$' )-'syllable' 
           endif
                      
			  ## end syllable annotation
             Insert boundary... syllableTier end
         endif

     if addVowels

			#####
			# annotate the vowels of current word of interest on a separate tier

            # count segments
            startSegment = Get interval at time... segmentTier start
            endSegment = Get interval at time... segmentTier end
            numberSegments = endSegment - startSegment

			# initiate loop variables
			segmentCounter = 0
			vowelNumber = 1

			# loop to look for vowels
            repeat
	
		       labelCurrentSegment$ = Get label of interval... segmentTier startSegment+segmentCounter
               
               call checkIsVowel 'labelCurrentSegment$'

               if isVowel

					if verbose
	                   if vowelNumber = 1
							print   Vowels:
						endif
						print  ('labelCurrentSegment$' )-'vowelNumber'
    				endif
             
					# place boundary at beginning of vowel, unless there is one (from previous vowel)
					vowelStartTime = Get start time of interval... segmentTier startSegment+segmentCounter
					isEdge = Get interval edge from time... vowelTier vowelStartTime
					if isEdge = 0
						Insert boundary... vowelTier vowelStartTime
					endif

					# place boundary at end of vowel
					vowelEndTime = Get end time of interval... segmentTier startSegment+segmentCounter
					Insert boundary... vowelTier vowelEndTime

					# add label for current vowel
                    #
					currentVowel = Get interval at time... vowelTier vowelStartTime+0.0001
                   Set interval text... vowelTier currentVowel 'vowelNumber'
		
					vowelNumber = vowelNumber + 1

               endif

               segmentCounter = segmentCounter + 1

             until segmentCounter = numberSegments

                      
         endif


     if addStressedVowels

			#####
			# annotate the vowel with main stress for each woi and label with woi number

            # count segments
            startSegment = Get interval at time... segmentTier start
            endSegment = Get interval at time... segmentTier end
            numberSegments = endSegment - startSegment

			# initiate loop variables
			segmentCounter = 0

			# loop to look for vowels
            repeat
	
		       labelCurrentSegment$ = Get label of interval... segmentTier startSegment+segmentCounter
               
               call checkIsVowel 'labelCurrentSegment$'

               if isVowel

				 stressMainStress = index(labelCurrentSegment$,"1")

			     if stressMainStress <> 0
				
					if verbose
						print   StressedVowel: 'labelCurrentSegment$'
    				endif

					# place boundary at beginning of vowel, unless there is one (from previous vowel)
					vowelStartTime = Get start time of interval... segmentTier startSegment+segmentCounter
                   Insert boundary... stressTier vowelStartTime

					# place boundary at end of vowel
					vowelEndTime = Get end time of interval... segmentTier startSegment+segmentCounter
					Insert boundary... stressTier vowelEndTime

					# add label for current vowel
                    #
					currentVowel = Get interval at time... stressTier vowelStartTime+0.0001
                   Set interval text... stressTier currentVowel 'nextLabel$'
		          endif
               endif

               segmentCounter = segmentCounter + 1

             until segmentCounter = numberSegments

                      
         endif


	   	endif

	 	until woiline$=""		

		select tgrid
		if dry_run<>1
			Write to text file... 'filename$'
		endif

        if annotateError <> 1
		   select tgrid
		   #Remove
        endif

	endif

   if i/50 = round(i/50)
      printline
      printline Labeled 'i'/'numberOfLoops'
      printline 
   endif

endfor


select woi_file
Remove

select filenames
Remove

printline
printline