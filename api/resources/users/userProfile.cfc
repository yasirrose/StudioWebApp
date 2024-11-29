<cfcomponent extends="taffy.core.resource" taffy_uri="/userprofile" taffy:docs:name="user.profile">

	<cffunction name="userProfile" taffy:verb="get" access="public" output="true" hint="">
		<cfargument name="userID" type="any" required="false" hint="" />
		<!--- <cfset jwtObj = createObject("component", "core.jwt")>
		<cfset jwtData = jwtObj.validateJwt()>


		<cfif not isDefined("jwtData.sessions.userid") or jwtData.sessions.userid eq ''>
			<cfreturn noData().withStatus(401)>
		</cfif> --->

        <cfset core_user = createObject("component","core.users")>
		
		<Cfset profileData = core_user.getUserData()>

		<cfreturn rep(profileData).withStatus(200) />
	</cffunction>

	<cffunction name="updateUserProfile" taffy:verb="put" access="public" output="true" hint="">
		<cfargument name="user_id" type="any" required="false" default="" hint="" />
		<cfargument name="first_name" type="any" required="false" default="" hint="" />
		<cfargument name="last_name" type="any" required="false" default="" hint="" />
		<cfargument name="company" type="any" required="false" default="" hint="" />
		<cfargument name="company_site" type="any" required="false" default="" hint="" />
		<cfargument name="country" type="any" required="false" default="" hint="" />
		<cfargument name="phone" type="any" required="false" default="" hint="" />
		<cfargument name="email" type="any" required="false" default="" hint="" />
		<cfargument name="address" type="any" required="false" default="" hint="" />
		<cfargument name="avatar" type="any" required="false" hint="Uploaded avatar file." />

        <cfset core_user = createObject("component","core.users")>


		<!--- Handle avatar file upload if provided --->
		<cfset var avatarPath = "">
		<cfif structKeyExists(arguments, "avatar") AND isDefined("arguments.avatar")>
			<cfset avatarFile = arguments.avatar>
	
			<!--- Check if avatarFile is a valid File object --->
			<cfif isObject(avatarFile) AND structKeyExists(avatarFile, "name") AND structKeyExists(avatarFile, "size")>
				<cfset uploadPath = expandPath("C:\web\Developer 3\Uploads\")> <!-- Ensure the path ends with a backslash -->
				<cfset newFileName = createUUID() & "." & listLast(avatarFile.name, ".")>
	
				<!--- Using cffile to upload the file --->
				<cffile action="upload" filefield="avatar" destination="#uploadPath#" nameconflict="makeunique" accept="image/png,image/jpg,image/jpeg">
				<cfset avatarPath = uploadPath & newFileName>
			</cfif>
		</cfif>

		<!--- Prepare user data for update --->
		<cfset userData = {
			first_name: arguments.first_name,
			last_name: arguments.last_name,
			company: arguments.company,
			company_site: arguments.company_site,
			address: arguments.address,
			country: arguments.country,
			phone: arguments.phone,
			email: arguments.email,
			avatarPath: avatarPath,
			user_id: arguments.user_id
		}>

		
		<!--- <Cfset profileData = core_user.updateUserData(userID,arguments)> --->
		<cfset profileData = core_user.updateUserData(userData)>

		<cfreturn rep(profileData).withStatus(200) />
	</cffunction>

</cfcomponent>
