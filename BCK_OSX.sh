#! /bin/bash
 
 . $HOME/.rootenv # File contenente tutte le variabili / This file contains all variables
 
 set -x
# Script per il backup della componente server
# Verrà effettuato il backup delle impostazioni
# Dell'Open Directory
# Del Profile Manager
# e del Wiki (DB Compreso)

#### ELIMINO FILE TEMPORANEI / Remove temporary files

rm ${TMP_SERVER_RISULTATO}
rm ${TMP_SERVIZI_RISULTATO}
rm ${TMP_OD_RISULTATO}
rm ${TMP_MAIL_RISULTATO}
rm ${TMP_SICUREZZA_RISULTATO}
rm ${TMP_REMOVE_RISULTATO}
rm ${TMP_OWNER_RISULTATO}
rm ${TMP_CORPO_MAIL}

### Funzione Backup Servzi Server / Server Configuration files backup

function ServerAdminBackup {
	
	{
		 ${SERVERADMIN} settings all -x > ${SETTINGS_FILENAME}
			if [ "$?" ==  0 ];
				then
					echo -e "Backup dei servizi Server eseguito correttamente\n " >> ${TMP_SERVER_RISULTATO}
				else
					echo -e "ATTENZIONE: problemi con il backup dei servizi Server\n " >> ${TMP_SERVER_RISULTATO}
				fi
	}
	lista_servizi=$(${SERVERADMIN} list)
	{
		for SERVIZIO in ${lista_servizi}; 
		do
	 		${SERVERADMIN} settings ${SERVIZIO} -x > ${GEN_BCK_DEST}/BCK_${SERVIZIO}_${DATE}.plist
				if [ "$?" ==  0 ];
					then
						echo -e "Backup del ${SERVIZIO} eseguito con esito positivo\n " >> ${TMP_SERVIZI_RISULTATO}
					else
						echo -e "ATTENZIONE: Backup del ${SERVIZIO} eseguito con esito negativo\n " >> ${TMP_SERVIZI_RISULTATO}
				fi
		done
	}
				}



### Funzione Backup OD / Open Directory backup

function DirServBackup {

    echo "dirserv:backupArchiveParams:archivePassword = ${PASS}" > ${GEN_BCK_DEST}/od_env.txt
            echo "dirserv:backupArchiveParams:archivePath = ${GEN_BCK_DEST}/DirServ_$DATE.sparseimage" >> ${GEN_BCK_DEST}/od_env.txt
            echo "dirserv:command = backupArchive" >> ${GEN_BCK_DEST}/od_env.txt
            echo "" >> ${GEN_BCK_DEST}/od_env.txt
   ${SERVERADMIN} command < $OD_BCK_DEST/od_env.txt
			if [ "$?" ==  0 ];
				then
					echo -e "Backup dei dati di Open Directory eseguita correttamente\n " >> ${TMP_OD_RISULTATO}
				else
					echo -e "ATTENZIONE: problemi con il backup dei dati di Open Directory\n " >> ${TMP_OD_RISULTATO}
			fi


			}		





### Funzione Backup Cartella Mail / Mail Folder backup (Server Side)

function MailBackup {

	  tar -cvf ${GEN_BCK_DEST}/${MAIL_BCK_NAME} /Library/Server/Mail
	 gzip ${GEN_BCK_DEST}/${MAIL_BCK_NAME}			
			if [ "$?" ==  0 ];
				then
					echo -e "Backup della componente Mail eseguita con esito positivo\n " >> ${TMP_MAIL_RISULTATO}
				else
					echo -e "ATTENZIONE: Backup della componente Mail eseguita con esito negativo\n " >> ${TMP_MAIL_RISULTATO}
			fi				
		}



### Funzione Backup Copia di Sicurezza / Security Copy (different device)

function CopiaSicurezza {
	scp -r ${GEN_BCK_DEST}/*${DATE}* root@nas:${BCKNASOSX}
		if [ "$?" ==  0 ];
			then
				echo -e "Backup di sicurezza eseguito con esito positivo\n " >> ${TMP_SICUREZZA_RISULTATO}
			else
				echo -e "ATTENZIONE: Backup di sicurezza eseguito con esito negativo\n " >> ${TMP_SICUREZZA_RISULTATO}
		fi
			}


### Funzione Eliminazione Vecchi File (END_LIFE & END_LIFE: giorni di retention) / Remove Old Files (END_LIFE & END_LIFE_NAS= days of retention)
							
function EliminaVecchiBCK {
	
	find ${GEN_BCK_DELETE} -mtime ${END_LIFE} -exec rm -rf {} \;
	ssh root@nas "find ${BCKNASOSX} -mtime ${END_LIFE_NAS} -exec rm -rf {} \;"
		if [ "$?" ==  0 ];
			then
				echo -e "I file sono stati rimossi con esito positivo\n " >> ${TMP_REMOVE_RISULTATO}
			else
				echo -e "ATTENZIONE: Problemi nella fase di rimozione dei file\n " >> ${TMP_REMOVE_RISULTATO}
		fi
			} 
			
### Funzione di cambio proprietario / Changing Owner & Group

function CambioPermessi {

		chown -R ${MYUSER}:${MYGROUP} ${GEN_BCK_DEST}
		#chown -R thegod:staff ${GEN_BCK_DEST}

		if [ "$?" ==  0 ];
			then
				echo -e "Cambio proprietario eseguito correttamente\n " >> ${TMP_OWNER_RISULTATO}
			else
				echo -e "ATTENZIONE: ATTENZIONE: Problemi nella fase di cambio permessi del proprietario\n " >> ${TMP_OWNER_RISULTATO}
		fi

}

### Funzione per la creazione del corpo della mail da inviare / Now I create a body mail

function CorpoMail {
	echo -e "Salve,\n " > ${TMP_CORPO_MAIL}
	echo -e "questo il report del ${OGGI2}\n " >> ${TMP_CORPO_MAIL}
	cat ${TMP_SERVER_RISULTATO} >> ${TMP_CORPO_MAIL}
	cat ${TMP_SERVIZI_RISULTATO} >> ${TMP_CORPO_MAIL}
	cat ${TMP_OD_RISULTATO} >> ${TMP_CORPO_MAIL}
	cat ${TMP_MAIL_RISULTATO} >> ${TMP_CORPO_MAIL}
	cat ${TMP_SICUREZZA_RISULTATO} >> ${TMP_CORPO_MAIL}
	cat ${TMP_REMOVE_RISULTATO} >> ${TMP_CORPO_MAIL}
	cat ${TMP_OWNER_RISULTATO} >> ${TMP_CORPO_MAIL}
	echo -e "Mail generata automaticamente. Si prega di non rispondere alla presente casella mail, in quanto non presidiata.\n " >> ${TMP_CORPO}
	echo -e "Grazie per la collaborazione.\n " >> ${TMP_CORPO_MAIL}
	echo -e "Saluti.\n " >> ${TMP_CORPO_MAIL}
}


# Funzione per l'invio della mail / Send Mail Function

function InviaReportMail {

cat ${TMP_CORPO_MAIL} | mailx -s "Risultato del Backup della Componente Server del ${OGGI2}" "${RECEIVER}" -F "Admin" -f "${SENDER}"

}
 

### CASE

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
			CambioPermessi
			CorpoMail			
			InviaReportMail
			;;
	*)
	echo "UTILIZZO:{ServerBCK|OpenDirBCK|MailBCK|CopiaBCK|RemoveBCK|ALL}"
	;;
esac
