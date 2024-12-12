import { useState, useEffect } from 'react';
import { signOut } from 'next-auth/react'; // Import signOut from next-auth
import api from '/utils/api';
import { toast } from 'react-toastify';

// Hook for fetching Menu Permissions
const useFetchMenuPermissions = () => {
    const [menuPermissions, setMenuPermissions] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        const token = localStorage.getItem('jwttoken');

        const getMenuPermissions = async () => {
            try {
                const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
                const endpoint = '/menuPermissions';
                const url = `${baseURL}${endpoint}`;

                const response = await api.get(url, {
                    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` }
                });
                console.log("--API CALL ");
                
                setMenuPermissions(response.data); // Set the fetched permissions data
            } catch (error) {
                setError(error.message || 'Error fetching permissions data');
            } finally {
                setLoading(false); // Turn off loading once the process completes
            }
        };

        if (token) {
            getMenuPermissions();
        } else {
            setError('Token is missing');
            setLoading(false);
        }
    }, []); // Run the effect once on component mount

    return { menuPermissions, loading, error };
};

// Hook for updating Menu Permissions
const useUpdateMenuPermission = () => {
    
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    
    const updateMenuPermission = async (permissionData) => {
        const token = localStorage.getItem('jwttoken');
        const userId = localStorage.getItem('id');
        console.log("updateMenuPermission----permissionData =", permissionData);
        
        try {
            if (!userId || !token) {
                signOut();
                throw new Error('User ID or Token is missing');
            }

            if (token) {
                getMenuPermissions();
            } else {
                console.warn('Token is missing, signing out...');
                setError('Token is missing');
                setLoading(false);
                signOut(); // Call the NextAuth signOut function
            }

            const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
            const endpoint = '/menuPermissions';
            const url = `${baseURL}${endpoint}`;

            setLoading(true);

            const response = await api.put(url, permissionData, {
                headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` }
            });

            console.log("-add/update permission -----response.data = ", response);

            if (response.data.STATUSCODE === 201) {
                // setMenuPermissions(response.data.PERMISSIONS); // Update the permissions list
                toast.success(response.data.DATA.message);
            } else {
                toast.error(response.data.DATA.message);
            }

            return response.data
        } catch (error) {
            toast.error('Failed');
            setError(error.message || 'Error updating permission data');
            throw error; // Re-throw to handle it in the calling component if needed
        } finally {
            setLoading(false);
        }
    };

    return { updateMenuPermission, loading, error };
};

// Hook for fetching Action Permissions
const useFetchActionPermissions = () => {
    const [actionPermissions, setActionPermissions] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        const token = localStorage.getItem('jwttoken');

        const getActionPermissions = async () => {
            try {
                const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
                const endpoint = '/actionPermissions';
                const url = `${baseURL}${endpoint}`;

                const response = await api.get(url, {
                    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` }
                });

                setActionPermissions(response.data); // Set the fetched permissions data
            } catch (error) {
                setError(error.message || 'Error fetching action permissions data');
            } finally {
                setLoading(false); // Turn off loading once the process completes
            }
        };

        if (token) {
            getActionPermissions();
        } else {
            setError('Token is missing');
            setLoading(false);
        }
    }, []); // Run the effect once on component mount

    return { actionPermissions, loading, error };
};

// Hook for updating Action Permissions
const useUpdateActionPermission = () => {

    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const updateActionPermission = async (permissionData) => {
        const token = localStorage.getItem('jwttoken');
        const userId = localStorage.getItem('id');
        console.log("----permissionData =", permissionData);
        
        try {
            if (!userId || !token) {
                throw new Error('User ID or Token is missing');
            }

            const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
            const endpoint = '/actionPermissions';
            const url = `${baseURL}${endpoint}`;

            setLoading(true);

            const response = await api.put(url, permissionData, {
                headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` }
            });

            console.log("-add/update permission -----response.data = ", response);

            if (response.data.STATUSCODE === 201) {
                // setActionPermissions(response.data.PERMISSIONS); // Update the permissions list
                toast.success(response.data.DATA.message);
            } else {
                toast.error(response.data.DATA.message);
            }

            return response.data; // Return the updated permission data
        } catch (error) {
            toast.error('Failed');
            setError(error.message || 'Error updating permission data');
            throw error; // Re-throw to handle it in the calling component if needed
        } finally {
            setLoading(false);
        }
    };

    return { updateActionPermission, loading, error };
};

export { useFetchMenuPermissions, useUpdateMenuPermission, useFetchActionPermissions, useUpdateActionPermission };

