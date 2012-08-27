layer style strucutre should get parsed to  laua able version of css.

that way to get we just accept dag & drop and detemrine files contents create reveleant class & parse. then toCSS should return css as a table. should be classes to then caress "lua css" to sass, compass etc.

css = {
	color: "green",
	gradient: "",
	text-decoration: "none"
}

readShortInt = readUInt16


Remeber we only have to sources of info.

1. Layer name
2. Nesting.

And potentially meta data in the app in the future.

What might a PSD look like?

If we want to export a file add an extension
e.g Icon.png both on groups or layers. Calling toPNG on an Icon gives a png.
Photoshop doesn't disinct between group and layers so this works fine.

What if we want to turn a layer both into css and into an icon? Create objects for both. Then just hit them each.

Sytax though. how would that look? .icon Icon.png ? To avoid it getting complicated souh be a sprite tag. We will use '@' for tags.

So think about the following
 
 (class name becomes image name)
.icon .png @sprite bob/

:hover
:active
:focus

so we get. 

.icon:hover { styles }
.icon:active { styles }
.icon:focus { styles }

and the images are;

bob/
  icon_hover.png
  icon_active.png
  icon_focus.png

Simply adding a class is enough to get something outputted as css.

How would we handle a non nested icon hover class?
.icon:hover. Just becomes the css?

I think this can get way to complicated to conceptualize every use case. Lets start with two. .format for images and .className to generate css.
The abstraction of object types is all thats necessary to grow later. Because all it becomes is toCSS. What if object has no css? Probably should abstract everything into a different method name. no we just check for css type/outputimage type and then add to css if it is or output image. 