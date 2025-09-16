# An unofficial NoteBlock Studio player
[![Noteblock Studio version 3.11](https://img.shields.io/badge/NoteBlock%20Studio%20-%203.11%20-%20blue?style=plastic)](https://github.com/OpenNBS/NoteBlockStudio)

The goal for this project was to create a music player that can play on a variety of instruments. I felt like using the ComputerCraft speakers wasn't quite interesting enough, so I wanted to find a way to incorporate other music making devices - such as the pipe organs from the Create mod - into my music player.

## [The NBS Wrapper](NBSWrapper.lua)
The NBS Wrapper is developed to create an interface between NBS files. It is able to list all `.nbs` files on the system, read track information off a given file, load a file (saving it to a cached folder to ensure that it maintains access even if the file is removed), and read the file note by note.

The NBS Wrapper creates a NBS object with the following format:
```lua
{
  objects:
  info = {}        table containing all the file's header info
  file =           the lua file object of the cached .nbs file
  filePath =       the path to the open cached .nbs file
  currentNotePos = the offset of the file to the start of the next note
  nextTick =       how many ticks until the next note (the currently loaded note) should be played
  nextNotes = {}   table containing all layers in the song, and the note that is to be played next

  functions:
  :loadNextNotes()  loads the next set of notes for the song, and any other information about them
  :unloadNBT()      unloads the song and removes it from cache. This object should then be set to nil after running, as it is a dead object.
}
```
