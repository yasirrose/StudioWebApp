import React, { useState, useEffect } from 'react';
import Header from '../../components/common/Header';
import Footer from '../../components/common/Footer';
import Sidebar from '../../components/common/Sidebar';
import AddUserModal from '../../components/Shared/AddUserModal';
import DataTable from 'react-data-table-component';
import { FaChevronDown, FaSearch, FaPlus, FaFileExport } from 'react-icons/fa';
import styles from './users.module.scss';
import { useFetchUsers, useDeleteUser, useActivateDeactivateUser } from '/hooks/users';
import { useRouter } from 'next/router';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import Swal from 'sweetalert2';
import { GridLoader, ClimbingBoxLoader } from 'react-spinners';
import { useTheme } from '../../context/ThemeContext';
import { useFetchActionPermissions } from "../../hooks/permissions";

const Users = () => {
    const { Users, loading, error } = useFetchUsers(); // Fetch users via the hook
    const { deleteUser } = useDeleteUser(); // Use delete user hook
    const { activateDeactivateUser } = useActivateDeactivateUser(); // Use activate/deactivate hook
    const { actionPermissions } = useFetchActionPermissions();
    console.log("-----actionPermissions ", actionPermissions);

    const [users, setUsers] = useState([]); // Initialize state for users list
    const [searchTerm, setSearchTerm] = useState(''); // State for search input
    const [roleId, setRoleId] = useState(null);
    const router = useRouter();

    // If the fetched Users list is available, update the local users state
    useEffect(() => {
        if (Users) {
            setUsers(Users);
        }
    }, [Users]);

    useEffect(() => {
        const storedRoleId = localStorage.getItem("roleId");
        setRoleId(parseInt(storedRoleId, 10)); // Parse roleId from localStorage
    }, []);

    const hasAccessToAction = (menuName, actionName) => {
        // Find the menu object with the given MENU_NAME and ACTION_NAME
        const action = actionPermissions?.find(
            item => item.MENU_NAME === menuName && item.ACTION_NAME === actionName
        );

        // Check if the user's role has access to this action
        const role = action?.ROLES.find(role => role.ROLE_ID === roleId);
        return role?.HAS_ACCESS === 1; // Return true if the role has access
    };

    const canAddUser = hasAccessToAction("Users", "User -> Add User");
    const canEditUser = hasAccessToAction("Users", "User -> Update User");
    const canDeleteUser = hasAccessToAction("Users", "User -> Delete User");    

    // Filter users based on the search term
    const filteredUsers = users.filter(user => 
        (user.first_name + ' ' + user.last_name).toLowerCase().includes(searchTerm.toLowerCase())
    );

    const handleNavigation = (path, user_id) => {
        router.push(path)
    };
    
    const handleDelete = (userId, setUsers) => {
        Swal.fire({
            title: 'Are you sure?',
            text: "You won't be able to revert this!",
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#3085d6',
            cancelButtonColor: '#d33',
            confirmButtonText: 'Yes, delete it!'
        }).then((result) => {
            if (result.isConfirmed) {
                deleteUser(userId, setUsers);
                // Swal.fire(
                //     'Deleted!',
                //     'The user has been deleted.',
                //     'success'
                // );
            }
        });
    };

    const columns = [
        {
            name: 'User Name',
            selector: row => row.first_name + ' ' + row.last_name,
            sortable: true,
        },
        {
            name: 'User Email',
            selector: row => row.email,
            sortable: true,
        },
        {
            name: 'Phone',
            selector: row => row.phone,
            sortable: true,
        },
        {
            name: 'User Status',
            selector: row => row.user_active ? 'Active' : 'Inactive', // Simplified for sorting
            sortable: true,
            cell: row => (
              <span className={`badge ${row.user_active ? 'badge-light-success' : 'badge-light-danger'}`}>
                {row.user_active ? 'Active' : 'Inactive'}
              </span>
            ),
        },        
        {
            name: 'Type',
            selector: row => row.role_name,
            sortable: true,
        },
        {
        name: 'Actions',
        cell: row => (
            <div className={styles.dropdown}>
                <button className={`${styles.dropdownButton} ${isDarkMode ? styles.darkButton : styles.lightButton}`}>
                Actions <FaChevronDown className={styles.dropdownIcon} />
                </button>
                <div className={`${styles.dropdownContent} ${isDarkMode ? styles.darkDropdown : styles.lightDropdown}`}>
                    <button
                        className={`${styles.viewButton} ${isDarkMode ? styles.darkViewButton : styles.lightViewButton}`}
                        onClick={() => handleNavigation(`/userProfile?id=${row.user_id}&isEditProfile=false`, row.user_id)}
                    >
                        View Profile
                    </button>
                    { canEditUser && (
                        <button
                            className={`${styles.viewButton} ${isDarkMode ? styles.darkViewButton : styles.lightViewButton}`}
                            onClick={() => handleNavigation(`/userProfile?id=${row.user_id}&isEditProfile=true`, row.user_id)}
                        >
                            Edit Profile
                        </button>
                    )}
                    { canDeleteUser && (
                        <button
                            className={`${styles.deleteButton} ${isDarkMode ? styles.darkDeleteButton : styles.lightDeleteButton}`}
                            onClick={() => deleteUser(row.user_id, setUsers)}
                        >
                            Delete
                        </button>
                    )}
                    { canEditUser && (
                        <button
                            className={`${row.user_active ? styles.deactivateButton : styles.activateButton} ${isDarkMode ? styles.darkToggleButton : styles.lightToggleButton}`}
                            onClick={() => activateDeactivateUser(row.user_id, row.user_active ? 0 : 1, setUsers)}
                        >
                            {row.user_active ? 'Deactivate' : 'Activate'}
                        </button>
                    )}
                </div>
            </div>
        ),
        },
    ];

    const [collapsed, setCollapsed] = useState(false);
    const { isDarkMode } = useTheme();
    return (
        <div className={`main-screen ${isDarkMode ? 'darkMode' : 'lightMode'}`}>
            <Sidebar collapsed={collapsed} setCollapsed={setCollapsed} />
            <div className={`main-content ${collapsed ? 'collapsed' : ''}`}>
                <Header />
                <div className="app-main flex-column flex-row-fluid" id="kt_app_main">
                    <div className="content-section d-flex flex-column flex-column-fluid">
                        <ToastContainer/>
                        <div id="kt_app_content" className="app-content flex-column-fluid">
                            <div id="kt_app_content_container" className="app-container container-fluid">
                                <div className="app-toolbar-wrapper d-flex flex-stack flex-wrap gap-4 w-100">
                                    <div className="page-title d-flex flex-column justify-content-center gap-1 me-3">
                                        <h1 className="page-heading d-flex flex-column justify-content-center text-gray-900 fw-bold fs-3 m-0">
                                            Users
                                        </h1>
                                        <ul className="breadcrumb breadcrumb-separatorless fw-semibold fs-7 my-0">
                                            <li className="breadcrumb-item text-muted">
                                                <a href="/" className="text-muted text-hover-primary">Home</a>
                                            </li>
                                            <li className="breadcrumb-item">
                                                <span className="bullet bg-gray-500 w-5px h-2px"></span>
                                            </li>
                                            <li className="breadcrumb-item text-muted">Users</li>
                                        </ul>
                                    </div>
                                </div>
                                <div className="card mt-5">
                                    <div className="card-header border-0 pt-6">
                                        <div className="card-title">
                                            <div className="d-flex align-items-center position-relative my-1">
                                                <div className="search-field position-relative w-250px">
                                                <FaSearch className="position-absolute top-50 start-0 translate-middle-y" />
                                                <input
                                                    type="text"
                                                    placeholder="Search Users"
                                                    className="form-control form-control-solid ps-5"
                                                    onChange={e => setSearchTerm(e.target.value)}
                                                />
                                                </div>
                                            </div>
                                        </div>
                                        <div className="card-toolbar d-flex gap-3">
                                            <button className="btn btn-light-primary">
                                                <FaFileExport className="me-1" /> Export
                                            </button>
                                            { canAddUser && (
                                                <button className="btn btn-primary" onClick={() => handleNavigation('/userProfile?mode=add', 0)}>
                                                    <FaPlus className="me-1" /> Add New
                                                </button>
                                            )}
                                        </div>
                                    </div>

                                    <div className="card-body pt-0">
                                        {/* {loading ? (
                                            <div>Loading...</div>
                                        ) : error ? (
                                            <div>Error: {error}</div>
                                        ) : ( */}
                                            <DataTable
                                                columns={columns}
                                                data={filteredUsers}
                                                paginationPerPage={5}
                                                pagination
                                                highlightOnHover
                                                responsive
                                                progressPending={loading} // Show loading indicator while data is being fetched
                                                // progressComponent={<div>Loading...</div>} // Custom loading component
                                                progressComponent={<GridLoader color="#20e992" size={15} />}
                                            />
                                        {/* )} */}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <Footer />
                </div>
            </div>
        </div>
    );
};

export default Users;
