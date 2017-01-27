# zbximg
Script for inserting images in batch to Zabbix 3.0.
When inserting, the script adds a UID to the end of the name of each image, to simplify the batch removal.

Usage: zbximg [OPTION]
                
Required Arguments:
-u              Zabbix user name.
-p              Zabbix user password.
-s              Hostname or FQDN of the Zabbix frontend server.

Arguments for Insertion:
-i [Folder]     Folder with the images to be inserted. Default PWD.
-e              Extension of images. Default PNG.

Arguments for Removal:
-r [name]       Part of the name of the images to be removed or UID
-Y              Remove without confirmation
