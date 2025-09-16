------------ Local functions

-- Read the next byte of a file, as a byte and not a string
-- Really just wrote this to make typing like 2 seconds faster
local function readByte(file)
    return string.byte(file.read(1))
end

-- Read 16-bit short
local function readShort(file)
    return readByte(file) + readByte(file)*16^2
end

-- Read 32-bit int
local function readInt(file)
    return readByte(file) + readByte(file)*16^2 + readByte(file)*16^4 + readByte(file)*16^6
end

-- Reads the upcoming string from a given nbs file
-- Requires: file is a valid open file
-- Requires: the next sequence of bytes is a string
local function readString(file)
    
    -- Reads string length, which is a 32-bit int
    strLen = readInt(file)
    if strLen > 0 then
        return file.read(strLen)
    else
        -- Wasn't sure what to return if string length is zero, so empty string I guess
        return ""
    end
end



---------- Public functions

-- Loads an NBT file and returns a custom object
-- Requires: filePath to lead to a valid file
-- Returns: NBT Object, or NIL if invalid path
function loadNBS(filePath)

    if not fs.exists(filePath) then
        return nil
    end

    obj = {}
    obj.info = getNBSInfo(filePath)
    -- Copy file to a cached directory, so we don't have to store the whole file in memory,
    --  but can ensure it won't be removed (ex. removing floppy disk)
    fs.copy(filePath, "/NBS_cache/"..fs.getName(filePath))
    obj.file = fs.open("/NBS_cache/"..fs.getName(filePath),"rb")
    obj.filePath = "/NBS_cache/"..fs.getName(filePath)

    -- Keep track of where in the file we should read notes from
    -- just in case someone decides to access the file object improperly
    obj.currentNotePos = obj.info.songStartByte

    obj.nextTick = -1

    obj.nextNotes = {}

    -- Create instance function that will load the next tick of notes for the song

    function obj:loadNextNotes()
        
        -- Ensure we're reading the file at the start of the next note
        self.file.seek("set",self.currentNotePos)
        -- Read note block header info
        self.nextTick = self.nextTick + readShort(self.file)
        -- Read note blocks by layer
        -- Note, NBS documentation shows start at -1 with first index at 0, 
        --  but lua indexing starts at 1 so starting at 0 instead
        layer = 0
        notes = {}

        for i = 1, self.info.layerCount do
            notes[i] = nil
        end
        -- Figure out which layer to start at
        layerJump = readShort(self.file)
        while layerJump ~= 0 and layer < self.info.layerCount do
            layer = layer + layerJump
            notes[layer] = {
                instrument=readByte(self.file),
                key=readByte(self.file),
                velocity=readByte(self.file),
                panning=readByte(self.file),
                pitch=readShort(self.file)
            }
            layerJump = readShort(self.file)
        end

        self.nextNotes = notes
        self.currentNotePos = self.file.seek()
    
    end

    
    function obj:unloadNBT()
        
        self.file.close()
        fs.delete(self.filePath)

    end

    return obj

end


-- Returns a list of all NBS files found on the system
function listNBSFiles()
    -- Get list of .nbs files
    return fs.find("/*/*.nbs")
end

-- Returns a table with NBS info about the file
-- Returns nil if invalid file
function getNBSInfo(filePath)

    -- Escape if file path is invalid
    if not fs.exists(filePath) then
        return nil
    end

    -- Open file in binary read mode
    file = fs.open(filePath,"rb")
    -- Ensure first two bytes are zero. After this, it is assumed the file is valid
    if readByte(file) ~= 0 or readByte(file) ~= 0 then
        return nil
    end

    -- Throw away NBS version, I just assume latest
    -- Yes this is probably bad, might fix later. this is for fun anyways
    readByte(file)

    -- Go through the header info and save it to table
    info = {}
    info["instrumentCount"] = readByte(file)
    -- song length, in ticks
    info["songLength"] = readShort(file)
    info["layerCount"] = readShort(file)
    info["songName"] = readString(file)
    info["songAuthor"] = readString(file)
    info["songOGAuthor"] = readString(file)
    info["songDesc"] = readString(file)
    info["songTempo"] = readShort(file)
    -- Some stats and info that's really only about the NBS program itself
    info["programAutosave"] = readByte(file)
    info["programAutosaveDuration"] = readByte(file)
    info["songTimeSignature"] = readByte(file)      -- Why is this in the middle of program info
    info["programMinutesSpent"] = readInt(file)
    info["programLeftClicks"] = readInt(file)
    info["programRightClicks"] = readInt(file)
    info["programBlocksAdded"] = readInt(file)
    info["programBlocksRemoved"] = readInt(file)
    -- Original name of midi or schematic file
    info["songOriginFile"] = readString(file)

    info["songLoop"] = readByte(file)
    info["songLoopTimes"] = readByte(file)
    info["songLoopStart"] = readShort(file)
    -- Save start of song location
    info["songStartByte"] = file.seek()

    -- Release file
    file.close()

    return info

end

-- Editor's note: 0 is A0, C3 = 27 = lowest pipe organ note
