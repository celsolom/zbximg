# zbximg
Tool to insert and remove images from Zabbix 3.0

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
