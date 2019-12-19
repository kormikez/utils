#!/usr/bin/env bash
# kormikez@19dec2019

# This scripts depends on Medihunter:
# https://github.com/apqlzm/medihunter

# Example cron entry:
# */15 * * * * U=1234567 P='dGFqbmVoYXNsbwo=' S=100 D=12345 F=2020 /home/user/scripts/medihunter.sh
#              ^User     ^Password (base64)   ^Spec ^Doctor ^Filter - i.e. date
# 
# Test the setup by executing with TEST env variable set, i.e.:
# TEST=true U=1234567 P='dGFqbmVoYXNsbwo=' S=100 /home/user/scripts/medihunter.sh

MEDIHUNTER_PATH=/home/user/venv/medihunter
MAILTO=medihunter@example.com

if [ "$TEST" == "" ]; then
    sleep "$((RANDOM%5))"
    # random wait to avoid exploiting the service while having many crons
fi

if [ "$D" == "" ]; then D=-1; fi

PW=$(echo $P |base64 -d)

source "${MEDIHUNTER_PATH}/bin/activate"

# set generic name in case specialization is not definied in Medihunter
spec="$(medihunter show-params -f specialization | grep id=${S})"
if [ "$spec" == "" ]; then spec="Specjalizacja #$S"; fi

# execute the actual query
apts=$(medihunter find-appointment --region 207 --specialization ${S} --user ${U} --password ${PW} --doctor $D |grep ^20 |grep "$F");
echo "$apts" > /tmp/medihunter_current
if [ "$?" -eq "0" ]; then
    # if the appointments haven't been reported already, fire off an e-mail
    new_apts=$(diff --new-line-format="" --unchanged-line-format="" /tmp/medihunter_current /tmp/medihunter_history)
    if [ "$new_apts" != "" ]; then
        echo -en "Wizyty:\n$new_apts" | mail -s "Medihunter: ${spec}" ${MAILTO};
        echo "$new_apts" >> /tmp/medihunter_history
    fi
    rm /tmp/medihunter_current
else
    echo "$(date) Błąd Medihuntera >> /tmp/medihunter_log"
fi
if [ "$TEST" != "" ]; then
    echo -en "Wizyty:\n$apts\n"
fi
