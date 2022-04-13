#!/bin/bash


# ========================================================== Var

varFolder="$1"
varResultFile="$(pwd)/duplication-result.txt"
varSafeToDelete="$(pwd)/safe-to-delete.txt"
varDeletedLog="$(pwd)/deleted-file.txt"
varRegexFind="^.*$"

# List of Colors
varColorLightRed="\033[1;31m"
varColorLightGreen="\033[1;32m"
varColorYellow="\033[1;33m"
varColorLightBlue="\033[1;34m"
varColorLightPurple="\033[1;35m"
varColorLightCyan="\033[1;36m"
varColorBoldWhite="\033[1;37m"
varNoColor="\033[0m"

varTotalDuplicate=0



# ========================================================== Func

function funcPrint(){
    varMessage=$1
    varMode=$2
    varAddInfo=$3

    if [[ $varMode == "title" ]]; then
        printf "\t\t${varColorBoldWhite} %s ${varNoColor}" "$varMessage"

    elif [[ $varMode == "header" ]]; then
        printf "\n\n [+] ${varColorLightCyan}%s ${varNoColor}\n" "$varMessage"

    elif [[ $varMode == "sub" ]]; then
        varMessage=$(echo "$varMessage" | sed 's/ /*/g')
        printf "%-50s" "**|--[+]*$varMessage*" | sed 's/ /./g' | sed 's/*/ /g'

    elif [[ $varMode == "sub-res" ]]; then
        varMessage=$(echo "$varMessage" | sed 's/*/ /g' | awk '{printf "%s (%s)", $2, $1}')
        printf "      |--[+]${varColorLightPurple} %s ${varNoColor}\n" "$varMessage"

    elif [[ $varMode == "summary" ]]; then
        printf "  |--[+] %-20s => %s\n" "$varMessage" "$varAddInfo"

    else
        n=1
        while read -r line; do
            printf "      |   |--[ %s ]   %s \n" "$n" "$line"
            echo "== $line" >> $varResultFile 2>&1
            
            if [[ n -ge 2 ]]; then
                echo "$line" >> $varSafeToDelete 2>&1
            fi

            n=$(( $n+1 ))
        done
        echo "      |"

    fi
}

function funcCheck(){
    if [[ $? -eq 0 && ${PIPESTATUS[0]} -eq 0 ]]; then
        echo -e "${varColorLightGreen} [ Success ]${varNoColor}"
    else
        echo -e "${varColorLightRed} [ Failed  ]${varNoColor}"
    fi
}

function funcDelete(){
    funcPrint "DUPLICATION CHECKER [ delete mode ]" title
        [ ! -f "$varSafeToDelete" ] && funcPrint "File $varSafeToDelete not exist" header && exit 3

        funcPrint "DELETE" header
            funcPrint "Deleting duplicate file" sub
                cat "$varSafeToDelete" \
                | xargs -IX -n1 -P0 bash -c 'rm -rfv "X" >> '$varDeletedLog''
            funcCheck
}



# ========================================================== Logic

function main(){

    varStartTime=$(date +%s)


    funcPrint "DUPLICATION CHECKER" title
        [ -z "$varFolder" ] && funcPrint "No params given" header && exit 2

        funcPrint "CHECK" header
            funcPrint "Remove Result File" sub
                rm -rf $varResultFile $varSafeToDelete $varDeletedLog errFind.log
            funcCheck

            funcPrint "Checking Duplication" sub
                find $varFolder -type f -regextype egrep -iregex "$varRegexFind" -print0 \
                | xargs -0IX -n1 -P0 bash -c 'md5sum "X" >> '"$varResultFile"' 2> errFind.log'
            funcCheck

        funcPrint "RESULT" header
            funcPrint "Parsing Result" sub
                varListDuplication=$(awk '{print $1}' $varResultFile 2>/dev/null | sort -k1 | uniq -cd | sed 's/^[[:blank:]]*//; s/ /*/g' | sort -t '*' -nk 1,1)
            funcCheck
        
            for i in $varListDuplication; do
                varTotalDuplicate=$(( $varTotalDuplicate+1 ))
                funcPrint $i sub-res
                grep $(echo $i | awk -F '*' '{print $2}') $varResultFile | cut -c 35- | funcPrint
            done
            
            funcPrint "LIST DONE" sub-res



    varEndTime=$(date +%s)
    varRuntime=$(($varEndTime-$varStartTime))
    varTotalHours=$((varRuntime / 3600)); varTotalMinutes=$(( (varRuntime % 3600) / 60 )); varTotalSeconds=$(( (varRuntime % 3600) % 60 ))

    funcPrint "SUMMARY" header
    funcPrint "Time" summary "$varTotalHours : $varTotalMinutes : $varTotalSeconds"
    funcPrint "Scanned File" summary "$(grep -iE '^\w+' $varResultFile 2>/dev/null | wc -l) File(s)"
    funcPrint "Total Duplication" summary "$varTotalDuplicate Item(s)"
    funcPrint "Total Identic File" summary "$(grep -iE '^==' $varResultFile 2>/dev/null | wc -l) File(s)"
    funcPrint "Folder" summary "$varFolder"
    funcPrint "Result File" summary "$varResultFile"
    funcPrint "Safe to delete" summary "$varSafeToDelete"


}

clear

case "$1" in

  d|del|delete|delMode|deleteMode)
    funcDelete
    ;;

  *)
    main
    ;;
esac
