use clap::{Arg, Command};

mod pible;

use pible::{Compiler, CompileOptions, CompileTarget};

fn main() -> anyhow::Result<()> {
    let matches = Command::new("pible")
        .version("0.1.0")
        .about("HolyC to BPF Compiler - In Memory of Terry A. Davis")
        .long_about(
            "A divine bridge between Terry Davis's HolyC and BPF runtimes, \
             allowing HolyC programs to run in Linux kernel and Solana blockchain."
        )
        .arg(
            Arg::new("input")
                .help("HolyC source file to compile")
                .required(true)
                .value_name("FILE")
                .index(1)
        )
        .arg(
            Arg::new("target")
                .long("target")
                .help("Compilation target")
                .value_name("TARGET")
                .default_value("linux-bpf")
                .value_parser(["linux-bpf", "solana-bpf", "bpf-vm"])
        )
        .arg(
            Arg::new("generate-idl")
                .long("generate-idl")
                .help("Generate Interface Definition Language for Solana programs")
                .action(clap::ArgAction::SetTrue)
        )
        .arg(
            Arg::new("enable-vm-testing")
                .long("enable-vm-testing")
                .help("Enable BPF VM testing and emulation")
                .action(clap::ArgAction::SetTrue)
        )
        .arg(
            Arg::new("output-dir")
                .long("output-dir")
                .help("Output directory for generated files")
                .value_name("DIR")
        )
        .get_matches();

    let input_file = matches.get_one::<String>("input").unwrap();
    let target = match matches.get_one::<String>("target").unwrap().as_str() {
        "linux-bpf" => CompileTarget::LinuxBpf,
        "solana-bpf" => CompileTarget::SolanaBpf,
        "bpf-vm" => CompileTarget::BpfVm,
        _ => unreachable!(), // clap ensures valid values
    };

    let options = CompileOptions {
        target,
        generate_idl: matches.get_flag("generate-idl"),
        enable_vm_testing: matches.get_flag("enable-vm-testing"),
        solana_program_id: None,
        output_directory: matches.get_one::<String>("output-dir").map(|s| s.as_str()),
    };

    println!("=== Pible - HolyC to BPF Compiler ===");
    println!("Divine compilation initiated...");
    println!("Source: {}", input_file);
    println!("Target: {:?}", target);

    let compiler = Compiler::new();
    compiler.compile_file(input_file, &options)?;

    println!("Divine compilation completed! 🙏");
    Ok(())
}