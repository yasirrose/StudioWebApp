import React, { useState, useEffect } from 'react';
import Header from '../../components/common/Header';
import Footer from '../../components/common/Footer';
import Sidebar from '../../components/common/Sidebar';
import styles from './permissions.module.scss'; // Ensure styles are updated
import { useTheme } from '../../context/ThemeContext';
import { useFetchMenuPermissions, useUpdateMenuPermission, useFetchActionPermissions, useUpdateActionPermission } from '/hooks/permissions'; // Import the hooks
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

const PermissionsPage = () => {
    const { isDarkMode } = useTheme();

    // Fetch Menu Permissions using the hook
    const { menuPermissions, loading: menuLoading, error: menuError } = useFetchMenuPermissions();
    const { updateMenuPermission } = useUpdateMenuPermission();

    // Fetch Action Permissions using the hook
    const { actionPermissions, loading: actionLoading, error: actionError } = useFetchActionPermissions();
    const { updateActionPermission } = useUpdateActionPermission();

    // State to hold roles
    const [roles, setRoles] = useState([]);

    // State to hold updated permissions (locally)
    const [updatedMenuPermissions, setUpdatedMenuPermissions] = useState([]);
    const [updatedActionPermissions, setUpdatedActionPermissions] = useState([]);

    // Fetch and calculate roles when menuPermissions changes
    useEffect(() => {
        if (menuPermissions) {
            const uniqueRoles = [...new Set(menuPermissions.flatMap((menu) => menu?.ROLES?.map((role) => role?.ROLE_NAME) || []))];
            setRoles(uniqueRoles);

            // Initialize updated permissions state with current permissions
            setUpdatedMenuPermissions(menuPermissions);
        }
    }, [menuPermissions]);  // Only run when menuPermissions changes

    // Initialize action permissions when actionPermissions data is fetched
    useEffect(() => {
        if (actionPermissions) {
            setUpdatedActionPermissions(actionPermissions);
        }
    }, [actionPermissions]);

    // Toggle function for page permissions (menu permissions)
    const handlePagePermissionChange = (menuId, roleId, currentAccess) => {
        // Update the local state
        const updatedPermissions = updatedMenuPermissions.map((menu) => {
            if (menu.MENU_ID === menuId) {
                const updatedRoles = menu.ROLES.map((role) => {
                    if (role.ROLE_ID === roleId) {
                        return { ...role, HAS_ACCESS: currentAccess ? 0 : 1 };
                    }
                    return role;
                });
                return { ...menu, ROLES: updatedRoles };
            }
            return menu;
        });

        setUpdatedMenuPermissions(updatedPermissions);

        // Immediately update via API
        const permissionToUpdate = {
            menu_id: menuId,
            role_id: roleId,
            has_access: currentAccess ? 0 : 1
        };
        updateMenuPermission(permissionToUpdate);
    };

    // Toggle function for action permissions
    const handleActionPermissionChange = (actionId, roleId, currentAccess) => {
        // Update the local state
        const updatedPermissions = updatedActionPermissions.map((action) => {
            if (action.ACTION_ID === actionId) {
                const updatedRoles = action.ROLES.map((role) => {
                    if (role.ROLE_ID === roleId) {
                        return { ...role, HAS_ACCESS: currentAccess ? 0 : 1 };
                    }
                    return role;
                });
                return { ...action, ROLES: updatedRoles };
            }
            return action;
        });

        setUpdatedActionPermissions(updatedPermissions);

        // Immediately update via API
        const permissionToUpdate = {
            action_id: actionId,
            role_id: roleId,
            has_access: currentAccess ? 0 : 1
        };
        updateActionPermission(permissionToUpdate);
    };

    // Render Permission Cell with Editable Checkbox
    const renderPermissionCell = (isAllowed, menuId, roleId, onChangeHandler, isDisabled=false) => (
        <div className="form-group mb-0">
            <label className="form-check form-check-custom form-check-solid">
                <input
                    type="checkbox"
                    className="form-check-input"
                    checked={isAllowed}
                    onChange={() => onChangeHandler(menuId, roleId, isAllowed)}
                    disabled={isDisabled}
                />
                <span className="form-check-label"></span>
            </label>
        </div>
    );

    const [collapsed, setCollapsed] = useState(false);

    return (
        <div className={`main-screen ${isDarkMode ? 'darkMode' : 'lightMode'}`}>
            <Sidebar collapsed={collapsed} setCollapsed={setCollapsed} />
            <div className={`main-content permistion-secreen ${collapsed ? 'collapsed' : ''}`}>
                <Header />
                <div className="app-main flex-column flex-row-fluid" id="kt_app_main">
                    <div className="content-section d-flex flex-column flex-column-fluid">
                        <ToastContainer />
                        <div id="kt_app_content" className="app-content flex-column-fluid">
                            <div id="kt_app_content_container" className="app-container container-fluid">
                                <div className="page-title d-flex flex-column justify-content-center fw-bold fs-3 m-0 mb-4">
                                    Permissions
                                </div>
                                {menuLoading || actionLoading ? (
                                    <div>Loading...</div>
                                ) : menuError || actionError ? (
                                    <div>Error loading permissions</div>
                                ) : (
                                    <div>
                                        {/* Page Permissions Table */}
                                        <div className="card mb-5">
                                            <div className="card-header min-h-0 border-0 pt-6">
                                                <h3 className="card-title">Page/Module Permissions</h3>
                                            </div>
                                            <div className={`card-body pt-0 pb-5 ${isDarkMode ? styles.darkTable : ''}`}>
                                                <table className={`table-bordered ${styles.table}`}>
                                                    <thead>
                                                        <tr>
                                                            <th>Page/Module</th>
                                                            {roles.map((role, index) => (
                                                                <th key={index}>{role}</th>
                                                            ))}
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        {updatedMenuPermissions?.map((perm, index) => (
                                                            <tr key={index}>
                                                                <td>{perm.MENU_NAME}</td>
                                                                {roles.map((role) => {
                                                                    const rolePermission = perm.ROLES.find(
                                                                        (r) => r.ROLE_NAME === role
                                                                    );
                                                                    let isDisabled = false;
                                                                    if (perm.MENU_NAME === "Dashboard") {
                                                                        isDisabled = true;
                                                                    } else if (perm.MENU_NAME === "Users" && role != "Super Admin") {
                                                                        isDisabled = true;
                                                                    } else if ((perm.MENU_NAME === "Clients" || perm.MENU_NAME === "Client Projects") && role === "Client User") {
                                                                        isDisabled = true;
                                                                    } else if (perm.MENU_NAME === "Permissions") {
                                                                        isDisabled = true;
                                                                    }

                                                                    return (
                                                                        <td key={`${index}-${role}`}>
                                                                            {renderPermissionCell(
                                                                                rolePermission?.HAS_ACCESS === 1,
                                                                                perm.MENU_ID,
                                                                                rolePermission?.ROLE_ID,
                                                                                handlePagePermissionChange,
                                                                                isDisabled
                                                                            )}
                                                                        </td>
                                                                    );
                                                                })}
                                                            </tr>
                                                        ))}
                                                    </tbody>
                                                </table>
                                            </div>
                                        </div>

                                        {/* Action-Level Access Table */}
                                        <div className="card">
                                            <div className="card-header min-h-0 border-0 pt-6">
                                                <h3 className="card-title">Action-Level Access</h3>
                                            </div>
                                            <div className={`card-body pt-0 pb-5 ${isDarkMode ? styles.darkTable : ''}`}>
                                                <table className={`table-bordered ${styles.table}`}>
                                                    <thead>
                                                        <tr>
                                                            <th>Action</th>
                                                            {roles.map((role, index) => (
                                                                <th key={index}>{role}</th>
                                                            ))}
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        {updatedActionPermissions?.map((perm, index) => (
                                                            <tr key={index}>
                                                                <td>{perm.ACTION_NAME}</td>
                                                                {roles.map((role) => {
                                                                    const rolePermission = perm.ROLES.find(
                                                                        (r) => r.ROLE_NAME === role
                                                                    );

                                                                    let isDisabled = false;
                                                                    if ((perm.ACTION_NAME.includes("Client") || perm.ACTION_NAME.includes("Project") || perm.ACTION_NAME.includes("User")) && role === "Client User") {
                                                                        isDisabled = true;
                                                                    } else if (perm.ACTION_NAME.includes("User") && role === "Admin") {
                                                                        isDisabled = true;
                                                                    } else if (role === "Super Admin") {
                                                                        isDisabled = true;
                                                                    }

                                                                    return (
                                                                        <td key={`${index}-${role}`}>
                                                                            {renderPermissionCell(
                                                                                rolePermission?.HAS_ACCESS === 1,
                                                                                perm.ACTION_ID,
                                                                                rolePermission?.ROLE_ID,
                                                                                handleActionPermissionChange,
                                                                                isDisabled
                                                                            )}
                                                                        </td>
                                                                    );
                                                                })}
                                                            </tr>
                                                        ))}
                                                    </tbody>
                                                </table>
                                            </div>
                                        </div>
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>
                </div>
                <Footer />
            </div>
        </div>
    );
};

export default PermissionsPage;
