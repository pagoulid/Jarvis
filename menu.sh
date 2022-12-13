#!/bin/bash
########### MESSAGE FUNCTIONS ###############
function greeting {
 printf "[!] Hello sir Jarvis is here to help you\n\n\n\n"

}

function service_greeting {
  printf "[!] Welcome to the service menu!\n\n\n\n"

}

function unspecified {
 printf "[+] Cannot understand your command Sir\n"
 newline
 main
}

function what {
 printf "\t[+] What can i do for you today, Sir?\n\n"
}

function newline {
  printf "\n===================\n\n"
}
########### MESSAGE FUNCTIONS #########
########### MAIN FUNCTIONS ############
########### MAIN FUNCTIONS ############ 
function status {
  printf "[+] Your machine stats are:\n\n"

  load_avg
  util
  newline
  main

}

function who {

 printf "\t[+] Active users:\n"

 loggedin
 newline
 main

}

function updates {
 sync
 packages
 os_release
 newline
 main

}

function storage {
 partitions
 echo ''
 newline
 main
}


########### MAIN FUNCTIONS ############



############## STATUS ###############
function load_avg {
 uptime=$("uptime")
 load=${uptime:${#uptime}-16:16}
 echo "LOAD AVERAGE: "$load""
}

function util {
 cpu_util
 mem_util
}

function cpu_util {

 while read -r line;do

  IFS=' '
  read -ra arr <<< ""$line""

  idle=""
  tmp="" # tmp for checking prev item
  SUB="ni"

  for val in ""${arr[@]}""; do

    STR=""$val""

    if [[ "$tmp" = "ni" ]]; # if prev el is ni next value is % of idle
    then
     idle=""$val""
     tmp=""
    fi

    if [[ "$STR" == *"$SUB"* ]]; # if str contains substr 'ni'  next val is  % of idle
    then
     tmp="ni"
    fi

  done

  #echo "IDLE TIME: "$idle"" # e.g. 70,8

  if [[ ""$idle"" =~ (.*)\,(.*) ]] # splits physical and decimal numeric parts of idle stat
  then
   FIRST=${BASH_REMATCH[1]}
   FIRST=$((100-$FIRST))
   echo "Cpu util: "$FIRST"."${BASH_REMATCH[2]}"%" # e.g. 45.2%
  fi
  
 done < <(top -n1 | grep -w Cpu | tr -d '^[(Bm3941;')

}

function mem_util {

 while read -r line; do

  IFS=' '  
  read -ra arr <<< ""$line""

  total=${arr[1]}
  used=${arr[2]}

  #echo "Total Mem : "$total""
  #echo "Used Mem : "$used""
  
  total=$((total))
  used=$((used))

  used=$(($used*100))
  mem=$(($used/$total))
  memrem=$(($used%$total)) 
### mem=(used*100)/total , memrem=<remainder of division> ###

  memrem=""$memrem""
  memrem=${memrem:1:1} 
### Round remainder ###

  echo "Memory usage: "$mem"."$memrem"%"

 done < <(free | grep -w Mem )

}

############## STATUS #################
############## WHO #################
function loggedin {
 IFS=' '
 accounts=''

 ####### store unique usernames -> accounts = "username1 username2 username3..."######
 ##################### 
 while read -r line; do
 
  read -ra arr <<< ""$line""

  user=${arr[0]} # first value of line is username  
  if [[ "$accounts" = "" ]];
  then
   accounts=""$user"" # store first user
   echo "[+] User: "$user""
  else

   if [[ "$accounts" == *"$user"* ]]; # if user exist in accounts  
   then
    continue
   else
    accounts=" "$accounts" "$user" "
    echo "[+] User: "$user""
   fi

  fi

 done < <(w -h -s -f)
 ###################

 #echo "Accounts: "$accounts""
 printf '\n'

 usercount=0
 read  -ra arr <<< ""$accounts""
 
   #### for each account check number of users###
 ##############################
 for account in ""${arr[@]}""; do

  while read -r line; do
   
   usercount=$(($usercount+1))   

  done < <(w -h ""$account"")
  
  printf '\t'
  echo "[!] "$usercount" users active on "$account" account"
  usercount=0 # reset count for next account check

 done
 ###############################
 
 printf '\n'
}
############## WHO #################
############## UPDATES #################

function sync {

 printf "\t--[#] Synchronizing repositories. Sir may have to wait some minutes [#]--"
 echo $(apt update 2>/dev/null >> /dev/null)
 printf "\n"
}
function packages {

 printf  "\t[+] There are available updates for:\n"
 

 while read -r line;do
  
  

  if [[ ""$line"" =~ (.*)\/(.*) ]] # format pkg/...
  then
  
   PKG=${BASH_REMATCH[1]}
   
   echo "[-] Package: "$PKG""
   echo ''

  fi


 done < <(apt list --upgradable 2>/dev/null) # 2 is stderr channel send to null to silent warnings
 
}

function os_release {

 os_name=$(cat /etc/os-release | grep -w NAME | tr '"' ' ' | tr "[:upper:]" "[:lower:]") # remove "" from os name

 if [[ ""$os_name"" =~ (.*)\=(.*) ]]
 then
  os_name=$(sed -e 's/^[[:space:]]*//'<<<""${BASH_REMATCH[2]}"") #trim
  os_name=$(sed -e 's/[[:space:]]*$//'<<<""$os_name"")
  release=""$os_name"-release"  
 fi

 IFS=' '

 while read -r line;do #
  
  if [[ "$line" != "" ]]; # if os package  exists to packages which needs upgrade
  then

   read -ra arr <<< ""$line"" # second item iscurrent version last item upgrade version

   length=${#arr}
   new=""${arr[1]}""
   old=""${arr[-1]}""


   old=$(echo ""$old""| tr -d ']')
   old=$(sed -e 's/^[0-9]://g'<<<""$old"") # 
   new=$(sed -e 's/^[0-9]://g'<<<""$new"")

   printf '\t'
   echo "[!] Note Sir that "$os_name"  can be upgraded from "$old" current version to "$new""
   printf '\n' 
  fi
  
 done < <(apt list --upgradable 2>/dev/null | grep -w  -m 1 ""$release"")

}

############## UPDATES #################
############## SERVICES #################
function services {
  service_greeting
  what
  service_menu
}
function service_menu {

  selections="check exit"
  PS3=''
 select selection in $selections; do

  case $selection in

   "check")
     which
     newline
     ;;
   "exit")
     echo "[#] Exiting services..."
     newline
     main
      ;;
    *)
     unspecified
     which
     ;;
   esac
  done
}
function which {
 
 msg=''
 ## until user requests an existed service#
 until [[ "$msg" == *"status"* ]];do
  echo "[+] Which service do you wnat to check Sir?: "
  printf "\n"

  read input
  service=""$input""
 

  msg=$(systemctl status ""$service"" | grep -w 'Active')

  msg=${msg//'Active'/'[+] Service  status'}

  echo ""$msg"" # output of systemctl status

 done

 
 printf  "\n[+] What do you want me todo with that service?\n"
 
 selections="start stop reload nothing exit"
  PS3=''

 select selection in $selections; do

  case $selection in
  "start")
     echo $(systemctl start ""$service"")
     echo ''
     echo "[#] Starting "$service" service..."
     newline
     which
     ;;
   "stop")
     echo $(systemctl stop ""$service"")
     echo ''
     echo "[#] Stoping "$service" service..."
     newline
     which
     ;;
   "reload")
     echo $(systemctl reload ""$service"")
     echo ''
     echo "[#] Reloading  "$service" service..."
     newline
     which
     ;;
    "nothing")
      newline
      which
      ;;
    "exit")
      
      echo "[#] Back to service menu..."
      newline
      printf '\n'
      what
      printf '\n'
      service_menu
      ;;
     *)
     unspecified
     which
     ;;
  esac
 done

}

############## SERVICES #################
############## STORAGE #################

function partitions {

 lcount=0
 nomount=''
 IFS=' '

 echo "		[+] Your Storage info is:"
 printf '\n'
 
 while read -r line;do

  line=$(echo ""$line"" | tr ' ' '|')

   if [[ ""$line"" =~ (.*)\|(.*)\|(.*)\|(.*)\|(.*)\|(.*) ]]
   then

     
     
    echo "[-] Partition: "${BASH_REMATCH[1]}"                [-] Mount point: "${BASH_REMATCH[6]}""
     

    printf "\n"

   fi



  IFS=' '

 done < <(df -h |df -h | grep -w "/dev/sd.*" )

}
############## STORAGE #################

########## MAIN #######################
function main {


 what
 selections="status who updates services storage quit"
 PS3=''
 select selection in $selections; do

  case $selection in
  "status")
     status
     ;;
   "who")
     who
     ;;
   "updates")
     updates
     ;;
    "services")
      services
      ;;
    "storage")
      storage
      ;;
    "quit")
     exit 0
     ;;
     *)
     unspecified
     ;;
  esac
 done


}
########## MAIN #######################


greeting
main
