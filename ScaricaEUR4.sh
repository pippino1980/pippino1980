#!/bin/bash
# Alpi
#ALPI="https://ftp5.gwdg.de/pub/misc/openstreetmap/openmtbmap/odbl/mtbalpslinux.7z"
#FRANCIA="https://ftp5.gwdg.de/pub/misc/openstreetmap/openmtbmap/odbl/mtbfrancelinux.7z"
#GERMANIA="https://ftp5.gwdg.de/pub/misc/openstreetmap/openmtbmap/odbl/mtbgermanylinux.7z"
# Scelta mappa
mappa=$(zenity --list --checklist --title="Scarica Mappa" --text="seleziona le mappe desiderate" --width=350 --height=550 --column "" --column "Nazione" "" alps "" andorra "" austria "" azores "" belarus "" belgium "" bosnia-herzegovina "" bulgaria "" croatia "" cyprus "" czech-republic "" denmark "" estonia "" faroe-islands "" finland "" france "" georgia "" germany "" great-britain "" greece "" iceland "" ireland "" isle-of-man "" italy "" kosovo "" latvia "" liechtenstein "" lithuania "" luxembourg ""  macedonia ""  malta "" moldova ""  monaco "" montenegro "" netherlands "" norway "" poland "" portugal "" romania "" serbia "" slovakia "" slovenia "" spain "" sweden "" switzerland "" turkey "" ukraine)
if [[ "$?" != "0" ]] ; then
    exit 1
fi

# Scelta Type
Type=$(zenity --entry --title="Scelta TYPE" --width 350 --text="seleziona il formato desiderato" clas easy hike thin trad wide wint)
if [[ "$?" != "0" ]] ; then
    exit 1
fi

# Scelta directory
QMSMAPDIR=$(zenity --file-selection --directory --width 350 --title="Seleziona la cartella di destinazione")
if [[ "$?" != "0" ]] ; then
    exit 1
fi

MKGMAP="/usr/bin/mkgmap"
WGET="/usr/bin/wget"
SZ="/usr/bin/7z"

red="\e[31m"
green="\e[32m"
NC="\e[0m"
error_check() {
  if [ $1 != 0 ]; then
    echo -e "${red}ERROR${NC}"
        exit 1
    else
    echo -e "${green}OK${NC}"
  fi
}

tool_check() {
   which $1 2>&1 1>/dev/null
     if [ $? != 0 ]; then
         echo -e "${red}ERROR: $1 missing${NC}"
         exit 1
     fi
}
tool_check $WGET
tool_check $SZ
${MKGMAP} >/dev/null 2>&1
mappa=(${mappa//|/ }); for (( element = 0 ; element < ${#mappa[@]}; element++ )); do naz=${mappa[$element]};
declare -a FILESCR=""
if [ $naz != "alps" -a $naz != "france" -a $naz != "germany" ]; then 
     FILESCR=( "http://ftp5.gwdg.de/pub/misc/openstreetmap/openmtbmap/odbl/mtb$naz.exe" )
else 
    if [ $naz = "alps" ]; then
        FILESCR=("https://ftp5.gwdg.de/pub/misc/openstreetmap/openmtbmap/odbl/mtbalpslinux.7z" )
    fi
    if [ $naz = "france" ]; then
         FILESCR=("https://ftp5.gwdg.de/pub/misc/openstreetmap/openmtbmap/odbl/mtbfrancelinux.7z" )
    fi
    if [ $naz = "germany" ]; then
        FILESCR=("https://ftp5.gwdg.de/pub/misc/openstreetmap/openmtbmap/odbl/mtbgermanylinux.7z" )
    fi
fi
echo $FILESCR
arraylength=${#FILESCR[@]}
for (( i=0; i<${arraylength}; i++ ));
do
    FILE=${FILESCR[$i]}
    cd $QMSMAPDIR
    # Possibili opzioni per TYPE
    # clas
    # easy
    # hike
    # thin
    # trad -- desktop
    # wide
    # wint
    TYPE=$Type
    TMP=""
    TMP=`mktemp`
    if [ ! -f "${TMP}" ]; then
        echo -e "${red}ERROR: failed to get temp. file${NC}"
        exit 1
    fi
    if [ $? != 0 ]; then
        echo -e "${red}ERROR: mkgmap can\'t be executed${NC}"
        echo -e "${red}ERROR: make sure MKGMAP is set properly in script configuration${NC}"
        exit 1
    fi

    echo -n " * Downloading... " 
        $WGET -O "$TMP" "$FILE" 2>&1 | sed -un 's/.*\ \([0-9]\+%\)\ \+\([0-9.,]\+.\)\ [0-9]\+s$/\1\n# Velocità di download \2B\/s/p' | zenity --progress --percentage=0 --width 350 --auto-close --auto-kill

    error_check $?

    echo -n " * Decompressing... "
        ( $SZ e -o"${TMP}_" ${TMP} >/dev/null
    error_check $?
    # This is needed to extract the map code (e.g. by for Bavaria or bw for baden-wuerttemberg)
    TYPE_FILE=$(basename ${TMP}_/${TYPE}*.TYP)
    tmp=${TYPE_FILE#${TYPE}}
    REGION=${tmp%\.TYP}
    IMGFMT="%Y-%m-%d_${REGION}_OpenMTBMap.img"

    FILETIME=`stat -c %Y ${TMP}`
    IMGFILE=`date -d@${FILETIME} +"${IMGFMT}"`

    echo -n " * Building ${IMGFILE}... "
    cd "${TMP}_"
    if [ $naz = "spain" -o $naz = "belarus" -o $naz = "georgia" -o $naz="norway" ]; then
        FID=`ls -x 6*.img | head -1 | cut -c1-4`
            ${MKGMAP} --show-profiles=1 --product-id=1 --family-id=${FID} --index --gmapsupp 6*.img ${TYPE_FILE} >/dev/null
         error_check $?
    else
    FID=`ls -x 7*.img | head -1 | cut -c1-4`
    
    ${MKGMAP} --show-profiles=1 --product-id=1 --family-id=${FID} --index --gmapsupp 6*.img 7*.img ${TYPE_FILE} >/dev/null
    error_check $?
    fi

    echo -n " * Moving gmapsupp.img to ${QMSMAPDIR}... "
    mv "${TMP}_/gmapsupp.img" "${QMSMAPDIR}/${IMGFILE}"
    error_check $?

    echo -n " * Cleanup... "
    rm -rf "${TMP}" "${TMP}_") | zenity --progress --width 350 --pulsate --text "Attendi..." --title "Preparazione e spostamento mappa" --auto-close --auto-kill
    error_check $?
done
done
zenity --info --text="Operazione completata" --width 350

