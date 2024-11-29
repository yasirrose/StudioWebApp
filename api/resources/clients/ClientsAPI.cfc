<cfcomponent extends="taffy.core.resource" taffy_uri="/clients" taffy:docs:name="clients">

	<cffunction name="clientProfile" taffy:verb="get" access="public" output="true" hint="">
		<cfargument name="client_id" type="any" required="false" hint="" />
		<!--- <cfset jwtObj = createObject("component", "core.jwt")>
		<cfset jwtData = jwtObj.validateJwt()>


		<cfif not isDefined("jwtData.sessions.userid") or jwtData.sessions.userid eq ''>
			<cfreturn noData().withStatus(401)>
		</cfif> --->

        <cfset clientService = createObject("component","core.clients")>
		
        <cfif len(arguments.client_id) GT 0>
            <Cfset clientsData = clientService.getClientsData(arguments.client_id)>
        <cfelse>
            <Cfset clientsData = clientService.getClientsData()>
        </cfif>
		

		<cfreturn rep(clientsData).withStatus(200) />
	</cffunction>

	<cffunction name="addUpdateClientProfile" taffy:verb="put" access="public" output="true" hint="Adds a new client">
        <cfargument name="client_id" type="numeric" required="false" default="0" hint="Client ID">
        <cfargument name="client_main_id" type="numeric" required="true" hint="Main ID for client">
        <cfargument name="first_name" type="string" required="true" hint="First name of the client">
        <cfargument name="last_name" type="string" required="true" hint="Last name of the client">
        <cfargument name="email" type="string" required="true" default="" hint="Email of the client">
        <cfargument name="phone" type="string" required="false" default="" hint="Phone number of the client">
        <cfargument name="client_pin" type="string" required="false" default="" hint="PIN for the client">
        <cfargument name="client_default_page" type="string" required="false" default="" hint="Default page for the client">
    
        <cfset var clientService = createObject("component", "core.clients")>
        <cfset var response = {}>
        
        <cfif client_id GT 0>
            <cfset response = clientService.updateClientData(
                client_id=arguments.client_id,
                client_main_id=arguments.client_main_id,
                first_name=arguments.first_name,
                last_name=arguments.last_name,
                email=arguments.email,
                phone=arguments.phone,
                client_pin=arguments.client_pin,
                client_default_page=arguments.client_default_page
            )>
        
            <!-- Check if client was successfully updated -->
            <cfset response.clients = clientService.getClientsData()>
            <cfreturn rep(response)>          
        <cfelse>
            <!-- Call funAddNewClient to add a new client -->
            <cfset response = clientService.funAddNewClient(
                client_main_id=arguments.client_main_id,
                first_name=arguments.first_name,
                last_name=arguments.last_name,
                email=arguments.email,
                phone=arguments.phone,
                client_pin=arguments.client_pin,
                client_default_page=arguments.client_default_page
            )>
        
            <!-- Check if client was successfully created -->
            <cfif response.statusCode EQ 201>
                <cfset response.clients = clientService.getClientsData()>
                <cfreturn rep(response).withStatus(201)>
            <cfelse>
                <cfreturn rep(response.data).withStatus(response.statusCode)>
            </cfif>
        </cfif>
    </cffunction>

    <cffunction name="deleteClient" taffy:verb="delete" access="public" output="false" hint="Delete a Client">
        <cfargument name="id" type="numeric" required="true" />

        <cfset core_client = createObject("component", "core.clients")>
        <cfset result = core_client.deleteClient(arguments.id)>

        <cfreturn rep(result).withStatus(200) />
    </cffunction>

    <cffunction name="activateDeactivateClient" taffy:verb="post" access="public" output="false" hint="Activate/Deactivate Client">
        <cfargument name="client_id" type="numeric" required="true" />
        <cfargument name="active" type="numeric" required="true" />

        <cfset core_client = createObject("component", "core.clients")>
        <cfset result = core_client.activateDeactivateClient(arguments.client_id, arguments.active)>

        <cfif result>
            <cfreturn rep({ message = "Client activated successfully." }).withStatus(200) />
        <cfelse>
            <cfreturn noData().withStatus(404, "Client not found or could not be activated.") />
        </cfif>
    </cffunction>
    

</cfcomponent>
