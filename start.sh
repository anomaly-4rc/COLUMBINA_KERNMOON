#!/bin/bash

ARCH_DETECT=$(uname -m)
KERNEL_DETECT=$(uname -sr)
DATE=$(date)

if [[ "$ARCH_DETECT" == "aarch64" ]]; then
    SYS_TYPE="Android Platform (ARM64)"
else
    SYS_TYPE="Linux Platform (x86_64)"
fi

ORANGE='\e[38;5;214m'
PINK='\e[1;95m'
RED='\e[1;91m'
CYAN='\033[0;36m'
BLUE='\e[38;2;135;206;235m'
LEMON='\033[1;38;2;255;244;79m'
GREEN='\e[1;32m'
NC='\033[0m'

clear
echo -e "${CYAN}|════════════════════════════════════════════════════════════════════════════|${NC}"
echo -e "${CYAN}|${NC}               ${RED}╰┈➤${NC} ${LEMON}𝚆𝙴𝙻𝙲𝙾𝙼𝙴 𝚃𝙾 𝚂𝙲𝚁𝙸𝙿𝚃 𝙱𝚄𝙸𝙻𝙳 ${GREEN}૮₍´˶• . • ⑅ ₎ა${NC}                   ${CYAN}|${NC}"
echo -e "${CYAN}|════════════════════════════════════════════════════════════════════════════|${NC}"
echo -e "${BLUE}BY:${NC} ${LEMON}anomaly-4rc${NC}"
echo -e "${RED}✦─${NC}──${GREEN}──${NC}──${BLUE}──${NC}──${RED}──${NC}──${GREEN}──${NC}──${BLUE}─✦${NC}"

echo -e "${BLUE}[≽(•⩊ •マ≼°➤]${NC} ${ORANGE}Time${NC} ${PINK}⌯⌲${NC} ${GREEN}$DATE${NC}"
echo -e "${BLUE}[≽(•⩊ •マ≼°➤]${NC} ${ORANGE}Architecture${NC} ${PINK}⌯⌲${NC} ${GREEN}$ARCH_DETECT${NC}"
echo -e "${BLUE}[≽(•⩊ •マ≼°➤]${NC} ${ORANGE}Environment${NC} ${PINK}⌯⌲${NC} ${GREEN}$SYS_TYPE${NC}"
echo -e "${BLUE}[≽(•⩊ •マ≼°➤]${NC} ${ORANGE}Kernel${NC} ${PINK}⌯⌲${NC} ${GREEN}$KERNEL_DETECT${NC}"
echo -e "${RED}✦─${NC}──${GREEN}──${NC}──${BLUE}──${NC}──${RED}──${NC}──${GREEN}──${NC}──${BLUE}─✦${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}[≽(•⩊ •マ≼°➤]${NC} ${ORANGE}Select the build configuration you want to run:${NC}    "
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"

PS3=$(echo -e "${BLUE}[≽(•⩊ •マ≼°➤] ${GREEN}Enter your preferred number${NC} ${LEMON}(1-5): ${NC}")

options=(
    "X86 ᯓ➤ Build Using GCC "
    "X86 ᯓ➤ Build Using Clang "
    "ARM ᯓ➤ Build Using GCC "
    "ARM ᯓ➤ Build Using Clang "
    "Exit"
)
echo ""
select opt in "${options[@]}"
do
    case $opt in
        "X86 ᯓ➤ Build Using GCC ")
            echo -e "\n${BLUE}[ᯓ➤]${NC} Operating X86 GCC Build...${NC}"
            if [[ -f "./build.sh" ]]; then
                chmod +x build.sh
                ./build.sh
            else
                echo -e "${RED}[メ]${NC} ${ORANGE}Error: File build.sh not found!${NC}"
            fi
            break
            ;;
        "X86 ᯓ➤ Build Using Clang ")
            echo -e "\n${BLUE}[ᯓ➤]${NC} ${GREEN}Operating X86 Clang Build...${NC}"
            if [[ -f "./build-clang.sh" ]]; then
                chmod +x build-clang.sh
                ./build-clang.sh
            else
                echo -e "${RED}[メ]${NC} ${ORANGE}Error: File build-clang.sh not found!${NC}"
            fi
            break
            ;;
        "ARM ᯓ➤ Build Using GCC ")
            echo -e "\n${BLUE}[ᯓ➤]${NC} ${GREEN}Operating ARM ARM GCC Build...${NC}"
            if [[ -f "./build_ARM.sh" ]]; then
                chmod +x build_ARM.sh
                ./build_ARM.sh
            else
                echo -e "${RED}[メ${NC}] ${ORANGE}Error: File build_ARM.sh not found!${NC}"
            fi
            break
            ;;
        "ARM ᯓ➤ Build Using Clang ")
            echo -e "\n${BLUE}[ᯓ➤]${NC} ${GREEN}Operating ARM ARM Clang Build...${NC}"
            if [[ -f "./build-ARM-clang.sh" ]]; then
                chmod +x build-ARM-clang.sh
                ./build-ARM-clang.sh
            else
                echo -e "${RED}[メ]${NC} ${ORANGE}Error: File build-ARM-clang.sh not found!${NC}"
            fi
            break
            ;;
        "Exit")
            echo -e "\n${BLUE}[ꉂ(˵˃ ᗜ ˂˵)]${NC} ${ORANGE}See you developers...${NC}"
            echo ""
            exit 0
            ;;
        *) 
            echo -e "\n${RED}[メ]${NC} ${ORANGE}Invalid selection! Please enter a number from 1 to 5.${NC}"
            ;;
    esac
    echo ""
done
