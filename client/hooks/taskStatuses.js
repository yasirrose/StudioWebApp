import { useState, useEffect } from 'react';
import api from '/utils/api';
import { useRouter } from 'next/router';


const useFetchStatuses = () => {
    const [Statuses, setStatuses] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const router = useRouter();
  
    useEffect(() => {
        // Get the user ID and jwttoken from local storage
        const token = localStorage.getItem('jwttoken');
        const userId = router.query.id || localStorage.getItem('id');

        // Define the API call function
        const getStatuses = async () => {
            try {
                if (!userId || !token) {
                    throw new Error('User ID or Token is missing');
                }

                // Make the API request to fetch user profile data
                const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
                const endpoint = `/statuses`;
                const url = `${baseURL}${endpoint}`;

                const response = await api.get(
                    url,
                    { headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` } }
                );
                // console.log("-STATUSES--response.data = ", response.data);

                // Set the data in state
                setStatuses(response.data);
            } catch (error) {
                // Handle errors
                setError(error.message || 'Error fetching statuses');
            } finally {
                // Turn off loading once the process completes
                setLoading(false);
            }
        };

        if (userId) {
            getStatuses();
        } else {
            setError('User ID not found in local storage');
            setLoading(false);
        }
    }, []);
  
    // Return the necessary state variables
    return { Statuses, loading, error };
  };

export {useFetchStatuses}

