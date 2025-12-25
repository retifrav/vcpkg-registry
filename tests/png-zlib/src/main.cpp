#include <iostream>
#include <fstream>
#include <cassert>
#include <vector>

#include <zlib/zlib.h>
#include <png/png.h>

// original sources: https://cyberforum.ru/cpp-cross-platform/thread3213759.html#post17643586

void userReadData(png_structp pngPtr, png_bytep data, png_size_t length)
{
    std::istream *s { reinterpret_cast<std::istream*>(png_get_io_ptr(pngPtr)) };
    s->read(reinterpret_cast<char*>(data), static_cast<int>(length));
}

int main(int argc, char *argv[])
{
    // the PNG file is expected to be alongside the executable (and working folder should be set to that one too)
    std::ifstream file { "./some.png", std::ios::binary };
    png_byte header[8];

    int res;
    file.read(reinterpret_cast<char*>(header), sizeof(header));
    res = png_sig_cmp(header, 0, 8);
    assert(!res && "invalid file");

    png_structp pngPtr { png_create_read_struct(PNG_LIBPNG_VER_STRING, nullptr,nullptr, nullptr) };
    assert(pngPtr);

    png_infop infoPtr { png_create_info_struct(pngPtr) };
    if (!infoPtr)
    {
        png_destroy_read_struct(&pngPtr, nullptr, nullptr);
        return 1;
    }

    png_infop endInfo { png_create_info_struct(pngPtr) };
    if (!endInfo)
    {
        png_destroy_read_struct(&pngPtr, &infoPtr, nullptr);
        return 2;
    }

    if (setjmp(png_jmpbuf(pngPtr)))
    {
        png_destroy_read_struct(&pngPtr, &infoPtr, &endInfo);
        return 3;
    }

    png_set_sig_bytes(pngPtr, 8);
    png_set_read_fn(pngPtr,reinterpret_cast<png_voidp>(&file), userReadData);
    png_read_info(pngPtr, infoPtr);

    int w { static_cast<int>(png_get_image_width(pngPtr, infoPtr)) };
    int h { static_cast<int>(png_get_image_height(pngPtr, infoPtr)) };

    int depth { png_get_bit_depth(pngPtr, infoPtr) };
    assert(depth == 8 && "invalid depth");

    int channels { png_get_channels(pngPtr, infoPtr) };
    assert(channels == 4 && "invalid number of channels");

    int rowbytes { static_cast<int>(png_get_rowbytes(pngPtr, infoPtr)) };
    png_read_update_info(pngPtr, infoPtr);

    std::vector<png_bytep> rowPtrs(h);
    std::vector<unsigned char> data(h * rowbytes);
    for (int i = 0; i < h; i++) {
        rowPtrs[i] = data.data() + i * rowbytes;
    }
    png_read_image(pngPtr, rowPtrs.data());

    png_destroy_read_struct(&pngPtr, &infoPtr, &endInfo);

    file.close();

    std::cout << w << "x" << h << std::endl;

    int s { static_cast<int>(data.size()) };
    uLongf size { compressBound(s) };

    std::vector<Bytef> zip(size);
    int r { compress2(zip.data(), &size, reinterpret_cast<Byte*>(data.data()), s, Z_BEST_COMPRESSION) };
    assert(r == Z_OK && "compression error");

    std::ofstream out { "./im.bin", std::ios::binary };
    out.write(reinterpret_cast<char*>(&w), sizeof(w));
    out.write(reinterpret_cast<char*>(&h), sizeof(h));
    out.write(reinterpret_cast<char*>(zip.data()), size);
    out.close();

    return 0;
}
