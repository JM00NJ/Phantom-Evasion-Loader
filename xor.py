import re


raw_asm = """

"""

hex_values = re.findall(r'0x[0-9a-fA-F]{2}', raw_asm)

# 0xACDAABBBA2BC1337
# İşlemci (x86-64) bunu XOR'larken Little-Endian (Sondan başa) okuyacağı için,
key_bytes = [0x37, 0x13, 0xBC, 0xA2, 0xBB, 0xAB, 0xDA, 0xAC]

encrypted_bytes = []


for i, val in enumerate(hex_values):
    original_byte = int(val, 16)
    # Her 8 baytta bir anahtar döngüsünü başa sar
    key_byte = key_bytes[i % 8] 
    
    # Bayt sınırlarını aşmaması için (0-255 arası kalması için) XOR'la
    encrypted_byte = original_byte ^ key_byte
    encrypted_bytes.append(encrypted_byte)

# NASM formatında çıktı üret
print("c2_payload:")
for i in range(0, len(encrypted_bytes), 12):
    chunk = encrypted_bytes[i:i+12]
    formatted_chunk = ", ".join([f"0x{b:02x}" for b in chunk])
    print(f"\tdb {formatted_chunk}")

print(f"\n[+] Result {len(encrypted_bytes)} The byte was successfully encrypted using QWORD (Little-Endian) logic.")
