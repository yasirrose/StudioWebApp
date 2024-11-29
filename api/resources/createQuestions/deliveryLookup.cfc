<cfcomponent extends="taffy.core.resource" taffy_uri="/createQuestions/deliveryLookup" taffy:docs:name="createQuestions.deliveryLookup">

	<cffunction name="deliveryLookup" taffy:verb="get" access="public" output="true" hint="">
		<cfargument name="workflowTypeCode" type="string" required="true" hint="" />
		<cfset jwtObj = createObject("component", "core.jwt")>
		<cfset jwtData = jwtObj.validateJwt()>


		<cfif not isDefined("jwtData.sessions.userid") or jwtData.sessions.userid eq ''>
			<cfreturn noData().withStatus(401)>
		</cfif>
		<cfset var result = structNew() />
		<cfquery datasource="#request.datasources#" name="qry_totalRecords">
			SELECT COUNT(*) AS totalRecords
			FROM roles
		</cfquery>

		<cfdump  var="#qry_totalRecords#" abort="true">


		<!--- contents will be here --->

		<cfreturn representationOf(result).withStatus(200) />
	</cffunction>

</cfcomponent>