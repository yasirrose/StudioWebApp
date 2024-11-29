<cfcomponent extends="taffy.core.resource" taffy_uri="/statuses" taffy:docs:name="task.statuses">

	<cffunction name="taskStatuses" taffy:verb="get" access="public" output="true" hint="">
		<!--- <cfset jwtObj = createObject("component", "core.jwt")>
		<cfset jwtData = jwtObj.validateJwt()>


		<cfif not isDefined("jwtData.sessions.userid") or jwtData.sessions.userid eq ''>
			<cfreturn noData().withStatus(401)>
		</cfif> --->

        <cfset core_statuses = createObject("component","core.statuses")>
		
		<Cfset statusesData = core_statuses.getStatuses()>

		<cfreturn rep(statusesData).withStatus(200) />
	</cffunction>

</cfcomponent>
