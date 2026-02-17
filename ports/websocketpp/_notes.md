# Maintainer notes

## Vendored dependencies

The library maintainer(s) decided to vendor 3rd-party dependencies, and to make it worse, they have also modified their original sources, so bringing this all to order will require some effort. For now let's try to go the way it is.

So far the following 3rd-party dependencies have been spotted:

- [Base64](https://renenyffenegger.ch/notes/development/Base64/Encoding-and-decoding-base-64-with-cpp/)
- [MD5](https://github.com/apple/cups/blob/master/cups/md5.c)
- [SHA-1](https://code.google.com/archive/p/smallsha1/)
- [UTF8 validator](https://bjoern.hoehrmann.de/utf-8/decoder/dfa/)
