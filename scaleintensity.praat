
#  chael@mcgill.ca


form Scale intensity
  boolean Soundfile_in_same_directory_as_script yes
  sentence soundDirectory
  sentence Extension .wav
  boolean TextGrid_in_same_directory_as_sound yes
  sentence textGridDirectory 
  choice scalingMethod: 1
    button scale peak
    button scale mean
  comment Default is 0.9 for scale peak and .7 for scale mean
  real scaleToValue 0
  comment Set to overwrite orginal files, or else specify target directory
  comment target directory will be created inside sounddirectory if it doesn't already exist
  boolean overwrite 0
  sentence targetDirectory 0_original
endform

# set directories with forward slash (for linux and mac)

if soundfile_in_same_directory_as_script
    soundDirectory$ = ""
else
    soundDirectory$ = "'soundDirectory$'/"
endif   

if textGrid_in_same_directory_as_sound
     textGridDirectory$ = soundDirectory$
else
    textGridDirectory$ = "'textGridDirectory$'/"
endif


# create target directory, if it doesn't already exist

targetDirectory$ = "'soundDirectory$''targetDirectory$'"

if overwrite = 0
   createDirectory: targetDirectory$
   targetDirectory$ = "'targetDirectory$'/"
else
  targetDirectory$ = soundDirectory$
endif



# set default values
if scaleToValue = 0
  if scalingMethod$ = "scale peak"
    scaleToValue = 0.9
  else
    scaleToValue = 70.0
endif

echo 'scalingMethod$' to 'scaleToValue'
printline targetDirectory: 'targetDirectory$'
printline

Create Strings as file list... list 'soundDirectory$'*'extension$'
numberFiles = Get number of strings

numberFilesScaled = 0

for ifile to numberFiles
   select Strings list
   filename$ = Get string... ifile

   Read from file... 'soundDirectory$''filename$'
   name$ = selected$("Sound")

   if scalingMethod$ = "scale peak"
    	Scale peak... scaleToValue
   else
        Scale peak... 0.7
        Scale intensity... scaleToValue
   endif

   Write to WAV file... 'targetDirectory$''name$'.wav
   Remove
   numberFilesScaled = numberFilesScaled + 1
 

   if overwrite = 0
     grid$ = replace$(filename$,extension$,".TextGrid",0)
     
     if fileReadable (grid$)
          Read from file... 'textGridDirectory$''grid$'
          Write to text file... 'targetDirectory$''grid$'
          Remove
     else
           printline 'filename$': No Textgrid file
     endif

   endif

endfor

select Strings list
#Remove

printline
printline Files scaled: 'numberFilesScaled'

