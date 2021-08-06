#!/bin/bash


# START ============================================= VAR

_FOLDER_="$1"
_RES_FILE_="$(pwd)/dup_res.txt"
_REGEX_FIND_="^.*"

# List of Colors
Light_Red="\033[1;31m"
Light_Green="\033[1;32m"
Yellow="\033[1;33m"
Light_Blue="\033[1;34m"
Light_Purple="\033[1;35m"
Light_Cyan="\033[1;36m"
Bold_White="\033[1;37m"
NoColor="\033[0m"

# END ============================================= VAR

_TD_=0

function print(){
    String_=$1
    Mode_=$2
    Info_=$3

    if [[ $Mode_ == "title" ]]; then
        printf "\t\t${Bold_White} %s ${NoColor}" "$String_"

    elif [[ $Mode_ == "header" ]]; then
        printf "\n\n [+] ${Light_Cyan}%s ${NoColor}\n" "$String_"

    elif [[ $Mode_ == "sub" ]]; then
        String_=$(echo "$String_" | sed 's/ /*/g')
        printf "%-50s" "**|--[+]*$String_*" | sed 's/ /./g' | sed 's/*/ /g'

    elif [[ $Mode_ == "sub-res" ]]; then
        String_=$(echo "$String_" | sed 's/*/ /g' | awk '{printf "%s (%s)", $2, $1}')
        printf "      |--[+]${Light_Purple} %s ${NoColor}\n" "$String_"

    elif [[ $Mode_ == "summary" ]]; then
        printf "  |--[+] %-20s => %s\n" "$String_" "$Info_"

    else
        n=1
        while read -r line; do
            printf "      |   |--[ %s ]   %s \n" "$n" "$line"
            echo "== $line" >> $_RES_FILE_ 2>&1
            n=$(( $n+1 ))
        done
        echo "      |"

    fi
}


function check(){
    if [[ $? -eq 0 && ${PIPESTATUS[0]} -eq 0 ]]; then
        echo -e "${Light_Green} [ Success ]${NoColor}"
    else
        echo -e "${Light_Red} [ Failed  ]${NoColor}"
    fi
}

function main(){
    _start_script_=$(date +%s)
    print "DUPLICATION CHECKER" title

    print "CHECK" header
    print "Remove Result File" sub
    rm -rf $_RES_FILE_
    check

    print "Checking Duplication" sub
    find $_FOLDER_ -type f -regex "$_REGEX_FIND_" | xargs -I {} -n 1 -P 50 md5sum {} >> $_RES_FILE_ 2>&1
    check


    print "RESULT" header
    print "Parsing Result" sub
    duplication_=$(cat $_RES_FILE_ | awk '{print $1}' | sort -k 1 | uniq -cd | sed 's/^[[:blank:]]*//;s/ /*/g' | sort -t '*' -nk 1,1)
    check
    
    for i in $duplication_; do
        _TD_=$(( $_TD_+1 ))
        print $i sub-res
        cat $_RES_FILE_ | grep $(echo $i | awk -F '*' '{print $2}') | cut -c 35- | print
    done
    print "LIST DONE" sub-res

    _end_script_=$(date +%s)
    _runtime_script_=$(($_end_script_-$_start_script_))
    hours=$((_runtime_script_ / 3600)); minutes=$(( (_runtime_script_ % 3600) / 60 )); seconds=$(( (_runtime_script_ % 3600) % 60 ))

    print "SUMMARY" header
    print "Time" summary "$hours : $minutes : $seconds"
    print "Folder" summary "$_FOLDER_"
    print "Result File" summary "$_RES_FILE_"
    print "Scanned File" summary "$(cat $_RES_FILE_ | grep -iE '^\w+' | wc -l) File(s)"
    print "Total Duplication" summary "$_TD_ Item(s)"
    print "Total Identic File" summary "$(cat $_RES_FILE_ | grep -iE '^==' | wc -l) File(s)"
}

clear
main
