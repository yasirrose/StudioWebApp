<cfcomponent extends="taffy.core.resource" taffy_uri="/auth/resetPassword"  taffy:docs:name="auth.resetPassword">
    <cffunction name="funResetPassword" taffy:verb="get" access="public" output="true" hint="">
    
            <cfargument name="token" type="string" required="true" value="#url.token#">
            
            <cfset core_auth = createObject("component","core.auth")>

            <cftry>
                <cfset reset_result = core_auth.funAuthResetPassword(arguments.token)>
                
                <cfset result_status = 200>
              

                <cfreturn rep(reset_result).withStatus(result_status)>

                <cfcatch>
                    <cfreturn rep(cfcatch.message).withStatus(401)>
                </cfcatch>
            </cftry>
    </cffunction>

</cfcomponent>

