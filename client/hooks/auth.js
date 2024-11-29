import { useState, useEffect, useCallback } from 'react';
import axios from 'axios';

const useSignUp = () => {
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [signUpUser, setsignUpUser] = useState(null);
    
    const signUp = async (first_name, last_name, email, password) => {
        setLoading(true);
        setError(null);
        try {
            const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL;
            const endpoint = `/auth/signup`;
            const url = `${baseURL}${endpoint}`;
            
            const response = await axios.put(
                url,
                { first_name, last_name, email, password },
                { headers: { 'Content-Type': 'application/json' } }
            );
            // console.log("---response.data = ", response.data);
            
            
            setsignUpUser(response.data);
        } catch (err) {
            setError(err.response ? err.response.data : err.message);
        } finally {
            setLoading(false);
        }
    };
    
    // return { signUp, signUpUser };
    return { signUp, signUpUser, loading, error };
};

export {useSignUp}
