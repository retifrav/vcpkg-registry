#include <iostream>

#include <SomeLibrary/some.h>

int main(int argc, char *argv[])
{
    std::cout << "Base application message" << std::endl;
    std::cout << std::endl;

    std::cout << "From dependency:" << std::endl;
    lbrSome::doSome();
    lbrSome::doTheThing();
}
