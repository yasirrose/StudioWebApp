<cfcomponent name="coreStatuses" output="false">

    <cffunction access="public" name="getStatuses" returntype="array">
        <cfquery returntype="array" name="qGetStatuses" datasource="#request.datasources#">
            SELECT 
                status_id, status_name
            FROM 
                task_statuses
        </cfquery>

        <cfreturn qGetStatuses>
    </cffunction>

</cfcomponent>
