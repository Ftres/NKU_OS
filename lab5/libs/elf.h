#ifndef __LIBS_ELF_H__
#define __LIBS_ELF_H__

#include <defs.h>

#define ELF_MAGIC   0x464C457FU         // ELF 文件的魔数 "\x7FELF"（小端序）

/* ELF 文件头 */
struct elfhdr {
    uint32_t e_magic;     // 必须等于 ELF_MAGIC，用于标识 ELF 文件格式
    uint8_t e_elf[12];    // ELF 文件头的保留字段
    uint16_t e_type;      // 1=可重定位文件（relocatable），2=可执行文件（executable），3=共享目标文件（shared object），4=核心转储文件（core image）
    uint16_t e_machine;   // 3=x86, 4=68K, 等等，表示目标体系结构
    uint32_t e_version;   // 文件版本，始终为1
    uint64_t e_entry;     // 如果是可执行文件，表示入口点的虚拟地址
    uint64_t e_phoff;     // 程序头表的文件偏移，或者为0
    uint64_t e_shoff;     // 节头表的文件偏移，或者为0
    uint32_t e_flags;     // 架构相关的标志，通常为0
    uint16_t e_ehsize;    // ELF 文件头的大小
    uint16_t e_phentsize; // 程序头表中每个条目的大小
    uint16_t e_phnum;     // 程序头表中的条目数量，或者为0
    uint16_t e_shentsize; // 节头表中每个条目的大小
    uint16_t e_shnum;     // 节头表中的条目数量，或者为0
    uint16_t e_shstrndx;  // 包含节名字符串的节的编号
};

/* 程序段头 */
struct proghdr {
    uint32_t p_type;   // 可加载的代码或数据，动态链接信息等
    uint32_t p_flags;  // 读/写/执行标志位
    uint64_t p_offset; // 段在文件中的偏移
    uint64_t p_va;     // 映射段的虚拟地址
    uint64_t p_pa;     // 物理地址，未使用
    uint64_t p_filesz; // 段在文件中的大小
    uint64_t p_memsz;  // 段在内存中的大小（如果包含 bss 段，则更大）
    uint64_t p_align;  // 所需的对齐方式，通常是硬件页大小
};

/* Proghdr::p_type 的取值 */
#define ELF_PT_LOAD                     1

/* Proghdr::p_flags 的标志位 */
#define ELF_PF_X                        1  // 可执行标志
#define ELF_PF_W                        2  // 可写标志
#define ELF_PF_R                        4  // 可读标志

#endif /* !__LIBS_ELF_H__ */

// #ifndef __LIBS_ELF_H__
// #define __LIBS_ELF_H__

// #include <defs.h>

// #define ELF_MAGIC   0x464C457FU         // "\x7FELF" in little endian

// /* file header */
// struct elfhdr {
//     uint32_t e_magic;     // must equal ELF_MAGIC
//     uint8_t e_elf[12];
//     uint16_t e_type;      // 1=relocatable, 2=executable, 3=shared object, 4=core image
//     uint16_t e_machine;   // 3=x86, 4=68K, etc.
//     uint32_t e_version;   // file version, always 1
//     uint64_t e_entry;     // entry point if executable
//     uint64_t e_phoff;     // file position of program header or 0
//     uint64_t e_shoff;     // file position of section header or 0
//     uint32_t e_flags;     // architecture-specific flags, usually 0
//     uint16_t e_ehsize;    // size of this elf header
//     uint16_t e_phentsize; // size of an entry in program header
//     uint16_t e_phnum;     // number of entries in program header or 0
//     uint16_t e_shentsize; // size of an entry in section header
//     uint16_t e_shnum;     // number of entries in section header or 0
//     uint16_t e_shstrndx;  // section number that contains section name strings
// };

// /* program section header */
// struct proghdr {
//     uint32_t p_type;   // loadable code or data, dynamic linking info,etc.
//     uint32_t p_flags;  // read/write/execute bits
//     uint64_t p_offset; // file offset of segment
//     uint64_t p_va;     // virtual address to map segment
//     uint64_t p_pa;     // physical address, not used
//     uint64_t p_filesz; // size of segment in file
//     uint64_t p_memsz;  // size of segment in memory (bigger if contains bss）
//     uint64_t p_align;  // required alignment, invariably hardware page size
// };

// /* values for Proghdr::p_type */
// #define ELF_PT_LOAD                     1

// /* flag bits for Proghdr::p_flags */
// #define ELF_PF_X                        1
// #define ELF_PF_W                        2
// #define ELF_PF_R                        4

// #endif /* !__LIBS_ELF_H__ */

