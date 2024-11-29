<cfcomponent displayname="Action Permissions Service">

    <!--- Fetch All Action Permissions --->
    <cffunction name="getAllActionPermissions" access="public" returntype="array" hint="Fetch All Action Permissions with Action and Role Names">

        <cfquery name="actionPermissionsQuery" datasource="#request.datasources#">
            SELECT 
                ap.action_id,
                a.action_name,
                ap.role_id,
                r.role_name,
                ap.has_access,
                m.menu_id,
                m.menu_name
            FROM 
                action_permissions ap
            INNER JOIN 
                actions a ON ap.action_id = a.action_id
            INNER JOIN 
                roles r ON ap.role_id = r.role_id
            INNER JOIN 
                menus m ON m.menu_id = a.menu_id
        </cfquery>

        <cfset structuredData = [] />

        <cfloop query="actionPermissionsQuery">
            <!--- Check if the action is already in the structuredData array --->
            <cfset existingAction = ArrayFind(structuredData, function(item) {
                return item.action_id == actionPermissionsQuery.action_id;
            })>

            <!--- If the action exists, add the role's permissions to it --->
            <cfif existingAction>
                <cfset ArrayAppend(
                    structuredData[existingAction].roles,
                    {
                        role_id: actionPermissionsQuery.role_id,
                        role_name: actionPermissionsQuery.role_name,
                        has_access: actionPermissionsQuery.has_access
                    }
                )>
            <cfelse>
                <!--- If the menu doesn't exist, add a new menu with its roles --->
                <cfset ArrayAppend(
                    structuredData,
                    {
                        action_id: actionPermissionsQuery.action_id,
                        action_name: actionPermissionsQuery.action_name,
                        menu_id: actionPermissionsQuery.menu_id,
                        menu_name: actionPermissionsQuery.menu_name,
                        roles: [
                            {
                                role_id: actionPermissionsQuery.role_id,
                                role_name: actionPermissionsQuery.role_name,
                                has_access: actionPermissionsQuery.has_access
                            }
                        ]
                    }
                )>
            </cfif>
        </cfloop>

        <!--- Return the structured action data as an array --->
        <cfreturn structuredData>
    </cffunction>

    <!--- Update Action Permission for a Role --->
    <cffunction name="updateActionPermission" access="public" returntype="struct" hint="Update Action Permission for Role">
        <cfargument name="role_id" type="numeric" required="true">
        <cfargument name="action_id" type="numeric" required="true">
        <cfargument name="has_access" type="boolean" required="true">
        
        <cfset var response = {}>

        <cftry>
            <cfquery name="updateActionPermissionQuery" datasource="#request.datasources#">
                UPDATE action_permissions
                SET has_access = <cfqueryparam value="#arguments.has_access#" cfsqltype="cf_sql_boolean">,
                    updated_at = NOW()
                WHERE role_id = <cfqueryparam value="#arguments.role_id#" cfsqltype="cf_sql_integer">
                AND action_id = <cfqueryparam value="#arguments.action_id#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfset response.statusCode = 201>
            <cfset response.data = { "message" = "Action Permission Updated successfully" }>
        <cfcatch type="any">
            <cfset response.statusCode = 500>
            <cfset response.data = { "message" = "Error updating Action Permission", "errorDetail" = cfcatch.message }>
        </cfcatch>
        </cftry>

        <cfreturn response>
    </cffunction>

</cfcomponent>
