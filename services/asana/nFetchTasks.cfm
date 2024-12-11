<cfquery name="getProjects" datasource="ipstudio"> 
    SELECT project_id, project_gid, asana_api_client_secret
    FROM projects
    WHERE asana_api_client_secret IS NOT NULL
        AND project_gid IS NOT NULL
</cfquery>

<cfdump var="#getProjects#">

<cfif getProjects.recordCount GT 0>
    <cfloop query="getProjects">
        <cfset accessToken = getProjects.asana_api_client_secret />
        <cfset projectGid = getProjects.project_gid />
        <cfset projectId = getProjects.project_id />
        <cfset baseUrl = "https://app.asana.com/api/1.0" />

        <cftry>
            <!-- Fetch Tasks for Project -->
            <cfhttp method="get" url="#baseUrl#/projects/#projectGid#/tasks" result="taskResponse">
                <cfhttpparam type="header" name="Authorization" value="Bearer #accessToken#" />
            </cfhttp>

            <cfif taskResponse.status_code EQ 200>
                <cfset tasks = deserializeJson(taskResponse.FileContent).data />

                <cfloop array="#tasks#" index="task">
                    <cfset task_gid = task.gid />
                    <cfset task_name = task.name />

                    <!-- Fetch Task Details -->
                    <cftry>
                        <cfhttp method="get" url="#baseUrl#/tasks/#task_gid#" result="taskDetailResponse">
                            <cfhttpparam type="header" name="Authorization" value="Bearer #accessToken#" />
                        </cfhttp>

                        <cfif taskDetailResponse.status_code EQ 200>
                            <cfset taskDetails = deserializeJson(taskDetailResponse.FileContent).data />
                            <cfset assignee = structKeyExists(taskDetails, "assignee") ? taskDetails.assignee : "" />

                            <!--- Fetch Assignee Details --->
                            <cfif NOT isNull(assignee) AND isStruct(assignee)>
                                <cfset assignee_gid = assignee.gid />
                                <cfset assignee_name = assignee.name />

                                <cftry>
                                    <cfhttp method="get" url="#baseUrl#/users/#assignee_gid#" result="userDetailResponse">
                                        <cfhttpparam type="header" name="Authorization" value="Bearer #accessToken#" />
                                    </cfhttp>

                                    <cfif userDetailResponse.status_code EQ 200>
                                        <cfset userDetails = deserializeJson(userDetailResponse.FileContent).data />
                                        <cfset assignee_email = structKeyExists(userDetails, "email") ? userDetails.email : "" />

                                        <!--- Insert or Update Assignee in Users Table
                                        <cfquery name="saveUser" datasource="ipstudio">
                                            INSERT INTO users (user_gid, name, email)
                                            VALUES (
                                                <cfqueryparam value="#assignee_gid#" cfsqltype="cf_sql_varchar">,
                                                <cfqueryparam value="#assignee_name#" cfsqltype="cf_sql_varchar">,
                                                <cfqueryparam value="#assignee_email#" cfsqltype="cf_sql_varchar">
                                            )
                                            ON DUPLICATE KEY UPDATE 
                                                name = <cfqueryparam value="#assignee_name#" cfsqltype="cf_sql_varchar">,
                                                email = <cfqueryparam value="#assignee_email#" cfsqltype="cf_sql_varchar">
                                        </cfquery> --->
                                    <cfelse>
                                        <cfoutput>Failed to fetch details for user #assignee_gid#: #userDetailResponse.status_code#</cfoutput>
                                    </cfif>
                                <cfcatch>
                                    <cfoutput>Error fetching details for user #assignee_gid#: #cfcatch.message#</cfoutput>
                                </cfcatch>
                                </cftry>
                            </cfif>
                        <cfelse>
                            <cfoutput>Failed to fetch task details for #task_gid#: #taskDetailResponse.status_code#</cfoutput>
                        </cfif>
                    <cfcatch>
                        <cfoutput>Error fetching task details for #task_gid#: #cfcatch.message#</cfoutput>
                    </cfcatch>
                    </cftry>

                    <!-- Insert or Update Task Data -->
                    <cfquery name="saveTask" datasource="ipstudio">
                        INSERT INTO tasks (task_name, project_id, task_gid)
                        VALUES (
                            <cfqueryparam value="#task_name#" cfsqltype="cf_sql_varchar">,
                            <cfqueryparam value="#projectId#" cfsqltype="cf_sql_numeric">,
                            <cfqueryparam value="#task_gid#" cfsqltype="cf_sql_varchar">,
                        )
                        ON DUPLICATE KEY UPDATE 
                            task_name = <cfqueryparam value="#task_name#" cfsqltype="cf_sql_varchar">,
                            project_id = <cfqueryparam value="#projectId#" cfsqltype="cf_sql_numeric">
                    </cfquery>
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
