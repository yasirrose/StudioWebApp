import React, { useState, useEffect } from 'react';
import Header from '../../components/common/Header';
import Footer from '../../components/common/Footer';
import Sidebar from '../../components/common/Sidebar';
import DataTable from 'react-data-table-component';
import AddClientModal from '../../components/Shared/AddClientModal';
import { FaChevronDown, FaSearch, FaPlus, FaFileExport, FaChevronLeft, FaChevronRight } from 'react-icons/fa';
import { useClients, useAddUpdateClient, useDeleteClient, useActivateDeactivateClient } from '/hooks/clients';
import styles from './client.module.scss';
import { useRouter } from 'next/router';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import { useFetchUsers } from '/hooks/users';
import Swal from 'sweetalert2';
import { useTheme } from '../../context/ThemeContext';
import { useFetchActionPermissions } from "../../hooks/permissions";
import ReactPaginate from "react-paginate";

const Clients = () => {
    const { Users, loading:loadingUsers } = useFetchUsers(); // Fetch users via the hook
    const { Clients, loading, error } = useClients(); // Fetch clients data
    const { deleteClient } = useDeleteClient(); // Hook for deleting a client
    const { activateDeactivateClient } = useActivateDeactivateClient(); // Hook for activation/deactivation
    const { addUpdateClient } = useAddUpdateClient(); // Hook for activation/deactivation
    const { actionPermissions } = useFetchActionPermissions();
    const [users, setUsers] = useState([]);
    const [currentPage, setCurrentPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(5);
    const startIndex = currentPage * rowsPerPage;
    const [activeDropdown, setActiveDropdown] = useState(null);
    const [clients, setClients] = useState([]); // Initialize state for clients list
    const [searchTerm, setSearchTerm] = useState(''); // State for search input
    const [isModalOpen, setModalOpen] = useState(false);
    const [modalMode, setModalMode] = useState('add'); // 'add' or 'edit'
    const [selectedClient, setSelectedClient] = useState(null); // For edit mode
    const [roleId, setRoleId] = useState(null);
    const router = useRouter();

    const handlePageChange = (selectedPage) => {
        setCurrentPage(selectedPage.selected);
      };
      const handleDropdownToggle = (id) => {
        setActiveDropdown(activeDropdown === id ? null : id);
      };
    
      const handleRowsPerPageChange = (e) => {
        setRowsPerPage(Number(e.target.value));
        setCurrentPage(0); // Reset to the first page
      };
    // If the fetched clients list is available, update the local clients state
    useEffect(() => {
        if (Clients){
            setClients(Clients);
        } 
    }, [Clients]);

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

    const canAddClient = hasAccessToAction("Clients", "Client -> Add Client");
    const canEditClient = hasAccessToAction("Clients", "Client -> Update Client");
    const canDeleteClient = hasAccessToAction("Clients", "Client -> Delete Client");

    const openAddClientModal = () => {
        setSelectedClient(null);
        setModalMode('add');
        // setModalOpen(true);
    };

    const openEditClientModal = (client) => {
        console.log("data for edit client====0-->>>  ", client);
        
        setSelectedClient(client);
        setModalMode('edit');
        // setModalOpen(true);
    };

    const handleDelete = (clientId, setClients) => {
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
                deleteClient(clientId, setClients);
            }
        });
    };

    const [openDropdownId, setOpenDropdownId] = useState(null);

    // Filter clients based on the search term
    const filteredClients = clients.filter(client => 
        (client.first_name + ' ' + client.last_name).toLowerCase().includes(searchTerm.toLowerCase())
    );

    const paginatedClients = clients.slice(startIndex, startIndex + rowsPerPage);


    // Define columns for DataTable
    const columns = [
        {
            name: 'Client Name',
            selector: row => `${row.first_name} ${row.last_name}`,
            sortable: true,
        },
        {
            name: 'Main Contact',
            selector: row => row.main_contact_name,
            sortable: true,
        },
        {
            name: 'Phone',
            selector: row => row.phone,
            sortable: true,
        },
        {
            name: 'Email',
            selector: row => row.email,
            sortable: true,
        },
        {
            name: 'Status',
            selector: row => row.client_active ? 'Active' : 'Inactive', // Simplified for sorting
            sortable: true,
            cell: row => (
                <span className={`badge ${row.client_active ? 'badge-light-success' : 'badge-light-danger'}`}>
                    {row.client_active ? 'Active' : 'Inactive'}
                </span>
            ),
        },
        {
            name: "Actions",
            cell: row => {
        
                // const [isOpen, setIsOpen] = useState(false);
                
                useEffect(() => {
                    const handleOutsideClick = (event) => {
                        if (!event.target.closest(`#dropdown-${row.client_id}`)) {
                            // setIsOpen(false);
                            setOpenDropdownId(null);
                        }
                    };
        
                    document.addEventListener('click', handleOutsideClick);
                    return () => document.removeEventListener('click', handleOutsideClick);
                }, [row.client_id]);
        
                return (
                    <div
                        id={`dropdown-${row.client_id}`}
                        className={`${styles.dropdown} ${isDarkMode ? styles.darkDropdown : styles.lightDropdown}`}
                        onClick={e => e.stopPropagation()}
                        >
                        <button
                            className={`${styles.dropdownButton} ${
                            isDarkMode ? styles.darkButton : styles.lightButton
                            }`}
                            onClick={() =>
                                setOpenDropdownId(prevId => (prevId === row.client_id ? null : row.client_id))
                            }
                        >
                            Actions <FaChevronDown className={styles.dropdownIcon} />
                        </button>
                        {openDropdownId === row.client_id && (
                            <div className={`${styles.dropdownContent} ${isDarkMode ? styles.darkDropdown : styles.lightDropdown}`}>
                                <button
                                    className={`${styles.viewButton} ${isDarkMode ? styles.darkViewButton : styles.lightViewButton}`}
                                    onClick={() => {
                                        // setIsOpen(false);
                                        router.push(`/clientProjects?client_id=${row.client_id}`);
                                    }}
                                >
                                    View Projects
                                </button>
                                {canEditClient && (
                                    <button
                                        className={`${styles.viewButton} ${isDarkMode ? styles.darkViewButton : styles.lightViewButton}`}
                                        data-bs-toggle="modal"
                                        data-bs-target="#kt_modal_add_customer"
                                        onClick={() => {
                                            // setIsOpen(false);
                                            openEditClientModal(row);
                                        }}
                                    >
                                        Edit Client
                                    </button>
                                )}
                                {canDeleteClient && (
                                    <button
                                        className={`${styles.deleteButton} ${isDarkMode ? styles.darkDeleteButton : styles.lightDeleteButton}`}
                                        onClick={() => {
                                            // setIsOpen(false);
                                            handleDelete(row.client_id, setClients);
                                        }}
                                    >
                                        Delete
                                    </button>
                                )}
                                {canEditClient && (
                                    <button
                                        className={`${row.client_active ? styles.deactivateButton : styles.activateButton} ${isDarkMode ? styles.darkToggleButton : styles.lightToggleButton}`}
                                        onClick={() => {
                                            // setIsOpen(false);
                                            setOpenDropdownId(null);
                                            activateDeactivateClient(row.client_id, row.client_active ? 0 : 1, setClients);
                                        }}
                                    >
                                        {row.client_active ? 'Deactivate' : 'Activate'}
                                    </button>
                                )}
                            </div>
                        )}
                    </div>
                );
            },
        }
    ];

    // const closeModal = () => setModalOpen(false);
    const closeModal = () => {
        console.log("------close modal");
        
        // setShowModal(false); // Hide the modal
        setSelectedClient(null); // Reset selected project
    };

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
                                            Clients
                                        </h1>
                                        <ul className="breadcrumb breadcrumb-separatorless fw-semibold fs-7 my-0">
                                            <li className="breadcrumb-item text-muted">
                                                <a href="/" className="text-muted text-hover-primary">Home</a>
                                            </li>
                                            <li className="breadcrumb-item">
                                                <span className="bullet bg-gray-500 w-5px h-2px"></span>
                                            </li>
                                            <li className="breadcrumb-item text-muted">Clients</li>
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
                                                    placeholder="Search Clients"
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
                                            { canAddClient && (
                                                <button
                                                className="btn btn-primary"
                                                data-bs-toggle="modal"
                                                data-bs-target="#kt_modal_add_user"
                                              >
                                                <FaPlus className="me-1" /> Add New
                                              </button>
                                            )}
                                        </div>
                                    </div>
                                    <div className="card-body pt-0">
                                        {loading ? (
                                            <div>Loading...</div>
                                        ) : error ? (
                                            <div>Error: {error}</div>
                                        ) : (
                                            <>
                                                <DataTable
                                                    columns={columns}
                                                    data={paginatedClients}
                                                    highlightOnHover
                                                    responsive
                                                    noHeader
                                                />
                                                <div className={styles.paginationContainer}>
                                                    <select
                                                        className={styles.pageDropdown}
                                                        value={rowsPerPage}
                                                        onChange={handleRowsPerPageChange}
                                                    >
                                                        {[5, 10, 15, 20].map((num) => (
                                                            <option key={num} value={num}>
                                                                {num}
                                                            </option>
                                                        ))}
                                                    </select>
                                                    <ReactPaginate
                                                        previousLabel={<FaChevronLeft />}
                                                        nextLabel={<FaChevronRight />}
                                                        pageCount={Math.ceil(clients.length / rowsPerPage)}
                                                        onPageChange={handlePageChange}
                                                        containerClassName={styles.pagination}
                                                        previousLinkClassName={styles.previous}
                                                        nextLinkClassName={styles.next}
                                                        activeClassName={styles.active}
                                                        disabledClassName={styles.disabled}
                                                        pageLinkClassName={styles.pageLink}
                                                    />
                                                </div>
                                            </>
                                        )}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    {!loadingUsers && (
                        <AddClientModal
                            addUpdateClient={addUpdateClient}
                            Users={Users}
                            setClients={setClients}
                            mode={modalMode}
                        />
                    )}
                    <Footer />
                </div>
            </div>
        </div>
    );
};

export default Clients;
