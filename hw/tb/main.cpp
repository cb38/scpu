#include "Vcpu_tb.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include "assembler.h"
#include <iostream>
#include <vector>
#include <cstdio>
#include <fstream>

int main(int argc, char **argv)
{
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    // Create model
    Vcpu_tb *top = new Vcpu_tb;

    // Create wave dump
    VerilatedFstC *tfp = new VerilatedFstC;
    top->trace(tfp, 99);
    tfp->open("hw/gen/sim/waveform.fst");

    // Parse command line arguments
    std::string program_file = "asm/cpu.asm";
    bool verbose = false;

    for (int i = 1; i < argc; i++)
    {
        std::string arg(argv[i]);
        if (arg.find("+program=") == 0)
        {
            program_file = arg.substr(9);
        }
        if (arg.find("+verbose=") == 0)
        {
            verbose = (arg[arg.length() - 1] == '1');
        }
    }

    // Assemble program
    Assembler assembler;
    std::vector<uint16_t> program;

    if (!assembler.assemble(program_file, program))
    {
        std::cerr << "Assembly failed!" << std::endl;
        return 1;
    }

    // Write program to hex file
    std::string hex_file = "hw/gen/sim/program.hex";
    std::ofstream hex_out(hex_file);
    if (!hex_out.is_open())
    {
        std::cerr << "Failed to open hex file for writing: " << hex_file << std::endl;
        return 1;
    }

    for (size_t i = 0; i < program.size(); i++)
    {
        hex_out << std::hex << program[i] << std::endl;
    }
    hex_out.close();

    if (verbose)
    {
        std::cout << "Program loaded into memory" << std::endl;
    }

    // Run simulation - clock generation
    int max_cycles = 100;
    int cycle = 0;

    // Reset

    // Execute
    while (!Verilated::gotFinish() && cycle < max_cycles)
    {
        top->eval();
        tfp->dump(Verilated::time());

        Verilated::timeInc(5);
        cycle++;
    }

    std::cout << "\n=== Test Results ===" << std::endl;
    std::cout << "Total cycles: " << cycle << std::endl;

    // Cleanup
    tfp->close();
    top->final();
    delete top;
    delete tfp;

    return 0;
}
