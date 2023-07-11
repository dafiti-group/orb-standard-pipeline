#!/bin/bash
CHECKMARX_URL="$CHECKMARX_URL"
PARAMETER_BRANCH_NAME_SANITIZED=$(echo ${CIRCLE_BRANCH} | sed 's|\/|-|g' | sed 's|_|-|g' | tr '[:upper:]' '[:lower:]')
PARAMETER_PROJECT_BRANCH_NAME="${CIRCLE_PROJECT_REPONAME}.${PARAMETER_BRANCH_NAME_SANITIZED}"
THRESHOLDS_HIGH_CHECKMARX="0"
THRESHOLDS_MEDIUM_CHECKMARX="0"
GATE=""
INCREMENTAL="true"
EXCLUDE_FOLDER=""
EXCLUDE_FILE=""

Authentication () {
	response=$(curl -s -X POST ${CHECKMARX_URL}'/cxrestapi/auth/identity/connect/token' \
            --header 'Content-Type: application/x-www-form-urlencoded' \
            --data-urlencode 'username='$1 \
            --data-urlencode 'password='$2 \
            --data-urlencode 'grant_type=password' \
            --data-urlencode 'scope=access_control_api sast_api' \
            --data-urlencode 'client_id=resource_owner_sast_client' \
            --data-urlencode 'client_secret='$3)
			token=$(echo $response | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//' | sed 's/"//')

			if [ -z "$token" ]; then
				echo "Houve erro ao obter token de autenticacao"
				echo $response
				exit 1
			fi
}

GetProjectId (){
	url=$CHECKMARX_URL'/cxrestapi/projects?projectName='$1
	response=$(curl -s --location $url --header 'Authorization: Bearer '$token)

	if [[ "$response" == "[]" ]]; then
		projeto_existe="false"
	else
		projectId=$(echo "$response" | grep -o '"id": [0-9]*' | grep -o '[0-9]*')
		
		if [ -z "$projectId" ]; then
			echo "Houve erro ao obter Id do proejto"
			echo $1
			echo "$response"
			exit 1
		fi
		
		teamId=$(echo "$response" | grep -o '"teamId": [0-9]*' | grep -o '[0-9]*')
		projeto_existe="true"
	fi
}

GetTeamId (){
	targetFullName=$1
	response=$(curl -s --location $CHECKMARX_URL'/cxrestapi/auth/Teams' --header 'accept: application/json' --header 'Authorization: Bearer '$token)

	# Percorre o array no JSON
	for item in $(echo "$response" | jq -c '.[]'); do
		fullName=$(echo "$item" | jq -r '.fullName')

		# Verifica se o fullName é igual ao targetFullName
		if [ "$fullName" = "$targetFullName" ]; then
			teamid=$(echo "$item" | jq -r '.id')
		fi
	done

	if [ -z "$teamid" ]; then
		echo "Erro: Team nao existe"
		exit 1
	fi
}

CreateProject (){
	response=$(curl -s -X POST $CHECKMARX_URL'/cxrestapi/projects' \
  --header 'Content-Type: application/json;v=1.0' \ 
  --header 'Accept: application/json' \ 
  --header 'Authorization: Bearer '$token \ 
  --data '{"name": "'$1'","owningTeam": "'$2'","isPublic": "true"}')
	erroCode="28501"

	if [[ $response == *"$erroCode"* ]]; then
		echo "Erro: Max. number of licensed projects is already utilized"
		exit 1
	else
		projectId=$(echo "$response" | grep -o '"id": [0-9]*' | grep -o '[0-9]*')
		
		if [ -z "$projectId" ]; then
			echo "Houve erro ao criar o proejto"
			echo "$response"
			exit 1
		else
			echo "Projeto criado. Id: $projectId"
		fi
	fi
}

UpdateRepository () {
	url=$CHECKMARX_URL'/cxrestapi/projects/'$1'/sourceCode/remoteSettings/git'
	response=$(curl -s -o /dev/null -w "%{http_code}" POST $url \
	--header 'Content-Type: application/json;v=1.0' \
	--header 'Accept: application/json' \
	--header 'Authorization: Bearer '$token \
	--data '{"url": "'$2'","branch": "'$3'"}')
	code="204"

	if [[ $response == *"$code"* ]]; then
		echo "Repositorio configurado"
	else
		echo "Falha na configuracao do repositorio git"
		echo "$1"
		echo "$2"
		echo "$3"
		echo $response
		exit 1
	fi
}

ExcludeSettings () {
	url=$CHECKMARX_URL'/cxrestapi/projects/'$1'/sourceCode/excludeSettings'
	response=$(curl -s -o /dev/null -w "%{http_code}" -X PUT $url \
	--header 'Content-Type: application/json;v=1.0' \
	--header 'Authorization: Bearer '$token \
	--data '{ "excludeFoldersPattern": "'$2'", "excludeFilesPattern": "'$3'" }')
	code="200"

	if [[ $response == *"$code"* ]]; then
		echo "Exclude folders and files configurado"
	else
		echo "Falha na configuracao do exclude folders and files"
		echo "$response"
	fi
}

PresetId () {
	targetPresetName=$1
	response=$(curl -s --location $CHECKMARX_URL'/cxrestapi/sast/presets' \
	--header 'Authorization: Bearer '$token)
	presetid=$(echo "$response" | jq -r --arg name "$targetPresetName" '.[] | select(.name == $name) | .id')
	
	if [ -z "$presetid" ]; then
		echo "Erro: Preset nao existe"
		exit 1
	fi
}

scanSettings () {
	url=$CHECKMARX_URL'/cxrestapi/sast/scanSettings'
	response=$(curl -s -o /dev/null -w "%{http_code}" -X POST $url \
	--header 'Content-Type: application/json;v=1.0' \
	--header 'Accept: application/json' \
	--header 'Authorization: Bearer '$token \
	--data '{ "projectId": '$1', "presetId": '$2', "engineConfigurationId": 1 }')
	code="200"
	
	if [[ $response == *"$code"* ]]; then
		echo "Scan settings definido"
	else
		echo "Falha ao definir scans settings"
		echo "$1"
		echo "$2"
		echo "$response"
	fi
}

Scan (){
	response=$(curl -s -X POST $CHECKMARX_URL'/cxrestapi/sast/scans' \
	--header 'Content-Type: application/json;v=1.0' \
	--header 'Accept: application/json' \
	--header 'Authorization: Bearer '$token \
	--data '{ "projectId": '$1',"isIncremental": '$2',"isPublic": true,"forceScan": true,"comment": "'$3'"}')
	scanid=$(echo "$response" | grep -oP '(?<="id": )\d+')
	echo "Iniciando scan de Id: "$scanid
	status="scanning"
	
	while [ "$status" != "Finished" ];
	do
		Authentication $p1 $p2 $p3
		statusUrl=$CHECKMARX_URL'/cxrestapi/sast/scansQueue/'$scanid
		response=$(curl -s --location $statusUrl --header 'Authorization: Bearer '$token)
		status=$(echo "$response" | grep -oP '(?<="value": ")[^"]+')
		sleep 10
		echo "Scan status..."$status
		
		if [ "$status" = "Canceled" ] || [ "$status" = "Failed" ]; then
			echo "O scan foi cancelado ou falhou"
			exit 1
		fi		
	done
	
	echo "Scan finalizado"
}

SecurityGate () {
  case "$3" in
    "threshold")
      echo "Security gate baseado em threshold"
      
	  if [ -z "$4" ] || [ -z "$5" ]; then
		echo "Erro: Threshold para vulnerabilidades High and medium nao foi informado. Encerrando..."
		exit 1
	  else
	    Threshold $2 $4 $5
	  fi
      ;;
    "new")
      echo "Verificando se existe novas vulnerabilidades..."
      NewVulnerabilities $1
      ;;
    *)
      echo "Security Gate nao configurado"
      exit 0
      ;;
  esac
}

