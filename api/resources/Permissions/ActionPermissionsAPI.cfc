<cfcomponent extends="taffy.core.resource" taffy_uri="/actionPermissions" taffy:docs:name="Action Permissions">

    <cffunction name="fetchAllActionPermissions" taffy:verb="get" access="public" output="true" hint="Fetch All Action Permissions">
        <cfset var permissionService = createObject("component", "core.actionPermissions")>
        <cfset var permissionsData = []>
    
        <!--- Fetch all action permissions --->
        <cfset permissionsData = permissionService.getAllActionPermissions()>
        
        <cfreturn rep(permissionsData).withStatus(200)>
    </cffunction>
    
    
    <cffunction name="updateActionPermissions" taffy:verb="put" access="public" output="true" hint="Update Action Permissions">
        <cfargument name="role_id" type="numeric" required="true" hint="Role ID to update action permissions for">
        <cfargument name="action_id" type="numeric" required="true" hint="Action ID to update permissions for">
        <cfargument name="has_access" type="boolean" required="true" default="1" hint="Has Access to the action (1 for access, 0 for no access)">
        
        <cfset var permissionService = createObject("component", "core.actionPermissions")>
        <cfset var response = {}>
    
        <!--- Update the action permission for the specified role and action --->
        <cfset response = permissionService.updateActionPermission(
            role_id=arguments.role_id,
            action_id=arguments.action_id,
            has_access=arguments.has_access
        )>
    
        <cfreturn rep(response).withStatus(200)>
    </cffunction>

</cfcomponent>
