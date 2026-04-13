# 👻 Phantom-Evasion-Loader (x64 Linux)
Phantom-Evasion-Loader is a standalone, pure x64 Assembly injection engine engineered to minimize the detection surface of modern EDR/XDR solutions and Kernel-level monitors like Falco (eBPF). It leverages advanced techniques such as SROP and Zero-Copy Injection to deliver payloads as a ghost in the machine.

# 🧠 What the hell does this code actually do?
Unlike traditional, noisy injectors, this engine is built for stealth. It doesn't scream "I'M MALWARE" at the Kernel. Instead, it mimics legitimate system debugging behavior, performing surgical memory operations that stay under the radar of behavioral analysis.

## 🛠️ Key Technical Features
SROP (Sigreturn Oriented Programming) Hijacking: Instead of manually setting registers one by one via noisy ptrace calls, it uses rt_sigreturn (Syscall 15) to manipulate the entire CPU context in a single, legitimate-looking transaction.

Zero-Copy Injection (process_vm_writev): It ditches the old-school, slow, and heavily monitored PTRACE_POKEDATA loops. By utilizing process_vm_writev (Syscall 311), it pipes the payload directly from the loader's memory to the target process in one hit, bypassing standard "Code Injection" signatures.

Detection Surface Reduction (Falco/EDR): In real-world stress tests, this architecture reduced Falco's default alert noise from over 200 lines of "Critical/Warning" logs to just 8 lines of "Low-Priority Debug" noise.

In-Memory Runtime Decryption (XOR): The payload remains encrypted in memory and is only decrypted at the millisecond of injection. This thwarts static shellcode scanners and basic memory strings analysis.

Dynamic Target Enumeration: Automatically parses the /proc filesystem to locate and target high-privilege root services like cron, systemd, or sshd.

## 🚀 Evasion Strategy
This loader masquerades as a "System Fault Debugger." When renamed to strace or gdb, most EDR rules mark the initial ptrace_attach as an administrative task. The subsequent "heavy lifting"—allocating 8MB of memory and injecting the agent—remains completely invisible thanks to the SROP and process_vm_writev implementation.


## 📝 Important Note: Shellcode Testing
For safety and modularity, this repository does not contain an active malicious payload. The c2_payload section is provided as a placeholder.

To perform a full-scale integration test:

**Go to my https://github.com/JM00NJ/ICMP-Ghost-A-Fileless-x64-Assembly-C2-Agent project.**

Navigate to the Phantom_Loader directory.

Copy the pre-compiled shellcode from loader.asm and paste it into this engine.

**Warning: When using custom shellcode, ensure it is XOR-encrypted with the key 0xACDAABBBA2BC1337 and that the payload size is correctly updated in Phase 3 of the source code.**

## Payload Obfuscation
The loader implements a rolling XOR decryption mechanism. To prepare your shellcode:

**Use the provided xor.py script.**

It processes raw hex strings and encrypts them using an 8-byte Little-Endian key (0xACDAABBBA2BC1337).

This ensures that the xor r10, r14 instruction in the Assembly source correctly restores the original instructions at runtime.
## Resources
**Blog / Technical Writeup:** netacoding.com

**Author:** github.com/JM00NJ

## ⚖️ Licensing
This project is licensed under GNU AGPLv3. I chose this to ensure the research remains open and beneficial to the community.

If the copyleft nature of AGPLv3 doesn't align with your commercial requirements or proprietary environment, feel free to reach out via GitHub Issues or email for custom licensing or collaboration opportunities.

## Legal Disclaimer
**This project is developed for educational purposes and authorized penetration testing only. The author is not responsible for any misuse. Operating this tool against systems you do not own or have explicit written permission to test is illegal.**
