BAKDIR=/backups
PCBAKDIR=/backups/pc
SPACE=`df -h | grep dev/mapper | awk '{ print $5 }' | sed 's/%//'`
LOG=/var/log/backup.log
MAIL=root@localhost
PC=(charmander@192.168.0.204 blastoise@192.168.0.203)

{
mkdir -p $PCBAKDIR
chmod 733 $PCBAKDIR
if [ ! -e $LOG ] ; then
  touch $LOG
fi

#kollar att skriptet körs som root användaren
if [ "$EUID" -ne 0 ]
 then echo "Run this script as the root user please."
 exit
fi

tar cvpzf $BAKDIR/backup`date +"%m_%d_%Y"`.tgz --exclude=/proc --exclude=/lost+found --exclude=/backup.tgz --exclude=/mnt --exclude=/sys /home

#kontrollera utrymmet på disken och börjar skicka mail när disken är håller på och blir full.
if      [ "$SPACE" -ge 70 ]
  then echo "Warning space is running low! "$SPACE"% used" | mail -s "Space for Backup" $MAIL
elif    [ "$SPACE" -ge 90 ]
  then echo "Critical Warning! You better do something now "$SPACE"% used " | mail -s "Space for Backup" $MAIL
exit
fi

#använder listan i PC variabeln och gör en backup på hemkatalogen via ssh
for i in "${PC[@]}"; do
        ssh $i 'tar cvpzf "backup$LOGNAME`date +"%m_%d_%Y"`.tgz" /home'
        ssh $i 'rsync -avz --remove-source-files /home/$LOGNAME/backup$LOGNAME`date +"%m_%d_%Y"`.tgz abra@192.168.0.202:/backups/pc'
done

#Tar bort gamla backuper
find $BAKDIR -atime +28 -name 'backup*.tgz' -exec rm {} \;
find $PCBAKDIR -atime +28 -name 'backup*.tgz' -exec rm {} \;
#loggar allting till en separat loggfil för att enklare kunna se vad som har hänt under backupen.
} | tee -a $LOG
exit
