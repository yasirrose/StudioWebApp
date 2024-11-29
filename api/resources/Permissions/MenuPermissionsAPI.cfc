<cfcomponent extends="taffy.core.resource" taffy_uri="/menuPermissions" taffy:docs:name="Menu Permissions">

    <cffunction name="fetchAllMenuPermissions" taffy:verb="get" access="public" output="true" hint="Fetch All Menu Permissions">
        <cfset var permissionService = createObject("component", "core.menuPermissions")>
        <cfset var permissionsData = []>
    
        <!-- Fetch all menu permissions -->
        <cfset permissionsData = permissionService.getAllMenuPermissions()>
        
        <cfreturn rep(permissionsData).withStatus(200)>
    </cffunction>
    

    <cffunction name="updateMenuPermissions" taffy:verb="put" access="public" output="true" hint="Update Menu Permissions">
        <cfargument name="menu_id" type="numeric" required="true">
        <cfargument name="role_id" type="numeric" required="true">
        <cfargument name="has_access" type="boolean" required="true">
        <cflog text="<--core---permissions--menu_id-> #arguments.menu_id#" type="info">
        <cflog text="<--core---permissions-role_id--> #arguments.role_id#" type="info">
        <cflog text="<--core---permissions-has_access--> #arguments.has_access#" type="info">

        <cfset var permissionService = createObject("component", "core.menuPermissions")>
        <cfset var response = {}>

        <cfset response = permissionService.updateMenuPermission(
            menu_id=arguments.menu_id,
            role_id=arguments.role_id,
            has_access=arguments.has_access
        )>

        <cfreturn rep(response).withStatus(200)>
    </cffunction>

</cfcomponent>
