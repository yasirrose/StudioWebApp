import React from 'react';
import { useState, useEffect } from 'react';
import Sidebar from "../../components/common/Sidebar";
import Header from "../../components/common/Header";
import Footer from "../../components/common/Footer";
import UserProfile from "../../components/Shared/UserProfile/UserProfile";
import EditProfile from "../../components/Shared/UserProfile/EditProfile/EditProfile";
import { IoCheckmarkCircleOutline, IoPersonOutline, IoLocationOutline, IoMailOutline } from 'react-icons/io5';
import { useUserProfile } from '/hooks/userProfile';
import { useRouter } from 'next/router';
import { useTheme } from '../../context/ThemeContext';

const Profile = () => {
    const { profileData: allUsers, setProfileData, loading, error } = useUserProfile(); // Use the custom hook
    const [isEditProfile, setIsEditProfile] = useState(false);
    const [isToken, setIsToken] = useState(true);
    const router = useRouter();
    const { query } = router;
    const [isFiltering, setIsFiltering] = useState(true);
    const [filteredProfile, setFilteredProfile] = useState([]);

    const user_id = router?.query?.id;

    useEffect(() => {
        setIsEditProfile(query?.mode === 'edit' || query?.mode === 'add');

        if (allUsers) {
            console.log("-------user_id = ", user_id);
            let id = localStorage.getItem('id')
            console.log("-------id = ", id);
            let filteredList = [];
            if (user_id) {
                filteredList = allUsers.filter(pro => pro.user_id.toString() === user_id.toString());
                console.log("-1---filteredList = ", filteredList);

                setFilteredProfile(filteredList);
                setIsFiltering(false);
            } else {
                filteredList = allUsers.filter(pro => pro.user_id.toString() === id.toString());
                console.log("-2---filteredList = ", filteredList);
                
                setFilteredProfile(filteredList);
                setIsFiltering(false);
            }
        }
    }, [user_id, allUsers]);

    useEffect(() => {
        // Function to check for token availability
        // console.log("----userpeoifel index ---query =", query);

        // Set edit mode based on query parameters
        setIsEditProfile(query?.mode === 'edit' || query?.mode === 'add');

        const checkToken = () => {
            const token = localStorage.getItem('jwttoken');
            setIsToken(!!token); // Converts the token to a boolean

            const interval = setInterval(() => {
                const token = localStorage.getItem('jwttoken');
                if (token) {
                    setIsToken(true);
                    clearInterval(interval);
                }
            }, 500);
            return () => clearInterval(interval);
        };
        checkToken();
    }, [query]); // Add query to dependency array

    const [collapsed, setCollapsed] = useState(false);
    const { isDarkMode } = useTheme();

    return (
        <>
            <div className={`main-screen ${isDarkMode ? 'darkMode' : 'lightMode'}`}>
                <Sidebar collapsed={collapsed} setCollapsed={setCollapsed} />
                <div className={`main-content ${collapsed ? 'collapsed' : ''}`}>
                    <Header />
                    {isToken && (
                        <>
                            { !isFiltering && isEditProfile && !loading && (
                                <EditProfile 
                                    profileData={isEditProfile && query?.mode === 'add' ? [] : filteredProfile} 
                                    setProfileData={setFilteredProfile} 
                                    setIsEditProfile={setIsEditProfile} 
                                />
                            )}
                            { !isFiltering && !isEditProfile && !loading && (
                                <UserProfile profileData={filteredProfile} loading={loading} error={error} setIsEditProfile={setIsEditProfile} />
                            )}
                            <Footer />
                        </>
                    )}
                </div>
            </div>
        </>
    );
};

export default Profile;
