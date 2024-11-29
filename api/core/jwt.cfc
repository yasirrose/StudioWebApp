component
	output = false
	hint = "I provide a ColdFusion gateway for creating and consuming JSON Web Tokens (JWT)."
	{

	// I map the common JWT algorithm names onto the underlying Java algorithm names.
	// --
	// Read More: http://docs.oracle.com/javase/7/docs/technotes/guides/security/StandardNames.html
	mapToJavaAlgorithm = {
		HS256 = "HmacSHA256",
		HS384 = "HmacSHA384",
		HS512 = "HmacSHA512",
		RS256 = "SHA256withRSA",
		RS384 = "SHA384withRSA",
		RS512 = "SHA512withRSA"
		// --
		// Not yet supported. 
		// --
		// ES256 = "SHA256withECDSA",
		// ES384 = "SHA384withECDSA",
		// ES512 = "SHA512withECDSA"
	};


	/**
	* I initialize the JSON Web Tokens gateway. The gateway can create clients; or, it
	* can proxy a client for ease-of-use.
	* 
	* @output false
	*/
	public any function init() {

		return( this );

	}


	// ---
	// PUBLIC METHODS.
	// ---


	/**
	* I create a JSON Web Token client that can encode() and decode() JWT values. If the
	* algorithm is an Hmac-based algorithm, only the secret key is required. If the 
	* algorithm is an RSA-based algorithm, both the public and private keys are required
	* (and assumed to be in PEM format).
	* 
	* @algorithm I am the Hmac algorithm to be used when signing and verifying the payloads.
	* @key If the algorithm is Hmac, I am the secret key. If RSA, I am the public key in PEM format.
	* @privateKey If the algorithm is RSA, I am the private key in PEM format.
	* @output false
	*/
	public any function createClient( 
		required string algorithm,
		required string key,
		string privateKey
		) {

		switch ( algorithm ) {
			case "HS256":
			case "HS384":
			case "HS512":

				var jwtClient = new client.JsonWebTokensClient(
					new encode.JsonEncoder(),
					new encode.Base64urlEncoder(),
					new sign.HmacSigner( mapToJavaAlgorithm[ algorithm ], key )
				);

			break;
			case "RS256":
			case "RS384":
			case "RS512":

				var jwtClient = new client.JsonWebTokensClient(
					new encode.JsonEncoder(),
					new encode.Base64urlEncoder(),
					new sign.RSASigner( mapToJavaAlgorithm[ algorithm ], key, privateKey )
				);

			break;
			default:

				throw(
					type = "JsonWebTokens.InvalidAlgorithm",
					message = "The given algorithm is not supported.",
					detail = "No client can be created for the given algorithm [#algorithm#] as it is not supported."
				);

			break;
		}

		return( jwtClient );

	}


	/**
	* I decode the given JSON Web Token and return the deserialized payload.
	* 
	* NOTE: If you plan to use the same key and algorithm for a number of operations,
	* it would be more efficient to create and cache a web-tokens client instead of using
	* this one-off method.
	* 
	* @token I am the JSON Web Token being decoded.
	* @algorithm I am the algorithm to be used to verify the signature.
	* @key If the algorithm is Hmac, I am the secret key. If RSA, I am the public key in PEM format.
	* @privateKey If the algorithm is RSA, I am the private key in PEM format.
	* @output false
	*/
	public struct function decode(
		required string token,
		required string algorithm,
		required string key,
		string privateKey = ""
		) {

		return( createClient( algorithm, key, privateKey ).decode( token ) );
		
	}


	/**
	* I encode the given payload and return the JSON Web Token.
	* 
	* NOTE: If you plan to use the same key and algorithm for a number of operations,
	* it would be more efficient to create and cache a web-tokens client instead of using
	* this one-off method.
	* 
	* @payload I am the payload being encoded for transport.
	* @algorithm I am the algorithm to be used to generate the signature.
	* @key If the algorithm is Hmac, I am the secret key. If RSA, I am the public key in PEM format.
	* @privateKey If the algorithm is RSA, I am the private key in PEM format.
	* @output false
	*/
	public string function encode(
		required struct payload,
		required string algorithm,
		required string key,
		string privateKey = ""
		) {

		return( createClient( algorithm, key, privateKey ).encode( payload ) );

	}

    public struct function validateJwt() {
			var http_headers = getHTTPRequestData().headers;

			var authorizationHeader = "";

			// Check that valid Authorization header exists
			if(
				http_headers.keyExists("Authorization")
				&& isValid("string", http_headers["Authorization"]) 
				&& http_headers["Authorization"].startsWith("Bearer ")
			){
				authorizationHeader = http_headers["Authorization"];
			} else {
				throw(
					type = "JsonWebTokens.InvalidToken",
					message = "Invalid Authorization header or token format.",
					detail = "Expected Authorization header format: 'Bearer <token>'."
				);
			}

			var jwtToken = listGetAt(authorizationHeader, 2, " ");
			
			// Replace 'your_secret_key_here' with your actual secret key
			var decodedJwt = decode(jwtToken, "HS256", "633c6deb-b5e9-40ad-85e8-63f14c4ba8c9");
			var expiryDateTime = DateFormat(decodedJwt.SESSIONS.JWTEXPIRATIONDATETIME, "YYYY-MM-dd") & " " & TimeFormat(decodedJwt.SESSIONS.JWTEXPIRATIONDATETIME, "HH:MM:SS");
			var currentTimestamp = DateFormat(now(), "YYYY-MM-dd") & " " & TimeFormat(now(), "HH:MM:SS");;
			var currentTimestampSec = dateDiff("s", expiryDateTime, currentTimestamp); // Current time in seconds
			
			if( decodedJwt.SESSIONS.JWTEXPIRATIONTIME lt currentTimestampSec ) {
					throw(
							type = "JsonWebTokens.TokenExpired",
							message = "JWT token has expired.",
							detail = "The JWT token provided has expired and is no longer valid."
					);
			}

			if( not isDefined("session.library_context") or not isStruct(session.library_context) ){
				var core_library = createObject("component","core.library");
				session.library_context = core_library.getInternalContext(decodedJwt.sessions.libraryid);
			}
			
			return decodedJwt;
    }

}
