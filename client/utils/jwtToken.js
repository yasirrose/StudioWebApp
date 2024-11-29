import jwt from 'jsonwebtoken';
// import {useLoading } from '/context/LoadingContext';
const getDecodedToken = () => {
    // const { setLoading } = useLoading();
    // setLoading(false);
    if( typeof localStorage === "undefined" ) return null;

    try {

        // Retrieve the token from local storage
        const token = localStorage.getItem('jwttoken');
        if (!token) {
            return null;
        }
        
        const decodedPayload = jwt.decode(token);

        // Parse the JSON payload
        return decodedPayload;
    } catch (error) {
        console.error('Error decoding JWT token:', error);
        return null;
    }
};

export default getDecodedToken;