NewVulnerabilities () {
	url=$CHECKMARX_URL'/Cxwebinterface/odata/v1/Projects('$1')?%24expand=LastScan(%24expand%3DResultSummary%3B%24select%3DId%2CScanRequestedOn%2CResultSummary)'
	response=$(curl -s --location $url --header 'Authorization: Bearer '$token)

	new=$(echo "$response" | grep -oP '(?<=\"New\":)\d+')
	recurrent=$(echo "$response" | grep -oP '(?<="Recurrent":)\d+')
	resolved=$(echo "$response" | grep -oP '(?<="Resolved":)\d+')

	if [ -z "$new" ]; then
		echo "Erro ao obter resultados do scan"
		echo "$response"
		exit 1
	fi	

	if [ $new > 0 ]; then
	  echo "Scan não aprovado por violar as politicas de segurança"
	  echo "Existem "$new" vulnerabilidades novas"
	  echo " "
	  echo "Resultados do scan: "
	  echo "New : "$new
	  echo "Recurrent : "$recurrent
	  echo "Resolved : "$resolved
	  exit 1
	fi
	
	echo "Scan aprovado! Resultados do scan: "
	echo "New : "$new
	echo "Recurrent : "$recurrent
	echo "Resolved : "$resolved
	exit 0
}

Threshold () {
	url=$CHECKMARX_URL'/cxrestapi/sast/scans/'$1'/resultsStatistics' \
	response=$(curl -s --location $url --header 'Authorization: Bearer '$token)
	
	highSeverity=$(echo "$response" | grep -oP '(?<="highSeverity": )\d+')
	mediumSeverity=$(echo "$response" | grep -oP '(?<="mediumSeverity": )\d+')
	lowSeverity=$(echo "$response" | grep -oP '(?<="lowSeverity": )\d+')

	if (( highSeverity > "$2" )) || (( mediumSeverity > "$3" )); then
	  echo "Scan não aprovado por violar as politicas de segurança"
	  echo "Total de vulnerabilidades High encontradas: "$highSeverity "Threshold informado para vulnerabilidades High: "$2
	  echo "Total de vulnerabilidades Medium encontradas: "$mediumSeverity "Threshold informado para vulnerabilidades Medium: "$3
	  exit 1
	fi

	echo "Scan aprovado! Resultados do scan: "
	echo "High Severity: "$highSeverity
	echo "Medium Severity: "$mediumSeverity
	echo "Low Severity: "$lowSeverity
	exit 0
}

