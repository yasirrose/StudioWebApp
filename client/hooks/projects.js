import { useState, useEffect } from 'react';
import axios from 'axios';
import api from '/utils/api';
import { toast } from 'react-toastify';


// Hook for fetching users
const useFetchProjects = () => {
    const [Projects, setProjects] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        const token = localStorage.getItem('jwttoken');
        const id = localStorage.getItem('id');
        const roleId = localStorage.getItem('roleId');

        const getProjects = async () => {
            try {
                const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
                let endpoint = '/projects';
                if (id && roleId && roleId !== '1') {
                    endpoint = `/projects&id=${id}`;
                }
                const url = `${baseURL}${endpoint}`;

                const response = await api.get(url, {
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${token}`
                    }
                });
                // console.log("--projects---response.data  = ", response.data);

                setProjects(response.data);
            } catch (error) {
                setError(error.message || 'Error fetching project data');
            } finally {
                setLoading(false);
            }
        };

        if (token) {
            getProjects();
        } else {
            setError('Token is missing');
            setLoading(false);
        }
    }, []);

    return { Projects, setProjects, loading, error };
};

// Hook for deleting a user
const useDeleteProject = () => {
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const deleteProject = async (id, setProjects) => {
        setLoading(true);
        try {
            const token = localStorage.getItem('jwttoken');
            const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
            const endpoint = '/projects';
            const url = `${baseURL}${endpoint}`;

            const response = await api.delete(url, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                data: {
                    project_id: id
                }
            });

            console.log("--project delete--response = ", response);
            // Call the setProjects function to update the users state in the parent component
            toast.success('Project deleted successfully');
            setProjects(prevProjects => prevProjects.filter(project => project.project_id !== id));
        } catch (error) {
            toast.error('Failed to delete project');
            console.error('Error deleting project:', error);
            setError('Error deleting project');
        } finally {
            setLoading(false);
        }
    };

    return { loading, error, deleteProject };
};

// Hook for activating/deactivating a user
const useActivateDeactivateProject = () => {
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const activateDeactivateProject = async (id, active, setProjects) => {
        
        setLoading(true);
        try {
            const token = localStorage.getItem('jwttoken');
            const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
            const endpoint = '/projects';
            const url = `${baseURL}${endpoint}`;

            const response = await api.patch(url, {
                project_id: id,
                active: active
            }, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                }
            });

            console.log("--project active--response = ", response);
            // Call the setProjects function to update the project active status in the parent component

            setProjects(prevProjects => prevProjects.map(project => project.project_id === id ? { ...project, project_active: active === 1 } : project));
            toast.success(`Project ${active === 1 ? 'activated' : 'deactivated'} successfully`);
        } catch (error) {
            console.error('Error activating/deactivating project:', error);
            setError('Error activating/deactivating project');
            toast.error(`Failed to ${active === 1 ? 'activate' : 'deactivate'} project`);
        } finally {
            setLoading(false);
        }
    };

    return { loading, error, activateDeactivateProject };
};

// Hook for add/update a project
const useAddUpdateProject = () => {
    
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    
    const addUpdateProject = async (projectData, setProjects) => {

        const token = localStorage.getItem('jwttoken');
        const userId = localStorage.getItem('id');

        try {
            if (!userId || !token) {
                throw new Error('User ID or Token is missing');
            }

            const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
            const endpoint = `/projects`;
            const url = `${baseURL}${endpoint}`;
            setLoading(true);

            const response = await api.put(url, projectData, {
                headers: { 'Content-Type': 'multipart/form-data', 'Authorization': `Bearer ${token}` }
            });

            // console.log("-add update project ----projectData = ", projectData);
            // console.log("-add update project -----response.data = ", response);

            if (response.data.STATUSCODE == 201) {
                setProjects(response.data.PROJECTS);
                toast.success(response.data.DATA.message);
            } else {
                toast.error(response.data.DATA.message);
            }
            return response.data.PROJECTS; // Return the updated project data
        } catch (error) {
            toast.error('Failed');
            setError(error.message || 'Error updating project data');
            throw error; // Re-throw to handle it in the calling component if needed
        } finally {
            setLoading(false);
        }
    };

    return { addUpdateProject, loading, error };
};

// Export all hooks
export { useFetchProjects, useDeleteProject, useActivateDeactivateProject, useAddUpdateProject };





