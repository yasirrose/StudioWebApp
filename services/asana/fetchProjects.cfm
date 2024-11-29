<cfset accessToken = "2/1204193702138666/1208762713128264:90575a6c0212c2b450bd2a4161be266a" />
<cfset baseUrl = "https://app.asana.com/api/1.0" />

<!--- Fetch Projects with Authorization Header --->
<cfhttp method="get" url="#baseUrl#/projects" result="projectResponse">
    <cfhttpparam type="header" name="Authorization" value="Bearer #accessToken#" />
</cfhttp>

<cfdump  var="#projectResponse.status_code#">
<!--- Check for successful response --->
<cfif projectResponse.status_code EQ 200>
    <cfset projects = deserializeJson(projectResponse.FileContent).data />

    <!--- Loop through each project and insert/update into the database --->
    <cfloop array="#projects#" index="project">
        <cfset project_gid = project.gid />
        <cfset project_name = project.name />
        
        <!--- Output project info for debugging --->
        <cfoutput>
            <p>PROJECT NAME: #project_name#</p>
            <p>GLOBAL ID: #project_gid#</p>
        </cfoutput>

        <!--- Insert or update project data in the database --->
        <cfquery name="saveProject" datasource="ipstudio">
            INSERT INTO projects (asana_project_name, project_gid)
            VALUES (
                <cfqueryparam value="#project_name#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#project_gid#" cfsqltype="cf_sql_numeric">
            )
            ON DUPLICATE KEY UPDATE asana_project_name = 
                <cfqueryparam value="#project_name#" cfsqltype="cf_sql_varchar">
        </cfquery>
    </cfloop>
<cfelse>
    <cfoutput>Failed to fetch projects: #projectResponse.StatusCode#</cfoutput>
</cfif>
