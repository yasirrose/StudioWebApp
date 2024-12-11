"use client";
import Image from "next/image";
import styles from "./header.module.scss";
import { useTheme } from '../../../context/ThemeContext';
import { signOut } from "next-auth/react";
import { useRouter } from 'next/router';
import getDecodedToken from '/utils/jwtToken';
import { useState, useEffect } from 'react';
import { FiSun, FiMoon, FiMonitor } from 'react-icons/fi';

const ProfileDropdown = () => {
    const router = useRouter();
    const [tokenData, setTokenData] = useState(null);
    const { theme, isDarkMode, toggleTheme } = useTheme();

    useEffect(() => {
        const token = localStorage.getItem('jwttoken');
        if (token) {
            const decodedToken = getDecodedToken(token);
            setTokenData(decodedToken);
        }
    }, []);

    const handleNavigation = async (path) => {
        if (path == '/userProfile') {
            localStorage.removeItem('client_userId');
        } else {
            localStorage.clear();
            await signOut({ redirect: false });
        }
        router.push(path);
    };

    const handleThemeChange = (newTheme) => {
        if (newTheme === "system") {
            toggleTheme("system"); // Set theme as "system" to persist
        } else {
            toggleTheme(newTheme);
        }
      };

    // Determine the icon to display based on the current theme
    const getThemeIcon = () => {
        if (theme === "light") return <FiSun />;
        if (theme === "dark") return <FiMoon />;
        if (theme === "system") return <FiMonitor />;
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
                <div className={`${styles.menuItem}`}>
                    <div className={`${styles.menuContent} d-flex align-items-center px-0`}>
                        <div className={`${styles.symbol} me-5`}>
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
                        <span>Mode</span> {getThemeIcon()}
                    </button>
                    <div className={styles.innerDropdown}>
                        <button onClick={() => handleThemeChange("light")} className={styles.innerDropdownLink}>
                            <FiSun style={{ marginRight: "8px" }} /> Light
                        </button>
                        <button onClick={() => handleThemeChange("dark")} className={styles.innerDropdownLink}>
                            <FiMoon style={{ marginRight: "8px" }} /> Dark
                        </button>
                        <button onClick={() => handleThemeChange("system")} className={styles.innerDropdownLink}>
                            <FiMonitor style={{ marginRight: "8px" }} /> System
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
