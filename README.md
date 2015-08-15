# sac
matlab sac get routine

this package contains the class "filesac"
to read a sacfile

`s = sac.sacfile(filename)`

s now contains the header and data structures, along with some basic file information.
s.header -> a structure containing one field for every sac field, with data parsed out.
s.data -> a structure containing `independent` and `dependent` data.  Generally, only 
`dependent` is used.

### future
I could create a way to peek into the datafile without having to load it all up. This could be useful
when other programs would like to find out something about the data before comitting to grabbing it.

Not sure what else could be needed.


Created by Celso Reyes

_This is independent of the waveform suite, which will have it's own conversion function._
