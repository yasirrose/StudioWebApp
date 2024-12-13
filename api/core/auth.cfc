<cfcomponent name="coreAuth" output="false">
    
    <cffunction name="login_name_and_password" returntype="struct">
        <cfargument name="email" type="string" required="true">
        <cfargument name="password" type="string" required="true">

        <cfset var response = structNew()>
        
        <!--- Query the database for user --->
        <cfquery name="getUser" datasource="#request.datasources#">
            SELECT 
                users.*,
                roles.role_name AS user_role
            FROM 
                users AS users
            LEFT JOIN 
                roles ON users.role_id = roles.role_id
            WHERE 
                users.email = <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar">
        </cfquery>

        <!--- Validate user existence and password --->
        <cfif getUser.recordCount EQ 1>
            <!--- Retrieve stored hashed password --->
            <cfset var storedPassword = getUser.password>
            <cfset var isPasswordValid = false>

            <!--- Compare provided password with stored password --->
            <cftry>
            <cfif hash(arguments.password, "SHA-256") EQ storedPassword>
                <!--- <cfif (arguments.password EQ storedPassword)> --->
                    <cfset isPasswordValid = true>
                </cfif>
            <cfcatch>
                <cfset response.success = false>
                <cfset response.message = "Error while verifying password.">
                <cfset response.httpcode = 500>
                <cfreturn response>
            </cfcatch>
            </cftry>

            <!--- Check if password validation succeeded --->
            <cfif isPasswordValid>
                <cfset response.success = true>
                <cfset jwtObj = createObject("component", "jwt")>
                
                <!--- Add 3 hours to the current timestamp --->
                <cfset threeHoursLater = dateAdd("h", 3, now())>
                <!--- Convert the resulting datetime to seconds since epoch --->
                <cfset jwtExpirationTime = dateDiff("s", now(), threeHoursLater)>
                <cfset session.jwtExpirationTime = jwtExpirationTime>  
                <cfset session.jwtExpirationDateTime = DateFormat(threeHoursLater, "YYYY-MM-dd") & " " & TimeFormat(threeHoursLater, "HH:MM:SS")>

                <cfset keysToExtract = [
                    "JWTEXPIRATIONTIME",
                    "JWTEXPIRATIONDATETIME"
                ]>

                <cfset extractedSession = StructNew() />

                <cfloop array="#keysToExtract#" index="key">
                    <cfif StructKeyExists(session, key)>
                        <cfset extractedSession[key] = session[key] />
                    </cfif>
                </cfloop>

                <cfset data = {
                    status: "SUCCESS",
                    name: "#getUser.first_name# #getUser.last_name#",
                    userID: "#getUser.user_id#",
                    roleID: "#getUser.role_id#",
                    email: "#getUser.email#",
                    role: "#getUser.user_role#",
                    sessions: "#extractedSession#",
                    httpcode: 200
                }>

                <cfset hashedData = jwtObj.encode(data, "HS256", "633c6deb-b5e9-40ad-85e8-63f14c4ba8c9")>  

                <cfset returnData = {
                    status: "SUCCESS",
                    name: "#getUser.first_name# #getUser.last_name#",
                    userID: "#getUser.user_id#",
                    roleID: "#getUser.role_id#",
                    role: "#getUser.user_role#",
                    email: "#getUser.email#",
                    sessions: "#extractedSession#",
                    httpcode: 200,
                    jwt: hashedData
                }>

                <cfreturn returnData>
            <cfelse>
                <cfset response.success = false>
                <cfset response.message = "Invalid credentials.">
                <cfset response.httpcode = 401>
                <cfreturn response>
            </cfif>
        <cfelse>
            <cfset response.success = false>
            <cfset response.message = "Invalid credentials.">
            <cfset response.httpcode = 401>
            <cfreturn response>
        </cfif>
    </cffunction>
    
    <!---  Client login via PIN --->
    <cffunction name="login_with_pin" returntype="struct">
        <cfoutput>
            <cflog text="AUTH.CFC -EMAIL --AND PASSWORD-IDENTIFIER IDENTIFIER  --output --- IDENTIFIER:" type="info">
        </cfoutput>
        <cfargument name="pincode" type="string" required="true">

        <cflog text="AUTH.CFC -PIN---IDENTIFIER IDENTIFIER  --output --- IDENTIFIER: #pincode#" type="info">

        <cfset var response = structNew()>
    
        <!-- Query the database for client based on PIN -->
        <cfquery name="getClient" datasource="#request.datasources#">
            SELECT 
                clients.*,
                clients.first_name
            FROM 
                clients
            WHERE 
                clients.client_pin = <cfqueryparam value="#pincode#" cfsqltype="CF_SQL_INTEGER">
        </cfquery>

        <cflog text="GET CLIENT: #serializeJSON(getClient)#" type="info">
        <!--- <cflog text="GET CLIENT: #getClient#" type="info"> --->

    
        <!-- Validate PIN -->
        <cfif getClient.recordCount EQ 1>
            <cfset response.success = true>
            <cfset jwtObj = createObject("component", "jwt")>
    
            <!--- Add 3 hours to the current timestamp --->
            <cfset threeHoursLater = dateAdd("h", 3, now())>
            <cfset jwtExpirationTime = dateDiff("s", now(), threeHoursLater)>
            <cfset session.jwtExpirationTime = jwtExpirationTime>  
            <cfset session.jwtExpirationDateTime = DateFormat(threeHoursLater, "YYYY-MM-dd") & " " & TimeFormat(threeHoursLater, "HH:MM:SS")>
    
            <cfset data = {
                status: "SUCCESS",
                name: "#getClient.first_name#",
                clientID: "#getClient.client_id#",
                pin: "#getClient.client_pin#",
                sessions: {JWTEXPIRATIONTIME: jwtExpirationTime, JWTEXPIRATIONDATETIME: session.jwtExpirationDateTime},
                httpcode: 200
            }>
    
            <cfset hashedData = jwtObj.encode(data, "HS256", "your-secret-key")>
    
            <cfset returnData = {
                status: "SUCCESS",
                name: "#getClient.first_name#",
                clientID: "#getClient.client_id#",
                sessions: {JWTEXPIRATIONTIME: jwtExpirationTime, JWTEXPIRATIONDATETIME: session.jwtExpirationDateTime},
                httpcode: 200,
                jwt: hashedData
            }>
    
            <cfreturn returnData>
        <cfelse>
            <cfset response.success = false>
            <cfset response.message = "Invalid PIN.">
            <cfset response.httpcode = 401>
            <cfreturn response>
        </cfif>
    </cffunction>

    <!---  Add New Member  --->
    <cffunction name="funAddNewMember" access="public" returntype="struct" output="false">
        <cfargument name="first_name" hint="first_name" type="string" required="true">
        <cfargument name="last_name" hint="last_name" type="string" required="true">
        <cfargument name="email" type="string" required="true">
		<cfargument name="password" type="string" required="true">
        <cfset var response = {}>


        <!-- Check already exists by email -->
        <cfset var userExists = checkUserExistsByEmail(email)>

        <cfif userExists>
            <cfset response.statusCode = 409>
            <cfset response.data = { "message" = "User with this email already exists" }>
        <cfelse>
            <cfset var hashedPassword = hash(password, "SHA-256")>

            <!-- Save the user  -->
            <cfset var signupSuccess = saveUser(first_name, last_name, email, hashedPassword)>

            <cfif signupSuccess>
                <cfset response.statusCode = 201>
                <cfset response.data = { "message" = "User created successfully" }>
            <cfelse>
                <cfset response.statusCode = 500>
                <cfset response.data = { "message" = "Error creating user" }>
            </cfif>
        </cfif>
        <cfreturn response>
    </cffunction>

    <!---Check user exists by email --->
    <cffunction name="checkUserExistsByEmail" access="private" returntype="boolean" output="false">
        <cfargument name="email" required="true" type="string">
        <cfset var exists = false>

        <cftry>
            <cfquery datasource="#request.datasources#" name="qCheckUser">
                SELECT COUNT(*) AS userCount
                FROM users
                WHERE email = <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar">
            </cfquery>

            <cfif qCheckUser.userCount GT 0>
                <cfset exists = true>
            </cfif>
            
            <cfcatch>
                <cflog text="Error checking if user exists: #cfcatch.message#" type="error">
            </cfcatch>
        </cftry>
        <cfreturn exists>
    </cffunction>

    <!---  save the user   --->
    <cffunction name="saveUser" access="private" returntype="boolean" output="false">
        <cfargument name="first_name" required="true" type="string">
        <cfargument name="last_name" required="true" type="string">
        <cfargument name="email" required="true" type="string">
        <cfargument name="hashedPassword" required="true" type="string">
        <cfset var success = false>

        <cftry>
            <cfquery datasource="#request.datasources#">
                INSERT INTO users (role_id, first_name, last_name, email, password)
                VALUES (<cfqueryparam value="1" cfsqltype="cf_sql_integer">, 
                        <cfqueryparam value="#arguments.first_name#" cfsqltype="cf_sql_varchar">, 
                        <cfqueryparam value="#arguments.last_name#" cfsqltype="cf_sql_varchar">, 
                        <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#arguments.hashedPassword#" cfsqltype="cf_sql_varchar">)
            </cfquery>
            <cfset success = true>
            <cfcatch>
                <cfset success = false>
                <cflog text="Error saving user: #cfcatch.message#" type="error">
            </cfcatch>
        </cftry>

        <cfreturn success>
    </cffunction>

   <!---Forget Password --->


    <!---/auth/forgetPassword --->
    <cffunction name="funAuthForgetPassword" access="public" returntype="struct" output="false">
        <cfargument name="email" required="true" type="string">
        <cfset var response = {}>

        <!-- Check if the user exists -->
        <cfset var userExists = checkUserExistsByEmail(email)>

        <cfif NOT userExists>
            <cfset response.statusCode = 404>
            <cfset response.data = { "message" = "User not found" }>
            <cfreturn response>
        </cfif>

        <!-- Generate a unique reset token -->
        <cfset var resetToken = createUUID()>

        <!-- Store the reset token -->
        <cfset var saveSuccess = saveResetToken(email, resetToken)>

        <cfif saveSuccess>
            <cfset sendResetEmail(email, resetToken)>
            <cfset response.statusCode = 200>
            <cfset response.data = { "message" = "Password reset email sent" }>
        <cfelse>
            <cfset response.statusCode = 500>
            <cfset response.data = { "message" = "Error processing reset request" }>
        </cfif>

        <cfreturn response>
    </cffunction>

    <!---save the reset token--->
    <cffunction name="saveResetToken" access="private" returntype="boolean" output="false">
        <cfargument name="email" required="true" type="string">
        <cfargument name="resetToken" required="true" type="string">
        <cfset var success = false>

        <cftry>
            <cfquery datasource="yourDatasource">
                UPDATE users
                SET reset_token = <cfqueryparam value="#arguments.resetToken#" cfsqltype="cf_sql_varchar">,
                    token_expiry = DATEADD("h", 1, NOW()) <!-- Token valid for 1 hour -->
                WHERE email = <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar">
            </cfquery>
            <cfset success = true>
            <cfcatch>
                <cfset success = false>
            </cfcatch>
        </cftry>

        <cfreturn success>
    </cffunction>

    <!---send the password reset email  --->
    <cffunction name="sendResetEmail" access="private" returntype="void" output="false">
        <cfargument name="email" required="true" type="string">
        <cfargument name="resetToken" required="true" type="string">

        <!-- reset URL -->
        <cfset var resetURL = "https://yourfrontend.com/resetPassword?token=" & arguments.resetToken>

        <!-- Send email -->
        <cfmail to="#arguments.email#" from="no-reply@yourapp.com" subject="Password Reset Request">
            Please click the following link to reset your password:
            #resetURL#
            This link is valid for 1 hour.
        </cfmail>
    </cffunction>


    <cffunction name="funAuthResetPassword" access="public" returntype="struct" output="false">
        <cfargument name="token" required="true" type="string">
        <cfset var response = {}>

        <!-- Check if the token expired or not -->
        <cfquery name="checkToken" datasource="yourDatasource">
            select top 1
            DATEDIFF(minute , u.dateCreated,getdate()) as spentTime
            from user u
            where token = #arguments.token#
            and token_expiry = 'DATEADD("h", 1, NOW())'
            order by u.dateCreated desc
        </cfquery>


        <cfif NOT userExists>
            <cfset response.statusCode = 404>
            <cfset response.data = { "message" = "User not found" }>
            <cfreturn response>
        </cfif>

        <!-- Generate a unique reset token -->
        <cfset var resetToken = createUUID()>

        <!-- Store the reset token -->
        <cfset var saveSuccess = saveResetToken(email, resetToken)>

        <cfif saveSuccess>
            <cfset sendResetEmail(email, resetToken)>
            <cfset response.statusCode = 200>
            <cfset response.data = { "message" = "Password reset email sent" }>
        <cfelse>
            <cfset response.statusCode = 500>
            <cfset response.data = { "message" = "Error processing reset request" }>
        </cfif>

        <cfreturn response>
    </cffunction>



</cfcomponent>