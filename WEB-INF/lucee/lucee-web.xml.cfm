<?xml version="1.0" encoding="ISO-8859-1" standalone="no"?><cfLuceeConfiguration salt="618094CC-663D-4BF3-997B309FA05ECE0D" version="5.3">

<!-- 
Path placeholders:
	{lucee-web}: path to the Lucee web directory typical "{web-root}/WEB-INF/lucee"
	{lucee-server}: path to the Lucee server directory typical where the Lucee.jar is located
	{lucee-config}: same as {lucee-server} in server context and same as {lucee-web} in web context}
	{temp-directory}: path to the temp directory of the current user of the system
	{home-directory}: path to the home directory of the current user of the system
	{web-root-directory}: path to the web root
	{system-directory}: path to thesystem directory
	{web-context-hash}: hash of the web context
-->

    <!--
    arguments:
		close-connection - 	write connection-close to response header
		suppress-whitespace	-	supress white space in response
		show-version - show lucee version uin response header
	 -->
	<setting/>

<!--	definition of all database used inside your application. 										-->
<!--	above you can find some definition of jdbc drivers (all this drivers are included at lucee) 	-->
<!--	for other database drivers see at: 																-->
<!--	 - http://servlet.java.sun.com/products/jdbc/drivers 											-->
<!--	 - http://sourceforge.net 																		-->
<!--	or ask your database distributor 																-->

	<data-sources>
	</data-sources>
	<mode develop="false"/>
	
	<resources>
    	<!--
        arguments:
		lock-timeout   - 	define how long a request wait for a lock
	 	-->
    	<resource-provider arguments="case-sensitive:true;lock-timeout:1000;" class="lucee.commons.io.res.type.ram.RamResourceProvider" scheme="ram"/>
    </resources>
    
    <remote-clients directory="{lucee-web}remote-client/"/>
	
	
	<!--
		deploy-directory - directory where java classes will be deployed
		custom-tag-directory - directory where the custom tags are
		tld-directory / fld-directory - directory where additional Function and Tag Library Deskriptor are.
		temp-directory - directory for temporary files (upload aso.)
	 -->
	<file-system deploy-directory="{lucee-web}/cfclasses/" fld-directory="{lucee-web}/library/fld/" temp-directory="{lucee-web}/temp/" tld-directory="{lucee-web}/library/tld/">
	</file-system>
	
	<!--
	scope configuration:
	
		cascading (expanding of undefined scope)
			- strict (argument,variables)
			- small (argument,variables,cgi,url,form)
			- standard (argument,variables,cgi,url,form,cookie)
			
		cascade-to-resultset: yes|no
			when yes also allow inside "output type query" and "loop type query" call implizid call of resultset
			
		merge-url-form:yes|no
			when yes all form and url scope are synonym for both data
		
		client-directory:path to directory where client scope values are stored
		client-directory-max-size: max size of the client scope directory
	-->
	<scope client-directory="{lucee-web}/client-scope/" client-directory-max-size="100mb"/>
		
	<mail>
	</mail>
	
	
	<!--
	define path to scedule task directory
		directory: path
	-->	
	<scheduler directory="{lucee-web}/scheduler/"/>
	
	<mappings>
	<!--
	directory mapping:
		
		trusted: yes|no
			trusted cache -> recheck every time if there are changes in the called cfml file or not.
		virtual:
			virtual path of the application
			example: /somedir/
			
		physical: 
			physical path to the apllication
			example: d:/projects/app1/webroot/somedir/
			
		archive:
			path to an archive file:
			example: d:/projects/app1/rasfiles/somedir.ras
		primary: archive|physical
			define where lucee first look for a called cfml file.
			for example when you define physical you can partiquel overwrite the archive.
		-->
		<mapping archive="{lucee-web}/context/lucee-context.lar" physical="{lucee-web}/context/" primary="physical" readonly="yes" toplevel="yes" trusted="true" virtual="/lucee/"/>
	</mappings>	
	
	<custom-tag>
		<mapping physical="{lucee-web}/customtags/" trusted="yes"/>
	</custom-tag>
	
	<ext-tags>
		<ext-tag class="lucee.cfx.example.HelloWorld" name="HelloWorld" type="java"/>
	</ext-tags>
	
	<!--
	component:
		
		base: 
			path to base component for every component that have no base component defined 
		data-member-default-access: remote|public|package|private
			access type of component data member (variables in this scope)
		use-shadow: if true component variable scope has a second scope, not only the this scope
	-->
	<component base="/lucee/Component.cfc" data-member-default-access="public" use-shadow="yes"> 
	</component>
	
	<!--
	regional configuration:
		
		locale: default: system locale
			define the locale 
		timezone: default:maschine configuration
			the ID for a TimeZone, either an abbreviation such as "PST", 
			a full name such as "America/Los_Angeles", or a custom ID such as "GMT-8:00". 
		timeserver: [example: swisstime.ethz.ch] default:local time
			dns of a ntp time server
	-->
	<regional/>
	
	<!--
		enable and disable debugging
	 -->
	<debugging template="/lucee/templates/debugging/debugging.cfm"/>
		
	<application cache-directory="{lucee-web}/cache/" cache-directory-max-size="100mb"/>
<datasource/><rest/><gateways/><orm/><search/></cfLuceeConfiguration>