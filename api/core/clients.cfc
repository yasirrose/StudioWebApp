<cfcomponent name="coreClients" output="false">

    <cffunction name="funAddNewClient" access="public" returntype="struct" output="false">
        <cfargument name="client_main_id" hint="Main ID for client" type="numeric" required="false" default="0">
        <cfargument name="first_name" hint="First name of the client" type="string" required="true">
        <cfargument name="last_name" hint="Last name of the client" type="string" required="true">
        <cfargument name="email" hint="Client email" type="string" required="true">
        <cfargument name="phone" hint="Client phone number" type="string" required="true">
        <cfargument name="client_pin" hint="PIN for client" type="string" required="true">
        <cfargument name="client_default_page" hint="Default page for client" type="string" required="false" default="">
        <cfset var response = {}>

        <!-- Check if the client already exists by email -->
        <cfset var clientExists = checkClientExistsByEmail(email)>

        <cfif clientExists>
            <cfset response.statusCode = 409>
            <cfset response.data = { "message" = "Client with this email already exists" }>
        <cfelse>
            <!-- Save the client -->
            <cfset var addClientSuccess = saveClient(
                client_main_id,
                first_name,
                last_name,
                email,
                phone,
                client_pin,
                client_default_page
            )>

            <cfif addClientSuccess>
                <cfset response.statusCode = 201>
                <cfset response.data = { "message" = "Client created successfully" }>
            <cfelse>
                <cfset response.statusCode = 500>
                <cfset response.data = { "message" = "Error creating client" }>
            </cfif>
        </cfif>
        
        <cfreturn response>
    </cffunction>

    <cffunction name="checkClientExistsByEmail" access="private" returntype="boolean" output="false">
        <cfargument name="email" required="true" type="string">
        <cfset var exists = false>

        <cftry>
            <cfquery datasource="#request.datasources#" name="qCheckClient">
                SELECT COUNT(*) AS clientCount
                FROM clients
                WHERE email = <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar">
            </cfquery>

            <cfif qCheckClient.clientCount GT 0>
                <cfset exists = true>
            </cfif>
            
            <cfcatch>
                <cflog text="Error checking if client exists: #cfcatch.message#" type="error">
            </cfcatch>
        </cftry>
        <cfreturn exists>
    </cffunction>


    <cffunction name="saveClient" access="public" returntype="boolean" output="false">
        <cfargument name="client_main_id" type="numeric" required="true">
        <cfargument name="first_name" type="string" required="true">
        <cfargument name="last_name" type="string" required="true">
        <cfargument name="email" type="string" required="true">
        <cfargument name="phone" type="string" required="true">
        <cfargument name="client_pin" type="string" required="true">
        <cfargument name="client_default_page" type="string" required="false" default="">
        
        <cfset var success = false>

        <cftry>
            <cfquery datasource="#request.datasources#">
                INSERT INTO clients (
                    client_main_id,
                    first_name,
                    last_name,
                    email,
                    phone,
                    client_pin,
                    client_default_page,
                    created_at,
                    updated_at
                )
                VALUES (
                    <cfqueryparam value="#arguments.client_main_id#" cfsqltype="CF_SQL_INTEGER">,
                    <cfqueryparam value="#arguments.first_name#" cfsqltype="CF_SQL_VARCHAR">,
                    <cfqueryparam value="#arguments.last_name#" cfsqltype="CF_SQL_VARCHAR">,
                    <cfqueryparam value="#arguments.email#" cfsqltype="CF_SQL_VARCHAR">,
                    <cfqueryparam value="#arguments.phone#" cfsqltype="CF_SQL_VARCHAR">,
                    <cfqueryparam value="#arguments.client_pin#" cfsqltype="CF_SQL_VARCHAR">,
                    <cfqueryparam value="#arguments.client_default_page#" cfsqltype="CF_SQL_VARCHAR">,
                    NOW(),
                    NOW()
                )
            </cfquery>
            <cfset success = true>
            
            <cfcatch>
                <cfset success = false>
                
            </cfcatch>
        </cftry>
        
        <cfreturn success>
    </cffunction>

    <cffunction access="public" name="getClientsData" returntype="array">
		<cfargument name="id" type="any" required="false" default="">
		<cfquery returntype="array" name="qGetClientsData" datasource="#request.datasources#">

            SELECT clients.*, CONCAT(COALESCE(users.first_name, ''), ' ', COALESCE(users.last_name, '')) AS main_contact_name
            FROM clients
			LEFT JOIN users ON clients.client_main_id = users.user_id
            WHERE client_deleted IS NULL
            <cfif len(id) GT 0>
                AND client_main_id = '#id#'
            </cfif>
            ORDER BY clients.updated_at DESC
			
		</cfquery>

		<cfreturn qGetClientsData>
	</cffunction>

    <cffunction name="updateClientData" access="public" returntype="any" output="false">
        <cfargument name="client_id" type="numeric" required="true">
        <cfargument name="client_main_id" type="numeric" required="false" default="">
        <cfargument name="first_name" type="string" required="false" default="">
        <cfargument name="last_name" type="string" required="false" default="">
        <cfargument name="email" type="string" required="false" default="">
        <cfargument name="phone" type="string" required="false" default="">
        <cfargument name="client_pin" type="string" required="false" default="">
        <cfargument name="client_default_page" type="string" required="false" default="">
        
        <cfset var response = {}>
    
        <cftry>
            <!-- Update client information in the database -->
            <cfquery name="updateClient" datasource="#request.datasources#">
                UPDATE clients
                SET 
                    client_main_id = <cfqueryparam value="#arguments.client_main_id#" cfsqltype="CF_SQL_INTEGER" null="#NOT len(arguments.client_main_id)#">,
                    first_name = <cfqueryparam value="#arguments.first_name#" cfsqltype="CF_SQL_VARCHAR" null="#NOT len(arguments.first_name)#">,
                    last_name = <cfqueryparam value="#arguments.last_name#" cfsqltype="CF_SQL_VARCHAR" null="#NOT len(arguments.last_name)#">,
                    email = <cfqueryparam value="#arguments.email#" cfsqltype="CF_SQL_VARCHAR" null="#NOT len(arguments.email)#">,
                    phone = <cfqueryparam value="#arguments.phone#" cfsqltype="CF_SQL_VARCHAR" null="#NOT len(arguments.phone)#">,
                    client_pin = <cfqueryparam value="#arguments.client_pin#" cfsqltype="CF_SQL_VARCHAR" null="#NOT len(arguments.client_pin)#">,
                    client_default_page = <cfqueryparam value="#arguments.client_default_page#" cfsqltype="CF_SQL_VARCHAR" null="#NOT len(arguments.client_default_page)#">,
                    updated_at = NOW()
                WHERE client_id = <cfqueryparam value="#arguments.client_id#" cfsqltype="CF_SQL_INTEGER">
            </cfquery>

            <cfset response.statusCode = 201>
            <cfset response.data = { "message" = "Client Updated successfully" }>
    
        <cfcatch type="any">
            <cfset response.statusCode = 500>
            <cfset response.data = { "message" = "Error updating client", "errorDetail" = cfcatch.message }>
        </cfcatch>
        </cftry>
    
        <cfreturn response>
    </cffunction>

    <cffunction name="activateDeactivateClient" access="public" returntype="boolean">
		<cfargument name="client_id" type="numeric" required="true" />
		<cfargument name="active" type="numeric" required="true" />
	
		<!-- Initialize variable to hold query result -->
		<cfset var result = false>
	
		<cftry>
			<!-- Perform the update query to activate the client -->
			<cfquery datasource="#request.datasources#">
				UPDATE clients 
				SET client_active = <cfqueryparam value="#arguments.active#" cfsqltype="cf_sql_integer">,
					updated_at = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
				WHERE client_id = <cfqueryparam value="#arguments.client_id#" cfsqltype="cf_sql_integer">
				AND client_deleted IS NULL
			</cfquery>

			<cfset result = true>

			<cfcatch>
				<cflog text="Error activating client: #cfcatch.message#" type="error">
				<cfset result = false>
			</cfcatch>
		</cftry>
	
		<cfreturn result>
	</cffunction>
	

	<cffunction access="public" name="deleteClient" returntype="any">
		<cfargument name="client_id" type="numeric" required="true" />
		
		<cftry>
			<!-- Execute the query to delete the Client -->
			<cfquery name="qDeleteClient" datasource="#request.datasources#">
				UPDATE clients 
				SET client_deleted = <cfqueryparam value="#createodbcdatetime(now())#" cfsqltype="cf_sql_timestamp"> 
				WHERE client_id = <cfqueryparam value="#arguments.client_id#" cfsqltype="cf_sql_integer">
			</cfquery>

			<cfreturn {message = "Client deleted successfully.", status = 200 } />
        <cfcatch>
            <!-- Handle any exceptions during the delete operation -->
            <cflog text="Error deleting client: #cfcatch.message#" type="error">
            <cfreturn { message = "An error occurred while deleting the client: #cfcatch.message#", status = 500 } />
        </cfcatch>
		</cftry>
	</cffunction>

</cfcomponent>