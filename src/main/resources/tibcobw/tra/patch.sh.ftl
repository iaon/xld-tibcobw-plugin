<#--

    THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
    FOR A PARTICULAR PURPOSE. THIS CODE AND INFORMATION ARE NOT SUPPORTED BY XEBIALABS.

-->


set -e 

<#assign container=targetDeployed.container />
<#assign traHome="${container.tibcoHome}/tra/${container.version}"/>

TMPXML=$(mktemp /tmp/${targetDeployed.applicationName}-XXXXXXX.xml)

${traHome}/bin/AppManage --propFile ${traHome}/bin/AppManage.tra -serialize -export -app ${targetDeployed.applicationName} -out $TMPXML -user ${container.username} -pw ${container.password} -domain ${container.domainPath}

DEPL_NAME=$(xmlstarlet sel -t -v '/_:application/_:repoInstanceName' $TMPXML| sed 's/%%DOMAIN%%-//')

export EXT_OPTS="<#if targetDeployed.javaAgent??>-javaagent\\:${targetDeployed.javaAgent} </#if>\
<#if targetDeployed.agentPath??>-agentpath\\:${targetDeployed.agentPath} </#if>\
<#if targetDeployed.loggc>-Xloggc\\:${targetDeployed.loggcPath}/${targetDeployed.applicationName}-gc.log<#if targetDeployed.UseGCLogFileRotation> -XX\\:+UseGCLogFileRotation -XX\:GCLogFileSize\\=${targetDeployed.GCLogFileSize}M -XX\\:NumberOfGCLogFiles\\=${targetDeployed.NumberOfGCLogFiles}</#if> </#if>\
<#if targetDeployed.HeapDumpOnOutOfMemoryError>-XX\\:+HeapDumpOnOutOfMemoryError -XX\\:HeapDumpPath\\=${targetDeployed.HeapDumpPath} </#if>\
<#if targetDeployed.MaxPermSize??>-XX\\:MaxPermSize\\=${targetDeployed.MaxPermSize}M </#if>\
<#if targetDeployed.MiscExtProperties??>${targetDeployed.MiscExtProperties}</#if>"

EXT_OPTS=$(echo $EXT_OPTS | sed 's/ +$//')

echo EXT_OPTS=$EXT_OPTS