if VERSION < v"0.5-dev"
    error("Cxx requires Julia 0.5")
end

#in case we have specified the path to the julia installation
#that contains the headers etc, use that
BASE_JULIA_BIN = get(ENV, "BASE_JULIA_BIN", JULIA_HOME)
BASE_JULIA_SRC = get(ENV, "BASE_JULIA_SRC", joinpath(BASE_JULIA_BIN, "../.."))

#write a simple include file with that path
println("writing path.jl file")
s = """
const BASE_JULIA_BIN=\"$BASE_JULIA_BIN\"
export BASE_JULIA_BIN

const BASE_JULIA_SRC=\"$BASE_JULIA_SRC\"
export BASE_JULIA_SRC
"""
f = open(joinpath(dirname(@__FILE__),"path.jl"), "w")
write(f, s)
close(f)

println("Tuning for julia installation at $BASE_JULIA_BIN with sources possibly at $BASE_JULIA_SRC")

# Try to autodetect C++ ABI in use
llvm_lib_path = Libdl.dlpath("libLLVM-$(Base.libllvm_version)")
old_cxx_abi = searchindex(open(read, llvm_lib_path),"_ZN4llvm3sys16getProcessTripleEv".data,0) != 0
old_cxx_abi && (ENV["OLD_CXX_ABI"] = "1")

llvm_config_path = joinpath(BASE_JULIA_BIN,"..","tools","llvm-config")
if isfile(llvm_config_path)
    info("Building julia source build")
    ENV["LLVM_CONFIG"] = llvm_config_path
    delete!(ENV,"LLVM_VER")
else
    info("Building julia binary build")
    ENV["LLVM_VER"] = Base.libllvm_version
    ENV["JULIA_BINARY_BUILD"] = "1"
    ENV["PATH"] = string(JULIA_HOME,":",ENV["PATH"])
end
run(`make -j$(Sys.CPU_CORES) -f BuildBootstrap.Makefile BASE_JULIA_BIN=$BASE_JULIA_BIN BASE_JULIA_SRC=$BASE_JULIA_SRC`)
