import { useState, useEffect, useCallback } from 'react';
import axios from 'axios';
import api from '/utils/api';
import { toast } from 'react-toastify'; // Import toast if not already


// Hook for fetching clients
const useClients = () => {
    const [Clients, setClients] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
  
    useEffect(() => {
        // Get the client ID and jwttoken from local storage
        const token = localStorage.getItem('jwttoken');

        // Define the API call function
        const getClient = async () => {
            try {

                // Make the API request to fetch client profile data
                const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
                const endpoint = '/clients';
                const url = `${baseURL}${endpoint}`;
                
                const response = await axios.get(
                    url,
                    { headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` } }
                );

                // Set the data in state
                setClients(response.data);
            } catch (error) {
                // Handle errors
                setError(error.message || 'Error fetching profile data');
            } finally {
                // Turn off loading once the process completes
                setLoading(false);
            }
        };

        if (token) {
            getClient();
        } else {
            setError(' Token is missing');
            setLoading(false);
        }
    }, []);
  
    // Return the necessary state variables
    return { Clients, loading, error };
};

// Hook for add/update a client
const useAddUpdateClient = () => {
    
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    
    const addUpdateClient = async (clientData, setClients) => {
        console.log("->    useAddUpdateClient-----clientdata = ", clientData);
        
        const token = localStorage.getItem('jwttoken');
        const userId = localStorage.getItem('id');

        try {
            if (!userId || !token) {
                throw new Error('User ID or Token is missing');
            }

            const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
            const endpoint = `/clients`;
            const url = `${baseURL}${endpoint}`;
            setLoading(true);

            const response = await api.put(url, clientData, {
                headers: { 'Content-Type': 'multipart/form-data', 'Authorization': `Bearer ${token}` }
            });

            // console.log("-add update client profile-----response.data = ", response);
            // console.log("-add update client profile-----response.data = ", response.data.CLIENTS);

            if (response.data.STATUSCODE == 201) {
                setClients(response.data.CLIENTS);
                toast.success(response.data.DATA.message);
            } else {
                toast.error(response.data.DATA.message);
                return;
            }
            
            return response.data.CLIENTS; // Return the updated profile data
        } catch (error) {
            console.log("-> ERROR:", error);
            toast.error(error.response.data.message);
            // setError(error.message || 'Error updating profile data');
            // throw error; // Re-throw to handle it in the calling component if needed
        } finally {
            setLoading(false);
        }
    };

    return { addUpdateClient, loading, error };
};


// Hook for deleting a client
const useDeleteClient = () => {
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const deleteClient = async (id, setClients) => {
        setLoading(true);
        try {
            const token = localStorage.getItem('jwttoken');
            const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
            const endpoint = '/clients';
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

            toast.success('Client deleted successfully');
            console.log("--client delete--response = ", response);
            // Call the setClients function to update the clients state in the parent component
            setClients(prevClients => prevClients.filter(client => client.client_id !== id));
        } catch (error) {
            console.error('Error deleting client:', error);
            setError('Error deleting client');
            toast.error('Failed to delete client');
        } finally {
            setLoading(false);
        }
    };

    return { loading, error, deleteClient };
};

// Hook for activating/deactivating a client
const useActivateDeactivateClient = () => {
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const activateDeactivateClient = async (id, active, setClients) => {
        setLoading(true);
        try {
            const token = localStorage.getItem('jwttoken');
            const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
            const endpoint = '/clients';
            const url = `${baseURL}${endpoint}`;

            const response = await axios.post(url, {
                client_id: id,
                active: active
            }, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                }
            });

            // console.log("--client active--response = ", response);
            // Call the setClients function to update the client active status in the parent component
            setClients(prevClients => prevClients.map(client => client.client_id === id ? { ...client, client_active: active === 1 } : client));
            toast.success(`Client ${active === 1 ? 'activated' : 'deactivated'} successfully`);
        } catch (error) {
            console.error('Error activating/deactivating client:', error);
            setError('Error activating/deactivating client');
            toast.error(`Failed to ${active === 1 ? 'activate' : 'deactivate'} client`);
        } finally {
            setLoading(false);
        }
    };

    return { loading, error, activateDeactivateClient };
};

// Export all hooks
export { useClients, useAddUpdateClient, useDeleteClient, useActivateDeactivateClient };
