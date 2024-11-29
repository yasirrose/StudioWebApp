import React, { useState, useEffect } from 'react';
import Header from '../../components/common/Header';
import Footer from '../../components/common/Footer';
import Sidebar from '../../components/common/Sidebar';
import DataTable from 'react-data-table-component';
import AddProjectModal from '../../components/Shared/AddProjectModal';
import styles from './clientProjects.module.scss';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import { FaChevronDown, FaSearch, FaPlus, FaFileExport } from 'react-icons/fa';
import { useRouter } from 'next/router';
import { useClients } from '/hooks/clients';
import { useFetchProjects, useDeleteProject, useActivateDeactivateProject, useAddUpdateProject } from '../../hooks/projects';
import Swal from 'sweetalert2';
import { useTheme } from '../../context/ThemeContext';
import { useFetchActionPermissions } from "../../hooks/permissions";

const ClientProjects = () => {
    const router = useRouter();
    const client_id = router.query.client_id;
    
    // const { Projects, loading, error } = useFetchProjects(client_id);
    const { Projects: allProjects, loading, error, setProjects } = useFetchProjects(); // Fetch tasks data
    
    const { deleteProject } = useDeleteProject();
    const { activateDeactivateProject } = useActivateDeactivateProject();
    const { addUpdateProject } = useAddUpdateProject();
    const { Clients, loading:loadingClients } = useClients(); // Fetch projects via the hook
    const { actionPermissions } = useFetchActionPermissions();

    
    // const [projects, setProjects] = useState([]);
    const [searchTerm, setSearchTerm] = useState('');
    const [showModal, setShowModal] = useState(true);
    const [modalMode, setModalMode] = useState('add'); // 'add' or 'edit'
    const [selectedProject, setSelectedProject] = useState(null);
    const [filteredProjects, setFilteredProjects] = useState([]);
    const [isFiltering, setIsFiltering] = useState(true);
    const [roleId, setRoleId] = useState(null);


    useEffect(() => {
        if (allProjects) {
            // Filter tasks by project_id if available
            if (client_id) {
                setIsFiltering(true);
                const filteredList = allProjects.filter(proj => proj.client_id.toString() === client_id.toString());
                setFilteredProjects(filteredList);
                setIsFiltering(false);
            } else {
                setIsFiltering(false);
                setFilteredProjects(allProjects); // Show all tasks if no client_id is specified
            }
        }
    }, [allProjects, client_id]);

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

    const canAddProject = hasAccessToAction("Client Projects", "Project -> Add Project");
    const canEditProject = hasAccessToAction("Client Projects", "Project -> Update Project");
    const canDeleteProject = hasAccessToAction("Client Projects", "Project -> Delete Project");

    const handleAddProject = () => {
        setSelectedProject(null); // Set to null to indicate "add" mode
        setModalMode('add');

        // setShowModal(true);
    };

    const handleEditProject = (project) => {
        console.log("----handleEditProject  ");
        setSelectedProject(project); // Set the project to be edited
        setModalMode('edit');

        // setShowModal(true);
    };

    const handleDelete = (projectId, setProjects) => {
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
                deleteProject(projectId, setProjects);
            }
        });
    };

    // Filter projects based on the search term   
    const displayedProjects = filteredProjects.filter(project =>
        // (project.first_name + ' ' + project.last_name).toLowerCase().includes(searchTerm.toLowerCase())
        project?.project_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        project?.asana_project_name?.toLowerCase().includes(searchTerm.toLowerCase())

    );
    

    // Define columns for DataTable
    const columns = [
        {
            name: 'Project Name',
            selector: row => row.project_name,
            sortable: true,
        },
        {
            name: 'Asana Project Name',
            selector: row => row.asana_project_name,
            sortable: true,
        },
        {
            name: 'Client',
            selector: row => row.first_name,
            sortable: true,
        },
        {
            name: 'Asana API Client ID',
            selector: row => row.asana_api_client_id,
            sortable: true,
        },
        {
            name: 'Asana API Client Secret',
            selector: row => row.asana_api_client_secret,
            sortable: true,
        },
        {
            name: 'Project Status',
            selector: row => row.project_active ? 'Active' : 'Inactive', // Simplified for sorting
            sortable: true,
            cell: row => (
              <span className={`badge ${row.project_active ? 'badge-light-success' : 'badge-light-danger'}`}>
                {row.project_active ? 'Active' : 'Inactive'}
              </span>
            ),
        },        
        {
            name: 'Actions',
            cell: row => (
                <div className={`${styles.dropdown} ${isDarkMode ? styles.darkDropdown : styles.lightDropdown}`}>
                    <button className={`${styles.dropdownButton} ${isDarkMode ? styles.darkButton : styles.lightButton}`}>Actions <FaChevronDown className={styles.dropdownIcon} /></button>
                    <div className={`${styles.dropdownContent} ${isDarkMode ? styles.darkDropdown : styles.lightDropdownContent}`}>
                        { canEditProject && (
                            <button className={`${styles.viewButton} ${isDarkMode ? styles.darkViewButton : styles.lightViewButton}`} data-bs-toggle="modal" data-bs-target="#kt_modal_add_project" onClick={() => handleEditProject(row)}>Edit Project</button>
                        )}
                        <button className={`${styles.viewButton} ${isDarkMode ? styles.darkViewButton : styles.lightViewButton}`} onClick={() => router.push(`/projectTasks?project_id=${row.project_id}`)}>View Tasks</button>
                        { canDeleteProject && (
                            <button className={`${styles.deleteButton} ${isDarkMode ? styles.darkDeleteButton : styles.lightDeleteButton}`} onClick={() => handleDelete(row.project_id, setProjects)}>Delete</button>
                        )}
                        { canEditProject && (
                            <button
                                className={`${row.user_active ? styles.deactivateButton : styles.activateButton} ${isDarkMode ? styles.darkToggleButton : styles.lightToggleButton}`}
                                onClick={() => activateDeactivateProject(row.project_id, row.project_active ? 0 : 1, setProjects)}
                            >
                                {row.project_active ? 'Deactivate' : 'Activate'}
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
                        <ToastContainer />
                        <div id="kt_app_content" className="app-content flex-column-fluid">
                        <div id="kt_app_content_container" className="app-container container-fluid">
                            <div className="app-toolbar-wrapper d-flex flex-stack flex-wrap gap-4 w-100">
                                <div className="page-title d-flex flex-column justify-content-center gap-1 me-3">
                                    <h1 className="page-heading d-flex flex-column justify-content-center text-gray-900 fw-bold fs-3 m-0">
                                        Client Projects
                                    </h1>
                                    <ul className="breadcrumb breadcrumb-separatorless fw-semibold fs-7 my-0">
                                        <li className="breadcrumb-item text-muted">
                                            <a href="/" className="text-muted text-hover-primary">Home</a>
                                        </li>
                                        <li className="breadcrumb-item">
                                            <span className="bullet bg-gray-500 w-5px h-2px"></span>
                                        </li>
                                        <li className="breadcrumb-item text-muted">Client Projects</li>
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
                                                    placeholder="Search Projects"
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
                                        { canAddProject && (
                                            <button className="btn btn-primary" data-bs-toggle="modal" data-bs-target="#kt_modal_add_project" onClick={handleAddProject}>
                                                <FaPlus className="me-1" /> Add New
                                            </button>
                                        )}
                                    </div>
                                </div>

                                <div className="card-body pt-0">
                                    { isFiltering || loading ? (
                                        <div>Loading...</div>
                                    ) : error ? (
                                        <div>Error: {error}</div>
                                    ) : (
                                    <DataTable
                                        columns={columns}
                                        data={displayedProjects}
                                        paginationPerPage={5}
                                        pagination
                                        highlightOnHover
                                        responsive
                                    />
                                    )}
                                    {error && <p className="text-danger">{error}</p>}
                                </div>
                            </div>
                            { !loadingClients && showModal && (
                                <AddProjectModal
                                    mode={modalMode}
                                    projectData={selectedProject}
                                    setProjects={setProjects}
                                    Clients={Clients}
                                    addUpdateProject={addUpdateProject}
                                />
                            )}
                        </div>
                        </div>
                    </div>
                    <Footer />
                </div>
            </div>
        </div>
    );
};

export default ClientProjects;
