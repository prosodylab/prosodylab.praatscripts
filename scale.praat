
#  chael@mcgill.ca


form Scale peak  of all files in a directory
  sentence Extension .wav
  boolean Soundfile_in_same_directory_as_script yes
  sentence Directory_sound /Users/chael/work_static/intonly/data/subjfil_pc/Results/11
  boolean TextGrid_in_same_directory_as_sound yes
  sentence Directory_grid 
endform

if soundfile_in_same_directory_as_script
    directory_sound$ = ""
else
     directory_sound$ = "'directory_sound$'/"
endif   

if textGrid_in_same_directory_as_sound
     directory_grid$ = directory_sound$
endif


Create Strings as file list... list 'directory_sound$'*'extension$'
numberFiles = Get number of strings

for ifile to numberFiles
   select Strings list
   filename$ = Get string... ifile
   
 printline 'filename$'

  if filename$ <> "openfiles.praat"
  	Read from file... 'directory_sound$''filename$'
    name$ = selected$("Sound")
	Scale peak... 0.99
	Write to WAV file... 'directory_sound$''name$'.wav
	Remove
   endif

   length = length(filename$)
   length2 = length(extension$)
   length = length - length2
   short$ = left$(filename$, length)

   grid$ = directory_grid$+short$+".TextGrid"
    
     if fileReadable (grid$)
          Read from file... 'grid$'
     else
           printline 'short$': No Textgrid file
     endif

endfor

select Strings list
Remove

