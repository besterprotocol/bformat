bformat
=======

[![D](https://github.com/besterprotocol/bformat/actions/workflows/d.yml/badge.svg)](https://github.com/besterprotocol/bformat/actions/workflows/d.yml)

A simple message format for automatically length-prefixing messages over any [`Socket`](https://dlang.org/phobos/std_socket.html#.Socket) or [River-based](https://github.com/deavmi/river) [`Stream`](https://river.dpldocs.info/river.core.stream.Stream.html).

## What is bformat?

bformat is simply a format and a library that allows one to prefix their messages with a length field such that it can be retrieved on the other side over a socket that is opened in a STREAM mode. It simply manages a socket's I/O stream such that the first 4 bytes are read as the length and then the preceding bytes are read accordingly. Rather than duplicate this sort of logic in all the code I wrote ever for my networking projects, I decided to make it a library as it would reduce the amount of duplicate code and also allow code re-use of something I could change or optimize later.

It's also cross-platform and does all the byte-swapping endianess goodness you'd need - so you need not worry about that.


## Want to use it in your project?

It's rather easy to add it to your D project (so far I have only implemented this in DLang as that is where I need it). 

Just run the command `dub add bformat`.

When using the library you will want to use the two functions provided `sendMessage(Socket, byte[])` and `receiveMessage(Socket, ref byte[])`. These two functions allow you to send data and have it encoded into the bformat format and receive data and interpret the received bformat format such that the correct length of data can read.

And then you can take a look at the [source code documentation](https://bformat.dpldocs.info/v3.1.18/) here on the functions the library provides and how to use them.
