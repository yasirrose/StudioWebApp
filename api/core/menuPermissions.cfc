<cfcomponent displayname="Menu Permissions Service">

    <!--- Fetch All Menu Permissions --->
    <cffunction name="getAllMenuPermissions" access="public" returntype="array" hint="Fetch All Menu Permissions with Menu and Role Names">

        <cfquery name="menuPermissionsQuery" datasource="#request.datasources#">
            SELECT 
                m.menu_id,
                m.menu_name,
                r.role_id,
                r.role_name,
                mp.has_access
            FROM 
                menu_permissions mp
            INNER JOIN 
                menus m ON mp.menu_id = m.menu_id
            INNER JOIN 
                roles r ON mp.role_id = r.role_id
            ORDER BY 
                m.menu_id, r.role_id
        </cfquery>
        
        <cfset structuredData = [] />
        
        <cfloop query="menuPermissionsQuery">
            <!--- Check if the menu is already in the structuredData array --->
            <cfset existingMenu = ArrayFind(structuredData, function(item) {
                return item.menu_id == menuPermissionsQuery.menu_id;
            })>
        
            <!--- If the menu exists, add the role's permissions to it --->
            <cfif existingMenu>
                <cfset ArrayAppend(
                    structuredData[existingMenu].roles,
                    {
                        role_id: menuPermissionsQuery.role_id,
                        role_name: menuPermissionsQuery.role_name,
                        has_access: menuPermissionsQuery.has_access
                    }
                )>
            <cfelse>
                <!--- If the menu doesn't exist, add a new menu with its roles --->
                <cfset ArrayAppend(
                    structuredData,
                    {
                        menu_id: menuPermissionsQuery.menu_id,
                        menu_name: menuPermissionsQuery.menu_name,
                        roles: [
                            {
                                role_id: menuPermissionsQuery.role_id,
                                role_name: menuPermissionsQuery.role_name,
                                has_access: menuPermissionsQuery.has_access
                            }
                        ]
                    }
                )>
            </cfif>
        </cfloop>
        
        <cfreturn structuredData />
    </cffunction>

    <!--- Define an API method to update menu permissions --->
    <cffunction name="updateMenuPermission" access="public" returntype="any" output="false">
        <cfargument name="menu_id" type="numeric" required="true">
        <cfargument name="role_id" type="numeric" required="true">
        <cfargument name="has_access" type="boolean" required="true">
        <cflog text="<--core---permissions--menu_id-> #arguments.menu_id#" type="info">
        <cflog text="<--core---permissions-role_id--> #arguments.role_id#" type="info">
        <cflog text="<--core---permissions-has_access--> #arguments.has_access#" type="info">
    
        <cfset var response = {}>
    
        <cftry>
            <!--- Update Menu Permission --->
            <cfquery name="qUpdateMenupermissions" datasource="#request.datasources#">
                UPDATE menu_permissions
                SET has_access = <cfqueryparam value="#arguments.has_access#" cfsqltype="cf_sql_boolean">
                WHERE role_id = <cfqueryparam value="#arguments.role_id#" cfsqltype="cf_sql_integer">
                AND menu_id = <cfqueryparam value="#arguments.menu_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            
            <cfset response.statusCode = 201>
            <cfset response.data = { "message" = "Page Permission Updated successfully" }>
        <cfcatch type="any">
            <cfset response.statusCode = 500>
            <cfset response.data = { "message" = "Error updating Page Permission", "errorDetail" = cfcatch.message }>
        </cfcatch>
        </cftry>

        <cfreturn response>
    </cffunction>
    
</cfcomponent>
