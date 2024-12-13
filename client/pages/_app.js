import React, { useEffect, useState } from 'react';
import 'bootstrap/dist/css/bootstrap.min.css';
import "../styles/style.bundle.css";
import "../styles/globals.scss";
import 'nprogress/nprogress.css';
import Loader from '../components/common/loader/Loader';
import { LoadingProvider, useLoading } from '../context/LoadingContext';
import { useRouter } from 'next/router';
import { getSession, SessionProvider } from 'next-auth/react';
import { ThemeProvider } from '../context/ThemeContext';
import { AuthProvider } from "../context/authContext";
import { useFetchMenuPermissions } from "../hooks/permissions"; // Hook to fetch menu permissions
import { hasAccess } from "../utils/permissions"; // Utility function for permission validation
import nprogress from 'nprogress';

nprogress.configure({
    showSpinner: false, 
    speed: 400,         
    minimum: 0.2       
  });


const AppInitializer = ({ setSession }) => {
    const { setLoading } = useLoading();
    const router = useRouter();

    useEffect(() => {
        console.log("------in AppInitializer-----");
        import("bootstrap/dist/js/bootstrap.bundle.min.js");

        let timer;
            const handleRouteChangeStart = () => {
            timer = setTimeout(() => nprogress.start(), 100); 
        };

        const handleRouteChangeComplete = () => {
            clearTimeout(timer);
            nprogress.done();
        };

        const handleRouteChangeError = () => {
            clearTimeout(timer);
            nprogress.done();
        };

        router.events.on('routeChangeStart', handleRouteChangeStart);
        router.events.on('routeChangeComplete', handleRouteChangeComplete);
        router.events.on('routeChangeError', handleRouteChangeError);

        return () => {
            router.events.off('routeChangeStart', handleRouteChangeStart);
            router.events.off('routeChangeComplete', handleRouteChangeComplete);
            router.events.off('routeChangeError', handleRouteChangeError);
        };

        const initializeApp = async () => {
            setLoading(true);

            // Dynamically import Bootstrap JavaScript
            await import("bootstrap/dist/js/bootstrap.bundle.min.js");
            
            // Fetch user session
            const session = await getSession();

            if (session) {
                setSession(session);    
                console.log("session = ", session);

                if(!localStorage.getItem('jwttoken')) {
                    localStorage.setItem("jwttoken", session.user.jwttoken);
                }
                if(!localStorage.getItem('id')) {
                    localStorage.setItem("id", session.user?.id);
                }
                if(!localStorage.getItem('clientId')) {
                    localStorage.setItem("clientId", session.user?.clientId);
                }
                if(!localStorage.getItem('role')) {
                    localStorage.setItem("role", session.user?.role);
                }
                if(!localStorage.getItem('roleId')) {
                    localStorage.setItem("roleId", session.user?.roleId);
                }

            }
            setLoading(false);
        };

        initializeApp();
    }, [setLoading, setSession]);

    return null;
};

export default function App({ Component, pageProps: { session, ...pageProps } }) {
    const [clientSession, setClientSession] = useState(session);
    const { menuPermissions, loading: permissionsLoading, error } = useFetchMenuPermissions();
    const [isCheckingAccess, setIsCheckingAccess] = useState(true);
    const router = useRouter();
    const isLoginPage = router.pathname === '/Auth';

    useEffect(() => {
        const checkAccess = async () => {
            const roleId = localStorage.getItem("roleId");
            const path = router.pathname;

            // Check permissions and redirect if access is denied
            if (menuPermissions && roleId) {
                if ((roleId === '1' && path === '/userProfile') || path === '/Auth') {
                    return true;
                }
                else if (!hasAccess(menuPermissions, path, roleId)) {
                    console.log("Access denied. Redirecting to /dashboard.");
                    await router.replace("/dashboard");
                }
            }
            setIsCheckingAccess(false); // Access check complete
        };

        if (!permissionsLoading) {
            checkAccess();
        }
    }, [menuPermissions, router, permissionsLoading]);

    // Display a loader until access checking is complete
    // if (isCheckingAccess || permissionsLoading) {
    //     return  <p>Checking access...</p>; // Replace with your loading component if necessary
    // }

    return (
        <ThemeProvider>
            <AuthProvider>
                <LoadingProvider>
                    <AppInitializer setSession={setClientSession} />
                    <SessionProvider session={clientSession}>
                    <Component {...pageProps} />
                    {!isLoginPage && <Loader />}
                    </SessionProvider>
                </LoadingProvider>
            </AuthProvider>
        </ThemeProvider>
    );
}
