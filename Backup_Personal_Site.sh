#! /bin/bash

#set -x
# Lo script consente di effettuare il backup dei DB MySQL, della componente WEB e la rimozione 
# dei file piu vecchi di 5 giorni.
# E' possibile anche effettuare lo stop/start della parte Web

# Carico le variabili necessarie allo script

. $PATH/env_file

#### ELIMINO FILE TEMPORANEI

rm ${TMP_RISULTATO}
rm ${TMP_CORPO}

#### INIZIO FUNZIONI ####


# Funzione per lo Stop Componente web
function StopServer {
	
${SERVERADMIN} stop web

}

# Funzione per lo Start Componente web
function StartServer {
	
${SERVERADMIN} start web

}

# Funzione per il Backup dei DB

function BackupDB {

for i in ${DB_NAME}; do
mysqldump -u ${DB_USER} --password=${DB_PWD} ${i} > ${OUTDIR}/${i}_${DATA}.sql
if [ "$?" ==  0 ];
then
echo "DATABASE ${i}: Il backup ${i} ha avuto esito positivo" >> ${TMP_RISULTATO}
echo "" >> ${TMP_RISULTATO}
else
echo "ATTENZIONE: DATABASE ${i}: Il backup ${i} ha avuto esito negativo" >> ${TMP_RISULTATO}
echo "" >> ${TMP_RISULTATO}
fi
done
}

# Funzione per il Backup della parte Web

function BackupWEB {

tar -cvf ${OUTDIR}/WebServer_${DATA}.tar ${WEBDIR}
gzip ${OUTDIR}/WebServer_${DATA}.tar
if [ "$?" ==  0 ];
then
echo "Il backup della componente WEB ha avuto esito positivo" >> ${TMP_RISULTATO}
echo "" >> ${TMP_RISULTATO}
else
echo "ATTENZIONE: Il backup della componente WEB ha avuto esito negativo" >> ${TMP_RISULTATO}
echo "" >> ${TMP_RISULTATO}
fi
}

# Funzione per la copia di sicurezza su discon NAS

function CopiaSicurezza {
	scp ${OUTDIR}/*_${DATA}.sql root@nas:${BCKNAS}
	scp ${OUTDIR}/WebServer_${DATA}.tar.gz root@nas:${BCKNAS}
if [ "$?" ==  0 ];
then
echo "La copia di sicurezza su disco NAS ha avuto esito positivo" >> ${TMP_RISULTATO}
echo "" >> ${TMP_RISULTATO}
else
echo "ATTENZIONE: La copia di sicurezza su disco NAS avuto esito negativo" >> ${TMP_RISULTATO}
echo "" >> ${TMP_RISULTATO}
fi
}

# Funzione per la rimozione dei file in base a quanto impostato nella variabile END_LIFE

function EliminaVecchiBCK {

        find ${OUTDIR} -mtime ${END_LIFE} -exec rm -rf {} \;
	ssh root@nas "find ${BCKNAS} -mtime ${END_LIFE_NAS} -exec rm -f {} \;"
	if [ "$?" ==  0 ];
	then
echo "I vecchi file sono stati rimossi con successo" >> ${TMP_RISULTATO}
echo "" >> ${TMP_RISULTATO}
else
echo "ATTENZIONE: Non sono riuscito a rimuovere i vecchi file" >> ${TMP_RISULTATO}
echo "" >> ${TMP_RISULTATO}
	fi
}

### Funzione di cambio proprietario / Changing Owner & Group

function CambioPermessi {

                chown -R ${MYUSER}:${MYGROUP} ${GEN_BCK_DEST}
              #  chown -R thegod:staff ${OUTDIR}

                if [ "$?" ==  0 ];
                        then
			echo -e "Cambio proprietario eseguito correttamente\n " >> ${TMP_RISULTATO}
                        else
                                echo -e "ATTENZIONE: Problemi nella fase di cambio permessi del proprietario\n " >> ${TMP_RISULTATO}
                fi

}

# Funzione per la creazione del corpo della mail da inviare

function CorpoMail {
echo "Salve," > ${TMP_CORPO}
echo "" >> ${TMP_CORPO}
echo "questo il report del ${OGGI2}" >> ${TMP_CORPO}
echo "" >> ${TMP_CORPO}
cat ${TMP_RISULTATO} >> ${TMP_CORPO}
echo "Mail generata automaticamente. Si prega di non rispondere alla presente casella mail, in quanto non presidiata." >> ${TMP_CORPO}
echo "" >> ${TMP_CORPO}
echo "Grazie per la collaborazione." >> ${TMP_CORPO}
echo "" >> ${TMP_CORPO}
echo Saluti."" >> ${TMP_CORPO}
echo "" >> ${TMP_CORPO}
}

# Funzione per l'invio della mail

function InviaReportMail {

cat ${TMP_CORPO} | mailx -s "Risultato del Backup del ${OGGI2}" "${RECEIVER}" -F "Admin" -f "${SENDER}"

}

#### MAIN PROGRAM ####

case "${1}" in
	stop)
		StopServer
	;;
	start)
		StartServer
	;;
	db)
		BackupDB
	;;
	web)
		BackupWEB
	;;
	RemoveBCK)
		EliminaVecchiBCK
        ;;
	all)
		BackupDB
		BackupWEB
		CopiaSicurezza
		EliminaVecchiBCK
		CambioPermessi
		CorpoMail
		InviaReportMail
	;;
	*)
	echo "Usage: start|stop|db|web|RemoveBCK|all"
	echo "start = start WS"
	echo "stop = stop WS"
	echo "db = Backup DB"
	echo "web = Backup WS"
	echo "RemoveBCK = Cancellazione file obosoleti"
	echo "all = Effettua il backup del db e della parte WS"
	rval=1
	;;

esac
