<!--- Fetch projects with valid asana_api_client_id, asana_api_client_secret, and project_gid --->
<cfquery name="getProjects" datasource="ipstudio">
    SELECT project_id, project_gid, asana_api_client_secret
    FROM projects
    WHERE asana_api_client_secret IS NOT NULL
        AND project_gid IS NOT NULL
</cfquery>

<cfdump  var="#getProjects#">

<cfif getProjects.recordCount GT 0>
    <!--- Loop through each project --->
    <cfloop query="getProjects">
        <!--- Set Access Token and Project GID --->
        <cfset accessToken = getProjects.asana_api_client_secret />
        <cfset projectGid = getProjects.project_gid />
        <cfset projectId = getProjects.project_id />
        <cfset baseUrl = "https://app.asana.com/api/1.0" />

        <!--- Fetch Tasks for the Project --->
        <cftry>
            <cfhttp method="get" url="#baseUrl#/projects/#projectGid#/tasks" result="taskResponse">
                <cfhttpparam type="header" name="Authorization" value="Bearer #accessToken#" />
            </cfhttp>

            <!--- Check for successful response --->
            <cfif taskResponse.status_code EQ 200>
                <cfset tasks = deserializeJson(taskResponse.FileContent).data />
                <cfdump  var="#tasks#">

                <!--- Loop through each task and insert/update into the database --->
                <cfloop array="#tasks#" index="task">
                    <cfset task_gid = task.gid />
                    <cfset task_name = task.name />
                    

                    <cfif structKeyExists(task, "assignee")>
                        <cfset assignee = task.assignee />
                        <cfdump  var="-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>">
                        <cfdump  var="#assignee.name#>">
                        <cfdump  var="-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>">
                    <cfelse>
                        <cfset assignee = "" />
                    </cfif>
                    

                    <!--- Validate task data --->
                    <cfif NOT isNull(task_gid) AND NOT isNull(task_name)>
                        <!--- Insert or update task data in the database --->
                        <cfquery name="saveTask" datasource="ipstudio">
                            INSERT INTO tasks (task_name, project_id , task_gid, project_gid)
                            VALUES (
                                <cfqueryparam value="#task_name#" cfsqltype="cf_sql_varchar">,
                                <cfqueryparam value="#project_id#" cfsqltype="cf_sql_numeric">,
                                <cfqueryparam value="#task_gid#" cfsqltype="cf_sql_numeric">,
                                <cfqueryparam value="#projectGid#" cfsqltype="cf_sql_numeric">
                            )
                            ON DUPLICATE KEY UPDATE 
                                task_name = <cfqueryparam value="#task_name#" cfsqltype="cf_sql_varchar">,
                                project_id = <cfqueryparam value="#project_id#" cfsqltype="cf_sql_numeric">
                        </cfquery>
                    </cfif>
                </cfloop>
            <cfelse>
                <cfoutput>Failed to fetch tasks for project #projectGid#: #taskResponse.status_code#</cfoutput>
            </cfif>

        <cfcatch>
            <cfoutput>Error fetching tasks for project #projectGid#: #cfcatch.message#</cfoutput>
        </cfcatch>
        </cftry>
    </cfloop>
<cfelse>
    <cfoutput>No projects found with valid credentials.</cfoutput>
</cfif>
