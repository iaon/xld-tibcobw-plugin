<#--

    THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
    FOR A PARTICULAR PURPOSE. THIS CODE AND INFORMATION ARE NOT SUPPORTED BY XEBIALABS.

-->

set -x

<#assign container=targetDeployed.container />
<#assign traHome="${container.tibcoHome}/tra/${container.version}"/>

<#-- ${traHome}/bin/AppManage --propFile ${traHome}/bin/AppManage.tra -export -ear ${deployed.file.name}  -out /tmp/${targetDeployed.applicationName}.xml -->
${traHome}/bin/AppManage --propFile ${traHome}/bin/AppManage.tra -export -app ${targetDeployed.applicationName} -out /tmp/${targetDeployed.applicationName}.xml -user ${container.username} -pw ${container.password} -domain ${container.domainPath}

TMPFILE=$(mktemp)

cat > $TMPFILE << EOF
<bindings>
    <binding name="Process Archive">
        <machine>${container.host.address}</machine>
        <product>
            <type>BW</type>
            <version>5.11</version>
            <location>/opt/tibco/bw/5.11</location>
        </product>
        <setting>
            <startOnBoot>false</startOnBoot>
            <enableVerbose>false</enableVerbose>
            <maxLogFileSize>20000</maxLogFileSize>
            <maxLogFileCount>5</maxLogFileCount>
            <threadCount>8</threadCount>
            <java>
                <initHeapSize>32</initHeapSize>
                <maxHeapSize>256</maxHeapSize>
                <threadStackSize>256</threadStackSize>
            </java>
        </setting>
        <shutdown>
            <checkpoint>false</checkpoint>
            <timeout>0</timeout>
        </shutdown>
    </binding>
</bindings>

EOF

xmlstarlet ed -L  --subnode "/_:application/_:services/_:bw" --type elem -n xi_include \
	-i //xi_include --type attr -n xmlns:xi -v http://www.w3.org/2003/XInclude     \
	-i //xi_include --type attr -n href -v $TMPFILE -r //xi_include -v xi:include /tmp/${targetDeployed.applicationName}.xml

xmllint --xinclude /tmp/${targetDeployed.applicationName}.xml --output /tmp/${targetDeployed.applicationName}.xml

<#list deployed.placeholders?keys as key>
echo "Processing ${key} with value  ${deployed.placeholders[key]}"

echo "Check if the value exists"
xmlstarlet sel -t -v '/_:application/_:NVPairs/_:*/_:name="${key}"' /tmp/${targetDeployed.applicationName}.xml
XMLSTARLET_EXIT_CODE=$?
if [ $XMLSTARLET_EXIT_CODE -ne 0 ]; then
  echo "[ERROR]${key} not found 
  exit 2
fi

echo "Get the packaged value for ${key}"
xmlstarlet sel -t -v '/_:application/_:NVPairs/*[_:name="${key}"]/_:value' /tmp/${targetDeployed.applicationName}.xml
XMLSTARLET_EXIT_CODE=$?
if [ $XMLSTARLET_EXIT_CODE -ne 0 ]; then
  echo "[ERROR] Cannot get the packaged value for ${key}"
  exit 3
fi

echo "Change the value"
xmlstarlet edit -L -u '/_:application/_:NVPairs/*[_:name="${key}"]/_:value' -v '${deployed.placeholders[key]}' /tmp/${targetDeployed.applicationName}.xml
XMLSTARLET_EXIT_CODE=$?
if [ $XMLSTARLET_EXIT_CODE -ne 0 ]; then
  echo "[ERROR] Cannot change the packaged value for ${key} -> ${deployed.placeholders[key]}'"
  exit 4
fi

</#list>

${traHome}/bin/AppManage --propFile ${traHome}/bin/AppManage.tra -${command} -deployConfig /tmp/${targetDeployed.applicationName}.xml -app ${targetDeployed.applicationName} -user ${container.username} -pw ${container.password} -domain ${container.domainPath}

