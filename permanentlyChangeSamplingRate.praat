# Openfiles 
# michael. chael@mcgill.ca

# this script scales and resamples all soundfiles in a directory

form Open all files in a directory
  sentence Extension .wav
  natural samplingRate 22050
endform

Create Strings as file list... list  *'extension$'
numberFiles = Get number of strings

for ifile to numberFiles
   select Strings list
   filename$ = Get string... ifile
   Read from file... 'filename$'
   sound=selected("Sound")
 
    printline 'ifile'/'numberFiles'
    Scale peak... 0.70
  
    sfreq=Get sampling frequency
    if sfreq <> 'samplingRate'
 
        Resample... 'samplingRate' 50
    else
	Copy...
    endif

   Write to WAV file... 'filename$'
   Remove
   select sound
   Remove
endfor

select Strings list
Remove

