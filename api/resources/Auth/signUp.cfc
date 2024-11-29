<cfcomponent extends="taffy.core.resource" taffy_uri="/auth/signup"  taffy:docs:name="auth.signup">
    <!---Signup--->
    <cffunction name="funsignup" taffy:verb="put" access="public" output="true" hint="validate username/password and initialise session">
            <cfargument name="first_name" type="string" required="true">
            <cfargument name="last_name" type="string" required="true">
            <cfargument name="email" type="string" required="true">
            <cfargument name="password" type="string" required="true">
            
            <cfset core_auth = createObject("component","core.auth")>

            <cftry>
                <cfset signup_result = core_auth.funAddNewMember(arguments.first_name, arguments.last_name, arguments.email, arguments.password)>
                
                <cfset result_status = 200>
            
                <cfreturn rep(signup_result).withStatus(result_status)>

                <cfcatch>
                    <cfreturn rep(cfcatch.message).withStatus(401)>
                </cfcatch>
            </cftry>
    </cffunction>

</cfcomponent>

