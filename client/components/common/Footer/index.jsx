import React, { useState, useEffect } from 'react';
import { useTheme } from '../../../context/ThemeContext';
import styles from './footer.module.scss';
import Skeleton from 'react-loading-skeleton';
import 'react-loading-skeleton/dist/skeleton.css';

const Footer = () => {
    const { theme, isDarkMode } = useTheme();
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const firstLoad = localStorage.getItem("footerFirstLoad");
        if (!firstLoad) {
        localStorage.setItem("footerFirstLoad", "true");
        const timer = setTimeout(() => setLoading(false), 2000); // Simulate 2s loading
        return () => clearTimeout(timer);
        } else {
        setLoading(false);
        }
    }, []);

    if (loading) {
        return (
            <div className={`${styles.appFooter} ${theme === "system" ? styles.systemMode : isDarkMode ? styles.darkMode : styles.lightMode}`}>
                <div className="app-container container-fluid d-flex flex-column flex-md-row flex-center flex-md-stack py-3">
                    <div className="order-2 order-md-1">
                        <Skeleton width={150} height={20} />
                    </div>
                    <ul className="menu menu-gray-600 menu-hover-primary fw-semibold order-1">
                        <li className="menu-item">
                            <Skeleton width={70} height={20} />
                        </li>
                        <li className="menu-item">
                            <Skeleton width={70} height={20} />
                        </li>
                        <li className="menu-item">
                            <Skeleton width={70} height={20} />
                        </li>
                    </ul>
                </div>
            </div>
        );
    }

    return (
        <div className={`${styles.appFooter} ${theme === "system" ? styles.systemMode : isDarkMode ? styles.darkMode : styles.lightMode}`}>
            <div className="app-container container-fluid d-flex flex-column flex-md-row flex-center flex-md-stack py-3">
                <div className="text-gray-900 order-2 order-md-1">
                    <span className="text-muted fw-semibold me-1">2024©</span>
                    <a href="https://www.interactivepulse.co.nz/" target="_blank" className="text-gray-800 text-hover-primary">
                        Interactive Pulse
                    </a>
                </div>
                <ul className="menu menu-gray-600 menu-hover-primary fw-semibold order-1">
                    <li className="menu-item"><a href="#" target="_blank" className="menu-link px-2">About</a></li>
                    <li className="menu-item"><a href="#" target="_blank" className="menu-link px-2">Support</a></li>
                    <li className="menu-item"><a href="#" target="_blank" className="menu-link px-2">Purchase</a></li>
                </ul>
            </div>
        </div>
    );
};

export default Footer;
