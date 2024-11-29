<cfcomponent extends="taffy.core.resource" taffy_uri="/projects" taffy:docs:name="user.all">

    <cffunction name="projects" taffy:verb="get" access="public" output="false" hint="">
        <!-- Make clientID optional by setting required="false" and defaulting to an empty string -->
        <cfargument name="client_id" type="any" required="false" default="" />

        <!--- <cfset jwtObj = createObject("component", "core.jwt")>
		<cfset jwtData = jwtObj.validateJwt()>


		<cfif not isDefined("jwtData.sessions.userid") or jwtData.sessions.userid eq ''>
			<cfreturn noData().withStatus(401)>
		</cfif> --->

        <cfset core_project = createObject("component","core.projects")>
        
        <!-- Get projects based on whether client ID is provided or not -->
        <cfset projectsData = core_project.getProjectsData(arguments.client_id)>

        <cfreturn rep(projectsData).withStatus(200) />
    </cffunction>

    <cffunction name="deleteProject" taffy:verb="delete" access="public" output="false" hint="Delete a project">
        <cfargument name="project_id" type="numeric" required="true" />

        <cfset core_project = createObject("component", "core.projects")>
        <cfset result = core_project.deleteProject(arguments.project_id)>
        
        <cfreturn rep(result).withStatus(200) />
    </cffunction>

    <cffunction name="activateDeactivateProject" taffy:verb="patch" access="public" output="false" hint="Activate/Deactivate project">
        <cfargument name="project_id" type="numeric" required="true" />
        <cfargument name="active" type="numeric" required="true" />

        <cfset core_project = createObject("component", "core.projects")>
        <cfset result = core_project.activateDeactivateProject(arguments.project_id, arguments.active)>
        
        <cfif result>
            <cfreturn rep({ message = "Project activated successfully." }).withStatus(200) />
        <cfelse>
            <cfreturn noData().withStatus(404, "Project not found or could not be activated.") />
        </cfif>
    </cffunction>

    <cffunction name="addUser" taffy:verb="post" access="public" output="false" hint="Add a new project">
        <cfargument name="first_name" type="any" required="false" default="" hint="" />
		<cfargument name="last_name" type="any" required="false" default="" hint="" />
        <cfargument name="phone" type="any" required="false" default="" hint="" />
        <cfargument name="email" type="any" required="false" default="" hint="" /> 
		<cfargument name="company" type="any" required="false" default="" hint="" />
		<!--- <cfargument name="company_site" type="any" required="false" default="" hint="" />
		<cfargument name="country" type="any" required="false" default="" hint="" />
		<cfargument name="address" type="any" required="false" default="" hint="" />
		<cfargument name="avatar" type="any" required="false" hint="Uploaded avatar file." /> --->

        <cfset core_project = createObject("component", "core.projects")>
        <cfset result = core_project.addUser(arguments)>
        
        <cfreturn rep(result).withStatus(200) />
    </cffunction>


    <cffunction name="addUpdateProject" taffy:verb="put" access="public" output="true" hint="Add/Update a project">
        <cfargument name="project_id" type="numeric" required="false" default="0" hint="Project ID">
        <cfargument name="client_id" type="numeric" required="false" default="0" hint="Client ID">
        <cfargument name="project_name" type="string" required="true" hint="Project Name">
        <cfargument name="asana_api_client_id" type="string" required="true" hint="Client ID of the Project">
        <cfargument name="asana_api_client_secret" type="string" required="true" hint="Secret ID of the project">
        <cfargument name="asana_project_name" type="string" required="true" default="" hint="Asana project Name">
        
    
        <cfset var projectService = createObject("component", "core.projects")>
        <cfset var response = {}>
        
        <cfif project_id GT 0>
            <cfset response = projectService.updateProjectData(
                client_id=arguments.client_id,
                project_id=arguments.project_id,
                project_name=arguments.project_name,
                asana_api_client_id=arguments.asana_api_client_id,
                asana_api_client_secret=arguments.asana_api_client_secret,
                asana_project_name=arguments.asana_project_name
            )>
        
            <!-- Check if client was successfully updated -->
            <cfset response.projects = projectService.getProjectsData()>
            <cfreturn rep(response)>          
        <cfelse>
            <!-- Call addNewProject to add a new Project -->
            <cfset response = projectService.addNewProject(
                client_id=arguments.client_id,
                project_id=arguments.project_id,
                project_name=arguments.project_name,
                asana_api_client_id=arguments.asana_api_client_id,
                asana_api_client_secret=arguments.asana_api_client_secret,
                asana_project_name=arguments.asana_project_name
            )>
        
            <!-- Check if client was successfully created -->
            <cfif response.statusCode EQ 201>
                <cfset response.projects = projectService.getProjectsData()>
                <cfreturn rep(response).withStatus(201)>
            <cfelse>
                <cfreturn rep(response.data).withStatus(response.statusCode)>
            </cfif>
        </cfif>
    </cffunction>

</cfcomponent>