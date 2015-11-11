#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
# FOR A PARTICULAR PURPOSE. THIS CODE AND INFORMATION ARE NOT SUPPORTED BY XEBIALABS.
#

#import itertools
#from com.xebialabs.deployit.plugin.api.deployment.specification import Operation

if (delta.operation == "CREATE") or (delta.operation == "MODIFY"):
    deployed = delta.deployed
    container = delta.deployed.container
    nodes = [ container.firstNode ]
    if container.secondNode is not None:
        nodes.append(container.secondNode)
    for node in nodes:
        context.addStep(steps.os_script(
                description = "Patch TRA file for application %s on host %s" % (deployed.applicationName , node.host),
                order=78,
                script="tra/patch",
                freemarker_context = {
                    "targetDeployed" : deployed,
                    "node" : node
                }
            ))

