<cfcomponent name="coreTasks" output="false">

    <cffunction access="public" name="getTasks" returntype="array">
        <cfargument name="clientId" type="any" required="false" default="">

        <cftry>
            <!-- SQL query that joins the projects table to get project name information -->
            <cfquery returntype="array" name="qGetTasks" datasource="#request.datasources#">
                SELECT
                    tasks.*,
                    projects.project_name,
                    CONCAT(COALESCE(users.first_name, ''), ' ', COALESCE(users.last_name, '')) AS assigned_user_name,
                    task_statuses.status_name AS task_status
                FROM
                    tasks
                LEFT JOIN projects ON tasks.project_id = projects.project_id
                LEFT JOIN users ON tasks.assigned_to = users.user_id
                LEFT JOIN task_statuses ON tasks.status_id = task_statuses.status_id
                WHERE 0=0
                <cfif len(arguments.clientId) GT 0>
                    AND projects.client_id = <cfqueryparam value="#arguments.clientId#" cfsqltype="cf_sql_integer">
                </cfif>
                ORDER BY tasks.updated_at DESC
            </cfquery>

            <cfcatch>
                <cflog text="Error getting projects data: #cfcatch.message#" type="error">
            </cfcatch>
        </cftry>

        <cfreturn qGetTasks>
    </cffunction>

    <cffunction name="updateTaskData" access="public" returntype="any" output="false">
        <cfargument name="task_id" type="numeric" required="false" default="0" hint="Task ID">
        <cfargument name="project_id" type="numeric" required="false" default="0" hint="Project ID">
        <cfargument name="status_id" type="numeric" required="false" default="1" hint="Task Status ID">
        <cfargument name="task_name" type="string" required="true" hint="Task Name">
        <cfargument name="assigned_to" type="numeric" required="true" hint="Task Name">
        <cfargument name="description" type="string" required="true" hint="Task Description">
        
        <cfargument name="task_start_date" type="string" required="false" default="" hint="Task Start Date">
        <cfargument name="task_end_date" type="string" required="false" default="" hint="Task End Date">
        <cfargument name="task_start_time" type="string" required="false" default="" hint="Task Start Time">
        <cfargument name="task_end_time" type="string" required="false" default="" hint="Task End Time">
        <cfargument name="is_all_day" type="boolean" required="false" default="false" hint="Is All Day Event">


        <cfset var response = {}>
    
        <cftry>
            <!-- Update project information in the database -->
            <cfquery name="updateTask" datasource="#request.datasources#">
                UPDATE tasks
                SET 
                    project_id = <cfqueryparam value="#arguments.project_id#" cfsqltype="CF_SQL_INTEGER">,
                    status_id = <cfqueryparam value="#arguments.status_id#" cfsqltype="CF_SQL_INTEGER">,
                    task_name = <cfqueryparam value="#arguments.task_name#" cfsqltype="CF_SQL_VARCHAR">,
                    assigned_to = <cfqueryparam value="#arguments.assigned_to#" cfsqltype="CF_SQL_INTEGER">,
                    description = <cfqueryparam value="#arguments.description#" cfsqltype="CF_SQL_VARCHAR">,
                    task_start_date = <cfqueryparam value="#arguments.task_start_date#" cfsqltype="CF_SQL_DATE">,
                    task_end_date = <cfqueryparam value="#arguments.task_end_date#" cfsqltype="CF_SQL_DATE">,
                    task_start_time = <cfqueryparam value="#arguments.task_start_time#" cfsqltype="CF_SQL_TIME">,
                    task_end_time = <cfqueryparam value="#arguments.task_end_time#" cfsqltype="CF_SQL_TIME">,
                    is_all_day = <cfqueryparam value="#arguments.is_all_day#" cfsqltype="CF_SQL_BIT">
                WHERE task_id = <cfqueryparam value="#arguments.task_id#" cfsqltype="CF_SQL_INTEGER">
            </cfquery>
    
            <cfset response.statusCode = 201>
            <cfset response.data = { "message" = "Task Updated successfully" }>
        <cfcatch type="any">
            <cfset response.statusCode = 500>
            <cfset response.data = { "message" = "Error updating task", "errorDetail" = cfcatch.message }>
        </cfcatch>
        </cftry>
    
        <cfreturn response>
    </cffunction>

    <cffunction name="addNewTask" access="public" returntype="struct" output="false">
        <cfargument name="project_id" type="numeric" required="true" default="0" hint="Project ID">
        <cfargument name="status_id" type="numeric" required="true" default="1" hint="Task Status ID">
        <cfargument name="task_name" type="string" required="true" hint="Task Name">
        <cfargument name="assigned_to" type="numeric" required="false" hint="Assignee Name">
        <cfargument name="description" type="string" required="false" hint="Task Description">
        
        <cfargument name="task_start_date" type="string" required="false" default="" hint="Task Start Date">
        <cfargument name="task_end_date" type="string" required="false" default="" hint="Task End Date">
        <cfargument name="task_start_time" type="string" required="false" default="" hint="Task Start Time">
        <cfargument name="task_end_time" type="string" required="false" default="" hint="Task End Time">
        <cfargument name="is_all_day" type="boolean" required="false" default="false" hint="Is All Day Event">
    
        <cfset var response = {}>

        <!-- Save the task -->
        <cfset var addTaskSuccess = saveTask(
            project_id= arguments.project_id,
            status_id= arguments.status_id,
            task_name= arguments.task_name,
            assigned_to= arguments.assigned_to,
            description= arguments.description,
            task_start_date= arguments.task_start_date,
            task_end_date= arguments.task_end_date,
            task_start_time= arguments.task_start_time,
            task_end_time= arguments.task_end_time,
            is_all_day= arguments.is_all_day
        )>

        <cfif addTaskSuccess>
            <cfset response.statusCode = 201>
            <cfset response.data = { "message" = "Task created successfully" }>
        <cfelse>
            <cfset response.statusCode = 500>
            <cfset response.data = { "message" = "Error creating task" }>
        </cfif>
        
        <cfreturn response>
    </cffunction>

    <cffunction name="saveTask" access="public" returntype="boolean" output="false">
        <cfargument name="project_id" type="numeric" required="false" default="0" hint="Project ID">
        <cfargument name="task_name" type="string" required="true" hint="Task Name">
        <cfargument name="assigned_to" type="numeric" required="true" hint="Assignee Name">
        <cfargument name="description" type="string" required="true" hint="Task Description">

        <cfargument name="task_start_date" type="string" required="false" default="" hint="Task Start Date">
        <cfargument name="task_end_date" type="string" required="false" default="" hint="Task End Date">
        <cfargument name="task_start_time" type="string" required="false" default="" hint="Task Start Time">
        <cfargument name="task_end_time" type="string" required="false" default="" hint="Task End Time">
        <cfargument name="is_all_day" type="boolean" required="false" default="false" hint="Is All Day Event">


        <cfset var success = false>

        <cftry>
            <cfquery datasource="#request.datasources#">
                INSERT INTO tasks (
                    project_id,
                    task_name,
                    assigned_to,
                    description,
                    task_start_date,
                    task_end_date,
                    task_start_time,
                    task_end_time,
                    is_all_day
                )
                VALUES (
                    <cfqueryparam value="#arguments.project_id#" cfsqltype="CF_SQL_INTEGER">,
                    <cfqueryparam value="#arguments.task_name#" cfsqltype="CF_SQL_VARCHAR">,
                    <cfqueryparam value="#arguments.assigned_to#" cfsqltype="CF_SQL_INTEGER">,
                    <cfqueryparam value="#arguments.description#" cfsqltype="CF_SQL_VARCHAR">,
                    <cfqueryparam value="#arguments.task_start_date#" cfsqltype="CF_SQL_DATE">,
                    <cfqueryparam value="#arguments.task_end_date#" cfsqltype="CF_SQL_DATE">,
                    <cfqueryparam value="#arguments.task_start_time#" cfsqltype="CF_SQL_TIME">,
                    <cfqueryparam value="#arguments.task_end_time#" cfsqltype="CF_SQL_TIME">,
                    <cfqueryparam value="#arguments.is_all_day#" cfsqltype="CF_SQL_BIT">
                )
            </cfquery>
            <cfset success = true>
            
            <cfcatch>
                <cfset success = false>
            </cfcatch>
        </cftry>
        
        <cfreturn success>
    </cffunction>

</cfcomponent>