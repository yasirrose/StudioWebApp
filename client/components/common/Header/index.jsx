import React, { useState, useEffect } from "react";
import ProfileDropdown from "./ProfileDropdown";
import { useTheme } from '../../../context/ThemeContext';
import styles from "./header.module.scss";
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";

const Header = () => {
    const { theme, isDarkMode } = useTheme();
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const firstLoad = localStorage.getItem("headerFirstLoad");
        if (!firstLoad) {
            localStorage.setItem("headerFirstLoad", "true");
            const timer = setTimeout(() => setLoading(false), 2000); // Simulate 2s loading
            return () => clearTimeout(timer);
        } else {
            setLoading(false);
        }
    }, []);

    if (loading) {
        return (
            <header className={`${styles.header} ${theme === "system" ? styles.systemMode : isDarkMode ? styles.darkMode : styles.lightMode}`}>
                <div className={`${styles.headerTop} d-flex justify-content-between items-center`}>
                    <div  className={`${styles.dropdown} focus:outline-none`}>
                        <Skeleton circle height={45} width={35} />
                    </div>
                </div>
            </header>
        );
    }

    return (
        <header className={`${styles.header} ${theme === "system" ? styles.systemMode : isDarkMode ? styles.darkMode : styles.lightMode}`}>
            <div className={`${styles.headerTop} d-flex justify-content-between items-center`}>
                <ProfileDropdown />
            </div>
        </header>
    );
};

export default Header;
