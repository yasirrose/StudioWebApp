import { useState, useEffect, useCallback } from 'react';
import axios from 'axios';
import api from '/utils/api';
import { toast } from 'react-toastify'; // Import toast if not already


// Hook for fetching Tasks
const useTasks = () => {
    const [Tasks, setTasks] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
  
    useEffect(() => {
        // Get the task ID and jwttoken from local storage
        const token = localStorage.getItem('jwttoken');
        const userId = localStorage.getItem('id');
        const roleId = localStorage.getItem('roleId');
        const clientId = localStorage.getItem('clientId');

        console.log("-12--->client id = ", localStorage.getItem('clientId'));
        // Define the API call function
        const getTask = async () => {
            try {

                // Make the API request to fetch task data
                const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
                let endpoint = '/tasks';
                 
                if (userId && roleId && roleId == '2') {
                    endpoint = `/tasks&id=${userId}`;
                } else if (userId && roleId && roleId == '3') {
                    endpoint = `/tasks&assignee_id=${userId}`;
                } else if (clientId) {
                    endpoint = `/tasks&clientId=${clientId}`;
                }

                // const url = clientId > 0 ? `${baseURL}${endpoint}&clientId=${clientId}` : `${baseURL}${endpoint}`;
                const url = `${baseURL}${endpoint}`;

                const response = await api.get(
                    url,
                    { headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` } }
                );

                console.log("--TASKS ---", response);
                // Set the data in state
                setTasks(response.data);
            } catch (error) {
                // Handle errors
                setError(error.message || 'Error fetching profile data');
            } finally {
                // Turn off loading once the process completes
                setLoading(false);
            }
        };

        if (token) {
            getTask();
        } else {
            setError(' Token is missing');
            setLoading(false);
        }
    }, []);
  
    // Return the necessary state variables
    return { Tasks, setTasks, loading, error };
};

// Hook for add/update a Task
const useAddUpdateTask = () => {
    
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    
    const addUpdateTask = async (taskData, setTasks) => {

        const token = localStorage.getItem('jwttoken');
        const userId = localStorage.getItem('id');
        const roleId = localStorage.getItem('roleId');
        console.log("----taskData =", taskData);
        
        try {
            if (!userId || !token) {
                throw new Error('User ID or Token is missing');
            }

            const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
            let endpoint = `/tasks`;

            if (userId && roleId && roleId !== 1) {
                endpoint = `/tasks&id=${userId}`;
            }
            console.log("-ENDPOINNT = ", endpoint);
            
            const url = `${baseURL}${endpoint}`;
            setLoading(true);

            const response = await api.put(url, taskData, {
                headers: { 'Content-Type': 'multipart/form-data', 'Authorization': `Bearer ${token}` }
            });

            console.log("-add update task -----response.data = ", response);
            // console.log("-add update task -response.data.STATUSCOD = ", response.data.STATUSCODE);
            // debugger;

            if (response.data.STATUSCODE == 201) {
                setTasks(response.data.TASKS);
                toast.success(response.data.DATA.message);
            } else {
                toast.error(response.data.DATA.message);
            }

            return response.data.TASKS; // Return the updated task data
        } catch (error) {
            toast.error('Failed');
            setError(error.message || 'Error updating task data');
            throw error; // Re-throw to handle it in the calling component if needed
        } finally {
            setLoading(false);
        }
    };

    return { addUpdateTask, loading, error };
};

// Export all hooks
export { useTasks, useAddUpdateTask };