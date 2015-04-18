# TheKnownUnknowns
A CLI tool for semi-interactively normalizing text corpora in preparation for speech tasks like long alignment.

Usage: 

/SomeFilePath/TheKnownUnknowns ~/SomeFilePath/MyTextFile.txt

After loading your text it will ask you how you want to replace numbers and symbols which may be spoken in different ways, 
automatically remove or replace symbols where it knows how to, and mark any remaining unknown symbols inside of square brackets 
like so: [[[]]] so that you can easily check them in your final text output.
