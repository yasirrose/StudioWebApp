"use client";
import Image from "next/image";
import styles from "./header.module.scss";
import { useTheme } from '../../../context/ThemeContext';
import { signOut } from "next-auth/react";
import { useRouter } from 'next/router';
import getDecodedToken from '/utils/jwtToken';
import { useState, useEffect } from 'react';
import { FiSun, FiMoon } from 'react-icons/fi';

const ProfileDropdown = () => {
    const router = useRouter();
    const [tokenData, setTokenData] = useState(null);
    const { isDarkMode, toggleTheme } = useTheme();

    useEffect(() => {
        const token = localStorage.getItem('jwttoken');
        if (token) {
            const decodedToken = getDecodedToken(token);
            setTokenData(decodedToken);
        }
    }, []);

    const handleLogout = async () => {
        // localStorage.removeItem("jwttoken");
        // localStorage.removeItem("id");
        await signOut({ redirect: false });
        router.push('/Auth');
    };

    const handleNavigation = async (path) => {
        if (path == '/userProfile') {
            localStorage.removeItem('client_userId');
        } else {
            // localStorage.removeItem("jwttoken");
            // localStorage.removeItem("id");
            await signOut({ redirect: false });
        }
        router.push(path);
    };

    return (
        <div className={`${styles.dropdown} ${isDarkMode ? styles.darkMode : styles.lightMode}`}>
            <button className={`${styles.DropdownBtn} focus:outline-none`}>
                <Image
                    src="/images/profile-icon.png"
                    alt="Profile"
                    width={40}
                    height={40}
                    className="rounded-full"
                />
            </button>
            <div className={styles.dropdownMenu}>
                <div className={`${styles.menuItem} px-3`}>
                    <div className={`${styles.menuContent} d-flex align-items-center px-0 mb-2`}>
                        <div className="symbol symbol-50px me-5">
                            <Image
                                src="/images/profile-icon.png"
                                alt="Logo"
                                width={50}
                                height={50}
                                className="rounded-full"
                            />
                        </div>
                        <div className="d-flex flex-column">
                            <div className="fw-bold d-flex align-items-center fs-5">
                                {tokenData?.NAME}
                                <span className="badge badge-light-success fw-bold fs-8 px-2 py-1 ms-2">
                                    {tokenData?.ROLE}
                                </span>
                            </div>
                            <a href="#" className="fw-semibold text-muted text-hover-primary fs-7">
                                {tokenData?.EMAIL}
                            </a>
                        </div>
                    </div>
                </div>
                
                {/* <div className={styles.dropdownMenuList}>
                    <button onClick={() => handleNavigation('/userProfile')} className={styles.dropdownLink}>
                        My Profile
                    </button>
                    <button onClick={() => handleNavigation('/auth')} className={styles.dropdownLink}>
                        Logout
                    </button>
                </div> */}


                <div className={styles.dropdownMenuList}>
                <div className={styles.dropdownbuttons}>
                    <button onClick={() => handleNavigation('/userProfile')} className={styles.dropdownLink}>
                    My Profile
                    </button>
                </div>
                <div className={styles.themeDropdownContainer}>
                    <button className={styles.themeToggleBtn}>
                    Mode
                    </button>
                    <div className={styles.innerDropdown}>
                    <button onClick={() => toggleTheme("light")} className={styles.innerDropdownLink}>
                        <FiSun style={{ marginRight: '8px' }} /> Light
                    </button>
                    <button onClick={() => toggleTheme("dark")} className={styles.innerDropdownLink}>
                        <FiMoon style={{ marginRight: '8px' }} /> Dark
                    </button>
                    </div>
                </div>
                <div className={styles.dropdownbuttons}>
                    <button onClick={() => handleNavigation('/auth')} className={styles.dropdownLink}>
                    Logout
                    </button>
                </div>
                </div>

            </div>
        </div>
    );
};

export default ProfileDropdown;
