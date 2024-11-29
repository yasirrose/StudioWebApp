<cfcomponent extends="taffy.core.resource" taffy_uri="/tasks" taffy:docs:name="tasks">

	<cffunction name="fetchTasks" taffy:verb="get" access="public" output="true" hint="">
		<cfargument name="clientId" type="any" required="false" default="">

        <!--- <cfset jwtObj = createObject("component", "core.jwt")>
		<cfset jwtData = jwtObj.validateJwt()> 
		<cfif not isDefined("jwtData.sessions.userid") or jwtData.sessions.userid eq ''>
			<cfreturn noData().withStatus(401)>
		</cfif> --->

        <cfset taskService = createObject("component","core.tasks")>
		
        <cfif len(arguments.clientId) GT 0>
            <Cfset tasksData = taskService.getTasks(arguments.clientId)>
        <cfelse>
            <Cfset tasksData = taskService.getTasks()>
        </cfif>
		

		<cfreturn rep(tasksData).withStatus(200) />
	</cffunction> 
    
    <cffunction name="addUpdateTask" taffy:verb="put" access="public" output="true" hint="Add/Update a project">
        <cfargument name="task_id" type="numeric" required="false" default="0" hint="Task ID">
        <cfargument name="status_id" type="numeric" required="false" default="1" hint="Task Status ID">
        <cfargument name="project_id" type="numeric" required="false" default="0" hint="Project ID">
        <cfargument name="task_name" type="string" required="true" hint="Task Name">
        <cfargument name="assigned_to" type="numeric" required="false" hint="Assignee Name">
        <cfargument name="description" type="string" required="true" hint="Task Description">
        
        <cfargument name="task_start_date" type="string" required="false" default="" hint="Task Start Date">
        <cfargument name="task_end_date" type="string" required="false" default="" hint="Task End Date">
        <cfargument name="task_start_time" type="string" required="false" default="" hint="Task Start Time">
        <cfargument name="task_end_time" type="string" required="false" default="" hint="Task End Time">
        <cfargument name="is_all_day" type="boolean" required="false" default="false" hint="Is All Day Event">
        
    
        <cfset var taskService = createObject("component", "core.tasks")>
        <cfset var response = {}>
        <cflog text="TAKS ID IS: #arguments.task_id#" type="error">
        
        <cfif arguments.task_id GT 0>
            <cfset response = taskService.updateTaskData(
                task_id=arguments.task_id,
                project_id=arguments.project_id,
                status_id=arguments.status_id,
                task_name=arguments.task_name,
                assigned_to=arguments.assigned_to,
                description=arguments.description,
                task_start_date=arguments.task_start_date,
                task_end_date=arguments.task_end_date,
                task_start_time=arguments.task_start_time,
                task_end_time=arguments.task_end_time,
                is_all_day=arguments.is_all_day
            )>
        
            <!-- Check if client was successfully updated -->
            <cfset response.tasks = taskService.getTasks()>
            <cfreturn rep(response)>          
        <cfelse>
            <!-- Call addNewTask to add a new Task -->
            <cfset response = taskService.addNewTask(
                task_id=arguments.task_id,
                project_id=arguments.project_id,
                status_id=arguments.status_id,
                task_name=arguments.task_name,
                assigned_to=arguments.assigned_to,
                description=arguments.description,
                task_start_date=arguments.task_start_date,
                task_end_date=arguments.task_end_date,
                task_start_time=arguments.task_start_time,
                task_end_time=arguments.task_end_time,
                is_all_day=arguments.is_all_day
            )>
        
            <!-- Check if Task was successfully created -->
            <cfif response.statusCode EQ 201>
                <cfset response.tasks = taskService.getTasks()>
                <cfreturn rep(response).withStatus(201)>
            <cfelse>
                <cfreturn rep(response.data).withStatus(response.statusCode)>
            </cfif>
        </cfif>
    </cffunction>


</cfcomponent>
