<#--

    THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
    FOR A PARTICULAR PURPOSE. THIS CODE AND INFORMATION ARE NOT SUPPORTED BY XEBIALABS.

-->

<#assign container=targetDeployed.container />
<#assign traHome="${container.tibcoHome}/tra/${container.version}"/>

<#list deployed.placeholders?keys as key>
echo "Processing ${key} with value  ${deployed.placeholders[key]}"

echo "Check if the value exists"
xmlstarlet sel -t -v '/_:application/_:NVPairs/_:*/_:name="${key}"' ${targetDeployed.file.name}
XMLSTARLET_EXIT_CODE=$?
if [ $XMLSTARLET_EXIT_CODE -ne 0 ]; then
  echo "[ERROR]${key} not found 
  exit 2
fi

echo "Get the packaged value for ${key}"
xmlstarlet sel -t -v '/_:application/_:NVPairs/*[_:name="${key}"]/_:value'  ${targetDeployed.file.name}
XMLSTARLET_EXIT_CODE=$?
if [ $XMLSTARLET_EXIT_CODE -ne 0 ]; then
  echo "[ERROR] Cannot get the packaged value for ${key}"
  exit 3
fi

echo "Change the value"
xmlstarlet edit -L -u '/_:application/_:NVPairs/*[_:name="${key}"]/_:value' -v '${deployed.placeholders[key]}' ${targetDeployed.file.name}
XMLSTARLET_EXIT_CODE=$?
if [ $XMLSTARLET_EXIT_CODE -ne 0 ]; then
  echo "[ERROR] Cannot change the packaged value for ${key} -> ${deployed.placeholders[key]}'"
  exit 4
fi

</#list>

${traHome}/bin/AppManage --propFile ${traHome}/bin/AppManage.tra -${command} -deployConfig ${targetDeployed.file} -app ${targetDeployed.applicationName} -user ${container.username} -pw ${container.password} -domain ${container.domainPath}

