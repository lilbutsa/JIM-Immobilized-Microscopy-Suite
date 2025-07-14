#ifndef BLFLAGPARSER_HPP
#define BLFLAGPARSER_HPP


/**
 * @file    BLFlagParser.hpp
 * @brief   Lightweight command-line flag parser supporting scalar and vector arguments.
 *
 * This header defines a templated utility for parsing command-line flags into variables
 * or vectors using a list of flag-to-variable mappings. It supports:
 *   - Typed scalar flags (int, float, double, string, bool)
 *   - Multiple-value flags via `std::vector<T>`
 *   - Automatic type conversion with error handling
 *   - Optional flags (bool switches with no value required)
 *
 * Example usage:
 *     bool verbose = false;
 *     int threads = 4;
 *     std::string filename;
 *     std::vector<float> thresholds;
 *     std::vector<std::pair<std::string, bool*>> scalarParams = {{"verbose", &verbose}};
 *     std::vector<std::pair<std::string, int*>> scalarParams = {{"threads", &threads}};
 *     std::vector<std::pair<std::string, std::string*>> stringParams = {{"file", &filename}};
 *     std::vector<std::pair<std::string, std::vector<float>*>> vectorParams = {{"thresh", &thresholds}};
 *     BLFlagParser::parseValues(scalarParams, argc, argv);
 *     BLFlagParser::parseValues(stringParams, argc, argv);
 *     BLFlagParser::parseValues(vectorParams, argc, argv);
 *
 * @note This library avoids external dependencies for lightweight usage. 
 * @author James Walsh james.walsh@phys.unsw.edu.au
 * @date 2025-07-14
 */



#include <unordered_map>
#include <string>
#include <vector>
#include <iostream>
#include <type_traits>
#include <regex>

namespace BLFlagParser {

    // Helper to convert string to T
    template<typename T>
    T convertFromString(const std::string& s);

    template<>
    inline int convertFromString<int>(const std::string& s) {
        return std::stoi(s);
    }

    template<>
    inline uint32_t convertFromString<uint32_t>(const std::string& s) {
        return std::stoi(s);
    }


    template<>
    inline float convertFromString<float>(const std::string& s) {
        return std::stof(s);
    }

    template<>
    inline double convertFromString<double>(const std::string& s) {
        return std::stod(s);
    }

    template<>
    inline std::string convertFromString<std::string>(const std::string& s) {
        return s;
    }

    // Generic parser
    template <typename T>
    inline int parseValues(std::vector<std::pair<std::string, T*>>& parameterPairs, int argc, char* argv[]) {
        std::unordered_map<std::string, T*> paramMap;
        for (const auto& p : parameterPairs) {
            paramMap["-" + p.first] = p.second;
        }

        for (int i = 1; i < argc ; ++i) {
            auto it = paramMap.find(argv[i]);
            if (it != paramMap.end()) {
                try {
                    if constexpr (std::is_same<T, bool>::value) {
                        *(it->second) = true;
                    }
                    else if (i + 1 >= argc) {
                        std::cerr << "Missing value for flag " << it->first << "\n";
                        return 1;
                    }else *(it->second) = convertFromString<T>(argv[i + 1]);
                    //std::cout << it->first.substr(1) << " set to " << *(it->second) << "\n";
                    ++i; // Skip value
                }
                catch (const std::exception& e) {
                    std::cerr << "Error parsing " << it->first << ": " << e.what() << "\n";
                    return 1;
                }
            }
        }

        return 0;
    }


    bool isNumber(const std::string& token)
    {
        return std::regex_match(token, std::regex(("((\\+|-)?[[:digit:]]+)(\\.(([[:digit:]]+)?))?")));
    }

    // Generic parser for vectors
    template <typename T>
    inline int parseValues(std::vector<std::pair<std::string, std::vector<T>*>>& parameterPairs, int argc, char* argv[]) {
        std::unordered_map<std::string, std::vector<T>*> paramMap;
        for (const auto& p : parameterPairs) {
            paramMap["-" + p.first] = p.second;
        }
        for (int i = 1; i < argc; ++i) {
            auto it = paramMap.find(argv[i]);
            if (it != paramMap.end()) {
                try {
                    for (int j = i + 1; j < argc && (isNumber(argv[j]) || argv[j][0] != '-'); ++j, ++i)
                        it->second->push_back(convertFromString<T>(argv[j]));
                }
                catch (const std::exception& e) {
                    std::cerr << "Error parsing " << it->first << ": " << e.what() << "\n";
                    return 1;
                }
            }
        }

        return 0;
    }

} // namespace BLFlagParser

#endif // BLFLAGPARSER_HPP