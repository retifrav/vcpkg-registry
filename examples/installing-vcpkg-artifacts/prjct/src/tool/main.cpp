#include <iostream>

#include <SomeLibrary/some.h>
#include <nlohmann/json.hpp>

int main(int argc, char *argv[])
{
    std::cout << "Base application message" << std::endl;
    std::cout << std::endl;

    std::cout << "Messages from the project library:" << std::endl;
    lbrSome::doSome();
    lbrSome::doTheThing();
    std::cout << std::endl;

    std::cout << "Parsing a string with json-nlohmann:" << std::endl;
    auto j = nlohmann::json::parse(R"({"age": 48, "name": "Christina"})");
    std::cout << j["name"].get<std::string>() << " is "
              << j["age"] << " years old" << std::endl;
}
