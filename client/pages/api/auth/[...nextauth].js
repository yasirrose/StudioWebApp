import NextAuth from 'next-auth';
import GitHubProvider from 'next-auth/providers/github';
import GoogleProvider from 'next-auth/providers/google';
import CredentialsProvider from 'next-auth/providers/credentials';
import api from '/utils/api';

export default async function auth(req, res) {
  const { host } = req.headers;
  const protocol = !host.includes("local") ? "https" : "http";
  
  //should this have the path /api/auth?
  process.env.NEXTAUTH_URL = `${protocol}://${host}`;

    const providers = [
        CredentialsProvider({
            name: "Email",
            credentials: {
                email: { label: 'Email', type: 'email', placeholder: 'Enter your email' },
                password: { label: 'Password', type: 'password' },
                pincode: { label: 'PIN', type: 'text', placeholder: 'Enter your 6-digit PIN (for clients)' },        
            },
            async authorize(credentials) {
                console.log("--authorize----IN CREDENTIALS PROVIDER");
                const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
                const endpoint = '/auth/login';
                let url = "";

                if (credentials.email) {
                    url = `${baseURL}${endpoint}&email=${encodeURIComponent(credentials.email)}&password=${encodeURIComponent(credentials.password)}`;
                } else {
                    url = `${baseURL}${endpoint}&pincode=${encodeURIComponent(credentials.pincode)}`;
                }

                // console.log('credentials',url);
                console.log('credentials-URL----->>>>>>>>',url);

                try {
                    // toast.error('Login passed. Please check your credentials.');
                    const response = await api.get(url, {
                        headers: {
                        'Content-Type': 'application/json',
                        },
                    });
                    console.log("RESPONSE-----login----->: ", response.data);

                    //   console.log(response);

                    if (response.data.STATUS === 'SUCCESS') {
                        const user = {
                            id: response.data?.USERID,
                            clientId: response.data?.CLIENTID,
                            role: response.data?.ROLE,
                            roleId: response.data?.ROLEID,
                            name: response.data.NAME,
                            jwt: response.data.JWT,
                        };
                        
                        return Promise.resolve(user);
                    } else {
                        return null;
                    }
                } catch (error) {
                    if (error.response) {
                        
                    } else if (error.request) {
                        // The request was made but no response was received
                        console.error('Error request:', error.request);
                    } else {
                        // Something happened in setting up the request that triggered an Error
                        console.error('Error message:', error.message);
                    }
                    return null;
                }
            },
        }),
    ];

    const authOptions = {  
        providers,
        pages: {
        signIn: '/Auth',
        },
        session: {
        jwt: true,
        maxAge: 24 * 60 * 60,
        },
        callbacks: {
        async jwt({ token, user }) {
            console.log("---user---", user);
            
            if (user) {
                token.id = user?.id; // Store user id in JWT token
                token.clientId = user?.clientId; // Store client id in JWT token
                token.role = user?.role;
                token.roleId = user?.roleId;
                token.jwt = user.jwt; // Store user id in JWT token
            }
            return Promise.resolve(token);
        },
        async session({ session, token }) {
            console.log("---token---", token);

            session.user.id = token?.id; // Set user id from token to session
            session.user.clientId = token?.clientId; // Set client id from token to session
            session.user.role = token?.role;
            session.user.roleId = token?.roleId; // Set client id from token to session
            session.user.jwttoken = token.jwt; // Set user id from token to session
            return Promise.resolve(session);
        },
        // async redirect({ url, baseUrl }) {
        //   console.log("next auth redirect called with url arg: ", url, baseUrl);

        //   if( url.startsWith("/") ) return `${baseUrl}${url}`;

        //   //split by '?' or '#' to remove search params/anchor
        //   // const url_path_only = url.split(/[?#]/)[0];
        //   // console.log("url_path_only: ", url_path_only);
        //   // debugger;
        //   // return Promise.resolve( url_path_only ); // Redirect to app after sign in
        //   return Promise.resolve(process.env.NEXTAUTH_URL); // Redirect to app after sign in
        // },
        },
    };

  return NextAuth(req, res, authOptions);
}
