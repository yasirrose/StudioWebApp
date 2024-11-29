<cfcomponent extends="taffy.core.resource" taffy_uri="/users" taffy:docs:name="user.all">

    <cffunction name="users" taffy:verb="get" access="public" output="false" hint="">
        <!-- Make userID optional by setting required="false" and defaulting to an empty string -->
        <cfargument name="userID" type="any" required="false" default="" />

        <!--- <cfset jwtObj = createObject("component", "core.jwt")>
		<cfset jwtData = jwtObj.validateJwt()>


		<cfif not isDefined("jwtData.sessions.userid") or jwtData.sessions.userid eq ''>
			<cfreturn noData().withStatus(401)>
		</cfif> --->

        <cfset core_user = createObject("component","core.users")>
        
        <!-- Get users based on whether userID is provided or not -->
        <cfset userData = core_user.getUsersData(arguments.userID)>

        <cfreturn rep(userData).withStatus(200) />
    </cffunction>

    <cffunction name="deleteUser" taffy:verb="delete" access="public" output="false" hint="Delete a user">
        <cfargument name="id" type="numeric" required="true" />

        <cfset core_user = createObject("component", "core.users")>
        <cfset result = core_user.deleteUser(arguments.id)>
        
        <cfreturn rep(result).withStatus(200) />
    </cffunction>

    <cffunction name="activateDeactivateUser" taffy:verb="put" access="public" output="false" hint="Activate a user">
        <cfargument name="user_id" type="numeric" required="true" />
        <cfargument name="active" type="numeric" required="true" />

        <cfset core_user = createObject("component", "core.users")>
        <cfset result = core_user.activateDeactivateUser(arguments.user_id, arguments.active)>
        
        <cfif result>
            <cfreturn rep({ message = "User activated successfully." }).withStatus(200) />
        <cfelse>
            <cfreturn noData().withStatus(404, "User not found or could not be activated.") />
        </cfif>
    </cffunction>

    <cffunction name="addUser" taffy:verb="post" access="public" output="false" hint="Add a new user">
        <cfargument name="first_name" type="any" required="false" default="" hint="" />
		<cfargument name="last_name" type="any" required="false" default="" hint="" />
        <cfargument name="phone" type="any" required="false" default="" hint="" />
        <cfargument name="email" type="any" required="false" default="" hint="" /> 
		<cfargument name="company" type="any" required="false" default="" hint="" />


        <cfset core_user = createObject("component", "core.users")>
        <cfset result = core_user.addUser(arguments)>
        
        <cfreturn rep(result).withStatus(200) />
    </cffunction>

</cfcomponent>
