<cfcomponent name="coreUsers" output="false">

	<cffunction name="addUser" access="public" returntype="boolean" output="true">
		<cfargument name="formData" type="any" required="false" default="" hint="" />

        
        <cfset var success = false>

        <cftry>
            <cfquery name="qAddData" datasource="#request.datasources#">
                INSERT INTO users 
				(
					first_name, 
					last_name, 
					phone,
					email,
					company
				)
                VALUES 
				(
					<cfqueryparam value="#formData.first_name#" cfsqltype="cf_sql_varchar">, 
					<cfqueryparam value="#formData.last_name#" cfsqltype="cf_sql_varchar">, 
					<cfqueryparam value="#formData.phone#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#formData.email#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#formData.company#" cfsqltype="cf_sql_varchar">
				)
            </cfquery>
            <cfset success = true>
            <cfcatch>
                <cfset success = false>
                <cflog text="Error saving user: #cfcatch.message#" type="error">
            </cfcatch>
        </cftry>

        <cfreturn success>
    </cffunction>

	<cffunction name="activateDeactivateUser" access="public" returntype="boolean">
		<cfargument name="user_id" type="numeric" required="true" />
		<cfargument name="active" type="numeric" required="true" />
	
		<!-- Initialize variable to hold query result -->
		<cfset var result = false>
	
		<cftry>
			<!-- Perform the update query to activate the user -->
			<cfquery datasource="#request.datasources#">
				UPDATE users 
				SET user_active = <cfqueryparam value="#arguments.active#" cfsqltype="cf_sql_integer">,
					updated_at = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
				WHERE user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
				AND user_deleted IS NULL
			</cfquery>

			<cfset result = true>

			<cfcatch>
				<cflog text="Error activating user: #cfcatch.message#" type="error">
				<cfset result = false>
			</cfcatch>
		</cftry>
	
		<cfreturn result>
	</cffunction>
	

	<cffunction access="public" name="deleteUser" returntype="any">
		<cfargument name="user_id" type="numeric" required="true" />
		
		<cftry>
			<!-- Execute the query to delete the user -->
			<cfquery name="qDeleteUser" datasource="#request.datasources#">
				UPDATE users 
				SET user_deleted = <cfqueryparam value="#createodbcdatetime(now())#" cfsqltype="cf_sql_timestamp"> 
				WHERE user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
			</cfquery>
	
			<!-- Fetch and return the updated user list -->
			<cfset updatedUsers = getUsersData()>
	
			<cfreturn {message = "User deleted successfully.", status = 200 } />
        
        <cfcatch>
            <!-- Handle any exceptions during the delete operation -->
            <cfreturn { message = "An error occurred while deleting the user: #cfcatch.message#", status = 500 } />
        </cfcatch>
		</cftry>
	</cffunction>

	<cffunction access="public" name="getUsersData" returntype="array">
		<cfargument name="user_id" type="any" required="false" default="" />

		<!-- SQL query that joins the roles table to get role information -->
		<cfquery returntype="array" name="qGetUserData" datasource="#request.datasources#">
			SELECT 
				users.*,
				roles.role_name,
				roles.description
			FROM
				users
			LEFT JOIN roles ON users.role_id = roles.role_id
			WHERE users.user_deleted IS NULL
			<cfif len(arguments.user_id)>
				AND users.user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
			</cfif>
			ORDER BY users.updated_at DESC
		</cfquery>

		<cfreturn qGetUserData>
	</cffunction>


	<!--- above are the new apis for client user management --->

    <cffunction access="public" name="getUserData" returntype="array">
		<cfargument name="user_id" type="any" required="false" default="">


		<cfquery returntype="array" name="qGetUserData" datasource="#request.datasources#">

            SELECT *
            FROM users
            -- WHERE user_ID = '#user_id#'
			
		</cfquery>

		<cfreturn qGetUserData>
	</cffunction>

	<cffunction access="public" name="updateUserData" returntype="array">
		<cfargument name="userData" type="any" required="true">

		<cfset avatarPath = ''>

		<cfquery name="qUpdateData" datasource="#request.datasources#">

			UPDATE users
				SET first_name = <cfqueryparam value="#userData.first_name#" cfsqltype="cf_sql_varchar">,
				last_name = <cfqueryparam value="#userData.last_name#" cfsqltype="cf_sql_varchar">,
				company = <cfqueryparam value="#userData.company#" cfsqltype="cf_sql_varchar">,
				company_site = <cfqueryparam value="#userData.company_site#" cfsqltype="cf_sql_varchar">,
				address = <cfqueryparam value="#userData.address#" cfsqltype="cf_sql_varchar">,
				country = <cfqueryparam value="#userData.country#" cfsqltype="cf_sql_varchar">,
				phone = <cfqueryparam value="#userData.phone#" cfsqltype="cf_sql_varchar">,
				email = <cfqueryparam value="#userData.email#" cfsqltype="cf_sql_varchar">,
				avatar = <cfqueryparam value="#avatarPath#" cfsqltype="cf_sql_varchar">
			WHERE user_id = <cfqueryparam value="#userData.user_id#" cfsqltype="cf_sql_integer">
		</cfquery>

		<Cfset userData = getUserData(user_id)>
		
		<Cfreturn userData>
	</cffunction>

</cfcomponent>