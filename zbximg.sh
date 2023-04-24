#!/bin/bash

# ZBXImg
#
# Batch image insertion on Zabbix
#
# Created by Celso Lira in 2017
#
# Need jq, base64 and curl

# --- License ---
#                    GNU GENERAL PUBLIC LICENSE
#                       Version 3, 29 June 2007
#
# Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
# Everyone is permitted to copy and distribute verbatim copies
# of this license document, but changing it is not allowed.
#

# --- Changelog ---
#2017-01-23 Version 1
#

# --- Functions  ---

function exec_curl {
	json=$1
	curl -s -H 'Content-Type:application/json' -d "$json" http://"$server"/api_jsonrpc.php
}

function zauth {
	json=" 
		{\"jsonrpc\": \"2.0\",
		\"method\":\"user.login\",
		\"params\":{
			\"user\":\"$user\",
			\"password\":\"$pass\"
			},
		\"auth\": null,\"id\":0}
	"

	auth=$(exec_curl "$json")
	id=$(echo $auth | jq -r .id)
	auth=$(echo $auth | jq -r .result)
}

function img_create {
	imagem=$1
	nome=$2
	tipo=$3
	
	# Check if image name is blank, set the name of file as name.
	if [ -z $nome ]; then
		nome=$(basename "$imagem")
		nome="${nome%.*}"
	fi
	# Check if type of image is blank, set to icon(1)
	if [ -z $tipo ]; then
		tipo=1
	fi
	
	# $(cat $imagem | base64 -w 0)
	
	nome="$nome-$uid"	

	json="
		{\"jsonrpc\": \"2.0\",
                \"method\":\"image.create\",
                \"params\": {
			\"imagetype\": $tipo,
			\"name\": \"$nome\",
			\"image\": \"$(cat $imagem | base64 -w 0)\"
			},
                \"auth\": \"$auth\",
                \"id\":$id}
	"
	exec_curl "$json"
}

function img_batch_add { \
	caminho=$1
	ext=$2
	
	# Check if path name ends with /, if not, add to it
	if [[ "$caminho" == *"/" ]]; then
		caminho="$caminho*.$ext" 	
	else
		caminho="$caminho/*.$ext" 	
	fi
	
	# Generate UID to easily remove images
	uid=$(uuidgen -t)

	# Insert images
	i=0
	for f in $caminho
	do
		img_id=$(img_create "$f" | jq -r .result.imageids[])
		echo "http://$server/adm.images.php?form=update&imageid=$img_id"
		i=$(($i+1))
	done
	
	# Display end message
	echo "$i $msg4"
}

function img_get {
	busca=$1
	json="
		{\"jsonrpc\": \"2.0\",
                \"method\":\"image.get\",
                \"params\": {
			\"output\": \"extend\",
			\"search\": {\"name\": [\"$busca\"]}
			},
                \"auth\": \"$auth\",
                \"id\":$id}
	"
#	exec_curl "$json" | jq '.result[].imageid'
	exec_curl "$json"
}

function img_batch_remove {
	uid=$1
	imageids=$(img_get "$uid")
	
	echo -e "$msg8"
	i=$(echo $imageids | jq '.result | length')
	i=$(($i-1))
	for n in $(seq 0 "$i"); do
		echo "ID:$(echo $imageids | jq .result[$n].imageid) $(echo $imageids | jq .result[$n].name)"
	done
	if [ $conf -eq 0 ]; then
		echo -n "$msg9"
		read -n 1 resp
	else
		resp="Y"
	fi

	if [ "$resp" == "Y" ] || [ "$resp" == "S" ]; then
		imageids=$(echo $imageids | jq '.result[].imageid')
		imageids=$(echo $imageids | sed 's/\" \"/\",\"/g')

		json="
			{\"jsonrpc\": \"2.0\",
			\"method\": \"image.delete\",
			\"params\": [ 
				$imageids
				],
			\"auth\": \"$auth\",
			\"id\":$id}
		"
		n=$(exec_curl "$json" | jq '.result.imageids | length')
		echo "$n $msg5"
	else
		echo -e "$msg10"
	fi
}


