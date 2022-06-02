#!/bin/sh

VOLUME=0
OUT=""
INPUT=""
SERVER="192.168.20.30"
rest_id=1
VERBOSE=0
DRY_RUN=0

function usage {
  echo "./$(basename $0) -h --> shows usage

-l volume
  set volume level 0..50

-o speaker (A|B|AB) 
  set sound to output to speaker A, B or A+B

-i input (sacd-cd|tv)
  set avr input to saca/cd, tv, ...
  
-v
  set vernose mode

-n
  set dry run mode
  "
}

# list of arguments expected in the input
optstring=":hl:o:i:vn"

while getopts ${optstring} arg; do
  case ${arg} in
    v)
      VERBOSE=1
      ;;
    n)
      DRY_RUN=1
      ;;
    h)
      echo "showing usage!"
      usage
      exit
      ;;
    :)
      echo "$0: Must supply an argument to -$OPTARG." >&2
      usage
      exit 1
      ;;
    l)
      VOLUME=${OPTARG}
      ;;
    o)
      OUT=${OPTARG}
      ;;
    i)
      INPUT=${OPTARG}
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      exit 2
      ;;
  esac
done


# if no input argument found, exit the script with usage
if [[ ${#} -eq 0 ]]; then
   usage
   exit
fi

# lib: rest module
# payload: json payload to post to the module
function rest_call {

  local lib="$1"
  local payload="$2"

  ## verbose output
  [[ $VERBOSE -eq 1 ]] && echo call $lib $payload

  [[ $DRY_RUN -eq 0 ]] && curl --location --request POST "http://$SERVER:10000/sony/$lib" \
  --header 'Content-Type: application/json' \
  --data-raw $payload 

  ## increment rest call counter
  ((rest_id++))
}

# change volume
[[ $VOLUME -ne 0 ]] && rest_call "audio" '{"id":'$rest_id',"method":"setAudioVolume","params":[{"volume":"'$VOLUME'","output":""}],"version":"1.1"}'

# change input
[[ $INPUT ]] && rest_call "avContent" '{"id":'$rest_id',"method":"setPlayContent","params":[{"output":"extOutput:zone?zone=1","uri":"extInput:'$INPUT'"}],"version":"1.2"}'

# change speaker pattern
[[ $OUT ]] && rest_call "audio" '{"id":'$rest_id',"method":"setSpeakerSettings","params":[{"settings":[{"value":"speaker'$OUT'","target":"speakerSelection"}]}],"version":"1.0"}'

# set pure direct
