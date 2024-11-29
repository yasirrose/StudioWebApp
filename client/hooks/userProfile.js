import { useState, useEffect, useCallback } from 'react';
import axios from 'axios';
import { signOut } from "next-auth/react";
import { useRouter } from 'next/router';


const useUserProfile = () => {
    const [profileData, setProfileData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const router = useRouter();
  
    useEffect(() => {
        // Get the user ID and jwttoken from local storage
        
        const token = localStorage.getItem('jwttoken');
        // console.log("-----router = ",router );
        // console.log("-----router.query.id = ",router.query.id );
        const userId = router.query.id || localStorage.getItem('id');

        // Define the API call function
        const getUserProfile = async () => {
            console.log("----useUserProfile");
            
            try {
                if (!userId || !token) {
                    throw new Error('User ID or Token is missing');
                }

                // Make the API request to fetch user profile data
                const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
                // const endpoint = `/user/${userId}/profile`;
                const endpoint = `/userprofile`;
                const url = `${baseURL}${endpoint}`;

                const response = await axios.get(
                    url,
                    { headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` } }
                );
                // console.log("---response.data = ", response.data);

                // Set the data in state
                setProfileData(response.data);
            } catch (error) {
                // Handle errors
                setError(error.message || 'Error fetching profile data');
            } finally {
                // Turn off loading once the process completes
                setLoading(false);
            }
        };

        if (userId) {
            getUserProfile();
        } else {
            setError('User ID not found in local storage');
            setLoading(false);
        }
    }, []);
  
    // Return the necessary state variables
    return { profileData, setProfileData, loading, error };
  };

export {useUserProfile}

const useUpdateUserProfile = () => {
    
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const router = useRouter();

    
    const updateUserProfile = async (updatedData) => {
        console.log("---updatedData = ", updatedData);

        const token = localStorage.getItem('jwttoken');
        const userId = router.query.id || localStorage.getItem('id');
        // return;
        try {
            if (!userId || !token) {
                throw new Error('User ID or Token is missing');
            }

            const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
            // const endpoint = `/user/${userId}/profile`;
            const endpoint = `/userprofile`;
            const url = `${baseURL}${endpoint}`;
            setLoading(true);

            const response = await axios.put(url, updatedData, {
                headers: { 'Content-Type': 'multipart/form-data', 'Authorization': `Bearer ${token}` }
            });

            console.log("-update user profile-----response.data = ", response.data);

            return response.data; // Return the updated profile data
        } catch (error) {
            setError(error.message || 'Error updating profile data');
            throw error; // Re-throw to handle it in the calling component if needed
        } finally {
            setLoading(false);
        }
    };

    return { updateUserProfile, loading, error };
};

export { useUpdateUserProfile };

