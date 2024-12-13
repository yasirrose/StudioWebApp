<cfcomponent extends="taffy.core.api">
	<cfscript>

		// this.utils = createObject("component", "../../../ApplicationUtils.cfc");


		//shares name with /SmartGate/Application.cfc so APPLICATION scope is shared as well
		this.name = "StudioWebApp"; // 1i00

		this.mappings["/resources"] = listDeleteAt(cgi.script_name, listLen(cgi.script_name, "/"), "/") & "/resources";
		this.mappings["/core"] = listDeleteAt(cgi.script_name, listLen(cgi.script_name, "/"), "/") & "/core";
		
		
		this.mappings["/taffy"] = expandPath("./Taffy");

		//central db for iapproveit
		// this.datasources["1i00_central"] = {
		// 	class: "com.microsoft.sqlserver.jdbc.SQLServerDriver",
		// 	bundleName: "org.lucee.mssql",
		// 	bundleVersion: "12.6.3.jre11",
		// 	connectionString: "jdbc:sqlserver://1i00dbserver:1433;DATABASENAME=1i00_central;sendStringParametersAsUnicode=true;SelectMethod=direct;encrypt=false",
		// 	username: "sa",
		// 	password: "encrypted:09428ce2c7b7412f7199b483b77b4bfef2fb438f394e26aa89f1af5468646ec5",
		// 	// optional settings
		// 	blob:true, // default: false
		// 	clob:true, // default: false
		// 	connectionLimit:100, // default:-1
		// 	liveTimeout:5, // default: -1; unit: minutes
		// 	validate:false, // default: false
		// };

		request.datasources = 'ipstudio'; 

		variables.framework = {};
		variables.framework.debugKey = "debug";
		variables.framework.reloadKey = "reload";
		variables.framework.reloadPassword = "true";
		variables.framework.reloadOnEveryRequest = true;
		variables.framework.serializer = "taffy.core.nativeJsonSerializer";
		// variables.framework.serializer = "taffy.core.baseSerializer";
		variables.framework.returnExceptionsAsJson = true;
		variables.framework.globalHeaders = {
			"TrySkipIisCustomErrors": false,
		};

		function onApplicationStart(){
			writeLog('1i00 api onApplicationStart');
			// include "../../../Mixin/common_application_init.inc";
			return super.onApplicationStart();
		}

		function onRequestStart(TARGETPATH){
			if (cgi.request_method == "GET" && urlDecode(cgi.query_string) contains "/auth/login") {
				
			}
			return true;
		}

		function onRequest(TARGETPATH) {
			writeLog('1i00 api onRequest');
			cfheader(name="Access-Control-Allow-Origin", value="*");
			// cfheader(name="Access-Control-Allow-Origin", value="https://io.dev.ip.com.au");
			cfheader(name="Access-Control-Allow-Methods", value="GET, POST,PUT,OPTIONS");
			cfheader(name="Access-Control-Allow-Headers", value="Content-Type, Authorization");
			cfheader(name="Access-Control-Allow-Credentials", value="true");
			cfheader(name="Access-Control-Expose-Headers", value="X-Time-To-Reload, X-Time-In-Parse, X-Time-In-Ontaffyrequest, X-Time-In-Resource, X-Time-In-Cache-check, X-Time-In-Cache-save, X-Time-In-Serialize, X-Time-In-Taffy, X-Time-In-Ontaffyrequestend, X-Time-In-OnRequestStart");
			return super.onRequest(TARGETPATH);
		}

		function onError(e) {
			writeLog('1i00 api onError');
			return super.onError(e);
		}

		// this function is called after the request has been parsed and all request details are known
		function onTaffyRequest(verb, cfc, requestArguments, mimeExt){
			writeLog('1i00 api onTaffyRequest');
			// this would be a good place for you to check API key validity and other non-resource-specific validation
			return true;
		}

		// function onError(e){
		// 	writeDump(e);

		// }
	</cfscript>
</cfcomponent>
