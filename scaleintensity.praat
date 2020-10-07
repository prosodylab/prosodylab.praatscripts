

strings = Create Strings as file list: "Filelist", "*.wav"
numberOfFiles = Get number of strings


# system mkdir scaled

for ifile to numberOfFiles
  selectObject: strings
  fileName$ = Get string: ifile
  soundFile = Read from file: fileName$
  Scale intensity... 75.0
  Write to WAV file... scaled/'fileName$'
  Remove
endfor
