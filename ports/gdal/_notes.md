# Maintainer notes

## Vendored dependencies

The way they resolve dependencies is absolutely horrible: fucking self-made functions (*several variants of those*) for finding packages, separation into internal/external discovery (*which does not seem to respect what you tell it to use*), appending `find_dependency()` calls to a bitch-ass long string... Shortly saying, a god-awful abomination.

No one has time to get through all this wretched convolution of not-invented-here crutches in one go, so patching the original CMake project will be progressing gradually.
