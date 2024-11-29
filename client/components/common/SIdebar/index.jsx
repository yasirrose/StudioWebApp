"use client"; // Import as a client component since it uses state
import { useState, useEffect } from "react";
import { useRouter } from "next/router";
import { CgMenuRightAlt } from "react-icons/cg";
import {
    IoSpeedometerOutline,
    IoPersonOutline,
    IoPeopleOutline,
    IoBriefcaseOutline,
    IoCalendarOutline,
    IoLogOutOutline,
    IoKeyOutline
} from "react-icons/io5";
import { useTheme } from "../../../context/ThemeContext";
import styles from "./Sidebar.module.scss";
import { useFetchMenuPermissions } from "../../../hooks/permissions";

const Sidebar = ({ collapsed, setCollapsed }) => {
    const { menuPermissions, loading, error } = useFetchMenuPermissions();
    const router = useRouter();
    const { pathname } = router; // Get the current path
    const { isDarkMode } = useTheme();

    const [userRoleId, setUserRoleId] = useState(null);

    // Fetch roleId from localStorage on mount
    useEffect(() => {
        const roleId = localStorage.getItem("roleId");
        if (roleId) {
            setUserRoleId(parseInt(roleId)); // Ensure roleId is a number
        }
    }, []);

    // Filter menus based on user role and access
    const filteredMenus = userRoleId && menuPermissions
    ? menuPermissions.filter(menu => menu.ROLES.some(role => role.ROLE_ID === userRoleId && role.HAS_ACCESS === 1))
    : [];


    const isActive = (href) => (pathname === href ? styles.active : "");
    const handleNavigation = (path) => router.push(path);

    // Map icons to menu names
    const menuIcons = {
        Dashboard: <IoSpeedometerOutline className={styles.icon} />,
        Users: <IoPeopleOutline className={styles.icon} />,
        Clients: <IoPersonOutline className={styles.icon} />,
        "Client Projects": <IoBriefcaseOutline className={styles.icon} />,
        "Project Tasks": <IoBriefcaseOutline className={styles.icon} />,
        "Scheduled Tasks": <IoCalendarOutline className={styles.icon} />,
        Permissions: <IoKeyOutline className={styles.icon} />,
    };

    // Utility function to format menu names into paths
    const formatPath = (menuName) => {
        return menuName
        .split(" ")
        .map((word, index) => (index === 0 ? word.toLowerCase() : word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()))
        .join("");
    };

    return (
        <aside
            className={`${styles.sidebar} ${collapsed ? styles.collapsed : ""} ${
                isDarkMode ? styles.darkMode : styles.lightMode
            }`}
        >
            <div className={styles.logoContainer}>
                <div className={styles.logo}>
                    <a href="#" className={styles.appSidebarLogo}>
                        <div className={styles.iplogoOuter}>
                            <div className={styles.iplogoInner}>
                                <div className={styles.iplogoWhitetopleft}>
                                    <div className={styles.tlball}></div>
                                </div>
                                <div className={styles.iplogoTopright}></div>
                                <div className={styles.clear}></div>
                                <div className={styles.iplogoMiddleleft}></div>
                                <div className={styles.iplogoMiddleright}></div>
                                <div className={styles.clear}></div>
                                <div className={styles.iplogoBottomleft}></div>
                            </div>
                        </div>
                    </a>
                </div>
                <button
                    onClick={() => setCollapsed(!collapsed)}
                    className={`${styles.sidebarToggle} ${
                        collapsed ? styles.collapsed : ""
                    } btn btn-sm btn-icon bg-light btn-color-gray-700 btn-active-color-primary`}
                >
                    <CgMenuRightAlt
                        className={`${styles.Icon} ${collapsed ? styles.IconRotated : ""}`}
                    />
                </button>
            </div>

            {/* Loader or Error State */}
            {(loading || !userRoleId) && (
                <div className={styles.loaderContainer}>
                    <p>Loading Sidebar...</p>
                </div>
            )}
            {error && (
                <div className={styles.errorContainer}>
                    <p>Error loading menu permissions.</p>
                </div>
            )}

            {/* Menu Rendering */}
            {!loading && userRoleId && (
                <div className={styles.menuContainer}>
                    <ul className={styles.menuItems}>
                        {filteredMenus.map((menu) => {
                            const path = `/${formatPath(menu.MENU_NAME)}`;
                            return (
                                <li
                                    key={menu.MENU_ID}
                                    className={`${styles.menuItem} ${isActive(path)}`}
                                    onClick={() => handleNavigation(path)}
                                >
                                    {menuIcons[menu.MENU_NAME]} {!collapsed && menu.MENU_NAME}
                                </li>
                            );
                        })}
                        <li className={styles.menuItem} onClick={() => handleNavigation("/Auth")}>
                            <IoLogOutOutline className={styles.icon} /> {!collapsed && "Logout"}
                        </li>
                    </ul>
                </div>
            )}
        </aside>
    );
};

export default Sidebar;
