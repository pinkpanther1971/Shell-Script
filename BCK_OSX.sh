#! /bin/bash
 
 . $HOME/.pinkenv
 
 set -x
# Script per il backup della componente server
# Verrà effettuato il backup delle impostazioni
# Dell'Open Directory
# Del Profile Manager
# e del Wiki (DB Compreso)

#### ELIMINO FILE TEMPORANEI

rm ${TMP_SERVER_RISULTATO}
rm ${TMP_SERVIZI_RISULTATO}
rm ${TMP_OD_RISULTATO}
rm ${TMP_MAIL_RISULTATO}
rm ${TMP_SICUREZZA_RISULTATO}
rm ${TMP_REMOVE_RISULTATO}
rm ${TMP_CORPO_MAIL}


function ServerAdminBackup () {
	
	{
		echo "${PASS}" | sudo -S ${SERVERADMIN} settings all -x > ${SETTINGS_FILENAME}
			if [ "$?" ==  0 ];
				then
					ECHO "Backup dei servizi Server eseguito correttamente\n" >> ${TMP_SERVER_RISULTATO}
				else
					ECHO "ATTENZIONE: problemi con il backup dei servizi Server\n" >> ${TMP_SERVER_RISULTATO}
				fi
	}
	lista_servizi=$(echo "${PASS}" | sudo -S ${SERVERADMIN} list)
	{
		for SERVIZIO in ${lista_servizi}; 
		do
	 		sudo ${SERVERADMIN} settings ${SERVIZIO} -x > ${GEN_BCK_DEST}/BCK_${SERVIZIO}_${DATE}.plist
				if [ "$?" ==  0 ];
					then
						ECHO "Backup del ${SERVIZIO} eseguito con esito positivo\n" >> ${TMP_SERVIZI_RISULTATO}
					else
						ECHO "Backup del ${SERVIZIO} eseguito con esito negativo\n" >> ${TMP_SERVIZI_RISULTATO}
				fi
		done
	
				}

function DirServBackup {

		echo "dirserv:backupArchiveParams:archivePassword = ${PASS}" > ${GEN_BCK_DEST}/od_env.txt
		echo "dirserv:backupArchiveParams:archivePath = ${GEN_BCK_DEST}/DirServ_$DATE.sparseimage" >> ${GEN_BCK_DEST}/od_env.txt
		echo "dirserv:command = backupArchive" >> ${GEN_BCK_DEST}/od_env.txt
		echo "" >>${GEN_BCK_DEST}/od_env.txt
		echo ${PASS} | sudo -S ${SERVERADMIN} command < ${GEN_BCK_DEST}/od_env.txt
		gzip ${GEN_BCK_DEST}/DirServ_${DATE}.sparseimage
			if [ "$?" ==  0 ];
				then
					ECHO "Backup dei dati di Open Directory eseguita correttamente\n" >> ${TMP_OD_RISULTATO}
				else
					ECHO "ATTENZIONE: problemi con il backup dei dati di Open Directory\n" >> ${TMP_OD_RISULTATO}
			fi
			}		


function MailBackup {

	echo ${PASS} | sudo -S tar -cvf ${GEN_BCK_DEST}}/${MAIL_BCK_NAME} /Library/Server/Mail
	gzip ${GEN_BCK_DEST}}/${MAIL_BCK_NAME}			
			if [ "$?" ==  0 ];
				then
					ECHO "Backup della componente Mail eseguita con esito positivo\n" >> ${TMP_MAIL_RISULTATO}
				else
					ECHO "Backup della componente Mail eseguita con esito negativo\n" >> ${TMP_MAIL_RISULTATO}
			fi				
		}

function CopiaSicurezza {
	scp -r ${GEN_BCK_DEST}/* root@nas:${BCKNASOSX}
		if [ "$?" ==  0 ];
			then
				ECHO "Backup di sicurezza eseguito con esito positiv\no" >> ${TMP_SICUREZZA_RISULTATO}
			else
				ECHO "Backup di sicurezza eseguito con esito negativo\n" >> ${TMP_SICUREZZA_RISULTATO}
		fi
			}
							
function EliminaVecchiBCK {
	
	find ${GEN_BCK_DELETE} -mtime ${END_LIFE} -exec rm -rf {} \;
	ssh root@nas "find ${BCKNASOSX} -mtime ${END_LIFE_NAS} -exec rm -rf {} \;"
		if [ "$?" ==  0 ];
			then
				ECHO "Backup di sicurezza eseguito con esito positivo\n" >> ${TMP_REMOVE_RISULTATO}
			else
				ECHO "Backup di sicurezza eseguito con esito negativo\n" >> ${TMP_REMOVE_RISULTATO}
		fi
			} 
			
# Funzione per la creazione del corpo della mail da inviare


function CorpoMail {
	ECHO "Salve,\n" > ${TMP_CORPO_MAIL}
	ECHO "questo il report del ${OGGI2}\n" >> ${TMP_CORPO_MAIL}
	cat ${TMP_SERVER_RISULTATO} >> ${TMP_CORPO_MAIL}
	cat ${TMP_SERVIZI_RISULTATO} >> ${TMP_CORPO_MAIL}
	cat ${TMP_OD_RISULTATO} >> ${TMP_CORPO_MAIL}
	cat ${TMP_MAIL_RISULTATO} >> ${TMP_CORPO_MAIL}
	cat ${TMP_SICUREZZA_RISULTATO} >> ${TMP_CORPO_MAIL}
	cat ${TMP_REMOVE_RISULTATO} >> ${TMP_CORPO_MAIL}
	ECHO "Mail generata automaticamente. Si prega di non rispondere alla presente casella mail, in quanto non presidiata.\n" >> ${TMP_CORPO}
	ECHO "Grazie per la collaborazione.\n" >> ${TMP_CORPO_MAIL}
	ECHO "Saluti.\n" >> ${TMP_CORPO_MAIL}
}

# Funzione per l'invio della mail

function InviaReportMail {

cat ${TMP_CORPO_MAIL} | mailx -s "Risultato del Backup della Componente Server del ${OGGI2}" "${RECEIVER}" -F "Admin" -f "${SENDER}"

}

case "${1}" in
        ServerBCK)
			ServerAdminBackup
        ;;
        OpenDirBCK)
			DirServBackup
        ;;
		MailBCK)
			MailBackup
        ;;
		RemoveBCK)
			EliminaVecchiBCK
        ;;
		CopiaBCK)
			CopiaSicurezza
			;;
		ALL)
			ServerAdminBackup
			DirServBackup
			MailBackup
			CopiaSicurezza
			EliminaVecchiBCK
			CorpoMail
			InviaReportMail
	;;
	*)
	echo "UTILIZZO:{ServerBCK|OpenDirBCK|MailBCK|CopiaBCK|RemoveBCK|ALL}"
	;;
esac 
