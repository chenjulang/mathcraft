import «Mathcraft».model.Block
import «Mathcraft».model.Chunk

namespace Mathcraft

structure World where
  -- A world is just a directory where the chunks are stored as json files
  directory : System.FilePath
  deriving Inhabited, Repr

def World.chunkExists (x y : Chunk.AxisLocation) (w : World) : IO Bool := do
  -- check if the file `{directory}/chunk_{x}_{y}.bin` exists
  let filename : String := Chunk.filename x y
  let filepath : System.FilePath := System.FilePath.withFileName (directory w) filename
  System.FilePath.pathExists filepath

def World.getChunk (x y : Chunk.AxisLocation) (w : World) : IO (Option Chunk) := do
  -- read in the file `{directory}/chunk_{x}_{y}.bin`
  let fileName : String := Chunk.filename x y
  let filePath : System.FilePath := System.FilePath.withFileName (directory w) fileName
  let fileExists : Bool ← System.FilePath.pathExists filePath
  if !fileExists then
    return none
  else do
    let bytes : ByteArray ← IO.FS.readBinFile filePath
    let chunk : Chunk := Chunk.read x y bytes
    return some chunk

def World.saveChunk (c : Chunk) (w : World) : IO Unit := do
  -- write the chunk to the file `{directory}/chunk_{c.x}_{c.y}.bin`
  let fileName : String := s!"chunk_{c.x}_{c.y}.bin"
  let filePath : System.FilePath := System.FilePath.withFileName (directory w) fileName
  let bytes : ByteArray := Chunk.write c
  IO.FS.writeBinFile filePath bytes

def World.createChunk (x y : Chunk.AxisLocation) (w : World) : IO Chunk := do
  -- create a new chunk with the given x and y coordinates
  let c : Chunk := Chunk.empty x y
  World.saveChunk c w
  return c

def World.getOrCreateChunk (x y : Chunk.AxisLocation) (w : World) : IO Chunk := do
  -- check if the chunk exists
  let c : Option Chunk ← World.getChunk x y w
    match c with
    | some c => return c
    | none => return (← World.createChunk x y w)

def World.listChunks (w : World) : IO (List Chunk) := do
  -- list all the files in the directory and read in the chunks
  let files : List System.FilePath := ( ← System.FilePath.walkDir (directory w) (λ _ ↦ return true) ).data
  let chunks : List Chunk ← files.filterMapM fun file => do
    let bytes : ByteArray ← IO.FS.readBinFile file
    let chunk' ← Chunk.readFromFile file
    if let some chunk := chunk' then
      return some chunk
    else
      return none
  return chunks

end Mathcraft
