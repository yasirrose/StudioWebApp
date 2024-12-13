"use client"; // Import as a client component since it uses state
import { useState, useEffect } from "react";
import { signOut } from "next-auth/react";
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
import Link from "next/link";
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";
import { useTheme } from "../../../context/ThemeContext";
import styles from "./Sidebar.module.scss";
import { useFetchMenuPermissions } from "../../../hooks/permissions";

const DynamicIcon = ({ icon: Icon }) => <Icon className={styles.icon} />;

const Sidebar = ({ collapsed, setCollapsed }) => {
    const { menuPermissions, loading: menuLoading, error } = useFetchMenuPermissions();
    const router = useRouter();
    const { pathname } = router; // Get the current path
    const { theme, isDarkMode } = useTheme();
    const [loading, setLoading] = useState(true);

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

    // if (filteredMenus.length < 0) {
    //     debugger;
    // } else {

    // }

    const isActive = (href) => (pathname === href ? styles.active : "");

    const handleSignout = async (path) => {
        localStorage.clear();
        await signOut({ redirect: false });
        router.push(path);
    };

    // useEffect(() => {
    //     // Simulate loading only on the first site load
    //     const firstLoad = localStorage.getItem("firstLoad");
    //     if (!firstLoad) {
    //         localStorage.setItem("firstLoad", "true");
    //         const timer = setTimeout(() => setLoading(false), 2000); // Simulate 2s loading
    //         return () => clearTimeout(timer);
    //     } else {
    //         setLoading(false);
    //     }
    // }, []);

    // Map icons to menu names (store component references, not JSX)
    const menuIcons = {
        Dashboard: IoSpeedometerOutline,
        Users: IoPeopleOutline,
        Clients: IoPersonOutline,
        "Client Projects": IoBriefcaseOutline,
        "Project Tasks": IoBriefcaseOutline,
        "Scheduled Tasks": IoCalendarOutline,
        Permissions: IoKeyOutline,
    };


    // Utility function to format menu names into paths
    const formatPath = (menuName) => {
        return menuName
        .split(" ")
        .map((word, index) => (index === 0 ? word.toLowerCase() : word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()))
        .join("");
    };

    // if (loading) {
    //     // Show Skeleton Loader while loading
    //     return (
    //         <aside className={styles.sidebar}>
    //             <div className={styles.logoContainer}>
    //                 <Skeleton height={32} width="100%" />
    //             </div>
    //             <div className={styles.menuContainer}>
    //                 <ul className={styles.menuItems}>
    //                     {[...Array(7)].map((_, i) => (
    //                         <li key={i} className={styles.skeletonMenuItem}>
    //                             <Skeleton height={40} width="90%" />
    //                         </li>
    //                     ))}
    //                 </ul>
    //             </div>
    //         </aside>
    //     );
    // }

    return (
        <aside
            className={`${styles.sidebar} ${
                collapsed ? styles.collapsed : ""
            } ${theme === "system" ? styles.systemMode : isDarkMode ? styles.darkMode : styles.lightMode}`}
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
            {/* {(loading || !userRoleId) && (
                <div className={styles.loaderContainer}>
                    <p>Loading Sidebar...</p>
                </div>
            )} */}
            {/* {error && (
                <div className={styles.errorContainer}>
                    <p>Error loading menu permissions.</p>
                </div>
            )} */}

            {/* Menu Rendering */}
            {!menuLoading && userRoleId && (
                <div className={styles.menuContainer}>
                    <ul className={styles.menuItems}>
                        {filteredMenus.map((menu) => {
                            const path = `/${formatPath(menu.MENU_NAME)}`;
                            return (
                                <li key={menu.MENU_ID}>
                                    <Link
                                        href={path}
                                        className={`${styles.menuItem} ${isActive(path)}`}
                                    >
                                        <DynamicIcon icon={menuIcons[menu.MENU_NAME]} /> <span>{menu.MENU_NAME}</span>
                                    </Link>
                                </li>
                            );
                        })}

                        <li>
                            <Link
                                href="/Auth"
                                className={`${styles.menuItem} ${isActive("/Auth")}`}
                                onClick={() => handleSignout("/Auth")}
                            >
                                <DynamicIcon icon={IoLogOutOutline} /> <span>{"Logout"}</span>
                            </Link>
                        </li>
                    </ul>
                </div>
            )}
            {menuLoading || !userRoleId && (
                <>
                <div className={styles.logoContainer}>
                    <Skeleton height={32} width="100%" />
                </div>
                <div className={styles.menuContainer}>
                    <ul className={styles.menuItems}>
                        {[...Array(7)].map((_, i) => (
                            <li key={i} className={styles.skeletonMenuItem}>
                                <Skeleton height={40} width="90%" />
                            </li>
                        ))}
                    </ul>
                </div>
                </>
            )}
        </aside>
    );
};

export default Sidebar;
