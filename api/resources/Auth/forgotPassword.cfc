<cfcomponent extends="taffy.core.resource" taffy_uri="/auth/forgotPassword"  taffy:docs:name="auth.forgotPassword">
    <cffunction name="funForgetPassword" taffy:verb="get" access="public" output="true" hint="">
            <cfargument name="email" type="string" required="true">
            
            <cfset core_auth = createObject("component","core.auth")>

            <cftry>
                <cfset forgot_result = core_auth.funAuthForgetPassword(arguments.email)>

                <cfset result_status = 200>

                <cfreturn rep(forgot_result).withStatus(result_status)>

                <cfcatch>
                    <cfreturn rep(cfcatch.message).withStatus(401)>
                </cfcatch>
            </cftry>
    </cffunction>

</cfcomponent>