# --- Check LANG
if [[ $LANG == "pt_"* ]]; then
	msg1="Digite o hostname ou FQDN do servidor ZABBIX: "
	msg2="Digite o usuário: "
	msg3="Digite a senha: "
	msg4="imagem[s] inserida[s]."
	msg5="imagem[s] removida[s]."
	msg6="Erro: a opção"  
	msg7="requer um argumento."
	msg8="Lista de Imagens\n"
	msg9="Você deseja apagar estas imagens? " 
	msg10="\n\nCancelado."
	msg11="é inválida!"
	msg12="
ZBXImg 1.0 - 2017 por Celso Lira
Script para inserção de imagens em batch no Zabbix 3.0
Ao inserir, o script adiciona um UID ao fim do nome de cada imagem, para simplificar a remoção em batch.
Uso: zbximg [OPÇÂO]
	      	
Argumentos obrigatórios:
-u		Nome do usuário Zabbix.
-p		Senha do usuário Zabbix.
-s		Hostname ou FQDN do servidor frontend Zabbix.
Argumentos para Inserção:
-i [Pasta]	Pasta com as imagens a serem inseridas. Padrão PWD.
-e		Extensão das imagens. Padrão PNG.
Argumentos para Remoção:
-r [nome]	Parte do nome das imagens a serem removidas ou UID
-Y		Remover sem confirmação
"

else
	msg1="Hostname or FQDN of Zabbix Server: "
	msg2="Username: "
	msg3="Password: "
	msg4="image[s] inserted."
	msg5="image[s] removed."
	msg6="Error: option" 
	msg7="requires argument."
	msg8="Image List\n"
	msg9="Do you want to delete these images? " 
	msg10="\n\nCanceled."
	msg11="is invalid!"
	msg12="
ZBXImg 1.0 - 2017 by Celso Lira
Script for inserting images in batch to Zabbix 3.0.
When inserting, the script adds a UID to the end of the name of each image, to simplify the batch removal.
Usage: zbximg [OPTION]
                
Required Arguments:
-u 		Zabbix user name.
-p 		Zabbix user password.
-s 		Hostname or FQDN of the Zabbix frontend server.
Arguments for Insertion:
-i [Folder] 	Folder with the images to be inserted. Default PWD.
-e 		Extension of images. Default PNG.
Arguments for Removal:
-r [name] 	Part of the name of the images to be removed or UID
-Y 		Remove without confirmation
"
fi


# --- Start of execution ---
oper=""
conf=0

# --- Check options ---
while getopts "u:p:s:d:e:i:r:YhV" opt; do
	case $opt in
	u) # User
		user="$OPTARG"	
		;;
	p) # Password
		pass="$OPTARG"	
		;;
	s) # Server
		server="$OPTARG"	
		;;
	d) # Directory -- Desativada
		dir="$OPTARG"	
		;;
	e) # Extension
		ext="$OPTARG"
		;;
	i) # Insert
		oper="i"	
		dir="$OPTARG"
		;;
	r) # Remove
		oper="r"
		remo="$OPTARG"
		;;
	Y) # No Confirmation
		conf=1
		;;
	h) # Help
		echo "$msg12"
		exit 0
		;;
	V) # Version
		echo "ZBXImg 1.0 - 2017 by Celso Lira"
		exit 0
		;;
	?) # Invalid option 
		echo "$msg6 -$opt $msg7" >&2
		exit 1
		;;
	:) # Requires Argument
		echo "$msg6 -$opt $msg11" >&2
		exit 1
		;;
	esac
done

echo ZBXImg 1.0

# Prompt server hostname
if [[ -z $server ]]; then
	echo -n "$msg1"
	read server 
fi

# Prompt username
if [[ -z $user ]]; then
	echo -n "$msg2"
	read user
fi

# Prompt password
if [[ -z $pass ]]; then
	echo -n "$msg3"
	read -s pass
fi

# Define work directory
if [[ -z $dir ]]; then
	dir=$PWD
fi

# Define extension
if [[ -z $ext ]]; then
	ext="png"
fi


# Authenticate
zauth

# Operations
case $oper in
	i)
		img_batch_add $dir $ext
	;;

	r)
		img_batch_remove $remo
	;;
esac

echo -e "\n"
