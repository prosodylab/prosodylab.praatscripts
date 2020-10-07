
# chop up long sound file based on annotation
# September 2011. chael@mcgill.ca

### What this script does:
# This file extracts and saves all labeled intervals (sound and TextGrid) from a soundfile.
# Just select the soundfile and the textgrid and then the individual sound files will be saved.

### Target Directory:
# If you don't specify a directory name, the name of the soundfile will be used.
# Unless you specify a complete path, the new directrory 
# will be the same directory as the praat script.
# If a directory of that name already exists, an error message will occur.

### File names of individual files:
# if you click 'asciiName', then file name of the soundfiles and textgrid files will be the ascii only
# (i.e., IPA symbols will be stripped from the interval label)
# If multiple files have the same transcription, numbers will be added to create a unique filename


form Chop Soundfile
	positive Annotation_tier 1
	sentence directory_name
	boolean LongSound yes
	boolean asciiName no
endform

if longSound=1
	soundtype$="LongSound"
else
	soundtype$="Sound"
endif
 
soundfile=selected("'soundtype$'")
short$=selected$("'soundtype$'")
grid=selected("TextGrid")

if directory_name$=""
	directory_name$=short$
endif

system mkdir 'directory_name$'

select grid
nInterval=Get number of intervals... 'annotation_tier' 

for i to nInterval

	select grid

	# the labe of the interval will be used as the file name of the extracted Sound and TextGrid
	label$= Get label of interval... 'annotation_tier' 'i'

	if label$<>""
		# strip non-ascii characters to assure a file in ascii-only
		if asciiName=1
			name$=replace_regex$(label$,"[^(\x20-\x7F)]","",0)
		else
			name$=label$
		endif

		printline 'label$' > 'name$'

		# Check whether soundfile with same name exists, 
		# and if so, determine number that will make a unique soundfile

		unique=0
		counter=0
		repeat
			# prevent empty file name
			if name$=""
				counter=1
			endif

			if counter=0
				uniquifier$=""
			else 
				uniquifier$=fixed$(counter,0)
			endif
			if fileReadable("'directory_name$'/'name$''uniquifier$'.wav")=0
				unique=1
			endif
			counter=counter+1
        
		until unique=1

		## Extract and Save Soundfile and TextGrid

		begin=Get start point... 'annotation_tier' 'i'
		end=Get end point... 'annotation_tier' 'i'

		Extract part... begin end 0
		Write to text file... 'directory_name$'/'name$''uniquifier$'.TextGrid		
		Remove

		select soundfile
		Extract part... begin end rectangular 1.0 0
		Write to WAV file... 'directory_name$'/'name$''uniquifier$'.wav
		Remove

	endif

endfor