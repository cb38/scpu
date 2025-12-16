#ifndef ASSEMBLER_H
#define ASSEMBLER_H

#include <string>
#include <vector>
#include <map>
#include <fstream>
#include <sstream>
#include <iostream>
#include <cctype>
#include <algorithm>

class Assembler
{
public:
    // Opcodes
    static constexpr uint8_t NOP = 0x00;
    static constexpr uint8_t ADD = 0x01;
    static constexpr uint8_t SUB = 0x02;
    static constexpr uint8_t BRNZ = 0x03;
    static constexpr uint8_t STR = 0x06;
    static constexpr uint8_t LD = 0x07;
    static constexpr uint8_t LDI = 0x08;
    static constexpr uint8_t EXIT = 0xFF;

    struct Symbol
    {
        std::string name;
        int address;
    };

    Assembler() = default;

    // Assemble program from file
    bool assemble(const std::string &filename, std::vector<uint16_t> &program)
    {
        program.clear();
        symbols.clear();

        std::ifstream file(filename);
        if (!file.is_open())
        {
            std::cerr << "Error: Cannot open file " << filename << std::endl;
            return false;
        }

        std::string line;
        int pc = 0;

        // Read and assemble
        while (std::getline(file, line) && pc < 256)
        {
            uint16_t instr = parseLine(line, pc);
            if (instr != INVALID_INSTR)
            {
                program.push_back(instr);
            }
        }

        file.close();

        displayProgram(program);
        return true;
    }

    // Get symbols
    const std::vector<Symbol> &getSymbols() const
    {
        return symbols;
    }

private:
    static constexpr uint16_t INVALID_INSTR = 0xFFFF;
    std::vector<Symbol> symbols;

    // Trim whitespace
    std::string trim(const std::string &str)
    {
        size_t first = str.find_first_not_of(" \t\r\n");
        if (first == std::string::npos)
            return "";
        size_t last = str.find_last_not_of(" \t\r\n");
        return str.substr(first, (last - first + 1));
    }

    // Convert string to lowercase
    std::string toLower(const std::string &str)
    {
        std::string result = str;
        std::transform(result.begin(), result.end(), result.begin(),
                       [](unsigned char c)
                       { return std::tolower(c); });
        return result;
    }

    // Split string into tokens
    std::vector<std::string> splitTokens(const std::string &str)
    {
        std::vector<std::string> tokens;
        std::istringstream iss(str);
        std::string token;

        while (iss >> token)
        {
            tokens.push_back(token);
        }

        return tokens;
    }

    // Convert string to integer (hex or decimal)
    int str2int(const std::string &s)
    {
        if (s.substr(0, 2) == "0x" || s.substr(0, 2) == "0X")
        {
            return std::stoi(s.substr(2), nullptr, 16);
        }
        else
        {
            return std::stoi(s);
        }
    }

    // Parse single assembly line
    uint16_t parseLine(const std::string &line, int &pc)
    {
        std::string trimmed = trim(line);

        // Skip empty lines and comments
        if (trimmed.empty() || trimmed[0] == '#')
        {
            return INVALID_INSTR;
        }

        std::vector<std::string> tokens = splitTokens(trimmed);
        if (tokens.empty())
        {
            return INVALID_INSTR;
        }

        // Handle labels
        if (tokens[0].back() == ':')
        {
            Symbol sym;
            sym.name = tokens[0].substr(0, tokens[0].length() - 1);
            sym.address = pc;
            symbols.push_back(sym);

            // Remove label from tokens
            tokens.erase(tokens.begin());
            if (tokens.empty())
            {
                return INVALID_INSTR;
            }
        }

        // Parse instruction
        std::string mnemonic = toLower(tokens[0]);
        uint16_t instruction = 0;

        if (mnemonic == "nop")
        {
            instruction = NOP;
        }
        else if (mnemonic == "add" && tokens.size() > 1)
        {
            instruction = (str2int(tokens[1]) << 8) | ADD;
        }
        else if (mnemonic == "sub" && tokens.size() > 1)
        {
            instruction = (str2int(tokens[1]) << 8) | SUB;
        }
        else if (mnemonic == "ld" && tokens.size() > 1)
        {
            instruction = (str2int(tokens[1]) << 8) | LD;
        }
        else if (mnemonic == "ldi" && tokens.size() > 1)
        {
            instruction = (str2int(tokens[1]) << 8) | LDI;
        }
        else if (mnemonic == "st" && tokens.size() > 1)
        {
            instruction = (str2int(tokens[1]) << 8) | STR;
        }
        else if (mnemonic == "brnz" && tokens.size() > 1)
        {
            instruction = (str2int(tokens[1]) << 8) | BRNZ;
        }
        else if (mnemonic == "exit")
        {
            instruction = EXIT;
        }
        else
        {
            std::cerr << "Unknown instruction: " << mnemonic << std::endl;
            return INVALID_INSTR;
        }

        pc++;
        return instruction;
    }

    // Display assembled program
    void displayProgram(const std::vector<uint16_t> &program)
    {
        std::cout << "Assembled program:" << std::endl;
        for (size_t i = 0; i < program.size(); i++)
        {
            printf("%03lx: %04x\n", i, program[i]);
        }
        std::cout << "Total instructions: " << program.size() << std::endl;
    }
};

#endif // ASSEMBLER_H
