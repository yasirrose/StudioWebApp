import { useState, useEffect } from 'react';
import axios from 'axios';
import { toast } from 'react-toastify'; // Import toast if not already


// Hook for fetching users
const useFetchUsers = () => {
    const [Users, setUsers] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        const token = localStorage.getItem('jwttoken');

        const getUsers = async () => {
            try {
                const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
                const endpoint = '/users';
                const url = `${baseURL}${endpoint}`;

                const response = await axios.get(url, {
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${token}`
                    }
                });

                setUsers(response.data);
            } catch (error) {
                setError(error.message || 'Error fetching user data');
            } finally {
                setLoading(false);
            }
        };

        if (token) {
            getUsers();
        } else {
            setError('Token is missing');
            setLoading(false);
        }
    }, []);

    return { Users, loading, error };
};

// Hook for deleting a user
const useDeleteUser = () => {
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const deleteUser = async (id, setUsers) => {
        setLoading(true);
        try {
            const token = localStorage.getItem('jwttoken');
            const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
            const endpoint = '/users';
            const url = `${baseURL}${endpoint}`;

            const response = await axios.delete(url, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                data: {
                    id: id
                }
            });

            // console.log("--user delete--response = ", response);
            // Call the setUsers function to update the users state in the parent component
            setUsers(prevUsers => prevUsers.filter(user => user.user_id !== id));
            toast.success('User deleted successfully');
        } catch (error) {
            console.error('Error deleting user:', error);
            setError('Error deleting user');
            toast.error('Failed to delete user');
        } finally {
            setLoading(false);
        }
    };

    return { loading, error, deleteUser };
};

// Hook for activating/deactivating a user
const useActivateDeactivateUser = () => {
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const activateDeactivateUser = async (id, active, setUsers) => {
        setLoading(true);
        try {
            const token = localStorage.getItem('jwttoken');
            const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
            const endpoint = '/users';
            const url = `${baseURL}${endpoint}`;

            const response = await axios.put(url, {
                user_id: id,
                active: active
            }, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                }
            });

            // console.log("--user active--response = ", response);
            // Call the setUsers function to update the user active status in the parent component
            setUsers(prevUsers => prevUsers.map(user => user.user_id === id ? { ...user, user_active: active === 1 } : user));
            toast.success(`User ${active === 1 ? 'activated' : 'deactivated'} successfully`);
        } catch (error) {
            console.error('Error activating/deactivating user:', error);
            setError('Error activating/deactivating user');
            toast.error(`Failed to ${active === 1 ? 'activate' : 'deactivate'} user`);
        } finally {
            setLoading(false);
        }
    };

    return { loading, error, activateDeactivateUser };
};

// Hook for Adding a user
const useAddUser = () => {
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const addUser = async (userData) => {
        console.log("----hook--------addUser");
        console.log("----hook--------addUser");
        console.log("----hook--------addUser");
        console.log("----hook--------addUser");
        // return;
        setLoading(true);
        try {
            const token = localStorage.getItem('jwttoken');
            const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
            const endpoint = '/users';
            const url = `${baseURL}${endpoint}`;

            const response = await axios.post(url, userData, {
                headers: { 
                    'Content-Type': 'multipart/form-data',
                    'Authorization': `Bearer ${token}`
                }
            });

            console.log("--add user--response = ", response);

            // Call the setUsers function to update the users state in the parent component
            // setUsers(prevUsers => prevUsers.filter(user => user.user_id !== id));
            toast.success('User deleted successfully');
        } catch (error) {
            console.error('Error Adding user:', error);
            setError('Error Adding user');
            toast.error('Failed to Add user');
        } finally {
            setLoading(false);
        }
    };

    return { loading, error, addUser };
};

// Export all hooks
export { useFetchUsers, useDeleteUser, useActivateDeactivateUser, useAddUser };
