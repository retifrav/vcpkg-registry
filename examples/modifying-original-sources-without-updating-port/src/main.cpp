#include <iostream>

#include <some/some.h>

int main(int argc, char *argv[])
{
    std::cout << "Base program message" << std::endl;

    std::cout << std::endl << "Message from a dependency:" << std::endl;
    sm::lbr::printSomething();
}
