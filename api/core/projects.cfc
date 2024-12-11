<cfcomponent name="coreProjects" output="false">

	<cffunction name="activateDeactivateProject" access="public" returntype="boolean">
		<cfargument name="project_id" type="numeric" required="true" />
		<cfargument name="active" type="numeric" required="true" />
	
		<!-- Initialize variable to hold query result -->
		<cfset var result = false>
	
		<cftry>
			<!-- Perform the update query to activate the project -->
			<cfquery datasource="#request.datasources#">
				UPDATE projects 
				SET project_active = <cfqueryparam value="#arguments.active#" cfsqltype="cf_sql_integer">,
					updated_at = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
				WHERE project_id = <cfqueryparam value="#arguments.project_id#" cfsqltype="cf_sql_integer">
				AND project_deleted IS NULL
			</cfquery>

			<cfset result = true>

			<cfcatch>
				<cflog text="Error activating project: #cfcatch.message#" type="error">
				<cfset result = false>
			</cfcatch>
		</cftry>
	
		<cfreturn result>
	</cffunction>
	

	<cffunction access="public" name="deleteProject" returntype="any">
		<cfargument name="project_id" type="numeric" required="true" />
		
		<cftry>
			<!-- Execute the query to delete the project -->
			<cfquery name="qDeleteProject" datasource="#request.datasources#">
				UPDATE projects 
				SET project_deleted = <cfqueryparam value="#createodbcdatetime(now())#" cfsqltype="cf_sql_timestamp"> 
				WHERE project_id = <cfqueryparam value="#arguments.project_id#" cfsqltype="cf_sql_integer">
			</cfquery>
	
			<cfreturn {message = "Project deleted successfully.", status = 200 } />
        
        <cfcatch>
            <!-- Handle any exceptions during the delete operation -->
            <cfreturn { message = "An error occurred while deleting the project: #cfcatch.message#", status = 500 } />
        </cfcatch>
		</cftry>
	</cffunction>

	<cffunction access="public" name="getProjectsData" returntype="array">
		<cfargument name="id" type="any" required="false" default="" />
		<cftry>
            <!-- SQL query that joins the roles table to get role information -->
            <cfquery returntype="array" name="qGetProjectsData" datasource="#request.datasources#">
                SELECT 
                    projects.*, 
                    clients.first_name
                FROM 
                    projects
                LEFT JOIN clients ON projects.client_id = clients.client_id
                WHERE projects.project_deleted IS NULL
                <cfif len(arguments.id)>
                    AND clients.client_main_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
                </cfif>
				ORDER BY projects.updated_at DESC
            </cfquery>
        	<cfcatch>
				<cflog text="Error getting projects data: #cfcatch.message#" type="error">
			</cfcatch>
		</cftry>

		<cfreturn qGetProjectsData>
	</cffunction>



	<cffunction name="addNewProject" access="public" returntype="struct" output="false">
		<cfargument name="project_id" type="numeric" required="false" default="0" hint="Project ID">
        <cfargument name="client_id" type="numeric" required="false" default="0" hint="Client ID">
        <cfargument name="project_name" type="string" required="true" hint="Project Name">
        <cfargument name="asana_api_client_id" type="string" required="true" hint="Client ID of the Project">
        <cfargument name="asana_api_client_secret" type="string" required="true" hint="Secret ID of the project">
        <cfargument name="asana_project_name" type="string" required="true" default="" hint="Asana project Name">
        
		<cfset var response = {}>
	
		<!-- Save the project -->
		<cfset var addProjectSuccess = saveProject(
			client_id,
			project_name,
			asana_api_client_id,
			asana_api_client_secret,
			asana_project_name
		)>

		<cfif addProjectSuccess>
			<cfset response.statusCode = 201>
			<cfset response.data = { "message" = "Project created successfully" }>
		<cfelse>
			<cfset response.statusCode = 500>
			<cfset response.data = { "message" = "Error creating project" }>
		</cfif>
        
        <cfreturn response>
    </cffunction>

    <cffunction name="saveProject" access="public" returntype="boolean" output="false">
        <cfargument name="client_id" type="numeric" required="false" default="0">
        <cfargument name="project_name" type="string" required="true">
        <cfargument name="asana_api_client_id" type="string" required="true">
        <cfargument name="asana_api_client_secret" type="string" required="true">
        <cfargument name="asana_project_name" type="string" required="true" default="">
        
        <cfset var success = false>

        <cftry>
            <cfquery datasource="#request.datasources#">
                INSERT INTO projects (
                    client_id,
                    project_name,
                    asana_project_name,
                    asana_api_client_id,
                    asana_api_client_secret
                )
                VALUES (
                    <cfqueryparam value="#arguments.client_id#" cfsqltype="CF_SQL_INTEGER">,
                    <cfqueryparam value="#arguments.project_name#" cfsqltype="CF_SQL_VARCHAR">,
                    <cfqueryparam value="#arguments.asana_project_name#" cfsqltype="CF_SQL_VARCHAR">,
                    <cfqueryparam value="#arguments.asana_api_client_id#" cfsqltype="CF_SQL_VARCHAR">,
                    <cfqueryparam value="#arguments.asana_api_client_secret#" cfsqltype="CF_SQL_VARCHAR">
                )
            </cfquery>
            <cfset success = true>
            
            <cfcatch>
                <cfset success = false>
            </cfcatch>
        </cftry>
        
        <cfreturn success>
    </cffunction>

    <cffunction name="updateProjectData" access="public" returntype="any" output="false">
        <cfargument name="project_id" type="numeric" required="true" default="0">
        <cfargument name="client_id" type="numeric" required="false" default="0">
        <cfargument name="project_name" type="string" required="true">
        <cfargument name="asana_api_client_id" type="string" required="true">
        <cfargument name="asana_api_client_secret" type="string" required="true">
        <cfargument name="asana_project_name" type="string" required="true" default="">
        
        <cfset var response = {}>
    
        <cftry>
            <!-- Update project information in the database -->
            <cfquery name="updateProject" datasource="#request.datasources#">
                UPDATE projects
                SET 
                    client_id = <cfqueryparam value="#arguments.client_id#" cfsqltype="CF_SQL_INTEGER">,
                    project_name = <cfqueryparam value="#arguments.project_name#" cfsqltype="CF_SQL_VARCHAR">,
                    asana_project_name = <cfqueryparam value="#arguments.asana_project_name#" cfsqltype="CF_SQL_VARCHAR">,
                    asana_api_client_id = <cfqueryparam value="#arguments.asana_api_client_id#" cfsqltype="CF_SQL_VARCHAR">,
                    asana_api_client_secret = <cfqueryparam value="#arguments.asana_api_client_secret#" cfsqltype="CF_SQL_VARCHAR">
                WHERE project_id = <cfqueryparam value="#arguments.project_id#" cfsqltype="CF_SQL_INTEGER">
            </cfquery>
    
			<cfset response.statusCode = 201>
            <cfset response.data = { "message" = "Project Updated successfully" }>
        <cfcatch type="any">
            <cfset response.statusCode = 500>
            <cfset response.data = { "message" = "Error updating project", "errorDetail" = cfcatch.message }>
        </cfcatch>
        </cftry>
    
        <cfreturn response>
    </cffunction>

</cfcomponent>