echo "Parametros recebidos"
echo "$CHECKMARX_USERNAME"
echo "$CHECKMARX_PASSWORD"
echo "$CHECKMARX_CLIENT_SECRET"
echo "$PARAMETER_PROJECT_BRANCH_NAME"
echo "$CHECKMARX_TEAM"
echo "$CHECKMARX_PRESET"
echo "$EXCLUDE_FOLDER"
echo "$EXCLUDE_FILE"
echo "$CIRCLE_REPOSITORY_URL"
echo "refs/heads/$CIRCLE_BRANCH"
echo "$GITHUB_TOKEN"
echo "$INCREMENTAL"
echo "$CIRCLE_BUILD_NUM"
echo "$GATE"
echo "$THRESHOLDS_HIGH_CHECKMARX"
echo "$THRESHOLDS_MEDIUM_CHECKMARX"

#main
Authentication "$CHECKMARX_USERNAME" "$CHECKMARX_PASSWORD" "$CHECKMARX_CLIENT_SECRET"
GetProjectId "$PARAMETER_PROJECT_BRANCH_NAME"

if [[ $projeto_existe == "false" ]]; then
	echo "O projeto nao existe no Checkmarx. Criando novo projeto"
	GetTeamId "$CHECKMARX_TEAM"
	CreateProject "$PARAMETER_PROJECT_BRANCH_NAME" "$teamid"
else
	echo "Projeto ja existe"
fi

UpdateRepository "$projectId" "$CIRCLE_REPOSITORY_URL" "refs/heads/$CIRCLE_BRANCH"
ExcludeSettings "$projectId" "$EXCLUDE_FOLDER" "$EXCLUDE_FILE"
PresetId "$CHECKMARX_PRESET"
scanSettings "$projectId" "$presetid"
Scan "$projectId" "$INCREMENTAL" "$CIRCLE_BUILD_NUM"
SecurityGate "$projectId" "$scanid" "$GATE" "$THRESHOLDS_HIGH_CHECKMARX" "$THRESHOLDS_MEDIUM_CHECKMARX"
