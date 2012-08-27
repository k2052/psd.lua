> go over structure from start and cleanup line by line
> replace constructor with new
> change tell to seek
> change seek to skip

> check layermask_info filler/struct

> make arrays into tables

> logging class
	> when high error thro to handler
		> note: on higher level plan to have handler be QT dialog.

> file 
	> real lua style file handling
	> hook up methods to use lua equivalents

> layers
	> finish parser loops
	> finish parsers

> Layer Style Parsers
	> get loops setup
	> add assertions where needed
	> get nils/skips
	> go over add missing reads/gets
	> go over add missing switches

- css abstraction 
	- gradients to one layer of stops. i.e merge
	- toCSS on gradient overlay
	- toCSS on stroke.
  - need to somehow abstract icons/groups/button types etc. each one has class etc.

> psdfile
  > readers
    > readInt
    > readBoolean
    > readDouble
    > readBlendMode()
    > readRgbColorSpace
    > readObjectPoint
    > readS with count
    > read 

  > skipObject

> checks
  > uint4 does it exist? should be uint8. correct. Was I high when I wrote uint4? haha

> add setGradient stuff to styles/stroke
> PSDChannelImage
  > decodeRLEChannel
> translate all the bitwise operations
> add all the Log calls
> check for loops that take the form for i = 0,items should it be for i = 1,items?  answer == yes
> check stirng diference between double and signel quotes in lua
> check getTechnique
> skipObject should be passed ostype
> all the reads for struct types
> Uint32 to UInt32
> push to table.insert
> fix up Log.debug to take table for dumping
> implement correct skip relative and set
> throws from psd.js to asserts
> repalce usages of type with ostype or kind
> all asserts from psd.js
> check for stray assert.equal
> check case of read methods
> organize files
> go over again
> look into ^ bitwise operator
instance methods should use \ instead of dot. oh shit that is a lot of recoding