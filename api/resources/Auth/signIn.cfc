<cfcomponent extends="taffy.core.resource" taffy_uri="/auth/login" taffy:docs:name="auth.login">

    <cffunction name="login" taffy:verb="get" access="public" output="true" hint="validate credentials and initialize session">
        <cfargument name="email" type="string" required="false" hint="Email">
        <cfargument name="pincode" type="string" required="false" hint="PIN">
        <cfargument name="password" type="string" required="false" hint="Password for email-based login">

        <cfset core_auth = createObject("component", "core.auth")>

        <cftry>
            <cfif structKeyExists(arguments, "password") AND len(trim(arguments.password)) GT 0>
                <!-- Email and Password Authentication -->
                <cfset login_result = core_auth.login_name_and_password(arguments.email, arguments.password)>
            <cfelse>
                <!-- PIN Authentication -->
                <cfset login_result = core_auth.login_with_pin(arguments.pincode)>
            </cfif>

            <cfset result_status = 200>
            <cfif login_result.keyExists("httpcode")>
                <cfset result_status = login_result.httpcode>
                <cfset login_result.delete("httpcode")>
            </cfif>
            <cfreturn rep(login_result).withStatus(result_status)>

        <cfcatch type="login_invalid">
            <cfreturn rep(cfcatch.message).withStatus(401)>
        </cfcatch>
        </cftry>
    </cffunction>
</cfcomponent>
